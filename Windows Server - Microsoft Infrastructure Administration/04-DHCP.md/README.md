# PHASE 04 - DHCP

## Windows Server 2025 Enterprise Infrastructure

**Project:** Windows Server 2025 Enterprise Infrastructure  
**Domain:** `diarabaka.com`  
**Network:** `192.168.1.0/24`  
**DC01:** `192.168.1.10`  
**DC02:** `192.168.1.11`  
**Gateway:** `192.168.1.1`  
**Client:** `WIN11`  
**Platform:** VMware  
**Professional Domain:** Microsoft Infrastructure  
**Target Level:** Confirmed

---

# 04.0 - Objectif

DHCP fournit automatiquement aux clients les paramètres réseau nécessaires à leur fonctionnement :

```text
IPv4 Address
Subnet Mask
Default Gateway
DNS Servers
DNS Domain
Lease
```

Dans notre infrastructure :

```text
                    192.168.1.0/24
                           │
               ┌───────────┴───────────┐
               │                       │
               ▼                       ▼
             DC01                    DC02
        AD + DNS + DHCP        AD + DNS + DHCP
               │                       │
               └───────────┬───────────┘
                           │
                    DHCP Failover
                     Load Balance
                        50 / 50
                           │
                           ▼
                         WIN11
                           │
                    ┌──────┼──────┐
                    │      │      │
                    ▼      ▼      ▼
                   IP   Gateway   DNS
                                  │
                           DC01 + DC02
                                  │
                                  ▼
                           diarabaka.com
```

---

# 04.2 - Architecture réseau

Valeurs prévues pour le lab :

```text
Network  : 192.168.1.0/24
Gateway  : 192.168.1.1

DC01     : 192.168.1.10
DC02     : 192.168.1.11

DHCP Pool:
192.168.1.100
        ↓
192.168.1.200
```

---

# 04.3 - Préparer l'Evidence Pack

Sur `DC01` :

```powershell
$EvidenceRoot = "C:\Evidence\DHCP"

$Folders = @(
    "01-Baseline",
    "02-Network",
    "03-Role",
    "04-Authorization",
    "05-Binding",
    "06-Scope",
    "07-Options",
    "08-Dynamic-DNS",
    "09-DDNS-Credentials",
    "10-Leases",
    "11-Reservations",
    "12-Client",
    "13-Failover",
    "14-Failover-Replication",
    "15-Failover-States",
    "16-Statistics",
    "17-Logs",
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

---

# 04.4 - Baseline DHCP avant modification

Sur `DC01` :

```powershell
Get-Date
hostname
whoami
```

Puis :

```powershell
Get-WindowsFeature DHCP
```

```powershell
Get-Service DHCPServer `
    -ErrorAction SilentlyContinue
```

```powershell
Get-DhcpServerInDC
```

```powershell
Get-DhcpServerv4Binding `
    -ErrorAction SilentlyContinue
```

```powershell
Get-DhcpServerv4Scope `
    -ErrorAction SilentlyContinue
```

```powershell
Get-DhcpServerv4OptionValue `
    -ErrorAction SilentlyContinue
```

```powershell
Get-DhcpServerv4Failover `
    -ErrorAction SilentlyContinue
```

```powershell
Get-DhcpServerv4DnsSetting `
    -ErrorAction SilentlyContinue
```

```powershell
Get-DhcpServerDnsCredential `
    -ErrorAction SilentlyContinue
```

---

# 04.5 - Vérifier DC01

```powershell
hostname
```

Puis :

```powershell
Get-NetIPAddress `
    -AddressFamily IPv4 |
    Where-Object {
        $_.IPAddress -like "192.168.1.*"
    } |
    Select-Object `
        IPAddress,
        PrefixLength,
        InterfaceAlias
```

Cible :

```text
Hostname : DC01
IPv4     : 192.168.1.10
Prefix   : /24
```

---

# 04.6 - Vérifier DC02

Depuis `DC01` :

```powershell
Invoke-Command `
    -ComputerName DC02 `
    -ScriptBlock {

        hostname

        Get-NetIPAddress `
            -AddressFamily IPv4 |
            Where-Object {
                $_.IPAddress -like "192.168.1.*"
            } |
            Select-Object `
                IPAddress,
                PrefixLength,
                InterfaceAlias
    }
```

Cible :

```text
Hostname : DC02
IPv4     : 192.168.1.11
Prefix   : /24
```

---

# 04.7 - Vérifier la Gateway

Sur `WIN11` :

```powershell
Get-NetRoute `
    -DestinationPrefix "0.0.0.0/0" |
    Select-Object `
        InterfaceAlias,
        NextHop,
        RouteMetric
```

Cible :

```text
NextHop : 192.168.1.1
```

Puis :

```powershell
Test-Connection 192.168.1.1
```

---

# 04.8 - Vérifier WIN11 avant DHCP

Sur `WIN11` :

```powershell
ipconfig /all
```

Puis :

```powershell
Get-NetIPConfiguration
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

Cette sortie constitue la baseline client.

---

# 04.9 - Inventaire DHCP DC01

```powershell
Get-WindowsFeature DHCP
```

```powershell
Get-Service DHCPServer `
    -ErrorAction SilentlyContinue
```

```powershell
Get-DhcpServerInDC
```

Si le rôle existe déjà :

