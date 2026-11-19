# 12 --- ROUTINE QUOTIDIENNE, GOUVERNANCE & CHANGE MANAGEMENT

## 12.0 --- Objectif

Maintenir l'infrastructure dans un état connu, stable, sécurisé et
récupérable.

```text
KNOWN BASELINE
      ↓
OBSERVE
      ↓
COMPARE
      ↓
DEVIATION?
 ┌────┴────┐
 NO       YES
 │          ↓
 │       ASSESS
 │          ↓
 │       INCIDENT / CHANGE?
 │          ↓
 │       CONTROLLED ACTION
 │          ↓
 └────────VALIDATE
            ↓
         DOCUMENT
```

```text
ALERT ≠ ROOT CAUSE
WARNING ≠ OUTAGE
EVENT ≠ INCIDENT
SERVICE STOPPED ≠ ALWAYS BROKEN
```

## 12.1 --- Fréquences

Fréquence Objectif

---

Daily Disponibilité et défaillances majeures
Weekly Dérive, sécurité, capacité, hygiène
Monthly Gouvernance, récupération, documentation
After Change Confirmer l'état cible et les dépendances
After Incident Confirmer le retour du service

## 12.2 --- Morning Health Check

Contrôle court :

```text
AD → REPLICATION → DNS → DHCP → FILE01 → STORAGE → BACKUP → CRITICAL EVENTS
```

### AD

```powershell
Get-ADDomainController -Filter * |
Select-Object HostName,IPv4Address,Site,IsGlobalCatalog,IsReadOnly

netdom query fsmo
```

Attendu : DC01 et DC02 explicitement. Les deux GC doivent être vérifiés
selon la baseline réelle.

### Replication

```powershell
repadmin /replsummary
repadmin /showrepl DC01
repadmin /showrepl DC02
```

Ne jamais déclarer la réplication saine avant une sortie actuelle.

### DNS

Tester chaque DNS directement pour éviter qu'un partenaire sain masque
l'autre :

```powershell
Resolve-DnsName "_ldap._tcp.dc._msdcs.diarabaka.com" `
    -Type SRV -Server 192.168.1.10

Resolve-DnsName "_ldap._tcp.dc._msdcs.diarabaka.com" `
    -Type SRV -Server 192.168.1.11

Resolve-DnsName "_kerberos._tcp.diarabaka.com" `
    -Type SRV -Server 192.168.1.10

Resolve-DnsName "_kerberos._tcp.diarabaka.com" `
    -Type SRV -Server 192.168.1.11
```

### DHCP

```powershell
Get-Service -ComputerName DC01 -Name DHCPServer
Get-Service -ComputerName DC02 -Name DHCPServer

Get-DhcpServerv4Scope -ComputerName DC01

Get-DhcpServerv4ScopeStatistics `
    -ComputerName DC01 `
    -ScopeId 192.168.1.0

Get-DhcpServerv4Failover -ComputerName DC01 | Format-List
Get-DhcpServerv4Failover -ComputerName DC02 | Format-List
```

### FILE01

```powershell
Get-Service -ComputerName FILE01 -Name LanmanServer
Test-NetConnection FILE01 -Port 445
```

### Storage

```powershell
Invoke-Command -ComputerName FILE01 -ScriptBlock {
    Get-Volume |
    Where-Object DriveLetter |
    Select-Object DriveLetter,FileSystemLabel,HealthStatus,
        @{N='SizeGB';E={[math]::Round($_.Size/1GB,2)}},
        @{N='FreeGB';E={[math]::Round($_.SizeRemaining/1GB,2)}},
        @{N='FreePercent';E={
            if ($_.Size -gt 0) {
                [math]::Round(($_.SizeRemaining/$_.Size)*100,2)
            }
        }}
}
```

### Backup

```powershell
Invoke-Command -ComputerName FILE01 -ScriptBlock {
    wbadmin get versions
}
```

Une version visible n'est pas un restore test.

### Events

```powershell
$Since = (Get-Date).AddHours(-24)

Get-WinEvent -FilterHashtable @{
    LogName   = 'System'
    StartTime = $Since
} -ErrorAction SilentlyContinue |
Where-Object { $_.LevelDisplayName -in 'Critical','Error' } |
Select-Object TimeCreated,Id,ProviderName,LevelDisplayName,Message
```

Classer les événements selon pertinence, répétition et impact ; ne pas
transformer chaque erreur en incident.

## 12.3 --- Routine hebdomadaire

### Utilisateurs

```powershell
Get-ADUser -Filter 'Enabled -eq $false' |
Select-Object Name,SamAccountName

Search-ADAccount -UsersOnly -AccountExpired
Search-ADAccount -UsersOnly -LockedOut

Search-ADAccount -UsersOnly -AccountInactive -TimeSpan 90.00:00:00
```

Les résultats inactifs sont une liste de revue, pas une liste de
suppression.

### Groupes privilégiés

```powershell
Get-ADGroupMember "Domain Admins" -Recursive
Get-ADGroupMember "Enterprise Admins" -Recursive
Get-ADGroupMember "Administrators" -Recursive
Get-ADGroupMember "GG-IT-Admins" -Recursive
```

Comparer à une baseline approuvée :

```text
CURRENT MEMBERS → COMPARE → APPROVED MEMBERS → INVESTIGATE DIFFERENCE
```

### Ordinateurs

```powershell
Get-ADComputer -Filter * -Properties OperatingSystem,Enabled,LastLogonDate |
Select-Object Name,Enabled,OperatingSystem,LastLogonDate

Search-ADAccount -ComputersOnly -AccountInactive -TimeSpan 90.00:00:00
```

### GPO

OU canonique :

