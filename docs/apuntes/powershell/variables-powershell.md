# Variables en PowerShell

Las variables son un recurso de programación que nos permite asignar un nombre a un dato que pasará a estar cargado en memoria para su posterior uso.

El formato básico para definir una variable es:
```powershell
$nombrevariable = valor
```

Para ver el valor de una variable, basta con escribir su nombre: `$nombrevariable`.

## Nomenclatura y Tipos de Datos

El **nombre de la variable**:

- Puede contener caracteres alfanuméricos (letras y números) y caracteres especiales. No obstante, se recomienda no utilizar caracteres especiales o limitarse al guion bajo (`_`).
- No distingue entre mayúsculas y minúsculas (ej. `$NOMBRE` es interpretado igual que `$nombre`).

El **valor** puede ser de los siguientes tipos:

- Números (`int32`, `int64`), cadenas de texto (`string`), un conjunto o array de datos numéricos o cadenas de texto, o cualquier objeto devuelto por los cmdlets.

Ejemplos de asignaciones:
```powershell
$numero = 12
$palabra = "Word"
$varMatriz = 12, "Word"
$ficheros = Get-ChildItem "C:\Windows"
$procesos = Get-Process
```

## Forzar el Tipo de Dato

Las variables pueden crearse especificando el tipo de dato para forzar a que sean exclusivamente de ese tipo durante la sesión. Si posteriormente se intenta asignar un valor de otro tipo de dato, PowerShell devolverá un error.

```powershell
[int]$numero = 10
# $numero = "Hola" devolvería un error de conversión

[string]$palabra = "Hola"
# $palabra += 10 no dará error, pero lo concatenará como texto en vez de sumar

[datetime]$fecha = "09/12/2023"
# Permite extraer propiedades como $fecha.Year
```

## Categorías de Variables

PowerShell define diferentes categorías de variables:

- **Variables estáticas (Constantes):** Por ejemplo, `[Math]::PI`.
- **Variables de instancia:** Por ejemplo, `$fecha.Month`.
- **Elementos de matriz:** Por ejemplo, `$valores[2]`.
- **Pares clave-valor de tabla hash (Hashtable):** Por ejemplo, `$tablaHash.FirstName` o su equivalente `$tablaHash['FirstName']`.
- **Variables normales:** Las variables estándar que creamos, como `$radio`, `$circunferencia`, `$fecha`, `$mes`, `$valores` o `$tablaHash`.
- **Variables en unidades de proveedor:** Variables asociadas a providers específicos, por ejemplo, `$Alias:ls`, `$Env:MyPath`, `${D:output.txt}` y `$function:F`.

Ejemplos de categorías de variables:
```powershell
$radio = 2.45
$circunferencia = $radio * 2 * [Math]::PI
$fecha = Get-Date -Date "20/04/2025 14:40"
$mes = $fecha.Month
$dia = $fecha.Day
$valores = 10, 55, 93, 102
$tablaHash = @{FirstName = "Juan"; LastName = "Pérez"; Age = 25}
$tablaHash.FirstName
$tablaHash['FirstName']
$alias:ls
$env:COMPUTERNAME
```

## Consultar Variables

- **`Get-Variable`**: Permite ver todas las variables creadas en la sesión actual de PowerShell.

## Variables de Entorno

Existen variables predefinidas en el shell, denominadas **variables de entorno**, que contienen valores asignados automáticamente por el sistema y que están disponibles a nivel de máquina, usuario y sesión.

- Para consultarlas y utilizarlas, comienzan siempre con **`$env:`** (por ejemplo, `$env:COMPUTERNAME`).
- Para listar todas las variables del proveedor `Env:`:
```powershell
Get-Item -Path Env:
```

---

## 📚 Referencias y Fuentes Consultadas

!!! info "Documentación Oficial y Autoría"
    * **Material Base:** Presentación de clase *«PowerShell. Variables»*.
    * **Autoría del Temario:** José Ramón Soria Nieto.
    * **Marco Curricular:** Programación didáctica para el módulo de *Administración de Sistemas Operativos (ASO)* del Ciclo Formativo de Grado Superior en *Administración de Sistemas Informáticos en Red (ASIR/ASIX)*.
    * **Documentación Oficial:** [Documentación oficial de PowerShell (Microsoft Learn)](https://learn.microsoft.com/es-es/powershell/)

!!! abstract "Cofinanciación y Soporte Institucional"
    * **Entidad Educativa:** Generalitat Valenciana — Conselleria d'Educació, Cultura i Esport.
    * **Fondo de Financiación:** Proyecto cofinanciado por la **Unión Europea** a través del **Fondo Social Europeo (FSE)**. 
    * *«El FSE invierte en tu futuro»* — Acciones orientadas al impulso de la educación, formación avanzada y preparación para el mercado laboral técnico.
