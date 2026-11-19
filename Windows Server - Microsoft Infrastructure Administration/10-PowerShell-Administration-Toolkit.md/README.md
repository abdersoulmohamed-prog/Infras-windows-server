# PHASE 10 - POWERSHELL ADMINISTRATION TOOLKIT

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

# 10.0 - Objective

L'objectif n'est pas de créer une collection de scripts indépendants.

Le toolkit doit devenir une couche opérationnelle réutilisable autour des phases précédentes :

```text
                         SYSADMIN TOOLKIT
                                │
         ┌──────────────────────┼──────────────────────┐
         │                      │                      │
         ▼                      ▼                      ▼
   HEALTH CHECK            AD OPERATIONS          INVENTORY
         │                      │                      │
         │                 HELPDESK ACTIONS            │
         │                      │                      │
         └───────────────┬──────┴──────┬───────────────┘
                         │             │
                         ▼             ▼
                    BACKUP CHECK   COMMON MODULE
                         │             │
                         └──────┬──────┘
                                ▼
                           REPORTING
                                │
                                ▼
                         EXIT CODES / LOGS
                                │
                                ▼
                            EVIDENCE
```

---

## Administrative actions

```text
Helpdesk User Management
```

Ce script peut modifier AD, uniquement avec action explicite.

---

# 10.2 - Toolkit Architecture

Créer :

```powershell
$Root = "C:\SysAdminToolkit"

$Folders = @(
    $Root,
    "$Root\00-Common",
    "$Root\01-HealthCheck",
    "$Root\02-ActiveDirectory",
    "$Root\03-Inventory",
    "$Root\04-Backup",
    "$Root\Config",
    "$Root\Logs",
    "$Root\Reports",
    "$Root\Reports\HealthCheck",
    "$Root\Reports\Inventory",
    "$Root\Reports\Backup"
)

foreach ($Folder in $Folders) {
    New-Item `
        -Path $Folder `
        -ItemType Directory `
        -Force |
        Out-Null
}
```

Architecture finale :

```text
C:\SysAdminToolkit
│
├── 00-Common
│   └── SysAdminToolkit.Common.psm1
│
├── 01-HealthCheck
│   └── Invoke-InfrastructureHealthCheck.ps1
│
├── 02-ActiveDirectory
│   └── Helpdesk-UserManagement.ps1
│
├── 03-Inventory
│   └── Get-InfrastructureInventory.ps1
│
├── 04-Backup
│   └── Test-BackupStatus.ps1
│
├── Config
│   └── ToolkitConfig.psd1
│
├── Logs
│   └── Helpdesk-Actions.log
│
└── Reports
    ├── HealthCheck
    ├── Inventory
    └── Backup
```

---

# 10.3 - Naming Convention

Utiliser :

```text
ApprovedVerb-Noun.ps1
```

Exemples :

```text
Invoke-InfrastructureHealthCheck.ps1
Get-InfrastructureInventory.ps1
Test-BackupStatus.ps1
```

Le nom `Helpdesk-UserManagement.ps1` reste acceptable dans ce projet pour conserver la convention déjà utilisée, mais une évolution possible serait :

```text
Invoke-HelpdeskUserAction.ps1
```

---

# 10.4 - Common Configuration

Créer :

```text
C:\SysAdminToolkit\Config\ToolkitConfig.psd1
```

Exemple :

```powershell
@{
    DomainName = "diarabaka.com"

    DomainControllers = @(
        "DC01",
        "DC02"
    )

    DC01IP = "192.168.1.10"
    DC02IP = "192.168.1.11"

    FileServer = "FILE01"

    Client = "WIN11"

    DhcpScope = "192.168.1.0"

    DhcpWarningPercent = 80
    DhcpCriticalPercent = 90

    DiskWarningPercent = 20
    DiskCriticalPercent = 10

    ReportRoot = "C:\SysAdminToolkit\Reports"

    LogRoot = "C:\SysAdminToolkit\Logs"
}
```

Principe :

```text
CONFIGURATION
      ≠
SCRIPT LOGIC
```

---

# 10.5 - Common Module

Créer :

```text
C:\SysAdminToolkit\00-Common\
SysAdminToolkit.Common.psm1
```

Objectifs :

```text
Shared result object
Shared logging
Shared prerequisite checks
Shared export logic
Shared exit code logic
```

---

# 10.6 - Structured Result Model

Chaque check doit produire un objet structuré.

```powershell
function New-ToolkitResult {

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

    [PSCustomObject]@{
        TestId         = $TestId
        Timestamp      = Get-Date
        Host           = $HostName
        Category       = $Category
        Check          = $Check
        Expected       = $Expected
        Actual         = $Actual
        Status         = $Status
        Interpretation = $Interpretation
    }
}
```

---

# 10.7 - Status Model

Utiliser :

```text
OK
WARNING
CRITICAL
UNKNOWN
```

Éviter de mélanger :

```text
PASS
FAIL
WARN
INFO
```

avec un autre modèle dans les scripts.

Règle :

```text
UNKNOWN
   ≠
OK
```

---

# 10.8 - Exit Code Model

```text
0 → HEALTHY
1 → WARNING / UNKNOWN
2 → CRITICAL
```

Exemple :

```powershell
function Get-ToolkitExitCode {

    param(
        [Parameter(Mandatory)]
        [object[]]$Results
    )

    $Critical = @(
        $Results |
            Where-Object Status -eq "CRITICAL"
    ).Count

    $Warning = @(
        $Results |
            Where-Object Status -eq "WARNING"
    ).Count

    $Unknown = @(
        $Results |
            Where-Object Status -eq "UNKNOWN"
    ).Count

    if ($Critical -gt 0) {
        return 2
    }

    if (
        $Warning -gt 0 -or
        $Unknown -gt 0
    ) {
        return 1
    }

    return 0
}
```

---

# 10.9 - Export Model

Chaque script doit pouvoir exporter :

```text
Human-readable text
CSV
JSON
```

Exemple :

```powershell
$Results |
    Export-Csv `
        -Path $CsvPath `
        -NoTypeInformation `
        -Encoding UTF8

$Results |
    ConvertTo-Json `
        -Depth 5 |
    Set-Content `
        -Path $JsonPath `
        -Encoding UTF8
