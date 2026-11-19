# 02 - ACTIVE DIRECTORY

## Windows Server 2025 Enterprise Infrastructure

**Project:** Windows Server 2025 Enterprise Infrastructure
**Domain:** `diarabaka.com`
**Domain Controllers:** `DC01`, `DC02`
**Domain:** Microsoft Infrastructure
**Level:** Confirmed`

---

# 02.0 - Objectif

Cette phase met en place et administre l'infrastructure Active Directory du domaine :

```text
diarabaka.com
```

L'objectif n'est pas uniquement de créer des utilisateurs.

La phase couvre :

```text
ACTIVE DIRECTORY
      │
      ├── OU Architecture
      ├── User Accounts
      ├── Security Groups
      ├── Group Membership
      ├── Administrative Accounts
      ├── User Lifecycle
      ├── Password Policy
      ├── Account Lockout
      ├── Helpdesk Delegation
      ├── FSMO
      ├── Global Catalog
      ├── Replication
      ├── Sites & Subnets
      ├── Protected Groups
      ├── Auditing
      ├── Health Checks
      └── Backup Strategy
```

Principe général :

```text
DESIGN
   ↓
CREATE
   ↓
CONFIGURE
   ↓
DELEGATE
   ↓
SECURE
   ↓
OPERATE
   ↓
MONITOR
   ↓
TROUBLESHOOT
   ↓
BACKUP
   ↓
VALIDATE
```

---

# 02.1 - Architecture des OU

## Objectif

Organiser Active Directory autour d'une **OU racine dédiée à l'entreprise** afin de séparer les objets métier des conteneurs natifs du domaine et de faciliter les GPO, la délégation, l'audit et le cycle de vie.

Architecture définitive :

```text
DIARABAKA.COM
│
├── Domain Controllers
│   ├── DC01
│   └── DC02
│
└── OU=Diarabaka
    │
    ├── OU=Users
    │   ├── OU=IT
    │   ├── OU=HR
    │   ├── OU=Finance
    │   ├── OU=Marketing
    │   └── OU=Sales
    │
    ├── OU=Groups
    │   ├── OU=Department
    │   ├── OU=Roles
    │   └── OU=Resources
    │
    ├── OU=Computers
    │   └── OU=Workstations
    │
    ├── OU=Servers
    │   ├── OU=File Servers
    │   ├── OU=Application Servers
    │   └── OU=Infrastructure Servers
    │
    ├── OU=Admins
    │
    └── OU=Service Accounts
```

`DC01` et `DC02` restent dans l'OU native :

```text
OU=Domain Controllers,DC=diarabaka,DC=com
```

Ils ne sont pas déplacés sous `OU=Servers`.

## Rôle de chaque espace

| OU                               | Contenu                                                          |
| -------------------------------- | ---------------------------------------------------------------- |
| `Diarabaka`                      | Racine administrative de l'entreprise                            |
| `Users`                          | Conteneur parent des utilisateurs standards                      |
| `Users\IT`                       | Utilisateurs du département IT                                   |
| `Users\HR`                       | Utilisateurs des ressources humaines                             |
| `Users\Finance`                  | Utilisateurs Finance                                             |
| `Users\Marketing`                | Utilisateurs Marketing                                           |
| `Users\Sales`                    | Utilisateurs Sales                                               |
| `Groups\Department`              | Groupes globaux de département                                   |
| `Groups\Roles`                   | Groupes globaux représentant des rôles administratifs ou métiers |
| `Groups\Resources`               | Groupes destinés aux permissions sur les ressources              |
| `Computers\Workstations`         | Postes clients Windows, par exemple `WIN11`                      |
| `Servers\File Servers`           | Serveurs de fichiers, par exemple `FILE01`                       |
| `Servers\Application Servers`    | Serveurs applicatifs                                             |
| `Servers\Infrastructure Servers` | Serveurs membres d'infrastructure                                |
| `Admins`                         | Comptes administratifs dédiés                                    |
| `Service Accounts`               | Comptes techniques / services                                    |

---

# 02.1.1 - Inventaire avant modification

Sur `DC01` :

```powershell
Get-ADOrganizationalUnit -Filter * |
    Select-Object Name,DistinguishedName |
    Sort-Object DistinguishedName |
    Format-Table -AutoSize
```

Vérifier également l'OU native des contrôleurs de domaine :

```powershell
Get-ADOrganizationalUnit `
    -Identity "OU=Domain Controllers,DC=diarabaka,DC=com"
```

Principe :

```text
OU EXISTS?
   │
┌──┴──┐
│     │
YES   NO
│     │
KEEP  CREATE
```

Ne jamais recréer inutilement une OU existante.

# 02.1.2 - Préparer le toolkit

```powershell
$Root = "C:\SysAdminToolkit\02-ActiveDirectory"

New-Item -ItemType Directory -Path "$Root\Data" -Force | Out-Null
New-Item -ItemType Directory -Path "$Root\Logs" -Force | Out-Null
New-Item -ItemType Directory -Path "$Root\Reports" -Force | Out-Null
```

Structure :

```text
C:\SysAdminToolkit
└── 02-ActiveDirectory
    ├── Data
    │   └── Users.csv
    ├── Logs
    ├── Reports
    ├── 01-Create-AD-OUs.ps1
    ├── 02-Create-Users.ps1
    ├── 03-Create-Groups.ps1
    ├── 04-Assign-Users-To-Groups.ps1
    └── 05-Helpdesk-UserManagement.ps1
```

# 02.1.3 - Script de création des OU

Créer :

```powershell
notepad C:\SysAdminToolkit\02-ActiveDirectory\01-Create-AD-OUs.ps1
```

Contenu :

```powershell
#requires -Modules ActiveDirectory

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$Preview
)

Import-Module ActiveDirectory -ErrorAction Stop

$Domain   = Get-ADDomain
$DomainDN = $Domain.DistinguishedName
$BaseOU   = "OU=Diarabaka,$DomainDN"

$OUPlan = @(
    @{ Name = "Diarabaka";              Path = $DomainDN;                         Description = "Diarabaka enterprise root OU" }

    @{ Name = "Users";                  Path = $BaseOU;                           Description = "Standard user accounts" }
    @{ Name = "Groups";                 Path = $BaseOU;                           Description = "Security groups" }
    @{ Name = "Computers";              Path = $BaseOU;                           Description = "Client computers" }
    @{ Name = "Servers";                Path = $BaseOU;                           Description = "Member servers" }
    @{ Name = "Admins";                 Path = $BaseOU;                           Description = "Dedicated administrative accounts" }
    @{ Name = "Service Accounts";       Path = $BaseOU;                           Description = "Service accounts" }

    @{ Name = "IT";                     Path = "OU=Users,$BaseOU";                Description = "IT users" }
    @{ Name = "HR";                     Path = "OU=Users,$BaseOU";                Description = "Human Resources users" }
    @{ Name = "Finance";                Path = "OU=Users,$BaseOU";                Description = "Finance users" }
    @{ Name = "Marketing";              Path = "OU=Users,$BaseOU";                Description = "Marketing users" }
    @{ Name = "Sales";                  Path = "OU=Users,$BaseOU";                Description = "Sales users" }

    @{ Name = "Department";             Path = "OU=Groups,$BaseOU";               Description = "Department security groups" }
    @{ Name = "Roles";                  Path = "OU=Groups,$BaseOU";               Description = "Role-based security groups" }
    @{ Name = "Resources";              Path = "OU=Groups,$BaseOU";               Description = "Resource permission groups" }

    @{ Name = "Workstations";           Path = "OU=Computers,$BaseOU";            Description = "Domain workstations" }

    @{ Name = "File Servers";           Path = "OU=Servers,$BaseOU";              Description = "File servers" }
    @{ Name = "Application Servers";    Path = "OU=Servers,$BaseOU";              Description = "Application servers" }
    @{ Name = "Infrastructure Servers"; Path = "OU=Servers,$BaseOU";              Description = "Infrastructure member servers" }
)

function Get-TargetDN {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Path
    )

    "OU=$Name,$Path"
}

function Test-OUExists {
    param(
        [Parameter(Mandatory)]
        [string]$DistinguishedName
    )

    try {
        $null = Get-ADOrganizationalUnit `
            -Identity $DistinguishedName `
            -ErrorAction Stop

        return $true
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        return $false
    }
}

# ============================================================
# PRE-CHECK
# ============================================================

$Results = foreach ($OU in $OUPlan) {

    $TargetDN = Get-TargetDN `
        -Name $OU.Name `
        -Path $OU.Path

    $Exists = Test-OUExists `
        -DistinguishedName $TargetDN

    [PSCustomObject]@{
        Name   = $OU.Name
        Path   = $OU.Path
        DN     = $TargetDN
        Status = if ($Exists) { "EXISTS" } else { "READY" }
    }
}

