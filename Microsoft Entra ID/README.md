```sh
Install-Module Microsoft.Graph -Scope CurrentUser
```

- Installation du module Graph.

```sh
Connect-MgGraph -Scopes "Organization.ReadWriteAll"
```

- Connexion à ton tenant Entra.
  - Vérification :

```sh
Get-MgOrganization | Select-Object OnPremisesSyncEnabled
```

- Avant : `OnPremisesSyncEnabled : True`

- Désactivation :

```sh
$org = Get-MgOrganization

Update-MgOrganization `
    -OrganizationId $org.Id `
    -OnPremisesSyncEnabled:$false
```

- Vérification :

```sh
Get-MgOrganization | Format-List OnPremisesSyncEnabled
```

- Maintenant :

```sh
OnPremisesSyncEnabled :
```

---

```sh
Import-Module .\AzureADSSO.psd1
New-AzureADSSOAuthenticationContext
Get-AzureADSSOStatus

---

Disable-AzureADSSOForest
```

----------------------------

```sh
$org = Get-MgOrganization

$org | Format-List Id,DisplayName,OnPremisesSyncEnabled
```

```sh
Update-MgOrganization `
    -OrganizationId $org.Id `
    -OnPremisesSyncEnabled:$false
```

```sh
Get-MgOrganization |
Format-List DisplayName,OnPremisesSyncEnabled
```

```sh
Get-MgContext | Select-Object Account,Scopes
```

