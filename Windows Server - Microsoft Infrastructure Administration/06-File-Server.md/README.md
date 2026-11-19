# PHASE 06 - FILE SERVER

## Windows Server 2025 Enterprise Infrastructure

**Project:** Windows Server 2025 Enterprise Infrastructure  
**Domain:** `diarabaka.com`  
**File Server:** `FILE01`  
**Clients:** Windows 11 domain members  
**Platform:** VMware  
**Professional Domain:** Microsoft Infrastructure

---

# 06.0 - Objectif

Mettre en place un serveur de fichiers Windows dédié permettant de centraliser les données métiers et de contrôler les accès à partir d'Active Directory.

---

# 06.2 - Evidence Pack

Sur `FILE01` :

```powershell
$EvidenceRoot = "C:\Evidence\FileServer"

$Folders = @(
    "01-Baseline",
    "02-Network",
    "03-Storage",
    "04-AD-Groups",
    "05-AGDLP",
    "06-SMB",
    "07-NTFS",
    "08-Access-Tests",
    "09-SMB-Security",
    "10-FSRM",
    "11-Capacity",
    "12-Backup",
    "13-Restore",
    "14-Logs",
    "15-Incidents",
    "16-Post-Reboot",
    "17-Final-Regression"
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

# 06.3 - Baseline FILE01

Sur `FILE01` :

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

Puis :

```powershell
(Get-CimInstance Win32_ComputerSystem).Domain
```

Cible :

```text
FILE01
diarabaka.com
```

---

# 06.4 - Vérifier l'objet AD FILE01

Depuis DC01 :

```powershell
Get-ADComputer FILE01 |
    Select-Object `
        Name,
        DistinguishedName,
        Enabled
```

Placement cible selon l'architecture AD :

```text
OU=File Servers,OU=Servers,OU=Diarabaka,DC=diarabaka,DC=com
```

---

# 06.5 - Vérifier le réseau FILE01

```powershell
Get-NetIPAddress `
    -AddressFamily IPv4 |
    Where-Object {
        $_.IPAddress -notlike "169.254*" -and
        $_.IPAddress -ne "127.0.0.1"
    } |
    Select-Object `
        IPAddress,
        PrefixLength,
        InterfaceAlias
```

Puis :

```powershell
Get-NetIPConfiguration
```

Documenter :

```text
IPv4
Prefix
Gateway
DNS Servers
```

Ne pas inventer l'IP de FILE01.

---

# 06.6 - DNS et Active Directory Connectivity

```powershell
Resolve-DnsName diarabaka.com
Resolve-DnsName DC01
Resolve-DnsName DC02
```

Puis :

```powershell
Test-NetConnection DC01 -Port 53
Test-NetConnection DC01 -Port 389
```

Puis :

```powershell
nltest /dsgetdc:diarabaka.com
```

---

# 06.7 - Installer File Server Role

Vérifier :

```powershell
Get-WindowsFeature FS-FileServer
```

Si nécessaire :

```powershell
Install-WindowsFeature `
    FS-FileServer `
    -IncludeManagementTools
```

Puis :

```powershell
Get-Service LanmanServer
```

Cible :

```text
FS-FileServer : Installed
LanmanServer  : Running
```

---

# 06.8 - Découvrir le stockage réel

Ne pas supposer `D:` ou `E:`.

```powershell
Get-Disk |
    Select-Object `
        Number,
        FriendlyName,
        OperationalStatus,
        HealthStatus,
        PartitionStyle,
        Size
```

Puis :

```powershell
Get-Volume |
    Select-Object `
        DriveLetter,
        FileSystemLabel,
        FileSystem,
        HealthStatus,
        Size,
        SizeRemaining
```

Décision :

```text
DATA VOLUME CONFIRMED?
      ↓
YES → define <FILE01_DATA_PATH>
NO  → STOP and determine storage design
```

---

# 06.9 - Variables de stockage

Une fois la lettre réelle confirmée :

```powershell
$DataRoot = "<FILE01_DATA_PATH>"
$SharesRoot = Join-Path $DataRoot "Shares"
```

Exemple uniquement si la réalité confirme `E:` :

```powershell
$DataRoot = "E:\"
$SharesRoot = "E:\Shares"
```

---

# 06.10 - Architecture stockage

Architecture cible :

```text
C:\
 └── Windows Server

<FILE01_DATA_PATH>
 └── Shares
      ├── Departments
      │    ├── IT
      │    ├── HR
      │    ├── Finance
      │    ├── Marketing
      │    └── Sales
      │
      └── Public
```

