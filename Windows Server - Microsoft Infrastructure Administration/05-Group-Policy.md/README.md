# PHASE 05 - GROUP POLICY

## Windows Server 2025 Enterprise Infrastructure

**Project:** Windows Server 2025 Enterprise Infrastructure  
**Domain:** `diarabaka.com`  
**Management Server:** `DC01`  
**Secondary Domain Controller:** `DC02`  
**Client:** `WIN11`  
**Platform:** VMware  
**Target OU:** `OU=Workstations,OU=Computers,OU=Diarabaka,DC=diarabaka,DC=com`  
**Professional Domain:** Microsoft Infrastructure  
**Target Level:** Confirmed  
**Technical Status:** `READY FOR VALIDATION`

---

# 05.0 - Objectif

Group Policy permet d'administrer et de sécuriser de manière centralisée les ordinateurs et utilisateurs d'un domaine Active Directory.

Dans cette infrastructure :

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
    │
    ├── OU=Groups
    │
    ├── OU=Computers
    │   └── OU=Workstations
    │       └── WIN11
    │
    ├── OU=Servers
    ├── OU=Admins
    └── OU=Service Accounts
```

Les GPO principales de cette phase sont :

```text
GPO-WS-Security-Baseline
    ├── Windows Defender Firewall
    ├── Microsoft Defender Antivirus
    └── Windows Update

GPO-Windows11-BitLocker
    ├── TPM
    ├── Recovery Password
    └── AD DS Recovery Backup

GPO-Windows11-LAPS
    ├── Local Administrator Password
    ├── Password Rotation
    └── AD Backup
```

---

# 05.2 - Evidence Pack

Sur `DC01` :

```powershell
$EvidenceRoot = "C:\Evidence\GroupPolicy"

