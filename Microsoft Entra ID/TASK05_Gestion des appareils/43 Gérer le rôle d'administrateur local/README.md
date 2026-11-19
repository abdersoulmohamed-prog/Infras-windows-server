# Gérer le rôle d’administrateur local des appareils joints à Microsoft Entra ID

Dans le tenant de lab **Diarabaka**, je vérifie les paramètres d’administration locale, puis je compare les sessions Windows de **John Doe** et de **Virat Kohli**.

## 1. Vérifier les droits accordés à la jointure

Dans **Entra ID → Devices → Device settings → Local administrator settings**, l’ajout automatique du rôle **Global Administrator** est réglé sur **No**. L’ajout de l’utilisateur qui effectue la jointure est réglé sur **Selected**, avec **John Doe** dans la liste. Ce réglage s’applique au moment de la jointure.

![Paramètres d’administration locale lors de la jointure](./assets/01_Joined_Device_Local_Admin_role.png)
![John Doe sélectionné pour l’ajout lors de la jointure](./assets/02_Joined_Device_Local_Admin_role.png)

## 2. Attribuer le rôle à Virat Kohli

Depuis **Manage Additional local administrators on all Microsoft Entra joined devices**, j’ouvre **Device Administrators → Add assignments** et je sélectionne **Virat Kohli**. La liste confirme l’attribution avec la portée **Directory**.

![Sélection de Virat Kohli pour l’attribution du rôle](./assets/03_Joined_Device_Local_Admin_role.png)
![Attribution du rôle confirmée au niveau de l’annuaire](./assets/04_Joined_Device_Local_Admin_role.png)

## 3. Vérifier la session Windows de John Doe

Sur le poste Windows, j’ajoute le compte professionnel `john.d@diarabaka.com` et je valide la demande dans **Microsoft Authenticator**.

![Saisie de l’identifiant professionnel de John Doe](./assets/05_Joined_Device_Local_Admin_role.png)
![Authentification avec le mot de passe](./assets/06_Joined_Device_Local_Admin_role.png)
![Demande MFA dans Microsoft Authenticator](./assets/07_Joined_Device_Local_Admin_role.png)
![Confirmation de l’ajout du compte professionnel](./assets/08_Joined_Device_Local_Admin_role.png)

J’ouvre ensuite une session Windows avec John et je configure son code PIN. Je consulte le groupe local **Administrators** et la page **Accounts → Your info**, où son profil s’affiche sans la mention **Administrator**.

![Ouverture de session Windows avec John Doe](./assets/09_Joined_Device_Local_Admin_role.png)
![Configuration du code PIN](./assets/10_Joined_Device_Local_Admin_role.png)
![Membres du groupe local Administrators](./assets/11_Joined_Device_Local_Admin_role.png)
![Profil Windows de John Doe](./assets/12_Joined_Device_Local_Admin_role.png)

## 4. Confirmer les droits de Virat Kohli

J’ouvre une session avec `virat@diarabaka.com`. Dans **Accounts → Your info**, Windows affiche la mention **Administrator**, ce qui confirme ses droits d’administrateur local sur le poste testé.

![Ouverture de session Windows avec Virat Kohli](./assets/13_Joined_Device_Local_Admin_role.png)
![Virat Kohli affiché comme administrateur dans Windows](./assets/14_Joined_Device_Local_Admin_role.png)
