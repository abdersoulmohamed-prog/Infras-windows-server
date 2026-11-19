# PHASES 11--13 --- EXPLOITATION, ROUTINE OPÉRATIONNELLE & AUDIT FINAL

## Windows Server 2025 Enterprise Infrastructure

**Project:** Windows Server 2025 Enterprise Infrastructure\
**Domain:** `diarabaka.com`\
**Network:** `192.168.1.0/24`\
**Domain Controllers:** `DC01` (`192.168.1.10`), `DC02`
(`192.168.1.11`)\
**File Server:** `FILE01`\
**Client:** `WIN11`\
**Platform:** VMware\
**Professional Domain:** Microsoft Infrastructure\
**Target Level:** Confirmed\

---

# 0 --- Règles de validation communes

Ces trois phases ferment le cycle d'administration du projet. Elles ne
doivent jamais transformer une configuration documentée en résultat
prétendument validé.

```text
CONFIGURED
    ↓
TESTED
    ↓
EXPECTED = ACTUAL?
    ├── YES → VALIDATED
    └── NO  → INVESTIGATE / CORRECT / RETEST
```

Règles impératives :

```text
COMMAND RUNS ≠ CONTROL VALIDATED
SCRIPT RUNS ≠ INFRASTRUCTURE HEALTH VALIDATED
REMEDIATED ≠ VALIDATED
BACKUP EXISTS ≠ RECOVERY VALIDATED
OLD EVIDENCE ≠ CURRENT HEALTH
UNKNOWN ≠ OK
```

Tout contrôle important doit produire :

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

Statuts autorisés :

```text
READY FOR VALIDATION
TESTED
VALIDATED
WARNING
NEEDS FIX
UNKNOWN
NOT APPLICABLE
```

Aucun `PASS`, `VALIDATED` ou verdict de disponibilité ne doit être écrit
sans sortie réelle et actuelle.

---

# 11 --- SIMULATION D'UNE JOURNÉE D'EXPLOITATION WINDOWS

## 11.0 --- Objectif

Cette phase transforme le lab en environnement d'exploitation administré
par tickets.

```text
TICKET
   ↓
TRIAGE / PRIORITY
   ↓
SCOPE
   ↓
BASELINE
   ↓
EVIDENCE
   ↓
ISOLATION
   ↓
ROOT CAUSE
   ↓
MINIMAL SAFE CORRECTION
   ↓
FUNCTIONAL RETEST
   ↓
NEGATIVE / REGRESSION TEST
   ↓
DOCUMENTATION
   ↓
CLOSURE
```

La compétence attendue n'est pas de connaître beaucoup de commandes,
mais de démontrer pourquoi une commande est pertinente, quel état elle
mesure et comment le retour du service est prouvé.

## 11.1 --- Golden Rule

```text
OBSERVE → MEASURE → ISOLATE → PROVE → CORRECT → RETEST → DOCUMENT
```

Ne jamais commencer arbitrairement par :

```text
Restart everything
Disable firewall
Change DNS
Modify GPO
Change NTFS ACL
Delete DHCP leases
Force AD replication
Reset passwords
Move FSMO roles
```

## 11.2 --- Cycle de vie d'un ticket

```text
OPEN
  ↓
INVESTIGATING
  ↓
ROOT CAUSE IDENTIFIED
  ↓
REMEDIATED
  ↓
VALIDATED
  ↓
CLOSED
```

`REMEDIATED` signifie qu'une correction a été appliquée. `VALIDATED`
signifie que le service attendu a été retesté avec succès.

## 11.3 --- Evidence Before Change

Avant toute correction, capturer lorsque possible :

```text
Timestamp
Hostname
User/System
Symptom
Scope
Relevant configuration
Command
Actual output
Event ID
Error code
```

Puis conserver :

```text
BEFORE → CHANGE → AFTER → FUNCTIONAL TEST
```

---

## 11.4 --- SYS-001 --- Compte utilisateur verrouillé

**Utilisateur :** Jean Dupont\
**Compte :** `jdupont`\
**Impact :** authentification indisponible pour un utilisateur.

Ne pas supposer un lockout. Vérifier :

```powershell
Get-ADUser "jdupont" -Properties `
    Enabled,LockedOut,PasswordExpired,PasswordLastSet,LastLogonDate |
