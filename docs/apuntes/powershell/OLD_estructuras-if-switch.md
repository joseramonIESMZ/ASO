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

## 📝 Ejercicios Prácticos

A continuación se plantean 5 ejercicios prácticos para afianzar el uso de parámetros de entrada (`param()`), estructuras condicionales (`If`, `ElseIf`, `Else`), validación con `Test-Path`, tuberías (*pipeline*) y control de flujo en PowerShell.

### Ejercicio 1. Parametrización de Operaciones Aritméticas Básicas (`ej3.ps1`)

**Problema:**  
Parametriza el script `ej1.ps1` (del tema de introducción a scripts) de modo que los dos números sean parámetros de entrada recibidos en la llamada al script en lugar de variables fijas. Guárdalo como `ej3.ps1`:

- Define un bloque `param()` al comienzo del script que reciba dos parámetros forzados a tipo numérico entero (por ejemplo, `[int]$num1` y `[int]$num2`).
- Realiza las operaciones aritméticas básicas (suma, resta, multiplicación y división) e imprime los resultados por pantalla utilizando `Write-Output` y subexpresiones `$()`.
- Muestra ejemplos de ejecución pasando los argumentos tanto por posición como por nombre de parámetro.

??? success "Ver solución"
    ```powershell
    # ej3.ps1
    # Definición de parámetros forzados a entero
    param(
        [int]$num1,
        [int]$num2
    )

    # Mostramos los resultados de las operaciones aritméticas con Write-Output
    Write-Output "El resultado de la suma de $num1 + $num2 es $($num1 + $num2)"
    Write-Output "El resultado de la resta de $num2 - $num1 es $($num2 - $num1)"
    Write-Output "El resultado de la multiplicación es $num2 * $num1 es $($num2 * $num1)"
    Write-Output "El resultado de la división es $num2 / $num1 es $($num2 / $num1)"
    ```

    **Ejemplos de ejecución:**
    ```powershell
    # Ejecución por posición:
    .\ej3.ps1 5 10

    # Ejecución con nombres de parámetro:
    .\ej3.ps1 -num1 5 -num2 10
    ```

---

### Ejercicio 2. Parametrización de Consulta de Unidades de Disco (`ej4.ps1`)

**Problema:**  
Parametriza el script `ej2.ps1` (del tema de introducción a scripts) para que la letra de la unidad de disco no se solicite mediante `Read-Host`, sino que sea un parámetro de entrada obligatorio. Guárdalo como `ej4.ps1`:

- Define un bloque `param()` con el parámetro `$letra` (de tipo `[string]`) configurado como obligatorio (`Mandatory = $true`) y con un mensaje de ayuda descriptivo.
- Muestra el nombre del equipo obtenido de la variable de entorno `$env:COMPUTERNAME`.
- Concatena los dos puntos `:` a la letra introducida (por ejemplo, `"$($letra):"`) y consulta la información de la unidad mediante `Get-CimInstance Win32_LogicalDisk`.
- Muestra en pantalla el espacio total en GB, el espacio disponible en GB y la etiqueta o nombre del volumen (`VolumeName`).
- Muestra ejemplos de cómo ejecutar el script pasando el parámetro por posición o por nombre.

??? success "Ver solución"
    ```powershell
    # ej4.ps1
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Indica la letra de la unidad de disco (C, D, ...)")]
        [string]$letra
    )

    # 1. Obtenemos y mostramos el nombre del equipo desde la variable de entorno
    Write-Output "Equipo: $env:COMPUTERNAME"

    # 2. Formamos la unidad con los dos puntos (ej: 'C:') y consultamos con Get-CimInstance
    $unidad = "$($letra):"
    $disco = Get-CimInstance Win32_LogicalDisk | Where-Object DeviceID -eq $unidad

    # 3. Mostramos el espacio total, disponible y el nombre del volumen
    Write-Output "Espacio total en $letra : $($disco.Size / 1GB) GB"
    Write-Output "Espacio disponible en $letra : $($disco.FreeSpace / 1GB) GB"
    Write-Output "Nombre del volumen $letra : $($disco.VolumeName)"
    ```

    **Ejemplos de ejecución:**
    ```powershell
    # Ejecución pasando la letra de unidad por posición:
    .\ej4.ps1 C

    # Ejecución indicando el parámetro explícitamente:
    .\ej4.ps1 -letra C
    ```

