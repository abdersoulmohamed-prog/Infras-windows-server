# PHASE 03 - DNS

## Windows Server 2025 Enterprise Infrastructure

**Project:** Windows Server 2025 Enterprise Infrastructure  
**Domain:** `diarabaka.com`  
**Network:** `192.168.1.0/24`  
**Domain Controllers:** `DC01`, `DC02`  
**Client:** `WIN11`  
**Platform:** VMware  
**Professional Domain:** Microsoft Infrastructure  
**Target Level:** Confirmed

---

# 03.0 - Objectif

DNS est un composant critique d'Active Directory.

Dans cette infrastructure :

```text
WIN11
  │
  │ DNS
  ▼
┌───────────────┐
│               │
▼               ▼
DC01            DC02
AD DS + DNS     AD DS + DNS
│               │
└───────┬───────┘
        │
        ├── diarabaka.com
        ├── _msdcs.diarabaka.com
        ├── Reverse DNS
        ├── LDAP SRV
        ├── Kerberos SRV
        ├── DC Locator
        └── Secure Dynamic Updates
```

L'objectif n'est pas seulement d'obtenir :

```text
Resolve-DnsName → réponse
```

L'objectif est de démontrer :

```text
DNS SERVICE
    +
AD-INTEGRATED ZONES
    +
SECURE DYNAMIC UPDATES
    +
A / PTR RECORDS
    +
LDAP / KERBEROS SRV
    +
DC LOCATOR
    +
SITE-AWARE DISCOVERY
    +
CLIENT DNS CONFIGURATION
    +
FUNCTIONAL LDAP
    +
FUNCTIONAL KERBEROS
    +
FORWARDERS / EXTERNAL RESOLUTION
    +
CACHE BEHAVIOR
    +
AGING / SCAVENGING REVIEW
    +
DNS SECURITY
    +
AD REPLICATION
    +
DNS REDUNDANCY
    +
CONTROLLED FAILURE
    +
RECOVERY
    +
POST-REBOOT VALIDATION
    +
EVIDENCE
```

---

# 03.1 - Préparer l'Evidence Pack

Sur `DC01` :

```powershell
$EvidenceRoot = "C:\Evidence\DNS"

$Folders = @(
    "01-Baseline",
    "02-Role-Services",
    "03-Zones",
    "04-Records",
    "05-Reverse-DNS",
    "06-Forwarders",
    "07-DNS-Clients",
    "08-AD-SRV",
    "09-Sites-DC-Locator",
    "10-LDAP-Kerberos",
    "11-Diagnostics",
    "12-Replication",
    "13-Cache",
    "14-Aging-Scavenging",
    "15-Security",
    "16-Logs",
    "17-Redundancy",
    "18-Failure-Recovery",
    "19-Post-Reboot",
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

Vérifier :

```powershell
Get-ChildItem C:\Evidence\DNS -Directory |
    Select-Object Name,FullName
```

---

# 03.2 - Baseline DNS avant modification

Sur `DC01` :

```powershell
Get-Date
hostname
whoami
```

Enregistrer :

```powershell
Get-Date |
    Out-File "C:\Evidence\DNS\01-Baseline\DNS-BASELINE.txt"

hostname |
    Out-File `
        "C:\Evidence\DNS\01-Baseline\DNS-BASELINE.txt" `
        -Append

whoami |
    Out-File `
        "C:\Evidence\DNS\01-Baseline\DNS-BASELINE.txt" `
        -Append
```

Collecter les zones :

```powershell
Get-DnsServerZone |
    Select-Object `
        ZoneName,
        ZoneType,
        IsDsIntegrated,
        DynamicUpdate,
        ReplicationScope |
    Sort-Object ZoneName |
    Format-Table -AutoSize |
    Out-String |
    Out-File `
        "C:\Evidence\DNS\01-Baseline\DNS-BASELINE.txt" `
        -Append
```

Forwarders :

```powershell
Get-DnsServerForwarder |
    Format-List * |
    Out-String |
    Out-File `
        "C:\Evidence\DNS\01-Baseline\DNS-BASELINE.txt" `
        -Append
```

Configuration DNS locale :

```powershell
Get-DnsClientServerAddress -AddressFamily IPv4 |
    Where-Object { $_.ServerAddresses } |
    Select-Object InterfaceAlias,ServerAddresses |
    Format-List |
    Out-String |
    Out-File `
        "C:\Evidence\DNS\01-Baseline\DNS-BASELINE.txt" `
        -Append
```

---

# 03.3 - Inventaire du rôle DNS

## DC01

```powershell
Get-WindowsFeature DNS
Get-Service DNS
Get-DnsServer
```

Attendu après validation :

```text
DNS Role      : Installed
DNS Service   : Running
DNS Server    : Queryable
```

## DC02

```powershell
Invoke-Command -ComputerName DC02 -ScriptBlock {

    Get-WindowsFeature DNS

    Get-Service DNS

    Get-DnsServer
}
```

---

# 03.4 - Inventaire des zones DNS

Sur `DC01` :

```powershell
Get-DnsServerZone |
    Select-Object `
        ZoneName,
        ZoneType,
        IsDsIntegrated,
        DynamicUpdate,
        ReplicationScope |
    Sort-Object ZoneName |
    Format-Table -AutoSize
