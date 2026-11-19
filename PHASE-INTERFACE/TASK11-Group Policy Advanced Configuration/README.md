# Group Policy Advanced Configuration

## Pour cibler uniquement Windows 11

La version ne suffit pas, car Windows 10 et Windows 11 utilisent tous deux 10.0.

Il faut utiliser le numéro de build, par exemple :

```sh
SELECT * FROM Win32_OperatingSystem
WHERE Version >= "10.0.22000"
```

- Windows 10 : builds inférieurs à 22000
- Windows 11 : builds 22000 et supérieurs
- Pour cibler Windows Server uniquement

## Tu peux utiliser le type de produit :

```sh
SELECT * FROM Win32_OperatingSystem
WHERE ProductType <> 1
```

- ProductType = 1 → Windows Client
- ProductType = 2 → Domain Controller
- ProductType = 3 → Member Server

---

![GPO Advenced](./assets/01.png)
![GPO Advenced](./assets/02.png)
![GPO Advenced](./assets/03.png)
![GPO Advenced](./assets/04.png)
![GPO Advenced](./assets/05.png)
![GPO Advenced](./assets/06.png)
![GPO Advenced](./assets/07.png)
![GPO Advenced](./assets/08.png)
![GPO Advenced](./assets/09.png)
![GPO Advenced](./assets/10.png)
![GPO Advenced](./assets/11.png)
![GPO Advenced](./assets/12.png)
![GPO Advenced](./assets/13.png)
![GPO Advenced](./assets/14.png)
![GPO Advenced](./assets/15.png)
![GPO Advenced](./assets/16.png)
![GPO Advenced](./assets/17.png)
![GPO Advenced](./assets/18.png)
![GPO Advenced](./assets/19.png)
![GPO Advenced](./assets/20.png)
![GPO Advenced](./assets/21.png)
![GPO Advenced](./assets/22.png)
![GPO Advenced](./assets/23.png)
![GPO Advenced](./assets/24.png)
