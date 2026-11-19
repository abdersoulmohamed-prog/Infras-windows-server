# Créer des utilisateurs en masse via CSV dans Microsoft Entra ID

Dans ce lab, je crée cinq comptes de test dans le domaine `diarabaka.com` à partir d’un seul fichier CSV.

## 1. Télécharger le modèle CSV

Dans **Entra ID → Users → All users**, je sélectionne **Bulk operations → Bulk create (Preview)**.

![Ouverture de la création d’utilisateurs en masse](./assets/01.png)

Dans le panneau **Bulk create users**, je clique sur **Download** pour récupérer le modèle CSV.

![Téléchargement du modèle CSV](./assets/02.png)

## 2. Préparer et importer le fichier

Je conserve la ligne de version et les en-têtes du modèle. J’ajoute une ligne par utilisateur avec son nom d’affichage, son identifiant de connexion (UPN), son mot de passe initial et l’état du compte.

![Fichier CSV complété pour cinq utilisateurs](./assets/03.png)

Dans **Bulk create users**, je sélectionne le fichier `bulk-user-creation.csv`.

![Sélection du fichier CSV à importer](./assets/04.png)

Le message **File uploaded successfully** confirme que le fichier a été téléversé.

![Confirmation du téléversement du fichier CSV](./assets/05.png)

## 3. Vérifier la création des comptes

Dans **Bulk operation results (Preview)**, l’opération **Create Users** affiche le statut **Succeeded**.

![Opération de création en masse terminée avec succès](./assets/06.png)

Dans **All users**, je retrouve les cinq nouveaux comptes au milieu des deux comptes existants. La liste affiche désormais **7 utilisateurs**.

![Les cinq comptes importés apparaissent dans la liste des utilisateurs](./assets/07.png)
