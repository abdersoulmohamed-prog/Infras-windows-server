# Utiliser un Temporary Access Pass dans Microsoft Entra ID

Dans ce lab, je génère un **Temporary Access Pass (TAP)** pour le compte de test **Rama Barry**. Je l’utilise pour me connecter et accéder aux informations de sécurité du compte.

## 1. Configurer la stratégie TAP

Dans **Entra ID → Authentication methods → Policies**, je vérifie que **Temporary Access Pass** est activé pour **All users**.

![Stratégie Temporary Access Pass activée pour tous les utilisateurs](./assets/01.png)

Dans **Configure**, je règle la durée minimale et la durée par défaut sur **1 heure**, la durée maximale sur **8 heures** et la longueur du code sur **12 caractères**. L’usage unique est désactivé dans ce lab.

![Durées de validité, longueur du code et réglage de l’usage unique](./assets/02.png)

## 2. Créer le compte de test

Dans **Users → New user → Create new user**, je prépare le compte `rama@diarabaka.com` avec un mot de passe généré automatiquement.

![Ouverture du formulaire de création d’un utilisateur](./assets/03.png)
![Configuration du compte Rama Barry](./assets/04.png)

Je vérifie le récapitulatif, je clique sur **Create**, puis je retrouve **Rama Barry** dans **All users**.

![Récapitulatif avant la création du compte](./assets/05.png)
![Compte Rama Barry dans la liste des utilisateurs](./assets/06.png)

## 3. Générer le TAP

Sur la fiche de **Rama Barry**, j’ouvre **Authentication methods → Add authentication method**. Je sélectionne **Temporary Access Pass** et je crée un code valable **1 heure**, utilisable plusieurs fois pendant cette période.

![Création d’un TAP valable une heure](./assets/07.png)

Le panneau **Temporary Access Pass details** affiche le code et son heure d’expiration.

![Détails et durée de validité du TAP généré](./assets/08.png)

## 4. Tester la connexion et vérifier les méthodes

Je me connecte à [Security info](https://aka.ms/mysecurityinfo) avec le compte de test et je saisis le TAP. Une fois connecté, je vérifie que **Microsoft Authenticator** et **Temporary access pass** figurent dans les méthodes du compte.

![Connexion avec un Temporary Access Pass](./assets/09.png)
![Microsoft Authenticator et TAP dans Security info](./assets/10.png)

## 5. Vérifier le TAP côté administrateur

Dans **Authentication methods**, je retrouve le TAP et son expiration. Le menu de la méthode propose **Delete** pour retirer le code avant son expiration.

![TAP et heure d’expiration dans le centre d’administration](./assets/11.png)
![Option Delete dans le menu du TAP](./assets/12.png)
