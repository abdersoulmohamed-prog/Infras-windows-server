# Exiger le MFA avec l’accès conditionnel dans Microsoft Entra ID

Dans le tenant de lab **Diarabaka**, je passe des paramètres de sécurité par défaut à l’accès conditionnel et j’active une stratégie MFA à partir d’un modèle Microsoft.

## 1. Passer à l’accès conditionnel

Dans **Entra ID → Overview → Properties → Manage security defaults**, je sélectionne **Disabled** et je coche l’option de remplacement par des stratégies d’accès conditionnel avant d’enregistrer.

![Passage des paramètres de sécurité par défaut à l’accès conditionnel](./assets/01_conditional_access.png)

## 2. Créer la stratégie MFA

Dans **Conditional Access → Policies**, je clique sur **New policy from template**.

![Ouvrir l’assistant de création d’une stratégie à partir d’un modèle](./assets/02_conditional_access.png)

Je sélectionne le modèle **Require multifactor authentication for all users**.

![Sélection du modèle MFA pour tous les utilisateurs](./assets/03_conditional_access.png)

Dans **Review + Create**, je règle **Policy state** sur **On**. La stratégie cible **All users** et exclut le compte actuellement connecté ainsi que le rôle **Directory Synchronization Accounts**. Je clique sur **Create**.

![État et exclusions de la stratégie MFA avant sa création](./assets/04_conditional_access.png)

## 3. Vérifier l’activation

Dans **Conditional Access → Policies**, la stratégie créée affiche **On**. La stratégie équivalente gérée par Microsoft, **Multifactor authentication for all users**, affiche **Off**.

![Stratégie MFA créée et activée dans la liste des stratégies](./assets/05_conditional_access.png)
