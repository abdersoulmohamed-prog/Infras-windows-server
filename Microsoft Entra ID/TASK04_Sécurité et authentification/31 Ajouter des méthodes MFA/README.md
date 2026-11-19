# Ajouter des méthodes MFA dans Microsoft Entra ID

Dans ce lab, j’ajoute un numéro de téléphone au compte **Rama Barry**, j’active les SMS pour un groupe de test et je vérifie l’inscription de **Microsoft Authenticator**.

## 1. Ajouter un numéro de téléphone

Dans **Entra ID → Users → Rama Barry → Authentication methods**, je clique sur **Add authentication method**, puis je sélectionne **Phone number** et **Primary mobile**.

![Sélection du compte Rama Barry](./assets/01_MFA_Methods.png)
![Ajout du numéro de téléphone principal](./assets/02_MFA_Methods.png)

Le numéro est enregistré, mais il apparaît dans **Non-usable authentication methods** avec la mention **Disabled by policy**. Dans **Authentication methods → Policies**, la méthode **SMS** affiche **No**.

![Numéro enregistré mais désactivé par la stratégie](./assets/03_MFA_Methods.png)
![Méthode SMS désactivée dans la stratégie](./assets/04_MFA_Methods.png)

## 2. Activer les SMS pour le groupe de test

Dans **SMS settings**, j’active la méthode, puis je passe de **All users** à **Select groups**. Je sélectionne **TMB-SecGroup1** et j’enregistre.

![Activation de la méthode SMS avant le ciblage](./assets/06_MFA_Methods.png)
![Sélection du groupe TMB-SecGroup1](./assets/07_MFA_Methods.png)
![Configuration SMS ciblée sur TMB-SecGroup1](./assets/08_MFA_Methods.png)

La liste des stratégies confirme que les SMS sont activés pour **1 group**. Sur la fiche de Rama, le numéro figure désormais parmi les méthodes utilisables.

![Stratégie SMS activée pour un seul groupe](./assets/09_MFA_Methods.png)
![Numéro principal utilisable pour les SMS](./assets/10_MFA_Methods.png)

## 3. Enregistrer Microsoft Authenticator

À la connexion, le compte est invité à configurer **Microsoft Authenticator**. Une demande d’approbation avec correspondance de numéro s’affiche ensuite.

![Invite de configuration de Microsoft Authenticator](./assets/11_MFA_Methods.png)
![Demande d’approbation avec correspondance de numéro](./assets/12_MFA_Methods.png)

## 4. Vérifier les méthodes et les connexions

Dans **Security info**, je retrouve le téléphone et **Microsoft Authenticator**. Dans **Sign-in logs**, plusieurs connexions du compte affichent **Success**.

![Téléphone et Microsoft Authenticator dans Security info](./assets/13_MFA_Methods.png)
![Résultats des connexions du compte Rama Barry](./assets/14_MFA_Methods.png)

Côté administrateur, **Authentication methods** confirme que le téléphone et Microsoft Authenticator sont utilisables. La méthode MFA préférée par le système est **PhoneAppNotification**, la notification de Microsoft Authenticator.

![Méthodes utilisables et méthode MFA préférée par le système](./assets/16_MFA_Methods.png)
