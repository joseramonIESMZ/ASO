# Estructuras de Control: Condicional If y Switch en PowerShell

## Introducción al condicional `If`

Las estructuras de control condicionales permiten que un script tome decisiones basadas en una o varias condiciones. En PowerShell, la estructura `If` lanza una serie de instrucciones si se cumple una condición determinada (es decir, su evaluación da como resultado `$true`). Para más información detallada, puedes consultar la ayuda interna mediante `Get-Help about_If`.

La sintaxis básica es:

```powershell
If ( condición ) {
    # Instrucciones que se ejecutan si la condición es verdadera
}
```

!!! tip "Truco: Evaluación directa de variables"
    Dado que PowerShell evalúa automáticamente todo lo que está dentro del paréntesis del `if` como un valor booleano (`$true` o `$false`), es muy común usar directamente una variable como condición: `if ($variable) { ... }`. Si la variable contiene texto, un número distinto de cero o un objeto, se evaluará como verdadero. Si está nula, vacía, o es un cero, se evaluará como falso.

### Ejemplo de `If` simple

```powershell
PS C:\> $nota = 5
PS C:\> if ( $nota -ge 5 ) {
>> Write-Host "Has aprobado, enhorabuena!"
>> }
Has aprobado, enhorabuena!
```

## Estructura `If...Else`

Se lanzan unas instrucciones si se cumple la condición, y otras instrucciones diferentes si no se cumple (es decir, si evalúa a `$false`).

La sintaxis es:

```powershell
If ( condición ) {
    # Instrucciones si se cumple la condición
} else {
    # Instrucciones si NO se cumple la condición
}
```

### Ejemplo de `If...Else`

```powershell
PS C:\> $nota = 3
PS C:\> if ( $nota -ge 5 ) {
>> Write-Host "Has aprobado, enhorabuena!"
>> } else {
>> Write-Host "Has suspendido, lástima!"
>> }
Has suspendido, lástima!
```

## Estructura `If...ElseIf...Else`

En el caso de que se quiera seguir comprobando más condiciones tras fallar la primera, se puede encadenar utilizando `elseif`.

La sintaxis es:

```powershell
If ( condición 1 ) {
    # Instrucciones si se cumple la condición 1
} elseif ( condición 2 ) {
    # Instrucciones si se cumple la condición 2 pero NO la condición 1
} else {
    # Instrucciones si no se cumplen ni la condición 1 ni la 2
}
```

### Ejemplo de múltiples condiciones

```powershell
PS C:\> $nota = 9
PS C:\> if ( $nota -lt 5 ) {
>> Write-Host "Has obtenido insuficiente"
>> } elseif ( $nota -lt 6 ) {
>> Write-Host "Has obtenido suficiente"
>> } elseif ( $nota -lt 7 ) {
>> Write-Host "Has obtenido bien"
>> } elseif ( $nota -lt 9 ) {
>> Write-Host "Has obtenido notable"
>> } elseif ( $nota -lt 10 ) {
>> Write-Host "Has obtenido sobresaliente"
>> } else {
>> Write-Host "Has obtenido matrícula de honor"
>> }
Has obtenido sobresaliente
```
## Operadores de Comparación

Para formular las condiciones, PowerShell utiliza operadores específicos de comparación (en lugar de los típicos `>`, `<`, `=` de otros lenguajes). 

Algunos de los operadores más utilizados son:

| Tipo | Operador | Descripción |
|---|---|---|
| **Equality** (Igualdad) | `-eq` | Igual a (*equals*) |
| | `-ne` | Diferente de (*not equals*) |
| | `-gt` | Mayor que (*greater than*) |
| | `-ge` | Mayor o igual que (*greater than or equal*) |
| | `-lt` | Menor que (*less than*) |
| | `-le` | Menor o igual que (*less than or equal*) |
| **Matching** (Coincidencia) | `-like` | Devuelve `$true` si la cadena coincide con un patrón usando comodines (`*`, `?`). |
| | `-notlike` | Devuelve `$true` si la cadena **no** coincide con el patrón. |
| | `-match` | Devuelve `$true` si la cadena coincide con una expresión regular (*regex*). |
| | `-notmatch`| Devuelve `$true` si la cadena **no** coincide con la expresión regular. |
| **Containment** (Contenido) | `-contains` | Devuelve `$true` si una colección contiene un valor de referencia específico. |
| | `-notcontains`| Devuelve `$true` si la colección **no** contiene el valor. |
| | `-in` | Devuelve `$true` si un valor de prueba se encuentra dentro de una colección. |
| | `-notin` | Devuelve `$true` si el valor **no** se encuentra en la colección. |
| **Replacement** (Reemplazo)| `-replace` | Reemplaza un patrón de cadena de texto por otro. |
| **Type** (Tipado) | `-is` | Devuelve `$true` si ambos objetos son del mismo tipo. |
| | `-isnot` | Devuelve `$true` si los objetos **no** son del mismo tipo. |