Le volume data doit être séparé logiquement du système.

---

# 06.11 - Créer l'arborescence

```powershell
$Folders = @(
    "$SharesRoot\Departments\IT",
    "$SharesRoot\Departments\HR",
    "$SharesRoot\Departments\Finance",
    "$SharesRoot\Departments\Marketing",
    "$SharesRoot\Departments\Sales",
    "$SharesRoot\Public"
)

foreach ($Folder in $Folders) {
    New-Item `
        -Path $Folder `
        -ItemType Directory `
        -Force |
        Out-Null
}
```

Vérifier :

```powershell
Get-ChildItem `
    $SharesRoot `
    -Directory `
    -Recurse |
    Select-Object FullName
```

---

# 06.12 - Modèle AGDLP

Le modèle principal de cette phase est :

```text
Accounts
   ↓
Global Groups
   ↓
Domain Local Groups
   ↓
Permissions
```

Department groups :

```text
GG-IT
GG-HR
GG-Finance
GG-Marketing
GG-Sales
```

Resource groups :

```text
DL-FS-IT-Modify
DL-FS-HR-Modify
DL-FS-Finance-Modify
DL-FS-Marketing-Modify
DL-FS-Sales-Modify
DL-FS-Public-Modify
```

---

# 06.13 - Vérifier Department Groups

Depuis DC01 :