```

---

# 10.10 - Execution Context

Le toolkit doit être exécuté depuis un poste ou serveur autorisé.

Prérequis possibles :

```text
PowerShell
RSAT Active Directory
RSAT DNS
RSAT DHCP
PowerShell Remoting
Network connectivity
Delegated rights
```

Important :

```text
NOT EVERY SCRIPT NEEDS EVERY MODULE
```

---

# 10.11 - Per-Script Module Validation

Créer :

```powershell
function Test-RequiredModule {

    param(
        [Parameter(Mandatory)]
        [string[]]$Name
    )

    foreach ($ModuleName in $Name) {

        if (
            -not (
                Get-Module `
                    -ListAvailable `
                    -Name $ModuleName
            )
        ) {
            throw "Required module missing: $ModuleName"
        }
    }
}
```

Exemple Health Check :

```powershell
Test-RequiredModule `
    -Name @(
        "ActiveDirectory",
        "DnsServer",
        "DhcpServer"
    )
```

Inventaire :

```powershell
Test-RequiredModule `
    -Name @(
        "ActiveDirectory"
    )
```

---

# 10.12 - SCRIPT 01 - Infrastructure Health Check

Fichier :

```text
C:\SysAdminToolkit\01-HealthCheck\
Invoke-InfrastructureHealthCheck.ps1
```

Objectif :

```text
AD
DC01
DC02
Global Catalog
FSMO
Replication
DNS
DHCP
Failover
FILE01
SMB
Storage
FSRM
Backup
WIN11
Security
```

Ce script est :

```text
READ-ONLY
```

---

# 10.13 - Health Check Parameters

```powershell
[CmdletBinding()]
param(
    [string]$ConfigPath = `
        "C:\SysAdminToolkit\Config\ToolkitConfig.psd1"
)

$ErrorActionPreference = "Stop"

$Config = Import-PowerShellDataFile `
    -Path $ConfigPath

$DomainName = $Config.DomainName
$DC01 = $Config.DomainControllers[0]
$DC02 = $Config.DomainControllers[1]
$DC01IP = $Config.DC01IP
$DC02IP = $Config.DC02IP
$FileServer = $Config.FileServer
$Client = $Config.Client
$ScopeId = $Config.DhcpScope
```

---

# 10.14 - Health Check Result Collection

```powershell
$Results = [System.Collections.Generic.List[object]]::new()
```

---

# 10.15 - AD Domain Check

```powershell
try {

    $Domain = Get-ADDomain `
        -Identity $DomainName `
        -ErrorAction Stop

    if ($Domain.DNSRoot -eq $DomainName) {

        $Results.Add(
            (
                New-ToolkitResult `
                    -TestId "PS-010" `
                    -HostName $DC01 `
                    -Category "AD" `
                    -Check "Domain" `
                    -Expected $DomainName `
                    -Actual $Domain.DNSRoot `
                    -Status "OK" `
                    -Interpretation "Expected AD domain detected"
            )
        )
    }
    else {

        $Results.Add(
            (
                New-ToolkitResult `
                    -TestId "PS-010" `
                    -HostName $DC01 `
                    -Category "AD" `
                    -Check "Domain" `
                    -Expected $DomainName `
                    -Actual $Domain.DNSRoot `
                    -Status "CRITICAL" `
                    -Interpretation "Unexpected AD domain"
            )
        )
    }
}
catch {

    $Results.Add(
        (
            New-ToolkitResult `
                -TestId "PS-010" `
                -HostName $DC01 `
                -Category "AD" `
                -Check "Domain" `
                -Expected $DomainName `
                -Actual $_.Exception.Message `
                -Status "UNKNOWN" `
                -Interpretation "Domain check could not be evaluated"
        )
    )
}
```

---

# 10.16 - Expected Domain Controllers

Ne pas utiliser :

```text
DC count >= 2
```

comme seul critère.

Utiliser :

```powershell
$ExpectedDCs = @(
    "$DC01.$DomainName",
    "$DC02.$DomainName"
)

$ActualDCs = @(
    Get-ADDomainController -Filter * |
        Select-Object -ExpandProperty HostName
)

$MissingDCs = @(
    $ExpectedDCs |
        Where-Object {
            $_ -notin $ActualDCs
        }
)
```

---

# 10.17 - Global Catalog

```powershell
foreach ($DCName in @(
    $DC01,
    $DC02
)) {

    try {

        $DC = Get-ADDomainController `
            -Identity $DCName `
            -ErrorAction Stop

        $Status = if (
            $DC.IsGlobalCatalog
        ) {
            "OK"
        }
        else {
            "WARNING"
        }

        $Results.Add(
            (
                New-ToolkitResult `
                    -TestId "PS-GC-$DCName" `
                    -HostName $DCName `
                    -Category "AD" `
                    -Check "Global Catalog" `
                    -Expected "True" `
                    -Actual "$($DC.IsGlobalCatalog)" `
                    -Status $Status `
                    -Interpretation "Global Catalog state"
            )
        )
    }
    catch {

        $Results.Add(
            (
                New-ToolkitResult `
                    -TestId "PS-GC-$DCName" `
                    -HostName $DCName `
                    -Category "AD" `
                    -Check "Global Catalog" `
                    -Expected "True" `
                    -Actual $_.Exception.Message `
                    -Status "UNKNOWN" `
                    -Interpretation "GC check failed"
            )
        )
    }
}
```

---

# 10.18 - FSMO Inventory

```powershell
try {

    $Forest = Get-ADForest `
        -ErrorAction Stop

    $Domain = Get-ADDomain `
        -ErrorAction Stop

    $Fsmo = @(
        $Forest.SchemaMaster,
        $Forest.DomainNamingMaster,
        $Domain.PDCEmulator,
        $Domain.RIDMaster,
        $Domain.InfrastructureMaster
    )

    $Results.Add(
        (
            New-ToolkitResult `
                -TestId "PS-015" `
                -HostName $DC01 `
                -Category "FSMO" `
                -Check "FSMO Roles" `
                -Expected "5 role holders identified" `
                -Actual ($Fsmo -join ", ") `
                -Status "OK" `
                -Interpretation "FSMO holders retrieved"
        )
    )
}
catch {

    $Results.Add(
        (
            New-ToolkitResult `
                -TestId "PS-015" `
                -HostName $DC01 `
                -Category "FSMO" `
                -Check "FSMO Roles" `
                -Expected "5 role holders identified" `
                -Actual $_.Exception.Message `
                -Status "UNKNOWN" `
                -Interpretation "FSMO inventory failed"
        )
    )
}
```

---

# 10.19 - Replication Principle

Ne pas utiliser :

```text
repadmin exit code = 0
```

comme preuve suffisante.

Contrôles minimum :

```text
repadmin /replsummary
repadmin /showrepl DC01
repadmin /showrepl DC02
dcdiag /test:replications
```

---

# 10.20 - Replication Summary Collection

```powershell
$ReplicationSummary = & repadmin /replsummary 2>&1
$ReplicationExitCode = $LASTEXITCODE
```

Puis conserver la sortie complète dans le rapport brut.

Important :

```text
COMMAND COMPLETED
      ≠
0 REPLICATION FAILURES
```

La logique d'analyse doit chercher les échecs réels dans la sortie ou conserver le résultat en `UNKNOWN` si l'analyse automatisée ne peut pas être fiable.

---

# 10.21 - Replication Conservative Logic

Exemple conservateur :

```powershell
if ($ReplicationExitCode -ne 0) {

    $ReplicationStatus = "CRITICAL"

}
elseif (
    ($ReplicationSummary -join "`n") -match `
    "fails:\s*[1-9]"
) {

    $ReplicationStatus = "CRITICAL"

}
else {

    $ReplicationStatus = "UNKNOWN"
}
```

Puis :

```text
UNKNOWN
=
Manual review still required
```

Ce modèle évite un faux `OK`.

---

# 10.22 - Repadmin Showrepl

```powershell
$ShowReplDC01 = & repadmin /showrepl $DC01 2>&1
$ShowReplDC02 = & repadmin /showrepl $DC02 2>&1
```

Exporter les deux sorties.

---

# 10.23 - DCDIAG Replication

```powershell
$DcdiagReplication = `
    & dcdiag /test:replications 2>&1
```

Collecter :

```text
Raw output
Exit code
Manual interpretation
```

---

# 10.24 - DNS Direct Test

Éviter de résoudre le nom du DNS pour obtenir son IP avant de tester ce même DNS.

Utiliser :

```powershell
$DnsServers = @(
    @{
        Name = $DC01
        IP   = $DC01IP
    },
    @{
        Name = $DC02
        IP   = $DC02IP
    }
)
```

Puis :

```powershell
foreach ($DnsServer in $DnsServers) {

    try {

        Resolve-DnsName `
            "_ldap._tcp.dc._msdcs.$DomainName" `
            -Type SRV `
            -Server $DnsServer.IP `
            -ErrorAction Stop |
            Out-Null

        $Status = "OK"
        $Actual = "Direct SRV query succeeded"
    }
    catch {

        $Status = "CRITICAL"
        $Actual = $_.Exception.Message
    }

    $Results.Add(
        (
            New-ToolkitResult `
                -TestId "PS-DNS-$($DnsServer.Name)" `
                -HostName $DnsServer.Name `
                -Category "DNS" `
                -Check "Direct LDAP SRV Query" `
                -Expected "SRV response" `
                -Actual $Actual `
                -Status $Status `
                -Interpretation "Direct DNS server validation"
        )
    )
}
```

---

# 10.25 - DNS Internal Records

```powershell
$InternalQueries = @(
    $DomainName,
    "$DC01.$DomainName",
    "$DC02.$DomainName",
    "$FileServer.$DomainName"
)

foreach ($Query in $InternalQueries) {

    try {

        Resolve-DnsName `
            -Name $Query `
            -ErrorAction Stop |
            Out-Null

        $Status = "OK"
        $Actual = "Resolved"
    }
    catch {

        $Status = "CRITICAL"
        $Actual = $_.Exception.Message
    }
}
```

---

# 10.26 - DNS SRV Tests

```powershell
$SrvQueries = @(
    "_ldap._tcp.dc._msdcs.$DomainName",
    "_kerberos._tcp.$DomainName"
)
```

Chaque requête doit être testée.

---

# 10.27 - DCDIAG DNS

```powershell
$DcdiagDns = & dcdiag /test:dns 2>&1
```

Règle :

```text
OUTPUT COLLECTED
      ≠
DNS HEALTH CONFIRMED
```

---

# 10.28 - DHCP Services Both Partners

```powershell
foreach ($Server in @(
    $DC01,
    $DC02
)) {

    try {

        $Service = Get-Service `
            -ComputerName $Server `
            -Name DHCPServer `
            -ErrorAction Stop

        if ($Service.Status -eq "Running") {
            $Status = "OK"
        }
        else {
            $Status = "CRITICAL"
        }

        $Results.Add(
            (
                New-ToolkitResult `
                    -TestId "PS-DHCP-SVC-$Server" `
                    -HostName $Server `
                    -Category "DHCP" `
                    -Check "DHCP Service" `
                    -Expected "Running" `
                    -Actual "$($Service.Status)" `
                    -Status $Status `
                    -Interpretation "DHCP service state"
            )
        )
    }
    catch {

        $Results.Add(
            (
                New-ToolkitResult `
                    -TestId "PS-DHCP-SVC-$Server" `
                    -HostName $Server `
                    -Category "DHCP" `
                    -Check "DHCP Service" `
                    -Expected "Running" `
                    -Actual $_.Exception.Message `
                    -Status "UNKNOWN" `
                    -Interpretation "DHCP service could not be queried"
            )
        )
    }
}
```

---

# 10.29 - DHCP Authorization

```powershell
$AuthorizedDhcp = Get-DhcpServerInDC
```

Comparer explicitement avec :

```text
DC01
DC02
```

---

# 10.30 - DHCP Scope Both Partners

```powershell
foreach ($Server in @(
    $DC01,
    $DC02
)) {

    try {

        $Scope = Get-DhcpServerv4Scope `
            -ComputerName $Server `
            -ScopeId $ScopeId `
            -ErrorAction Stop

        $Status = if (
            $Scope.State -eq "Active"
        ) {
            "OK"
        }
        else {
            "CRITICAL"
        }

    }
    catch {

        $Status = "UNKNOWN"
    }
}
```

---

# 10.31 - DHCP Capacity

```powershell
$Statistics = `
    Get-DhcpServerv4ScopeStatistics `
        -ComputerName $DC01 `
        -ScopeId $ScopeId
```

Thresholds :

```text
< 80%  → OK
80-90% → WARNING
>=90%  → CRITICAL
```

---

# 10.32 - DHCP Failover Bilateral

DC01 :

```powershell
$FailoverDC01 = `
    Get-DhcpServerv4Failover `
        -ComputerName $DC01 `
        -ScopeId $ScopeId
```

DC02 :

```powershell
$FailoverDC02 = `
    Get-DhcpServerv4Failover `
        -ComputerName $DC02 `
        -ScopeId $ScopeId
```

Vérifier :

```text
PartnerServer
Mode
State
LoadBalancePercent
ScopeId
MaxClientLeadTime
```

Ne pas considérer seulement :

```text
State = Normal
```

---

# 10.33 - FILE01 SMB Service

```powershell
$SmbService = Get-Service `
    -ComputerName $FileServer `
    -Name LanmanServer
```

---

# 10.34 - Expected Shares

Ne pas seulement compter les shares.

```powershell
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
                    Name,
                    Path,
                    FolderEnumerationMode,
                    EncryptData
        }
)

$ActualNames = $ActualShares.Name

$MissingShares = @(
    $ExpectedShares |
        Where-Object {
            $_ -notin $ActualNames
        }
)
```

---

# 10.35 - AGDLP Resource Groups

Depuis AD :

```powershell
$ExpectedResourceGroups = @(
    "DL-FS-IT-Modify",
    "DL-FS-HR-Modify",
    "DL-FS-Finance-Modify",
    "DL-FS-Marketing-Modify",
    "DL-FS-Sales-Modify",
    "DL-FS-Public-Modify"
)
```

Vérifier leur existence.

---

# 10.36 - SMB ACL Review

Sur FILE01 :

```powershell
Invoke-Command `
    -ComputerName $FileServer `
    -ScriptBlock {

        foreach ($Share in @(
            "IT$",
            "HR$",
            "Finance$",
            "Marketing$",
            "Sales$",
            "Public$"
        )) {

            Get-SmbShareAccess `
                -Name $Share
        }
    }