```

Sur `DC02` :

```powershell
Invoke-Command -ComputerName DC02 -ScriptBlock {

    Get-DnsServerZone |
        Select-Object `
            ZoneName,
            ZoneType,
            IsDsIntegrated,
            DynamicUpdate,
            ReplicationScope |
        Sort-Object ZoneName
}
```

Zones AD importantes attendues :

```text
diarabaka.com
_msdcs.diarabaka.com
```

---

# 03.6 - Vérifier la zone `diarabaka.com`

Sur `DC01` :

```powershell
Get-DnsServerZone -Name "diarabaka.com" |
    Format-List `
        ZoneName,
        ZoneType,
        IsDsIntegrated,
        DynamicUpdate,
        ReplicationScope
```

Cible pour une zone AD intégrée utilisant les mises à jour dynamiques sécurisées :

```text
ZoneName       : diarabaka.com
IsDsIntegrated : True
DynamicUpdate  : Secure
```

---

# 03.7 - Vérifier `_msdcs.diarabaka.com`

```powershell
Get-DnsServerZone -Name "_msdcs.diarabaka.com" |
    Format-List `
        ZoneName,
        ZoneType,
        IsDsIntegrated,
        DynamicUpdate,
        ReplicationScope
```

Cette zone participe notamment à la localisation des contrôleurs de domaine.

Vérifier également depuis `DC02` :

```powershell
Invoke-Command -ComputerName DC02 -ScriptBlock {

    Get-DnsServerZone -Name "_msdcs.diarabaka.com" |
        Format-List `
            ZoneName,
            ZoneType,
            IsDsIntegrated,
            DynamicUpdate,
            ReplicationScope
}
```

---

# 03.8 - Replication Scope et partitions DNS AD

La propriété `ReplicationScope` ne doit pas seulement être affichée : elle doit être interprétée.

Collecter :

```powershell
Get-DnsServerZone |
    Where-Object { $_.IsDsIntegrated } |
    Select-Object `
        ZoneName,
        IsDsIntegrated,
        ReplicationScope |
    Format-Table -AutoSize
```

Vérifier les naming contexts AD :

```powershell
Get-ADRootDSE |
    Select-Object -ExpandProperty namingContexts
```

On s'attend notamment à observer, selon l'architecture AD réelle, les partitions DNS applicables telles que :

```text
DC=DomainDnsZones,DC=diarabaka,DC=com
DC=ForestDnsZones,DC=diarabaka,DC=com
```

---

# 03.9 - Inventaire des enregistrements

Zone du domaine :

```powershell
Get-DnsServerResourceRecord `
    -ZoneName "diarabaka.com" |
    Select-Object `
        HostName,
        RecordType,
        Timestamp |
    Sort-Object HostName,RecordType |
    Format-Table -AutoSize
```

Zone `_msdcs` :

```powershell
Get-DnsServerResourceRecord `
    -ZoneName "_msdcs.diarabaka.com" |
    Select-Object `
        HostName,
        RecordType,
        Timestamp |
    Sort-Object HostName,RecordType |
    Format-Table -AutoSize
```

Rechercher les éléments nécessaires à :

```text
DC01
DC02
LDAP
Kerberos
Global Catalog
DC Locator
Site-aware DC Locator
```

---

# 03.10 - Vérifier les enregistrements A

```powershell
Resolve-DnsName dc01.diarabaka.com -Type A
Resolve-DnsName dc02.diarabaka.com -Type A
```

Récupérer les IP réellement configurées.

Sur `DC01` :

```powershell
Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object {
        $_.IPAddress -notlike "169.254*" -and
        $_.IPAddress -ne "127.0.0.1"
    } |
    Select-Object `
        InterfaceAlias,
        IPAddress,
        PrefixLength