```powershell
$DepartmentGroups = @(
    "GG-IT",
    "GG-HR",
    "GG-Finance",
    "GG-Marketing",
    "GG-Sales"
)

foreach ($Group in $DepartmentGroups) {
    Get-ADGroup $Group |
        Select-Object `
            Name,
            GroupScope,
            GroupCategory,
            DistinguishedName
}
```

Cible :

```text
GroupScope : Global
```

---

# 06.14 - Créer / vérifier Resource Groups

Placement canonique :

```text
OU=Resources,OU=Groups,OU=Diarabaka,DC=diarabaka,DC=com
```

Variables :

```powershell
$DomainDN = "DC=diarabaka,DC=com"
$ResourceOU = "OU=Resources,OU=Groups,OU=Diarabaka,$DomainDN"
```

Resource groups :

```powershell
$ResourceGroups = @(
    "DL-FS-IT-Modify",
    "DL-FS-HR-Modify",
    "DL-FS-Finance-Modify",
    "DL-FS-Marketing-Modify",
    "DL-FS-Sales-Modify",
    "DL-FS-Public-Modify"
)
```

Créer seulement si absents :

```powershell
foreach ($Group in $ResourceGroups) {

    if (-not (Get-ADGroup -Filter "SamAccountName -eq '$Group'")) {

        New-ADGroup `
            -Name $Group `
            -SamAccountName $Group `
            -GroupScope DomainLocal `
            -GroupCategory Security `
            -Path $ResourceOU
    }
}
```

---

# 06.15 - Vérifier Resource Groups

```powershell
foreach ($Group in $ResourceGroups) {
    Get-ADGroup $Group |
        Select-Object `
            Name,
            GroupScope,
            GroupCategory,
            DistinguishedName
}
```

Cible :

```text
GroupScope : DomainLocal
```

---

# 06.16 - Nesting AGDLP

Configurer :

```powershell
Add-ADGroupMember `
    -Identity "DL-FS-IT-Modify" `
    -Members "GG-IT"

Add-ADGroupMember `
    -Identity "DL-FS-HR-Modify" `
    -Members "GG-HR"

Add-ADGroupMember `
    -Identity "DL-FS-Finance-Modify" `
    -Members "GG-Finance"

Add-ADGroupMember `
    -Identity "DL-FS-Marketing-Modify" `
    -Members "GG-Marketing"

Add-ADGroupMember `
    -Identity "DL-FS-Sales-Modify" `
    -Members "GG-Sales"
```

Pour Public :

```powershell
Add-ADGroupMember `
    -Identity "DL-FS-Public-Modify" `
    -Members "Domain Users"
```

Seulement si ce design est réellement voulu.

---

# 06.17 - Vérifier le nesting

```powershell
Get-ADGroupMember "DL-FS-HR-Modify"
Get-ADGroupMember "DL-FS-IT-Modify"
Get-ADGroupMember "DL-FS-Finance-Modify"
Get-ADGroupMember "DL-FS-Marketing-Modify"
Get-ADGroupMember "DL-FS-Sales-Modify"
Get-ADGroupMember "DL-FS-Public-Modify"
```

Chaîne :

```text
USER
 ↓
GG
 ↓
DL
 ↓
PERMISSION
```

---

# 06.18 - Créer les partages SMB

Les partages :

```text
IT$
HR$
Finance$
Marketing$
Sales$
Public$
```

Le suffixe `$` signifie uniquement :

```text
Hidden Share
```

Il ne remplace pas les permissions.

---

# 06.19 - Vérifier les partages existants

```powershell
$ShareNames = @(
    "IT$",
    "HR$",
    "Finance$",
    "Marketing$",
    "Sales$",
    "Public$"
)

foreach ($Name in $ShareNames) {
    Get-SmbShare `
        -Name $Name `
        -ErrorAction SilentlyContinue
}
```

Règle :

```text
EXISTS → AUDIT
MISSING → CREATE
```

---

# 06.20 - Créer IT$

```powershell
New-SmbShare `
    -Name "IT$" `
    -Path "$SharesRoot\Departments\IT" `
    -Description "IT Department Share" `
    -FullAccess "DIARABAKA\DL-FS-IT-Modify" `
    -FolderEnumerationMode AccessBased
```

---

# 06.21 - Créer HR$

```powershell
New-SmbShare `
    -Name "HR$" `
    -Path "$SharesRoot\Departments\HR" `
    -Description "HR Department Share" `
    -FullAccess "DIARABAKA\DL-FS-HR-Modify" `
    -FolderEnumerationMode AccessBased
```

---

# 06.22 - Créer Finance$

```powershell
New-SmbShare `
    -Name "Finance$" `
    -Path "$SharesRoot\Departments\Finance" `
    -Description "Finance Department Share" `
    -FullAccess "DIARABAKA\DL-FS-Finance-Modify" `
    -FolderEnumerationMode AccessBased
```

---

# 06.23 - Créer Marketing$

```powershell
New-SmbShare `
    -Name "Marketing$" `
    -Path "$SharesRoot\Departments\Marketing" `
    -Description "Marketing Department Share" `
    -FullAccess "DIARABAKA\DL-FS-Marketing-Modify" `
    -FolderEnumerationMode AccessBased
```

---

# 06.24 - Créer Sales$

```powershell
New-SmbShare `
    -Name "Sales$" `
    -Path "$SharesRoot\Departments\Sales" `
    -Description "Sales Department Share" `
    -FullAccess "DIARABAKA\DL-FS-Sales-Modify" `
    -FolderEnumerationMode AccessBased
```

---

# 06.25 - Créer Public$

```powershell
New-SmbShare `
    -Name "Public$" `
    -Path "$SharesRoot\Public" `
    -Description "Public Collaboration Share" `
    -FullAccess "DIARABAKA\DL-FS-Public-Modify" `
    -FolderEnumerationMode AccessBased
```

---

# 06.26 - Vérifier SMB shares

```powershell
Get-SmbShare |
    Where-Object {
        $_.Name -in $ShareNames
    } |
    Select-Object `
        Name,
        Path,
        Description,
        FolderEnumerationMode,
        EncryptData
```

---

# 06.27 - Vérifier SMB permissions

```powershell
foreach ($Share in $ShareNames) {

    Write-Host "`n===== $Share ====="

    Get-SmbShareAccess `
        -Name $Share
}
```

Ne pas supposer qu'aucune ACE inattendue n'existe.

---

# 06.28 - Share Permission Model

Modèle choisi :

```text
DL RESOURCE GROUP
       ↓
SMB Full
       ↓
NTFS Modify
       ↓
Effective Modify
```

Le contrôle fin reste sur NTFS.

---

# 06.29 - NTFS Administrative Baseline

Avant ajout des groupes métier, examiner les ACL :

```powershell
icacls "$SharesRoot\Departments\HR"
```

Les principals administratifs attendus peuvent inclure :

```text
SYSTEM
BUILTIN\Administrators
```

Ne pas les supprimer sans justification.

---

# 06.30 - NTFS HR

```powershell
icacls "$SharesRoot\Departments\HR" `
    /grant "DIARABAKA\DL-FS-HR-Modify:(OI)(CI)(M)"
```

---

# 06.31 - NTFS IT

```powershell
icacls "$SharesRoot\Departments\IT" `
    /grant "DIARABAKA\DL-FS-IT-Modify:(OI)(CI)(M)"
```

---

# 06.32 - NTFS Finance

```powershell
icacls "$SharesRoot\Departments\Finance" `
    /grant "DIARABAKA\DL-FS-Finance-Modify:(OI)(CI)(M)"
```

---

# 06.33 - NTFS Marketing

```powershell
icacls "$SharesRoot\Departments\Marketing" `
    /grant "DIARABAKA\DL-FS-Marketing-Modify:(OI)(CI)(M)"
```

---

# 06.34 - NTFS Sales

```powershell
icacls "$SharesRoot\Departments\Sales" `
    /grant "DIARABAKA\DL-FS-Sales-Modify:(OI)(CI)(M)"
```

---

# 06.35 - NTFS Public

```powershell
icacls "$SharesRoot\Public" `
    /grant "DIARABAKA\DL-FS-Public-Modify:(OI)(CI)(M)"
```

Le design `Public Modify` signifie espace collaboratif partagé.

Si le besoin futur est :

```text
user can create own file
but cannot modify others
```

il faudra une ACL plus fine.

---

# 06.36 - Vérifier ACL

```powershell
$DepartmentFolders = @(
    "IT",
    "HR",
    "Finance",
    "Marketing",
    "Sales"
)

foreach ($Folder in $DepartmentFolders) {

    Write-Host "`n===== $Folder ====="

    icacls "$SharesRoot\Departments\$Folder"
}
```

Puis :

```powershell
icacls "$SharesRoot\Public"
```

---

# 06.37 - SMB + NTFS Effective Access

Exemple :

```text
SMB Full
   +
