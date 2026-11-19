# Créer et attribuer des attributs de sécurité personnalisés dans Microsoft Entra ID

Dans ce lab, je crée l’attribut `TMBProductionRole`, j’attribue la valeur `Learning system` à **Jean Martin**, puis je vérifie l’attribution avec un filtre.

## 1. Créer un ensemble d’attributs

Dans **Entra ID → Custom security attributes → Add attribute set**, je crée l’ensemble `TMBProduction` avec une limite de **10 attributs**.

![Création de l’ensemble d’attributs TMBProduction](./assets/01.png)

Je vérifie que `TMBProduction` apparaît dans la liste, puis je l’ouvre.

![Ensemble TMBProduction dans la liste des attributs personnalisés](./assets/02.png)

## 2. Définir l’attribut

Dans **Active attributes**, je clique sur **Add attribute**.

![Ajout d’un attribut dans l’ensemble TMBProduction](./assets/03.png)

Je crée `TMBProductionRole` avec le type **String**. L’attribut accepte une seule valeur, choisie parmi `Learning system`, `Script Writer` et `Learning network`. Je clique sur **Save**.

![Configuration de TMBProductionRole et de ses valeurs prédéfinies](./assets/04.png)

Je vérifie que `TMBProductionRole` apparaît dans **Active attributes**.

![Attribut TMBProductionRole dans la liste des attributs actifs](./assets/05.png)

## 3. Attribuer une valeur à Jean Martin

Dans **Entra ID → Users**, j’ouvre la fiche de **Jean Martin**, puis **Custom security attributes**.

![Accès aux attributs de sécurité personnalisés de Jean Martin](./assets/06.png)

Je clique sur **Add assignment** pour ajouter une attribution.

![Ajout d’une attribution sur le compte de Jean Martin](./assets/07.png)

Je sélectionne `TMBProductionRole` dans l’ensemble `TMBProduction`, je choisis `Learning system`, puis je clique sur **Save**.

![Valeur Learning system sélectionnée pour Jean Martin](./assets/08.png)

## 4. Vérifier l’attribution

Dans **All users → Add filter**, je sélectionne **Custom security attributes** et je filtre sur `TMBProductionRole` avec la valeur `Learning system`.

![Filtre sur la valeur Learning system de TMBProductionRole](./assets/09.png)

Le filtre renvoie un seul utilisateur, **Jean Martin**, ce qui confirme l’attribution.

![Jean Martin comme seul résultat du filtre](./assets/10.png)
