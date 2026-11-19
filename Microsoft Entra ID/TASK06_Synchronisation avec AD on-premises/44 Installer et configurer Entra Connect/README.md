# Installer et configurer Microsoft Entra Connect Sync

Dans ce lab, je synchronise les identités de l’Active Directory local `diarabaka.com` vers Microsoft Entra ID. L’installation personnalisée utilise **Password Hash Synchronization (PHS)**. Le premier cycle exporte **trois utilisateurs et un groupe de sécurité**.

## 1. Préparer le serveur et le tenant

Le lab utilise **SRV22**, une VM Windows Server 2022 sous VirtualBox, dans le domaine `diarabaka.com`. Dans **Active Directory Users and Computers**, l’OU `BELGIUM → USERS` contient les trois comptes de test et le groupe `GG_BelgiumTeams`.

![Serveur SRV22 dans le domaine diarabaka.com](./assets/01.png)
![Utilisateurs et groupe de sécurité dans l’AD local](./assets/02.png)

Dans le portail Entra, je vérifie que `diarabaka.com` est **Verified** et **Primary**. La page **Connect Sync** indique qu’aucune synchronisation n’a encore été exécutée.

![Domaine personnalisé vérifié et principal](./assets/03.png)
![État de Connect Sync avant l’installation](./assets/04.png)

## 2. Installer Connect Sync

Je télécharge le programme d’installation depuis le portail Entra, puis je le récupère sur SRV22 via le dossier partagé VirtualBox `\\vboxsrv`.

![Téléchargement de Microsoft Entra Connect Sync](./assets/05.png)
![Accès au dossier partagé VirtualBox](./assets/06.png)
![Programme d’installation AzureADConnect sur SRV22](./assets/07.png)

Je lance l’assistant, je choisis **Customize**, puis j’installe les composants requis avec les options proposées.

![Écran d’accueil de Microsoft Entra Connect Sync](./assets/08.png)
![Sélection de l’installation personnalisée](./assets/09.png)
![Installation des composants requis](./assets/10.png)

## 3. Connecter Microsoft Entra ID et Active Directory

Dans **User sign-in**, je sélectionne **Password Hash Synchronization** et je laisse **Enable single sign-on** décoché. Je me connecte au tenant avec le compte administrateur du lab et je valide le MFA dans Microsoft Authenticator.

![Sélection de Password Hash Synchronization](./assets/11.png)
![Compte administrateur utilisé pour connecter le tenant](./assets/12.png)
![Saisie de l’identifiant Microsoft Entra](./assets/13.png)
![Authentification du compte Microsoft Entra](./assets/14.png)
![Demande de validation MFA](./assets/15.png)

Dans **Connect your directories**, j’ajoute la forêt `diarabaka.com`. Je sélectionne **Create new AD account** pour que l’assistant crée le compte du connecteur AD.

![Sélection de la forêt Active Directory](./assets/16.png)
![Création du compte du connecteur AD](./assets/17.png)
![Forêt diarabaka.com ajoutée à la configuration](./assets/18.png)

## 4. Définir le périmètre de synchronisation

L’assistant confirme que le suffixe UPN `diarabaka.com` est vérifié. Je conserve `userPrincipalName` comme identifiant de connexion et je limite la synchronisation à l’OU `BELGIUM`, avec les sous-OU `COMPUTERS`, `MANAGEMENT`, `SERVERS` et `USERS` cochées.

![Suffixe UPN vérifié et attribut de connexion](./assets/19.png)
![Filtrage du domaine et des unités organisationnelles](./assets/20.png)

Je laisse l’assistant gérer le **source anchor**, l’identifiant utilisé pour lier les objets locaux à leurs équivalents dans Entra ID. Je conserve le périmètre défini par les OU, sans ajouter de filtre par groupe pilote.

![Gestion du source anchor par l’assistant](./assets/21.png)
![Synchronisation sans filtre supplémentaire par groupe pilote](./assets/22.png)

## 5. Lancer la première synchronisation

Dans **Optional features**, je vérifie que **Password hash synchronization** est cochée. Je laisse le démarrage automatique de la synchronisation activé et je clique sur **Install**. L’assistant confirme que la configuration est terminée et que le premier cycle a démarré.

![Fonctionnalités sélectionnées pour la synchronisation](./assets/23.png)
![Démarrage de la synchronisation après l’installation](./assets/24.png)
![Configuration terminée et premier cycle lancé](./assets/25.png)

## 6. Vérifier les objets synchronisés

Dans **Microsoft Entra Connect → Connect Sync**, je vérifie que **Sync status** et **Password Hash Sync** affichent **Enabled**. Dans **All users**, les comptes issus de l’AD local affichent **Yes** dans la colonne **On-premises sync enabled**.

![Connect Sync et Password Hash Sync activés](./assets/26.png)
![Comptes locaux synchronisés visibles dans All users](./assets/27.png)

Sur **SRV22**, j’ouvre **Synchronization Service Manager**. L’export vers Microsoft Entra affiche **Success** et **4 ajouts**.

![Ouverture de Synchronization Service sur SRV22](./assets/28.png)
![Export réussi avec quatre objets ajoutés](./assets/29.png)

Dans le portail Entra, le filtre **On-premises sync enabled = Yes** renvoie **Aminata Barry**, **Axel Harden** et **Sylvain Renard**. Le groupe `GG_BelgiumTeams` apparaît dans **All groups**.

![Configuration du filtre des utilisateurs synchronisés](./assets/30.png)
![Trois utilisateurs synchronisés depuis Active Directory](./assets/31.png)
![Groupe GG_BelgiumTeams dans Microsoft Entra ID](./assets/32.png)
