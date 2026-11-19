# Exécuter les scripts Microsoft Entra ID

## 1. Vérifier la version de PowerShell

Ouvre **PowerShell 7** (`pwsh`). Les scripts demandent **PowerShell 7.2 ou ultérieur**.

```powershell
$PSVersionTable.PSVersion
```

## 2. Installer le module Microsoft Graph

À faire une seule fois sur le poste depuis lequel tu lances les scripts.

```powershell
Install-Module Microsoft.Graph.Authentication -Scope CurrentUser
```

## 3. Tester la connexion au tenant

Décompresse le ZIP et ouvre PowerShell dans le dossier qui contient `scripts`. Dans le portail Microsoft Entra, copie le **Tenant ID** depuis **Entra ID → Overview**.

```powershell
$TenantId = 'COLLE-ICI-LE-GUID-DU-TENANT'

.\scripts\Tenant\Get-TenantInformation.ps1 -TenantId $TenantId
```

Connecte-toi avec ton compte professionnel du lab. Les informations du tenant **Diarabaka** doivent s’afficher.

## 4. Lister les utilisateurs et exporter le rapport MFA

Garde la même fenêtre PowerShell pour réutiliser `$TenantId`.

```powershell
.\scripts\Users\Get-EntraUsers.ps1 -TenantId $TenantId

.\scripts\Authentication\Get-MFAStatus.ps1 `
    -TenantId $TenantId `
    -OutputPath '.\mfa-status.csv'
```

Le rapport est créé dans le dossier courant. Si `mfa-status.csv` existe déjà, choisis un autre nom de fichier. Tu peux ensuite tester les rapports dans cet ordre **appareils → groupes → rôles → accès conditionnel → journaux de connexion**.

## Exemple de rapport `mfa-status.csv`

Les quatre comptes ci-dessous sont fictifs.

```csv
"Id","UserPrincipalName","DisplayName","IsMfaRegistered","IsMfaCapable","IsPasswordlessCapable","MethodsRegistered"
"00000000-0000-4000-8000-000000000001","alice.dupont@example.com","Alice Dupont","True","True","False","microsoftAuthenticatorPush"
"00000000-0000-4000-8000-000000000002","bob.martin@example.com","Bob Martin","True","True","True","fido2;microsoftAuthenticatorPush"
"00000000-0000-4000-8000-000000000003","marie.dubois@example.com","Marie Dubois","False","False","False",""
"00000000-0000-4000-8000-000000000004","jean.martin@example.com","Jean Martin","True","False","False","mobilePhone"
```

`IsMfaRegistered` indique si une méthode MFA est enregistrée. `IsMfaCapable` indique si une méthode MFA enregistrée est autorisée par la stratégie du tenant. Pour vérifier le MFA lors d’une connexion précise, consulte **Sign-in logs → Authentication details**.
