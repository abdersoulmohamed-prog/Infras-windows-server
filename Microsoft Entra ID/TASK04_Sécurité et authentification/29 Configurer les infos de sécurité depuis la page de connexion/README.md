# Configurer les informations de sécurité à la connexion dans Microsoft Entra ID

Dans ce lab, j’enregistre **Microsoft Authenticator** comme méthode MFA pour le compte de test, puis je vérifie son inscription côté utilisateur et côté administrateur.

## 1. Préparer la connexion

Dans le centre d’administration Microsoft Entra, je réinitialise le mot de passe de **Test User** pour obtenir un mot de passe temporaire.

![Réinitialisation du mot de passe du compte de test](./assets/01.png)

Je me connecte avec `test.user@diarabaka.com` et le mot de passe temporaire.

![Connexion avec le compte de test](./assets/02.png)

## 2. Enregistrer Microsoft Authenticator

À l’invite **Scan the QR code**, je scanne le code avec l’application **Microsoft Authenticator**, puis je clique sur **Next**.

![Écran d’inscription à Microsoft Authenticator](./assets/03.png)

Le message **Authenticator Added** confirme l’inscription de l’application comme méthode de connexion par défaut.

![Confirmation de l’ajout de Microsoft Authenticator](./assets/04.png)

Sur l’écran **Update your password**, je remplace le mot de passe temporaire par un nouveau mot de passe.

![Changement du mot de passe temporaire](./assets/05.png)

## 3. Vérifier l’inscription

Dans **Mon compte → Security info**, je retrouve **Microsoft Authenticator** comme méthode MFA par notification.

![Microsoft Authenticator dans les informations de sécurité du compte](./assets/06.png)

Dans **Entra ID → Users → Test User → Authentication methods**, je vérifie que **Microsoft Authenticator** figure parmi les méthodes utilisables et que **PhoneAppNotification** est la méthode MFA préférée par le système.

![Méthode Microsoft Authenticator confirmée dans le centre d’administration](./assets/07.png)