Select-Object SamAccountName,Enabled,LockedOut,PasswordExpired,PasswordLastSet,LastLogonDate
```

Identifier le PDC Emulator :

```powershell
$PDC = (Get-ADDomain).PDCEmulator
$PDC
```

Chercher l'événement 4740 sur le PDC :

```powershell
Get-WinEvent -ComputerName $PDC -FilterHashtable @{
    LogName = 'Security'
    Id      = 4740
} -MaxEvents 200 |
Where-Object { $_.Message -match '\bjdupont\b' } |
Select-Object TimeCreated,MachineName,Id,Message
```

Examiner le `Caller Computer Name`, la fréquence et les horaires. Si le
verrouillage est confirmé et le déverrouillage autorisé :

```powershell
Unlock-ADAccount -Identity "jdupont"

Get-ADUser "jdupont" -Properties LockedOut |
Select-Object SamAccountName,LockedOut
```

La validation finale exige une authentification utilisateur réelle. Si
le compte se reverrouille, rechercher les identifiants mémorisés, tâches
planifiées, services, lecteurs mappés, anciennes sessions et autres
postes.

```text
UNLOCK COMMAND SUCCESS
        ≠
USER AUTHENTICATION RESTORED
```

---

## 11.5 --- SYS-002 --- Access Denied sur Finance\$

Chemin de diagnostic :

```text
CLIENT → DNS → TCP/445 → IDENTITY → TOKEN → AD GROUP
       → AGDLP → SMB ACL → NTFS ACL → EFFECTIVE ACCESS
```

Sur WIN11 :

```powershell
whoami
whoami /groups
Resolve-DnsName FILE01
Test-NetConnection FILE01 -Port 445
```

Le modèle d'autorisation du projet est AGDLP :

```text
Finance user
   ↓
GG-Finance
   ↓
DL-FS-Finance-Modify
   ↓
SMB / NTFS permissions
```

Vérifier l'imbrication AD :

```powershell
Get-ADGroupMember "GG-Finance"
Get-ADGroupMember "DL-FS-Finance-Modify"
```

Sur FILE01 :

```powershell
Get-SmbShare -Name "Finance$" |
Select-Object Name,Path,Description

Get-SmbShareAccess -Name "Finance$"
```

Ne pas hardcoder `D:\Shares`. Découvrir le chemin réel :

```powershell
$FinancePath = (Get-SmbShare -Name "Finance$").Path
$FinancePath
icacls $FinancePath
```

Si l'appartenance vient d'être modifiée, une nouvelle ouverture de
session utilisateur peut être nécessaire. `klist purge` ne remplace pas
le renouvellement du jeton de connexion Windows.

Test positif avec un utilisateur autorisé :

```powershell
$TestFile = "\\FILE01\Finance$\OPS-$([guid]::NewGuid()).txt"
"Controlled access test $(Get-Date -Format o)" | Set-Content $TestFile
Get-Content $TestFile
Remove-Item $TestFile -Force
```

Test négatif depuis une session non autorisée : l'accès doit être refusé
conformément à la baseline.

Ne jamais corriger par `Everyone : Full Control`.

---

## 11.6 --- SYS-003 --- GPO non appliquée

OU canonique du projet :

```text
OU=Workstations,OU=Computers,OU=Diarabaka,DC=diarabaka,DC=com
```

Baseline client :

```powershell
gpresult /r
New-Item C:\Temp -ItemType Directory -Force | Out-Null
gpresult /h C:\Temp\GPResult-Before.html
```

Vérifier l'objet ordinateur :

```powershell
Get-ADComputer "WIN11" |
Select-Object Name,DistinguishedName
```

Vérifier les GPO et l'héritage :

```powershell
Get-GPO -All |
Select-Object DisplayName,GpoStatus,ModificationTime

