# Configurer le filtrage par OU dans Microsoft Entra Connect Sync

Dans le lab **Diarabaka**, je limite le périmètre de synchronisation à l’OU `BELGIUM` et à ses sous-OU. J’applique la configuration sur **SRV22** en mode staging, avec les cycles automatiques désactivés.

## 1. Vérifier les OU et suspendre les cycles automatiques

Dans **Active Directory Users and Computers**, je vérifie la structure de l’OU `BELGIUM`. Sur **SRV22**, je désactive les cycles automatiques avant de modifier le filtre.

```powershell
Set-ADSyncScheduler -SyncCycleEnabled $false
```

![Structure de l’OU BELGIUM dans Active Directory](./assets/01.png)
![Désactivation des cycles automatiques sur SRV22](./assets/02.png)

## 2. Sélectionner les OU à synchroniser

Dans **Microsoft Entra Connect Sync → Configure → Customize synchronization options**, je me connecte au tenant et je vérifie que la forêt `diarabaka.com` est configurée.

![Ouverture de l’assistant Entra Connect Sync](./assets/03.png)
![Sélection de Customize synchronization options](./assets/04.png)
![Connexion au tenant Microsoft Entra](./assets/05.png)
![Forêt diarabaka.com configurée](./assets/06.png)

Dans **Domain and OU filtering**, je choisis **Sync selected domains and OUs** et je coche `BELGIUM` ainsi que ses sous-OU `COMPUTERS`, `MANAGEMENT`, `SERVERS` et `USERS`. Le conteneur `Users` à la racine du domaine est exclu du périmètre.

![Filtrage sur BELGIUM et ses quatre sous-OU](./assets/07.png)

## 3. Appliquer la configuration en mode staging

Je laisse **Password hash synchronization** cochée dans **Optional features** et je vérifie l’étape **Seamless SSO**. Dans le récapitulatif, le **mode staging** est actif et l’option de démarrage automatique de la synchronisation est décochée. Je clique sur **Configure**.

![Option Password hash synchronization cochée](./assets/08.png)
![Validation de l’étape Seamless SSO](./assets/09.png)
![Récapitulatif avec mode staging et démarrage automatique désactivé](./assets/10.png)

L’assistant affiche **Configuration complete**. Le filtre est configuré sur **SRV22**. La validation des objets inclus et exclus après un cycle de synchronisation reste à documenter.

![Configuration terminée avec la synchronisation désactivée](./assets/11.png)
