# Gestion avancée des groupes dans Microsoft Entra ID

Dans ce lab, je teste la création de groupes en libre-service, je contrôle l’accès à **My Groups** et je vérifie l’application d’une convention de nommage aux groupes Microsoft 365.

## 1. Créer un groupe Microsoft 365 en libre-service

Avec le compte de **David Warner**, j’ouvre **My Groups → Overview** et je clique sur **Create M365 Group**.

![Création d’un groupe Microsoft 365 depuis My Groups](./assets/01.png)

Je saisis `TMB-M365Group1` et je choisis la visibilité **Public**. Le formulaire ajoute le préfixe `Belgium-` et le suffixe `-IT Infrastructure`.

![Formulaire avec le préfixe et le suffixe appliqués](./assets/02.png)

La fiche confirme la création de `Belgium-TMB-M365Group1-IT Infrastructure` et indique que les utilisateurs peuvent rejoindre le groupe.

![Nom final et politique d’adhésion du groupe Microsoft 365](./assets/03.png)

## 2. Contrôler l’adhésion à un groupe de sécurité

Dans **Groups I own**, je clique sur **Create Group** et je sélectionne **Control Access**.

![Création d’un groupe depuis Groups I own](./assets/04.png)
![Sélection du type de groupe de sécurité](./assets/05.png)

Je crée `TMB-SecGroup1` avec une politique qui exige l’approbation du propriétaire.

![Configuration initiale du groupe TMB-SecGroup1](./assets/06.png)

Je modifie ensuite la politique pour que seuls le propriétaire et les administrateurs puissent ajouter des membres. La fiche du groupe confirme le changement.

![Modification de la politique d’adhésion](./assets/07.png)
![Politique d’adhésion enregistrée](./assets/08.png)

Depuis **Add member**, j’ajoute **Jean Martin**. L’onglet **Members** confirme son ajout et l’onglet **Owners** affiche **David Warner** comme propriétaire.

![Ouverture de l’action Add member](./assets/09.png)
![Sélection de Jean Martin comme membre](./assets/10.png)
![Jean Martin dans la liste des membres](./assets/11.png)
![David Warner dans la liste des propriétaires](./assets/12.png)

## 3. Tester les restrictions de My Groups

Dans **Entra ID → Groups → General**, j’active la restriction d’accès à **My Groups** et je désactive la gestion des demandes d’adhésion par les propriétaires. Avec le compte de David, le portail affiche **My Groups is restricted by your organization**.

![Restriction d’accès à My Groups activée](./assets/13.png)
![Message de restriction affiché pour David Warner](./assets/14.png)

Je désactive la restriction d’accès. Les boutons de création des deux types de groupes réapparaissent.

![Restriction d’accès à My Groups désactivée](./assets/15.png)
![Boutons de création Microsoft 365 et Security visibles](./assets/16.png)

Je désactive ensuite les deux options de création. Sur le compte de test, les boutons de création ne s’affichent plus. David peut toujours consulter les groupes dont il est propriétaire et ouvrir la liste des membres de `TMB-SecGroup1`.

![Création des deux types de groupes désactivée](./assets/17.png)
![Vue My Groups sans boutons de création](./assets/18.png)
![Groupes existants visibles dans Groups I own](./assets/19.png)
![Liste des membres de TMB-SecGroup1 toujours accessible](./assets/20.png)

## 4. Autoriser uniquement la création de groupes Microsoft 365

Je réactive la création des groupes **Microsoft 365** et je laisse celle des groupes de sécurité sur **No**.

![Création Microsoft 365 autorisée et création Security désactivée](./assets/21.png)

J’ouvre [My Apps](https://myapps.microsoft.com/) en navigation privée, puis je me connecte avec le compte de David et je valide la demande dans Microsoft Authenticator.

![Ouverture de My Apps en navigation privée](./assets/22.png)
![Connexion avec le compte de David Warner](./assets/23.png)
![Demande de validation dans Microsoft Authenticator](./assets/24.png)

Dans **My Groups**, seul le bouton **Create M365 Group** est visible.

![Seule l’option de création Microsoft 365 est affichée](./assets/25.png)

## 5. Vérifier la convention de nommage

Dans **Groups → Naming policy**, la règle suit le format `<CountryOrRegion>-<Group name>-<Department>`. Le préfixe et le suffixe proviennent du profil du créateur.

![Règle de nommage basée sur le pays et le service](./assets/26.png)

Avec le compte de David, je saisis `AdminSystem`. La fiche du groupe confirme le nom **Belgium-AdminSystem-IT Infrastructure**.

![Création du groupe AdminSystem avec le préfixe et le suffixe](./assets/27.png)
![Nom complet confirmé dans la fiche du groupe](./assets/28.png)

Je retrouve le groupe sous ce même nom dans **Groups I own** côté utilisateur et dans **All groups** côté administration.

![Groupe visible dans Groups I own](./assets/29.png)
![Groupe confirmé dans All groups](./assets/30.png)
