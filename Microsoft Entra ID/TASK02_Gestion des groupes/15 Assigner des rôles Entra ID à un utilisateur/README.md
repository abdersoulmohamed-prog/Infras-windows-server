# Attribuer un rôle Microsoft Entra ID à un utilisateur

Dans ce lab, j’attribue le rôle **Attribute Assignment Administrator** à **Thierno Barry**, puis je vérifie l’attribution depuis le rôle et depuis la fiche utilisateur.

## 1. Sélectionner le rôle

Depuis la vue d’ensemble du tenant **Diarabaka**, j’ouvre **Entra ID → Roles and administrators**.

![Vue d’ensemble du tenant Diarabaka](./assets/01.png)

Dans **All roles**, je sélectionne **Attribute Assignment Administrator**. Ce rôle permet d’attribuer des valeurs d’attributs de sécurité personnalisés aux objets Microsoft Entra pris en charge.

![Rôle Attribute Assignment Administrator dans la liste des rôles](./assets/02.png)

## 2. Attribuer le rôle

Dans **Assignments → Add assignments**, j’ajoute **Thierno Barry**. La liste des attributions affiche son compte avec la portée **Directory**.

![Attribution du rôle à Thierno Barry au niveau de l’annuaire](./assets/03.png)

## 3. Vérifier l’attribution depuis le compte

Dans **Entra ID → Users → All users**, j’ouvre la fiche de **Thierno Barry**.

![Sélection du compte Thierno Barry](./assets/04.png)

Dans **Assigned roles**, je vérifie que **Attribute Assignment Administrator** apparaît avec le mode **Direct**. La fiche affiche aussi les rôles **Attribute Definition Administrator** et **Global Administrator**.

![Attribution directe du rôle confirmée dans Assigned roles](./assets/05.png)