```

Comparer au modèle AGDLP.

---

# 10.37 - Discover FILE01 Paths

```powershell
$SharePaths = @(
    Invoke-Command `
        -ComputerName $FileServer `
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
)
```

Ne pas coder :

```text
D:\Shares
E:\Shares
```

---

# 10.38 - NTFS ACL Collection

```powershell
Invoke-Command `
    -ComputerName $FileServer `
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

            Write-Output `
                "===== $($Share.Name) ====="

            icacls $Share.Path
        }
    }
```

---

# 10.39 - FILE01 Storage

```powershell
$Volumes = @(
    Invoke-Command `
        -ComputerName $FileServer `
        -ScriptBlock {

            Get-Volume |
                Where-Object DriveLetter |
                Select-Object `
                    DriveLetter,
                    FileSystemLabel,
                    HealthStatus,
                    Size,
                    SizeRemaining
        }
)
```

---

# 10.40 - Storage Thresholds

```text
Free >= 20% → OK
Free 10-20% → WARNING
Free < 10%  → CRITICAL
```

Ces seuils sont configurables.

---

# 10.41 - FSRM Inventory

```powershell
$FsrmQuotas = @(
    Invoke-Command `
        -ComputerName $FileServer `
        -ScriptBlock {

            Get-FsrmQuota |
                Select-Object `
                    Path,
                    Size,
                    Usage,
                    Disabled,
                    SoftLimit
        }
)
```

Ne pas utiliser :

```text
quota count > 0
```

comme preuve suffisante.

---

# 10.42 - Backup Inventory

```powershell
$BackupOutput = Invoke-Command `
    -ComputerName $FileServer `
    -ScriptBlock {
        wbadmin get versions
    }
```

---

# 10.43 - Backup Rule

```text
BACKUP VERSION EXISTS
        ≠
RESTORE VALIDATED
```

Le script doit reporter :

```text
Backup inventory
Backup version
Backup age if parsed reliably
Backup target if available
Restore validation status
```

Si pas de preuve de restore :

```text
RestoreValidation = UNKNOWN
```

---

# 10.44 - WIN11 Domain State

```powershell
$ClientState = Get-CimInstance `
    -ComputerName $Client `
    -ClassName Win32_ComputerSystem
```

Vérifier :

```text
PartOfDomain
Domain
```

---

# 10.45 - WIN11 DNS

```powershell
Invoke-Command `
    -ComputerName $Client `
    -ScriptBlock {

        Get-DnsClientServerAddress `
            -AddressFamily IPv4
    }
```

---

# 10.46 - WIN11 DC Locator

```powershell
Invoke-Command `
    -ComputerName $Client `
    -ScriptBlock {

        nltest /dsgetdc:diarabaka.com
    }
```

---

# 10.47 - WIN11 Secure Channel

```powershell
$SecureChannel = Invoke-Command `
    -ComputerName $Client `
    -ScriptBlock {

        Test-ComputerSecureChannel
    }
```

---

# 10.48 - WIN11 Security

Defender :

```powershell
Invoke-Command `
    -ComputerName $Client `
    -ScriptBlock {

        Get-MpComputerStatus |
            Select-Object `
                AntivirusEnabled,
                RealTimeProtectionEnabled
    }
```

Firewall :

```powershell
Invoke-Command `
    -ComputerName $Client `
    -ScriptBlock {

        Get-NetFirewallProfile |
            Select-Object `
                Name,
                Enabled
    }
```

BitLocker :

```powershell
Invoke-Command `
    -ComputerName $Client `
    -ScriptBlock {

        Get-BitLockerVolume `
            -MountPoint "C:"
    }
```

---

# 10.49 - Health Check Final Export

```powershell
$RunId = Get-Date `
    -Format "yyyyMMdd-HHmmss"

$ReportRoot = `
    Join-Path `
        $Config.ReportRoot `
        "HealthCheck"

New-Item `
    -Path $ReportRoot `
    -ItemType Directory `
    -Force |
    Out-Null

$CsvPath = Join-Path `
    $ReportRoot `
    "HealthCheck-$RunId.csv"

$JsonPath = Join-Path `
    $ReportRoot `
    "HealthCheck-$RunId.json"

$TxtPath = Join-Path `
    $ReportRoot `
    "HealthCheck-$RunId.txt"
```

---

# 10.50 - Health Check Human Report

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
        -AutoSize |
    Out-String |
    Set-Content `
        -Path $TxtPath `
        -Encoding UTF8
```

---

# 10.51 - Health Check Machine Reports

```powershell
$Results |
    Export-Csv `
        -Path $CsvPath `
        -NoTypeInformation `
        -Encoding UTF8

$Results |
    ConvertTo-Json `
        -Depth 5 |
    Set-Content `
        -Path $JsonPath `
        -Encoding UTF8
```

---

# 10.52 - Health Check Exit

```powershell
$ExitCode = `
    Get-ToolkitExitCode `
        -Results $Results

exit $ExitCode
```

---

# 10.53 - Health Check Read-Only Guarantee

Le script ne doit pas appeler :

```powershell
Restart-Service
Stop-Service
Start-Service
Set-AD*
Set-DnsServer*
Set-DhcpServer*
repadmin /syncall
gpupdate /force
Unlock-ADAccount
Remove-Item
```

Règle :

```text
DETECT
REPORT
EXIT
```

---

# 10.54 - SCRIPT 02 - Helpdesk User Management

Fichier :

```text
C:\SysAdminToolkit\02-ActiveDirectory\
Helpdesk-UserManagement.ps1
```

Actions :

```text
UserInfo
Unlock
ResetPassword
ExpirePassword
Disable
Enable
```

---

# 10.55 - Helpdesk Parameters

```powershell
[CmdletBinding(
    SupportsShouldProcess = $true,
    ConfirmImpact = "Medium"
)]
param(

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Username,

    [Parameter(Mandatory)]
    [ValidateSet(
        "UserInfo",
        "Unlock",
        "ResetPassword",
        "ExpirePassword",
        "Disable",
        "Enable"
    )]
    [string]$Action,

    [string]$PreferredDC,

    [string]$LogPath = `
        "C:\SysAdminToolkit\Logs"
)

Import-Module ActiveDirectory `
    -ErrorAction Stop
```

---

# 10.56 - Preferred DC Logic

Pour les opérations sensibles, il peut être utile de connaître le DC utilisé.

Exemple :

```powershell
if ($PreferredDC) {

    $Server = $PreferredDC

}
else {

    $Server = (
        Get-ADDomainController `
            -Discover `
            -Writable
    ).HostName
}
```

Documenter :

```text
Target DC
```

dans les logs.

---

# 10.57 - Validate User

```powershell
try {

    $User = Get-ADUser `
        -Identity $Username `
        -Server $Server `
        -Properties `
            Enabled,
            LockedOut,
            PasswordExpired,
            PasswordLastSet,
            LastLogonDate `
        -ErrorAction Stop
}
catch {

    Write-Error "User not found: $Username"
    exit 1
}
```

---

# 10.58 - Helpdesk Logging

```powershell
function Write-AdminLog {

    param(
        [string]$Operation,
        [string]$Result,
        [string]$Detail = ""
    )

    $Entry = "{0};{1};{2};{3};{4};{5};{6}" -f `
        (Get-Date -Format "yyyy-MM-dd HH:mm:ss"),
        $env:USERNAME,
        $env:COMPUTERNAME,
        $Username,
        $Operation,
        $Result,
        $Server

    Add-Content `
        -Path (
            Join-Path `
                $LogPath `
                "Helpdesk-Actions.log"
        ) `
        -Value $Entry
}
```

Ne jamais écrire le secret.

---

# 10.59 - Helpdesk Log States

Valeurs :

```text
REQUESTED
WHATIF
SUCCESS
NOT_REQUIRED
FAILED
VALIDATION_FAILED
```

---

# 10.60 - UserInfo

```powershell
switch ($Action) {

    "UserInfo" {

        $User |
            Select-Object `
                SamAccountName,
                Enabled,
                LockedOut,
                PasswordExpired,
                PasswordLastSet,
                LastLogonDate

        Write-AdminLog `
            -Operation "UserInfo" `
            -Result "SUCCESS"
    }
}
```

---

# 10.61 - Unlock

```powershell
"Unlock" {

    if (-not $User.LockedOut) {

        Write-Host `
            "Account is not locked: $Username"

        Write-AdminLog `
            -Operation "Unlock" `
            -Result "NOT_REQUIRED"

        break
    }

    if (
        $PSCmdlet.ShouldProcess(
            $Username,
            "Unlock AD account"
        )
    ) {

        try {

            Unlock-ADAccount `
                -Identity $User `
                -Server $Server `
                -ErrorAction Stop

            $Check = Get-ADUser `
                -Identity $Username `
                -Server $Server `
                -Properties LockedOut

            if (-not $Check.LockedOut) {

                Write-AdminLog `
                    -Operation "Unlock" `
                    -Result "SUCCESS"

            }
            else {

                Write-AdminLog `
                    -Operation "Unlock" `
                    -Result "VALIDATION_FAILED"

                throw "Account remains locked."
            }
        }
        catch {

            Write-AdminLog `
                -Operation "Unlock" `
                -Result "FAILED"

            throw
        }
    }
    else {

        Write-AdminLog `
            -Operation "Unlock" `
            -Result "WHATIF"
    }
}
```

---

# 10.62 - Reset Password

```powershell
"ResetPassword" {

    $Password = Read-Host `
        "Temporary password" `
        -AsSecureString

    if (
        $PSCmdlet.ShouldProcess(
            $Username,
            "Reset AD password"
        )
    ) {

        try {

            $Before = Get-ADUser `
                -Identity $Username `
                -Server $Server `
                -Properties PasswordLastSet

            Set-ADAccountPassword `
                -Identity $User `
                -Server $Server `
                -Reset `
                -NewPassword $Password `
                -ErrorAction Stop

            Set-ADUser `
                -Identity $User `
                -Server $Server `
                -ChangePasswordAtLogon $true `
                -ErrorAction Stop

            $After = Get-ADUser `
                -Identity $Username `
                -Server $Server `
                -Properties `
                    PasswordLastSet,
                    PasswordExpired

            Write-Host `
                "Password reset accepted by AD on $Server."

            Write-Host `
                "Password change required at next logon."

            Write-AdminLog `
                -Operation "ResetPassword" `
                -Result "SUCCESS"
        }
        catch {

            Write-AdminLog `
                -Operation "ResetPassword" `
                -Result "FAILED"

            throw
        }
    }
    else {

        Write-AdminLog `
            -Operation "ResetPassword" `
            -Result "WHATIF"
    }
}
```

---

# 10.63 - Password Reset Validation Rule

Important :

```text
SET-ADACCOUNTPASSWORD SUCCEEDED
         ≠
WINDOWS 11 LOGON VALIDATED
```

Le script peut valider :

```text
Operation accepted by target DC
User object still accessible
Password policy flag updated
```

Mais la validation finale nécessite :

```text
Real user authentication test
```

---

# 10.64 - Password / DC / Replication Diagnostic

Si le mot de passe fonctionne avec une commande directe mais pas via WIN11 :

```text
Which DC accepted the reset?
Which DC authenticated WIN11?
Is the user object current on both DCs?
Is AD replication healthy?
Is WIN11 using internal DNS?
Is DC Locator selecting expected DC?
Is secure channel healthy?
Is the login online or cached?
Is ChangePasswordAtLogon involved?
```

Commandes utiles :

```powershell
nltest /dsgetdc:diarabaka.com
```

Puis :

```powershell
repadmin /replsummary
```

Puis :

```powershell
repadmin /showrepl DC01
repadmin /showrepl DC02
```

Ne pas accuser automatiquement la réplication sans preuve.

---

# 10.65 - Expire Password

```powershell
"ExpirePassword" {

    if (
        $PSCmdlet.ShouldProcess(
            $Username,
            "Require password change at next logon"
        )
    ) {

        Set-ADUser `
            -Identity $User `
            -Server $Server `
            -ChangePasswordAtLogon $true `
            -ErrorAction Stop

        Write-AdminLog `
            -Operation "ExpirePassword" `
            -Result "SUCCESS"
    }
    else {

        Write-AdminLog `
            -Operation "ExpirePassword" `
            -Result "WHATIF"
    }
}
```

---

# 10.66 - Disable

```powershell
"Disable" {

    if (-not $User.Enabled) {

        Write-AdminLog `
            -Operation "Disable" `
            -Result "NOT_REQUIRED"

        break
    }

    if (
        $PSCmdlet.ShouldProcess(
            $Username,
            "Disable AD account"
        )
    ) {

        Disable-ADAccount `
            -Identity $User `
            -Server $Server `
            -ErrorAction Stop

        $Check = Get-ADUser `
            -Identity $Username `
            -Server $Server

        if (-not $Check.Enabled) {

            Write-AdminLog `
                -Operation "Disable" `
                -Result "SUCCESS"

        }
        else {

            Write-AdminLog `
                -Operation "Disable" `
                -Result "VALIDATION_FAILED"

            throw "Disable validation failed."
        }
    }
    else {

        Write-AdminLog `
            -Operation "Disable" `
            -Result "WHATIF"
    }
}
```

---

# 10.67 - Enable

```powershell
"Enable" {

    if ($User.Enabled) {

        Write-AdminLog `
            -Operation "Enable" `
            -Result "NOT_REQUIRED"

        break
    }

    if (
        $PSCmdlet.ShouldProcess(
            $Username,
            "Enable AD account"
        )
    ) {

        Enable-ADAccount `
            -Identity $User `
            -Server $Server `
            -ErrorAction Stop

        $Check = Get-ADUser `
            -Identity $Username `
            -Server $Server

        if ($Check.Enabled) {

            Write-AdminLog `
                -Operation "Enable" `
                -Result "SUCCESS"

        }
        else {

            Write-AdminLog `
                -Operation "Enable" `
                -Result "VALIDATION_FAILED"

            throw "Enable validation failed."
        }
    }
    else {

        Write-AdminLog `
            -Operation "Enable" `
            -Result "WHATIF"
    }
}
```

---

# 10.68 - WhatIf

```powershell
.\Helpdesk-UserManagement.ps1 `
    -Username jdupont `
    -Action Disable `
    -WhatIf
```

Attendu :

```text
No modification
Log = WHATIF
```

---

# 10.69 - Helpdesk Usage

Read-only :

```powershell
.\Helpdesk-UserManagement.ps1 `
    -Username jdupont `
    -Action UserInfo
```

Unlock :

```powershell
.\Helpdesk-UserManagement.ps1 `
    -Username jdupont `
    -Action Unlock
```

Password reset :

```powershell
.\Helpdesk-UserManagement.ps1 `
    -Username jdupont `
    -Action ResetPassword
```

Disable :

```powershell
.\Helpdesk-UserManagement.ps1 `
    -Username jdupont `
    -Action Disable `
    -Confirm
```

---

# 10.70 - SCRIPT 03 - Infrastructure Inventory

Fichier :

```text
C:\SysAdminToolkit\03-Inventory\
Get-InfrastructureInventory.ps1
```

Objectif :

```text
DISCOVER
   ↓
STRUCTURE
   ↓
EXPORT
   ↓
COMPARE
```

Read-only.

---

# 10.71 - Inventory Parameters

```powershell
[CmdletBinding()]
param(
    [string]$ConfigPath = `
        "C:\SysAdminToolkit\Config\ToolkitConfig.psd1"
)

Import-Module ActiveDirectory `
    -ErrorAction Stop

$Config = Import-PowerShellDataFile `
    -Path $ConfigPath

$Timestamp = Get-Date `
    -Format "yyyyMMdd-HHmmss"

$OutputPath = Join-Path `
    $Config.ReportRoot `
    "Inventory\$Timestamp"

New-Item `
    -Path $OutputPath `
    -ItemType Directory `
    -Force |
    Out-Null
```

---

# 10.72 - Computer Inventory

```powershell
$Computers = Get-ADComputer `
    -Filter * `
    -Properties `
        OperatingSystem,
        OperatingSystemVersion,
        IPv4Address,
        Enabled,
        LastLogonDate,
        DistinguishedName

$Computers |
    Select-Object `
        Name,
        OperatingSystem,
        OperatingSystemVersion,
        IPv4Address,
        Enabled,
        LastLogonDate,
        DistinguishedName |
    Export-Csv `
        "$OutputPath\Computers.csv" `
        -NoTypeInformation `
        -Encoding UTF8
```

---

# 10.73 - Server Inventory

```powershell
$Servers = Get-ADComputer `
    -Filter 'OperatingSystem -like "*Server*"' `
    -Properties `
        OperatingSystem,
        OperatingSystemVersion,
        IPv4Address,
        Enabled,
        LastLogonDate,
        DistinguishedName
```

---

# 10.74 - User Inventory

```powershell
$Users = Get-ADUser `
    -Filter * `
    -Properties `
        Enabled,
        Department,
        Title,
        PasswordLastSet,
        LastLogonDate,
        DistinguishedName
```

Exporter :

```text
Name
SamAccountName
UPN
Enabled
Department
Title
PasswordLastSet
LastLogonDate
DistinguishedName
```

---

# 10.75 - Group Inventory

```powershell
$Groups = Get-ADGroup `
    -Filter * `
    -Properties Description
```

Exporter :

```text
Name
GroupScope
GroupCategory
Description
DistinguishedName
```

---

# 10.76 - Domain Controller Inventory

```powershell
$DomainControllers = `
    Get-ADDomainController `
        -Filter *
```

Exporter :

```text
HostName
IPv4Address
Site
IsGlobalCatalog
IsReadOnly
```

---

# 10.77 - OU Inventory

```powershell
$OUs = Get-ADOrganizationalUnit `
    -Filter * |
    Select-Object `
        Name,
        DistinguishedName
```

Permet de confirmer notamment :

```text
OU=Diarabaka
OU=Users
OU=Groups
OU=Computers
OU=Servers
OU=Admins
OU=Service Accounts
```

---

# 10.78 - Resource Group Inventory

```powershell
Get-ADGroup `
    -SearchBase `
        "OU=Resources,OU=Groups,OU=Diarabaka,DC=diarabaka,DC=com" `
    -Filter * |
    Select-Object `
        Name,
        GroupScope,
        GroupCategory
```

---

# 10.79 - Inventory Summary

```powershell
$Summary = [PSCustomObject]@{
    Timestamp         = Get-Date
    Computers         = @($Computers).Count
    Servers           = @($Servers).Count
    Users             = @($Users).Count
    Groups            = @($Groups).Count
    DomainControllers = @($DomainControllers).Count
    OUs               = @($OUs).Count
}
```

---

# 10.80 - Inventory Caveat

`IPv4Address` dans AD :

```text
Useful
```

mais pas forcément :

```text
Authoritative CMDB source
```

Le rapport doit le signaler.

---

# 10.81 - SCRIPT 04 - Backup Status

Fichier :

```text
C:\SysAdminToolkit\04-Backup\
Test-BackupStatus.ps1
```

Objectif :

```text
FEATURE
 ↓
BACKUP INVENTORY
 ↓
LATEST VERSION
 ↓
TARGET
 ↓
RECENCY
 ↓
RESTORE STATUS
 ↓
REPORT
```

---

# 10.82 - Backup Parameters

```powershell
[CmdletBinding()]
param(
    [string]$ComputerName = "FILE01",

    [string]$ConfigPath = `
        "C:\SysAdminToolkit\Config\ToolkitConfig.psd1"
)

