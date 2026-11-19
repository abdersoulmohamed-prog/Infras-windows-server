# PHASE 08 - SUPERVISION & INFRASTRUCTURE HEALTH CHECK

## Windows Server 2025 Enterprise Infrastructure

**Project:** Windows Server 2025 Enterprise Infrastructure  
**Domain:** `diarabaka.com`  
**Domain Controllers:** `DC01`, `DC02`  
**File Server:** `FILE01`  
**Client:** `WIN11`  
**Network:** `192.168.1.0/24`  
**Platform:** VMware  
**Professional Domain:** Microsoft Infrastructure

---

# 08.0 - Objectif

L'objectif est de répondre de manière structurée à la question :

```text
IS THE WINDOWS INFRASTRUCTURE HEALTHY?
```

La phase ne doit pas seulement :

```text
run commands
```

Elle doit :

```text
DISCOVER
   ↓
CHECK
   ↓
COMPARE
   ↓
CLASSIFY
   ↓
INVESTIGATE
   ↓
RETEST
   ↓
EVIDENCE
   ↓
VALIDATE
```

Périmètre :

```text
ACTIVE DIRECTORY
 │
 ├── Domain
 ├── Forest
 ├── DC01
 ├── DC02
 ├── Global Catalog
 ├── FSMO
 ├── Replication
 └── Time

DNS
 │
 ├── Zones
 ├── Direct DC01 query
 ├── Direct DC02 query
 ├── LDAP SRV
 ├── Kerberos SRV
 ├── DC Locator
 └── External resolution

DHCP
 │
 ├── Service DC01
 ├── Service DC02
 ├── Authorization
 ├── Scope
 ├── Options
 ├── Capacity
 ├── Failover DC01 view
 ├── Failover DC02 view
 └── Client validation

FILE01
 │
 ├── SMB
 ├── Shares
 ├── AGDLP
 ├── NTFS
 ├── Storage
 ├── FSRM
 ├── Backup
 └── Restore evidence

WIN11
 │
 ├── Domain
 ├── DNS
 ├── DC Locator
 ├── Secure Channel
 ├── Kerberos
 ├── GPO
 ├── Defender
 ├── Firewall
 ├── BitLocker
 ├── LAPS
 ├── Windows Update
 └── Local Administrators

OPERATIONS
 │
 ├── Event Logs
 ├── PowerShell Remoting
 ├── Status Engine
 ├── Exit Codes
 ├── CSV Reports
 ├── Controlled Warning Test
 ├── Controlled Critical Test
 └── Final Regression
```

---

# 08.1 - Règle de validation

```text
COMMAND RUNS
   ≠
CONTROL VALIDATED
```

et :

```text
SCRIPT RUNS
   ≠
INFRASTRUCTURE HEALTH VALIDATED
```

Validation :

```text
EXPECTED
   +
ACTUAL
   +
INTERPRETATION
   +
FUNCTIONAL CONTEXT
   +
EVIDENCE
   =
VALIDATED
```

Aucun contrôle ne doit passer en `VALIDATED` uniquement parce qu'une commande n'a pas généré d'erreur.

---

# 08.2 - Health States

Le modèle utilise :

```text
OK
WARNING
CRITICAL
UNKNOWN
```

| Status     | Signification                                                     |
| ---------- | ----------------------------------------------------------------- |
| `OK`       | Le résultat observé correspond au résultat attendu                |
| `WARNING`  | Le service reste disponible mais une anomalie ou un risque existe |
| `CRITICAL` | Un service critique ou un contrôle majeur échoue                  |
| `UNKNOWN`  | Le contrôle n'a pas pu être évalué correctement                   |

Principe :

```text
UNKNOWN
   ≠
OK
```

---

# 08.3 - Classification opérationnelle

Exemples `CRITICAL` :

```text
AD domain unavailable
Both DCs unavailable
Persistent AD replication failure
Internal AD DNS unavailable
DHCP scope unavailable
Expected DHCP failover missing
FILE01 SMB unavailable
WIN11 secure channel broken
Required security control disabled
```

Exemples `WARNING` :

```text
Disk free space approaching threshold
Quota approaching threshold
Backup older than policy threshold
Unexpected local administrator
One redundant service unavailable while service remains available
Recent significant warning requiring review
```

Exemples `UNKNOWN` :

```text
WinRM unavailable
Insufficient privileges
Module unavailable
Remote command failed
Host could not be queried
Expected evidence missing
```

---

# 08.4 - Dependency Order

Ordre :

```text
1. DC01 / DC02 reachability
2. Active Directory
3. FSMO
4. Replication
5. DNS
6. Time
7. DHCP
8. FILE01
9. Storage
10. FSRM
11. Backup
12. WIN11
13. Security
14. Event Logs
15. Global Health Status
```

Dépendance :

```text
DNS
 ↓
DC Locator
 ↓
Authentication
 ↓
GPO
 ↓
Resource Access
```

---

# 08.5 - Evidence Pack

Créer sur DC01 :

```powershell
$EvidenceRoot = "C:\Evidence\HealthCheck"

$Folders = @(
    "01-AD",
    "02-DC",
    "03-FSMO",
    "04-Replication",
    "05-DNS",
    "06-Time",
    "07-DHCP",
    "08-FILE01",
    "09-AGDLP",
    "10-Storage",
    "11-FSRM",
    "12-Backup",
    "13-WIN11",
    "14-Security",
    "15-Event-Logs",
    "16-Remoting",
    "17-Automation",
    "18-Warning-Test",
    "19-Critical-Test",
    "20-Final-Regression"
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

Evidence schema :

```text
TEST ID
TIMESTAMP
HOST
CATEGORY
CHECK
COMMAND
EXPECTED
ACTUAL
INTERPRETATION
STATUS
EVIDENCE PATH
```

---

# 08.6 - Baseline DC01

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

# 08.7 - AD Domain

```powershell
Get-ADDomain |
    Select-Object `
        DNSRoot,
        NetBIOSName,
        DomainMode,
        PDCEmulator,
        RIDMaster,
        InfrastructureMaster
```