```text
OU=Workstations,OU=Computers,OU=Diarabaka,DC=diarabaka,DC=com
```

```powershell
Get-GPO -All |
Select-Object DisplayName,GpoStatus,CreationTime,ModificationTime

Get-GPInheritance `
    -Target "OU=Workstations,OU=Computers,OU=Diarabaka,DC=diarabaka,DC=com"
```

Une modification de date est un signal à corréler avec le change log.

### FILE01 / AGDLP

```powershell
Invoke-Command -ComputerName FILE01 -ScriptBlock {
    Get-SmbShare |
    Select-Object Name,Path,Description

    foreach ($Share in 'IT$','HR$','Finance$','Marketing$','Sales$','Public$') {
        Get-SmbShareAccess -Name $Share
    }
}
```

Découvrir les chemins avant `icacls` :

```powershell
Invoke-Command -ComputerName FILE01 -ScriptBlock {
    foreach ($ShareName in 'IT$','HR$','Finance$','Marketing$','Sales$','Public$') {
        $Share = Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue
        if ($Share) {
            Write-Host "=== $ShareName : $($Share.Path) ==="
            icacls $Share.Path
        }
    }
}
```

Vérifier le modèle :

```text
Accounts → GG-Department → DL-FS-Resource-Modify/Read → SMB/NTFS
```

### FSRM

```powershell
Invoke-Command -ComputerName FILE01 -ScriptBlock {
    Get-FsrmQuota |
    Select-Object Path,Size,Usage,Disabled,SoftLimit,Status,Description
}
```

### WIN11 sécurité

```powershell
gpresult /r

Get-MpComputerStatus |
Select-Object AntivirusEnabled,RealTimeProtectionEnabled,
    BehaviorMonitorEnabled,AntivirusSignatureLastUpdated

Get-NetFirewallProfile |
Select-Object Name,Enabled,DefaultInboundAction,DefaultOutboundAction

Get-BitLockerVolume -MountPoint "C:" |
Select-Object MountPoint,VolumeStatus,ProtectionStatus,EncryptionPercentage

Get-Tpm |
Select-Object TpmPresent,TpmReady,TpmEnabled

Get-LocalGroupMember -Group "Administrators"
```

### LAPS

Ne pas exposer le secret :

```powershell
Get-WinEvent -LogName "Microsoft-Windows-LAPS/Operational" -MaxEvents 30 |
Select-Object TimeCreated,Id,LevelDisplayName,Message

Get-LapsDiagnostics
```

La récupération administrative peut être testée avec
`Get-LapsADPassword -Identity WIN11`, mais les preuves publiques doivent
masquer toute valeur secrète.

## 12.4 --- Routine mensuelle

Revoir :

```text
AD OBJECT HYGIENE
PRIVILEGED ACCESS
GPO INVENTORY
SERVER INVENTORY
CAPACITY TREND
BACKUP HISTORY
RESTORE READINESS
DOCUMENTATION
CHANGE HISTORY
RUNBOOKS
OPEN RISKS
```

Inclure un test de récupération contrôlé :

```text
SELECT TEST DATA
   ↓
CAPTURE HASH + ACL
   ↓
CONFIRM BACKUP INCLUDES DATA
   ↓
CONTROLLED LOSS / ALTERNATE RESTORE
   ↓
RESTORE
   ↓
HASH MATCH
   ↓
ACL / CONTENT CHECK
   ↓
DOCUMENT
```

## 12.5 --- Documentation repository

```text
Documentation/
├── 01-Infrastructure/
├── 02-Active-Directory/
├── 03-DNS-DHCP/
├── 04-File-Server/
├── 05-Security/
├── 06-Backup-Recovery/
├── 07-Operations/
├── 08-Change-Management/
└── 09-Troubleshooting/
```

## 12.6 --- Change Management

```text
CHANGE REQUEST
      ↓
REASON
      ↓
CURRENT STATE
      ↓
TARGET STATE
      ↓
SCOPE / IMPACT / DEPENDENCIES
      ↓
RISK
      ↓
BACKUP / EXPORT
      ↓
ROLLBACK PLAN
      ↓
APPROVAL
      ↓
IMPLEMENTATION
      ↓
TECHNICAL TEST
      ↓
FUNCTIONAL TEST
      ↓
NEGATIVE / REGRESSION TEST
      ↓
GLOBAL HEALTH CHECK
      ↓
DOCUMENTATION
```

Classification du lab :

Type Exemple

---

Standard Opération récurrente approuvée à faible risque
Normal GPO, ACL, DNS ou infrastructure planifiée
Emergency Changement urgent pour restaurer un service critique

## 12.7 --- Exemple : changement GPO contrôlé

Baseline :

```powershell
Get-GPO -Name "GPO-WS-Security-Baseline" |
Select-Object DisplayName,Id,GpoStatus,CreationTime,ModificationTime

Get-GPInheritance `
    -Target "OU=Workstations,OU=Computers,OU=Diarabaka,DC=diarabaka,DC=com"
```

Backup :

```powershell
$GpoBackupPath = "C:\SysAdminToolkit\GPO-Backup"
New-Item $GpoBackupPath -ItemType Directory -Force | Out-Null

$Backup = Backup-GPO `
    -Name "GPO-WS-Security-Baseline" `
    -Path $GpoBackupPath

$Backup | Select-Object DisplayName,Id,BackupId,CreationTime
```

Après modification approuvée :

```powershell
gpupdate /force
gpresult /r
gpresult /h C:\Temp\GPResult-ChangeValidation.html
```

Puis tester le contrôle concerné, par exemple Defender, Firewall,
BitLocker ou LAPS.

```text
GPO APPEARS IN GPRESULT
          ≠
SECURITY CONTROL VALIDATED
```
