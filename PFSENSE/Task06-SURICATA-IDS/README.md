# Suricata (IDS/IPS) + Snort (with Oinkcode rules) + Watchdog / monitoring + SIEM

![pfsense](/Task06-SURICATA-IDS/assets/01.png)

![pfsense](/Task06-SURICATA-IDS/assets/02.png)

![pfsense](/Task06-SURICATA-IDS/assets/02-1.png)

![pfsense](/Task06-SURICATA-IDS/assets/03.png)

![pfsense](/Task06-SURICATA-IDS/assets/04.png)

![pfsense](/Task06-SURICATA-IDS/assets/05.png)

![pfsense](/Task06-SURICATA-IDS/assets/06.png)

![pfsense](/Task06-SURICATA-IDS/assets/07.png)

![pfsense](/Task06-SURICATA-IDS/assets/08.png)

![pfsense](/Task06-SURICATA-IDS/assets/08-1.png)

![pfsense](/Task06-SURICATA-IDS/assets/09.png)

![pfsense](/Task06-SURICATA-IDS/assets/10.png)

![pfsense](/Task06-SURICATA-IDS/assets/11.png)

```sh
Services > Suricata > Interfaces > Add
Interface = LAN
Enable = ✔️
```

```sh
Services > Suricata > Interfaces > LAN > Variables

HOME_NET = 192.168.1.0/24
EXTERNAL_NET = !192.168.1.0/24
```

```sh
Services > Suricata > LAN > Logs View > Alerts
```

```sh
Services > Suricata > LAN > Rules > Custom Rules
```

```sh
# LAN

# SSH brute force detection
alert tcp any any -> $HOME_NET 22 (
    msg:"SOC LAB SSH Brute Force";
    flow:to_server;
    threshold:type threshold, track by_src, count 5, seconds 60;
    sid:900001;
    rev:1;
)

# Reverse shell detection (outgoing)
alert tcp $HOME_NET any -> any 4444 (
    msg:"SOC LAB Reverse Shell";
    flow:to_server;
    sid:900002;
    rev:1;
)

# RDP attempt detection
alert tcp any any -> $HOME_NET 3389 (
    msg:"SOC LAB RDP Attempt";
    flags:S;
    flow:stateless;
    sid:900003;
    rev:1;
)

# SSH attempt detection
alert tcp any any -> $HOME_NET 22 (
    msg:"SOC LAB SSH Attempt";
    flags:S;
    flow:stateless;
    sid:900004;
    rev:1;
)
```

```sh
# WAN (OK)
alert icmp any any -> $HOME_NET any (
    msg:"WAN ICMP Ping Detected";
    itype:8;
    threshold:type limit, track by_src, count 5, seconds 60;
    sid:910001;
)
```

```sh
nmap -sS -Pn 192.168.1.20
hydra -l root -P passwords.txt ssh://192.168.1.40
nmap -p 22,3389 192.168.1.20
sudo nmap -sS -T4 -Pn 192.168.1.0/24 --script vuln
hydra -l root -P pass.txt ssh://192.168.1.40
```

```sh
Services > Suricata > Alerts

#SOC LAB SSH Attempt
#SOC LAB SSH Brute Force
#SOC LAB RDP Attemp
```

```sh
Services > Suricata > Suppress

##############################################
# Suricata Suppress Rules - SOC Lab LAN
# Suppression des alertes "bruit" du lab
# Source : Kali Linux 192.168.1.50
##############################################

# Bruit Nmap / scan
suppress gen_id 1, sig_id 2260000, track by_src, ip 192.168.1.50

# Ping pfSense (tests lab)
suppress gen_id 1, sig_id 100001, track by_src, ip 192.168.1.50

# SSH brute force (tests Hydra)
suppress gen_id 1, sig_id 900001, track by_src, ip 192.168.1.50

# Reverse shell (tests lab)
suppress gen_id 1, sig_id 900002, track by_src, ip 192.168.1.50
```

```sh
index=pfsense_suricata
| stats count by alert.signature, src_ip, dest_ip
| sort -count
```

| Variable             | Valeur conseillée           |
| -------------------- | --------------------------- |
| DNS_SERVERS          | `192.168.1.1`               |
| SSH_SERVERS          | `192.168.1.10,192.168.1.12` |
| HTTP_SERVERS         | `192.168.1.1,192.168.1.40`  |
| SQL_SERVERS          | `192.168.1.30`              |
| SMTP_SERVERS         | _(laisser vide)_            |
| FTP_SERVERS          | _(laisser vide)_            |
| TELNET_SERVERS       | _(laisser vide)_            |
| MODBUS / DNP3 / ENIP | _(laisser vide)_            |