```powershell
Get-DhcpServerv4Scope
```

Puis :

```powershell
Get-DhcpServerv4Binding
```

Puis :

```powershell
Get-DhcpServerv4OptionValue
```

Règle :

```text
EXISTS
  ↓
AUDIT

MISSING
  ↓
INSTALL / CONFIGURE
```

---

# 04.10 - Installer DHCP sur DC01

Uniquement si nécessaire :

```powershell
Install-WindowsFeature `
    DHCP `
    -IncludeManagementTools
```

Vérifier :

```powershell
Get-WindowsFeature DHCP
```

Puis :

```powershell
Get-Service DHCPServer
```

Cible :

```text
DHCP Feature : Installed
DHCP Service : Running
```

---

# 04.11 - Autoriser DC01 dans Active Directory

Vérifier :

```powershell
Get-DhcpServerInDC
```

Si absent :

```powershell
Add-DhcpServerInDC `
    -DnsName "DC01.diarabaka.com" `
    -IPAddress 192.168.1.10
```

Puis :

```powershell
Get-DhcpServerInDC
```

Cible :

```text
DC01.diarabaka.com
192.168.1.10
```

---

# 04.12 - Vérifier les bindings DC01

```powershell
Get-DhcpServerv4Binding |
    Select-Object `
        InterfaceAlias,
        IPAddress,
        BindingState
```

---

# 04.13 - Vérifier les scopes existants

```powershell
Get-DhcpServerv4Scope |
    Format-Table `
        ScopeId,
        Name,
        StartRange,
        EndRange,
        SubnetMask,
        State `
        -AutoSize
```

Si `192.168.1.0` existe déjà :

---

# 04.14 - Vérifier le plan d'adressage

Design :

```text
Network:
192.168.1.0/24

Infrastructure:
192.168.1.1   Gateway
192.168.1.10  DC01
192.168.1.11  DC02

Dynamic Pool:
192.168.1.100
      ↓
192.168.1.200
```

Les IP d'infrastructure sont hors de la plage dynamique.

Donc aucune exclusion n'est requise pour :

```text
192.168.1.1
192.168.1.10
192.168.1.11
```

tant que le pool reste `100–200`.

---

# 04.15 - Créer le scope

Seulement s'il est absent :

```powershell
Add-DhcpServerv4Scope `
    -Name "LAN-192.168.1.0" `
    -StartRange 192.168.1.100 `
    -EndRange 192.168.1.200 `
    -SubnetMask 255.255.255.0 `
    -State Active
```

---

# 04.16 - Vérifier le scope

```powershell
Get-DhcpServerv4Scope |
    Format-Table `
        ScopeId,
        Name,
        StartRange,
        EndRange,
        SubnetMask,
        State `
        -AutoSize
```

Cible :

```text
ScopeId     : 192.168.1.0
StartRange  : 192.168.1.100
EndRange    : 192.168.1.200
SubnetMask  : 255.255.255.0
State       : Active
```

---

# 04.17 - Exclusions

Une exclusion ne concerne que des adresses situées dans le pool du scope.

Exemple de principe :

```text
100 ─────────────────────────── 200
          ┌──────────┐
          │Excluded  │
          └──────────┘
```

Si une plage doit réellement être réservée :

```powershell
Add-DhcpServerv4ExclusionRange `
    -ScopeId 192.168.1.0 `
    -StartRange <EXCLUSION_START> `
    -EndRange <EXCLUSION_END>
```

Vérifier :

```powershell
Get-DhcpServerv4ExclusionRange `
    -ScopeId 192.168.1.0
```

---

# 04.18 - Configurer les options DHCP

Variables :

```powershell
$Scope   = "192.168.1.0"
$DC01    = "192.168.1.10"
$DC02    = "192.168.1.11"
$Gateway = "192.168.1.1"
```

Puis :

```powershell
Set-DhcpServerv4OptionValue `
    -ScopeId $Scope `
    -Router $Gateway `
    -DnsServer $DC01,$DC02 `
    -DnsDomain "diarabaka.com"
```

---

# 04.19 - Vérifier Options 003 / 006 / 015

```powershell
Get-DhcpServerv4OptionValue `
    -ScopeId 192.168.1.0
```

Cibles :

```text
003 Router
    ↓
192.168.1.1

006 DNS Servers
    ↓
192.168.1.10
192.168.1.11

015 DNS Domain
    ↓
diarabaka.com
```

---

# 04.20 - Pourquoi Option 006 est critique

WIN11 ne doit pas recevoir uniquement :

```text
8.8.8.8
1.1.1.1
```

Le client de domaine doit utiliser les DNS Active Directory :

```text
WIN11
  │
  ├── DNS1 → 192.168.1.10
  └── DNS2 → 192.168.1.11
```

Il doit pouvoir résoudre :

```text
diarabaka.com
_msdcs.diarabaka.com
LDAP
Kerberos
DC Locator
```

---

# 04.21 - Dynamic DNS : audit

Vérifier au niveau serveur :

```powershell
Get-DhcpServerv4DnsSetting
```

Vérifier au niveau scope :

```powershell
Get-DhcpServerv4DnsSetting `
    -ScopeId 192.168.1.0
```

Documenter les valeurs réelles avant modification.

---

# 04.22 - Dynamic DNS : configuration scope

Si le design le requiert :

