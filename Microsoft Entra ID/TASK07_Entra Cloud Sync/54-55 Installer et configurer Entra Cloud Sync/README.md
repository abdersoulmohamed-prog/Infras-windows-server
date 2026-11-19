# Installer et configurer Microsoft Entra Cloud Sync

Dans le lab **Diarabaka**, j’installe l’agent de provisionnement sur **SRV22-02** et je configure la synchronisation d’Active Directory vers Microsoft Entra ID pour l’OU `BELGIUM`.

## 1. Installer l’agent de provisionnement

**SRV22-02** est un serveur Windows Server 2022 joint au domaine `diarabaka.com`. Avant l’installation, le portail affiche **Microsoft Entra Connect — Not enabled**.

![Serveur SRV22-02 joint au domaine diarabaka.com](./assets/01.png)
![État initial de la synchronisation dans le tenant](./assets/02.png)

Dans **Microsoft Entra Connect → Cloud Sync → Agents**, je télécharge l’agent local et je lance `AADConnectProvisioningAgentSetup` sur **SRV22-02**.

![Accès à Cloud Sync depuis le portail Entra](./assets/03.png)
![Téléchargement de l’agent de provisionnement](./assets/04.png)
![Installation de l’agent sur SRV22-02](./assets/05.png)

Dans l’assistant, je choisis de connecter un domaine Active Directory, je sélectionne **Create gMSA**, puis je valide la connexion à `diarabaka.com`.

![Assistant de configuration de l’agent](./assets/06.png)
![Création du compte de service gMSA](./assets/07.png)
![Connexion au domaine Active Directory](./assets/08.png)
![Récapitulatif de la configuration](./assets/09.png)
![Installation et configuration de l’agent terminées](./assets/10.png)

Dans Active Directory, je retrouve le compte de service `provAgentgMSA`. Dans **Cloud Sync → Agents**, `srv22-02.diarabaka.com` affiche le statut **Active**.

![Compte provAgentgMSA dans Managed Service Accounts](./assets/11.png)
![Agent SRV22-02 actif dans Microsoft Entra ID](./assets/12.png)

## 2. Créer la configuration et cibler l’OU BELGIUM

Dans **Cloud Sync → Configurations → New configuration**, je sélectionne **AD to Microsoft Entra ID sync**. Je choisis `diarabaka.com` et j’active **Password hash sync**. La configuration est initialement **Disabled**.

![Création d’une configuration AD vers Microsoft Entra ID](./assets/13.png)
![Sélection du domaine et activation de Password hash sync](./assets/14.png)
![Configuration initiale avec un agent disponible](./assets/15.png)

Je récupère le `distinguishedName` de l’OU `BELGIUM` et j’ajoute `OU=BELGIUM,DC=diarabaka,DC=com` dans **Scoping filters → Selected organizational units**. Je vérifie ensuite le mappage des attributs.

![Nom distinctif de l’OU BELGIUM dans Active Directory](./assets/16.png)
![Ajout de l’OU dans le filtre de périmètre](./assets/17.png)
![OU BELGIUM affichée dans le périmètre](./assets/18.png)
![Mappage des attributs Cloud Sync](./assets/19.png)

## 3. Préparer le test et activer la synchronisation

Dans **Provision on demand**, je renseigne le nom distinctif du compte **Aminata Barry** pour lancer un test ciblé. La configuration générale affiche encore **Disabled** à cette étape.

![Accès au test de provisionnement](./assets/20.png)
![Nom distinctif d’Aminata Barry dans Active Directory](./assets/21.png)
![Compte renseigné dans Provision on demand](./assets/22.png)
![Configuration encore désactivée avant la mise en service](./assets/23.png)

Dans **Edit properties**, je renseigne l’adresse de notification et je vérifie que la protection contre les suppressions accidentelles est activée avec un seuil de **500 objets**. J’active ensuite la configuration via **Review and enable**.

![Accès aux propriétés de Cloud Sync](./assets/24.png)
![Adresse de notification et seuil de suppression accidentelle](./assets/25.png)
![Propriétés enregistrées](./assets/26.png)
![Activation de la configuration Cloud Sync](./assets/27.png)

## 4. Vérifier le résultat

La configuration `diarabaka.com` affiche **Healthy**, avec **1 agent** et **Password hash sync** activé. Dans **All users**, le filtre **On-premises sync enabled = Yes** affiche uniquement le compte de service de synchronisation. Le provisionnement d’**Aminata Barry** reste à confirmer dans **Provisioning logs**.

![Configuration Cloud Sync au statut Healthy](./assets/28.png)
![Vue d’ensemble avec un agent actif et Password hash sync activé](./assets/29.png)
![Résultat du filtre des utilisateurs synchronisés](./assets/30.png)

## Commandes de vérification sur SRV22-02

```powershell
Get-Service -Name 'AADConnectProvisioningAgent'
Get-ADDomain
nltest /dsgetdc:diarabaka.com
Get-ADServiceAccount -Identity 'provAgentgMSA'
```
