# Configurer le MFA par utilisateur dans Microsoft Entra ID

Dans ce lab, j’active le **MFA par utilisateur** pour **David Warner**, puis je teste la connexion avec **Microsoft Authenticator**.

## 1. Vérifier l’état du tenant

Dans **Entra ID → Overview → Properties**, je relève que les paramètres de sécurité par défaut (**Security defaults**) sont actifs sur le tenant **Diarabaka**.

![Paramètres de sécurité par défaut actifs sur le tenant](./assets/01_Per_user_MFA%20.png)

## 2. Activer le MFA pour David Warner

Dans **Entra ID → Users → All users**, je clique sur **Per-user MFA**.

![Accès au MFA par utilisateur depuis la liste des comptes](./assets/02_Per_user_MFA%20.png)

Je sélectionne **David Warner**, je clique sur **Enable MFA**, puis je confirme avec **Enable**.

![Activation du MFA par utilisateur pour David Warner](./assets/03_Per_user_MFA%20.png)

La liste affiche le statut **Enforced** pour `david.w@diarabaka.com`.

![Statut Enforced pour David Warner](./assets/04_Per_user_MFA%20.png)

## 3. Tester la connexion

En navigation privée, je me connecte à [Mon compte Microsoft](https://myaccount.microsoft.com/) avec le compte de David Warner.

![Saisie du mot de passe du compte de test](./assets/05_Per_user_MFA%20.png)

J’approuve la demande dans **Microsoft Authenticator** avec le numéro affiché à l’écran.

![Demande MFA avec correspondance de numéro](./assets/06_Per_user_MFA%20.png)

Le portail **Mon compte** s’ouvre après la validation, ce qui confirme la réussite de la connexion.

![Accès au portail Mon compte après validation MFA](./assets/07_Per_user_MFA%20.png)
