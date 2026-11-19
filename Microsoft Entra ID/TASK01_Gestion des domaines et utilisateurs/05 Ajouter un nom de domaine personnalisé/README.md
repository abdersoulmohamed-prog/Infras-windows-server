# Ajouter un domaine personnalisé dans Microsoft Entra ID

Le domaine `diarabaka.com` a été ajouté à Microsoft Entra ID, vérifié via le DNS public dans Cloudflare, puis défini comme domaine principal.

## 1. Ajouter le domaine

Dans **Domain names → Custom domain names**, je clique sur **Add custom domain**, je saisis `diarabaka.com`, puis je valide avec **Add domain**.

![Ajout de diarabaka.com dans Microsoft Entra ID](./assets/01.png)

## 2. Publier l’enregistrement TXT dans Cloudflare

Microsoft Entra ID fournit un enregistrement **TXT** pour vérifier que je contrôle le domaine. Le nom `@` correspond à la racine de `diarabaka.com`.

![Paramètres de l’enregistrement TXT fournis par Microsoft Entra ID](./assets/02.png)

Dans Cloudflare, j’ajoute le TXT à la zone DNS publique de `diarabaka.com` avec la valeur fournie par Microsoft.

![Enregistrement TXT ajouté dans Cloudflare](./assets/03.png)

## 3. Vérifier le domaine

Dans Microsoft Entra ID, `diarabaka.com` apparaît d’abord avec le statut **Unverified**.

![Domaine diarabaka.com en attente de vérification](./assets/04.png)

J’ouvre la fiche du domaine et je clique sur **Verify**. Microsoft recherche alors l’enregistrement TXT dans le DNS public.

![Lancement de la vérification DNS](./assets/05.png)

Le statut passe à **Verified**. À ce stade, `diarabaka.onmicrosoft.com` est encore le domaine principal.

![Diarabaka.com vérifié et domaine initial toujours principal](./assets/06.png)

## 4. Définir le domaine comme principal

Je sélectionne `diarabaka.com` dans la liste des domaines.

![Sélection du domaine vérifié diarabaka.com](./assets/07.png)

Sur sa fiche, je clique sur **Make primary**.

![Action Make primary sur la fiche du domaine](./assets/08.png)

Je confirme le changement en cliquant sur **Yes**.

![Confirmation du changement de domaine principal](./assets/09.png)

## Résultat

`diarabaka.com` affiche le statut **Verified** et la coche **Primary**. Le suffixe `@diarabaka.com` est désormais proposé par défaut lors de la création de nouveaux utilisateurs dans le portail Entra.

![Diarabaka.com vérifié et défini comme domaine principal](./assets/10.png)