Get-GPInheritance -Target "OU=Workstations,OU=Computers,OU=Diarabaka,DC=diarabaka,DC=com"
```

Analyser :

```text
GPO EXISTS?
GPO ENABLED?
CORRECT LINK?
CORRECT OU?
LINK ENABLED?
SECURITY FILTERING?
WMI FILTER?
INHERITANCE / BLOCK INHERITANCE?
DENIED GPO?
CLIENT PROCESSING?
```

Journal client :

```powershell
Get-WinEvent -LogName "Microsoft-Windows-GroupPolicy/Operational" -MaxEvents 100 |
Select-Object TimeCreated,Id,LevelDisplayName,Message
```

Après correction démontrée :

```powershell
gpupdate /force
gpresult /r
gpresult /h C:\Temp\GPResult-After.html
```

Puis valider le **paramètre fonctionnel** réellement visé. Une GPO
visible dans `gpresult` ne prouve pas que le contrôle métier/sécurité
fonctionne.

---

## 11.7 --- SYS-004 --- Perte d'accès Internet

Sur WIN11 :

```powershell
ipconfig /all
Get-DnsClientServerAddress -AddressFamily IPv4
Test-Connection 192.168.1.1 -Count 2
Resolve-DnsName dc01.diarabaka.com
Resolve-DnsName google.com
Test-NetConnection google.com -Port 443
```

Interprétation :

```text
NO VALID IPv4 → DHCP / NIC / VLAN / NETWORK
VALID IPv4 + GATEWAY FAIL → LOCAL NETWORK / ROUTING
GATEWAY OK + INTERNAL DNS FAIL → AD DNS PATH
INTERNAL DNS OK + EXTERNAL DNS FAIL → FORWARDING / UPSTREAM DNS
DNS OK + TCP/443 FAIL → ROUTING / FIREWALL / UPSTREAM
TCP/443 OK → APPLICATION / PROXY / BROWSER
```

ICMP seul n'est pas une preuve suffisante de disponibilité ou
d'indisponibilité.

---

## 11.8 --- SYS-005 --- FILE01 indisponible

Depuis WIN11 :

```powershell
Resolve-DnsName FILE01
Test-NetConnection FILE01 -Port 445
```

Sur FILE01 :

```powershell
Get-Service LanmanServer
Get-SmbShare
Get-SmbSession
Get-Volume |
Select-Object DriveLetter,FileSystemLabel,HealthStatus,OperationalStatus,Size,SizeRemaining
```

Chaîne :

```text
DNS → NETWORK → TCP/445 → HOST → LANMANSERVER → SHARE → STORAGE → ACL
```

Collecter les événements avant un redémarrage de service :

```powershell
$Since = (Get-Date).AddHours(-2)

Get-WinEvent -FilterHashtable @{
    LogName   = 'System'
    StartTime = $Since
} -ErrorAction SilentlyContinue |
Where-Object { $_.LevelDisplayName -in 'Critical','Error' } |
Select-Object TimeCreated,Id,ProviderName,LevelDisplayName,Message
```

---

## 11.9 --- SYS-006 --- WIN11 ne reçoit pas de bail DHCP

Sur WIN11 :

```powershell
ipconfig /all
```

Une adresse `169.254.x.x` indique APIPA ; elle ne prouve pas que les
deux serveurs DHCP sont arrêtés.

Sur l'administration :

```powershell
Get-Service -ComputerName DC01 -Name DHCPServer
Get-Service -ComputerName DC02 -Name DHCPServer
Get-DhcpServerInDC

Get-DhcpServerv4Scope -ComputerName DC01

Get-DhcpServerv4ScopeStatistics `
    -ComputerName DC01 `
    -ScopeId 192.168.1.0

Get-DhcpServerv4Failover -ComputerName DC01 | Format-List
Get-DhcpServerv4Failover -ComputerName DC02 | Format-List
```

Le failover doit être évalué des deux côtés. `State = Normal` est un
élément important mais ne remplace pas la vérification du scope, du
partenaire, du mode, des paramètres et du comportement client.

Après correction :

```powershell
ipconfig /release
ipconfig /renew
ipconfig /all
Resolve-DnsName dc01.diarabaka.com
nltest /dsgetdc:diarabaka.com
```

---

## 11.10 --- SYS-007 --- Problèmes d'authentification domaine

Sur WIN11 :

```powershell
ipconfig /all

Resolve-DnsName "_ldap._tcp.dc._msdcs.diarabaka.com" -Type SRV
Resolve-DnsName "_kerberos._tcp.diarabaka.com" -Type SRV

nltest /dsgetdc:diarabaka.com
Test-ComputerSecureChannel
klist
w32tm /query /status
w32tm /query /source
```

Tester les ports comme indicateurs de transport :

```powershell
Test-NetConnection DC01 -Port 389
Test-NetConnection DC01 -Port 88
Test-NetConnection DC02 -Port 389
Test-NetConnection DC02 -Port 88
```

```text
TCP/389 OPEN ≠ LDAP FUNCTION VALIDATED
TCP/88 OPEN  ≠ KERBEROS VALIDATED
```

Corréler DNS SRV, DC Locator, secure channel, tickets Kerberos, heure et
santé des DC.

---

## 11.11 --- SYS-008 --- Incident DC01

Avant tout reboot :

```powershell
dcdiag /v
repadmin /replsummary
repadmin /showrepl DC01
dcdiag /test:replications
dcdiag /test:dns
netdom query fsmo