---

### Ejercicio 3. Monitorización de Servicios con Parámetros y Condicionales (`Comprobar-Servicio.ps1`)

**Problema:**  
Crea un script llamado `Comprobar-Servicio.ps1` que reciba el nombre de un servicio del sistema mediante un parámetro obligatorio (utiliza el bloque `param`). El script debe consultar los servicios del equipo y evaluar su estado con condicionales `if/elseif/else`:

- Si el servicio existe y está en ejecución (`Running`), debe mostrar un mensaje en verde indicando que el servicio funciona correctamente.
- Si el servicio existe pero está detenido (`Stopped`), debe advertir en color amarillo que el servicio se encuentra parado.
- Si no existe ningún servicio con ese nombre, debe informar con un error en color rojo.
- Además, muestra cómo lanzar este script pasando el parámetro y cómo saltarse puntualmente la directiva de ejecución mediante el parámetro `-ExecutionPolicy Bypass`.

??? success "Ver solución"
    ```powershell
    # Comprobar-Servicio.ps1
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Introduce el nombre del servicio a verificar")]
        [string]$NombreServicio
    )

    # Buscamos el servicio silenciando posibles errores en caso de que no exista
    $servicio = Get-Service -Name $NombreServicio -ErrorAction SilentlyContinue

    if ($null -eq $servicio) {
        Write-Host "ERROR: El servicio '$NombreServicio' no existe en el sistema." -ForegroundColor Red
    }
    elseif ($servicio.Status -eq 'Running') {
        Write-Host "OK: El servicio '$($servicio.DisplayName)' está en ejecución (Running)." -ForegroundColor Green
    }
    elseif ($servicio.Status -eq 'Stopped') {
        Write-Host "ADVERTENCIA: El servicio '$($servicio.DisplayName)' está detenido (Stopped)." -ForegroundColor Yellow
    }
    else {
        Write-Host "ESTADO: El servicio '$($servicio.DisplayName)' se encuentra en estado: $($servicio.Status)." -ForegroundColor Cyan
    }
    ```

    **Ejecución desde PowerShell:**
    ```powershell
    .\Comprobar-Servicio.ps1 -NombreServicio "wuauserv"
    ```

    **Ejecución desde línea de comandos saltando la política de ejecución:**
    ```cmd
    powershell.exe -ExecutionPolicy Bypass -File .\Comprobar-Servicio.ps1 -NombreServicio "wuauserv"
    ```

---

### Ejercicio 4. Auditoría de Procesos con Parámetros, Ámbito de Variables y Pipeline (`Top-ProcesosMemoria.ps1`)

**Problema:**  
Desarrolla un script llamado `Top-ProcesosMemoria.ps1` que analice los procesos que más memoria RAM consumen en el equipo:

- Debe aceptar un parámetro opcional `$Cantidad` con valor predeterminado 5 definido mediante el bloque `param`.
- Mediante la tubería (*pipeline*), debe obtener los procesos con `Get-Process`, ordenarlos de forma descendente por memoria de trabajo (`WorkingSet64` o `WS`) y seleccionar únicamente los `$Cantidad` primeros.
- Debe proyectar una tabla con `Id`, `ProcessName` y la memoria consumida calculada en Megabytes (MB).
- Para evitar sobreescribir variables en el entorno del usuario, debe almacenar la suma total de memoria consumida en una variable con ámbito explícito de script (`$script:TotalMemoriaMB`).
- Al terminar, debe mostrar un resumen destacado con la memoria total acumulada por esos procesos.

