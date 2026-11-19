# Install DNS Server & DHCP

```sh
# Vérifier les serveurs DNS de la zone
Get-DnsServerResourceRecord -ZoneName "thierno.lan" -RRType NS

# Tester la résolution de noms
nslookup dc01.thierno.lan
nslookup dc02.thierno.lan

# Vérifier la santé du DNS Active Directory
dcdiag /test:dns
```

![DNS](./assets/01.png)
![DNS](./assets/02.png)
![DNS](./assets/03.png)
![DNS](./assets/04.png)
![DNS](./assets/05.png)
![DNS](./assets/06.png)
![DNS](./assets/07.png)
![DNS](./assets/08.png)
![DNS](./assets/09.png)
![DNS](./assets/10.png)
![DNS](./assets/11.png)
![DNS](./assets/12.png)
![DNS](./assets/13.png)
![DNS](./assets/14.png)
![DNS](./assets/15.png)
![DNS](./assets/16.png)
![DNS](./assets/17.png)
![DNS](./assets/18.png)
![DNS](./assets/19.png)
![DNS](./assets/20.png)
![DNS](./assets/21.png)
![DNS](./assets/22.png)
![DNS](./assets/23.png)
![DNS](./assets/24.png)
![DNS](./assets/25.png)
