# Créer et gérer une unité administrative dans Microsoft Entra ID

Dans le tenant **Diarabaka**, je crée l’unité administrative **ITSystemAdmin**, je teste l’ajout manuel puis l’appartenance dynamique, et je délègue un rôle limité à cette unité.

## 1. Créer l’unité administrative

Dans **Entra ID → Roles and administrators → Admin units**, je clique sur **Add**. Je saisis le nom **ITSystemAdmin** et sa description, puis je laisse **Restricted management administrative unit** sur **No**.

![Ouverture de la création d’une unité administrative](./assets/01.png)
![Configuration de l’unité ITSystemAdmin](./assets/02.png)

Dans **Review + create**, je clique sur **Create**. La liste confirme la création de l’unité avec le type d’appartenance **Assigned**.

![Récapitulatif avant la création](./assets/03.png)
![ITSystemAdmin dans la liste des unités administratives](./assets/04.png)

## 2. Ajouter des membres manuellement

Depuis **ITSystemAdmin**, j’ajoute **David Warner** dans **Users** et **SG-IT-Admins** dans **Groups**.

![Sélection de David Warner dans Users](./assets/05.png)
![Sélection du groupe SG-IT-Admins dans Groups](./assets/06.png)

Les deux captures suivantes illustrent la sélection d’un appareil depuis **Devices → Add device** dans l’unité **CricketAustralia**, sur un autre tenant.

![Onglet Devices de l’unité CricketAustralia](./assets/07.png)
![Sélection d’un iPhone XS Max dans l’exemple](./assets/08.png)

Dans **Diarabaka**, j’ajoute aussi **Rama Barry** depuis sa fiche utilisateur, via **Administrative units → Assign to administrative unit**.

![Sélection d’ITSystemAdmin depuis la fiche de Rama Barry](./assets/09.png)

## 3. Configurer l’appartenance dynamique

Dans **ITSystemAdmin → Properties**, je sélectionne **Dynamic User**, puis **Add dynamic query**. J’enregistre la règle `(user.country -eq "Belgium")` pour cibler les utilisateurs dont le champ **Country** vaut `Belgium`.

![Sélection du type Dynamic User](./assets/10.png)
![Règle d’appartenance dynamique basée sur le pays](./assets/11.png)
![Type Dynamic User affiché dans les propriétés de l’unité](./assets/12.png)

## 4. Déléguer un rôle à l’échelle de l’unité

Dans **ITSystemAdmin → Roles and administrators**, j’ouvre le rôle **User Administrator**. La liste **Assignments** affiche **Rama Barry** avec la portée **This resource**, ce qui confirme que l’attribution est limitée à **ITSystemAdmin**.

![Rôle User Administrator dans ITSystemAdmin](./assets/13.png)
![Rama Barry avec le rôle User Administrator limité à l’unité](./assets/14.png)