```sh
SSH_PORTS = 22
HTTP_PORTS = 80
FTP_PORTS = 21
```

![pfsense](/Task06-SURICATA-IDS/assets/12.png)

![pfsense](/Task06-SURICATA-IDS/assets/13.png)

![pfsense](/Task06-SURICATA-IDS/assets/14.png)

![pfsense](/Task06-SURICATA-IDS/assets/15.png)

![pfsense](/Task06-SURICATA-IDS/assets/16.png)

![pfsense](/Task06-SURICATA-IDS/assets/17.png)

## Downloads Snort

- [Official rules download](https://snort.org/downloads#rules)

![pfsense](/Task06-SURICATA-IDS/assets/18.png)

![pfsense](/Task06-SURICATA-IDS/assets/19.png)

![pfsense](/Task06-SURICATA-IDS/assets/20.png)

![pfsense](/Task06-SURICATA-IDS/assets/21.png)

![pfsense](/Task06-SURICATA-IDS/assets/22.png)

![pfsense](/Task06-SURICATA-IDS/assets/23.png)

![pfsense](/Task06-SURICATA-IDS/assets/24.png)

![pfsense](/Task06-SURICATA-IDS/assets/25.png)

![pfsense](/Task06-SURICATA-IDS/assets/26.png)

![pfsense](/Task06-SURICATA-IDS/assets/27.png)

![pfsense](/Task06-SURICATA-IDS/assets/28.png)

![pfsense](/Task06-SURICATA-IDS/assets/29.png)

![pfsense](/Task06-SURICATA-IDS/assets/30.png)

![pfsense](/Task06-SURICATA-IDS/assets/31.png)

![pfsense](/Task06-SURICATA-IDS/assets/32.png)

```sh
[default]
host = 192.168.1.1

[monitor:///var/log/filter.log]
_TCP_ROUTING = *
disabled = false
index = pfsense_firewall
sourcetype = pfsense:firewall

[monitor:///var/log/suricata/eve.json]
_TCP_ROUTING = *
disabled = false
index = pfsense_suricata
sourcetype = suricata
```

```sh
index=pfsense_firewall action=block
index=pfsense_suricata event_type=alert

index=pfsense_suricata
| stats count by event_type

| tstats count from datamodel=Network_Traffic

(
 index=pfsense_suricata event_type=alert
)
OR
(
 index=pfsense_firewall action=block
)
| stats count by src_ip dest_ip dest_port
```

| Panel                          | Objectif                                | SPL                                                                                              |                                                  |              |
| ------------------------------ | --------------------------------------- | ------------------------------------------------------------------------------------------------ | ------------------------------------------------ | ------------ |
| **Firewall Blocks**            | Voir toutes les IP bloquées par pfSense | `index=pfsense_firewall action=block                                                             | stats count by src_ip dest_ip dest_port`         |              |
| **Suricata Alerts**            | Voir toutes les alertes IDS             | `index=pfsense_suricata event_type=alert                                                         | stats count by alert.signature, src_ip, dest_ip` |              |
| **SSH Brute Force**            | Filtrer tentatives SSH lab              | `index=pfsense_suricata event_type=alert alert.signature="SOC LAB SSH Brute Force"               | stats count by src_ip dest_ip`                   |              |
| **RDP Attempts**               | Filtrer tentatives RDP lab              | `index=pfsense_suricata event_type=alert alert.signature="SOC LAB RDP Attempt"                   | stats count by src_ip dest_ip`                   |              |
| **Reverse Shells**             | Filtrer tentatives reverse shell lab    | `index=pfsense_suricata event_type=alert alert.signature="SOC LAB Reverse Shell"                 | stats count by src_ip dest_ip`                   |              |
| **Ping / ICMP**                | Filtrer pings vers pfSense              | `index=pfsense_suricata event_type=alert alert.signature="[ALERT] ICMP Ping detected to pfSense" | stats count by src_ip`                           |              |
| **Top Talkers / Destinations** | Résumé des IP les plus actives          | `(index=pfsense_suricata event_type=alert) OR (index=pfsense_firewall action=block)              | stats count by src_ip dest_ip dest_port          | sort -count` |