Cible :

```text
DNSRoot : diarabaka.com
```

---

# 08.8 - AD Forest

```powershell
Get-ADForest |
    Select-Object `
        Name,
        ForestMode,
        SchemaMaster,
        DomainNamingMaster,
        GlobalCatalogs
```

---

# 08.9 - Expected Domain Controllers

Ne pas valider simplement :

```text
DC count >= 2
```

La cible est explicitement :

```text
DC01
DC02
```

Vérifier :

```powershell
$ExpectedDCs = @(
    "DC01.diarabaka.com",
    "DC02.diarabaka.com"
)

$ActualDCs = @(
    Get-ADDomainController -Filter * |
        Select-Object -ExpandProperty HostName
)

$MissingDCs = $ExpectedDCs |
    Where-Object {
        $_ -notin $ActualDCs
    }

$MissingDCs
```

Cible :

```text
No output
```

---

# 08.10 - DC Inventory

```powershell
Get-ADDomainController -Filter * |
    Select-Object `
        HostName,
        IPv4Address,
        Site,
        IsGlobalCatalog,
        IsReadOnly
```

---

# 08.11 - Global Catalog

Vérifier explicitement :

```powershell
Get-ADDomainController `
    -Identity "DC01" |
    Select-Object `
        HostName,
        IsGlobalCatalog

Get-ADDomainController `
    -Identity "DC02" |
    Select-Object `
        HostName,
        IsGlobalCatalog
```

Cible projet :

```text
DC01 → IsGlobalCatalog = True
DC02 → IsGlobalCatalog = True
```

---

# 08.12 - DC Reachability

```powershell
Test-Connection DC01 -Count 2
Test-Connection DC02 -Count 2
```

Puis :

```powershell
Test-NetConnection DC01 -Port 389
Test-NetConnection DC02 -Port 389
```

Puis :

```powershell
Test-NetConnection DC01 -Port 88
Test-NetConnection DC02 -Port 88
```

Puis :

```powershell
Test-NetConnection DC01 -Port 53
Test-NetConnection DC02 -Port 53
```

---

# 08.13 - FSMO Roles

```powershell
netdom query fsmo
```

Puis :

```powershell
Get-ADDomain |
    Select-Object `
        PDCEmulator,
        RIDMaster,
        InfrastructureMaster
```

Puis :

```powershell
Get-ADForest |
    Select-Object `
        SchemaMaster,
        DomainNamingMaster
```

Health Check :

```text
5 roles identifiable
+
owners reachable
```

Ne jamais déplacer automatiquement un rôle depuis le health check.

---

# 08.14 - FSMO Owner Reachability

```powershell
$Domain = Get-ADDomain
$Forest = Get-ADForest

$FsmoOwners = @(
    $Domain.PDCEmulator,
    $Domain.RIDMaster,
    $Domain.InfrastructureMaster,
    $Forest.SchemaMaster,
    $Forest.DomainNamingMaster
) |
    Sort-Object -Unique

foreach ($Owner in $FsmoOwners) {
    Test-Connection $Owner -Count 1
}
```

---

# 08.15 - AD Replication Principle

La réplication doit être prouvée avec plusieurs vues.

```text
ONE COMMAND
   ≠
FULL REPLICATION VALIDATION
```

Contrôles :

```text
repadmin /replsummary
repadmin /showrepl DC01
repadmin /showrepl DC02
dcdiag /test:replications
Get-ADReplicationFailure
```

---

# 08.16 - Replication Summary

```powershell
repadmin /replsummary
```

Cible :

```text
Fails = 0
```

Ne pas déclarer `OK` avant sortie réelle.

---

# 08.17 - Replication DC01

```powershell
repadmin /showrepl DC01
```

Examiner :

```text
Naming Context
Source DC
Last attempt
Result
Last success
```

---

# 08.18 - Replication DC02

```powershell
repadmin /showrepl DC02
```

---

# 08.19 - DCDIAG Replications

```powershell
dcdiag /test:replications
```

---

# 08.20 - PowerShell Replication Failures

```powershell
Get-ADReplicationFailure `
    -Target * `
    -Scope Forest
```

Attention :

```text
No object returned
   ≠
proof that every replication test is complete
```

Ce contrôle complète `repadmin` et `dcdiag`.

---

# 08.21 - Replication Troubleshooting

```text
REPLICATION FAILURE
      ↓
DNS
      ↓
Network
      ↓
Time
      ↓
RPC / AD services
      ↓
Event Logs
      ↓
repadmin /showrepl
      ↓
Root Cause
```

Ne pas :

```text
force sync blindly
delete metadata blindly
move FSMO blindly
rebuild DC blindly
```

---

# 08.22 - DNS Server Inventory

Sur DC01 :

```powershell
Get-DnsServerZone |
    Select-Object `
        ZoneName,
        ZoneType,
        IsDsIntegrated,
        DynamicUpdate,
        ReplicationScope
```

Puis sur DC02 :

```powershell
Get-DnsServerZone `
    -ComputerName DC02 |
    Select-Object `
        ZoneName,
        ZoneType,
        IsDsIntegrated,
        DynamicUpdate,
        ReplicationScope
```

---

# 08.23 - DNS Server Parameters

Définir les adresses attendues selon l'architecture documentée :

```powershell
$DC01IP = "192.168.1.10"
$DC02IP = "192.168.1.11"
```

Ici, ces valeurs sont des paramètres d'architecture connus du lab.

---

# 08.24 - Direct DNS Query DC01

```powershell
Resolve-DnsName `
    dc01.diarabaka.com `
    -Server $DC01IP
```

Puis :

```powershell
Resolve-DnsName `
    "_ldap._tcp.dc._msdcs.diarabaka.com" `
    -Type SRV `
    -Server $DC01IP
```

---

# 08.25 - Direct DNS Query DC02

```powershell
Resolve-DnsName `
    dc01.diarabaka.com `
    -Server $DC02IP
```