$Results |
    Format-Table Name, Path, Status -AutoSize

if ($Preview) {
    Write-Host ""
    Write-Host "PREVIEW ONLY - no change made." -ForegroundColor Yellow
    return
}

# ============================================================
# CREATION
# ============================================================

foreach ($OU in $OUPlan) {

    $TargetDN = Get-TargetDN `
        -Name $OU.Name `
        -Path $OU.Path

    if (Test-OUExists -DistinguishedName $TargetDN) {
        Write-Host "[EXISTS]  $TargetDN" -ForegroundColor Yellow
        continue
    }

    try {

        if ($PSCmdlet.ShouldProcess($TargetDN, "Create OU")) {

            New-ADOrganizationalUnit `
                -Name $OU.Name `
                -Path $OU.Path `
                -Description $OU.Description `
                -ProtectedFromAccidentalDeletion $true `
                -ErrorAction Stop

            Write-Host "[CREATED] $TargetDN" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "[ERROR]   $TargetDN : $($_.Exception.Message)" `
            -ForegroundColor Red
    }
}
```

# 02.1.4 - Preview

```powershell
cd C:\SysAdminToolkit\02-ActiveDirectory
.\01-Create-AD-OUs.ps1 -Preview
```

Attendu : `EXISTS` ou `READY`, sans modification.

# 02.1.5 - Création

```powershell
.\01-Create-AD-OUs.ps1
```

# 02.1.6 - Vérification

```powershell
$BaseOU = "OU=Diarabaka,DC=diarabaka,DC=com"

Get-ADOrganizationalUnit `
    -SearchBase $BaseOU `
    -Filter * |
    Select-Object Name,DistinguishedName,ProtectedFromAccidentalDeletion |
    Sort-Object DistinguishedName |
    Format-Table -AutoSize
```

DN attendus :

```text
OU=Diarabaka,DC=diarabaka,DC=com
OU=Users,OU=Diarabaka,DC=diarabaka,DC=com
OU=IT,OU=Users,OU=Diarabaka,DC=diarabaka,DC=com
OU=HR,OU=Users,OU=Diarabaka,DC=diarabaka,DC=com
OU=Finance,OU=Users,OU=Diarabaka,DC=diarabaka,DC=com
OU=Marketing,OU=Users,OU=Diarabaka,DC=diarabaka,DC=com
OU=Sales,OU=Users,OU=Diarabaka,DC=diarabaka,DC=com
OU=Groups,OU=Diarabaka,DC=diarabaka,DC=com
OU=Department,OU=Groups,OU=Diarabaka,DC=diarabaka,DC=com
OU=Roles,OU=Groups,OU=Diarabaka,DC=diarabaka,DC=com
OU=Resources,OU=Groups,OU=Diarabaka,DC=diarabaka,DC=com
OU=Computers,OU=Diarabaka,DC=diarabaka,DC=com
OU=Workstations,OU=Computers,OU=Diarabaka,DC=diarabaka,DC=com
OU=Servers,OU=Diarabaka,DC=diarabaka,DC=com
OU=File Servers,OU=Servers,OU=Diarabaka,DC=diarabaka,DC=com
OU=Application Servers,OU=Servers,OU=Diarabaka,DC=diarabaka,DC=com
OU=Infrastructure Servers,OU=Servers,OU=Diarabaka,DC=diarabaka,DC=com
OU=Admins,OU=Diarabaka,DC=diarabaka,DC=com
OU=Service Accounts,OU=Diarabaka,DC=diarabaka,DC=com
```

---

# 02.2 - Création des utilisateurs

## Objectif

Créer les comptes standards depuis `Users.csv` et placer automatiquement chaque utilisateur dans l'OU correspondant à son département.

Workflow :

```text
Users.csv
   │
   ├── Identity
   ├── Username
   ├── Department
   └── Title
        │
        ▼
VALIDATION
        │
        ▼
DEPARTMENT → OU MAPPING
        │
        ▼
PREVIEW
        │
        ▼
AD USER CREATION
        │
        ▼
OU=IT / HR / Finance / Marketing / Sales
```

# 02.2.1 - Préparer Users.csv

Créer :

```powershell
notepad C:\SysAdminToolkit\02-ActiveDirectory\Data\Users.csv
```

```csv
FirstName;LastName;Username;Department;Title
Jean;Dupont;jdupont;IT;IT Technician
Marie;Martin;mmartin;HR;HR Assistant
Paul;Bernard;pbernard;Finance;Financial Analyst
Sophie;Robert;srobert;Marketing;Marketing Specialist
Thomas;Petit;tpetit;Sales;Sales Representative
Julie;Durand;jdurand;IT;System Administrator
Nicolas;Leroy;nleroy;IT;Network Administrator
Camille;Moreau;cmoreau;HR;HR Specialist
Antoine;Simon;asimon;Finance;Accountant
Laura;Michel;lmichel;Marketing;Marketing Assistant
Lucas;Lefevre;llefevre;Sales;Sales Representative
Emma;Roux;eroux;IT;Support Technician
Hugo;David;hdavid;IT;Security Administrator
Chloe;Bertrand;cbertrand;HR;HR Assistant
Maxime;Fournier;mfournier;Finance;Financial Analyst
Sarah;Girard;sgirard;Marketing;Marketing Specialist
Alexandre;Bonnet;abonnet;Sales;Sales Representative
Elise;Lambert;elambert;IT;Cloud Administrator
Julien;Fontaine;jfontaine;IT;Helpdesk Technician
Clara;Chevalier;cchevalier;Sales;Sales Assistant
```

# 02.2.2 - Script de création des utilisateurs

```powershell
notepad C:\SysAdminToolkit\02-ActiveDirectory\02-Create-Users.ps1
```

```powershell
#requires -Modules ActiveDirectory

[CmdletBinding()]
param(
    [switch]$Preview
)

Import-Module ActiveDirectory

$Root            = "C:\SysAdminToolkit\02-ActiveDirectory"
$CsvPath         = "$Root\Data\Users.csv"
$ReportDirectory = "$Root\Reports"
$LogDirectory    = "$Root\Logs"

$Domain   = Get-ADDomain
$DomainDN = $Domain.DistinguishedName
$BaseOU   = "OU=Diarabaka,$DomainDN"
$UsersOU  = "OU=Users,$BaseOU"

$DepartmentOUs = @{
    "IT"        = "OU=IT,$UsersOU"
    "HR"        = "OU=HR,$UsersOU"
    "Finance"   = "OU=Finance,$UsersOU"
    "Marketing" = "OU=Marketing,$UsersOU"
    "Sales"     = "OU=Sales,$UsersOU"
}

New-Item -Path $ReportDirectory -ItemType Directory -Force | Out-Null
New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null

$Timestamp  = Get-Date -Format "yyyyMMdd-HHmmss"
$ReportPath = "$ReportDirectory\Create-Users-$Timestamp.csv"
$LogPath    = "$LogDirectory\Create-Users-$Timestamp.log"

function Write-Log {
    param([string]$Message)
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message" |
        Add-Content -Path $LogPath
}

if (-not (Test-Path $CsvPath)) {
    Write-Host "[ERROR] CSV not found: $CsvPath" -ForegroundColor Red
    exit 1
}

foreach ($OU in $DepartmentOUs.Values) {
    if (-not (Get-ADOrganizationalUnit -Identity $OU -ErrorAction SilentlyContinue)) {
        Write-Host "[ERROR] Missing department OU: $OU" -ForegroundColor Red
        exit 1
    }
}

$Users = Import-Csv -Path $CsvPath -Delimiter ";"

$RequiredColumns = "FirstName","LastName","Username","Department","Title"
$CsvColumns = $Users[0].PSObject.Properties.Name

foreach ($Column in $RequiredColumns) {
    if ($Column -notin $CsvColumns) {
        Write-Host "[ERROR] Missing CSV column: $Column" -ForegroundColor Red
        exit 1
    }
}

$Results = foreach ($User in $Users) {
    $DisplayName = "$($User.FirstName) $($User.LastName)"

    if ([string]::IsNullOrWhiteSpace($User.Username)) {
        [PSCustomObject]@{
            Username=$User.Username; Name=$DisplayName; Department=$User.Department
            TargetOU=""; Status="FAILED"; Message="Username missing"
        }
        continue
    }

    if (-not $DepartmentOUs.ContainsKey($User.Department)) {
        [PSCustomObject]@{
            Username=$User.Username; Name=$DisplayName; Department=$User.Department
            TargetOU=""; Status="FAILED"; Message="Unknown department"
        }
        continue
    }

    $TargetOU = $DepartmentOUs[$User.Department]
    $Existing = Get-ADUser -Filter "SamAccountName -eq '$($User.Username)'" -ErrorAction SilentlyContinue

    [PSCustomObject]@{
        Username   = $User.Username
        Name       = $DisplayName
        Department = $User.Department
        TargetOU   = $TargetOU
        Status     = if ($Existing) { "EXISTS" } else { "READY" }
        Message    = if ($Existing) { "User already exists" } else { "User can be created" }
    }
}

$Results | Format-Table Username,Department,TargetOU,Status -AutoSize
$Results | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8

if ($Preview) {
    Write-Host "PREVIEW ONLY - no change made." -ForegroundColor Yellow
    exit 0
}

if ($Results.Status -contains "FAILED") {
    Write-Host "[ERROR] Creation blocked because preview contains FAILED entries." -ForegroundColor Red
    exit 1
}

$Password = Read-Host "Temporary password" -AsSecureString

$FinalResults = foreach ($User in $Users) {
    $DisplayName = "$($User.FirstName) $($User.LastName)"
    $TargetOU = $DepartmentOUs[$User.Department]

    if (Get-ADUser -Filter "SamAccountName -eq '$($User.Username)'" -ErrorAction SilentlyContinue) {
        [PSCustomObject]@{Username=$User.Username;Department=$User.Department;TargetOU=$TargetOU;Status="EXISTS"}
        continue
    }

    try {
        New-ADUser `
            -Name $DisplayName `
            -GivenName $User.FirstName `
            -Surname $User.LastName `
            -SamAccountName $User.Username `
            -UserPrincipalName "$($User.Username)@$($Domain.DNSRoot)" `
            -DisplayName $DisplayName `
            -Department $User.Department `
            -Title $User.Title `
            -Path $TargetOU `
            -AccountPassword $Password `
            -Enabled $true `
            -ChangePasswordAtLogon $true `
            -ErrorAction Stop

        Write-Log "CREATED user=$($User.Username) ou=$TargetOU"
        [PSCustomObject]@{Username=$User.Username;Department=$User.Department;TargetOU=$TargetOU;Status="CREATED"}
    }
    catch {
        Write-Log "FAILED user=$($User.Username) error=$($_.Exception.Message)"
        [PSCustomObject]@{Username=$User.Username;Department=$User.Department;TargetOU=$TargetOU;Status="FAILED"}
    }
}

$FinalResults | Format-Table -AutoSize
$FinalResults | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8
```

# 02.2.3 - Preview utilisateurs

```powershell
cd C:\SysAdminToolkit\02-ActiveDirectory
.\02-Create-Users.ps1 -Preview
```

# 02.2.4 - Création réelle

```powershell
.\02-Create-Users.ps1
```

# 02.2.5 - Vérifier les 20 comptes

```powershell
$UsersOU = "OU=Users,OU=Diarabaka,DC=diarabaka,DC=com"

Get-ADUser `
    -SearchBase $UsersOU `
    -SearchScope Subtree `
    -Filter * `
    -Properties Department,Title,Enabled |
    Select-Object Name,SamAccountName,Enabled,Department,Title,DistinguishedName |
    Sort-Object Department,Name |
    Format-Table -AutoSize
```

Compter :

```powershell
(
    Get-ADUser `
        -SearchBase $UsersOU `
        -SearchScope Subtree `
        -Filter *
).Count
```

Attendu pour le dataset :

```text
20
```

# 02.2.6 - Vérifier le placement par département

```powershell
Get-ADUser `
    -SearchBase $UsersOU `
    -SearchScope Subtree `
    -Filter * `
    -Properties Department |
    Select-Object SamAccountName,Department,DistinguishedName |
    Sort-Object Department,SamAccountName |
    Format-Table -AutoSize
```

# 02.2.7 - Vérifier que les comptes standards ne sont pas Domain Admins

```powershell
Get-ADGroupMember "Domain Admins" |
    Select-Object Name,SamAccountName,ObjectClass
```

---

# 02.3 - Groupes Active Directory

## Objectif

Ranger les groupes selon leur fonction administrative :

```text
OU=Groups
│
├── OU=Department
│   ├── GG-IT
│   ├── GG-HR
│   ├── GG-Finance
│   ├── GG-Marketing
│   └── GG-Sales
│
├── OU=Roles
│   ├── GG-IT-Admins
│   ├── GG-IT-Helpdesk
│   ├── GG-IT-Network
│   ├── GG-IT-Security
│   └── GG-IT-Cloud
│
└── OU=Resources
    └── futurs groupes de permissions sur les ressources
```

# 02.3.1 - Script de création des groupes

```powershell
notepad C:\SysAdminToolkit\02-ActiveDirectory\03-Create-Groups.ps1
```

```powershell
#requires -Modules ActiveDirectory

[CmdletBinding()]
param([switch]$Preview)

Import-Module ActiveDirectory

$Domain   = Get-ADDomain
$DomainDN = $Domain.DistinguishedName
$BaseOU   = "OU=Diarabaka,$DomainDN"
$GroupsOU = "OU=Groups,$BaseOU"

$GroupOUs = @{
    Department = "OU=Department,$GroupsOU"
    Roles      = "OU=Roles,$GroupsOU"
    Resources  = "OU=Resources,$GroupsOU"
}

$Groups = @(
    @{ Name="GG-IT";          Type="Department"; Description="IT Department" },
    @{ Name="GG-HR";          Type="Department"; Description="Human Resources Department" },
    @{ Name="GG-Finance";     Type="Department"; Description="Finance Department" },
    @{ Name="GG-Marketing";   Type="Department"; Description="Marketing Department" },
    @{ Name="GG-Sales";       Type="Department"; Description="Sales Department" },

    @{ Name="GG-IT-Admins";    Type="Roles"; Description="IT administrative role" },
    @{ Name="GG-IT-Helpdesk";  Type="Roles"; Description="IT helpdesk role" },
    @{ Name="GG-IT-Network";   Type="Roles"; Description="Network administration role" },
    @{ Name="GG-IT-Security";  Type="Roles"; Description="Security administration role" },
    @{ Name="GG-IT-Cloud";     Type="Roles"; Description="Cloud administration role" }
)

foreach ($OU in $GroupOUs.Values) {
    if (-not (Get-ADOrganizationalUnit -Identity $OU -ErrorAction SilentlyContinue)) {
        Write-Host "[ERROR] Missing OU: $OU" -ForegroundColor Red
        exit 1
    }
}

$Results = foreach ($Group in $Groups) {
    $TargetOU = $GroupOUs[$Group.Type]
    $Existing = Get-ADGroup -Filter "SamAccountName -eq '$($Group.Name)'" -ErrorAction SilentlyContinue

    [PSCustomObject]@{
        Name     = $Group.Name
        Type     = $Group.Type
        TargetOU = $TargetOU
        Status   = if ($Existing) { "EXISTS" } else { "READY" }
    }
}

$Results | Format-Table -AutoSize

if ($Preview) {
    Write-Host "PREVIEW ONLY - no change made." -ForegroundColor Yellow
    return
}

foreach ($Group in $Groups) {
    $TargetOU = $GroupOUs[$Group.Type]

    if (Get-ADGroup -Filter "SamAccountName -eq '$($Group.Name)'" -ErrorAction SilentlyContinue) {
        Write-Host "[EXISTS] $($Group.Name)" -ForegroundColor Yellow
        continue
    }

    try {
        New-ADGroup `
            -Name $Group.Name `
            -SamAccountName $Group.Name `
            -GroupCategory Security `
            -GroupScope Global `
            -DisplayName $Group.Name `
            -Description $Group.Description `
            -Path $TargetOU `
            -ErrorAction Stop

        Write-Host "[CREATED] $($Group.Name) -> $TargetOU" -ForegroundColor Green
    }
    catch {
        Write-Host "[ERROR] $($Group.Name): $($_.Exception.Message)" -ForegroundColor Red
    }
}
```

# 02.3.2 - Preview

```powershell
.\03-Create-Groups.ps1 -Preview
```

# 02.3.3 - Création réelle

```powershell
.\03-Create-Groups.ps1
```

# 02.3.4 - Vérification

```powershell
$GroupsOU = "OU=Groups,OU=Diarabaka,DC=diarabaka,DC=com"

Get-ADGroup `
    -SearchBase $GroupsOU `
    -SearchScope Subtree `
    -Filter * |
    Select-Object Name,GroupScope,GroupCategory,DistinguishedName |
    Sort-Object DistinguishedName |
    Format-Table -AutoSize
```

Attendu :

```text
GG-IT, GG-HR, GG-Finance, GG-Marketing, GG-Sales
→ OU=Department

GG-IT-Admins, GG-IT-Helpdesk, GG-IT-Network, GG-IT-Security, GG-IT-Cloud
→ OU=Roles

GroupScope    → Global
GroupCategory → Security
```

---

# 02.4 - Affectation automatique aux groupes

## Objectif

Associer automatiquement chaque utilisateur au groupe départemental correspondant à son attribut `Department`.

```text
USER OU
   +
Department attribute
   ↓
MAPPING
   ↓
GLOBAL DEPARTMENT GROUP
```

Exemples :

```text
jdupont   → IT      → GG-IT
mmartin   → HR      → GG-HR
pbernard  → Finance → GG-Finance
```

# 02.4.1 - Script d'affectation

```powershell
notepad C:\SysAdminToolkit\02-ActiveDirectory\04-Assign-Users-To-Groups.ps1
```

```powershell
#requires -Modules ActiveDirectory

[CmdletBinding()]
param([switch]$Preview)

Import-Module ActiveDirectory

$Domain   = Get-ADDomain
$DomainDN = $Domain.DistinguishedName
$BaseOU   = "OU=Diarabaka,$DomainDN"
$UsersOU  = "OU=Users,$BaseOU"
$DeptOU   = "OU=Department,OU=Groups,$BaseOU"

$DepartmentGroups = @{
    "IT"        = "GG-IT"
    "HR"        = "GG-HR"
    "Finance"   = "GG-Finance"
    "Marketing" = "GG-Marketing"
    "Sales"     = "GG-Sales"
}

$Users = @(
    Get-ADUser `
        -SearchBase $UsersOU `
        -SearchScope Subtree `
        -Filter * `
        -Properties Department `
        -ErrorAction Stop
)

$Results = foreach ($User in $Users) {
    $Department = $User.Department

    if ([string]::IsNullOrWhiteSpace($Department)) {
        [PSCustomObject]@{User=$User.SamAccountName;Department="";Group="";Status="SKIPPED";Message="No department"}
        continue
    }

    if (-not $DepartmentGroups.ContainsKey($Department)) {
        [PSCustomObject]@{User=$User.SamAccountName;Department=$Department;Group="";Status="SKIPPED";Message="No mapping"}
        continue
    }

    $GroupName = $DepartmentGroups[$Department]
    $Group = Get-ADGroup `
        -Filter "SamAccountName -eq '$GroupName'" `
        -SearchBase $DeptOU `
        -ErrorAction SilentlyContinue

    if (-not $Group) {
        [PSCustomObject]@{User=$User.SamAccountName;Department=$Department;Group=$GroupName;Status="ERROR";Message="Group missing"}
        continue
    }

    $IsMember = Get-ADGroupMember -Identity $Group -ErrorAction SilentlyContinue |
        Where-Object SamAccountName -eq $User.SamAccountName

    [PSCustomObject]@{
        User       = $User.SamAccountName
        Department = $Department
        Group      = $GroupName
        Status     = if ($IsMember) { "EXISTS" } else { "READY" }
        Message    = if ($IsMember) { "Already member" } else { "Can be added" }
    }
}

$Results | Sort-Object Group,User | Format-Table -AutoSize

if ($Preview) {
    Write-Host "PREVIEW ONLY - no change made." -ForegroundColor Yellow
    return
}

foreach ($Result in $Results | Where-Object Status -eq "READY") {
    try {
        Add-ADGroupMember -Identity $Result.Group -Members $Result.User -ErrorAction Stop
        Write-Host "[ADDED] $($Result.User) -> $($Result.Group)" -ForegroundColor Green
    }
    catch {
        Write-Host "[ERROR] $($Result.User) -> $($Result.Group): $($_.Exception.Message)" -ForegroundColor Red
    }
}
```

# 02.4.2 - Preview

```powershell
.\04-Assign-Users-To-Groups.ps1 -Preview
```

# 02.4.3 - Affectation réelle

```powershell
.\04-Assign-Users-To-Groups.ps1
```

# 02.4.4 - Vérification

```powershell
$Groups = "GG-IT","GG-HR","GG-Finance","GG-Marketing","GG-Sales"

foreach ($Group in $Groups) {
    Write-Host "`n===== $Group =====" -ForegroundColor Cyan
    Get-ADGroupMember $Group |
        Select-Object Name,SamAccountName |
        Format-Table -AutoSize
}
```

---

# 02.5 - Comptes d'administration

## Principe

Un administrateur ne doit pas utiliser son compte quotidien pour toutes les tâches élevées.

```text
DAILY ACCOUNT
     ≠
ADMIN ACCOUNT
```

Exemple :

```text
Julie Durand
│
├── jdurand
│      └── Daily account
│
└── adm-jdurand
       └── Administrative account
```

Cette séparation permet de limiter l'exposition permanente des privilèges.

---

# 02.5.1 - Vérifier les comptes existants

```powershell
Get-ADUser -Filter * -Properties Enabled |
    Select-Object Name,
                  SamAccountName,
                  Enabled |
    Sort-Object SamAccountName |
    Format-Table -AutoSize
```

Vérifier les membres de `Domain Admins` :

```powershell
Get-ADGroupMember "Domain Admins" |
    Select-Object Name,
                  SamAccountName,
                  ObjectClass |
    Format-Table -AutoSize
```

---

# 02.5.2 - Vérifier l'OU Admins

```powershell
$Domain   = Get-ADDomain
$BaseOU   = "OU=Diarabaka,$($Domain.DistinguishedName)"
$AdminsOU = "OU=Admins,$BaseOU"
```

Puis :

```powershell
Get-ADOrganizationalUnit -Identity $AdminsOU
```

---

# 02.5.3 - Créer un compte administratif dédié

Exemple :

```powershell
New-ADUser `
    -Name "ADM - Julie Durand" `
    -GivenName "Julie" `
    -Surname "Durand" `
    -SamAccountName "adm-jdurand" `
    -UserPrincipalName "adm-jdurand@$($Domain.DNSRoot)" `
    -DisplayName "ADM - Julie Durand" `
    -Description "Dedicated administrative account" `
    -Path $AdminsOU `
    -Enabled $true `
    -AccountPassword (
        Read-Host "Password" -AsSecureString
    ) `
    -ChangePasswordAtLogon $true
```

Vérifier :

```powershell
Get-ADUser adm-jdurand `
    -Properties Enabled,Description |
    Select-Object Name,
                  SamAccountName,
                  Enabled,
                  Description
```

---

# 02.5.4 - Least Privilege

Ne pas ajouter automatiquement :

```text
adm-jdurand
      ↓
Domain Admins
```

La cible est :

```text
ADMIN ACCOUNT
      ↓
ROLE GROUP
      ↓
DELEGATED PRIVILEGE
```

Groupes disponibles :

```text
GG-IT-Admins
GG-IT-Helpdesk
GG-IT-Network
GG-IT-Security
GG-IT-Cloud
```

Exemple :

```powershell
Add-ADGroupMember `
    -Identity "GG-IT-Admins" `
    -Members "adm-jdurand"
```

Cela ne signifie pas que `GG-IT-Admins` doit être membre de `Domain Admins`.

Le privilège réel doit être attribué selon le besoin.

---

# 02.6 - Modèle de privilèges

Architecture :

```text
Standard User
     │
     ▼
Daily Account

Administrative User
     │
     ▼
Dedicated Admin Account
     │
     ▼
Role-Based Group
     │
     ▼
Delegated Permission
```

Exemple :

```text
Helpdesk
   ↓
GG-IT-Helpdesk
   ↓
Password Reset
Unlock
```

et non :

```text
Helpdesk
   ↓
Domain Admins
```

---

# 02.7 - Cycle de vie utilisateur

## Objectif

Un administrateur Active Directory doit être capable de gérer :

```text
CREATE
  ↓
ENABLE
  ↓
USE
  ↓
PASSWORD RESET
  ↓
UNLOCK
  ↓
DISABLE
  ↓
ENABLE
  ↓
PASSWORD EXPIRATION
  ↓
ACCOUNT EXPIRATION
  ↓
DEPARTURE
```

---

# 02.7.1 - Vérifier les commandes disponibles

```powershell
Get-Command `
    Get-ADUser,
    New-ADUser,
    Set-ADUser,
    Set-ADAccountPassword,
    Unlock-ADAccount,
    Disable-ADAccount,
    Enable-ADAccount,
    Search-ADAccount
```

---

# 02.7.2 - Outil Helpdesk

Créer :

```powershell
notepad C:\SysAdminToolkit\02-ActiveDirectory\05-Helpdesk-UserManagement.ps1
```

```powershell
#requires -Modules ActiveDirectory

[CmdletBinding()]
param(

    [Parameter(Mandatory)]
    [ValidateSet(
        "ResetPassword",
        "Unlock",
        "Disable",
        "Enable",
        "ExpirePassword",
        "UserInfo"
    )]
    [string]$Action,

    [Parameter(Mandatory)]
    [string]$Username
)

Import-Module ActiveDirectory

# ============================================================
# USER VALIDATION
# ============================================================

try {

    $User = Get-ADUser `
        -Identity $Username `
        -Properties `
            Enabled,
            LockedOut,
            PasswordExpired,
            PasswordLastSet,
            AccountExpirationDate,
            Department `
        -ErrorAction Stop
}
catch {

    Write-Host `
        "[ERROR] User not found: $Username" `
        -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "========================================" `
    -ForegroundColor Cyan

Write-Host "       HELPDESK USER MANAGEMENT" `
    -ForegroundColor Cyan

Write-Host "========================================" `
    -ForegroundColor Cyan

Write-Host ""
Write-Host "User   : $($User.SamAccountName)"
Write-Host "Name   : $($User.Name)"
Write-Host "Action : $Action"
Write-Host ""

# ============================================================
# ACTIONS
# ============================================================

switch ($Action) {

    # --------------------------------------------------------
    # USER INFORMATION
    # --------------------------------------------------------

    "UserInfo" {

        try {

            Get-ADUser `
                -Identity $Username `
                -Properties `
                    Enabled,
                    LockedOut,
                    PasswordExpired,
                    PasswordLastSet,
                    AccountExpirationDate,
                    Department `
                -ErrorAction Stop |
                Select-Object `
                    Name,
                    SamAccountName,
                    Enabled,
                    LockedOut,
                    PasswordExpired,
                    PasswordLastSet,
                    AccountExpirationDate,
                    Department
        }
        catch {

            Write-Host `
                "[ERROR] Unable to retrieve user information: $($_.Exception.Message)" `
                -ForegroundColor Red

            exit 1
        }
    }

    # --------------------------------------------------------
    # UNLOCK ACCOUNT
    # --------------------------------------------------------

    "Unlock" {

        try {

            Unlock-ADAccount `
                -Identity $Username `
                -ErrorAction Stop

            Write-Host `
                "[OK] Account unlocked." `
                -ForegroundColor Green
        }
        catch {

            Write-Host `
                "[ERROR] Unable to unlock account: $($_.Exception.Message)" `
                -ForegroundColor Red

            exit 1
        }
    }

    # --------------------------------------------------------
    # DISABLE ACCOUNT
    # --------------------------------------------------------

    "Disable" {

        try {

            Disable-ADAccount `
                -Identity $Username `
                -ErrorAction Stop

            Write-Host `
                "[OK] Account disabled." `
                -ForegroundColor Green
        }
        catch {

            Write-Host `
                "[ERROR] Unable to disable account: $($_.Exception.Message)" `
                -ForegroundColor Red

            exit 1
        }
    }

    # --------------------------------------------------------
    # ENABLE ACCOUNT
    # --------------------------------------------------------

    "Enable" {

        try {

            Enable-ADAccount `
                -Identity $Username `
                -ErrorAction Stop

            Write-Host `
                "[OK] Account enabled." `
                -ForegroundColor Green
        }
        catch {

            Write-Host `
                "[ERROR] Unable to enable account: $($_.Exception.Message)" `
                -ForegroundColor Red

            exit 1
        }
    }

    # --------------------------------------------------------
    # RESET PASSWORD
    # --------------------------------------------------------

    "ResetPassword" {

        Write-Host `
            "Enter a temporary password." `
            -ForegroundColor Yellow

        Write-Host `
            "The user will be required to change it at next logon." `
            -ForegroundColor Yellow

        Write-Host ""

        $Password = Read-Host `
            "Temporary password" `
            -AsSecureString

        try {

            Set-ADAccountPassword `
                -Identity $Username `
                -Reset `
                -NewPassword $Password `
                -ErrorAction Stop

            Set-ADUser `
                -Identity $Username `
                -ChangePasswordAtLogon $true `
                -ErrorAction Stop

            Write-Host ""
            Write-Host `
                "[OK] Password reset successfully." `
                -ForegroundColor Green

            Write-Host `
                "[OK] User must change password at next logon." `
                -ForegroundColor Green
        }
        catch {

            Write-Host ""
            Write-Host `
                "[ERROR] Password reset failed: $($_.Exception.Message)" `
                -ForegroundColor Red

            exit 1
        }
    }

    # --------------------------------------------------------
    # FORCE PASSWORD CHANGE
    # --------------------------------------------------------

    "ExpirePassword" {

        try {

            Set-ADUser `
                -Identity $Username `
                -ChangePasswordAtLogon $true `
                -ErrorAction Stop

            Write-Host `
                "[OK] Password marked for change at next logon." `
                -ForegroundColor Green
        }
        catch {

            Write-Host `
                "[ERROR] Unable to force password change: $($_.Exception.Message)" `
                -ForegroundColor Red

            exit 1
        }
    }
}
```

---

# 02.7.3 - Consultation

```powershell
.\05-Helpdesk-UserManagement.ps1 `
    -Action UserInfo `
    -Username jdupont
```

Exemple de résultat :

```text
Name                  : Jean Dupont
SamAccountName        : jdupont
Enabled               : True
LockedOut             : False
PasswordExpired       : False
PasswordLastSet       : ...
AccountExpirationDate :
Department            : IT
```

---

## 02.7.4 - Reset Password

Le technicien Helpdesk peut réinitialiser le mot de passe d’un utilisateur Active Directory à l’aide du script suivant :

```powershell
.\05-Helpdesk-UserManagement.ps1 `
    -Action ResetPassword `
    -Username jdupont
```

Le mot de passe temporaire :

```text
NE DOIT PAS
```

être affiché en clair, stocké dans les logs ou enregistré dans les rapports.

---

# 02.7.5 - Unlock

```powershell
.\05-Helpdesk-UserManagement.ps1 `
    -Action Unlock `
    -Username jdupont
```

---

# 02.7.6 - Disable

```powershell
.\05-Helpdesk-UserManagement.ps1 `
    -Action Disable `
    -Username jdupont
```

Vérifier :

```powershell
Get-ADUser jdupont `
    -Properties Enabled |
    Select-Object Name,
                  Enabled
```

Attendu :

```text
Enabled : False
```

---

# 02.7.7 - Enable

```powershell
.\05-Helpdesk-UserManagement.ps1 `
    -Action Enable `
    -Username jdupont
```

---

# 02.7.8 - Forcer le changement de mot de passe

```powershell
.\05-Helpdesk-UserManagement.ps1 `
    -Action ExpirePassword `
    -Username jdupont
```

Cela signifie :

```text
PASSWORD CHANGE
AT NEXT LOGON
```

---

# 02.7.9 - Expiration du compte

Attention :

```text
PASSWORD EXPIRATION
        ≠
ACCOUNT EXPIRATION
```

Exemple :

```powershell
Set-ADUser jdupont `
    -AccountExpirationDate "2026-12-31"
```

Vérifier :

```powershell
Get-ADUser jdupont `
    -Properties AccountExpirationDate |
    Select-Object SamAccountName,
                  AccountExpirationDate
```

---

# 02.8 - Password Policy

## Inventaire

```powershell
Get-ADDefaultDomainPasswordPolicy |
    Select-Object `
        MinPasswordLength,
        ComplexityEnabled,
        PasswordHistoryCount,
        MaxPasswordAge,
        MinPasswordAge,
        ReversibleEncryptionEnabled
```

Baseline choisie pour le lab :

```text
Minimum length          : 12
Complexity              : Enabled
Password history        : 24
Maximum password age    : 180 days
Minimum password age    : 1 day
Reversible encryption   : Disabled
```

Cette valeur constitue la baseline choisie pour ce projet.

---

# 02.8.1 - Configuration

```powershell
Set-ADDefaultDomainPasswordPolicy `
    -Identity "diarabaka.com" `
    -MinPasswordLength 12 `
    -ComplexityEnabled $true `
    -PasswordHistoryCount 24 `
    -MaxPasswordAge (
        New-TimeSpan -Days 180
    ) `
    -MinPasswordAge (
        New-TimeSpan -Days 1
    ) `
    -ReversibleEncryptionEnabled $false
```

---

# 02.8.2 - Validation

```powershell
Get-ADDefaultDomainPasswordPolicy |
    Format-List
```

La validation doit utiliser les valeurs réellement retournées.

---

# 02.9 - Account Lockout

Configuration :

```powershell
Set-ADDefaultDomainPasswordPolicy `
    -Identity "diarabaka.com" `
    -LockoutThreshold 5 `
    -LockoutDuration (
        New-TimeSpan -Minutes 15
    ) `
    -LockoutObservationWindow (
        New-TimeSpan -Minutes 15
    )
```

Principe :

```text
5 INVALID PASSWORDS
        ↓
ACCOUNT LOCKED
        ↓
15 MINUTES
```

---

# 02.9.1 - Vérification

```powershell
Get-ADDefaultDomainPasswordPolicy |
    Select-Object `
        LockoutThreshold,
        LockoutDuration,
        LockoutObservationWindow
```

---

# 02.9.2 - Test Helpdesk

Après un verrouillage contrôlé dans le lab :

```powershell
Search-ADAccount -LockedOut
```

Puis :

```powershell
Unlock-ADAccount jdupont
```

Vérifier :

```powershell
Get-ADUser jdupont `
    -Properties LockedOut |
    Select-Object SamAccountName,
                  LockedOut
```

Attendu :

```text
LockedOut : False
```

---

# 02.10 - Délégation Helpdesk

## Principe

Le Helpdesk n'a pas besoin de :

```text
Domain Admins
```

pour effectuer des opérations simples sur les utilisateurs.

Cible :

```text
GG-IT-Helpdesk
       │
       ├── Reset Password
       ├── Force Password Change
       └── Unlock Account
```

Les opérations plus sensibles telles que :

```text
Disable Account
Enable Account
Delete Account
Privileged Group Membership
```

peuvent rester réservées à une équipe disposant de privilèges plus élevés selon le processus de l'organisation.

---

# 02.10.1 - OU cible

La délégation est appliquée sur l'OU parent `Users` afin d'être héritée par les OU départementales.

```powershell
$Domain  = Get-ADDomain
$UsersOU = "OU=Users,OU=Diarabaka,$($Domain.DistinguishedName)"
```

Vérifier :

```powershell
Get-ADOrganizationalUnit `
    -Identity $UsersOU
```

---

# 02.10.2 - Reset Password

```powershell
dsacls $UsersOU /I:S /G `
"DIARABAKA\GG-IT-Helpdesk:CA;Reset Password;user"
```

---

# 02.10.3 - Unlock Account

```powershell
dsacls $UsersOU /I:S /G `
"DIARABAKA\GG-IT-Helpdesk:RPWP;lockoutTime;user"
```

---

# 02.10.4 - Vérifier la délégation

```powershell
dsacls $UsersOU | Select-String "GG-IT-Helpdesk|Reset Password|lockoutTime" -Context 2,4
```

Ne pas considérer la délégation comme validée uniquement parce que la commande a été exécutée.

Il faudra tester avec un compte membre de :

```text
GG-IT-Helpdesk
```

et démontrer :

```text
Reset Password   → ALLOWED
Unlock Account   → ALLOWED

Domain Admins    → NOT REQUIRED
```

---

# 02.11 - FSMO

## Objectif

Vérifier la localisation des cinq rôles FSMO.

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

Et :

```powershell
Get-ADForest |
    Select-Object `
        SchemaMaster,
        DomainNamingMaster
```

Les cinq rôles sont :

```text
FOREST
 │
 ├── Schema Master
 └── Domain Naming Master

DOMAIN
 │
 ├── PDC Emulator
 ├── RID Master
 └── Infrastructure Master
```

L'objectif est de connaître :

```text
ROLE
 ↓
CURRENT OWNER
 ↓
HEALTH
```

et non de déplacer les rôles sans raison.

---

# 02.12 - Global Catalog

Vérifier :

```powershell
# ============================================================
# 01 — DOMAIN CONTROLLERS
# ============================================================

Get-ADDomainController -Filter * |
Select-Object `
    HostName,
    IPv4Address,
    Site,
    IsGlobalCatalog,
    IsReadOnly


# ============================================================
# 02 — CURRENT FSMO
# ============================================================

netdom query fsmo


# ============================================================
# 03 — GENERAL DC HEALTH
# ============================================================

dcdiag /v


# ============================================================
# 04 — SYSVOL / NETLOGON
# ============================================================

dcdiag /test:SysVolCheck

dcdiag /test:NetLogons


# ============================================================
# 05 — REPLICATION
# ============================================================

repadmin /replsummary

repadmin /showrepl DC01

repadmin /showrepl DC02

dcdiag /test:replications


# ============================================================
# 06 — DNS
# ============================================================

dcdiag /test:dns /v

Resolve-DnsName `
    "_ldap._tcp.dc._msdcs.diarabaka.com" `
    -Type SRV `
    -Server 192.168.1.10

Resolve-DnsName `
    "_ldap._tcp.dc._msdcs.diarabaka.com" `
    -Type SRV `
    -Server 192.168.1.11

Resolve-DnsName `
    "_kerberos._tcp.diarabaka.com" `
    -Type SRV `
    -Server 192.168.1.10

Resolve-DnsName `
    "_kerberos._tcp.diarabaka.com" `
    -Type SRV `
    -Server 192.168.1.11


# ============================================================
# 07 — RPC BASIC CONNECTIVITY
# ============================================================

Test-NetConnection DC01 -Port 135

Test-NetConnection DC02 -Port 135
```

ne confirme pas un état sain.

---

# 02.14 - Active Directory Sites and Services

Vérifier les sites :

```powershell
Get-ADReplicationSite -Filter *
```

Puis :

```powershell
Get-ADReplicationSubnet -Filter *
```

Architecture du lab :

```text
Default-First-Site-Name
       │
       ├── DC01
       └── DC02

Subnet
192.168.1.0/24
       │
       ▼
      Site
```

Le subnet réellement configuré doit correspondre au réseau réel du lab.

Ne pas créer `192.168.1.0/24` uniquement parce qu'il apparaît dans la documentation si le réseau réel est différent.

---

# 02.15 - Protected Groups

## Objectif

Auditer régulièrement les groupes disposant de privilèges élevés.

```powershell
$ProtectedGroups = @(
    "Domain Admins",
    "Enterprise Admins",
    "Schema Admins",
    "Administrators",
    "Account Operators",
    "Backup Operators",
    "Server Operators"
)

foreach ($Group in $ProtectedGroups) {

    Write-Host "`n===== $Group =====" `
        -ForegroundColor Cyan

    Get-ADGroupMember $Group |
        Select-Object `
            Name,
            SamAccountName,
            ObjectClass
}
```

Objectif :

```text
Domain Admins
      ↓
MINIMUM REQUIRED MEMBERS
```

Et notamment :

```text
GG-IT
GG-IT-Helpdesk
GG-IT-Network
GG-IT-Security
GG-IT-Cloud
```

ne doivent pas être membres de `Domain Admins` simplement pour faciliter l'administration.

---

# 02.16 - Auditing Active Directory

## Objectif

Permettre la traçabilité des opérations sensibles.

Catégories importantes du projet :

```text
Account Logon
Account Management
Directory Service Changes
Logon / Logoff
Policy Change
Privilege Use
System
```

Événements importants :

| Event ID | Signification                    |
| -------: | -------------------------------- |
|   `4624` | Successful logon                 |
|   `4625` | Failed logon                     |
|   `4720` | User created                     |
|   `4722` | User enabled                     |
|   `4725` | User disabled                    |
|   `4726` | User deleted                     |
|   `4728` | Member added to global group     |
|   `4729` | Member removed from global group |
|   `4732` | Member added to local group      |
|   `4733` | Member removed from local group  |
|   `4740` | Account locked                   |
|   `4767` | Account unlocked                 |

Cette journalisation sera également utile pour les phases SIEM/Wazuh du projet.

---

# 02.16.1 - Vérification événementielle

Exemple :

```powershell
Get-WinEvent `
    -FilterHashtable @{
        LogName = "Security"
        Id      = 4720,4722,4725,4726,4728,4729,4740,4767
    } `
    -MaxEvents 50
```

La présence d'événements dépend des opérations réellement exécutées et de la configuration d'audit appliquée.

---

# 02.17 - Active Directory Health Check

## Domain Controllers

```powershell
Get-ADDomainController -Filter * |
    Select-Object `
        HostName,
        IPv4Address,
        Site,
        IsGlobalCatalog,
        OperatingSystem
```

---

## Diagnostic global

```powershell
dcdiag /e /c /v
```

---

## Replication

```powershell
repadmin /replsummary
```

---

## DNS

```powershell
dcdiag /test:dns
```

---

# 02.17.1 - Résultat attendu

La validation finale doit démontrer :

```text
DC01
 │
 ├── AD DS healthy
 ├── DNS healthy
 ├── Replication healthy
 └── GC available

DC02
 │
 ├── AD DS healthy
 ├── DNS healthy
 ├── Replication healthy
 └── GC available
```

Un seul test réussi ne suffit pas.

---

# 02.18 - Backup Active Directory

## Objectif

Une infrastructure Active Directory doit disposer d'une stratégie de sauvegarde.

Installer Windows Server Backup :

```powershell
Install-WindowsFeature Windows-Server-Backup
```

Vérifier :

```powershell
Get-WindowsFeature Windows-Server-Backup
```

Résultat attendu :

```text
Install State : Installed
```

---

# 02.18.1 - System State

Pour un contrôleur de domaine, le composant important est :

```text
SYSTEM STATE
    │
    ├── Active Directory Domain Services
    ├── Registry
    ├── Boot Files
    └── SYSVOL
```

---

# 02.19 - Troubleshooting Active Directory

Méthode générale :

```text
SYMPTOM
   ↓
DNS
   ↓
NETWORK
   ↓
DOMAIN CONTROLLER
   ↓
AD SERVICE
   ↓
REPLICATION
   ↓
OBJECT / OU
   ↓
GROUP MEMBERSHIP
   ↓
PERMISSIONS
   ↓
EVENT LOGS
   ↓
ROOT CAUSE
   ↓
CORRECTION
   ↓
RETEST
```

---

# 02.19.1 - Utilisateur introuvable

```powershell
Get-ADUser jdupont
```

Si erreur :

```text
Correct username?
Correct domain?
Correct DC?
AD module available?
Object deleted?
Replication issue?
```

---

# 02.19.2 - Groupe incorrect

```powershell
Get-ADPrincipalGroupMembership jdupont |
    Select-Object Name
```

Puis :

```powershell
Get-ADGroupMember GG-IT
```

---

# 02.19.3 - Compte verrouillé

```powershell
Search-ADAccount -LockedOut
```

Puis :

```powershell
Get-ADUser jdupont `
    -Properties LockedOut |
    Select-Object SamAccountName,
                  LockedOut
```

---

# 02.19.4 - Problème de réplication

```powershell
repadmin /replsummary
```

Puis :

```powershell
repadmin /showrepl
```

Puis :

```powershell
dcdiag /test:replications
```

Ne pas commencer directement par forcer ou reconstruire la réplication.

Identifier d'abord la cause.

---

# 02.19.5 - Problème DNS

```powershell
dcdiag /test:dns
```

Puis :

```powershell
Resolve-DnsName DC01
Resolve-DnsName DC02
Resolve-DnsName diarabaka.com
```

Active Directory dépend fortement d'une résolution DNS correcte.

---

# 02.20 - Audit final Active Directory

## OU

```powershell
Get-ADOrganizationalUnit -Filter * |
    Select-Object Name,
                  DistinguishedName |
    Sort-Object DistinguishedName
```

---

## Users

```powershell
Get-ADUser `
    -SearchBase "OU=Users,OU=Diarabaka,DC=diarabaka,DC=com" `
    -SearchScope Subtree `
    -Filter * `
    -Properties Department,Title,Enabled |
    Select-Object `
        Name,
        SamAccountName,
        Enabled,
        Department,
        Title |
    Sort-Object SamAccountName
```

---

## Groups

```powershell
Get-ADGroup `
    -SearchBase "OU=Groups,OU=Diarabaka,DC=diarabaka,DC=com" `
    -SearchScope Subtree `
    -Filter * |
    Select-Object `
        Name,
        GroupScope,
        GroupCategory |
    Sort-Object Name
```

---

## Admin Accounts

```powershell
Get-ADUser `
    -SearchBase "OU=Admins,OU=Diarabaka,DC=diarabaka,DC=com" `
    -Filter * |
    Select-Object `
        Name,
        SamAccountName,
        Enabled
```

---

## Domain Admins

```powershell
Get-ADGroupMember "Domain Admins" |
    Select-Object `
        Name,
        SamAccountName,
        ObjectClass
```

---

## Password Policy

```powershell
Get-ADDefaultDomainPasswordPolicy |
    Format-List
```

---

## FSMO

```
DC01
├── PDC Emulator
├── RID Master
└── Infrastructure Master
```

```powershell
Move-ADDirectoryServerOperationMasterRole `
    -Identity "DC01" `
    -OperationMasterRole PDCEmulator,RIDMaster,InfrastructureMaster
```

```
DC02
├── Schema Master
└── Domain Naming Master
```

```powershell
Move-ADDirectoryServerOperationMasterRole `
    -Identity "DC02" `
    -OperationMasterRole SchemaMaster,DomainNamingMaster
```

```powershell
netdom query fsmo

Get-ADDomain |
Select-Object PDCEmulator,RIDMaster,InfrastructureMaster

Get-ADForest |
Select-Object SchemaMaster,DomainNamingMaster
```

---

## Domain Controllers

```powershell
Get-ADDomainController -Filter * |
    Select-Object `
        HostName,
        IPv4Address,
        Site,
        IsGlobalCatalog
```

---

## Replication

```powershell
repadmin /replsummary
```

---

## DNS

```powershell
dcdiag /test:dns
```

---

# 02.21 - Architecture finale

```text
DIARABAKA.COM
│
├── Domain Controllers
│   ├── DC01
│   └── DC02
│
└── OU=Diarabaka
    │
    ├── OU=Users
    │   ├── OU=IT
    │   ├── OU=HR
    │   ├── OU=Finance
    │   ├── OU=Marketing
    │   └── OU=Sales
    │        │
    │        └── Standard User Accounts
    │
    ├── OU=Groups
    │   ├── OU=Department
    │   │   └── GG-IT / GG-HR / GG-Finance / GG-Marketing / GG-Sales
    │   ├── OU=Roles
    │   │   └── GG-IT-Admins / Helpdesk / Network / Security / Cloud
    │   └── OU=Resources
    │       └── Resource permission groups
    │
    ├── OU=Computers
    │   └── OU=Workstations
    │       └── WIN11
    │
    ├── OU=Servers
    │   ├── OU=File Servers
    │   │   └── FILE01
    │   ├── OU=Application Servers
    │   └── OU=Infrastructure Servers
    │
    ├── OU=Admins
    │   └── adm-jdurand
    │
    └── OU=Service Accounts
        └── Technical identities

DOMAIN CONTROLLERS
│
├── FSMO
├── Global Catalog
├── AD Replication
├── Sites / Subnets
├── DNS Dependency
├── Auditing
└── Backup / Recovery
```