$Folders = @(
    "01-Baseline",
    "02-OU",
    "03-GPO-Inventory",
    "04-Links-Inheritance",
    "05-Security-Filtering",
    "06-SYSVOL-Replication",
    "07-Security-Baseline",
    "08-Firewall",
    "09-Defender",
    "10-Windows-Update",
    "11-BitLocker",
    "12-LAPS",
    "13-GPResult-RSoP",
    "14-Event-Logs",
    "15-Backup-Restore",
    "16-Troubleshooting",
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

# 05.3 - Baseline Group Policy

Sur `DC01` :

```powershell
Get-Date
hostname
whoami
```

Inventaire :

```powershell
Get-GPO -All |
    Select-Object `
        DisplayName,
        Id,
        GpoStatus,
        CreationTime,
        ModificationTime |
    Sort-Object DisplayName |
    Format-Table -AutoSize
```

Rapport HTML :

```powershell
Get-GPOReport `
    -All `
    -ReportType HTML `
    -Path "C:\Evidence\GroupPolicy\01-Baseline\GPO-Baseline.html"
```

Vérifier :

```powershell
Test-Path "C:\Evidence\GroupPolicy\01-Baseline\GPO-Baseline.html"
```

---

# 05.4 - Architecture OU canonique

La structure utilisée dans cette phase est :

```text
DC=diarabaka,DC=com
│
└── OU=Diarabaka
    │
    └── OU=Computers
        │
        └── OU=Workstations
            │
            └── CN=WIN11
```

DN canonique :

```powershell
$DomainDN       = "DC=diarabaka,DC=com"
$BaseOU         = "OU=Diarabaka,$DomainDN"
$ComputersOU    = "OU=Computers,$BaseOU"
$WorkstationsOU = "OU=Workstations,$ComputersOU"
```

Valeur :

```text
OU=Workstations,OU=Computers,OU=Diarabaka,DC=diarabaka,DC=com
```

Les chemins historiques :

```text
OU=Workstations,DC=diarabaka,DC=com
```

ne doivent plus être utilisés dans cette phase.

---

# 05.5 - Vérifier les OU

```powershell
Get-ADOrganizationalUnit -Filter * |
    Select-Object `
        Name,
        DistinguishedName |
    Sort-Object DistinguishedName |
    Format-Table -AutoSize
```

Vérifier spécifiquement :

```powershell
Get-ADOrganizationalUnit `
    -Identity "OU=Workstations,OU=Computers,OU=Diarabaka,DC=diarabaka,DC=com"
```

.

---

# 05.6 - Vérifier WIN11

```powershell
Get-ADComputer WIN11 |
    Select-Object `
        Name,
        DistinguishedName
```

Cible :

```text
CN=WIN11,OU=Workstations,OU=Computers,OU=Diarabaka,DC=diarabaka,DC=com
```

Si WIN11 se trouve encore dans le conteneur natif :

```text
CN=WIN11,CN=Computers,DC=diarabaka,DC=com
```

déplacement contrôlé :

```powershell
Get-ADComputer WIN11 |
    Move-ADObject `
        -TargetPath "OU=Workstations,OU=Computers,OU=Diarabaka,DC=diarabaka,DC=com"
```

Puis vérifier de nouveau.

---

# 05.7 - Ne pas toucher aux Domain Controllers avec les GPO Workstation

Les DC restent dans :

```text
OU=Domain Controllers,DC=diarabaka,DC=com
```

Architecture :

```text
Domain Controllers
├── DC01
└── DC02

Diarabaka
└── Computers
    └── Workstations
        └── WIN11
```

Les GPO Windows 11 sont liées uniquement à :

```text
OU=Workstations,OU=Computers,OU=Diarabaka,...
```

---

# 05.8 - GPO Inventory détaillé

```powershell
Get-GPO -All |
    ForEach-Object {

        [PSCustomObject]@{
            DisplayName      = $_.DisplayName
            Id               = $_.Id
            GpoStatus        = $_.GpoStatus
            CreationTime     = $_.CreationTime
            ModificationTime = $_.ModificationTime
            Owner            = $_.Owner
        }
    } |
    Sort-Object DisplayName |
    Format-Table -AutoSize
```

Identifier :

```text
Default Domain Policy
Default Domain Controllers Policy
GPO-WS-Security-Baseline
GPO-Windows11-BitLocker
GPO-Windows11-LAPS
Other custom GPOs
Disabled GPOs
Unused GPOs
```

---

# 05.9 - Baseline des liens et de l'héritage

```powershell
Get-GPInheritance `
    -Target "OU=Workstations,OU=Computers,OU=Diarabaka,DC=diarabaka,DC=com"
```

---

# 05.10 - Precedence Group Policy

Ordre conceptuel :

```text
Local
  ↓
Site
  ↓
Domain
  ↓
OU parent
  ↓
OU child
```

LSDOU :

```text
L = Local
S = Site
D = Domain
OU = Organizational Units
```

À un niveau donné, la precedence dépend de l'ordre des liens.

Validation :

```text
GPO PRESENT
+
CORRECT LINK ORDER
+
NO CONFLICT
=
EXPECTED EFFECTIVE SETTING
```

---

# 05.11 - Block Inheritance / Enforced

Inventorier :

```powershell
Get-GPInheritance `
    -Target "OU=Workstations,OU=Computers,OU=Diarabaka,DC=diarabaka,DC=com" |
    Format-List *
```

Règle :

```text
BLOCK INHERITANCE
    → use only with justification

ENFORCED
    → use only with justification
```

Ne pas utiliser ces options pour résoudre rapidement un conflit sans comprendre l'impact.

---

# 05.12 - Security Filtering

Pour chaque GPO importante :

```powershell
Get-GPPermission `
    -Name "GPO-WS-Security-Baseline" `
    -All
```

Puis :

```powershell
Get-GPPermission `
    -Name "GPO-Windows11-BitLocker" `
    -All
```

Puis :

```powershell
Get-GPPermission `
    -Name "GPO-Windows11-LAPS" `
    -All
```

Vérifier notamment :

```text
Read
Apply Group Policy
Edit settings
Edit/Delete/Modify Security
```

Une GPO peut être liée et pourtant ne pas s'appliquer si l'objet n'a pas les droits nécessaires.

---

# 05.13 - WMI Filters

Inventorier les éventuels WMI Filters via GPMC et les rapports de GPO.

Dans le rapport HTML/XML, vérifier si une GPO est associée à un filtre WMI.

Principe :

```text
GPO LINKED
   +
SECURITY ALLOWS
   +
WMI FILTER TRUE
   =
ELIGIBLE FOR APPLICATION
```

Si aucun WMI filter n'est requis dans ce lab, ne pas en créer artificiellement.

---

# 05.14 - Créer `GPO-WS-Security-Baseline`

Vérifier d'abord :

```powershell
Get-GPO `
    -Name "GPO-WS-Security-Baseline" `
    -ErrorAction SilentlyContinue
```

Si absente :

```powershell
New-GPO `
    -Name "GPO-WS-Security-Baseline" `
    -Comment "Windows 11 workstation security baseline"
```

Puis :

```powershell
Get-GPO `
    -Name "GPO-WS-Security-Baseline"
```

---

# 05.15 - Lier Security Baseline

Avant création du lien :

```powershell
Get-GPInheritance `
    -Target "OU=Workstations,OU=Computers,OU=Diarabaka,DC=diarabaka,DC=com"
```

Si lien absent :

```powershell
New-GPLink `
    -Name "GPO-WS-Security-Baseline" `
    -Target "OU=Workstations,OU=Computers,OU=Diarabaka,DC=diarabaka,DC=com" `
    -LinkEnabled Yes
```

Puis vérifier.

---

# 05.16 - Windows Defender Firewall

Configurer dans :

```text
GPO-WS-Security-Baseline
  ↓
Computer Configuration
  ↓
Policies
  ↓
Windows Settings
  ↓
Security Settings
  ↓
Windows Defender Firewall with Advanced Security
```

Cible :

```text
Domain Profile  → Enabled
Private Profile → Enabled
Public Profile  → Enabled
```

---

# 05.17 - Validation Firewall effective

Sur WIN11 :

```powershell
Get-NetFirewallProfile |
    Select-Object `
        Name,
        Enabled,
        DefaultInboundAction,
        DefaultOutboundAction
```

Puis :

```powershell
Get-NetConnectionProfile
```

Objectif :

```text
Domain  : Enabled
Private : Enabled
Public  : Enabled
```

Mais la validation ne s'arrête pas là.

---

# 05.18 - Validation Firewall fonctionnelle

Vérifier qu'une règle nécessaire n'est pas cassée par la baseline.

Par exemple, si WinRM est utilisé dans le lab :

```powershell
Test-WSMan WIN11
```

ou depuis un serveur :

```powershell
Test-NetConnection WIN11 -Port 5985
```

uniquement si WinRM est volontairement activé.

Règle :

```text
FIREWALL ON
    +
REQUIRED MANAGEMENT STILL WORKS
    =
FUNCTIONAL VALIDATION
```

---

# 05.19 - Microsoft Defender Antivirus

Dans :

```text
GPO-WS-Security-Baseline
  ↓
Computer Configuration
  ↓
Policies
  ↓
Administrative Templates
  ↓
Windows Components
  ↓
Microsoft Defender Antivirus
```

Attention aux paramètres à logique négative.

Exemple :

```text
Turn off real-time protection
```

Pour garder la protection active :

```text
Policy = Disabled
```

---

# 05.20 - Defender Cloud Protection

Selon les ADMX réellement installés :

```text
Microsoft Defender Antivirus
  ↓
MAPS / Cloud Protection
```

Objectif :

```text
Cloud-delivered protection → Enabled / active
Automatic sample submission → policy reviewed
```

Ne pas inventer le chemin exact si l'ADMX présent utilise un libellé différent.

---

# 05.21 - Validation Defender effective

Sur WIN11 :

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

Puis :

```powershell
Get-MpPreference |
    Select-Object `
        DisableRealtimeMonitoring,
        MAPSReporting,
        SubmitSamplesConsent
```

Cible : aucune stratégie ne doit désactiver les protections attendues.

---

# 05.22 - Windows Update

Configurer une politique cohérente dans :

```text
Computer Configuration
  ↓
Policies
  ↓
Administrative Templates
  ↓
Windows Components
  ↓
Windows Update
```

Baseline du lab :

```text
Configure Automatic Updates : Enabled
Mode                        : 4
Scheduled day               : Sunday
Scheduled time              : 03:00
```

Les noms de catégories peuvent varier selon les ADMX.

---

# 05.23 - Validation Windows Update

Sur WIN11, produire le RSoP :

```powershell
gpresult /scope computer /h C:\Temp\GPResult-WindowsUpdate.html
```

Puis :

```powershell
Get-WindowsUpdateLog
```

si une analyse du client Windows Update est requise.

Vérifier également les paramètres effectifs via le rapport `gpresult` plutôt que de supposer qu'ils sont actifs parce que la GPO est liée.

---

# 05.24 - Application Security Baseline

Sur WIN11 :

```powershell
gpupdate /force
```

Puis :

```powershell
gpresult /r /scope computer
```

Créer un rapport :

```powershell
New-Item `
    -Path "C:\Temp" `
    -ItemType Directory `
    -Force |
    Out-Null
```

```powershell
gpresult `
    /scope computer `
    /h C:\Temp\GPResult-Security.html
```

Vérifier :

```powershell
Test-Path C:\Temp\GPResult-Security.html
```

---

# 05.25 - Applied et Denied GPOs

Dans `gpresult`, examiner :

```text
Applied Group Policy Objects
Denied Group Policy Objects
Filtering reason
Security
WMI
```

Une GPO dans `Denied` est une information de diagnostic importante.

---

# 05.26 - Créer `GPO-Windows11-BitLocker`

Baseline préalable :

```powershell
Get-GPO `
    -Name "GPO-Windows11-BitLocker" `
    -ErrorAction SilentlyContinue
```

Si absente :

```powershell
New-GPO `
    -Name "GPO-Windows11-BitLocker" `
    -Comment "BitLocker policy for Windows 11 workstations"
```

Lien :

```powershell
New-GPLink `
    -Name "GPO-Windows11-BitLocker" `
    -Target "OU=Workstations,OU=Computers,OU=Diarabaka,DC=diarabaka,DC=com" `
    -LinkEnabled Yes
```

uniquement si le lien n'existe pas déjà.

---

# 05.27 - BitLocker Pre-check

Sur WIN11 :

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

Si le disque est déjà chiffré, ne pas relancer le chiffrement.

---

# 05.28 - BitLocker Recovery Policy

Dans :

```text
GPO-Windows11-BitLocker
  ↓
Computer Configuration
└── Policies
    └── Administrative Templates
        └── Windows Components
            └── BitLocker Drive Encryption
                └── Operating System Drives
                    └── Choose how BitLocker-protected operating system drives can be recovered
```

`Enabled`

```
Choose how BitLocker-protected operating system drives can be recovered

(*) Enabled

Options:

☑ Allow data recovery agent
☑ Save BitLocker recovery information to AD DS
☑ Do not enable BitLocker until recovery information is stored to AD DS

☑ 48-digit recovery password

Recovery passwords and key packages
```

Configurer la récupération AD DS.

Objectif :

```text
Recovery Password
+
Recovery information backed up to AD DS
+
Do not enable until required recovery information is stored
```

---

# 05.29 - Appliquer BitLocker GPO

Sur WIN11 :

```powershell
gpupdate /force
```

Puis :

```powershell
gpresult /r /scope computer
```

Rapport :

```powershell
gpresult `
    /scope computer `
    /h C:\Temp\GPResult-BitLocker.html
```

Vérifier que :

```text
GPO-Windows11-BitLocker
```

est appliquée et non refusée.

---

# 05.30 - Vérifier les protecteurs BitLocker

```powershell
manage-bde -protectors -get C:
```

Cible :

```text
TPM
+
Numerical Password
```

Si un TPM protector est absent et que son ajout est réellement requis :

```powershell
Add-BitLockerKeyProtector `
    -MountPoint "C:" `
    -TpmProtector
```

Ne pas dupliquer un protector existant.

---

# 05.31 - Recovery Password Protector

Si absent :

```powershell
Add-BitLockerKeyProtector `
    -MountPoint "C:" `
    -RecoveryPasswordProtector
```

Puis :

```powershell
manage-bde -protectors -get C:
```

Pour evidence :

```text
Recovery Password : <REDACTED>
Protector ID       : <SAFE/REDACTED AS NEEDED>
```

---

# 05.32 - Vérifier backup BitLocker dans AD

Récupérer d'abord le DN réel de WIN11 :

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

Cette méthode évite de coder un ancien DN en dur.

Cible :

```text
msFVE-RecoveryInformation
```

présent sous l'objet ordinateur.

---

# 05.33 - Validation BitLocker

Sur WIN11 :

```powershell
manage-bde -status C:
```

Puis :

```powershell
manage-bde -protectors -get C:
```

Puis sur DC01 :

```powershell
$ComputerDN = (
    Get-ADComputer WIN11
).DistinguishedName

Get-ADObject `
    -Filter 'objectClass -eq "msFVE-RecoveryInformation"' `
    -SearchBase $ComputerDN |
    Select-Object `
        Name,
        ObjectClass
```

Validation complète :

```text
GPO applied
+
TPM ready
+
Volume encrypted
+
Protection ON
+
TPM protector
+
Recovery password protector
+
Recovery object in AD
=
BITLOCKER VALIDATED
```

---

# 05.34 - BitLocker VMware Incident

Incident possible :

```text
BitLocker Drive Encryption detected bootable media
```

Diagnostic :

```text
WIN11 VM
  ↓
CD/DVD
  ↓
Connected?
ISO mounted?
Connect at power on?
```

Correction uniquement si confirmée :

```text
Disconnect virtual CD/DVD
Remove mounted ISO
Reboot
Retest TPM
Retest protectors
Retest BitLocker
```

---

# 05.35 - Windows LAPS Pre-check

Sur DC01 :

```powershell
Get-Module -ListAvailable LAPS
```

Puis :

```powershell
Get-Command -Module LAPS
```

Vérifier notamment :

```text
Update-LapsADSchema
Set-LapsADComputerSelfPermission
Find-LapsADExtendedRights
Get-LapsADPassword
Get-LapsDiagnostics
Invoke-LapsPolicyProcessing
```

---

# 05.36 - Windows LAPS Schema

Vérifier :

```powershell
Get-ADObject `
    -SearchBase (Get-ADRootDSE).SchemaNamingContext `
    -LDAPFilter "(lDAPDisplayName=msLAPS-*)" `
    -Properties lDAPDisplayName |
    Select-Object `
        Name,
        lDAPDisplayName
```

Si les attributs requis sont présents :

```text
VERIFY ONLY
```

Sinon, seulement avec les droits appropriés :

```powershell
Update-LapsADSchema
```

Puis retester.

---

# 05.37 - LAPS OU Self Permission

Utiliser le DN canonique :

```powershell
$WorkstationsOU = "OU=Workstations,OU=Computers,OU=Diarabaka,DC=diarabaka,DC=com"
```

Configurer :

```powershell
Set-LapsADComputerSelfPermission `
    -Identity $WorkstationsOU
```

Puis :

```powershell
Find-LapsADExtendedRights `
    -Identity $WorkstationsOU
```

---

# 05.38 - LAPS Read Permissions

Les droits de lecture du mot de passe doivent être limités aux administrateurs/groupes prévus.

Auditer :

```powershell
Find-LapsADExtendedRights `
    -Identity "OU=Workstations,OU=Computers,OU=Diarabaka,DC=diarabaka,DC=com"
```

Documenter les principals autorisés.

Principe :

```text
COMPUTERS
   → self-write

AUTHORIZED ADMIN GROUP
   → read/decrypt as designed

NORMAL USERS
   → no password access
```

---

# 05.39 - Créer `GPO-Windows11-LAPS`

Vérifier :

```powershell
Get-GPO `
    -Name "GPO-Windows11-LAPS" `
    -ErrorAction SilentlyContinue
```

Si absente :

```powershell
New-GPO `
    -Name "GPO-Windows11-LAPS" `
    -Comment "Windows LAPS policy for Windows 11 workstations"
```

Puis lien :

```powershell
New-GPLink `
    -Name "GPO-Windows11-LAPS" `
    -Target "OU=Workstations,OU=Computers,OU=Diarabaka,DC=diarabaka,DC=com" `
    -LinkEnabled Yes
```

si absent.

---

# 05.40 - Configurer Windows LAPS

Dans :

```text
Computer Configuration
└── Policies
    └── Administrative Templates
        └── System
            └── LAPS
```

```
| Paramètre Windows LAPS                           | État             | Valeur                                          |
| ------------------------------------------------ | -----------------| ----------------------------------------------- |
| **Configure password backup directory**          | `Enabled`        | `Active Directory`                              |
| **Password Settings**                            | `Enabled`        | Length `14`, Age `30`, complexité forte         |
| **Enable password encryption**                   | `Enabled`        | Chiffrement dans AD DS                          |
| **Post-authentication actions**                  | Optionnel        | Tu peux laisser `Not Configured` pour l'instant |

```

Baseline :

**Configure password backup directory**

```text
Active Directory
```

Dans **Password Settings** :

```text
Enabled

Password complexity:
→ Large letters + small letters + numbers + special characters

Password length:
→ 14

Password age (days):
→ 30
```

Pour **Post-authentication actions**, une baseline raisonnable est :

```text
Enabled

Grace period:
→ 8 hours

Actions:
→ Reset the password and logoff the managed account
```

```text
System
└── LAPS
    │
    ├── Configure password backup directory
    │      └── Enabled
    │          └── Active Directory
    │
    ├── Password Settings
    │      └── Enabled
    │          ├── Password complexity : forte
    │          ├── Password length     : 14
    │          └── Password age        : 30 days
    │
    └── Enable password encryption
           └── Enabled
```

La stratégie exacte du mot de passe doit être documentée depuis les paramètres effectifs.

---

# 05.41 - LAPS account strategy

Identifier quel compte local est géré.

Sur WIN11 :

```powershell
Get-LocalUser |
    Select-Object `
        Name,
        Enabled,
        SID
```

Ne pas supposer automatiquement que le compte s'appelle :

```text
Administrator
```

sur toutes les machines.

---

# 05.42 - Appliquer LAPS

Sur WIN11 :

```powershell
gpupdate /force
```

Puis :

```powershell
Invoke-LapsPolicyProcessing
```

Puis :

```powershell
gpresult /r /scope computer
```

---

# 05.43 - LAPS Diagnostics

Sur WIN11 :

```powershell
Get-LapsDiagnostics
```

Puis :

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

Analyser :

```text
Policy processing
Password generation
Password update
AD backup
Rotation
Errors
```

---

# 05.44 - LAPS AD Verification sans révéler le secret

Sur DC01 :

```powershell
Get-LapsADPassword `
    -Identity "WIN11"
```

Ne pas utiliser `-AsPlainText` dans les preuves.

Pour evidence publique :

```text
Identity             : WIN11
Password present     : YES
Password             : <REDACTED>
Expiration           : <SAFE VALUE OR REDACTED>
Authorized retrieval : CONFIRMED
```

---

# 05.46 - User Configuration

Les GPO ordinateur et utilisateur ne suivent pas le même objet.

```text
Computer GPO:
WIN11
 ↓
OU=Workstations
 ↓
Computer Configuration
```

```text
User GPO:
User account
 ↓
OU=IT / HR / Finance / Marketing / Sales
 ↓
User Configuration
```

Chemins utilisateurs :

```text
OU=IT,OU=Users,OU=Diarabaka,DC=diarabaka,DC=com
OU=HR,OU=Users,OU=Diarabaka,DC=diarabaka,DC=com
OU=Finance,OU=Users,OU=Diarabaka,DC=diarabaka,DC=com
OU=Marketing,OU=Users,OU=Diarabaka,DC=diarabaka,DC=com
OU=Sales,OU=Users,OU=Diarabaka,DC=diarabaka,DC=com
```

---

# 05.47 - Loopback Processing

Dans ce lab, ne pas activer le loopback sans besoin.

Concept :

```text
Merge
or
Replace
```

Utilisable dans certains scénarios de machines partagées, kiosques, RDS, salles de formation, etc.

Mais :

```text
LOOPBACK
   ≠
normal solution for every user policy problem
```

---

# 05.48 - GPO Status

Auditer :

```powershell
Get-GPO -All |
    Select-Object `
        DisplayName,
        GpoStatus
```

Valeurs possibles :

```text
AllSettingsEnabled
ComputerSettingsDisabled
UserSettingsDisabled
AllSettingsDisabled
```

Une GPO Computer avec Computer Settings Disabled ne peut pas appliquer ses paramètres ordinateur.

---

# 05.49 - Backup des GPO

Avant changement important :

```powershell
$BackupPath = "C:\Evidence\GroupPolicy\15-Backup-Restore"
```

Puis :

```powershell
Backup-GPO `
    -Name "GPO-WS-Security-Baseline" `
    -Path $BackupPath
```

```powershell
Backup-GPO `
    -Name "GPO-Windows11-BitLocker" `
    -Path $BackupPath
```

```powershell
Backup-GPO `
    -Name "GPO-Windows11-LAPS" `
    -Path $BackupPath
```

---

# 05.50 - Vérifier les backups GPO

```powershell
Get-ChildItem `
    "C:\Evidence\GroupPolicy\15-Backup-Restore" `
    -Recurse |
    Select-Object `
        FullName,
        Length,
        LastWriteTime
```

---

# 05.51 - SYSVOL

Une GPO comprend deux composantes principales :

```text
GPC
Group Policy Container
→ Active Directory

GPT
Group Policy Template
→ SYSVOL
```

Une GPO cohérente nécessite que les deux soient disponibles.

---

# 05.52 - Vérifier SYSVOL / NETLOGON

Depuis WIN11 :

```powershell
Test-Path "\\diarabaka.com\SYSVOL"
```

Puis :

```powershell
Test-Path "\\diarabaka.com\NETLOGON"
```

Cible :

```text
True
True
```

Puis :

```powershell
Get-ChildItem "\\diarabaka.com\SYSVOL\diarabaka.com\Policies" |
    Select-Object Name
```

---

# 05.53 - Vérifier GPO GUID dans SYSVOL

Récupérer le GUID :

```powershell
$Gpo = Get-GPO `
    -Name "GPO-WS-Security-Baseline"

$Gpo.Id
```

Puis :

```powershell
$PolicyPath = "\\diarabaka.com\SYSVOL\diarabaka.com\Policies\{$($Gpo.Id)}"

Test-Path $PolicyPath
```

Puis :

```powershell
Test-Path "$PolicyPath\gpt.ini"
```

---

# 05.54 - Vérifier `gpt.ini`

```powershell
Get-Content `
    "\\diarabaka.com\SYSVOL\diarabaka.com\Policies\{$((Get-GPO -Name 'GPO-WS-Security-Baseline').Id)}\gpt.ini"
```

Cette vérification prouve l'accès au GPT dans SYSVOL.

---

# 05.55 - AD Replication avant troubleshooting GPO

Sur DC01 :

```powershell
repadmin /replsummary
```

Puis :

```powershell
repadmin /showrepl DC01
```

Puis :

```powershell
repadmin /showrepl DC02
```

Puis :

```powershell
dcdiag /test:replications
```

Ne pas déclarer la réplication saine avant résultat réel.

---

# 05.56 - SYSVOL DFSR Health

Vérifier les journaux DFS Replication :

```powershell
Get-WinEvent `
    -LogName "DFS Replication" `
    -MaxEvents 100 |
    Select-Object `
        TimeCreated,
        Id,
        LevelDisplayName,
        Message
```

Une GPO visible dans AD mais non disponible correctement dans SYSVOL peut créer un problème de traitement.

---

# 05.57 - DC utilisé par WIN11

Sur WIN11 :

```powershell
echo $env:LOGONSERVER
```

Puis :

```powershell
nltest /dsgetdc:diarabaka.com
```

Documenter le DC réellement utilisé pendant le test.

---

# 05.58 - GPUpdate

Sur WIN11 :

```powershell
gpupdate /force
```

Résultat :

```text
gpupdate succeeded
```

---

# 05.59 - GPResult / RSoP

```powershell
gpresult /r /scope computer
```

Rapport HTML :

```powershell
gpresult `
    /scope computer `
    /h C:\Temp\GPResult-Computer.html
```

Vérifier :

```text
Applied GPOs
Denied GPOs
Security groups
WMI filters
Last Group Policy application
Source DC
```

---

# 05.60 - Group Policy Operational Log

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

Ce journal doit être utilisé lorsque `gpresult` seul n'explique pas le problème.

---

# 05.61 - Troubleshooting Workflow

# 05.62 - Incident GPO-INC-001 : GPO absente de gpresult

Vérifier :

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

Puis permissions :

```powershell
Get-GPPermission `
    -Name "<GPO_NAME>" `
    -All
```

Puis client :

```powershell
gpresult /r /scope computer
```

---

# 05.63 - Incident GPO-INC-002 : GPO Denied

Dans `gpresult`, identifier :

```text
Denied GPO
Filtering reason
```

Causes possibles :

```text
Security filtering
Missing Apply Group Policy
Missing Read
WMI filter false
Computer/User side disabled
```

Corriger uniquement la cause confirmée.

---

# 05.64 - Incident GPO-INC-003 : GPO appliquée mais setting incorrect

Vérifier :

```text
Conflicting GPO?
Higher precedence?
Local setting?
MDM / other management?
GPO setting actually configured?
```

Puis comparer RSoP et état fonctionnel.

---

# 05.65 - Incident GPO-INC-004 : SYSVOL inaccessible

Sur WIN11 :

```powershell
Test-Path "\\diarabaka.com\SYSVOL"
Test-Path "\\diarabaka.com\NETLOGON"
```

Puis :

```powershell
Resolve-DnsName diarabaka.com
nltest /dsgetdc:diarabaka.com
```

Puis côté DC :

```powershell
repadmin /replsummary
```

Ne pas recréer la GPO avant diagnostic.

---

# 05.66 - Incident GPO-INC-005 : BitLocker GPO appliquée mais recovery absent

Vérifier :

```powershell
gpresult /r /scope computer
manage-bde -protectors -get C:
```

Puis :

```powershell
$ComputerDN = (
    Get-ADComputer WIN11
).DistinguishedName

Get-ADObject `
    -Filter 'objectClass -eq "msFVE-RecoveryInformation"' `
    -SearchBase $ComputerDN
```

Distinguer :

```text
GPO application
Protector creation
AD backup
```

---

# 05.67 - Incident GPO-INC-006 : LAPS password absent

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
Find-LapsADExtendedRights `
    -Identity "OU=Workstations,OU=Computers,OU=Diarabaka,DC=diarabaka,DC=com"
```

---

# 05.68 - Final Audit DC01

```powershell
Get-GPO -All |
    Select-Object `
        DisplayName,
        Id,
        GpoStatus |
    Sort-Object DisplayName
```

Puis :

```powershell
Get-GPInheritance `
    -Target "OU=Workstations,OU=Computers,OU=Diarabaka,DC=diarabaka,DC=com"
```

Puis :

```powershell
Get-ADComputer WIN11 |
    Select-Object `
        Name,
        DistinguishedName
```

---

# 05.69 - Final Audit WIN11

```powershell
gpupdate /force
```

Puis :

```powershell
gpresult /r /scope computer
```

Puis :

```powershell
Get-NetFirewallProfile |
    Select-Object `
        Name,
        Enabled
```

Puis :

```powershell
Get-MpComputerStatus |
    Select-Object `
        AntivirusEnabled,
        RealTimeProtectionEnabled
```

Puis :

```powershell
Get-BitLockerVolume `
    -MountPoint "C:" |
    Select-Object `
        MountPoint,
        VolumeStatus,
        ProtectionStatus,
        EncryptionPercentage
```

Puis :

```powershell
Get-Tpm
```

Puis :

```powershell
manage-bde -protectors -get C:
```

Puis :

```powershell
Get-WinEvent `
    -LogName "Microsoft-Windows-LAPS/Operational" `
    -MaxEvents 20
```

---

# 05.70 - Final Audit AD Recovery

BitLocker :

```powershell
$ComputerDN = (
    Get-ADComputer WIN11
).DistinguishedName

Get-ADObject `
    -Filter 'objectClass -eq "msFVE-RecoveryInformation"' `
    -SearchBase $ComputerDN |
    Select-Object `
        Name,
        ObjectClass
```

LAPS :

```powershell
Get-LapsADPassword `
    -Identity "WIN11"
```

Ne pas publier les secrets.

---

# 05.71 - Post-Reboot Validation

Redémarrer WIN11 de manière contrôlée :

```powershell
Restart-Computer
```

Après reboot :

```powershell
gpresult /r /scope computer
```

Puis :

```powershell
Get-NetFirewallProfile |
    Select-Object `
        Name,
        Enabled
```

```powershell
Get-MpComputerStatus |
    Select-Object `
        AntivirusEnabled,
        RealTimeProtectionEnabled
```

```powershell
Get-BitLockerVolume -MountPoint "C:"
```

```powershell
Get-Tpm
```

```powershell
manage-bde -protectors -get C:
```

```powershell
Get-WinEvent `
    -LogName "Microsoft-Windows-LAPS/Operational" `
    -MaxEvents 20
```

---

# 05.72 - Final Regression Test

Sur DC01 :

```powershell
repadmin /replsummary
```

Puis :

```powershell
Get-GPInheritance `
    -Target "OU=Workstations,OU=Computers,OU=Diarabaka,DC=diarabaka,DC=com"
```

Sur WIN11 :

```powershell
gpupdate /force
gpresult /r /scope computer
```

---

# 05.77 - Final Architecture

```text
                         DIARABAKA.COM
                              │
              ┌───────────────┴────────────────┐
              │                                │
              ▼                                ▼
     Domain Controllers                  OU=Diarabaka
         DC01 / DC02                          │
                                              ▼
                                        OU=Computers
                                              │
                                              ▼
                                      OU=Workstations
                                              │
                                              ▼
                                            WIN11
                                              │
                 ┌────────────────────────────┼────────────────────────────┐
                 │                            │                            │
                 ▼                            ▼                            ▼
   GPO-WS-Security-Baseline       GPO-Windows11-BitLocker       GPO-Windows11-LAPS
                 │                            │                            │
        ┌────────┼────────┐                   │                            │
        │        │        │                   │                            │
        ▼        ▼        ▼                   ▼                            ▼
    Firewall  Defender  Windows Update     BitLocker                   Local Admin
                                                │                         │
                                                ▼                         ▼
                                            TPM + Recovery             Password Rotation
                                                │                         │
                                                ▼                         ▼
                                          Recovery in AD              Backup in AD
```