!!! warning "Atención: Mayúsculas y Minúsculas (Case Sensitivity)"
    Por defecto, los operadores de comparación en PowerShell **no distinguen** entre mayúsculas y minúsculas (ej. `"Hola" -eq "hola"` devuelve `$true`). Si necesitas realizar una comparación estricta que **sí** distinga mayúsculas, debes anteponer la letra **`c`** (*case-sensitive*) al operador original. Por ejemplo: `-ceq`, `-clike`, `-cmatch`.

### Operadores Lógicos

Además de comparar valores, a menudo necesitarás combinar o negar condiciones. Para ello, PowerShell cuenta con los siguientes operadores lógicos:

| Operador | Equivalente | Descripción | Ejemplo |
|---|---|---|---|
| `-and` | Y (AND) | Devuelve `$true` solo si **ambas** condiciones son verdaderas. | `if ($x -gt 5 -and $x -lt 10)` |
| `-or` | O (OR) | Devuelve `$true` si **al menos una** de las condiciones es verdadera. | `if ($x -eq 1 -or $x -eq 2)` |
| `-not` o `!` | NO (NOT) | Invierte el valor de la condición (de `$true` a `$false` y viceversa). | `if (-not ($x -eq 5))` o `if (!($x -eq 5))` |

> **Más información:** Se debe consultar la ayuda interna ejecutando `Get-Help about_Comparison_Operators` para más detalles. También puedes consultar el siguiente artículo oficial (en inglés/español): [Everything you wanted to know about the if statement](https://docs.microsoft.com/es-es/powershell/scripting/learn/deep-dives/everything-about-if?view=powershell-7.2).

## Estructura `Switch`

La estructura `switch` es una alternativa al uso encadenado de múltiples `if...elseif`. Es especialmente útil y conveniente cuando se evalúa una misma variable o expresión contra diferentes valores posibles. Esto hace que el código sea mucho más limpio, directo y fácil de leer.

La sintaxis básica es:

```powershell
switch ( valor_a_evaluar ) {
    condicion_1 { # Instrucciones si coincide con condicion_1 }
    condicion_2 { # Instrucciones si coincide con condicion_2 }
    default     { # Instrucciones si no coincide con nada (opcional) }
}
```

### Ejemplo de `Switch`

```powershell
$diaSemana = 3

switch ( $diaSemana ) {
    1 { Write-Host "Lunes" }
    2 { Write-Host "Martes" }
    3 { Write-Host "Miércoles" }
    4 { Write-Host "Jueves" }
    5 { Write-Host "Viernes" }
    6 { Write-Host "Sábado" }
    7 { Write-Host "Domingo" }
    default { Write-Warning "Número de día inválido" }
}
```

Como puedes ver, al usar `switch` no necesitas repetir la evaluación (p.ej. `$diaSemana -eq ...`) cada vez. Esta simplicidad es precisamente lo que hace muy recomendable y conveniente introducir el `switch` junto a `if`, ya que cubre los casos de uso donde `if...elseif` resulta excesivamente verboso.

## Ejemplo Práctico Integrado: Detener un Proceso

A continuación se muestra un script real (`DetenerProceso.ps1`) que combina el uso de parámetros de entrada con estructuras condicionales `If...Else` anidadas para detener de forma segura un proceso en memoria. Fíjate cómo usa la variable `$EnEjecucion` directamente como condición, tal como explicamos en el *Tip* inicial.

```powershell
# Script que detecta si un proceso está en memoria y lo detiene

Param(
    [Parameter(Mandatory,HelpMessage = 'Introduce el nombre del ejecutable.')][String]$Nombre
)

$EnEjecucion = Get-Process -Name $Nombre -ErrorAction SilentlyContinue

if ( $EnEjecucion ) {
    Write-Host "$Nombre está en ejecución. Procedemos a su parada ..."
    Stop-Process -InputObject $EnEjecucion
    Sleep 5
    if (!$EnEjecucion.HasExited) {
        $EnEjecucion | Stop-Process -Force
    }
    Write-Host "$Nombre parado correctamente."
} else {
    Write-Host "$Nombre no está en ejecución."
}
```

**Ejemplo de ejecución en consola:**

```powershell
PS C:\scripts\EjemplosVarios> help .\DetenerProceso.ps1
DetenerProceso.ps1 [-Nombre] <string> [<CommonParameters>]

PS C:\scripts\EjemplosVarios> .\DetenerProceso.ps1 -Nombre firefox
firefox está en ejecución. Procedemos a su parada ...
firefox parado correctamente.
PS C:\scripts\EjemplosVarios>
```

## Ejemplo Práctico 2: Case-Sensitivity (`-ceq`)

Observa cómo en este script (`ChequeaPassword.ps1`) se usa el operador `-ceq` para garantizar que la comprobación de la contraseña distinga obligatoriamente entre mayúsculas y minúsculas (lo que se conoce como *case-sensitive*).

```powershell
# Script que comprueba que la palabra introducida sea igual a secreta

Param(
    [Parameter(Mandatory,HelpMessage = 'Introduce palabra.')][string]$Palabra
)

$secreta = 'accesoPermitido'

if ( $Palabra -ceq $secreta ) {
    Write-Host "Palabra correcta. Puedes acceder."
} else {
    Write-Host "Palabra no correcta. No puedes acceder."
}
```

**Ejemplo de ejecución en consola:**

```powershell
PS C:\scripts\EjemplosVarios> .\ChequeaPassword.ps1

cmdlet ChequeaPassword.ps1 en la posición 1 de la canalización de comandos
Proporcione valores para los parámetros siguientes:
(Escriba !? para obtener Ayuda).
Palabra: accesoPermitido
Palabra correcta. Puedes acceder.
```

## Ejemplo Práctico 3: Chequeo de Fichero

Este script (`ExisteArchivo.ps1`) ilustra cómo pedir datos al usuario de forma interactiva con `Read-Host` y cómo aprovechar los cmdlets del sistema, como `Test-Path`. Al devolver `Test-Path` un resultado booleano (verdadero si la ruta existe, falso en caso contrario), podemos usarlo directamente como condición, resultando en un `if` muy limpio.

```powershell
# Comprueba si el archivo existe y en ese caso, muestra su contenido

$Archivo = Read-Host "Introduce el nombre con la ruta completa del archivo."

if ( Test-Path $Archivo ) {
    $datos = Get-Content $Archivo
    Write-Host "------- $Archivo ------- "
    $datos
    Write-Host "-------------------------"
}
else {
    Write-Warning "No se puede encontrar $Archivo."
}
```

**Ejemplo de ejecución en consola:**

```powershell
PS C:\scripts\EjemplosVarios> .\ExisteArchivo.ps1
Introduce el nombre con la ruta completa del archivo.: C:\scripts\logDC01.html
------- C:\scripts\logDC01.html ------- 
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>Informe del log de eventos</title>
<link rel="stylesheet" type="text/css" href="http://jdhitsolutions.com/sample.css" />
</head><body>
<H1>DC01</H1>
<table>
</table>
<h5>Informe generado el 09/16/2020 20:08:52</h5>
</body></html>
-------------------------
```

## Ejemplo Práctico 4: Menú de Opciones con Switch

Este script (`MenuOpciones.ps1`) ilustra cómo utilizar un `switch` para crear un pequeño menú interactivo. Es un caso de uso muy común donde se pide al usuario que elija una opción y se ejecuta una acción diferente según su elección.

```powershell
# Script que muestra un menú y utiliza switch para procesar la opción elegida

Write-Host "=== MENÚ PRINCIPAL ===" -ForegroundColor Cyan
Write-Host "1. Mostrar la fecha actual"
Write-Host "2. Mostrar la versión de PowerShell"
Write-Host "3. Salir"
Write-Host "======================" -ForegroundColor Cyan

$Opcion = Read-Host "Elige una opción (1-3)"

switch ($Opcion) {
    '1' {
        $fecha = Get-Date
        Write-Host "La fecha y hora actuales son: $fecha" -ForegroundColor Green
    }
    '2' {
        Write-Host "Versión de PowerShell:" -ForegroundColor Green
        $PSVersionTable.PSVersion
    }
    '3' {
        Write-Host "Saliendo del script. ¡Hasta luego!" -ForegroundColor Yellow
    }
    default {
        Write-Warning "Opción no válida. Por favor, elige 1, 2 o 3."
    }
}
```

**Ejemplo de ejecución en consola:**

```powershell
PS C:\scripts\EjemplosVarios> .\MenuOpciones.ps1
=== MENÚ PRINCIPAL ===
1. Mostrar la fecha actual
2. Mostrar la versión de PowerShell
3. Salir
======================
Elige una opción (1-3): 1
La fecha y hora actuales son: 11/08/2026 19:35:00
```

---

## 📚 Referencias y Fuentes Consultadas

!!! info "Documentación Oficial y Autoría"
    * **Material Base:** Presentación de clase *«PowerShell. Estructuras de control If»*.
    * **Autoría del Temario:** José Ramón Soria Nieto.
    * **Marco Curricular:** Programación didáctica para el módulo de *Administración de Sistemas Operativos (ASO)* del Ciclo Formativo de Grado Superior en *Administración de Sistemas Informáticos en Red (ASIR/ASIX)*.
    * **Documentación Oficial:** [Documentación oficial de PowerShell (Microsoft Learn)](https://learn.microsoft.com/es-es/powershell/)

!!! abstract "Cofinanciación y Soporte Institucional"
    * **Entidad Educativa:** Generalitat Valenciana — Conselleria d'Educació, Cultura i Esport.
    * **Fondo de Financiación:** Proyecto cofinanciado por la **Unión Europea** a través del **Fondo Social Europeo (FSE)**. 
    * *«El FSE invierte en tu futuro»* — Acciones orientadas al impulso de la educación, formación avanzada y preparación para el mercado laboral técnico.