Puis :

```powershell
Resolve-DnsName `
    "_ldap._tcp.dc._msdcs.diarabaka.com" `
    -Type SRV `
    -Server $DC02IP
```

Cette méthode évite de dépendre d'une première résolution DNS pour trouver l'adresse du DNS que l'on veut tester.

---

# 08.26 - DNS Internal Records

```powershell
Resolve-DnsName diarabaka.com
Resolve-DnsName dc01.diarabaka.com
Resolve-DnsName dc02.diarabaka.com
Resolve-DnsName file01.diarabaka.com
```

---

# 08.27 - LDAP SRV

```powershell
Resolve-DnsName `
    "_ldap._tcp.dc._msdcs.diarabaka.com" `
    -Type SRV
```

Cible :

```text
DC01 present
DC02 present
```

---

# 08.28 - Kerberos SRV

```powershell
Resolve-DnsName `
    "_kerberos._tcp.diarabaka.com" `
    -Type SRV
```

---

# 08.29 - DC Locator

```powershell
nltest /dsgetdc:diarabaka.com
```

Le résultat doit retourner un DC utilisable.

---

# 08.30 - DCDIAG DNS

```powershell
dcdiag /test:dns
```

Puis :

```powershell
dcdiag /e /test:dns
```

---

# 08.31 - DNS Forwarders

```powershell
Get-DnsServerForwarder
```

Documenter :

```text
Configured?
Reachable?
Expected?
```

---

# 08.32 - External Resolution

```powershell
Resolve-DnsName www.microsoft.com
```

Un échec externe ne signifie pas nécessairement une panne de DNS AD.

---

# 08.33 - Time Health DC01

```powershell
w32tm /query /status
w32tm /query /source
```

---

# 08.34 - Time Health DC02

```powershell
Invoke-Command `
    -ComputerName DC02 `
    -ScriptBlock {
        w32tm /query /status
        w32tm /query /source
    }
```

---

# 08.35 - DHCP Feature / Service DC01

```powershell
Get-WindowsFeature DHCP
```

Puis :

```powershell
Get-Service DHCPServer
```

Cible :

```text
Installed
Running
```

---

# 08.36 - DHCP Service DC02

```powershell
Get-Service `
    -ComputerName DC02 `
    -Name DHCPServer
```

ou via remoting :

```powershell
Invoke-Command `
    -ComputerName DC02 `
    -ScriptBlock {
        Get-Service DHCPServer
    }
```

---

# 08.37 - DHCP Authorization

```powershell
Get-DhcpServerInDC
```

Vérifier que les serveurs attendus sont autorisés.

---

# 08.38 - DHCP Bindings DC01

```powershell
Get-DhcpServerv4Binding `
    -ComputerName DC01
```

---

# 08.39 - DHCP Bindings DC02

```powershell
Get-DhcpServerv4Binding `
    -ComputerName DC02
```

---

# 08.40 - DHCP Scope DC01

```powershell
Get-DhcpServerv4Scope `
    -ComputerName DC01 |
    Select-Object `
        ScopeId,
        Name,
        StartRange,
        EndRange,
        State
```

Cible :

```text
ScopeId    : 192.168.1.0
StartRange : 192.168.1.100
EndRange   : 192.168.1.200
State      : Active
```

---

# 08.41 - DHCP Scope DC02

```powershell
Get-DhcpServerv4Scope `
    -ComputerName DC02 |
    Select-Object `
        ScopeId,
        Name,
        StartRange,
        EndRange,
        State
```

Comparer les éléments attendus.

---

# 08.42 - DHCP Options

```powershell
Get-DhcpServerv4OptionValue `
    -ComputerName DC01 `
    -ScopeId 192.168.1.0
```

Vérifier :

```text
003 Router      → 192.168.1.1
006 DNS Servers → 192.168.1.10, 192.168.1.11
015 DNS Domain  → diarabaka.com
```

Puis contrôler DC02 si nécessaire pour comparaison.

---

# 08.43 - DHCP Capacity

```powershell
Get-DhcpServerv4ScopeStatistics `
    -ComputerName DC01 `
    -ScopeId 192.168.1.0
```

Projet :

```text
< 80%  → OK
80-90% → WARNING
>= 90% → CRITICAL
```

---

# 08.44 - DHCP Failover DC01 View

```powershell
Get-DhcpServerv4Failover `
    -ComputerName DC01 `
    -ScopeId 192.168.1.0 |
    Format-List
```

Examiner :

```text
Name
PartnerServer
Mode
State
LoadBalancePercent
MaxClientLeadTime
ScopeId
```

---

# 08.45 - DHCP Failover DC02 View

```powershell
Get-DhcpServerv4Failover `
    -ComputerName DC02 `
    -ScopeId 192.168.1.0 |
    Format-List
```

---

# 08.46 - DHCP Failover Consistency

Cible :

```text
DC01 sees DC02 as partner
DC02 sees DC01 as partner
Mode = LoadBalance
LoadBalancePercent = 50
Scope 192.168.1.0 associated
State = Normal
```

Ne pas valider uniquement :

```text
State = Normal
```

sans regarder les autres propriétés.

---

# 08.47 - DHCP Client Functional Check

Depuis WIN11 :

```powershell
ipconfig /all
```

Puis :

```powershell
Get-NetIPConfiguration
```

Vérifier :

```text
Valid address
Expected gateway
Internal DNS
Expected suffix
```

---

# 08.48 - FILE01 Service Health

```powershell
Invoke-Command `
    -ComputerName FILE01 `
    -ScriptBlock {
        Get-Service LanmanServer
    }
```

Cible :

```text
Running
```

---

# 08.49 - FILE01 Shares

```powershell
$ExpectedShares = @(
    "IT$",
    "HR$",
    "Finance$",
    "Marketing$",
    "Sales$",
    "Public$"
)

