# Inviter un utilisateur externe dans Microsoft Entra ID (B2B)

Dans ce lab, j’invite **John Doe** dans le tenant **Diarabaka**, puis je vérifie la création de son compte invité et l’état de son invitation.

## 1. Vérifier les paramètres de collaboration externe

Dans **Entra ID → External Identities → External collaboration settings**, je vérifie que l’accès des invités aux propriétés et aux appartenances des objets de l’annuaire est limité. Dans ce lab, l’envoi d’invitations est autorisé pour tous les utilisateurs du tenant, y compris les invités.

![Paramètres de collaboration externe du tenant Diarabaka](./assets/01.png)

## 2. Envoyer l’invitation

Dans **Entra ID → Users → All users**, je sélectionne **New user → Invite external user**.

![Ouverture du formulaire d’invitation B2B](./assets/02.png)

Je renseigne l’adresse externe et le nom d’affichage de **John Doe**, puis je laisse **Send invite message** coché et j’ajoute un message personnalisé.

![Adresse externe et message d’invitation](./assets/03.png)

Dans **Review + invite**, je vérifie les informations et le type **Guest**, puis je clique sur **Invite**.

![Vérification des informations avant l’envoi de l’invitation](./assets/04.png)

## 3. Vérifier le compte invité

Dans **All users**, **John Doe** apparaît avec le type **Guest** et le mode de création **Invitation**.

![Compte invité John Doe dans la liste des utilisateurs](./assets/05.png)

Sur sa fiche, la section **B2B invitation** affiche **Pending acceptance**. Le compte invité est créé et l’invitation attend encore d’être acceptée.

![Invitation B2B en attente d’acceptation](./assets/06.png)
