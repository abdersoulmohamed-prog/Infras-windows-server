# DHCP Failover

![DHCP Failover](./assets/01.png)
![DHCP Failover](./assets/02.png)
![DHCP Failover](./assets/03.png)
![DHCP Failover](./assets/04.png)
![DHCP Failover](./assets/05.png)
![DHCP Failover](./assets/06.png)
![DHCP Failover](./assets/07.png)
![DHCP Failover](./assets/08.png)
![DHCP Failover](./assets/09.png)
![DHCP Failover](./assets/10.png)

```sh
Get-DhcpServerv4Failover |
Format-List Name,PartnerServer,Mode,LoadBalancePercent,State,ScopeId,EnableAuth


Get-DhcpServerv4Scope |
Format-Table ScopeId,Name,StartRange,EndRange,State
```
