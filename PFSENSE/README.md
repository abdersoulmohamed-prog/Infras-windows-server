# PFSENSE Project

[![pfSense](https://img.shields.io/badge/pfSense-Firewall-blue)](https://www.pfsense.org/)
[![Status](https://img.shields.io/badge/Status-Learning-green)]()
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)]()

A hands-on project showcasing **pfSense firewall** installation, configuration, and security features.
Covers LAN/DMZ setup, NAT, VPN, IDS, and proxy filtering.

## Objectives

This project aims to provide hands-on experience in configuring and securing a pfSense firewall.
Key goals include:

- Understanding LAN/DMZ segmentation.
- Configuring NAT and firewall rules.
- Implementing secure remote access with OpenVPN.
- Detecting intrusions using Suricata IDS.
- Filtering web traffic with Squid and SquidGuard.

---

## Network Topology

```text
                   ┌───────────────┐
                   │     WAN       │
                   │   Internet    │
                   └───────┬───────┘
                           │
                    ┌──────▼──────┐
                    │   pfSense   │
                    │ Firewall/   │
                    │ VPN / IDS   │
                    └──────┬──────┘
             ┌─────────────┼─────────────┐
             │             │             │
      ┌──────▼──────┐  ┌─────▼──────┐  ┌────▼─────┐
      │    LAN      │  │    DMZ      │  │ OpenVPN  │
      │ Internal PC │  │ Web Server  │  │ Remote   │
      │ Services:   │  │ Services:   │  │ Clients  │
      │ HTTP/FTP    │  │ HTTP/HTTPS  │  │ VPN      │
      └─────────────┘  └─────────────┘  └─────────┘
```

---

## Tasks

- `Task01-Installation` -> pfSense installation & basic setup
- `Task02-LAN-&-DMZ` -> LAN/DMZ configuration
- `Task03-SNAT-&-DNAT` -> Source & Destination NAT
- `Task04-OPENVPN` -> OpenVPN server setup
- `Task05-RADIUS-OPENVPN` -> RADIUS authentication for OpenVPN
- `Task06-SURICATA-IDS` -> Suricata intrusion detection
- `Task07-Squid-Transparent-Proxy` -> Squid proxy configuration
- `Task08-SQUID-GUARD-BLACKLIST` -> Web filtering with SquidGuard

---

## Quick Start

1. Download [pfSense ISO](https://www.pfsense.org/download/).
2. Create a VM (VirtualBox / VMware / Proxmox).
3. Install pfSense.

---

## Usage

- Each task folder contains step-by-step instructions and screenshots.

---

## References

- [pfSense Docs](https://docs.netgate.com/pfsense/en/latest/)
- [Suricata IDS](https://suricata.io/)
- [Squid Proxy](http://www.squid-cache.org/)

---

## Author

**thierno953** - System & Network Administration | Cybersecurity Enthusiast

---

# pfSense + VLANs + DHCP Relay vers Windows Server

## VLANs recommandés

| VLAN | Usage          | Description / Notes              |
| ---- | -------------- | -------------------------------- |
| 10   | Administration | Secrétariat / direction          |
| 20   | Classe 1       | 25 PC élèves                     |
| 30   | Classe 2       | 25 PC élèves                     |
| 40   | Serveurs       | AD, DHCP, File, GLPI, Mail, etc. |
| 50   | Gamer Room 1   | Salle de gamers 1                |
| 51   | Gamer Room 2   | Salle de gamers 2                |
| 99   | Management     | Switch, APs, pfSense             |

## Rôle de pfSense

- **VLAN + Isolation** :
  - Chaque salle de gamers est isolée du reste du réseau pour éviter les conflits ou surcharges.
  - Les VLAN des classes et des gamers n’ont pas d’accès direct aux serveurs (sauf règles spécifiques si nécessaire).

- **Firewall + QoS** :
  - Tu peux limiter la bande passante pour les VLAN gamers si besoin.
  - Prioriser le trafic du secrétariat ou des serveurs.

- **DHCP Relay** :
  - Les deux salles de gamers reçoivent leurs IP via Windows Server DHCP.
  - Chaque VLAN a ses propres plages d’IP.

## Windows Server DHCP

- Distribue les IP à tous les VLANs (classes, gamers, secrétariat).
- Chaque VLAN peut avoir :
  - Plage IP spécifique (ex : Gamer 1 → 192.168.60.0/24, Gamer 2 → 192.168.61.0/24)
  - Gateway = pfSense VLAN interface
  - DNS interne = Windows Server

## Flux réseau type

```sh
                              Internet
                                 |
               -------------------------------------
               |                                   |
     [Firewall / Routeur principal]                |
               |                                   |
               |                                   |
       -----------------------------------------
       |                 VLAN 99                |
       |           Management (pfSense)        |
       |                                       |
       |                                       |
       |       ----------------------------     |
       |       |        VLAN 40             |   |
       |       |       Serveurs             |   |
       |       |  (AD, DHCP, File, GLPI,   |   |
       |       |   Mail, Backup)           |   |
       |       ----------------------------     |
       |                                       |
       |                                       |
       |       ----------------------------     |
       |       |       VLAN 10              |   |
       |       |      Administration       |   |
       |       |  (Secrétariat, Direction) |   |
       |       ----------------------------     |
       |                                       |
       |       ----------------------------     |
       |       |       VLAN 20              |   |
       |       |       Classe 1             |   |
       |       |  (25 PC élèves)            |   |
       |       ----------------------------     |
       |                                       |
       |       ----------------------------     |
       |       |       VLAN 30              |   |
       |       |       Classe 2             |   |
       |       |  (25 PC élèves)            |   |
       |       ----------------------------     |
       |                                       |
       |       ----------------------------     |
       |       |       VLAN 50              |   |
       |       |       Gamer Room 1         |   |
       |       |  (Salle de gamers)         |   |
       |       ----------------------------     |
       |                                       |
       |       ----------------------------     |
       |       |       VLAN 51              |   |
       |       |       Gamer Room 2         |   |
       |       |  (Salle de gamers)         |   |
       |       ----------------------------     |
       |                                       |
       |                                       |
       -----------------------------------------
```