```

Sur `DC02` :

```powershell
Invoke-Command -ComputerName DC02 -ScriptBlock {

    Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object {
            $_.IPAddress -notlike "169.254*" -and
            $_.IPAddress -ne "127.0.0.1"
        } |
        Select-Object `
            InterfaceAlias,
            IPAddress,
            PrefixLength
}
```

Validation :

```text
DNS NAME
   ↓
A RECORD
   ↓
EXPECTED DC IP
```

Une réponse DNS n'est pas suffisante si elle pointe vers une mauvaise adresse.

---

# 03.11 - Vérifier les SRV LDAP

```powershell
Resolve-DnsName `
    -Name "_ldap._tcp.dc._msdcs.diarabaka.com" `
    -Type SRV
```

---

# 03.12 - Vérifier les SRV Kerberos

```powershell
Resolve-DnsName `
    -Name "_kerberos._tcp.diarabaka.com" `
    -Type SRV
```

Puis :

```powershell
Resolve-DnsName `
    -Name "_kerberos._tcp.dc._msdcs.diarabaka.com" `
    -Type SRV
```

Ne pas conclure que Kerberos fonctionne uniquement parce que le SRV existe.

```text
SRV PRESENT
    ≠
KERBEROS FUNCTIONAL
```

---

# 03.13 - Vérifier les Global Catalog SRV

```powershell
Resolve-DnsName `
    -Name "_ldap._tcp.gc._msdcs.diarabaka.com" `
    -Type SRV
```

Comparer avec :

```powershell
Get-ADDomainController -Filter * |
    Select-Object `
        HostName,
        Site,
        IsGlobalCatalog,
        IsReadOnly
```

La réponse DNS doit être cohérente avec l'état réel des DC/GC.

---

# 03.14 - Reverse DNS

Réseau :

```text
192.168.1.0/24
```

Zone inverse correspondante :

```text
1.168.192.in-addr.arpa
```

Avant toute création :

```powershell
Get-DnsServerZone |
    Where-Object {
        $_.ZoneName -eq "1.168.192.in-addr.arpa"
    } |
    Select-Object `
        ZoneName,
        ZoneType,
        IsDsIntegrated,
        DynamicUpdate,
        ReplicationScope
```

---

# 03.15 - Créer la reverse zone uniquement si nécessaire

Seulement si la zone est réellement absente et que sa création fait partie du design approuvé :

```powershell
Add-DnsServerPrimaryZone `
    -NetworkId "192.168.1.0/24" `
    -ReplicationScope "Domain"
```

Puis :

```powershell
Set-DnsServerPrimaryZone `
    -Name "1.168.192.in-addr.arpa" `
    -DynamicUpdate Secure
```

Validation :

```powershell
Get-DnsServerZone `
    -Name "1.168.192.in-addr.arpa" |
    Select-Object `
        ZoneName,
        ZoneType,
        IsDsIntegrated,
        DynamicUpdate,
        ReplicationScope
```

Cible :

```text
ZoneName       : 1.168.192.in-addr.arpa
ZoneType       : Primary
IsDsIntegrated : True
DynamicUpdate  : Secure
```

---

# 03.16 - A et PTR

Tester les noms :

```powershell
Resolve-DnsName dc01.diarabaka.com
Resolve-DnsName dc02.diarabaka.com
```

Puis avec les IP réelles :

```powershell
Resolve-DnsName <DC01_IP>
Resolve-DnsName <DC02_IP>
```

Modèle :

```text
NAME
 ↓
 A
 ↓
 IP

 IP
 ↓
PTR
 ↓
NAME
```

Important :

```text
A SUCCESS
   ≠
PTR SUCCESS
```

Les deux doivent être testés séparément.

---

# 03.17 - Inspecter les PTR

```powershell
Get-DnsServerResourceRecord `
    -ZoneName "1.168.192.in-addr.arpa" |
    Where-Object {
        $_.RecordType -eq "PTR"
    } |
    Format-Table -AutoSize
```

Si un PTR manque :

```text
DO NOT CREATE IMMEDIATELY
        ↓
VERIFY HOST CONFIGURATION
        ↓
VERIFY DYNAMIC UPDATE
        ↓
VERIFY ZONE
        ↓
VERIFY REGISTRATION
        ↓
DETERMINE ROOT CAUSE
```

---

# 03.18 - DNS Forwarders

Les DNS AD sont autoritaires pour leurs zones internes.

Flux externe :

```text
WIN11
  │
  ▼
DC01 / DC02
  │
  │ external name
  ▼
Configured Forwarder
  │
  ▼
External DNS Resolution
```

## DC01

```powershell
Get-DnsServerForwarder
```

## DC02

```powershell
Invoke-Command -ComputerName DC02 -ScriptBlock {

    Get-DnsServerForwarder
}
```

Ne pas configurer automatiquement un DNS public simplement parce qu'il est connu.

La configuration doit correspondre à la stratégie réseau réelle.

---

# 03.19 - Tester la résolution externe

Depuis `DC01` :

```powershell
Resolve-DnsName www.microsoft.com
```

Depuis `DC02` :

```powershell
Invoke-Command -ComputerName DC02 -ScriptBlock {

    Resolve-DnsName www.microsoft.com
}
```

Attention :

```text
EXTERNAL NAME RESOLVES
        ≠
FORWARDER DEFINITELY USED
```

Selon la configuration DNS, la récursion/root hints peuvent aussi intervenir.

Il faut donc documenter :

```text
Configured forwarders
Recursion configuration
Observed external resolution
```

et ne pas attribuer automatiquement le succès à un forwarder sans preuve.

---

# 03.20 - Configuration DNS des Domain Controllers

Contrôle critique.

## DC01

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

## DC02

```powershell
Invoke-Command -ComputerName DC02 -ScriptBlock {

    Get-DnsClientServerAddress `
        -AddressFamily IPv4 |
        Where-Object {
            $_.ServerAddresses
        } |
        Select-Object `
            InterfaceAlias,
            ServerAddresses
}
```

Les DC doivent utiliser des DNS capables de résoudre correctement :

```text
diarabaka.com
_msdcs.diarabaka.com
LDAP SRV
Kerberos SRV
DC Locator
```

À éviter :

```text
DC01 → Public DNS only
DC02 → Public DNS only
```

Les DNS publics ne connaissent pas les zones privées de l'AD.

La séquence exacte DC01/DC02 doit être documentée depuis l'état réel du lab.

---

# 03.21 - Configuration DNS de WIN11

Sur `WIN11` :

```powershell
ipconfig /all
```

Puis :

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

Architecture cible :

```text
WIN11
  │
  ├── DNS → DC01
  └── DNS → DC02
```

avec les IP réelles.

Éviter :

```text
WIN11
  ↓
PUBLIC DNS ONLY
```

---

# 03.22 - Validation DNS depuis WIN11

```powershell
Resolve-DnsName diarabaka.com

Resolve-DnsName dc01.diarabaka.com
Resolve-DnsName dc02.diarabaka.com

Resolve-DnsName `
    "_ldap._tcp.dc._msdcs.diarabaka.com" `
    -Type SRV

Resolve-DnsName `
    "_kerberos._tcp.diarabaka.com" `
    -Type SRV
```

Le point de vue client est essentiel.

```text
SERVER-SIDE DNS TEST
        +
CLIENT-SIDE DNS TEST
        =
BETTER VALIDATION
```

---

# 03.23 - Domain Controller Locator

Depuis `WIN11` :

```powershell
nltest /dsgetdc:diarabaka.com
```

Puis :

```powershell
nltest /dclist:diarabaka.com
```

Résultat attendu :

- découverte d'un DC valide ;
- domaine correct ;
- DC correspondant à l'infrastructure ;
- aucune erreur de localisation.

Ne pas confondre :

```text
DNS SRV EXISTS
      ≠
DC LOCATOR WORKS
```

---

# 03.24 - AD Site Discovery

Depuis `WIN11` :

```powershell
nltest /dsgetsite
```

Enregistrer le nom réel du site retourné.

Sur un DC :

```powershell
Get-ADReplicationSite -Filter * |
    Select-Object Name
```

Puis :

```powershell
Get-ADReplicationSubnet -Filter * |
    Select-Object `
        Name,
        Site
```

---

# 03.25 - Site-specific SRV

Après avoir obtenu le nom réel du site avec :

```powershell
nltest /dsgetsite
```

construire la requête avec ce nom réel :

```powershell
$Site = "<ACTUAL_AD_SITE>"
```

Puis :

```powershell
Resolve-DnsName `
    "_ldap._tcp.$Site._sites.dc._msdcs.diarabaka.com" `
    -Type SRV
```

Et pour Kerberos :

```powershell
Resolve-DnsName `
    "_kerberos._tcp.$Site._sites.diarabaka.com" `
    -Type SRV
```

Ne jamais utiliser un nom de site inventé dans l'evidence.

---

# 03.26 - LDAP Reachability

Depuis `WIN11` :

```powershell
Test-NetConnection `
    dc01.diarabaka.com `
    -Port 389
```

Puis :

```powershell
Test-NetConnection `
    dc02.diarabaka.com `
    -Port 389
```

Attendu :

```text
TcpTestSucceeded : True
```

Mais :

```text
TCP 389 REACHABLE
       ≠
LDAP FUNCTIONAL
```

---

# 03.27 - LDAP / Active Directory Functional Test

Depuis une machine disposant du module ActiveDirectory :

```powershell
Get-ADDomainController `
    -Discover `
    -DomainName diarabaka.com |
    Select-Object `
        HostName,
        Site,
        IPv4Address
```

Puis un test de lecture AD non destructif :

```powershell
Get-ADUser `
    -Identity "jdupont" `
    -Properties Enabled |
    Select-Object `
        SamAccountName,
        Enabled,
        DistinguishedName
```

Si `jdupont` n'existe pas dans l'état réel du lab, utiliser un compte existant confirmé.

Objectif :

```text
DNS
  +
DC LOCATOR
  +
LDAP
  +
AD QUERY
  =
FUNCTIONAL AD READ
```

---

# 03.28 - Kerberos Reachability

```powershell
Test-NetConnection `
    dc01.diarabaka.com `
    -Port 88

Test-NetConnection `
    dc02.diarabaka.com `
    -Port 88
```

Attendu :

```text
TcpTestSucceeded : True
```

Mais :

```text
TCP 88 REACHABLE
       ≠
KERBEROS FUNCTIONAL
```

---

# 03.29 - Kerberos Functional Validation

Sur `WIN11`, dans une session de domaine contrôlée :

```powershell
klist
```

Pour un test contrôlé, on peut vider le cache uniquement si l'impact est compris :

```powershell
klist purge
```

Puis provoquer l'accès à une ressource de domaine autorisée, par exemple une ressource SMB réellement disponible :

```powershell
dir \\<DOMAIN_RESOURCE>\<SHARE>
```

Ensuite :

```powershell
klist
```

Rechercher des tickets cohérents avec l'accès effectué.

Validation :

```text
DNS SRV
   +
TIME
   +
DC LOCATOR
   +
DOMAIN SESSION
   +
SERVICE ACCESS
   +
KERBEROS TICKET
   =
FUNCTIONAL KERBEROS EVIDENCE
```

Ne jamais considérer `Test-NetConnection -Port 88` comme preuve Kerberos complète.

---

# 03.30 - Time Dependency Review

Kerberos dépend également de l'heure.

Sur `WIN11` :

```powershell
w32tm /query /status
w32tm /query /source
```

Sur `DC01` :

```powershell
w32tm /query /status
w32tm /query /source
```

Documenter les résultats.

Un problème présenté comme :

```text
KERBEROS FAILURE
```

peut avoir pour origine :

```text
DNS
DC Locator
time skew
secure channel
credentials
service configuration
```

---

# 03.31 - DCDIAG DNS

Sur `DC01` :

```powershell
dcdiag /test:dns
```

Analyse détaillée :

```powershell
dcdiag /test:dns /v
```

Tous les DC :

```powershell
dcdiag /e /test:dns
```

Audit DNS complet :

```powershell
dcdiag /test:dns /DnsAll /e /v
```

Conserver la sortie :

```powershell
dcdiag /test:dns /DnsAll /e /v `
    > C:\Evidence\DNS\11-Diagnostics\DNS-031-dcdiag-dnsall.txt
```

Ne pas réduire la validation à l'exit code.

Examiner les tests et erreurs réels.

---

# 03.32 - Netlogon et enregistrement DNS AD

Vérifier :

```powershell
Get-Service Netlogon
```

Sur `DC02` :

```powershell
Invoke-Command -ComputerName DC02 -ScriptBlock {

    Get-Service Netlogon
}
```

Puis :

```powershell
Resolve-DnsName `
    "_ldap._tcp.dc._msdcs.diarabaka.com" `
    -Type SRV
```

`ipconfig /registerdns` n'est pas une commande de maintenance à exécuter aveuglément.

Si un problème d'enregistrement est confirmé :

```text
COLLECT
  ↓
DIAGNOSE
  ↓
CONFIRM REGISTRATION ISSUE
  ↓
CONTROLLED REGISTERDNS
  ↓
RETEST
```

---

# 03.33 - AD Replication

Les zones AD-integrated dépendent de la réplication AD.

Sur `DC01` :

```powershell
repadmin /replsummary
```

Puis :

```powershell
repadmin /showrepl DC01
```

Et :

```powershell
repadmin /showrepl DC02
```

Puis :

```powershell
dcdiag /test:replications
```

Objectif uniquement après preuve réelle :

```text
REPLICATION FAILURES : 0
```

Mais ne pas l'écrire comme résultat avant exécution.

Architecture :

```text
DNS DATA
   ↓
AD-INTEGRATED ZONE
   ↓
AD PARTITION
   ↓
AD REPLICATION
   ↓
DC01 ↔ DC02
```

Une zone correcte sur DC01 ne prouve pas qu'elle est correcte sur DC02.

---

# 03.34 - Requêtes DNS directes DC01 / DC02

Récupérer les IP réelles des DC.

Puis :

```powershell
Resolve-DnsName `
    dc01.diarabaka.com `
    -Server <DC01_IP>

Resolve-DnsName `
    dc01.diarabaka.com `
    -Server <DC02_IP>

Resolve-DnsName `
    dc02.diarabaka.com `
    -Server <DC01_IP>

Resolve-DnsName `
    dc02.diarabaka.com `
    -Server <DC02_IP>
```

SRV :

```powershell
Resolve-DnsName `
    "_ldap._tcp.dc._msdcs.diarabaka.com" `
    -Type SRV `
    -Server <DC01_IP>
```

Puis :

```powershell
Resolve-DnsName `
    "_ldap._tcp.dc._msdcs.diarabaka.com" `
    -Type SRV `
    -Server <DC02_IP>
```

Kerberos :

```powershell
Resolve-DnsName `
    "_kerberos._tcp.diarabaka.com" `
    -Type SRV `
    -Server <DC01_IP>

Resolve-DnsName `
    "_kerberos._tcp.diarabaka.com" `
    -Type SRV `
    -Server <DC02_IP>
```

Principe :

```text
DC01 ANSWERS CORRECTLY
        +
DC02 ANSWERS CORRECTLY
        ≠
"DNS works somewhere"
```

---

# 03.35 - DNS Cache côté client

Sur `WIN11` :

```powershell
ipconfig /displaydns
```

Ou :

```powershell
Get-DnsClientCache
```

Si disponible dans l'environnement.

Ne vider le cache que lorsqu'un test le justifie :

```powershell
Clear-DnsClientCache
```

ou :

```powershell
ipconfig /flushdns
```

Workflow :

```text
RECORD CHANGED
   ↓
CLIENT STILL RETURNS OLD DATA?
   ↓
CHECK CACHE
   ↓
CONTROLLED FLUSH IF REQUIRED
   ↓
RETEST
```

Ne pas modifier à nouveau le serveur DNS si le problème vient uniquement du cache client.

---

# 03.36 - DNS Server Cache

Sur le serveur DNS :

```powershell
Get-DnsServerCache
```

Inspecter la configuration.

Ne pas vider le cache serveur comme première action de troubleshooting.

Principe :

```text
SERVER CACHE ISSUE?
       ↓
PROVE
       ↓
CLEAR ONLY IF JUSTIFIED
```

---

# 03.37 - Aging Review

Auditer la zone :

```powershell
Get-DnsServerZoneAging `
    -Name "diarabaka.com"
```

Reverse zone si elle existe :

```powershell
Get-DnsServerZoneAging `
    -Name "1.168.192.in-addr.arpa"
```

Documenter :

```text
Aging Enabled?
Refresh Interval?
No-Refresh Interval?
```

Ne rien activer automatiquement.

---

# 03.38 - Scavenging Review

```powershell
Get-DnsServerScavenging
```

Documenter :

```text
Scavenging enabled?
Scavenging interval?
Server selected?
```

Modèle :

```text
DYNAMIC RECORD
      ↓
TIMESTAMP
      ↓
NO-REFRESH
      ↓
REFRESH
      ↓
STALE ELIGIBILITY
      ↓
SCAVENGING
```

Attention :

```text
AGING / SCAVENGING
       +
BAD DESIGN
       =
POSSIBLE RECORD LOSS
```

Pour ce projet, l'audit peut être validé sans activer scavenging si son activation n'est pas requise par le scénario.

---

# 03.39 - DNS Security Review

Vérifier la zone :

```powershell
Get-DnsServerZone -Name "diarabaka.com" |
    Select-Object `
        ZoneName,
        ZoneType,
        IsDsIntegrated,
        DynamicUpdate,
        ReplicationScope
```

Cible :

```text
IsDsIntegrated : True
DynamicUpdate   : Secure
```

Vérifier `_msdcs` :

```powershell
Get-DnsServerZone -Name "_msdcs.diarabaka.com" |
    Select-Object `
        ZoneName,
        IsDsIntegrated,
        DynamicUpdate,
        ReplicationScope
```

Reverse zone :

```powershell
Get-DnsServerZone -Name "1.168.192.in-addr.arpa" |
    Select-Object `
        ZoneName,
        IsDsIntegrated,
        DynamicUpdate,
        ReplicationScope
```

Security review :

```text
AD-INTEGRATED?
SECURE DYNAMIC UPDATE?
EXPECTED REPLICATION SCOPE?
EXPECTED ZONES ONLY?
EXPECTED FORWARDERS?
NO PUBLIC DNS AS AD CLIENT DNS?
NO UNCONTROLLED RECORD CHANGES?
```

---

# 03.40 - DNS Event Logs

Lister :

```powershell
Get-WinEvent -ListLog *DNS* |
    Select-Object `
        LogName,
        IsEnabled,
        RecordCount
```

Examiner les événements pertinents :

```powershell
Get-WinEvent `
    -LogName "DNS Server" `
    -MaxEvents 100 |
    Select-Object `
        TimeCreated,
        Id,
        LevelDisplayName,
        Message
```

Si le nom du journal diffère dans l'environnement, utiliser la liste retournée par `Get-WinEvent -ListLog *DNS*`.

Ne pas activer une journalisation extrêmement détaillée en permanence sans justification.

---

# 03.41 - DNS Redundancy Baseline

Avant toute panne contrôlée :

```powershell
Resolve-DnsName `
    dc01.diarabaka.com `
    -Server <DC01_IP>

Resolve-DnsName `
    dc01.diarabaka.com `
    -Server <DC02_IP>

Resolve-DnsName `
    "_ldap._tcp.dc._msdcs.diarabaka.com" `
    -Type SRV `
    -Server <DC01_IP>

Resolve-DnsName `
    "_ldap._tcp.dc._msdcs.diarabaka.com" `
    -Type SRV `
    -Server <DC02_IP>
```

Sur `WIN11` :

```powershell
Get-DnsClientServerAddress -AddressFamily IPv4

nltest /dsgetdc:diarabaka.com
```

Ne pas commencer le failure test si cette baseline n'est pas correcte.

---

# 03.42 - Controlled Failure Test : DC01 DNS

Uniquement dans le lab.

Conditions :

```text
DC02 DNS VERIFIED
WIN11 HAS DC01 + DC02 DNS
CONSOLE ACCESS AVAILABLE
NO OTHER CRITICAL TEST IN PROGRESS
ONLY ONE DNS DISRUPTED
ROLLBACK KNOWN
```

Sur `DC01`, si le scénario choisi consiste à arrêter temporairement le service DNS :

```powershell
Stop-Service DNS
```

Immédiatement vérifier :

```powershell
Get-Service DNS
```

Sur `WIN11` :

```powershell
ipconfig /flushdns
```

Puis :

```powershell
Resolve-DnsName dc01.diarabaka.com
Resolve-DnsName dc02.diarabaka.com

Resolve-DnsName `
    "_ldap._tcp.dc._msdcs.diarabaka.com" `
    -Type SRV

nltest /dsgetdc:diarabaka.com
```

Interprétation :

```text
DC01 DNS unavailable
       ↓
WIN11 uses alternate DNS
       ↓
AD DNS resolution continues?
       ↓
DC Locator continues?
```

Ne pas arrêter DC02.

---

# 03.43 - Recovery après panne DC01 DNS

Sur `DC01` :

```powershell
Start-Service DNS
```

Puis :

```powershell
Get-Service DNS
```

Revalider directement :

```powershell
Resolve-DnsName `
    dc01.diarabaka.com `
    -Server <DC01_IP>

Resolve-DnsName `
    "_ldap._tcp.dc._msdcs.diarabaka.com" `
    -Type SRV `
    -Server <DC01_IP>
```

Puis :

```powershell
repadmin /replsummary
dcdiag /test:dns
```

Sur `WIN11` :

```powershell
Resolve-DnsName dc01.diarabaka.com
nltest /dsgetdc:diarabaka.com
```

Validation :

```text
FAILURE
  ↓
CONTINUITY
  ↓
SERVICE RESTORE
  ↓
DIRECT DNS RETEST
  ↓
AD RETEST
  ↓
REGRESSION CHECK
```

---

# 03.44 - Controlled Failure Test : DC02 DNS

Réaliser ce test séparément, après restauration complète de DC01.

Baseline obligatoire :

```powershell
Get-Service DNS
```

sur DC01 et DC02.

Puis, dans le lab seulement, arrêter le DNS de DC02 :

```powershell
Invoke-Command -ComputerName DC02 -ScriptBlock {

    Stop-Service DNS
    Get-Service DNS
}
```

Depuis `WIN11` :

```powershell
ipconfig /flushdns

Resolve-DnsName dc01.diarabaka.com
Resolve-DnsName dc02.diarabaka.com

Resolve-DnsName `
    "_ldap._tcp.dc._msdcs.diarabaka.com" `
    -Type SRV

nltest /dsgetdc:diarabaka.com
```

Restaurer immédiatement :

```powershell
Invoke-Command -ComputerName DC02 -ScriptBlock {

    Start-Service DNS
    Get-Service DNS
}
```

Puis refaire les tests directs contre DC02.

---

# 03.45 - Post-Failure Regression

Après chaque test de panne :

```powershell
repadmin /replsummary
repadmin /showrepl DC01
repadmin /showrepl DC02
dcdiag /test:replications
dcdiag /test:dns
```

Puis sur `WIN11` :

```powershell
Resolve-DnsName dc01.diarabaka.com
Resolve-DnsName dc02.diarabaka.com
nltest /dsgetdc:diarabaka.com
```

Ne pas clôturer le failure test simplement parce que le service DNS a redémarré.

---

# 03.46 - Post-Reboot Validation

Le fonctionnement doit survivre au reboot.

Ne jamais redémarrer `DC01` et `DC02` simultanément.

## Reboot DC01

Avant :

```powershell
repadmin /replsummary
Get-Service DNS
```

Redémarrage contrôlé :

```powershell
Restart-Computer
```

Après retour de DC01 :

```powershell
Get-Service DNS

Resolve-DnsName dc01.diarabaka.com
Resolve-DnsName dc02.diarabaka.com

Resolve-DnsName `
    "_ldap._tcp.dc._msdcs.diarabaka.com" `
    -Type SRV

dcdiag /test:dns
repadmin /replsummary
```

## DC02

Réaliser séparément après validation complète de DC01.

---

# 03.47 - Post-Reboot WIN11

Sur `WIN11` :

```powershell
ipconfig /flushdns

Resolve-DnsName diarabaka.com
Resolve-DnsName dc01.diarabaka.com
Resolve-DnsName dc02.diarabaka.com

Resolve-DnsName `
    "_ldap._tcp.dc._msdcs.diarabaka.com" `
    -Type SRV

nltest /dsgetdc:diarabaka.com
nltest /dsgetsite
```

Puis :

```powershell
klist
```

Objectif :

```text
REBOOT
  ↓
DNS
  ↓
DC LOCATOR
  ↓
SITE
  ↓
KERBEROS
  ↓
DOMAIN OPERATIONS
```

---

# 03.48 - Troubleshooting Methodology

Méthode Confirmed :

```text
SYMPTOM
   ↓
SCOPE
   ↓
CLIENT DNS CONFIG
   ↓
NETWORK
   ↓
DNS SERVER REACHABILITY
   ↓
DNS SERVICE
   ↓
ZONE
   ↓
RECORD
   ↓
CACHE
   ↓
SRV
   ↓
DC LOCATOR
   ↓
SITE / SUBNET
   ↓
LDAP / KERBEROS
   ↓
AD REPLICATION
   ↓
EVENT LOGS
   ↓
ROOT CAUSE
   ↓
MINIMUM SAFE CORRECTION
   ↓
RETEST
   ↓
REGRESSION TEST
   ↓
EVIDENCE
```

Règle :

```text
DO NOT:
restart everything
flush everything
register everything
recreate zones
change forwarders
change client DNS
```

avant d'avoir isolé le problème.

---

# 03.49 - Incident DNS-INC-001 : nom interne non résolu

Symptôme :

```text
dc01.diarabaka.com
        ↓
resolution failure
```

Collecte :

```powershell
Get-DnsClientServerAddress -AddressFamily IPv4

Resolve-DnsName dc01.diarabaka.com

Test-NetConnection <DNS_SERVER_IP> -Port 53
```

Sur DNS :

```powershell
Get-Service DNS

Get-DnsServerZone

Get-DnsServerResourceRecord `
    -ZoneName "diarabaka.com"
```

Ne pas créer immédiatement un A record.

---

# 03.50 - Incident DNS-INC-002 : IP fonctionne, nom échoue

Symptôme :

```text
IP CONNECTIVITY
    PASS

DNS NAME
    FAIL
```

Analyser :

```text
CLIENT DNS SERVERS
PORT 53 REACHABILITY
DNS SERVICE
ZONE
A RECORD
CACHE
```

Commandes :

```powershell
ipconfig /all
Resolve-DnsName dc01.diarabaka.com
Test-NetConnection <DNS_SERVER_IP> -Port 53
```

---

# 03.51 - Incident DNS-INC-003 : A fonctionne, PTR échoue

```text
NAME → IP
   PASS

IP → NAME
   FAIL
```

Vérifier :

```powershell
Get-DnsServerZone `
    -Name "1.168.192.in-addr.arpa"

Get-DnsServerResourceRecord `
    -ZoneName "1.168.192.in-addr.arpa"
```

Puis vérifier l'enregistrement dynamique/manuel attendu.

---

# 03.52 - Incident DNS-INC-004 : DC Locator échoue

```powershell
nltest /dsgetdc:diarabaka.com
```

Puis :

```powershell
Resolve-DnsName `
    "_ldap._tcp.dc._msdcs.diarabaka.com" `
    -Type SRV
```

Puis :

```powershell
nltest /dsgetsite
```

Puis :

```powershell
dcdiag /test:dns
repadmin /replsummary
```

Chaîne :

```text
CLIENT DNS
   ↓
SRV
   ↓
SITE
   ↓
DC LOCATOR
   ↓
AD REPLICATION
```

---

# 03.53 - Incident DNS-INC-005 : résolution externe échoue

Tester d'abord l'interne :

```powershell
Resolve-DnsName dc01.diarabaka.com
```

Puis externe :

```powershell
Resolve-DnsName www.microsoft.com
```

Puis :

```powershell
Get-DnsServerForwarder
```

Distinguer :

```text
INTERNAL AD DNS FAILURE
```

de :

```text
EXTERNAL RECURSION / FORWARDER FAILURE
```

---

# 03.54 - Incident DNS-INC-006 : réponses différentes DC01/DC02

Tester explicitement :

```powershell
Resolve-DnsName `
    dc01.diarabaka.com `
    -Server <DC01_IP>

Resolve-DnsName `
    dc01.diarabaka.com `
    -Server <DC02_IP>
```

Puis :

```powershell
repadmin /replsummary
repadmin /showrepl DC01
repadmin /showrepl DC02
```

Ne pas forcer immédiatement la réplication.

Collecter l'erreur exacte.

---

# 03.55 - Incident DNS-INC-007 : ancien résultat après correction

Sur client :

```powershell
ipconfig /displaydns
```

Puis comparer :

```powershell
Resolve-DnsName `
    dc01.diarabaka.com `
    -Server <DC01_IP>
```

Si serveur correct mais client encore obsolète :

```powershell
Clear-DnsClientCache
```

Puis retester.

---

# 03.56 - Incident DNS-INC-008 : Kerberos semble en panne

Ne pas se limiter à :

```powershell
Test-NetConnection dc01.diarabaka.com -Port 88
```

Collecter :

```powershell
Resolve-DnsName `
    "_kerberos._tcp.diarabaka.com" `
    -Type SRV

nltest /dsgetdc:diarabaka.com

w32tm /query /status

klist
```

Puis tester une ressource de domaine.

---

# 03.57 - Incident DNS-INC-009 : LDAP semble en panne

Collecter :

```powershell
Resolve-DnsName `
    "_ldap._tcp.dc._msdcs.diarabaka.com" `
    -Type SRV

Test-NetConnection dc01.diarabaka.com -Port 389
Test-NetConnection dc02.diarabaka.com -Port 389
```

Puis test fonctionnel :

```powershell
Get-ADDomainController `
    -Discover `
    -DomainName diarabaka.com
```

Distinguer :

```text
DNS discovery
TCP reachability
LDAP/AD functionality
```

---

# 03.58 - Incident DNS-INC-010 : mauvais DC sélectionné

Depuis le client :

```powershell
nltest /dsgetsite
nltest /dsgetdc:diarabaka.com
```

Sur DC :

```powershell
Get-ADReplicationSubnet -Filter * |
    Select-Object Name,Site
```

Puis tester les site-specific SRV.

Cause possible :

```text
missing subnet
wrong subnet
wrong site association
SRV issue
replication issue
```

Ne pas modifier le site avant preuve.

---

# 03.59 - Final DNS Audit

## Identity

```powershell
Get-Date
hostname
whoami
```

## Services

```powershell
Get-Service DNS
```

```powershell
Invoke-Command -ComputerName DC02 -ScriptBlock {

    Get-Service DNS
}
```

## Zones

```powershell
Get-DnsServerZone |
    Select-Object `
        ZoneName,
        ZoneType,
        IsDsIntegrated,
        DynamicUpdate,
        ReplicationScope |
    Sort-Object ZoneName
```

## Forwarders

```powershell
Get-DnsServerForwarder
```

## A

```powershell
Resolve-DnsName dc01.diarabaka.com -Type A
Resolve-DnsName dc02.diarabaka.com -Type A
```

## PTR

```powershell
Resolve-DnsName <DC01_IP>
Resolve-DnsName <DC02_IP>
```

## LDAP SRV

```powershell
Resolve-DnsName `
    "_ldap._tcp.dc._msdcs.diarabaka.com" `
    -Type SRV
```

## Kerberos SRV

```powershell
Resolve-DnsName `
    "_kerberos._tcp.diarabaka.com" `
    -Type SRV
```

## GC SRV

```powershell
Resolve-DnsName `
    "_ldap._tcp.gc._msdcs.diarabaka.com" `
    -Type SRV
```

## DC Locator

```powershell
nltest /dsgetdc:diarabaka.com
```

## Site

```powershell
nltest /dsgetsite
```

## DNS Diagnostics

```powershell
dcdiag /test:dns /DnsAll /e /v
```

## Replication

```powershell
repadmin /replsummary
repadmin /showrepl DC01
repadmin /showrepl DC02
dcdiag /test:replications
```

## Security

```powershell
Get-DnsServerZone -Name "diarabaka.com" |
    Select-Object `
        ZoneName,
        IsDsIntegrated,
        DynamicUpdate,
        ReplicationScope
```

## Aging

```powershell
Get-DnsServerZoneAging -Name "diarabaka.com"
```

## Scavenging

```powershell
Get-DnsServerScavenging
```

## Logs

```powershell
Get-WinEvent -ListLog *DNS* |
    Select-Object `
        LogName,
        IsEnabled,
        RecordCount
```

---

# 03.63 - Final Regression Test

À exécuter uniquement après les corrections éventuelles.

Sur `DC01` :

```powershell
Get-Service DNS

Get-DnsServerZone |
    Select-Object `
        ZoneName,
        IsDsIntegrated,
        DynamicUpdate,
        ReplicationScope

Resolve-DnsName dc01.diarabaka.com
Resolve-DnsName dc02.diarabaka.com

Resolve-DnsName `
    "_ldap._tcp.dc._msdcs.diarabaka.com" `
    -Type SRV

Resolve-DnsName `
    "_kerberos._tcp.diarabaka.com" `
    -Type SRV

dcdiag /test:dns

repadmin /replsummary
```

Sur `WIN11` :

```powershell
Get-DnsClientServerAddress -AddressFamily IPv4

Resolve-DnsName dc01.diarabaka.com
Resolve-DnsName dc02.diarabaka.com

Resolve-DnsName `
    "_ldap._tcp.dc._msdcs.diarabaka.com" `
    -Type SRV

nltest /dsgetsite
nltest /dsgetdc:diarabaka.com

klist
```

---

Sur `DC01`, ouvre PowerShell en administrateur et exécute :

```PowerShell
Move-ADDirectoryServerOperationMasterRole `
    -Identity "DC02" `
    -OperationMasterRole SchemaMaster,DomainNamingMaster
```

Cela signifie :

```
Tu exécutes la commande sur : DC01
Destination des rôles       : DC02
```

Après le transfert, vérifie toujours depuis DC01 :

```PowerShell
netdom query fsmo
```

```
Schema master               DC02.diarabaka.com
Domain naming master        DC02.diarabaka.com
PDC                         DC01.diarabaka.com
RID pool manager            DC01.diarabaka.com
Infrastructure master       DC01.diarabaka.com
```


---

# 03.64 - Architecture finale

```text
                              WIN11
                                │
                                │ DNS
                                ▼
                     ┌─────────────────────┐
                     │                     │
                     ▼                     ▼
                   DC01                  DC02
                AD DS + DNS           AD DS + DNS
                     │                     │
                     └──────────┬──────────┘
                                │
                         AD REPLICATION
                                │
              ┌─────────────────┼─────────────────┐
              │                 │                 │
              ▼                 ▼                 ▼
        diarabaka.com    _msdcs.diarabaka.com   Reverse DNS
              │                 │                 │
        A / other data     LDAP / Kerberos       PTR
              │             GC / DC Locator       │
              └─────────────────┼─────────────────┘
                                │
                         Internal queries
                                │
                                ▼
                           ACTIVE DIRECTORY

External query:
WIN11
  │
  ▼
DC01 / DC02
  │
  ▼
Configured Forwarder / Recursive Resolution
  │
  ▼
External DNS
```

