# Configurer la jointure hybride Microsoft Entra ID

Dans ce lab, je configure **Microsoft Entra Connect Sync** sur **SRV22** pour joindre le poste **WIN10** à Microsoft Entra ID tout en conservant sa jointure au domaine Active Directory `diarabaka.com`.

## 1. Vérifier le périmètre de synchronisation

Dans le tenant **Diarabaka**, je vérifie que **Microsoft Entra Connect** est actif. Sur **SRV22** (Windows Server 2022), je confirme que le compte ordinateur **WIN10** se trouve dans l’OU `BELGIUM → COMPUTERS`.

![Microsoft Entra Connect actif dans le tenant Diarabaka](./assets/01_Hybrid_Join_Device.png)
![Propriétés du serveur SRV22](./assets/02_Hybrid_Join_Device.png)
![Compte ordinateur WIN10 dans l’OU COMPUTERS](./assets/03_Hybrid_Join_Device.png)

Dans **Synchronization Service Manager → Connectors**, j’ouvre les propriétés du connecteur `diarabaka.com`. Dans **Configure Directory Partitions → Containers**, je vérifie que l’OU `BELGIUM → COMPUTERS` est incluse dans le périmètre.

![Ouverture de Synchronization Service Manager](./assets/04_Hybrid_Join_Device.png)
![Accès au filtrage des conteneurs du connecteur AD](./assets/05_Hybrid_Join_Device.png)
![Authentification pour afficher les conteneurs AD](./assets/06_Hybrid_Join_Device.png)
![OU COMPUTERS incluse dans la synchronisation](./assets/07_Hybrid_Join_Device.png)
![Validation des propriétés du connecteur](./assets/08_Hybrid_Join_Device.png)

## 2. Configurer la jointure hybride et le SCP

Dans l’assistant **Microsoft Entra Connect Sync**, je sélectionne **Configure → Configure device options**. Je me connecte au tenant avec le compte administrateur du lab et je valide le MFA.

![Ouverture de l’assistant Entra Connect Sync](./assets/09_Hybrid_Join_Device.png)
![Sélection de Configure device options](./assets/10_Hybrid_Join_Device.png)
![Présentation des options de gestion des appareils](./assets/11_Hybrid_Join_Device.png)
![Compte administrateur utilisé pour connecter le tenant](./assets/12_Hybrid_Join_Device.png)
![Authentification au compte Microsoft Entra](./assets/13_Hybrid_Join_Device.png)
![Demande de validation MFA](./assets/14_Hybrid_Join_Device.png)

Je choisis **Configure Hybrid Microsoft Entra ID join**, puis **Windows 10 or later domain-joined devices**.

![Sélection de la jointure hybride Microsoft Entra](./assets/15_Hybrid_Join_Device.png)
![Ciblage des appareils Windows 10 ou ultérieurs joints au domaine](./assets/16_Hybrid_Join_Device.png)

Je configure le **Service Connection Point (SCP)** pour la forêt `diarabaka.com` avec **Microsoft Entra ID** comme service d’authentification. Le SCP permet aux postes du domaine de découvrir le tenant Entra. L’assistant confirme que la configuration est terminée.

![Configuration du SCP pour la forêt diarabaka.com](./assets/17_Hybrid_Join_Device.png)
![Forêt et service d’authentification sélectionnés](./assets/18_Hybrid_Join_Device.png)
![Récapitulatif avant la configuration du SCP](./assets/19_Hybrid_Join_Device.png)
![Configuration de la jointure hybride terminée](./assets/20_Hybrid_Join_Device.png)

## 3. Synchroniser et vérifier la stratégie de groupe

Sur **SRV22**, je lance un cycle complet après la vérification du périmètre des OU.

```powershell
Start-ADSyncSyncCycle -PolicyType Initial
```

![Lancement réussi du cycle complet](./assets/21_Hybrid_Join_Device.png)

Je vérifie la présence du SCP dans Active Directory. Pour synchroniser les modifications suivantes, je lance un cycle **Delta**.

```powershell
Get-ADObject `
    -SearchBase 'CN=Configuration,DC=diarabaka,DC=com' `
    -LDAPFilter '(&(objectClass=serviceConnectionPoint)(keywords=azureADId*))' `
    -Properties keywords

Start-ADSyncSyncCycle -PolicyType Delta
```

![SCP trouvé dans Active Directory et cycle Delta lancé](./assets/22_Hybrid_Join_Device.png)

Dans la stratégie ordinateur, je vérifie que **Device Registration → Register domain joined computers as devices** est sur **Enabled**.

![Paramètre d’enregistrement des ordinateurs du domaine activé](./assets/23_Hybrid_Join_Device.png)

## 4. Confirmer la jointure hybride de WIN10

Sur **WIN10**, j’exécute `dsregcmd /status`. Le poste affiche **DomainJoined : YES**, **AzureAdJoined : YES** et **DeviceAuthStatus : SUCCESS**.

![Jointure au domaine et à Microsoft Entra confirmée sur WIN10](./assets/24_Hybrid_Join_Device.png)

Dans **Entra ID → Devices → All devices**, le poste **win10** apparaît avec le type **Microsoft Entra hybrid joined**.

![Poste win10 affiché comme Microsoft Entra hybrid joined](./assets/25_Hybrid_Join_Device.png)

---

**win10**

```PowerShell
#Commande utile diagnostic
dsregcmd /debug /leave
#Puis :
gpupdate /force
shutdown /r /t 0
#Après reboot :
dsregcmd /status
```
