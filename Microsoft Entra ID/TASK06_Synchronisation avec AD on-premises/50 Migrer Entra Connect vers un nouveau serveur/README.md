# Migrer Microsoft Entra Connect Sync vers un nouveau serveur

Dans le lab **Diarabaka**, je migre la synchronisation de **SRV22** vers **SRV22-02**. Je prépare le nouveau serveur en **mode staging**, puis je bascule les exports vers Microsoft Entra ID. Je valide la migration en synchronisant le compte de test **Manon Harden**.

## 1. Exporter la configuration de SRV22

Sur **SRV22**, j’ouvre **Microsoft Entra Connect Sync → View or export current configuration → Export Settings**. J’enregistre la configuration au format JSON et je la copie vers le partage `\\srv22-02\SHARED`.

![Serveur source SRV22](./assets/01.png)
![Accès à la configuration existante](./assets/02.png)
![Option Export Settings](./assets/03.png)
![Enregistrement de la configuration au format JSON](./assets/04.png)
![Paramètres de synchronisation du serveur source](./assets/05.png)
![Copie du fichier exporté](./assets/06.png)
![Accès au serveur SRV22-02](./assets/07.png)
![Fichier JSON disponible dans le partage SHARED](./assets/08.png)

## 2. Installer Entra Connect Sync sur SRV22-02

Sur **SRV22-02**, je choisis **Customize**, puis **Import synchronization settings** et je sélectionne le fichier JSON exporté. Dans **User sign-in**, je vérifie que **Pass-through authentication** est sélectionnée et que **Enable single sign-on** est coché.

![Serveur cible SRV22-02](./assets/09.png)
![Installation personnalisée](./assets/10.png)
![Option d’import de la configuration](./assets/11.png)
![Sélection du fichier JSON](./assets/12.png)
![Installation avec la configuration importée](./assets/13.png)
![PTA et Seamless SSO dans les paramètres de connexion](./assets/14.png)

Je me connecte au tenant Microsoft Entra, puis j’utilise **Change Credentials** pour créer le compte du connecteur de la forêt `diarabaka.com`. Je vérifie ensuite l’étape de configuration de Seamless SSO.

![Connexion au tenant Microsoft Entra](./assets/15.png)
![Authentification du compte d’administration](./assets/16.png)
![Configuration des identifiants du connecteur AD](./assets/17.png)
![Création du compte du connecteur AD](./assets/18.png)
![Connexion à la forêt diarabaka.com validée](./assets/19.png)
![Configuration Seamless SSO validée](./assets/20.png)

## 3. Vérifier le nouveau serveur en mode staging

Je coche **Enable staging mode** et je laisse le démarrage de la synchronisation activé. Le mode staging permet d’importer et de traiter les objets sans exporter les modifications. Sur **SRV22-02**, **Synchronization Service Manager** affiche **Success** pour les imports complets et les synchronisations complètes.

![Installation de SRV22-02 avec le mode staging activé](./assets/21.png)
![Installation terminée et import du fichier JSON confirmé](./assets/22.png)
![Ouverture de Synchronization Service Manager](./assets/23.png)
![Imports et synchronisations réussis en mode staging](./assets/24.png)

## 4. Basculer les exports vers SRV22-02

Je place d’abord **SRV22** en mode staging via **Configure staging mode**. L’assistant confirme l’activation du mode sur le serveur source.

![Retour sur le serveur source SRV22](./assets/25.png)
![Ouverture de l’assistant sur SRV22](./assets/26.png)
![Sélection de Configure staging mode](./assets/27.png)
![Connexion au tenant depuis SRV22](./assets/28.png)
![Authentification auprès de Microsoft Entra](./assets/29.png)
![Activation du mode staging sur SRV22](./assets/30.png)
![Application du changement sur SRV22](./assets/31.png)
![Mode staging confirmé sur le serveur source](./assets/32.png)

Pour le test, le compte **Manon Harden** est présent dans l’OU `BELGIUM → USERS`. Sur **SRV22-02**, je décoche **Enable staging mode** et j’applique la configuration pour autoriser les exports depuis le nouveau serveur.

![Compte de test Manon Harden dans Active Directory](./assets/33.png)
![Ouverture de l’assistant sur SRV22-02](./assets/34.png)
![Accès à Configure staging mode sur le serveur cible](./assets/35.png)
![Authentification auprès du tenant depuis SRV22-02](./assets/36.png)
![Désactivation du mode staging sur SRV22-02](./assets/37.png)
![Récapitulatif avant la reprise des exports](./assets/38.png)
![Désactivation du mode staging confirmée](./assets/39.png)

## 5. Valider la migration

Sur **SRV22-02**, l’export vers Microsoft Entra affiche **Success** et **1 ajout**. Dans **Entra ID → Users**, **Manon Harden** apparaît avec **On-premises sync enabled = Yes**. Le centre d’administration Microsoft 365 affiche également une synchronisation récente.

![Export réussi du compte Manon Harden depuis SRV22-02](./assets/40.png)
![Compte Manon Harden synchronisé dans Microsoft Entra ID](./assets/41.png)
![Synchronisation d’annuaire active dans le centre d’administration Microsoft 365](./assets/42.png)
