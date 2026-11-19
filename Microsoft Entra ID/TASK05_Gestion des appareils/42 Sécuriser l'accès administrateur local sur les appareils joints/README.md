# Sécuriser l’accès administrateur local sur les appareils joints à Microsoft Entra ID

Dans le tenant de lab **Diarabaka**, je limite l’ajout automatique d’administrateurs locaux lors de la jointure et je vérifie les droits de plusieurs comptes sur un poste Windows déjà joint.

## 1. Limiter les droits accordés lors de la jointure

Sur le poste Windows, je relève la composition du groupe local **Administrators**. **Bob Martin** y figure déjà.

![Membres du groupe Administrators avant le test](./assets/01.png)

Dans **Entra ID → Devices → Device settings → Local administrator settings**, je règle l’ajout du rôle **Global Administrator** sur **No**. Pour l’utilisateur qui effectue la jointure, je choisis **Selected** et je sélectionne **David Warner**.

![Paramètres d’ajout automatique des administrateurs locaux](./assets/02.png)
![Sélection de David Warner](./assets/03.png)
![Configuration avec un utilisateur sélectionné](./assets/04.png)

## 2. Vérifier l’accès avec Marie Dubois

J’ajoute le compte professionnel de **Marie Dubois** dans **Email & accounts**, puis je redémarre le poste et j’ouvre une session Windows avec son compte.

![Connexion avec le compte professionnel de Marie Dubois](./assets/05.png)
![Confirmation de l’ajout du compte professionnel](./assets/06.png)
![Redémarrage du poste Windows](./assets/07.png)
![Ouverture de session Windows avec Marie Dubois](./assets/08.png)

Le groupe local **Administrators** affiche les mêmes entrées qu’au début du test. Dans la session de Marie, **Access work or school** demande un compte administrateur pour modifier les paramètres de gestion de l’appareil.

![Liste des administrateurs locaux après le test](./assets/09.png)
![Modification des paramètres de gestion réservée aux administrateurs](./assets/10.png)

## 3. Attribuer le rôle d’administrateur local à Test User

Depuis **Device settings**, j’ouvre **Manage Additional local administrators on all Microsoft Entra joined devices**. Dans **Device Administrators → Add assignments**, j’ajoute **Test User**. L’attribution apparaît avec la portée **Directory**.

![Accès à la gestion des administrateurs locaux supplémentaires](./assets/11.png)
![David Warner dans la liste des utilisateurs sélectionnés pour la jointure](./assets/12.png)
![Attribution du rôle Device Administrators à Test User](./assets/13.png)
![Attribution confirmée avec la portée Directory](./assets/14.png)

## 4. Comparer les droits dans Windows

J’ajoute le compte professionnel de **David Warner**, puis j’ouvre une session avec ce compte sur le poste déjà joint. Son nom n’apparaît pas dans le groupe local **Administrators** et son profil Windows n’affiche pas la mention **Administrator**.

![Ajout du compte professionnel de David Warner](./assets/15.png)
![Ouverture de session Windows avec David Warner](./assets/16.png)
![Groupe Administrators sur le poste de test](./assets/17.png)
![Profil Windows de David Warner](./assets/18.png)

Le profil Windows de **Test User** affiche **Administrator**. Le portail Entra confirme son attribution au rôle **Device Administrators** à l’échelle de l’annuaire.

![Test User affiché comme administrateur dans Windows](./assets/19.png)
![Attribution du rôle Device Administrators confirmée dans Entra](./assets/20.png)
