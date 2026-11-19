# 13 --- FINAL AUDIT & OPERATIONAL READINESS ASSESSMENT

## 13.0 --- Objectif

Aucune nouvelle technologie. L'audit final détermine si
l'enterprise-style lab est cohérent, sécurisé, administrable,
observable, résilient, récupérable et documenté.

```text
DISCOVER
   ↓
VERIFY CONFIGURATION
   ↓
FUNCTIONAL TEST
   ↓
NEGATIVE / FAILURE TEST
   ↓
RECOVERY TEST
   ↓
COLLECT EVIDENCE
   ↓
ASSESS
```

## 13.1 --- Architecture de référence

```text
                         DIARABAKA.COM
                              │
                 ┌────────────┴────────────┐
                 │                         │
               DC01                      DC02
        AD DS / DNS / DHCP        AD DS / DNS / DHCP
                 │                         │
                 └────── AD REPLICATION ──┘
                              │
                    DNS + DHCP FAILOVER
                              │
                         GROUP POLICY
                              │
             ┌────────────────┼────────────────┐
             │                │                │
           FILE01           WIN11        ADMINISTRATION
             │                │                │
       SMB / NTFS / FSRM   SECURITY      POWERSHELL TOOLKIT
             │                │                │
             └────────────────┼────────────────┘
                              │
                         BACKUP / RESTORE
                              │
                            EVIDENCE
```

## 13.2 --- Audit AD

```powershell
Get-ADDomain
Get-ADForest

Get-ADDomainController -Filter * |
Select-Object HostName,IPv4Address,Site,IsGlobalCatalog,IsReadOnly

dcdiag /e /c /v
dcdiag /test:Advertising
dcdiag /test:Services
dcdiag /test:SysVolCheck
dcdiag /test:NetLogons

repadmin /replsummary
repadmin /showrepl DC01
repadmin /showrepl DC02
dcdiag /test:replications

netdom query fsmo
```

Ne pas marquer AD/replication `VALIDATED` avant les sorties actuelles.

## 13.3 --- Audit DNS

Inventaire :

```powershell
Get-DnsServerZone |
Select-Object ZoneName,ZoneType,IsDsIntegrated,DynamicUpdate,ReplicationScope

Get-DnsServerForwarder
```

Validation directe par IP :

```powershell
Resolve-DnsName dc01.diarabaka.com -Server 192.168.1.10
Resolve-DnsName dc02.diarabaka.com -Server 192.168.1.11

Resolve-DnsName "_ldap._tcp.dc._msdcs.diarabaka.com" `
    -Type SRV -Server 192.168.1.10

Resolve-DnsName "_ldap._tcp.dc._msdcs.diarabaka.com" `
    -Type SRV -Server 192.168.1.11

Resolve-DnsName "_kerberos._tcp.diarabaka.com" `
    -Type SRV -Server 192.168.1.10

Resolve-DnsName "_kerberos._tcp.diarabaka.com" `
    -Type SRV -Server 192.168.1.11

dcdiag /e /test:dns
```

Vérifier la reverse zone `1.168.192.in-addr.arpa` uniquement si elle
fait partie de la configuration attendue.

## 13.4 --- Audit DHCP

```powershell
Get-Service -ComputerName DC01 -Name DHCPServer
Get-Service -ComputerName DC02 -Name DHCPServer
Get-DhcpServerInDC

Get-DhcpServerv4Scope -ComputerName DC01

Get-DhcpServerv4OptionValue `
    -ComputerName DC01 `
    -ScopeId 192.168.1.0

Get-DhcpServerv4ScopeStatistics `
    -ComputerName DC01 `
    -ScopeId 192.168.1.0

Get-DhcpServerv4Lease `
    -ComputerName DC01 `
    -ScopeId 192.168.1.0

Get-DhcpServerv4Reservation `
    -ComputerName DC01 `
    -ScopeId 192.168.1.0

Get-DhcpServerv4Failover -ComputerName DC01 | Format-List
Get-DhcpServerv4Failover -ComputerName DC02 | Format-List
```

Baseline documentée du lab à comparer à l'état réel :

```text
Scope   : 192.168.1.0/24
Pool    : 192.168.1.100–192.168.1.200
Gateway : 192.168.1.1
DNS     : 192.168.1.10 / 192.168.1.11
Domain  : diarabaka.com
Mode    : LoadBalance
```

## 13.5 --- Audit GPO

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

Sur WIN11 :

```powershell
gpresult /r /scope computer
gpresult /h C:\Temp\GPResult-FinalAudit.html
```

Valider ensuite les contrôles réels :

```powershell
Get-MpComputerStatus
Get-NetFirewallProfile
Get-BitLockerVolume -MountPoint C:
Get-LapsDiagnostics
```

## 13.6 --- Audit sécurité AD

```powershell
Get-ADDefaultDomainPasswordPolicy | Format-List

Get-ADGroupMember "Domain Admins" -Recursive
Get-ADGroupMember "Enterprise Admins" -Recursive
Get-ADGroupMember "Administrators" -Recursive
Get-ADGroupMember "GG-IT-Admins" -Recursive
```

Baseline du lab à comparer à l'état réel, sans la présenter comme norme
universelle.

Séparation :

