# GPO C - Sécuriser les postes Windows 11

## Objectif de la GPO

```txt
Restriction	              |Résultat attendu
--------------------------|-----------------------------------------------
C1 - Stockage USB	      |Accès aux supports amovibles refusé
--------------------------|-----------------------------------------------
C2 - RDP	              |Connexions Bureau à distance bloquées
--------------------------|-----------------------------------------------
C3 - Paramètres Windows	  |Panneau de configuration et Paramètres bloqués
```

Nom de la GPO : `GPO-WS-03-Security-Restrictions`

---

## Étape 1 - Vérifier l'environnement

Sur DC01, exécute :

```PowerShell
Get-ADComputer WIN11 |
    Select-Object Name, DistinguishedName
```

WIN11 doit se trouver dans ton OU de test :

```txt
OU=Workstations-Pilot
```

Sur WIN11, vérifie que `user-test01`, autorisé par la GPO B, peut toujours se connecter et que l'administrateur local Windows LAPS reste accessible.

---

## Étape 2 - Créer la GPO C

Sur DC01 :

1. Ouvre gpmc.msc.
2. Développe Forest > Domains > diarabaka.com.
3. Clic droit sur Group Policy Objects.
4. Clique sur New.
5. Saisis :

```txt
GPO-WS-03-Security-Restrictions
```

---

## Étape 3 - C1 : bloquer le stockage USB

Dans l'éditeur GPO, ouvre :

```txt
Computer Configuration
 └── Policies
     └── Administrative Templates
         └── System
             └── Removable Storage Access
```

Double-clique sur :

**All Removable Storage classes: Deny all access**

Configure : `Enabled`

Cette stratégie bloque l'accès aux catégories de stockage amovible, notamment les clés USB. Elle peut aussi bloquer d'autres supports comme les CD/DVD, mais pas les claviers et souris USB ordinaires.
[Microsoft Learn](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-admx-removablestorage)

Si ton objectif est seulement de bloquer les clés USB, tu peux plutôt activer `Removable Disks: Deny read access et Removable Disks: Deny write access`, qui sont plus ciblés.
[Microsoft Learn](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-admx-removablestorage)

**Connecter la clé USB à WIN11**

1. Démarre WIN11 dans VMware.
2. Branche une clé USB physique à ton ordinateur.
3. Dans la barre de menus VMware, clique sur VM.
4. Sélectionne Removable Devices.
5. Trouve ta clé USB (par exemple Kingston ou SanDisk).
6. Clique sur Connect (Disconnect from Host).

**VMware Workstation**

> VM > Removable Devices > Kingston / SanDisk USB > Connect (Disconnect from Host)

La clé est alors transférée de ton ordinateur physique vers WIN11.

```PowerShell
Get-Disk | Select Number,FriendlyName,BusType
```

```PowerShell
gpupdate /force
```

```PowerShell
gpresult /r /scope computer
```

`GPO-WS-03-Security-Restrictions`

Ouvre une session avec `DIARABAKA\user-test01`.

Essaie ensuite d'ouvrir le lecteur USB, par exemple `E:`. Remplace la lettre si nécessaire.

```PowerShell
Get-ChildItem E:\ -ErrorAction Stop
```

Avec `Removable Disks: Deny read access = Enabled`, le résultat attendu est un **refus d'accès**.

Pour vérifier l'écriture séparément, essaie de créer un fichier de test :

```PowerShell
New-Item E:\GPO-Test.txt -ItemType File -ErrorAction Stop
```

Avec `Removable Disks: Deny write access = Enabled`, la création doit être refusée.

N'utilise qu'une clé de test contenant des données non importantes.

---

## Étape 4 - C2 : bloquer le Bureau à distance

Toujours dans la même GPO, accède à :

```txt
Computer Configuration
 └── Policies
     └── Administrative Templates
         └── Windows Components
             └── Remote Desktop Services
                 └── Remote Desktop Session Host
                     └── Connections
```

Double-clique sur :

Allow users to connect remotely by using Remote Desktop Services

Configure : `Disabled`

