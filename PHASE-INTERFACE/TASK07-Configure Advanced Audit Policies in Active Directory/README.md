# Configure-Advanced-Audit-Policies-in-Active-Directory

```
Account Logon
├── Credential Validation → Success, Failure

Account Management
├── User Account Management → Success, Failure
├── Security Group Management → Success, Failure
└── Computer Account Management → Success

Logon/Logoff
├── Logon → Success, Failure
├── Logoff → Success
├── Special Logon → Success
└── Other Logon/Logoff Events → Success, Failure

Policy Change
├── Audit Policy Change → Success, Failure
└── Authentication Policy Change → Success

Privilege Use
└── Sensitive Privilege Use → Success, Failure

System
├── Security State Change → Success
├── Security System Extension → Success, Failure
└── System Integrity → Success, Failure
```

Pour les **Domain Controllers**, tu peux également ajouter :

```
DS Access
├── Directory Service Access → Success, Failure
└── Directory Service Changes → Success
```

Et pour la surveillance des processus :

```
Detailed Tracking
└── Process Creation → Success
```

![Audit Policies](./assets/01.png)
![Audit Policies](./assets/02.png)
![Audit Policies](./assets/03.png)
![Audit Policies](./assets/04.png)
![Audit Policies](./assets/05.png)
![Audit Policies](./assets/06.png)
![Audit Policies](./assets/07.png)
![Audit Policies](./assets/08.png)
![Audit Policies](./assets/09.png)
![Audit Policies](./assets/10.png)
![Audit Policies](./assets/11.png)
![Audit Policies](./assets/12.png)
![Audit Policies](./assets/13.png)
![Audit Policies](./assets/14.png)
![Audit Policies](./assets/15.png)
![Audit Policies](./assets/16.png)
![Audit Policies](./assets/17.png)
![Audit Policies](./assets/18.png)
![Audit Policies](./assets/19.png)
![Audit Policies](./assets/20.png)
![Audit Policies](./assets/21.png)
![Audit Policies](./assets/22.png)
![Audit Policies](./assets/23.png)
![Audit Policies](./assets/24.png)
![Audit Policies](./assets/25.png)
![Audit Policies](./assets/26.png)
![Audit Policies](./assets/27.png)
