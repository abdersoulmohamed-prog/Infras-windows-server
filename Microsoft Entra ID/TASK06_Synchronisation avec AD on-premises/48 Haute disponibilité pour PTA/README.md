# Ajouter un second agent PTA dans Microsoft Entra ID

Dans le tenant de lab **Diarabaka**, j’ajoute un second agent **Pass-Through Authentication (PTA)** sur **SRV22-02** pour que l’authentification puisse continuer si l’un des agents devient indisponible.

## 1. Vérifier l’agent existant

Dans **Microsoft Entra Connect → Connect Sync**, je vérifie que PTA est activée avec **1 agent**. La page **Passthrough Authentication** affiche `srv22.diarabaka.com` avec un indicateur vert.

![PTA activée avec un seul agent](./assets/01.png)
![Agent PTA actif sur SRV22](./assets/02.png)

## 2. Installer le second agent

Depuis la page **Passthrough Authentication**, je télécharge le programme d’installation de l’agent. **SRV22** héberge déjà le premier agent. J’installe le second sur **SRV22-02**, un autre serveur Windows Server 2022 joint au domaine `diarabaka.com`.

![Téléchargement du programme d’installation de l’agent PTA](./assets/03.png)
![Propriétés du serveur SRV22](./assets/04.png)
![Propriétés du serveur SRV22-02](./assets/05.png)
![Installation de l’agent PTA sur SRV22-02](./assets/06.png)
![Installation de l’agent terminée avec succès](./assets/07.png)

## 3. Vérifier la redondance

Dans **Connect Sync**, PTA affiche désormais **2 agents**. Les serveurs `srv22.diarabaka.com` et `srv22-02.diarabaka.com` apparaissent tous les deux avec un indicateur vert.

![Deux agents PTA affichés dans Connect Sync](./assets/08.png)
![Agents SRV22 et SRV22-02 actifs dans Microsoft Entra ID](./assets/09.png)

**Résultat** — Les deux agents sont actifs dans le lab. Le test de continuité avec un agent arrêté reste à documenter. Le portail recommande au moins **trois agents** par tenant.
