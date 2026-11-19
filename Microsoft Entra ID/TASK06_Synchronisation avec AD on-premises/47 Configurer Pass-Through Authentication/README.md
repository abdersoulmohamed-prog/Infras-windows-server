# Configurer Pass-Through Authentication dans Microsoft Entra ID

Dans le tenant de lab **Diarabaka**, je passe de **Password Hash Synchronization (PHS)** à **Pass-Through Authentication (PTA)** comme méthode de connexion. Avec PTA, un agent installé sur **SRV22** fait valider les mots de passe par l’Active Directory local.

## 1. Vérifier l’état initial

Dans **Microsoft Entra Connect → Connect Sync**, je vérifie que **Password Hash Sync** est activé et que **Pass-through authentication** affiche **Disabled** avec **0 agents**.

![Microsoft Entra Connect actif dans le tenant Diarabaka](./assets/01.png)
![État initial de PHS et de PTA](./assets/02.png)

## 2. Activer PTA sur SRV22

Sur **SRV22** (Windows Server 2022), j’ouvre **Microsoft Entra Connect Sync → Configure → Change user sign-in**. Je me connecte au tenant avec le compte administrateur du lab et je valide le MFA.

![Serveur SRV22 dans le domaine diarabaka.com](./assets/03.png)
![Ouverture de l’assistant Entra Connect Sync](./assets/04.png)
![Sélection de Change user sign-in](./assets/05.png)
![Connexion au tenant Microsoft Entra](./assets/06.png)
![Authentification du compte administrateur](./assets/07.png)
![Demande de validation MFA](./assets/08.png)

Dans **User sign-in**, je sélectionne **Pass-through authentication** et je laisse **Enable single sign-on** coché pour `diarabaka.com`. Je lance la configuration pour installer l’agent PTA et activer la méthode de connexion.

![Sélection de Pass-through authentication](./assets/09.png)
![Configuration Seamless SSO pour diarabaka.com](./assets/10.png)
![Récapitulatif avant l’installation de l’agent PTA](./assets/11.png)
![PTA confirmé comme méthode de connexion](./assets/12.png)

## 3. Vérifier l’agent PTA

Dans **Connect Sync**, PTA affiche **Enabled** avec **1 agent**. La page **Passthrough Authentication** affiche un indicateur vert pour `srv22.diarabaka.com`. À ce stade, **Password Hash Sync** apparaît encore activé.

![PTA activé avec un agent et PHS encore activé](./assets/13.png)
![Agent PTA de SRV22 avec un indicateur vert](./assets/14.png)

## 4. Désactiver PHS dans le lab

Dans l’assistant, j’ouvre **View or export current configuration** pour confirmer que **Password Hash Synchronization** est encore activé.

![Réouverture de l’assistant Entra Connect Sync](./assets/15.png)
![Accès à la configuration actuelle](./assets/16.png)
![Password Hash Synchronization encore activé](./assets/17.png)

J’ouvre ensuite **Customize synchronization options**, je me reconnecte au tenant et je vérifie la forêt `diarabaka.com` ainsi que le mode de filtrage par domaine et OU.

![Accès aux options de synchronisation](./assets/18.png)
![Authentification auprès du tenant](./assets/19.png)
![Forêt Active Directory configurée](./assets/20.png)
![Vérification du mode de filtrage par domaine et OU](./assets/21.png)

Dans **Optional features**, je décoche **Password hash synchronization**. Je valide l’étape **Enable single sign-on**, puis j’applique la configuration.

![Option Password hash synchronization décochée](./assets/22.png)
![Configuration Seamless SSO conservée](./assets/23.png)
![Récapitulatif avant la désactivation de PHS](./assets/24.png)
![Configuration appliquée et synchronisation lancée](./assets/25.png)

## Résultat

Le portail confirme **PTA activé avec un agent** et **Password Hash Sync désactivé**. La validation d’une connexion utilisateur via PTA reste à documenter.

![État final de PTA et de Password Hash Sync dans Connect Sync](./assets/26.png)
