# HA in Proxmox and Setup QDevice "External Vote"

## SUR LA MACHINE QDEVICE (192.168.129.103)

Installation des paquets QDevice

```sh
apt update
apt install -y corosync-qnetd openssh-server
```

Activer et démarrer qnetd

```sh
systemctl enable corosync-qnetd
systemctl start corosync-qnetd
```

Vérifier

```sh
systemctl status corosync-qnetd
```

## SUR CHAQUE NODE PROXMOX (pve01 & pve02)

Installer les paquets nécessaires

```sh
apt update
apt install -y corosync-qdevice
which corosync-qdevice-net-certutil
systemctl start pve-cluster
systemctl start corosync
```

(Sur pve01 uniquement)

```sh
pvecm create mycluster
```

Puis sur pve02 :

```sh
pvecm add 192.168.129.101
```

## AJOUT DU QDEVICE (SUR pve01 UNIQUEMENT)

```sh
root@pve01:~# pvecm qdevice setup 192.168.129.103
root@pve01:~# pvecm status
```

![HA in Proxmox](./assets/01-HA-in-Proxmox%20.png)
![HA in Proxmox](./assets/02-HA-in-Proxmox%20.png)
![HA in Proxmox](./assets/03-HA-in-Proxmox%20.png)
![HA in Proxmox](./assets/04-HA-in-Proxmox%20.png)
![HA in Proxmox](./assets/05-HA-in-Proxmox%20.png)
![HA in Proxmox](./assets/06-HA-in-Proxmox%20.png)
![HA in Proxmox](./assets/07-HA-in-Proxmox%20.png)
![HA in Proxmox](./assets/08-HA-in-Proxmox%20.png)
![HA in Proxmox](./assets/09-HA-in-Proxmox%20.png)
![HA in Proxmox](./assets/10-HA-in-Proxmox%20.png)
![HA in Proxmox](./assets/11-HA-in-Proxmox%20.png)
![HA in Proxmox](./assets/12-HA-in-Proxmox%20.png)
![HA in Proxmox](./assets/13-HA-in-Proxmox%20.png)
![HA in Proxmox](./assets/14-HA-in-Proxmox%20.png)
![HA in Proxmox](./assets/15-HA-in-Proxmox%20.png)
![HA in Proxmox](./assets/16-HA-in-Proxmox%20.png)
![HA in Proxmox](./assets/17-HA-in-Proxmox%20.png)
![HA in Proxmox](./assets/18-HA-in-Proxmox%20.png)
![HA in Proxmox](./assets/19-HA-in-Proxmox%20.png)
![HA in Proxmox](./assets/20-HA-in-Proxmox%20.png)
![HA in Proxmox](./assets/21-HA-in-Proxmox%20.png)
