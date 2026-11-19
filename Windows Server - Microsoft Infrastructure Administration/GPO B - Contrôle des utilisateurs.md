# GPO B - Limiter les utilisateurs autorisés à se connecter à WIN11

Cette GPO permet de choisir précisément quels utilisateurs peuvent ouvrir une session sur un poste Windows.

```txt
            DC01 - Windows Server 2025

            GPO-WS-02-User-Logon

                 WIN11


Utilisateur autorisé : user-test01

Utilisateur non autorisé : user-test02

Administrateur local LAPS
```

---

## Étape 1 - Créer deux utilisateurs de test

Sur DC01 :

1. Ouvre `dsa.msc` (Active Directory Users and Computers).
2. Va dans `OU=Diarabaka > OU=Users` (si cette OU existe chez toi).
3. Clic droit → **New** → **User**.
4. Crée les deux comptes ci-dessous.

```txt
Nom 	        |Identifiant	  |  Rôle
----------------|-----------------|-------------------
User Test 01	|user-test01	  |  Autorisé
----------------|-----------------|-------------------
User Test 02	|user-test02	  |  Non autorisé
```

Définis des mots de passe de test conformes à la politique du domaine et active les comptes.

---

## Étape 2 - Créer le groupe de sécurité

Toujours sur DC01, dans dsa.msc :

1. Va dans `OU=Diarabaka > OU=Groups`.
2. Clic droit → **New** → **Group**.
3. Configure :

```txt
Propriété	 | Valeur
----------------------------------
Group name	 | GG-WS-WIN11-Logon
----------------------------------
Group scope	 | Global
----------------------------------
Group type	 | Security
```

---

## Étape 3 - Ajouter l'utilisateur autorisé

Ouvre le groupe `GG-WS-WIN11-Logon`.

Dans l'onglet **Members** :

1. Clique sur **Add**.
2. Ajoute uniquement `user-test01`.
3. Clique sur **Apply** → **OK**.

N'ajoute pas `user-test02`.

Vérifie avec PowerShell sur DC01 :

```PowerShell
Get-ADGroupMember "GG-WS-WIN11-Logon" |
    Select-Object Name, SamAccountName
```

---

## Étape 4 - Créer la GPO

Sur DC01 :

Ouvre `gpmc.msc`.

Dans `Group Policy Objects`, fais clic droit → **New**.

Nom :

```txt
GPO-WS-02-User-Logon
```

---

## Étape 5 - Configurer les connexions autorisées

Navigue vers :

```txt
Computer Configuration
 └── Policies
     └── Windows Settings
         └── Security Settings
             └── Local Policies
                 └── User Rights Assignment
```

Double-clique sur :

**Allow log on locally** (Autoriser l'ouverture de session locale).

Coche **Define these policy settings**.

Ajoute exactement ces groupes :

```txt
DIARABAKA\GG-WS-WIN11-Logon
BUILTIN\Administrators
```

Le second est le groupe Administrateurs intégré, qui permet notamment de conserver l'accès à l'administrateur local Windows LAPS. Sélectionne-le avec **Browse / Check Names**.

### Attention avant d'appliquer

N'ajoute pas `Domain Users, Users, Authenticated Users` ou `Everyone`, sinon les autres utilisateurs pourraient rester autorisés. Vérifie aussi que l'accès local LAPS fonctionne réellement depuis la console VMware.

Ce paramètre remplace la liste des groupes autorisés sur le poste cible, et une règle de refus de la GPO A reste [prioritaire](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-userrights)

---

## Étape 6 - Lier la GPO à WIN11

Dans `gpmc.msc` :

1. Va dans `OU=Diarabaka > OU=Workstations > OU=Workstations-Pilot`.
2. Vérifie que **WIN11** est bien dans cette OU, avec `Get-ADComputer WIN11 -Properties DistinguishedName`.
3. Clic droit sur `Workstations-Pilot`.
4. Choisis **Link an Existing GPO**.
5. Sélectionne `GPO-WS-02-User-Logon`.
6. Clique sur **OK**.

Tu dois maintenant avoir :

```txt
OU=Workstations-Pilot
    |
    +-- WIN11
    |
    +-- GPO-WS-01-Admin-Restriction
    |
    +-- GPO-WS-02-User-Logon
```

---

## Étape 7 - Appliquer la GPO sur WIN11

Depuis la console VMware de WIN11, ouvre PowerShell en administrateur.

```PowerShell
gpupdate /force
```

Ensuite :

```PowerShell
gpresult /r /scope computer
```

Vérifie que les deux GPO apparaissent :

```txt
GPO-WS-01-Admin-Restriction
GPO-WS-02-User-Logon
```

Pour consulter les droits effectifs, ouvre `secpol.msc` puis **Local Policies → User Rights Assignment → Allow log on locally**.

---

## Étape 8 - Tester les connexions

Garde un accès à la console VMware et vérifie d'abord que ton administrateur local LAPS peut ouvrir une session.

Ensuite, effectue les tests suivants.

```txt
Compte	                    |Résultat attendu
----------------------------|---------------------
DIARABAKA\user-test01	    |Connexion autorisée
----------------------------|---------------------
DIARABAKA\user-test02	    |Connexion refusée
----------------------------|---------------------
Domain Admin	            |Refus par GPO A
----------------------------|---------------------
Administrateur local LAPS	|Connexion autorisée
```

Pour chaque test, déconnecte complètement la session précédente. Utilise Other user pour saisir le compte suivant.

Pour que le refus de `user-test02` constitue une preuve fiable, vérifie que son compte est actif, que son mot de passe est correct et que DC02 ou DC01 est accessible. Un compte inexistant ou un mauvais mot de passe ne prouverait pas la restriction GPO.

---

## Étape 9 - Sauvegarder la GPO

Sur DC01 :

```PowerShell
New-Item C:\GPO-Backup -ItemType Directory -Force

Backup-GPO `
    -Name "GPO-WS-02-User-Logon" `
    -Path "C:\GPO-Backup"
```

En cas de blocage, utilise le compte administrateur local LAPS depuis VMware, puis retire le lien de la GPO sur DC01 et actualise les stratégies.

---

## Résultat

- les utilisateurs standards ne faisant pas partie du groupe ne peuvent plus ouvrir une session locale sur WIN11.
- Les administrateurs locaux restent une exception prévue pour l'administration et la récupération.

---

# Resumé

- La deuxième GPO limite les utilisateurs autorisés.

- J'ai créé un groupe Active Directory.
  - Seuls les membres de ce groupe peuvent se connecter au poste.