$Config = Import-PowerShellDataFile `
    -Path $ConfigPath
```

---

# 10.83 - Backup Feature

```powershell
$Feature = Invoke-Command `
    -ComputerName $ComputerName `
    -ScriptBlock {

        Get-WindowsFeature `
            Windows-Server-Backup
    }
```

---

# 10.84 - Backup Service Context

```powershell
$Service = Get-Service `
    -ComputerName $ComputerName `
    -Name wbengine `
    -ErrorAction SilentlyContinue
```

Important :

```text
wbengine stopped
      ≠
backup broken
```

---

# 10.85 - Backup Versions

```powershell
$Versions = Invoke-Command `
    -ComputerName $ComputerName `
    -ScriptBlock {

        wbadmin get versions
    }
```

---

# 10.86 - Backup Levels

```text
LEVEL 1
Feature present

LEVEL 2
Backup version exists

LEVEL 3
Backup age acceptable

LEVEL 4
Backup content accessible

LEVEL 5
Controlled restore succeeds

LEVEL 6
Restored data integrity validated
```

Le script ne doit pas prétendre au niveau 5 ou 6 sans vraie restauration.

---

# 10.87 - Restore Evidence

Si aucune preuve externe :

```text
RestoreValidation = UNKNOWN
```

Si une preuve Phase 06 existe :

