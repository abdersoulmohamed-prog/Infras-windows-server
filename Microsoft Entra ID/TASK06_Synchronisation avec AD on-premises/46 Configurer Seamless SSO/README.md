# Configurer Seamless SSO dans Microsoft Entra ID

Dans le tenant de lab **Diarabaka**, j’active **Seamless Single Sign-On** dans Microsoft Entra Connect Sync en conservant **Password Hash Synchronization (PHS)**. L’objectif est de permettre aux utilisateurs d’accéder aux services Microsoft depuis leur session Windows sans ressaisir leur mot de passe.

## 1. Activer Seamless SSO dans Entra Connect

Dans le portail Entra, je vérifie que **Connect Sync** est actif. Avant la configuration, la ligne **Seamless single sign-on** affiche **Enabled** avec **0 domains**.

![Entra Connect actif dans le tenant Diarabaka](./assets/01.png)
![État initial de Seamless SSO avec zéro domaine](./assets/02.png)

Sur le serveur, j’ouvre **Microsoft Entra Connect Sync → Configure → Change user sign-in**, puis je m’authentifie auprès du tenant.

![Ouverture de l’assistant depuis le serveur](./assets/03.png)
![Accès à la configuration Entra Connect Sync](./assets/04.png)
![Sélection de Change user sign-in](./assets/05.png)
![Connexion au tenant Microsoft Entra](./assets/06.png)
![Authentification du compte d’administration Entra](./assets/07.png)

Je conserve **Password Hash Synchronization** et je coche **Enable single sign-on**. Je fournis les identifiants d’un administrateur du domaine `diarabaka.com`, puis je lance la configuration.

![PHS conservé et option Enable single sign-on cochée](./assets/08.png)
![Sélection du domaine pour Seamless SSO](./assets/09.png)
![Authentification auprès du domaine Active Directory](./assets/10.png)
![Identifiants du domaine validés](./assets/11.png)
![Récapitulatif avant l’activation](./assets/12.png)
![Configuration terminée dans Entra Connect Sync](./assets/13.png)

Le portail affiche ensuite **1 domain** pour Seamless SSO. Dans Active Directory, le compte ordinateur `AZUREADSSOACC` apparaît dans le conteneur **Computers**.

![Seamless SSO activé pour un domaine](./assets/14.png)
![Compte ordinateur AZUREADSSOACC dans Active Directory](./assets/15.png)

## 2. Déployer la configuration par GPO

Dans **Group Policy Management**, je modifie la GPO **Microsoft Entra Seamless SSO**. Dans **Internet Control Panel → Security Page → Site to Zone Assignment List**, j’ajoute `https://autologon.microsoftazuread-sso.com` avec la valeur **1** pour la zone **Intranet local**. Dans **Intranet Zone**, j’active **Allow updates to status bar via script**.

![Ouverture de la GPO Microsoft Entra Seamless SSO](./assets/16.png)
![Accès aux paramètres de sécurité des zones](./assets/17.png)
![Ajout de l’URL Seamless SSO à la zone Intranet local](./assets/18.png)
![Activation du paramètre Allow updates to status bar via script](./assets/19.png)

Je lie la GPO à l’OU **BELGIUM**, puis j’actualise les stratégies sur **WIN10** et je redémarre le poste.

![Liaison d’une GPO existante à l’OU BELGIUM](./assets/20.png)
![Sélection de la GPO Microsoft Entra Seamless SSO](./assets/21.png)

```powershell
gpupdate /force
shutdown /r /t 0
```

![Actualisation réussie des stratégies sur WIN10](./assets/22.png)

## 3. Vérifier le résultat du test

J’ouvre une session Windows avec **Aminata Barry**, puis j’accède à [Mon compte Microsoft](https://myaccount.microsoft.com/). Le portail s’ouvre après une nouvelle saisie du mot de passe.

![Ouverture de session Windows avec Aminata Barry](./assets/23.png)
![Demande de mot de passe lors de l’accès au portail Microsoft](./assets/24.png)
![Accès au portail Mon compte après authentification](./assets/25.png)

**Résultat** — Seamless SSO est configuré pour un domaine. La connexion au portail a réussi après saisie du mot de passe. La validation d’une connexion sans ressaisie reste à faire.

[Documentation Microsoft sur Seamless SSO](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/how-to-connect-sso-quick-start)