Ce paramètre empêche les nouvelles connexions RDP entrantes vers WIN11.[Microsoft Learn](https://learn.microsoft.com/en-gb/windows/client-management/mdm/policy-csp-remotedesktopservices?WT.mc_id=Portal-Microsoft_Intune_Workflows)

---

## Étape 5 - C3 : bloquer les Paramètres Windows

Attention : il s'agit cette fois d'une **stratégie utilisateur**, contrairement aux deux précédentes.

Dans l'éditeur de la même GPO :

```txt
User Configuration
 └── Policies
     └── Administrative Templates
         └── Control Panel
```

Double-clique sur :

**Prohibit access to Control Panel and PC settings**

Configure : `Enabled`

Cette politique interdit l'ouverture du Panneau de configuration et de l'application Paramètres Windows.[Microsoft Learn](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-admx-controlpanel)

---

## Étape 6 - Activer le Loopback Processing

Cette étape est importante.

Puisque ta GPO sera liée à l'OU du poste WIN11, nous devons permettre l'application de ses paramètres utilisateur aux personnes qui se connectent à ce poste.

Dans la même GPO :

```txt
Computer Configuration
 └── Policies
     └── Administrative Templates
         └── System
             └── Group Policy
```

Double-clique sur :

Configure user Group Policy loopback processing mode

Configure : `Enabled` **Mode : Merge**

Le mode Merge combine les GPO habituelles de l'utilisateur et celles du poste. Les paramètres utilisateur de la GPO du poste sont alors prioritaires en cas de conflit.[Microsoft Learn](https://learn.microsoft.com/en-gb/windows-server/identity/ad-ds/manage/group-policy/group-policy-processing)

---

## Étape 7 - Lier la GPO à WIN11

Retourne dans `gpmc.msc`.

Dans ton domaine :

1. Va dans `OU=Diarabaka > OU=Workstations > OU=Workstations-Pilot`.
2. Clic droit sur l'OU pilote.
3. Sélectionne **Link an Existing GPO**.
4. Choisis `GPO-WS-03-Security-Restrictions`.
5. Clique sur OK.

Tu dois maintenant obtenir cette structure :

```txt
OU=Workstations-Pilot

WIN11

GPO-WS-01-Admin-Restriction

GPO-WS-02-User-Logon

GPO-WS-03-Security-Restrictions
```

---

## Étape 8 - Appliquer les stratégies

Sur WIN11, ouvre PowerShell en administrateur depuis la console VMware.

```PowerShell
gpupdate /force
```

Vérifie les stratégies appliquées :

```PowerShell
gpresult /r /scope computer
```

Tu dois retrouver les trois GPO :

```
GPO-WS-01-Admin-Restriction
GPO-WS-02-User-Logon
GPO-WS-03-Security-Restrictions
```

Redémarre WIN11, puis ouvre une session avec :

```txt
DIARABAKA\user-test01
```

Dans cette session, vérifie les GPO utilisateur :

```PowerShell
gpresult /r /scope user
```

Le rapport doit confirmer la politique utilisateur attendue.

Tu peux également générer un rapport HTML :

```PowerShell
gpresult /h C:\Users\Public\GPO-C.html /f
```

---

## Étape 9 - Tester les trois restrictions

### Test 1 - Stockage USB

Depuis VMware, connecte une clé USB de test à WIN11.

Avant d'appliquer la GPO, il est préférable d'avoir vérifié que la clé était accessible normalement.

Après application :

- Ouvre l'Explorateur Windows.
- Essaie d'ouvrir la clé USB.
- Vérifie que son contenu est inaccessible.

`Résultat attendu : accès au stockage amovible refusé.`

### Test 2 - RDP

Depuis une autre machine du laboratoire, essaie de te connecter à WIN11 avec :

```PowerShell
mstsc /v:WIN11
```

Pour prouver que la GPO bloque bien RDP, il faut avoir vérifié auparavant qu'une connexion RDP fonctionnait avec un compte autorisé. Cela nécessite notamment Windows 11 Pro ou Enterprise comme hôte RDP.

`Résultat attendu : nouvelle connexion RDP impossible.`

### Test 3 - Panneau de configuration

Sur WIN11, avec `user-test01`, appuie sur `Windows + R`.

Saisis :

```txt
control.exe
```

Puis essaie :

```txt
ms-settings:
```

`Résultat attendu : Windows interdit l'ouverture du Panneau de configuration et des Paramètres.`

---

## Étape 10 - Vérifier tous les résultats

```txt
Test	                      |Résultat attendu
--------------------------------------------------------------------
Utilisateur user-test01	      |Connexion locale autorisée
--------------------------------------------------------------------
Domain Admin	              |Connexion locale refusée par GPO A
--------------------------------------------------------------------
Stockage USB	              |Accès refusé
--------------------------------------------------------------------
Bureau à distance	          |Connexion entrante bloquée
--------------------------------------------------------------------
Panneau de configuration      |Ouverture bloquée
--------------------------------------------------------------------
GPO C	                      |Visible dans gpresult
```

Si un test échoue, examine d'abord le rapport `gpresult` et les éventuelles autres GPO prioritaires avant de modifier plusieurs paramètres à la fois.

---

## Étape 12 - Sauvegarder la GPO

Sur DC01 :

```PowerShell
New-Item C:\GPO-Backup -ItemType Directory -Force

Backup-GPO `
    -Name "GPO-WS-03-Security-Restrictions" `
    -Path "C:\GPO-Backup"
```

Pour annuler les restrictions, désactive temporairement le lien de la GPO C sur `Workstations-Pilot`, puis exécute `gpupdate /force` sur WIN11 et redémarre si nécessaire. Fais-le depuis VMware, en conservant ton accès de récupération avec Windows LAPS.

---

---

## Resumé :

- La troisième GPO bloque le stockage USB, les connexions RDP et les paramètres Windows.
  - Cela réduit les risques de sécurité.