$ActualShares = Invoke-Command `
    -ComputerName FILE01 `
    -ScriptBlock {
        Get-SmbShare |
            Select-Object `
                Name,
                Path,
                FolderEnumerationMode,
                EncryptData
    }

$ActualShares
```

---

# 08.50 - Missing Share Detection

```powershell
$ActualNames = $ActualShares.Name

$MissingShares = $ExpectedShares |
    Where-Object {
        $_ -notin $ActualNames
    }

$MissingShares
```

Cible :

```text
No missing expected shares
```

---

# 08.51 - AGDLP Resource Groups

Depuis DC01 :

```powershell
$ResourceGroups = @(
    "DL-FS-IT-Modify",
    "DL-FS-HR-Modify",
    "DL-FS-Finance-Modify",
    "DL-FS-Marketing-Modify",
    "DL-FS-Sales-Modify",
    "DL-FS-Public-Modify"
)

foreach ($Group in $ResourceGroups) {
    Get-ADGroup $Group |
        Select-Object `
            Name,
            GroupScope,
            GroupCategory
}
```

Cible :

```text
DomainLocal
Security
```

---

# 08.52 - AGDLP Nesting

```powershell
$Pairs = @{
    "GG-IT"        = "DL-FS-IT-Modify"
    "GG-HR"        = "DL-FS-HR-Modify"
    "GG-Finance"   = "DL-FS-Finance-Modify"
    "GG-Marketing" = "DL-FS-Marketing-Modify"
    "GG-Sales"     = "DL-FS-Sales-Modify"
}

foreach ($Global in $Pairs.Keys) {

    $DomainLocal = $Pairs[$Global]

    Write-Host "`n$Global -> $DomainLocal"

    Get-ADGroupMember $DomainLocal |
        Select-Object `
            Name,
            SamAccountName,
            ObjectClass
}
```

---

# 08.53 - SMB Permissions

Sur FILE01 :

```powershell
Invoke-Command `
    -ComputerName FILE01 `
    -ScriptBlock {
        $Shares = @(
            "IT$",
            "HR$",
            "Finance$",
            "Marketing$",
            "Sales$",
            "Public$"
        )

        foreach ($Share in $Shares) {
            Get-SmbShareAccess -Name $Share
        }
    }
```

Les ACL attendues doivent viser les groupes `DL-FS-*` selon le design.

---

# 08.54 - Discover NTFS Paths

Ne pas coder :

```text
D:\Shares
E:\Shares
```

Le health check doit découvrir les chemins depuis les partages.

Exemple :

```powershell
$SharePaths = Invoke-Command `
    -ComputerName FILE01 `
    -ScriptBlock {
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
    }

$SharePaths
```

---

# 08.55 - NTFS ACL Audit

```powershell
Invoke-Command `
    -ComputerName FILE01 `
    -ScriptBlock {

        $Shares = Get-SmbShare |
            Where-Object {
                $_.Name -in @(
                    "IT$",
                    "HR$",
                    "Finance$",
                    "Marketing$",
                    "Sales$",
                    "Public$"
                )
            }

        foreach ($Share in $Shares) {

            Write-Host "`n===== $($Share.Name) ====="

            icacls $Share.Path
        }
    }
```

---

# 08.56 - SMB Sessions

```powershell
Invoke-Command `
    -ComputerName FILE01 `
    -ScriptBlock {
        Get-SmbSession |
            Select-Object `
                ClientComputerName,
                ClientUserName,
                NumOpens,
                Dialect,
                Encrypted
    }
```

---

# 08.57 - SMB Open Files

```powershell
Invoke-Command `
    -ComputerName FILE01 `
    -ScriptBlock {
        Get-SmbOpenFile
    }
```

---

# 08.58 - FILE01 Storage

```powershell
Invoke-Command `
    -ComputerName FILE01 `
    -ScriptBlock {
        Get-Volume |
            Where-Object DriveLetter |
            Select-Object `
                DriveLetter,
                FileSystemLabel,
                FileSystem,
                HealthStatus,
                Size,
                SizeRemaining
    }
```

---

# 08.59 - Disk Thresholds

Projet :

```text
Free > 20%  → OK
Free 10-20% → WARNING
Free < 10%  → CRITICAL
```

Mais le health check doit distinguer :

```text
OS volume
Data volume
Backup volume
```

lorsque leur rôle est connu.

---

# 08.60 - FSRM Feature

```powershell
Invoke-Command `
    -ComputerName FILE01 `
    -ScriptBlock {
        Get-WindowsFeature FS-Resource-Manager
    }
```

---

# 08.61 - FSRM Quotas

```powershell
Invoke-Command `
    -ComputerName FILE01 `
    -ScriptBlock {
        Get-FsrmQuota |
            Select-Object `
                Path,
                Size,
                Usage,
                Disabled,
                SoftLimit,
                Description
    }
```

---

# 08.62 - FSRM Health Criteria

Ne pas considérer :

```text
Quota count > 0
```

comme preuve suffisante.

Vérifier :

```text
Expected quota path exists
Quota enabled
Expected hard/soft mode
Expected size
Usage
Threshold proximity
```

---

# 08.63 - Backup Feature

```powershell
Invoke-Command `
    -ComputerName FILE01 `
    -ScriptBlock {
        Get-WindowsFeature Windows-Server-Backup
    }
```

---

# 08.64 - Backup Versions

```powershell
Invoke-Command `
    -ComputerName FILE01 `
    -ScriptBlock {
        wbadmin get versions
    }
```

Ce contrôle peut montrer :

```text
backup time
backup target
version identifier
recoverable items
```

Il ne prouve pas automatiquement qu'une restauration a réussi.

---

# 08.65 - Backup Health Model

```text
BACKUP VERSION EXISTS
      ↓
BACKUP AGE CHECK
      ↓
BACKUP TARGET REVIEW
      ↓
BACKUP CONTENT CHECK
      ↓
RESTORE EVIDENCE
      ↓
RECOVERY CONFIDENCE
```

---

# 08.66 - Backup Recency

Définir une politique du lab, par exemple :

```text
<= 24 hours → OK
24-48 hours → WARNING
> 48 hours  → CRITICAL
```

uniquement si un backup quotidien est réellement prévu.

Sinon :

```text
UNKNOWN / POLICY NOT DEFINED
```

plutôt que d'inventer un seuil.

---

# 08.67 - Restore Evidence Health

Le health check doit rechercher une preuve documentaire de la Phase 06 :

```text
Alternate-path restore
SHA256 match
ACL validation
SMB functional retest
```

Sans cette preuve :

```text
BACKUP PRESENT
RESTORE VALIDATION UNKNOWN
```

---

# 08.68 - WIN11 Domain Membership

```powershell
Invoke-Command `
    -ComputerName WIN11 `
    -ScriptBlock {
        Get-CimInstance Win32_ComputerSystem |
            Select-Object `
                Name,
                Domain,
                PartOfDomain
    }