```powershell
Set-DhcpServerv4DnsSetting `
    -ScopeId 192.168.1.0 `
    -DynamicUpdates Always `
    -DeleteDnsRROnLeaseExpiry $true
```

Puis :

```powershell
Get-DhcpServerv4DnsSetting `
    -ScopeId 192.168.1.0
```

---

# 04.23 - DDNS credentials

Vérifier sur DC01 :

```powershell
Get-DhcpServerDnsCredential `
    -ComputerName DC01
```

Sur DC02 :

```powershell
Get-DhcpServerDnsCredential `
    -ComputerName DC02
```

Architecture cible :

```text
DHCP Service
     │
     ▼
Dedicated DNS Update Account
     │
     ▼
Secure Dynamic DNS
```

Ne pas utiliser :

```text
Domain Admin
Enterprise Admin
Administrator
```

comme identité DDNS.

Le compte technique doit être rangé sous :

```text
OU=Service Accounts,OU=Diarabaka,DC=diarabaka,DC=com
```

et suivre le principe du moindre privilège.

---

# 04.24 - Cohérence des credentials DDNS en failover

Avec DHCP failover, les deux partenaires doivent avoir une stratégie DDNS cohérente.

Validation :

```text
DC01 DDNS CREDENTIAL
        =
DC02 DDNS CREDENTIAL
```

Comparer :

```powershell
Get-DhcpServerDnsCredential -ComputerName DC01
Get-DhcpServerDnsCredential -ComputerName DC02
```

---

# 04.25 - Vérifier les leases

```powershell
Get-DhcpServerv4Lease `
    -ScopeId 192.168.1.0 |
    Select-Object `
        IPAddress,
        ScopeId,
        ClientId,
        HostName,
        AddressState,
        LeaseExpiryTime |
    Format-Table -AutoSize
```

Cette commande permet de vérifier :

```text
Client
IP
Client ID
Lease state
Lease expiry
```

---

# 04.26 - Scope Statistics

```powershell
Get-DhcpServerv4ScopeStatistics `
    -ScopeId 192.168.1.0
```

---

# 04.27 - Réservation DHCP

Une réservation associe un client DHCP à une IP déterminée.

```text
Client ID
   ↓
Reservation
   ↓
Fixed DHCP Address
```

La réservation doit appartenir au scope réellement administré.

---

# 04.28 - Identifier WIN11

Sur serveur :

```powershell
Get-DhcpServerv4Lease `
    -ScopeId 192.168.1.0
```

Identifier :

```text
WIN11
ClientId
Current IP
```

Sur WIN11 :

```powershell
Get-NetAdapter |
    Select-Object `
        Name,
        MacAddress,
        Status
```

Comparer l'adaptateur réellement utilisé avec le `ClientId`.

---

# 04.29 - Créer la réservation WIN11

Choisir une IP libre dans le scope.

```powershell
$ReservedIP = "<WIN11_RESERVED_IP>"
$ClientId   = "<WIN11_CLIENT_ID>"
```

Puis :

```powershell
Add-DhcpServerv4Reservation `
    -ScopeId 192.168.1.0 `
    -IPAddress $ReservedIP `
    -ClientId $ClientId `
    -Name "WIN11" `
    -Description "WIN11 DHCP Reservation"
```

---

# 04.30 - Vérifier la réservation

```powershell
Get-DhcpServerv4Reservation `
    -ScopeId 192.168.1.0 |
    Format-Table `
        IPAddress,
        ClientId,
        Name,
        Description `
        -AutoSize
```

---

# 04.31 - Test client WIN11

Baseline :

```powershell
ipconfig /all
```

Puis test contrôlé :

```powershell
ipconfig /release
```

Puis :

```powershell
ipconfig /renew
```

Puis :

```powershell
ipconfig /all
```

---

# 04.32 - Résultat client attendu

```text
DHCP Enabled      : Yes
IPv4 Address      : Scope IP or reservation
Subnet Mask       : 255.255.255.0
Default Gateway   : 192.168.1.1
DHCP Server       : DC01 or DC02
DNS Servers       : 192.168.1.10
                    192.168.1.11
DNS Suffix        : diarabaka.com
```

---

# 04.33 - Vérifier le lease côté serveur

```powershell
Get-DhcpServerv4Lease `
    -ScopeId 192.168.1.0 |
    Where-Object {
        $_.HostName -like "WIN11*"
    } |
    Format-List
```

Objectif :

```text
WIN11
  ↓
DHCP lease
  ↓
Expected IPv4
```

---

# 04.34 - Test DNS après DHCP

Sur WIN11 :

```powershell
Resolve-DnsName dc01.diarabaka.com
Resolve-DnsName dc02.diarabaka.com
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

Un lease n'est pas correctement validé si :

```text
IP received
BUT
AD DNS unusable
```

---

# 04.35 - Vérifier Dynamic DNS de WIN11

Depuis DC01 :

```powershell
Resolve-DnsName WIN11.diarabaka.com
```

Puis avec l'IP réelle :

```powershell
Resolve-DnsName <WIN11_IP>
```

Objectif :

```text
WIN11
  ↓
A record
  ↓
IPv4

IPv4
  ↓
PTR
  ↓
