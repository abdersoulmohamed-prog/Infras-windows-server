# Appareil joint ou enregistré dans Microsoft Entra ID

Dans ce lab, je joins une VM **Windows 10** au tenant **Diarabaka**, puis je compare son type de jointure à celui d’un appareil déjà enregistré.

| Type affiché dans Entra        | Usage sous Windows                                                                                                                                                                           |
| ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Microsoft Entra joined**     | L’appareil est joint à l’organisation. L’utilisateur peut ouvrir sa session Windows avec son compte professionnel.                                                                           |
| **Microsoft Entra registered** | Le compte professionnel est ajouté à une session Windows existante pour accéder aux ressources de l’organisation. L’utilisateur conserve son compte habituel pour ouvrir sa session Windows. |

## 1. Vérifier les paramètres du tenant

Depuis le tenant **Diarabaka**, j’ouvre **Entra ID → Devices → Device settings**. La jointure et l’enregistrement des appareils sont autorisés pour **All**.

![Vue d’ensemble du tenant Diarabaka](./assets/01.png)
![Jointure et enregistrement autorisés pour tous les utilisateurs](./assets/02.png)

## 2. Joindre la VM Windows 10

Dans **Settings → Accounts → Access work or school → Connect**, je sélectionne **Join this device to Microsoft Entra ID**. Je m’authentifie avec `bob.martin@diarabaka.com`.

![Sélection de la jointure Microsoft Entra ID dans Windows](./assets/03.png)
![Authentification avec le compte de Bob Martin](./assets/04.png)

Je vérifie que l’organisation affichée est `diarabaka.com`, puis je clique sur **Join**. Le message **You're all set!** confirme que l’appareil est connecté à **Diarabaka**.

![Confirmation de l’organisation avant la jointure](./assets/05.png)
![Jointure terminée dans Windows](./assets/06.png)

## 3. Vérifier la jointure

Je redémarre la VM, puis je me connecte à Windows avec le compte professionnel de Bob Martin. Dans **Access work or school**, Windows affiche **Connected to Diarabaka’s Entra ID**.

![Redémarrage de la VM Windows 10](./assets/07.png)
![Ouverture de session Windows avec le compte professionnel](./assets/08.png)
![Jointure à Diarabaka confirmée dans les paramètres Windows](./assets/09.png)

Dans **Entra ID → Devices → All devices**, la colonne **Join type** confirme que la VM de **Bob Martin** est **Microsoft Entra joined**. L’autre appareil, **Thierno**, apparaît comme **Microsoft Entra registered**.

![Comparaison des deux types de jointure dans All devices](./assets/10.png)
