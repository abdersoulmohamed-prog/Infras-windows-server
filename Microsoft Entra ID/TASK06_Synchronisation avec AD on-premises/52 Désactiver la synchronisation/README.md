# Désactiver la synchronisation d’annuaire dans Microsoft Entra ID

Dans le tenant de lab **Diarabaka**, je désactive les cycles automatiques sur **SRV22-02**, puis je désactive la synchronisation d’annuaire à l’échelle du tenant avec **Microsoft Graph PowerShell**.

## 1. Identifier les comptes synchronisés

Dans **Entra ID → Users → All users**, j’applique le filtre **On-premises sync enabled = Yes**. Le portail affiche **4 utilisateurs synchronisés** depuis Active Directory.

![Configuration du filtre des utilisateurs synchronisés](./assets/01.png)
![Quatre utilisateurs synchronisés avant la désactivation](./assets/02.png)

## 2. Désactiver les cycles automatiques sur SRV22-02

Sur **SRV22-02**, je désactive le planificateur d’Entra Connect Sync et je vérifie que `SyncCycleEnabled` affiche `False`.

```powershell
Set-ADSyncScheduler -SyncCycleEnabled $false
Get-ADSyncScheduler | Select-Object SyncCycleEnabled
```

![Serveur SRV22-02 dans le domaine diarabaka.com](./assets/03.png)
![Planificateur de synchronisation désactivé sur SRV22-02](./assets/04.png)

## 3. Désactiver la synchronisation du tenant

J’installe **PowerShell 7.6.3 x64** et j’utilise le module **Microsoft.Graph**. Après connexion au tenant, je vérifie que `OnPremisesSyncEnabled` affiche `True`, puis je définis cette propriété sur `$false` avec `Update-MgOrganization`.

![Téléchargement de PowerShell 7.6.3 x64](./assets/05.png)
![Programme d’installation disponible sur le serveur](./assets/06.png)
![Désactivation de la synchronisation du tenant avec Microsoft Graph](./assets/07.png)

## 4. Vérifier le résultat dans Entra ID

La vue d’ensemble affiche **Microsoft Entra Connect — Not enabled**. Dans **All users**, le filtre **On-premises sync enabled = Yes** passe de **4 utilisateurs à 0**.

![Microsoft Entra Connect affiché comme désactivé](./assets/08.png)
![Aucun utilisateur retourné par le filtre de synchronisation](./assets/09.png)

[v7.6.3 Release of PowerShell](https://github.com/PowerShell/PowerShell/releases)