```

---

# 08.69 - WIN11 DNS

```powershell
Invoke-Command `
    -ComputerName WIN11 `
    -ScriptBlock {
        Get-DnsClientServerAddress `
            -AddressFamily IPv4
    }
```

---

# 08.70 - WIN11 DC Locator

```powershell
Invoke-Command `
    -ComputerName WIN11 `
    -ScriptBlock {
        nltest /dsgetdc:diarabaka.com
    }
```

---

# 08.71 - WIN11 Secure Channel

```powershell
Invoke-Command `
    -ComputerName WIN11 `
    -ScriptBlock {
        Test-ComputerSecureChannel
    }
```

Cible :

```text
True
```

---

# 08.72 - WIN11 Kerberos

```powershell
Invoke-Command `
    -ComputerName WIN11 `
    -ScriptBlock {
        klist
    }
```

Pour une preuve fonctionnelle complète, utiliser la Phase 07 :

```text
TGT
+
CIFS ticket
+
SMB access
```

---

# 08.73 - WIN11 GPO

```powershell
Invoke-Command `
    -ComputerName WIN11 `
    -ScriptBlock {
        gpresult /r /scope computer
    }
```

Comparer aux GPO attendues.

---

# 08.74 - WIN11 Defender

```powershell
Invoke-Command `
    -ComputerName WIN11 `
    -ScriptBlock {
        Get-MpComputerStatus |
            Select-Object `
                AntivirusEnabled,
                RealTimeProtectionEnabled,
                BehaviorMonitorEnabled,
                AntivirusSignatureLastUpdated
    }
```

---

# 08.75 - WIN11 Firewall

```powershell
Invoke-Command `
    -ComputerName WIN11 `
    -ScriptBlock {
        Get-NetFirewallProfile |
            Select-Object `
                Name,
                Enabled,
                DefaultInboundAction,
                DefaultOutboundAction
    }
```

---

# 08.76 - WIN11 BitLocker

```powershell
Invoke-Command `
    -ComputerName WIN11 `
    -ScriptBlock {
        Get-BitLockerVolume `
            -MountPoint "C:" |
            Select-Object `
                MountPoint,
                VolumeStatus,
                ProtectionStatus,
                EncryptionPercentage
    }
```

---

# 08.77 - WIN11 TPM

```powershell
Invoke-Command `
    -ComputerName WIN11 `
    -ScriptBlock {
        Get-Tpm |
            Select-Object `
                TpmPresent,
                TpmReady,
                TpmEnabled,
                TpmActivated
    }
```

---

# 08.78 - BitLocker Recovery AD

Depuis DC01 :

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

Ne pas exposer le recovery password.

---

# 08.79 - WIN11 LAPS

Sur WIN11 :

```powershell
Invoke-Command `
    -ComputerName WIN11 `
    -ScriptBlock {
        Get-WinEvent `
            -LogName "Microsoft-Windows-LAPS/Operational" `
            -MaxEvents 20
    }
```

Depuis DC01 :

```powershell
Get-LapsADPassword `
    -Identity "WIN11"
```

Ne pas utiliser `-AsPlainText` dans les preuves.

---

# 08.80 - WIN11 Windows Update

```powershell
Invoke-Command `
    -ComputerName WIN11 `
    -ScriptBlock {
        Get-Service wuauserv
        Get-HotFix |
            Sort-Object InstalledOn -Descending |
            Select-Object -First 10
    }
```

Le health check doit distinguer :

```text
service inventory
policy state
update history
```

---

# 08.81 - WIN11 Local Administrators

```powershell
Invoke-Command `
    -ComputerName WIN11 `
    -ScriptBlock {
        Get-LocalGroupMember `
            -Group "Administrators" |
            Select-Object `
                Name,
                ObjectClass,
                PrincipalSource
    }
```

Comparer à la baseline attendue.

---

# 08.82 - Event Log Window

Définir :

```powershell
$Since = (Get-Date).AddHours(-24)
```

Ne pas conclure qu'une machine est en panne uniquement parce qu'une erreur ancienne est présente.

---

# 08.83 - System Critical / Error Events

```powershell
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
        LevelDisplayName,
        ProviderName,
        Message
```

---

# 08.84 - Directory Service Events

Sur DC01 / DC02 :

```powershell
Invoke-Command `
    -ComputerName DC01,DC02 `
    -ScriptBlock {

        $Since = (Get-Date).AddHours(-24)

        Get-WinEvent `
            -FilterHashtable @{
                LogName   = "Directory Service"
                StartTime = $Since
                Level     = 1,2
            } `
            -ErrorAction SilentlyContinue |
            Select-Object `
                TimeCreated,
                Id,
                LevelDisplayName,
                ProviderName,
                Message
    }
```

---

# 08.85 - DNS Logs Discovery

```powershell
Get-WinEvent -ListLog *DNS* |
    Select-Object `
        LogName,
        IsEnabled,
        RecordCount
```

Puis examiner les journaux réellement présents si nécessaire.

---

# 08.86 - DHCP Logs Discovery

```powershell
Get-WinEvent -ListLog *DHCP* |
    Select-Object `
        LogName,
        IsEnabled,
        RecordCount