??? success "Ver solución"
    ```powershell
    # Top-ProcesosMemoria.ps1
    param(
        [int]$Cantidad = 5
    )

    Write-Host "=== Top $Cantidad procesos con mayor consumo de memoria ===" -ForegroundColor Cyan

    # Obtenemos y filtramos los procesos usando la canalización
    $script:TopProcesos = Get-Process |
        Sort-Object -Property WorkingSet64 -Descending |
        Select-Object -First $Cantidad

    # Mostramos la tabla con una propiedad calculada para convertir bytes a MB
    $script:TopProcesos | Select-Object Id, ProcessName, @{
        Name       = "Memoria (MB)"
        Expression = { [math]::Round($_.WorkingSet64 / 1MB, 2) }
    } | Format-Table -AutoSize

    # Calculamos la suma total acumulada y la guardamos en el ámbito de script
    $totalBytes = ($script:TopProcesos | Measure-Object -Property WorkingSet64 -Sum).Sum
    $script:TotalMemoriaMB = [math]::Round($totalBytes / 1MB, 2)

    Write-Host "Memoria total consumida por estos $Cantidad procesos: $script:TotalMemoriaMB MB" -ForegroundColor Green
    ```

    **Ejemplos de ejecución:**
    ```powershell
    # 1. Ejecución con valor por defecto (5 procesos)
    .\Top-ProcesosMemoria.ps1

    # 2. Ejecución pasando el parámetro para consultar 10 procesos
    .\Top-ProcesosMemoria.ps1 -Cantidad 10
    ```

---

### Ejercicio 5. Script de Mantenimiento de Logs con `Test-Path`, Códigos de Retorno (`exit`) y Directiva de Proceso (`-Scope Process`) (`Auditar-Logs.ps1`)

**Problema:**  
Crea un script de mantenimiento llamado `Auditar-Logs.ps1` que verifique archivos en una carpeta y devuelva códigos de salida estándar para sistemas de monitorización:

- Recibe un parámetro obligatorio `$RutaCarpeta` con el directorio a auditar y un parámetro opcional `$TamanoMinimoMB` (por defecto 2), definidos en el bloque `param`.
- Comprueba con `Test-Path` mediante una estructura `if` si la carpeta existe. Si no existe, muestra un mensaje de error en rojo y finaliza inmediatamente el script devolviendo el código numérico de error `exit 1`.
- Si la ruta existe, busca con `Get-ChildItem` todos los archivos con extensión `.log` o `.tmp` que superen el tamaño indicado (usando `Where-Object` y el operador `-gt`).
- Muestra los ficheros encontrados ordenados de mayor a menor tamaño (con su nombre, tamaño en MB y fecha `LastWriteTime`).
- Si no se encuentra ninguno que supere el tamaño, muestra un aviso en verde informando de que no hay ficheros excesivamente grandes. Al finalizar correctamente, devuelve `exit 0`.
- Muestra cómo cambiarías la directiva en PowerShell únicamente para tu sesión de trabajo con `-Scope Process`, cómo ejecutarías el script pasando parámetros y cómo consultarías el código de salida obtenido con `$LASTEXITCODE`.

??? success "Ver solución"
    ```powershell
    # Auditar-Logs.ps1
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Introduce la ruta de la carpeta a auditar")]
        [string]$RutaCarpeta,

        [int]$TamanoMinimoMB = 2
    )

    # 1. Validación de la ruta
    if (-not (Test-Path -Path $RutaCarpeta)) {
        Write-Host "ERROR: La ruta '$RutaCarpeta' no existe." -ForegroundColor Red
        exit 1
    }

    $limiteBytes = $TamanoMinimoMB * 1MB
    Write-Host "Auditando archivos (.log, .tmp) superiores a $TamanoMinimoMB MB en: $RutaCarpeta" -ForegroundColor Cyan

    # 2. Búsqueda y filtrado por tubería
    $archivos = Get-ChildItem -Path $RutaCarpeta -Include *.log, *.tmp -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Length -gt $limiteBytes } |
        Sort-Object -Property Length -Descending

    if ($archivos) {
        $archivos | Select-Object Name, @{
            Name       = "Tamaño (MB)"
            Expression = { [math]::Round($_.Length / 1MB, 2) }
        }, LastWriteTime | Format-Table -AutoSize

        Write-Host "Se encontraron $($archivos.Count) archivo(s) que superan el límite." -ForegroundColor Yellow
    }
    else {
        Write-Host "No se encontraron archivos que superen los $TamanoMinimoMB MB." -ForegroundColor Green
    }

    exit 0
    ```

    **Prueba en PowerShell configurando la directiva solo para la sesión actual:**
    ```powershell
    # 1. Establecer política solo para la ventana/sesión activa (no requiere privilegios de Administrador)
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned

    # 2. Ejecutar el script indicando la ruta y el parámetro
    .\Auditar-Logs.ps1 -RutaCarpeta "$env:TEMP" -TamanoMinimoMB 1

    # 3. Consultar el código devuelto por el último comando/script ejecutado
    $LASTEXITCODE
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
