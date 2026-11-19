# GPO A - Restriction des connexions administrateurs sur les Workstations

**Objectif :** empêcher les membres de Domain Admins et Enterprise Admins d'ouvrir une session sur WIN11, tout en conservant l'accès des utilisateurs standards et de l'administrateur local Windows LAPS.

## 1. Architecture cible

```txt
                            DC01 - Windows Server 2025

                        Active Directory . Group Policy Management

                                GPO-WS-01-Admin-Restriction

                                OU=Workstations-Pilot

                                    WIN11


Domain Admins: Refusé

Enterprise Admins: Refusé

Utilisateur standard: Autorisé

Administrateur local LAPS: Autorisé
```

---

## 2. Étape 1 - Vérifier WIN11 dans Active Directory

Sur **DC01**, ouvre PowerShell en administrateur :

```PowerShell
Get-ADComputer -Identity "WIN11" |
    Select-Object Name, DistinguishedName
```

- Si WIN11 est dans `OU=Workstations`, crée une OU pilote en dessous, pour ne pas toucher aux autres postes.

```PowerShell
New-ADOrganizationalUnit `
    -Name "Workstations-Pilot" `
    -Path "OU=Workstations,OU=Diarabaka,DC=diarabaka,DC=com"
```

Déplace uniquement WIN11 dans cette OU, depuis Utilisateurs et ordinateurs Active Directory (`dsa.msc`).

Vérifie :

```PowerShell
Get-ADComputer "WIN11" |
    Select-Object DistinguishedName
```

---

## 3. Étape 2 - Créer la GPO

Sur DC01 :

1. Appuie sur `Windows + R`.
2. Saisis `gpmc.msc`.
3. Développe `Forest: diarabaka.com`.
4. Développe `Domains > diarabaka.com`.
5. Clic droit sur **Group Policy Objects**.
6. Sélectionne **New**.

Nom de la GPO :

```txt
GPO-WS-01-Admin-Restriction
```

---

## 4. Étape 3 - Bloquer les connexions locales

Dans `gpmc.msc` :

1. Clic droit sur `GPO-WS-01-Admin-Restriction`.
2. Clique sur **Edit**.
3. Accède au chemin suivant :

```txt
Computer Configuration
 └── Policies
     └── Windows Settings
         └── Security Settings
             └── Local Policies
                 └── User Rights Assignment
```

Ouvre :

**Deny log on locally** (Refuser l'ouverture de session locale).

Coche **Define these policy settings**, puis clique sur **Add User or Group**.

Ajoute ces deux groupes en utilisant **Check Name**s :

```txt
DIARABAKA\Domain Admins
DIARABAKA\Enterprise Admins
```

`Dans le domaine à forêt unique, ces groupes sont normalement disponibles. Ne sélectionne pas le groupe général Administrators, car cela pourrait également bloquer ton administrateur local LAPS.`

Cette restriction correspond aux recommandations [Microsoft pour protéger les comptes privilégiés](https://learn.microsoft.com/en-gb/windows-server/identity/ad-ds/plan/security-best-practices/appendix-f--securing-domain-admins-groups-in-active-directory?utm_source=chatgpt.com).

---

## 5. Étape 4 - Bloquer les connexions RDP

Toujours dans **User Rights Assignment**, ouvre :

**Deny log on through Remote Desktop Services** (Refuser l'ouverture de session par les Services Bureau à distance).

Coche **Define these policy settings**.

Ajoute les mêmes groupes :

```txt
DIARABAKA\Domain Admins
DIARABAKA\Enterprise Admins
```

Ainsi, les membres de ces groupes ne pourront pas ouvrir de session RDP sur le poste ciblé, même si RDP est activé.

---

## 6. Étape 5 - Lier la GPO à WIN11

Retourne dans `gpmc.msc`.

1. Développe `diarabaka.com`.
2. Ouvre `OU=Diarabaka > OU=Workstations`.
3. Clic droit sur `OU=Workstations-Pilot`.
4. Choisis **Link an Existing GPO**.
5. Sélectionne `GPO-WS-01-Admin-Restriction`.
6. Clique sur **OK**.

Vérifie que le lien GPO est activé.

**Attention** : la GPO doit être liée uniquement à `Workstations-Pilot`. Ne la lie pas au domaine entier ou à l'OU contenant les serveurs.

---

## 7. Étape 6 - Appliquer la GPO sur WIN11

Sur WIN11, ouvre PowerShell en administrateur :

```PowerShell
gpupdate /force
```

Vérifie ensuite les GPO appliquées :

```PowerShell
gpresult /r /scope computer
```

Tu dois retrouver :

```txt
GPO-WS-01-Admin-Restriction
```

Génère également un rapport HTML :

```PowerShell
gpresult /h C:\Windows\Temp\GPO-Admin-Restriction.html
```

Ouvre ce fichier pour vérifier les paramètres appliqués. Tu peux aussi utiliser `secpol.msc` sur WIN11 pour inspecter les droits de connexion effectifs.

---

## 8. Étape 7 - Tester les restrictions

Effectue ces tests depuis la console VMware, après avoir vérifié la possibilité de récupération avec LAPS.

```txt
Test                                | Résultat attendu
-------------------------------------------------------------------
Compte utilisateur standard	        | Connexion réussie
-------------------------------------------------------------------
Compte Domain Admin	                | Connexion locale refusée
-------------------------------------------------------------------
Compte Enterprise Admin	            | Connexion locale refusée
-------------------------------------------------------------------
Compte administrateur local LAPS	| Connexion réussie
-------------------------------------------------------------------
Domain Admin par RDP	            | Connexion refusée
```

Pour le test RDP, le poste doit disposer de Windows 11 Pro ou Enterprise et accepter normalement les connexions RDP. Sinon, un refus de connexion ne prouve pas que la GPO fonctionne.

Tu peux examiner les échecs d'authentification dans les événements de sécurité Windows, notamment l'événement `4625` si l'audit des échecs de connexion est activé.

---

## 9. Étape 8 - Sauvegarder la GPO

Sur DC01 :

```PowerShell
New-Item C:\GPO-Backup -ItemType Directory -Force

Backup-GPO `
    -Name "GPO-WS-01-Admin-Restriction" `
    -Path "C:\GPO-Backup"
```

Si tu dois annuler le test, retire le lien GPO de l'OU pilote, exécute `gpupdate /force` sur WIN11, puis reconnecte-toi. Ne supprime pas la GPO avant d'avoir confirmé le retour à une configuration utilisable.

---

## Résultat

- WIN11 reçoit la stratégie.

- Domain Admins et Enterprise Admins ne peuvent plus ouvrir de session locale ni RDP.

- L'utilisateur standard conserve son accès.

- L'administrateur local LAPS reste utilisable.

---

# Resumé

- La première GPO bloque les connexions des administrateurs du domaine.
  - Cela permet de protéger les comptes sensibles