WIN11
```

Le comportement réel dépend de la stratégie DDNS.

---

# 04.36 - Test DDNS après renouvellement

Sur WIN11 :

```powershell
ipconfig /release
ipconfig /renew
```

Puis sur DC01 :

```powershell
Resolve-DnsName WIN11.diarabaka.com
Resolve-DnsName <WIN11_IP>
```

Ensuite inspecter le lease :

```powershell
Get-DhcpServerv4Lease `
    -ScopeId 192.168.1.0 |
    Where-Object {
        $_.HostName -like "WIN11*"
    }
```

Objectif :

```text
LEASE
  +
A RECORD
  +
PTR RECORD
  =
DDNS FUNCTIONAL EVIDENCE
```

---

# 04.37 - Préparer DC02

Installer DHCP si nécessaire :

```powershell
Invoke-Command `
    -ComputerName DC02 `
    -ScriptBlock {

        Install-WindowsFeature `
            DHCP `
            -IncludeManagementTools
    }
```

---

# 04.38 - Vérifier DHCP DC02

```powershell
Invoke-Command `
    -ComputerName DC02 `
    -ScriptBlock {

        Get-WindowsFeature DHCP
        Get-Service DHCPServer
        Get-DhcpServerv4Binding
    }
```

Cible :

```text
Role     : Installed
Service  : Running
Binding  : Correct
```

---

# 04.39 - Autoriser DC02 dans Active Directory

Vérifier :

```powershell
Get-DhcpServerInDC
```

Si absent :

```powershell
Add-DhcpServerInDC `
    -DnsName "DC02.diarabaka.com" `
    -IPAddress 192.168.1.11
```

Puis :

```powershell
Get-DhcpServerInDC
```

Cible :

```text
DC01.diarabaka.com  192.168.1.10
DC02.diarabaka.com  192.168.1.11
```

---

# 04.40 - Pré-check Failover

Sur DC01 :

```powershell
Get-DhcpServerv4Scope
Get-DhcpServerv4OptionValue `
    -ScopeId 192.168.1.0
Get-DhcpServerv4Reservation `
    -ScopeId 192.168.1.0
Get-DhcpServerv4Lease `
    -ScopeId 192.168.1.0
```

Sur DC02 :

```powershell
Get-DhcpServerv4Scope `
    -ComputerName DC02
```

Avant failover :

```text
DC01
 └── Scope 192.168.1.0
       → Present

DC02
 ├── DHCP installed
 ├── Authorized
 └── Scope 192.168.1.0
       → MUST NOT be manually duplicated
```

---

# 04.41 - Baseline Failover

Collecter avant création :

```powershell
Get-DhcpServerv4Scope `
    -ComputerName DC01

Get-DhcpServerv4Scope `
    -ComputerName DC02

Get-DhcpServerv4OptionValue `
    -ComputerName DC01 `
    -ScopeId 192.168.1.0

Get-DhcpServerv4Reservation `
    -ComputerName DC01 `
    -ScopeId 192.168.1.0
```

---

# 04.42 - Concepts Failover à comprendre

DHCP Failover Windows Server fonctionne pour DHCPv4.

Dans ce projet :

```text
Mode:
Load Balance

Distribution:
50 / 50
```

Important :

```text
FAILOVER
   ≠
INSTANT FULL TAKEOVER
```

Le comportement dépend notamment de :

```text
State
CommunicationInterrupted
PartnerDown
AutoStateTransition
StateSwitchInterval
MaxClientLeadTime (MCLT)
```

---

# 04.43 - Max Client Lead Time

Le `MCLT` limite temporairement certains comportements de location lorsqu'un partenaire devient indisponible.

Architecture logique :

```text
PARTNER COMMUNICATION LOST
          ↓
CommunicationInterrupted
          ↓
AutoStateTransition / Admin action
          ↓
PartnerDown
          ↓
MCLT constraints
          ↓
Greater access to partner address ownership
```

Le MCLT doit être documenté dans la relation de failover.

---

# 04.44 - Créer DHCP Failover

Depuis DC01 :

```powershell
Add-DhcpServerv4Failover `
    -ComputerName DC01 `
    -PartnerServer DC02 `
    -Name "DHCP-DC01-DC02" `
    -ScopeId 192.168.1.0 `
    -LoadBalancePercent 50 `
    -AutoStateTransition $true `
    -StateSwitchInterval 01:00:00
```

---

# 04.45 - Failover Authentication Review

Documenter :

```text
Failover authentication configured?
Shared secret handling?
Secret stored securely?
Secret absent from repository?
```

Ne jamais écrire :

```text
SharedSecret = MySecret123
```

dans un document de projet.

---

# 04.46 - Vérifier le partenariat DC01

```powershell
Get-DhcpServerv4Failover `
    -ComputerName DC01 |
    Format-List
```

Vérifier notamment :

```text
Name
PartnerServer
Mode
LoadBalancePercent
State
MaxClientLeadTime
AutoStateTransition
StateSwitchInterval
```

Cible nominale :

```text
Name               : DHCP-DC01-DC02
PartnerServer      : DC02
Mode               : LoadBalance
LoadBalancePercent : 50
State              : Normal
```

---

# 04.47 - Vérifier le partenariat DC02

```powershell
Get-DhcpServerv4Failover `
    -ComputerName DC02 |
    Format-List