```

---

# 08.87 - FILE01 Logs Discovery

```powershell
Invoke-Command `
    -ComputerName FILE01 `
    -ScriptBlock {
        Get-WinEvent -ListLog *SMB*
        Get-WinEvent -ListLog *FileServer*
        Get-WinEvent -ListLog *Backup*
    }
```

---

# 08.88 - Critical Services DC01

```powershell
Get-Service `
    NTDS,
    DNS,
    Netlogon,
    KDC,
    DHCPServer |
    Select-Object `
        Name,
        Status,
        StartType
```

---

# 08.89 - Critical Services DC02

```powershell
Invoke-Command `
    -ComputerName DC02 `
    -ScriptBlock {
        Get-Service `
            NTDS,
            DNS,
            Netlogon,
            KDC,
            DHCPServer |
            Select-Object `
                Name,
                Status,
                StartType
    }
```

---

# 08.90 - FILE01 Critical Service

```powershell
Invoke-Command `
    -ComputerName FILE01 `
    -ScriptBlock {
        Get-Service LanmanServer |
            Select-Object `
                Name,
                Status,
                StartType
    }
```

---

# 08.91 - WIN11 Security Service Context

```powershell
Invoke-Command `
    -ComputerName WIN11 `
    -ScriptBlock {
        Get-Service WinDefend |
            Select-Object `
                Name,
                Status,
                StartType
    }
```

---

# 08.92 - PowerShell Remoting Pre-check

Depuis DC01 :

```powershell
Test-WSMan DC02
Test-WSMan FILE01
Test-WSMan WIN11
```

Le moteur doit distinguer :

```text
HOST UNREACHABLE
```

de :

```text
HOST REACHABLE
WINRM UNAVAILABLE
```

---

# 08.93 - Host vs Remoting Status

Exemple logique :

```text
PING / TCP works
+
Test-WSMan fails
=
REMOTE MANAGEMENT UNAVAILABLE
not
HOST DOWN
```

Ce cas doit produire `UNKNOWN` pour les contrôles distants dépendants de WinRM.

---

# 08.94 - Health Check Script Directory

```powershell
New-Item `
    -ItemType Directory `
    -Path "C:\SysAdminToolkit\08-HealthCheck" `
    -Force |
    Out-Null
```

---

# 08.95 - Script Design

Le script doit retourner pour chaque contrôle :

```text
TestId
Timestamp
Host
Category
Check
Expected
Actual
Status
Interpretation
```

---

# 08.96 - Health Result Function

```powershell
function Add-HealthResult {

    param(
        [Parameter(Mandatory)]
        [string]$TestId,

        [Parameter(Mandatory)]
        [string]$HostName,

        [Parameter(Mandatory)]
        [string]$Category,

        [Parameter(Mandatory)]
        [string]$Check,

        [Parameter(Mandatory)]
        [string]$Expected,

        [Parameter(Mandatory)]
        [string]$Actual,

        [Parameter(Mandatory)]
        [ValidateSet(
            "OK",
            "WARNING",
            "CRITICAL",
            "UNKNOWN"
        )]
        [string]$Status,

        [Parameter(Mandatory)]
        [string]$Interpretation
    )

    $script:Results.Add(
        [PSCustomObject]@{
            TestId        = $TestId
            Timestamp     = Get-Date
            Host          = $HostName
            Category      = $Category
            Check         = $Check
            Expected      = $Expected
            Actual        = $Actual
            Status        = $Status
            Interpretation = $Interpretation
        }
    )
}
```

---

# 08.97 - Safe Check Wrapper

```powershell
function Invoke-SafeCheck {

    param(
        [Parameter(Mandatory)]
        [string]$TestId,

        [Parameter(Mandatory)]
        [string]$HostName,

        [Parameter(Mandatory)]
        [string]$Category,

        [Parameter(Mandatory)]
        [string]$Check,

        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock
    )

    try {

        & $ScriptBlock

    }
    catch {

        Add-HealthResult `
            -TestId $TestId `
            -HostName $HostName `
            -Category $Category `
            -Check $Check `
            -Expected "Check completed successfully" `
            -Actual $_.Exception.Message `
            -Status "UNKNOWN" `
            -Interpretation "Control could not be evaluated"
    }
}
```

---

# 08.98 - Script Parameters

```powershell
[CmdletBinding()]
param(
    [string]$DomainName = "diarabaka.com",
    [string]$DC01 = "DC01",
    [string]$DC02 = "DC02",
    [string]$DC01IP = "192.168.1.10",
    [string]$DC02IP = "192.168.1.11",
    [string]$FileServer = "FILE01",
    [string]$Client = "WIN11",
    [string]$ScopeId = "192.168.1.0",
    [int]$DiskWarningPercent = 20,
    [int]$DiskCriticalPercent = 10,
    [int]$DhcpWarningPercent = 80,
    [int]$DhcpCriticalPercent = 90
)
```

---

# 08.99 - Script Result Collection

```powershell
$Results = [System.Collections.Generic.List[object]]::new()
```

---

# 08.100 - Example Check : Domain

```powershell
Invoke-SafeCheck `
    -TestId "HC-001" `
    -HostName $DC01 `
    -Category "AD" `
    -Check "Domain" `
    -ScriptBlock {

        $Domain = Get-ADDomain `
            -Identity $DomainName `
            -ErrorAction Stop

        if ($Domain.DNSRoot -eq $DomainName) {

            Add-HealthResult `
                -TestId "HC-001" `
                -HostName $DC01 `
                -Category "AD" `
                -Check "Domain" `
                -Expected $DomainName `
                -Actual $Domain.DNSRoot `
                -Status "OK" `
                -Interpretation "Expected AD domain detected"
        }
        else {

            Add-HealthResult `
                -TestId "HC-001" `
                -HostName $DC01 `
                -Category "AD" `
                -Check "Domain" `
                -Expected $DomainName `
                -Actual $Domain.DNSRoot `
                -Status "CRITICAL" `
                -Interpretation "Unexpected AD domain"
        }
    }