Get-Service NTDS,DNS,Netlogon,KDC |
Select-Object Name,Status,StartType
```

Vérifier DC02 en parallèle :

```powershell
repadmin /showrepl DC02
dcdiag /s:DC02 /test:Advertising /test:Services /test:SysVolCheck /test:NetLogons
```

Ne jamais exécuter arbitrairement un FSMO seizure, metadata cleanup,
réparation NTDS ou force replication sans diagnostic et procédure
adaptée.

---

## 11.12 --- SYS-009 --- Espace disque faible sur FILE01

Mesurer d'abord :

```powershell
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
```

FSRM :

```powershell
Get-FsrmQuota |
Select-Object Path,Size,Usage,Disabled,SoftLimit,Status,Description
```

Distinguer :

```text
PHYSICAL VOLUME CAPACITY
        ≠
FSRM QUOTA CAPACITY
```

Découvrir les racines de partage avant un scan :

```powershell
$BusinessShares = Get-SmbShare |
Where-Object { $_.Name -in 'IT$','HR$','Finance$','Marketing$','Sales$','Public$' }

$BusinessShares | Select-Object Name,Path
```

Un scan récursif peut être coûteux. Ne supprimer aucun fichier sans
propriétaire, besoin métier, rétention, sauvegarde et approbation.

---

## 11.13 --- SYS-010 --- Échec de sauvegarde FILE01

Baseline :

```powershell
Get-WindowsFeature Windows-Server-Backup
wbadmin get versions
Get-Service wbengine | Select-Object Name,Status,StartType
Get-WinEvent -ListLog *Backup* |
Select-Object LogName,RecordCount,IsEnabled
```

`wbengine = Stopped` peut être normal hors exécution d'un job.

Découvrir les volumes et la destination réelle ; ne pas supposer `E:` :

```powershell
Get-Volume |
Where-Object DriveLetter |
Select-Object DriveLetter,FileSystemLabel,HealthStatus,Size,SizeRemaining
```

Validation de récupération :

```text
JOB EXECUTED
   ↓
JOB SUCCESS CONFIRMED
   ↓
RECOVERY POINT VISIBLE
   ↓
RECOVERY POINT ACCESSIBLE
   ↓
CONTROLLED RESTORE
   ↓
HASH / ACL / CONTENT VALIDATION
```

---

## 11.14 --- Priorité et escalade

Modèle du lab :

Priority Exemple

---

P1 Authentification domaine indisponible à grande échelle
P1/P2 Défaillance majeure d'un DC selon redondance et impact
P2 FILE01 indisponible pour de nombreux utilisateurs
P2 DHCP indisponible pour de nombreux clients
P3 Partage départemental indisponible
P3 GPO incorrecte sur plusieurs postes
P4 Compte individuel verrouillé

```text
PRIORITY = IMPACT × URGENCY
```

Escalade renforcée pour corruption AD, seizure FSMO, panne de
réplication multi-DC, incident de sécurité inconnu, ransomware
potentiel, corruption de chaîne de sauvegarde, panne stockage,
changement privilégié inattendu ou GPO à large impact.

## 11.15 --- Modèle de rapport d'incident

```text
INCIDENT ID:
DATE:
ADMINISTRATOR:
PRIORITY:

USER / SYSTEM:
SERVICE:
SCOPE:
IMPACT:

SYMPTOM:
<ACTUAL OBSERVATION>

BASELINE:
<EXPECTED STATE>

DIAGNOSTIC:
<COMMAND + ACTUAL OUTPUT>

ROOT CAUSE:
<DEMONSTRATED CAUSE ONLY>

CORRECTIVE ACTION:
<MINIMUM SAFE CHANGE>

VALIDATION:
<FUNCTIONAL TEST>

EXPECTED:
<EXPECTED RESULT>

ACTUAL:
<ACTUAL RESULT>

REGRESSION / NEGATIVE TEST:
<RESULT>

EVIDENCE:
<PATH>

STATUS:
OPEN / INVESTIGATING / REMEDIATED / VALIDATED / CLOSED
```