```

Le partenariat doit être cohérent des deux côtés.

---

# 04.48 - Vérifier le scope sur DC02

```powershell
Get-DhcpServerv4Scope `
    -ComputerName DC02 |
    Format-Table `
        ScopeId,
        Name,
        StartRange,
        EndRange,
        State `
        -AutoSize
```

Attendu après création du failover :

```text
192.168.1.0
```

---

# 04.49 - Vérifier Options sur les deux partenaires

DC01 :

```powershell
Get-DhcpServerv4OptionValue `
    -ComputerName DC01 `
    -ScopeId 192.168.1.0
```

DC02 :

```powershell
Get-DhcpServerv4OptionValue `
    -ComputerName DC02 `
    -ScopeId 192.168.1.0
```

Comparer :

```text
003
006
015
```

---

# 04.50 - Vérifier les réservations sur les deux partenaires

DC01 :

```powershell
Get-DhcpServerv4Reservation `
    -ComputerName DC01 `
    -ScopeId 192.168.1.0
```

DC02 :

```powershell
Get-DhcpServerv4Reservation `
    -ComputerName DC02 `
    -ScopeId 192.168.1.0
```

---

# 04.51 - Lease Synchronization vs Configuration Replication

Important :

```text
LEASE SYNCHRONIZATION
        ≠
ADMINISTRATIVE CONFIG REPLICATION
```

Les baux sont synchronisés dans le cadre du failover.

Mais après certaines modifications administratives du scope, il faut explicitement synchroniser la configuration vers le partenaire.

---

# 04.52 - Réplication manuelle de configuration Failover

Après une modification du scope sur DC01 :

```powershell
Invoke-DhcpServerv4FailoverReplication `
    -ComputerName DC01 `
    -ScopeId 192.168.1.0 `
    -Force
```

Puis comparer :

```powershell
Get-DhcpServerv4OptionValue `
    -ComputerName DC01 `
    -ScopeId 192.168.1.0

Get-DhcpServerv4OptionValue `
    -ComputerName DC02 `
    -ScopeId 192.168.1.0
```

Puis :

```powershell
Get-DhcpServerv4Reservation `
    -ComputerName DC01 `
    -ScopeId 192.168.1.0

Get-DhcpServerv4Reservation `
    -ComputerName DC02 `
    -ScopeId 192.168.1.0
```

Principe :

```text
SOURCE OF TRUTH
      ↓
FAILOVER REPLICATION
      ↓
PARTNER CONFIG UPDATED
```

Avant de lancer la réplication, vérifier quel serveur contient la configuration correcte.

---

# 04.53 - Vérifier les leases sur les deux partenaires

DC01 :

```powershell
Get-DhcpServerv4Lease `
    -ComputerName DC01 `
    -ScopeId 192.168.1.0
```

DC02 :

```powershell
Get-DhcpServerv4Lease `
    -ComputerName DC02 `
    -ScopeId 192.168.1.0
```

Comparer :

```text
ClientId
IPAddress
HostName
AddressState
LeaseExpiryTime
```

---

# 04.54 - Scope Statistics en failover

DC01 :

```powershell
Get-DhcpServerv4ScopeStatistics `
    -ComputerName DC01 `
    -ScopeId 192.168.1.0
```

DC02 :

```powershell
Get-DhcpServerv4ScopeStatistics `
    -ComputerName DC02 `
    -ScopeId 192.168.1.0
```

Ces statistiques deviennent utiles avant, pendant et après les tests de panne.

---

# 04.55 - Test nominal Failover

Vérifier :

```powershell
Get-DhcpServerv4Failover `
    -ComputerName DC01
```

Cible nominale :

```text
State : Normal
```

Sur WIN11 :

```powershell
ipconfig /release
ipconfig /renew
ipconfig /all
```

Puis côté serveur :

```powershell
Get-DhcpServerv4Lease `
    -ScopeId 192.168.1.0 |
    Where-Object {
        $_.HostName -like "WIN11*"
    }
```

---

# 04.56 - Baseline avant test de panne DC01

Vérifier DC01 :

```powershell
Get-Service DHCPServer `
    -ComputerName DC01
```

DC02 :

```powershell
Get-Service DHCPServer `
    -ComputerName DC02
```

Failover :

```powershell
Get-DhcpServerv4Failover `
    -ComputerName DC01 |
    Format-List
```

Statistics :

```powershell
Get-DhcpServerv4ScopeStatistics `
    -ComputerName DC01 `
    -ScopeId 192.168.1.0

Get-DhcpServerv4ScopeStatistics `
    -ComputerName DC02 `
    -ScopeId 192.168.1.0
```

---

# 04.57 - Controlled Failure : DC01 DHCP

Stopper uniquement le service DHCP sur DC01 :

```powershell
Stop-Service DHCPServer
```

Vérifier :

```powershell
Get-Service DHCPServer
```

Attendu :

```text
Stopped
```

---

# 04.58 - Observer l'état Failover pendant la panne

Sur DC02 :

```powershell
Get-DhcpServerv4Failover `
    -ComputerName DC02 |
    Format-List
```

L'état peut évoluer.

Ne pas supposer instantanément :

```text
PartnerDown
```

Exemples possibles selon le timing et la configuration :

```text
CommunicationInterrupted
PartnerDown
PartnerDownPending
Normal
```

---

# 04.59 - Timeline de panne

Evidence recommandée :

```text
T0
DC01 DHCP stopped

T+short interval
Failover state captured