```

---

# 08.101 - Example Check : Expected DCs

```powershell
Invoke-SafeCheck `
    -TestId "HC-003" `
    -HostName $DC01 `
    -Category "AD" `
    -Check "Expected Domain Controllers" `
    -ScriptBlock {

        $Expected = @(
            "$DC01.$DomainName",
            "$DC02.$DomainName"
        )

        $Actual = @(
            Get-ADDomainController `
                -Filter * `
                -ErrorAction Stop |
            Select-Object `
                -ExpandProperty HostName
        )

        $Missing = @(
            $Expected |
            Where-Object {
                $_ -notin $Actual
            }
        )

        if ($Missing.Count -eq 0) {

            Add-HealthResult `
                -TestId "HC-003" `
                -HostName $DC01 `
                -Category "AD" `
                -Check "Expected Domain Controllers" `
                -Expected ($Expected -join ", ") `
                -Actual ($Actual -join ", ") `
                -Status "OK" `
                -Interpretation "DC01 and DC02 detected"
        }
        else {

            Add-HealthResult `
                -TestId "HC-003" `
                -HostName $DC01 `
                -Category "AD" `
                -Check "Expected Domain Controllers" `
                -Expected ($Expected -join ", ") `
                -Actual ("Missing: " + ($Missing -join ", ")) `
                -Status "CRITICAL" `
                -Interpretation "Expected DC missing"
        }
    }
```

---

# 08.102 - Example Check : Direct DNS

```powershell
foreach ($DnsTarget in @(
    @{
        Name = $DC01
        IP   = $DC01IP
        ID   = "HC-020"
    },
    @{
        Name = $DC02
        IP   = $DC02IP
        ID   = "HC-021"
    }
)) {

    Invoke-SafeCheck `
        -TestId $DnsTarget.ID `
        -HostName $DnsTarget.Name `
        -Category "DNS" `
        -Check "Direct DNS Query" `
        -ScriptBlock {

            $Answer = Resolve-DnsName `
                "$DC01.$DomainName" `
                -Server $DnsTarget.IP `
                -ErrorAction Stop

            Add-HealthResult `
                -TestId $DnsTarget.ID `
                -HostName $DnsTarget.Name `
                -Category "DNS" `
                -Check "Direct DNS Query" `
                -Expected "DNS response" `
                -Actual "Query succeeded via $($DnsTarget.IP)" `
                -Status "OK" `
                -Interpretation "DNS server answered directly"
        }
}
```

---

# 08.103 - Example Check : DHCP Service Both Partners

```powershell
foreach ($DhcpServer in @(
    @{
        Name = $DC01
        ID   = "HC-031"
    },
    @{
        Name = $DC02
        ID   = "HC-032"
    }
)) {

    Invoke-SafeCheck `
        -TestId $DhcpServer.ID `
        -HostName $DhcpServer.Name `
        -Category "DHCP" `
        -Check "DHCP Service" `
        -ScriptBlock {

            $Service = Get-Service `
                -ComputerName $DhcpServer.Name `
                -Name DHCPServer `
                -ErrorAction Stop

            $Status = if (
                $Service.Status -eq "Running"
            ) {
                "OK"
            }
            else {
                "CRITICAL"
            }

            Add-HealthResult `
                -TestId $DhcpServer.ID `
                -HostName $DhcpServer.Name `
                -Category "DHCP" `
                -Check "DHCP Service" `
                -Expected "Running" `
                -Actual $Service.Status `
                -Status $Status `
                -Interpretation "DHCP service state"
        }
}
```

---

# 08.104 - Example Check : DHCP Capacity

```powershell
Invoke-SafeCheck `
    -TestId "HC-038" `
    -HostName $DC01 `
    -Category "DHCP" `
    -Check "Scope Capacity" `
    -ScriptBlock {

        $Stats = Get-DhcpServerv4ScopeStatistics `
            -ComputerName $DC01 `
            -ScopeId $ScopeId `
            -ErrorAction Stop

        $Usage = [double]$Stats.PercentageInUse

        if ($Usage -ge $DhcpCriticalPercent) {
            $Status = "CRITICAL"
        }
        elseif ($Usage -ge $DhcpWarningPercent) {
            $Status = "WARNING"
        }
        else {
            $Status = "OK"
        }

        Add-HealthResult `
            -TestId "HC-038" `
            -HostName $DC01 `
            -Category "DHCP" `
            -Check "Scope Capacity" `
            -Expected "< $DhcpWarningPercent% preferred" `
            -Actual "$Usage% used" `
            -Status $Status `
            -Interpretation "DHCP utilization threshold"
    }
```

---

# 08.105 - Example Check : FILE01 Shares

```powershell
Invoke-SafeCheck `
    -TestId "HC-048" `
    -HostName $FileServer `
    -Category "FILE01" `
    -Check "Expected Shares" `
    -ScriptBlock {

        $ExpectedShares = @(
            "IT$",
            "HR$",
            "Finance$",
            "Marketing$",
            "Sales$",
            "Public$"
        )

        $ActualShares = @(
            Invoke-Command `
                -ComputerName $FileServer `
                -ScriptBlock {
                    Get-SmbShare |
                        Select-Object `
                            -ExpandProperty Name
                } `
                -ErrorAction Stop
        )

        $Missing = @(
            $ExpectedShares |
            Where-Object {
                $_ -notin $ActualShares
            }
        )

        if ($Missing.Count -eq 0) {
            $Status = "OK"
            $Actual = "All expected shares present"
        }
        else {
            $Status = "CRITICAL"
            $Actual = "Missing: $($Missing -join ', ')"
        }

        Add-HealthResult `
            -TestId "HC-048" `
            -HostName $FileServer `
            -Category "FILE01" `
            -Check "Expected Shares" `
            -Expected ($ExpectedShares -join ", ") `
            -Actual $Actual `
            -Status $Status `
            -Interpretation "Expected SMB share inventory"
    }
```