NTFS Modify
   =
Effective Modify
```

Autre exemple :

```text
SMB Full
   +
NTFS Read
   =
Effective Read
```

Le test client reste l'autorité finale.

---

# 06.38 - Access-Based Enumeration

Vérifier :

```powershell
Get-SmbShare |
    Where-Object {
        $_.Name -in $ShareNames
    } |
    Select-Object `
        Name,
        FolderEnumerationMode
```

Cible si design retenu :

```text
AccessBased
```

ABE masque les éléments auxquels l'utilisateur n'a pas accès, mais ne remplace pas les ACL.

---

# 06.39 - SMB Security Baseline

```powershell
Get-SmbServerConfiguration |
    Select-Object `
        EnableSMB1Protocol,
        EnableSMB2Protocol,
        EnableSecuritySignature,
        RequireSecuritySignature,
        EncryptData
```

Cible minimale :

```text
SMB1   : Disabled / not required
SMB2/3 : Enabled
```

Signing et encryption doivent être audités et interprétés selon le design.

---

# 06.40 - SMB Encryption Review

Par partage :

```powershell
Get-SmbShare |
    Where-Object {
        $_.Name -in $ShareNames
    } |
    Select-Object `
        Name,
        EncryptData
```

Ne pas forcer l'encryption partout sans analyse.

Pour des données sensibles, on peut décider :

```text
HR
Finance
```

→ encryption requise, mais seulement après validation du besoin et de la compatibilité.

---

# 06.41 - SMB Session / Dialect Review

Depuis FILE01 :

```powershell
Get-SmbSession |
    Select-Object `
        ClientComputerName,
        ClientUserName,
        NumOpens,
        Dialect,
        Encrypted
```

Cela permet d'observer le dialecte et l'état de chiffrement des sessions réellement actives.

---

# 06.42 - Test positif HR

Utiliser un compte réellement membre de :

```text
GG-HR
```

Sur WIN11 :

```powershell
whoami
whoami /groups
```

Vérifier que le token contient les appartenances pertinentes.

---

# 06.43 - Renouveler le token après changement de groupe

Si l'utilisateur vient d'être ajouté à un groupe :

```text
SIGN OUT
   ↓
SIGN IN
   ↓
whoami /groups
```

`klist purge` n'est pas un remplacement général du renouvellement du logon token.

---

# 06.44 - Test SMB connectivity

```powershell
Test-NetConnection FILE01 -Port 445
```

Cible :

```text
TcpTestSucceeded : True
```

---

# 06.45 - Test HR read/write/delete

```powershell
Test-Path "\\FILE01\HR$"
```

Puis :

```powershell
"FILE01 HR WRITE TEST" |
    Out-File "\\FILE01\HR$\test.txt"
```

Puis :

```powershell
"SECOND LINE" |
    Add-Content "\\FILE01\HR$\test.txt"
