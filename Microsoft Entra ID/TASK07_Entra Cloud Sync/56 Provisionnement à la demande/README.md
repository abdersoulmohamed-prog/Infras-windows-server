# Tester le provisionnement à la demande avec Microsoft Entra Cloud Sync

Dans ce lab, je lance un test de provisionnement ciblé pour **Jennifer Nevado**, un compte de l’Active Directory local `diarabaka.com`.

## 1. Vérifier la configuration Cloud Sync

Le portail Entra indique que la synchronisation est activée dans le tenant **Diarabaka**. Sur **SRV22-02**, je vérifie que le serveur est joint au domaine `diarabaka.com`.

![Synchronisation activée dans le tenant Diarabaka](./assets/01.png)
![Serveur SRV22-02 joint au domaine diarabaka.com](./assets/02.png)

Dans **Microsoft Entra Connect → Cloud Sync → Configurations**, la configuration `diarabaka.com` affiche **Healthy** et la direction **AD to Microsoft Entra ID**.

![Configuration Cloud Sync au statut Healthy](./assets/03.png)

## 2. Lancer le provisionnement à la demande

Dans **Active Directory Users and Computers**, j’ouvre le compte **Jennifer Nevado** dans `BELGIUM → USERS`. Dans **Attribute Editor**, je copie son attribut `distinguishedName`.

![Nom distinctif du compte Jennifer Nevado dans Active Directory](./assets/04.png)

Dans **Cloud Sync → diarabaka.com → Provision on demand**, je colle le nom distinctif du compte, puis je clique sur **Provision**.

![Compte Jennifer Nevado sélectionné pour le provisionnement à la demande](./assets/05.png)

## 3. Vérifier le périmètre et le résultat

Dans **Scoping filters**, je vérifie que la configuration cible l’OU `OU=BELGIUM,DC=diarabaka,DC=com`, qui contient le compte de test.

![OU BELGIUM incluse dans le périmètre Cloud Sync](./assets/06.png)

Le lancement du test est documenté. Le résultat pour **Jennifer Nevado** reste à confirmer dans **Provisioning logs**.