```text
STANDARD ACCOUNT → jdurand
ADMIN ACCOUNT    → adm-jdurand
```

`GG-IT-Admins` n'implique pas automatiquement `Domain Admins`.

Tester la délégation Helpdesk avec un vrai compte délégué et confirmer
que les opérations autorisées fonctionnent tandis que les opérations
privilégiées hors périmètre restent refusées.

## 13.7 --- Audit Windows LAPS

```powershell
Get-Command -Module LAPS
Get-LapsDiagnostics

Get-WinEvent -LogName "Microsoft-Windows-LAPS/Operational" -MaxEvents 50 |
Select-Object TimeCreated,Id,LevelDisplayName,Message
```

Depuis un compte autorisé :

```powershell
Get-LapsADPassword -Identity "WIN11"
```

Ne jamais publier le mot de passe. Valider aussi qu'un compte non
autorisé ne peut pas le récupérer.

## 13.8 --- Audit WIN11

```powershell
Get-CimInstance Win32_ComputerSystem |
Select-Object Name,Domain,PartOfDomain

Get-DnsClientServerAddress -AddressFamily IPv4
nltest /dsgetdc:diarabaka.com
Test-ComputerSecureChannel
klist
w32tm /query /status
w32tm /query /source

Get-MpComputerStatus |
Select-Object AntivirusEnabled,RealTimeProtectionEnabled,
    AntispywareEnabled,BehaviorMonitorEnabled,AntivirusSignatureLastUpdated

Get-NetFirewallProfile |
Select-Object Name,Enabled,DefaultInboundAction,DefaultOutboundAction

Get-BitLockerVolume -MountPoint C:
Get-Tpm
Get-LocalGroupMember -Group Administrators
Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 10
```

Objet BitLocker Recovery : utiliser le DN canonique de WIN11 :

```powershell
$Win11 = Get-ADComputer WIN11

Get-ADObject `
    -SearchBase $Win11.DistinguishedName `
    -LDAPFilter '(objectClass=msFVE-RecoveryInformation)' |
Select-Object Name,ObjectClass,DistinguishedName
```

Cette méthode évite de hardcoder un DN incorrect.

## 13.9 --- Audit FILE01

```powershell
Get-Service LanmanServer

Get-SmbShare |
Select-Object Name,Path,Description

foreach ($Share in 'IT$','HR$','Finance$','Marketing$','Sales$','Public$') {
    Get-SmbShareAccess -Name $Share
}
```

Découvrir les chemins :

```powershell
$Shares = Get-SmbShare |
Where-Object { $_.Name -in 'IT$','HR$','Finance$','Marketing$','Sales$','Public$' }

foreach ($Share in $Shares) {
    Write-Host "=== $($Share.Name) → $($Share.Path) ==="
    icacls $Share.Path
}
```

Valider AGDLP :

```text
Accounts → Global Department/Role Groups → Domain Local Resource Groups → ACL
```

Tests fonctionnels : utilisateur autorisé = accès attendu ; utilisateur
non autorisé = refus attendu. Ne pas utiliser seulement `Test-Path` pour
prouver une écriture autorisée : effectuer une
création/lecture/suppression contrôlée lorsque le rôle doit avoir
Modify.

FSRM et stockage :

```powershell
Get-FsrmQuota |
Select-Object Path,Size,Usage,Disabled,SoftLimit,Status,Description

Get-Volume |
Where-Object DriveLetter |
Select-Object DriveLetter,FileSystemLabel,HealthStatus,OperationalStatus,
    Size,SizeRemaining
```

## 13.10 --- Audit Backup & Recovery

```powershell
Get-WindowsFeature Windows-Server-Backup
wbadmin get versions
wbadmin get disks
Get-WinEvent -ListLog *Backup* |
Select-Object LogName,RecordCount,IsEnabled
```

Le test de restauration doit utiliser un fichier et un chemin réels
découverts dans FILE01, pas un `D:` inventé.

Exemple contrôlé :

```powershell
$HRShare = Get-SmbShare -Name "HR$"
$RestoreTestFile = Join-Path `
    $HRShare.Path `
    "Restore-Test-$([guid]::NewGuid()).txt"

"FINAL RECOVERY VALIDATION $(Get-Date -Format o)" |
Set-Content $RestoreTestFile

$OriginalHash = Get-FileHash $RestoreTestFile -Algorithm SHA256
$OriginalAcl  = Get-Acl $RestoreTestFile
```

Après inclusion confirmée dans un recovery point utilisable, effectuer
la procédure de restauration documentée avec **l'identifiant de version
réellement retourné par `wbadmin get versions`**.

Après restauration :

```powershell
$RestoredHash = Get-FileHash $RestoreTestFile -Algorithm SHA256

[pscustomobject]@{
    OriginalHash = $OriginalHash.Hash
    RestoredHash = $RestoredHash.Hash
    HashMatch    = ($OriginalHash.Hash -eq $RestoredHash.Hash)
}
```

Contrôler également contenu et ACL lorsque cela fait partie du test.

```text
BACKUP EXISTS
    ≠
RECOVERY VALIDATED

BACKUP + RESTORE + INTEGRITY CHECK
    =
RECOVERY EVIDENCE
```