```

Puis :

```powershell
Get-Content "\\FILE01\HR$\test.txt"
```

Puis :

```powershell
Remove-Item "\\FILE01\HR$\test.txt"
```

Enfin :

```powershell
Test-Path "\\FILE01\HR$\test.txt"
```

---

# 06.46 - Test négatif explicite HR → Finance

Ne pas utiliser uniquement `Test-Path`.

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

Attendu :

```text
Access is denied
```

ou équivalent selon la langue du système.

---

# 06.47 - Test négatif HR → IT

```powershell
try {

    Get-ChildItem "\\FILE01\IT$" `
        -ErrorAction Stop

    Write-Host "UNEXPECTED ACCESS"

}
catch {

    $_.Exception.Message
}
```

---

# 06.48 - Test négatif HR → Marketing

```powershell
try {

    Get-ChildItem "\\FILE01\Marketing$" `
        -ErrorAction Stop

    Write-Host "UNEXPECTED ACCESS"

}
catch {

    $_.Exception.Message
}
```

---

# 06.49 - Test négatif HR → Sales

```powershell
try {

    Get-ChildItem "\\FILE01\Sales$" `
        -ErrorAction Stop

    Write-Host "UNEXPECTED ACCESS"

}
catch {

    $_.Exception.Message
}
```

---

# 06.50 - Test Public

```powershell
Test-Path "\\FILE01\Public$"
```

Puis :

```powershell
"PUBLIC TEST" |
    Out-File "\\FILE01\Public$\public-test.txt"
```

Puis suppression contrôlée :

```powershell
Remove-Item "\\FILE01\Public$\public-test.txt"
```

---

# 06.51 - Matrice d'accès

| Profile        |    HR$ | Finance$ |    IT$ | Marketing$ | Sales$ | Public$ |
| -------------- | -----: | -------: | -----: | ---------: | -----: | ------: |
| `GG-HR`        | Modify |   Denied | Denied |     Denied | Denied |  Modify |
| `GG-Finance`   | Denied |   Modify | Denied |     Denied | Denied |  Modify |
| `GG-IT`        | Denied |   Denied | Modify |     Denied | Denied |  Modify |
| `GG-Marketing` | Denied |   Denied | Denied |     Modify | Denied |  Modify |
| `GG-Sales`     | Denied |   Denied | Denied |     Denied | Modify |  Modify |

---

# 06.52 - Sessions SMB

```powershell
Get-SmbSession
```

Fichiers ouverts :

```powershell
Get-SmbOpenFile
```

Ne pas utiliser :

```powershell
Close-SmbOpenFile
```

ou fermeture de session sans impact analysis.

---

# 06.53 - Installer FSRM

```powershell
Get-WindowsFeature FS-Resource-Manager
```

Si nécessaire :

```powershell
Install-WindowsFeature `
    FS-Resource-Manager `
    -IncludeManagementTools
```

Puis :

```powershell
Get-WindowsFeature FS-Resource-Manager
```

---

# 06.54 - FSRM Quota Strategy

Valeur lab :

```text
5 GB
```

Type choisi pour le lab :

```text
Hard Quota
```

Cette valeur n'est pas une recommandation universelle de production.

---

# 06.55 - Vérifier les quotas existants

```powershell
Get-FsrmQuota |
    Select-Object `
        Path,
        Size,
        Usage,
        SoftLimit,
        Description
```

Règle :

```text
EXISTS → AUDIT
MISSING → CREATE
```

---

# 06.56 - Créer quotas départementaux

```powershell
$QuotaPaths = @(
    "$SharesRoot\Departments\IT",
    "$SharesRoot\Departments\HR",
    "$SharesRoot\Departments\Finance",
    "$SharesRoot\Departments\Marketing",
    "$SharesRoot\Departments\Sales"
)

foreach ($Path in $QuotaPaths) {

    if (-not (Get-FsrmQuota -Path $Path -ErrorAction SilentlyContinue)) {

        New-FsrmQuota `
            -Path $Path `
            -Size 5GB `
            -Description "Department hard quota - 5 GB"
    }
}
```

---

# 06.57 - Vérifier hard/soft quota

```powershell
Get-FsrmQuota |
    Select-Object `
        Path,
        Size,
        Usage,
        SoftLimit,
        Description
```

Cible :

```text
SoftLimit : False
```

pour un hard quota.

---

# 06.58 - FSRM Threshold Review

Documenter une stratégie de thresholds :

```text
80%
90%
100%
```

---

# 06.59 - File Screening Review

Lister :

```powershell
Get-FsrmFileGroup
```

Ne pas bloquer arbitrairement :

```text
.exe
.zip
.iso
```

sans besoin métier.

---

# 06.60 - Capacity Monitoring

Utiliser le volume réellement confirmé.

```powershell
$DataDriveLetter = "<ACTUAL_DATA_DRIVE_LETTER>"

Get-Volume `
    -DriveLetter $DataDriveLetter |
    Select-Object `
        DriveLetter,
        HealthStatus,
        Size,
        SizeRemaining
```

Puis :

```powershell
Get-FsrmQuota |
    Select-Object `
        Path,
        Size,
        Usage,
        SoftLimit
```

---

# 06.61 - Capacity Percent

```powershell
Get-Volume `
    -DriveLetter $DataDriveLetter |
    Select-Object `
        DriveLetter,
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
            Name = "UsedPercent"
            Expression = {
                [math]::Round(
                    (($_.Size - $_.SizeRemaining) / $_.Size) * 100,
                    2
                )
            }
        }
```

---

# 06.62 - Installer Windows Server Backup

```powershell
Get-WindowsFeature Windows-Server-Backup
```

Si nécessaire :

```powershell
Install-WindowsFeature `
    Windows-Server-Backup
```

Puis :

```powershell
Get-WindowsFeature Windows-Server-Backup
```

---

# 06.63 - Backup Architecture

Ne jamais utiliser :

```text
SOURCE = E:
TARGET = E:
```

Architecture correcte :

```text
FILE01
│
├── C: OS
│
└── <FILE01_DATA_PATH>
    └── Shares

SEPARATE BACKUP TARGET
└── <FILE01_BACKUP_TARGET>
```

Le backup target doit être distinct du volume source.

---

# 06.64 - Backup Target Discovery

Vérifier :

```powershell
Get-Volume |
    Select-Object `
        DriveLetter,
        FileSystemLabel,
        FileSystem,
        HealthStatus,
        Size,
        SizeRemaining
```

Définir seulement après preuve :

```powershell
$SharesRoot = "E:\Shares"  # À adapter
$BackupTarget = "F:"
$BackupTarget = "<FILE01_BACKUP_TARGET>"
```

Exemples possibles :

```text
F:
\\BACKUP01\FILE01$
```

---

# 06.65 - Backup Independence Review

Documenter :

```text
Same partition?
Same VMDK?
Separate virtual disk?
Same datastore?
Separate storage?
Off-host?
Immutable?
```

Dans le lab, une deuxième virtual disk peut suffire pour tester la restauration, mais elle ne représente pas forcément un vrai DR backup.

---

# 06.66 - Créer un fichier de test avant backup

```powershell
$BackupTestFile = "$SharesRoot\Departments\HR\Backup-Test.txt"

"TEST BACKUP FILESERVER $(Get-Date -Format o)" |
    Out-File $BackupTestFile

---OU---

$SharesRoot = "E:\Shares"  # À adapter
$BackupTarget = "F:"

$HRFolder = Join-Path $SharesRoot "Departments\HR"
New-Item -Path $HRFolder -ItemType Directory -Force | Out-Null

$BackupTestFile = Join-Path $HRFolder "Backup-Test.txt"
"TEST BACKUP FILESERVER $(Get-Date -Format o)" |
    Out-File -FilePath $BackupTestFile

Get-Item $BackupTestFile
```

Puis :

```powershell
Get-Content $BackupTestFile
```

---

# 06.67 - Hash avant backup

```powershell
$OriginalHash = (
    Get-FileHash `
        $BackupTestFile `
        -Algorithm SHA256
).Hash

$OriginalHash
```

Enregistrer cette valeur dans l'evidence.

---

# 06.68 - ACL avant backup

```powershell
icacls $BackupTestFile
```

Puis :

```powershell
icacls $BackupTestFile `
    /save "C:\Evidence\FileServer\12-Backup\Backup-Test-ACL-Before.txt"
```

---

# 06.69 - Lancer le backup

Si target local distinct :

```powershell
wbadmin start backup `
    -backupTarget:<FILE01_BACKUP_TARGET> `
    -include:<FILE01_DATA_VOLUME> `
    -quiet
```

Exemple uniquement si confirmé :

```text
Data   = E:
Backup = F:
```

alors :

```powershell
wbadmin start backup `
    -backupTarget:F: `
    -include:E: `
    -quiet
```

---

# 06.70 - Vérifier les versions

```powershell
wbadmin get versions
```

Conserver :

```text
Version identifier
Backup target
Backup time
```

---

# 06.71 - Vérifier le contenu backup

```powershell
wbadmin get items `
    -version:<VERSION>
```

---

# 06.72 - Suppression contrôlée

```powershell
Remove-Item $BackupTestFile
```

Puis :

```powershell
Test-Path $BackupTestFile
```

Attendu :

```text
False
```

---

# 06.73 - Restore vers emplacement alternatif

Créer :

```powershell
$RestoreRoot = "C:\Restore-Test"
New-Item `
    -Path $RestoreRoot `
    -ItemType Directory `
    -Force |
    Out-Null
```

Principe :

```text
VERSION
  ↓
ITEM
  ↓
ALTERNATE RESTORE PATH
  ↓
HASH
  ↓
ACL
  ↓
FUNCTIONAL TEST
```

---

# 06.74 - Commande de récupération

Adapter avec la version réelle :

```powershell
wbadmin start recovery `
    -version:<VERSION> `
    -itemType:File `
    -items:"<ORIGINAL_FILE_PATH>" `
    -recoveryTarget:"C:\Restore-Test" `
    -overwrite:CreateCopy
```

La syntaxe exacte du chemin `-items` doit correspondre au backup réellement inventorié.

---

# 06.75 - Vérifier fichier restauré

Identifier le chemin réellement restauré :

```powershell
Get-ChildItem `
    C:\Restore-Test `
    -Recurse
```

Puis :

```powershell
$RestoredFile = "<ACTUAL_RESTORED_FILE_PATH>"
```

---

# 06.76 - Vérifier hash restauré

```powershell
$RestoredHash = (
    Get-FileHash `
        $RestoredFile `
        -Algorithm SHA256
).Hash

$RestoredHash
```

Comparer :

```powershell
$OriginalHash -eq $RestoredHash
```

Cible :

```text
True
```

---

# 06.77 - Vérifier ACL restaurée

```powershell
icacls $RestoredFile
```

Comparer avec l'evidence pré-backup.

Le contenu seul ne suffit pas.

---

# 06.78 - Restore à l'emplacement original

Seulement après validation du restore alternatif et si le test le requiert.

Objectif :

```text
ORIGINAL PATH
+
CONTENT
+
ACL
+
SMB ACCESS
```

Ne pas écraser aveuglément une donnée réelle.

---

# 06.79 - Validation SMB après restore

Depuis WIN11 avec utilisateur HR :

```powershell
Test-Path "\\FILE01\HR$\Backup-Test.txt"
```

Puis :

```powershell
Get-Content "\\FILE01\HR$\Backup-Test.txt"
```

Validation complète :

```text
FILE RESTORED
+
HASH MATCH
+
ACL PRESERVED
+
SMB ACCESS
=
RESTORE VALIDATED
```

---

# 06.80 - Backup Validation Principle

```text
BACKUP COMMAND SUCCESS
      ≠
BACKUP VALIDATED
```

Validation :

```text
BACKUP CREATED
      ↓
VERSION PRESENT
      ↓
CONTENT INVENTORY
      ↓
ALTERNATE RESTORE
      ↓
HASH MATCH
      ↓
ACL VERIFIED
      ↓
SMB FUNCTIONAL ACCESS
      ↓
VALIDATED
```

---

# 06.81 - File Server Logs

Lister :

```powershell
Get-WinEvent -ListLog *SMB*
```

Puis :

```powershell
Get-WinEvent -ListLog *FileServer*
```

Puis :

```powershell
Get-WinEvent -ListLog *Backup*
```

Examiner uniquement les journaux réellement présents.

---

# 06.82 - SMB Server Operational Log

Si présent :

```powershell
Get-WinEvent `
    -LogName "Microsoft-Windows-SMBServer/Operational" `
    -MaxEvents 100 |
    Select-Object `
        TimeCreated,
        Id,
        LevelDisplayName,
        Message
```

---

# 06.83 - Backup Event Review

Lister les canaux disponibles liés au backup puis analyser les événements du test.

Ne pas inventer un nom de journal si le système retourne un autre nom.

---

# 06.84 - Troubleshooting Method

# 06.85 - Incident FS-INC-001 : Access Denied

Sur WIN11 :

```powershell
whoami
whoami /groups
```

Puis :

```powershell
Test-NetConnection FILE01 -Port 445
```

Puis FILE01 :

```powershell
Get-SmbShare -Name "HR$"
Get-SmbShareAccess -Name "HR$"
icacls "$SharesRoot\Departments\HR"
```

Puis DC01 :

```powershell
Get-ADGroupMember "DL-FS-HR-Modify"
Get-ADGroupMember "GG-HR"
```

---

# 06.86 - Incident FS-INC-002 : SMB indisponible

Baseline :

```powershell
Get-Service LanmanServer
```

Controlled lab failure :

```powershell
Stop-Service LanmanServer
```

Depuis WIN11 :

```powershell
Test-NetConnection FILE01 -Port 445
```

Recovery :

```powershell
Start-Service LanmanServer
```

Puis :

```powershell
Test-NetConnection FILE01 -Port 445
Test-Path "\\FILE01\HR$"
```

---

# 06.87 - Incident FS-INC-003 : DNS Failure

```powershell
Resolve-DnsName FILE01
Resolve-DnsName FILE01.diarabaka.com
```

Si IP joignable mais nom non résolu :

```text
NETWORK OK
DNS FAILED
```

Ne pas modifier les ACL.

---

# 06.88 - Incident FS-INC-004 : Capacity

```powershell
Get-Volume `
    -DriveLetter $DataDriveLetter
```

Puis :

```powershell
Get-FsrmQuota |
    Select-Object `
        Path,
        Size,
        Usage,
        SoftLimit
```

Analyser :

```text
Volume full?
Quota reached?
Unexpected growth?
Backup accumulation?
Large files?
```

---

# 06.89 - Incident FS-INC-005 : Locked File

```powershell
Get-SmbOpenFile
```

Puis :

```powershell
Get-SmbSession
```

Identifier :

```text
User
Client
File
Open state
```

Ne fermer qu'après validation de l'impact.

---

# 06.90 - Incident FS-INC-006 : Wrong Group Token

Si le groupe vient d'être modifié :

```text
SIGN OUT
  ↓
SIGN IN
  ↓
whoami /groups
```

Puis retester.

---

# 06.91 - Audit FILE01

```powershell
hostname
Get-WindowsFeature FS-FileServer
Get-Service LanmanServer
Get-Volume
Get-SmbShare
Get-SmbSession
Get-FsrmQuota
wbadmin get versions
```

---

# 06.92 - Audit SMB

```powershell
foreach ($Share in $ShareNames) {

    Write-Host "`n===== $Share ====="

    Get-SmbShare -Name $Share |
        Select-Object `
            Name,
            Path,
            FolderEnumerationMode,
            EncryptData

    Get-SmbShareAccess -Name $Share
}
```

---

# 06.93 - Audit NTFS

```powershell
foreach ($Folder in $DepartmentFolders) {

    Write-Host "`n===== $Folder ====="

    icacls "$SharesRoot\Departments\$Folder"
}
```

Puis :

```powershell
icacls "$SharesRoot\Public"
```

---

# 06.94 - Audit AGDLP

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

    Get-ADGroupMember $DomainLocal
}
```

---

# 06.95 - Post-Reboot Validation FILE01

Avant :

```powershell
Get-Service LanmanServer
Get-SmbShare
Get-Volume
```

Puis :

```powershell
Restart-Computer
```

Après retour :

```powershell
Get-Service LanmanServer
Get-SmbShare
Get-FsrmQuota
```

---

# 06.96 - Post-Reboot Validation WIN11

```powershell
Resolve-DnsName FILE01
Test-NetConnection FILE01 -Port 445
Test-Path "\\FILE01\HR$"
Test-Path "\\FILE01\Public$"
```

Puis un test négatif explicite.

---

# 06.97 - Final Regression

Sur FILE01 :

```powershell
Get-Service LanmanServer

Get-SmbShare |
    Where-Object {
        $_.Name -in $ShareNames
    }

Get-FsrmQuota

wbadmin get versions
```

Depuis WIN11 :

```powershell
Resolve-DnsName FILE01
Test-NetConnection FILE01 -Port 445
```

Puis :

```powershell
Test-Path "\\FILE01\HR$"
Test-Path "\\FILE01\Public$"
```

et tests négatifs des autres départements.

---

# 06.102 - Final Architecture

```text
                         DIARABAKA.COM
                              │
                         Active Directory
                              │
               ┌──────────────┼───────────────┐
               │              │               │
               ▼              ▼               ▼
             GG-HR        GG-Finance        GG-IT
               │              │               │
               ▼              ▼               ▼
      DL-FS-HR-Modify  DL-FS-Finance-Modify DL-FS-IT-Modify
               │              │               │
               └──────────────┼───────────────┘
                              │
                            FILE01
                              │
                    <FILE01_DATA_PATH>
                              │
                             Shares
                              │
         ┌────────────────────┼────────────────────┐
         │                    │                    │
         ▼                    ▼                    ▼
        SMB                  NTFS                 FSRM
         │                    │                    │
         │                    │                    └── Quotas
         │                    │
         └──────────┬─────────┘
                    │
                    ▼
             Effective Access
                    │
                    ▼
               Windows Clients

Backup:
FILE01 DATA
   ↓
<FILE01_BACKUP_TARGET>
   ↓
Backup Version
   ↓
Alternate Restore
   ↓
Hash + ACL
   ↓
SMB Functional Retest
```