```text
Alternate restore path
SHA256 match
ACL validation
Functional access validation
```

alors seulement la restauration peut être considérée comme validée.

---

# 10.88 - Logging Model

```text
C:\SysAdminToolkit
│
├── Logs
│   └── Helpdesk-Actions.log
│
└── Reports
    ├── HealthCheck
    │   ├── *.txt
    │   ├── *.csv
    │   └── *.json
    ├── Inventory
    │   └── YYYYMMDD-HHMMSS
    └── Backup
        ├── *.txt
        ├── *.csv
        └── *.json
```

---

# 10.89 - Log Security

Le log ne contient jamais :

```text
Password
Recovery Password
LAPS Secret
Credential Object
Token
Private Key
```

---

# 10.90 - Least Privilege

Architecture cible :

```text
READ OPERATOR
   │
   ├── Health Check
   ├── Inventory
   └── Backup Read

HELPDESK
   │
   ├── UserInfo
   ├── Unlock
   ├── ResetPassword
   └── Limited lifecycle actions

PRIVILEGED ADMIN
   │
   └── Restricted high-impact operations
```

Le toolkit n'implique pas :

```text
Daily Domain Admin usage
```

---

# 10.91 - Code Signing Readiness

```powershell
Get-AuthenticodeSignature `
    "C:\SysAdminToolkit\01-HealthCheck\Invoke-InfrastructureHealthCheck.ps1"
