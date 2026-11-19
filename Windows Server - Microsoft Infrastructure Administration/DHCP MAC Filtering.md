# DHCP MAC Filtering

```txt
Élément	            |Résultat
------------------------------------------
DHCP	            |DC01 + DC02
------------------------------------------
Réseau	            |192.168.10.0/24
------------------------------------------
Plage DHCP	        |192.168.10.20–250
------------------------------------------
Failover	        |LoadBalance 50/50
------------------------------------------
État	            |Normal
------------------------------------------
Adresse MAC WIN11	|00-0C-29-D7-CF-59
```

**Objectif** : autoriser WIN11 à obtenir une adresse DHCP et refuser les nouvelles demandes des ordinateurs inconnus.

```txt
                                DC01 + DC02
                        DHCP Failover 50/50 · Filtrage MAC

WIN11 autorisé: Reçoit une IPv4 DHCP             PC inconnu: Pas de bail DHCP
```

Le filtrage MAC est une fonction intégrée au serveur DHCP Windows. Il s'applique aux demandes de bail IPv4, [pas aux connexions des utilisateurs Windows](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-r2-and-2012/dn268503%28v%3Dws.11%29).

---

## 2. Étape 1 - Vérifier le réseau VMware

Dans VMware Workstation :

1. Ouvre **Edit → Virtual Network Editor**.
2. Clique sur **Change Settings** si nécessaire.
3. Sélectionne le VMnet utilisé par DC01, DC02 et WIN11.
4. Vérifie que les trois machines partagent bien le même réseau virtuel.
5. Pour un réseau de laboratoire isolé, désactive **Use local DHCP service to distribute IP address to VMs**.

**Important** : il ne faut pas que le DHCP de VMware attribue lui aussi des adresses aux clients. Il pourrait contourner ton test des filtres Windows DHCP. Ne modifie pas un VMnet partagé avec d'autres machines importantes.
Support Portal

---

## 3. Étape 2 - Vérifier tes deux serveurs DHCP

Sur DC01, ouvre PowerShell en administrateur :

```PowerShell
Get-DhcpServerv4Scope -ComputerName DC01

Get-DhcpServerv4Failover -ComputerName DC01

Get-DhcpServerv4FilterList -ComputerName DC01
Get-DhcpServerv4FilterList -ComputerName DC02
```

Tu dois retrouver ton étendue DHCP, le partenariat Load Balance 50/50, et l'état actuel des filtres MAC sur chaque serveur.

---

## 4. Étape 3 - Récupérer l'adresse MAC de WIN11

Sur WIN11 :

```PowerShell
Get-NetAdapter |
    Select-Object Name, MacAddress, Status
```

Exemple fictif :

```
Name      MacAddress         Status
----      ----------         ------
Ethernet  00-0C-29-AA-BB-CC  Up
```

Copie l'adresse MAC réelle de ta carte Ethernet VMware.

Tu peux également la retrouver dans **VM → Settings → Network Adapter → Advanced**.

---

## 5. Étape 4 - Autoriser WIN11 sur les deux DHCP

Sur DC01, remplace l'adresse MAC d'exemple par celle de ton WIN11 :

```PowerShell
$mac = "00-0C-29-AA-BB-CC"
```

Ajoute WIN11 dans la liste des machines autorisées sur DC01 :

```PowerShell
Add-DhcpServerv4Filter `
    -ComputerName DC01 `
    -List Allow `
    -MacAddress $mac `
    -Description "WIN11 autorise"
```

Fais la même chose sur DC02 :

```PowerShell
Add-DhcpServerv4Filter `
    -ComputerName DC02 `
    -List Allow `
    -MacAddress $mac `
    -Description "WIN11 autorise"
```

Si l'adresse existe déjà dans la liste, ne l'ajoute pas une deuxième fois.

Vérifie :

```PowerShell
Get-DhcpServerv4Filter -ComputerName DC01 -List Allow

Get-DhcpServerv4Filter -ComputerName DC02 -List Allow
```

**Important** : ajoute également les adresses MAC de toutes les autres machines DHCP qui doivent conserver un bail. Les machines en IP statique ne dépendent pas de l'attribution DHCP.

---

## 6. Étape 5 - Activer le filtrage

Une fois les listes vérifiées sur les deux serveurs :

```PowerShell
Set-DhcpServerv4FilterList `
    -ComputerName DC01 -Allow $true
```

```PowerShell
Set-DhcpServerv4FilterList `
    -ComputerName DC02 -Allow $true
```

Vérifie :

```PowerShell
Get-DhcpServerv4FilterList -ComputerName DC01

Get-DhcpServerv4FilterList -ComputerName DC02
```

Le filtrage Allow doit être activé sur les deux serveurs. Cette configuration est prise en charge par Windows Server 2025.
[Microsoft L](https://learn.microsoft.com/en-us/powershell/module/dhcpserver/set-dhcpserverv4filterlist?view=windowsserver2025-ps)

---

## 7. Étape 6 - Tester WIN11 autorisé

Sur WIN11, depuis la console VMware :

```PowerShell
ipconfig /release
ipconfig /renew
ipconfig /all
```

Vérifie que WIN11 obtient une adresse IPv4 dans ton étendue DHCP et que le serveur qui a répondu est DC01 ou DC02.

**Résultat attendu : WIN11 reçoit une adresse DHCP.**

---

## 8. Étape 7 - Tester un ordinateur inconnu

Dans VMware Workstation :

1. Crée une deuxième machine virtuelle de test, WIN11-TEST, avec une nouvelle adresse MAC.
2. Connecte-la au même VMnet que WIN11.
3. Configure sa carte réseau en DHCP.
4. Ne l'ajoute à aucune liste Allow.

Sur WIN11-TEST :

```PowerShell
ipconfig /release
ipconfig /renew
ipconfig /all
```

**Résultat attendu** : aucun bail IPv4 ne doit être fourni par DC01 ni DC02. Windows peut afficher une adresse automatique 169.254.x.x si aucune autre configuration réseau n'intervient.

Si WIN11-TEST reçoit quand même une adresse, regarde le champ DHCP Server. Vérifie qu'aucun DHCP VMware ou autre serveur ne répond et que les filtres sont activés sur les deux DC.

Un bail déjà existant peut fausser le test : utilise une machine de test sans bail antérieur.

---

## 9. Étape 8 - Vérifier le DHCP Failover

Sur DC01 :

```PowerShell
Get-DhcpServerv4Failover -ComputerName DC01
```

Après avoir confirmé les deux listes de filtrage, tu peux arrêter uniquement le service DHCP sur DC01, puis renouveler le bail de WIN11 depuis VMware :

```PowerShell
Stop-Service DHCPServer
```

Depuis WIN11 :

```PowerShell
ipconfig /release
ipconfig /renew
ipconfig /all
```

Selon l'état de la relation et les délais de failover, DC02 doit pouvoir continuer à fournir le service aux machines autorisées.

Puis sur DC01 :

```PowerShell
Start-Service DHCPServer
```

Vérifie que la relation DHCP revient à l'état Normal. [Microsoft Learn](https://learn.microsoft.com/en-gb/windows-server/networking/technologies/dhcp/dhcp-failover)

Pour annuler le filtrage en cas de problème :

```PowerShell
Set-DhcpServerv4FilterList -ComputerName DC01 -Allow $false
Set-DhcpServerv4FilterList -ComputerName DC02 -Allow $false
```

**Limite importante** : une machine non autorisée pourrait toujours configurer une adresse IP statique. Le filtrage MAC du DHCP n'est donc pas un véritable contrôle d'accès au réseau.
