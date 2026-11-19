# Créer un compte utilisateur dans Microsoft Entra ID

Je crée un compte interne pour **David Warner** avec l’identifiant de connexion `david.w@diarabaka.com`, puis je l’active après sa création.

## 1. Créer l’utilisateur

Dans **Entra ID → Users**, je sélectionne **New user → Create new user**.

![Ouverture de l’assistant de création d’un utilisateur](./assets/01.png)

Dans **Basics**, je renseigne l’identifiant de connexion (UPN), le nom d’affichage et le mot de passe initial. Je laisse **Account enabled** décoché pour créer le compte à l’état désactivé.

![Identifiant, nom d’affichage et état initial du compte](./assets/02.png)

## 2. Renseigner le profil

Dans **Properties**, je sélectionne le type **Member** et je renseigne les informations professionnelles, dont le poste **System Administrator** et le service **IT Infrastructure**.

![Type de compte et informations professionnelles](./assets/03.png)

Je complète les coordonnées et je sélectionne **Belgium** dans **Usage location**.

![Coordonnées et emplacement d’utilisation](./assets/04.png)

## 3. Vérifier et créer le compte

Dans **Assignments**, je continue sans attribuer de groupe, de rôle ni d’unité administrative.

![Onglet Assignments sans attribution](./assets/05.png)

Dans **Review + create**, je vérifie les informations et je clique sur **Create**.

![Récapitulatif avant la création du compte](./assets/06.png)

David Warner apparaît dans **All users** avec le type **Member**.

![Compte David Warner dans la liste des utilisateurs](./assets/07.png)

## 4. Activer le compte

Sur la fiche de l’utilisateur, **Account status** affiche d’abord **Disabled**.

![Compte désactivé après sa création](./assets/08.png)

Après activation, **Account status** affiche **Enabled**. Le compte `david.w@diarabaka.com` est créé et activé.

![Compte David Warner activé dans Microsoft Entra ID](./assets/09.png)