---

# 08.106 - Example Check : Disk Space

```powershell
Invoke-SafeCheck `
    -TestId "HC-055" `
    -HostName $FileServer `
    -Category "STORAGE" `
    -Check "Disk Space" `
    -ScriptBlock {

        $Volumes = @(
            Invoke-Command `
                -ComputerName $FileServer `
                -ScriptBlock {
                    Get-Volume |
                        Where-Object DriveLetter |
                        Select-Object `
                            DriveLetter,
                            HealthStatus,
                            Size,
                            SizeRemaining
                } `
                -ErrorAction Stop
        )

        foreach ($Volume in $Volumes) {

            if ($Volume.Size -le 0) {
                continue
            }

            $FreePercent = [math]::Round(
                ($Volume.SizeRemaining / $Volume.Size) * 100,
                2
            )

            if (
                $Volume.HealthStatus -ne "Healthy" -or
                $FreePercent -lt $DiskCriticalPercent
            ) {
                $Status = "CRITICAL"
            }
            elseif ($FreePercent -lt $DiskWarningPercent) {
                $Status = "WARNING"
            }
            else {
                $Status = "OK"
            }

            Add-HealthResult `
                -TestId "HC-055" `
                -HostName $FileServer `
                -Category "STORAGE" `
                -Check "Disk $($Volume.DriveLetter):" `
                -Expected "Healthy and >= $DiskWarningPercent% free preferred" `
                -Actual "$FreePercent% free / $($Volume.HealthStatus)" `
                -Status $Status `
                -Interpretation "Volume health and capacity"
        }
    }
```

---

# 08.107 - Example Check : WIN11 Secure Channel

```powershell
Invoke-SafeCheck `
    -TestId "HC-069" `
    -HostName $Client `
    -Category "WIN11" `
    -Check "Secure Channel" `
    -ScriptBlock {

        $Healthy = Invoke-Command `
            -ComputerName $Client `
            -ScriptBlock {
                Test-ComputerSecureChannel
            } `
            -ErrorAction Stop

        if ($Healthy) {
            $Status = "OK"
        }
        else {
            $Status = "CRITICAL"
        }

        Add-HealthResult `
            -TestId "HC-069" `
            -HostName $Client `
            -Category "WIN11" `
            -Check "Secure Channel" `
            -Expected "True" `
            -Actual "$Healthy" `
            -Status $Status `
            -Interpretation "Domain trust relationship"
    }
```

---

# 08.108 - Result Display

```powershell
$Results |
    Sort-Object `
        Category,
        TestId |
    Format-Table `
        TestId,
        Host,
        Category,
        Check,
        Status,
        Actual `
        -AutoSize
```

---

# 08.109 - Status Counts

```powershell
$Critical = @(
    $Results |
        Where-Object Status -eq "CRITICAL"
).Count

$Warnings = @(
    $Results |
        Where-Object Status -eq "WARNING"
).Count

$Unknown = @(
    $Results |
        Where-Object Status -eq "UNKNOWN"
).Count
```

---

# 08.110 - Exit Code Model

```text
0 → HEALTHY
1 → WARNING / UNKNOWN
2 → CRITICAL
```

Règle :

```powershell
if ($Critical -gt 0) {

    $ExitCode = 2
    $Overall = "CRITICAL"

}
elseif (
    $Warnings -gt 0 -or
    $Unknown -gt 0
) {

    $ExitCode = 1
    $Overall = "WARNING"

}
else {

    $ExitCode = 0
    $Overall = "HEALTHY"
}
```

---

# 08.111 - Why UNKNOWN Is Not HEALTHY

```text
CHECK FAILED TO RUN
        ↓
NO ACTUAL STATE
        ↓
UNKNOWN
```

Le script ne doit jamais produire :

```text
HEALTHY
```

si des contrôles importants sont `UNKNOWN`.

---

# 08.112 - CSV Reporting

```powershell
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$ReportDirectory = `
    "C:\SysAdminToolkit\08-HealthCheck\Reports"

New-Item `
    -Path $ReportDirectory `
    -ItemType Directory `
    -Force |
    Out-Null

$Results |
    Export-Csv `
        -Path "$ReportDirectory\HealthCheck-$Timestamp.csv" `
        -NoTypeInformation `
        -Encoding UTF8
```

---

# 08.113 - History

```text
Reports
 │
 ├── HealthCheck-YYYYMMDD-HHMMSS.csv
 ├── HealthCheck-YYYYMMDD-HHMMSS.csv
 └── ...
```

Permet :

```text
CURRENT
+
PREVIOUS
=
TREND
```

---

# 08.114 - Healthy State Test

Après validation manuelle de chaque dépendance :

```powershell
.\Invoke-InfrastructureHealthCheck.ps1
```

Puis :

```powershell
$LASTEXITCODE
```

Seulement si :

```text
Critical = 0
Warning  = 0
Unknown  = 0
```

alors :

```text
HEALTHY
Exit 0
```

---

# 08.126 - Final Architecture

```text
                         DC01
                          │
                HEALTH CHECK ENGINE
                          │
       ┌──────────────────┼───────────────────┐
       │                  │                   │
       ▼                  ▼                   ▼
     DC02               FILE01              WIN11
       │                  │                   │
       ▼                  ▼                   ▼
  AD / DNS / DHCP     SMB / FSRM         GPO / Security
  Replication         Storage            Domain
  FSMO                Backup             Kerberos
       │                  │                   │
       └──────────────────┼───────────────────┘
                          │
                          ▼
                     STATUS ENGINE
                          │
              ┌───────────┼───────────┐
              │           │           │
              ▼           ▼           ▼
             OK        WARNING     CRITICAL
                          │
                          ▼
                       UNKNOWN
                          │
                          ▼
                     INVESTIGATE
                          │
                          ▼
                        RETEST
                          │
                          ▼
                       EVIDENCE
                          │
                          ▼
                      VALIDATION
```