```

Lab actuel :

```text
Unsigned controlled scripts
```

Évolution entreprise :

```text
Internal code-signing certificate
Signed releases
Controlled execution policy
Version control
Change approval
```

---

# 10.92 - Versioning

Chaque script :

```powershell
<#
.SYNOPSIS
    DIARABAKA infrastructure tool.

.VERSION
    1.0.0

.NOTES
    Project:
    Windows Server 2025 Enterprise Infrastructure

    Status:
    READY FOR VALIDATION
#>
```

---

# 10.93 - Syntax Validation

Avant exécution :

```powershell
$Errors = $null

[System.Management.Automation.Language.Parser]::ParseFile(
    "C:\Path\Script.ps1",
    [ref]$null,
    [ref]$Errors
) |
Out-Null

$Errors
```

Cible :

```text
No syntax errors
```

---

# 10.94 - PSScriptAnalyzer Readiness

Si disponible :

```powershell
Invoke-ScriptAnalyzer `
    -Path "C:\SysAdminToolkit" `
    -Recurse
```

Ne pas déclarer le script conforme si le module n'est pas installé ou si l'analyse n'a pas été réalisée.

---

# 10.95 - Negative Testing

Tester :

```text
DC02 unreachable
Unknown AD user
Invalid DHCP scope
FILE01 unreachable
WIN11 unreachable
Missing module
No backup available
WinRM unavailable
Insufficient rights
Unexpected share missing
Replication command error
```

---

# 10.96 - Error Classification

Distinguer :

```text
HOST DOWN
REMOTE MANAGEMENT UNAVAILABLE
COMMAND FAILED
CHECK UNKNOWN
SERVICE UNHEALTHY
CONFIGURATION UNEXPECTED
```

Ne pas tout convertir en :

```text
FAIL
```

---

# 10.97 - WhatIf Validation

Exemple :

```powershell
.\Helpdesk-UserManagement.ps1 `
    -Username jdupont `
    -Action Disable `
    -WhatIf
```

Puis vérifier :

```text
AD object unchanged
Log = WHATIF
```

---

# 10.98 - Health Check Negative Test

Exemple contrôlé :

```text
Stop one isolated lab service
Run health check
Expect CRITICAL
Restore service
Run health check
Expect baseline restored
```

Ne pas provoquer plusieurs pannes simultanément.

---

# 10.99 - Backup Negative Test

Exemple :

```text
Invalid ComputerName
```

Attendu :

```text
Clear UNKNOWN / error
No false OK
```

---

# 10.100 - Inventory Negative Test

Exemple :

```text
Missing ActiveDirectory module
```

Attendu :

```text
Controlled stop
Clear message
No partial report marked successful
```