T+StateSwitchInterval
Failover state captured again

T+MCLT-related interval
State / address availability reviewed

T+recovery
DC01 started
Failover state captured
```

L'objectif n'est pas d'attendre artificiellement des heures si ce n'est pas requis par le lab ; il faut surtout démontrer que tu comprends la logique des transitions.

---

# 04.60 - Test WIN11 pendant panne DC01

Sur WIN11 :

```powershell
ipconfig /release
ipconfig /renew
ipconfig /all
```

Vérifier :

```text
IPv4
Subnet Mask
Gateway
DHCP Server
DNS Servers
DNS Suffix
```

Puis :

```powershell
Resolve-DnsName dc01.diarabaka.com
Resolve-DnsName dc02.diarabaka.com
nltest /dsgetdc:diarabaka.com
```

Ce test démontre la continuité client dans les limites du scénario.

---

# 04.61 - Vérifier lease et statistics pendant panne DC01

Sur DC02 :

```powershell
Get-DhcpServerv4Lease `
    -ComputerName DC02 `
    -ScopeId 192.168.1.0 |
    Where-Object {
        $_.HostName -like "WIN11*"
    }
```

Puis :

```powershell
Get-DhcpServerv4ScopeStatistics `
    -ComputerName DC02 `
    -ScopeId 192.168.1.0
```

---

# 04.62 - Restaurer DC01

```powershell
Start-Service DHCPServer
```

Vérifier :

```powershell
Get-Service DHCPServer
```

Puis :

```powershell
Get-DhcpServerv4Failover `
    -ComputerName DC01 |
    Format-List
```

Le partenariat doit revenir à un état sain.

---

# 04.63 - Post-Recovery DC01

```powershell
Get-DhcpServerv4Scope `
    -ComputerName DC01

Get-DhcpServerv4Lease `
    -ComputerName DC01 `
    -ScopeId 192.168.1.0

Get-DhcpServerv4Failover `
    -ComputerName DC01
```

Puis :

```powershell
Get-DhcpServerv4ScopeStatistics `
    -ComputerName DC01 `
    -ScopeId 192.168.1.0
```

---

# 04.64 - Controlled Failure : DC02 DHCP

Réaliser seulement après récupération complète de DC01.

Baseline :

```powershell
Get-Service DHCPServer `
    -ComputerName DC01

Get-Service DHCPServer `
    -ComputerName DC02
```

Puis stopper uniquement DC02 DHCP :

```powershell
Invoke-Command `
    -ComputerName DC02 `
    -ScriptBlock {

        Stop-Service DHCPServer
        Get-Service DHCPServer
    }
```

---

# 04.65 - WIN11 pendant panne DC02

```powershell
ipconfig /release
ipconfig /renew
ipconfig /all
```

Puis :

```powershell
Resolve-DnsName dc01.diarabaka.com
Resolve-DnsName dc02.diarabaka.com
nltest /dsgetdc:diarabaka.com
```

---

# 04.66 - Restaurer DC02

```powershell
Invoke-Command `
    -ComputerName DC02 `
    -ScriptBlock {

        Start-Service DHCPServer
        Get-Service DHCPServer
    }
```

Puis :

```powershell
Get-DhcpServerv4Failover `
    -ComputerName DC02 |
    Format-List
```

---

# 04.67 - Post-Failure Regression

Après chaque panne :

```powershell
Get-Service DHCPServer `
    -ComputerName DC01

Get-Service DHCPServer `
    -ComputerName DC02
```

Puis :

```powershell
Get-DhcpServerv4Failover `
    -ComputerName DC01

Get-DhcpServerv4Failover `
    -ComputerName DC02
```

Puis :

```powershell
Get-DhcpServerv4Scope `
    -ComputerName DC01

Get-DhcpServerv4Scope `
    -ComputerName DC02
```

Puis WIN11 :

```powershell
ipconfig /renew
ipconfig /all
```

Ne pas clôturer le test simplement parce qu'un service est revenu à `Running`.

---

# 04.68 - DHCP Event Logs

Lister :

```powershell
Get-WinEvent -ListLog *DHCP* |
    Select-Object `
        LogName,
        IsEnabled,
        RecordCount
```

Examiner notamment les canaux liés aux événements DHCP Server.

Exemples typiques :

```text
Microsoft-Windows-DHCP Server Events/Admin
Microsoft-Windows-DHCP Server Events/Operational
```

Lire les événements récents si présents :

```powershell
Get-WinEvent `
    -LogName "Microsoft-Windows-DHCP Server Events/Admin" `
    -MaxEvents 100 |
    Select-Object `
        TimeCreated,
        Id,
        LevelDisplayName,
        Message
```

Puis Operational :

```powershell
Get-WinEvent `
    -LogName "Microsoft-Windows-DHCP Server Events/Operational" `
    -MaxEvents 100 |
    Select-Object `
        TimeCreated,
        Id,
        LevelDisplayName,
        Message
```

Si le nom exact du journal diffère, utiliser la sortie de `Get-WinEvent -ListLog *DHCP*`.

---

# 04.69 - Troubleshooting Methodology

