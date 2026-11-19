# How to Setup Proxmox on a Laptop

- ignore lid close

```sh
nano /etc/systemd/logind.conf
```

- add line:

```sh
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
```

```sh
systemctl restart systemd-logind
systemctl status systemd-logind
```

- turn off screen to prevent screenburn

```sh
nano /etc/default/grub
```

- Find this line: "GRUB_CMDLINE_LINUX" line GRUB_CMDLINE_LINUX_DEFAULT="quiet"
- Add : GRUB_CMDLINE_LINUX_DEFAULT="quiet consoleblank=300"

```sh
update-grub
reboot
```

```sh
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
```

---

```sh
grep -i virtio /boot/config-$(uname -r)
apt update 
apt-get install qemu-guest-agent -y
systemctl start qemu-guest-agent
systemctl enable qemu-guest-agent
```