```text
CLIENT HAS NO IP
       ↓
DHCP ENABLED?
       ↓
LINK / VLAN / NETWORK?
       ↓
DHCP SERVER REACHABLE?
       ↓
DHCP SERVICE?
       ↓
AD AUTHORIZED?
       ↓
CORRECT BINDING?
       ↓
SCOPE ACTIVE?
       ↓
POOL AVAILABLE?
       ↓
EXCLUSIONS?
       ↓
RESERVATIONS?
       ↓
FAILOVER STATE?
       ↓
LEASE?
       ↓
OPTIONS?
       ↓
DNS?
       ↓
DDNS?
       ↓
EVENT LOG?
       ↓
ROOT CAUSE
       ↓
MINIMUM SAFE CORRECTION
       ↓
RETEST
       ↓
REGRESSION
       ↓
EVIDENCE
```

---

# 04.70 - Incident DHCP-INC-001 : APIPA

Symptôme :

```text
169.254.x.x
```

Sur WIN11 :

```powershell
ipconfig /all
```

Sur DHCP :

```powershell
Get-Service DHCPServer
Get-DhcpServerv4Scope
Get-DhcpServerv4Binding
Get-DhcpServerInDC
```

Puis :

```powershell
Get-DhcpServerv4ScopeStatistics `
    -ScopeId 192.168.1.0
```

Et :

```powershell
Get-DhcpServerv4Lease `
    -ScopeId 192.168.1.0
```

---

# 04.71 - Incident DHCP-INC-002 : IP reçue mais pas Internet

Sur WIN11 :

```powershell
ipconfig /all
```

Contrôler :

```text
Option 003
Gateway
```

Sur serveur :

```powershell
Get-DhcpServerv4OptionValue `
    -ScopeId 192.168.1.0
```

Tester :

```powershell
Test-Connection 192.168.1.1
```

Un problème d'accès Internet n'est pas nécessairement un problème DHCP.

---

# 04.72 - Incident DHCP-INC-003 : IP reçue mais AD ne fonctionne pas

Sur WIN11 :

```powershell
ipconfig /all
```

Vérifier :

```text
DNS Servers:
192.168.1.10
192.168.1.11
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

---

# 04.73 - Incident DHCP-INC-004 : Scope épuisé

```powershell
Get-DhcpServerv4ScopeStatistics `
    -ScopeId 192.168.1.0
```

Puis :

```powershell
Get-DhcpServerv4Lease `
    -ScopeId 192.168.1.0
```

Analyser :

```text
Pool size
Used addresses
Free addresses
Expired leases
Reservations
Exclusions
```

Ne pas agrandir arbitrairement le pool.

---

# 04.74 - Incident DHCP-INC-005 : Réservation incorrecte

```powershell
Get-DhcpServerv4Reservation `
    -ScopeId 192.168.1.0
```

Puis :

```powershell
Get-DhcpServerv4Lease `
    -ScopeId 192.168.1.0
```

Comparer :

```text
Reservation ClientId
        vs
Actual ClientId
```

Puis :

```powershell
ipconfig /release
ipconfig /renew
```

---

# 04.75 - Incident DHCP-INC-006 : Failover non Normal

DC01 :

```powershell
Get-DhcpServerv4Failover `
    -ComputerName DC01 |
    Format-List
```

DC02 :

```powershell
Get-DhcpServerv4Failover `
    -ComputerName DC02 |
    Format-List
```

Puis :

```powershell
Get-Service DHCPServer `
    -ComputerName DC01

Get-Service DHCPServer `
    -ComputerName DC02
```

Et :

```powershell
Test-NetConnection DC02
```

Analyser :

```text
Partner reachable?
Service running?
Failover state?
Communication interrupted?
Partner down?
Scope present?
MCLT?
StateSwitchInterval?
```

---

# 04.76 - Incident DHCP-INC-007 : Options différentes DC01/DC02

Comparer :

```powershell
Get-DhcpServerv4OptionValue `
    -ComputerName DC01 `
    -ScopeId 192.168.1.0

Get-DhcpServerv4OptionValue `
    -ComputerName DC02 `
    -ScopeId 192.168.1.0
```

Si DC01 est la source correcte :

```powershell
Invoke-DhcpServerv4FailoverReplication `
    -ComputerName DC01 `
    -ScopeId 192.168.1.0 `
    -Force
```

Puis retester.

Ne pas lancer la réplication sans avoir déterminé le serveur source correct.

---

# 04.77 - Incident DHCP-INC-008 : DDNS ne crée pas les records

Vérifier :

```powershell
Get-DhcpServerv4DnsSetting `
    -ScopeId 192.168.1.0
```

Puis :

```powershell
Get-DhcpServerDnsCredential `
    -ComputerName DC01

Get-DhcpServerDnsCredential `
    -ComputerName DC02
```

Puis DNS :

```powershell
Resolve-DnsName WIN11.diarabaka.com
Resolve-DnsName <WIN11_IP>
```

Puis logs DHCP/DNS.

---

# 04.78 - Incident DHCP-INC-009 : Leases différents sur partenaires

Comparer :

```powershell
Get-DhcpServerv4Lease `
    -ComputerName DC01 `
    -ScopeId 192.168.1.0

Get-DhcpServerv4Lease `
    -ComputerName DC02 `
    -ScopeId 192.168.1.0
```

Puis vérifier :

```powershell
Get-DhcpServerv4Failover `
    -ComputerName DC01
```

Ne pas confondre :

```text
LEASE SYNC ISSUE
```

avec :

```text
CONFIGURATION REPLICATION ISSUE
```

---

# 04.79 - Incident DHCP-INC-010 : Mauvais DNS distribué

Vérifier scope :

```powershell
Get-DhcpServerv4OptionValue `
    -ScopeId 192.168.1.0
```

Puis client :

```powershell
ipconfig /all
```

Si le serveur est correct mais le client conserve une ancienne lease :

```powershell
ipconfig /release
ipconfig /renew
```

Puis retester.

---

# 04.80 - Post-Reboot Validation DC01

Avant reboot :

```powershell
Get-Service DHCPServer
Get-DhcpServerv4Failover
```

Redémarrer uniquement DC01 :

```powershell
Restart-Computer
```

Après retour :

```powershell
Get-Service DHCPServer

Get-DhcpServerv4Scope

Get-DhcpServerv4Failover

Get-DhcpServerv4ScopeStatistics `
    -ScopeId 192.168.1.0
```

Ne pas redémarrer DC02 en même temps.

---

# 04.81 - Post-Reboot Validation DC02

Après validation complète de DC01 :

```powershell
Restart-Computer `
    -ComputerName DC02
```

Après retour :

```powershell
Get-Service DHCPServer `
    -ComputerName DC02

Get-DhcpServerv4Scope `
    -ComputerName DC02

Get-DhcpServerv4Failover `
    -ComputerName DC02
```

---

# 04.82 - Post-Reboot WIN11

```powershell
ipconfig /release
ipconfig /renew
ipconfig /all
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

Objectif :

```text
REBOOT
  ↓
DHCP SERVICE
  ↓
FAILOVER
  ↓
LEASE
  ↓
OPTIONS
  ↓
AD DNS
  ↓
DC LOCATOR
```

---

# 04.83 - Final Audit DC01

```powershell
Get-WindowsFeature DHCP
```

```powershell
Get-Service DHCPServer
```

```powershell
Get-DhcpServerInDC
```

```powershell
Get-DhcpServerv4Binding
```

```powershell
Get-DhcpServerv4Scope
```

```powershell
Get-DhcpServerv4OptionValue `
    -ScopeId 192.168.1.0
```

```powershell
Get-DhcpServerv4DnsSetting `
    -ScopeId 192.168.1.0
```

```powershell
Get-DhcpServerDnsCredential `
    -ComputerName DC01
```

```powershell
Get-DhcpServerv4Reservation `
    -ScopeId 192.168.1.0
```

```powershell
Get-DhcpServerv4Lease `
    -ScopeId 192.168.1.0
```

```powershell
Get-DhcpServerv4ScopeStatistics `
    -ScopeId 192.168.1.0
```

```powershell
Get-DhcpServerv4Failover
```

---

# 04.84 - Final Audit DC02

```powershell
Get-WindowsFeature DHCP `
    -ComputerName DC02
```

```powershell
Get-Service DHCPServer `
    -ComputerName DC02
```

```powershell
Get-DhcpServerv4Binding `
    -ComputerName DC02
```

```powershell
Get-DhcpServerv4Scope `
    -ComputerName DC02
```

```powershell
Get-DhcpServerv4OptionValue `
    -ComputerName DC02 `
    -ScopeId 192.168.1.0
```

```powershell
Get-DhcpServerDnsCredential `
    -ComputerName DC02
```

```powershell
Get-DhcpServerv4Reservation `
    -ComputerName DC02 `
    -ScopeId 192.168.1.0
```

```powershell
Get-DhcpServerv4Failover `
    -ComputerName DC02
```

---

# 04.85 - Final Audit WIN11

```powershell
ipconfig /all
```

Puis :

```powershell
Resolve-DnsName dc01.diarabaka.com
Resolve-DnsName dc02.diarabaka.com
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
Resolve-DnsName WIN11.diarabaka.com
```

---

# 04.90 - Production Consideration

Pour le lab :

```text
DC01 → AD DS + DNS + DHCP
DC02 → AD DS + DNS + DHCP
```

est acceptable pour démontrer :

```text
AD integration
DNS integration
DHCP authorization
Dynamic DNS
DHCP failover
High availability
```

Dans une infrastructure plus importante, on peut séparer :

```text
DC01 / DC02
    ↓
AD DS + DNS

DHCP01 / DHCP02
    ↓
DHCP
```

afin de limiter la concentration de services critiques sur les contrôleurs de domaine.

---

# 04.91 - Architecture finale

```text
                         192.168.1.0/24
                                │
                      Gateway 192.168.1.1
                                │
             ┌──────────────────┴──────────────────┐
             │                                     │
             ▼                                     ▼
           DC01                                  DC02
      192.168.1.10                           192.168.1.11
             │                                     │
        AD + DNS + DHCP                       AD + DNS + DHCP
             │                                     │
             └──────────────────┬──────────────────┘
                                │
                         DHCP FAILOVER
                         LOAD BALANCE
                             50/50
                                │
                        Scope 192.168.1.0
                                │
                   192.168.1.100 → 200
                                │
                  ┌─────────────┴─────────────┐
                  │                           │
                  ▼                           ▼
                WIN11                       Clients
                  │
                  ├── IPv4
                  ├── Gateway
                  ├── DNS DC01
                  ├── DNS DC02
                  ├── diarabaka.com
                  └── DHCP Lease
```
