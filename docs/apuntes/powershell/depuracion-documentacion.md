## Depuración y documentación profesional de scripts PowerShell

Cuando un script comienza a crecer, ya no es suficiente con que simplemente "funcione". En un entorno profesional es necesario que sea **fácil de mantener, depurar, comprender y reutilizar**.

Un administrador de sistemas debe ser capaz de:

* localizar errores de sintaxis y ejecución;
* identificar qué parte del script está fallando;
* controlar cómo se muestran y gestionan los errores;
* generar información útil durante la ejecución;
* documentar correctamente el funcionamiento de un script;
* facilitar que otros administradores puedan utilizarlo y modificarlo.

PowerShell dispone de diferentes mecanismos para conseguir estos objetivos.

---

### Control estricto del código con `Set-StrictMode`

Por defecto, PowerShell permite determinadas construcciones que pueden ocultar errores durante la ejecución.

Por ejemplo:

```powershell
Write-Host $nombreUsuario
```

Si la variable `$nombreUsuario` no ha sido inicializada, PowerShell puede continuar la ejecución sin que el error resulte evidente.

Para detectar este tipo de problemas se puede utilizar:

```powershell
Set-StrictMode -Version Latest
```

A partir de ese momento PowerShell será más estricto y detectará determinados errores relacionados con:

* variables no inicializadas;
* acceso incorrecto a propiedades;
* uso incorrecto de determinadas expresiones;
* construcciones que pueden provocar comportamientos inesperados.

Por ejemplo:

```powershell
Set-StrictMode -Version Latest

Write-Host $nombreUsuario
```

En este caso, si `$nombreUsuario` no existe, PowerShell generará un error.

!!! tip "Buena práctica"
En scripts de administración es recomendable utilizar `Set-StrictMode` durante el desarrollo y las pruebas.

---

### Control de errores con `$ErrorActionPreference`

PowerShell clasifica muchos errores como **errores no terminantes**.

Esto significa que puede producirse un error y, aun así, continuar ejecutándose el resto del script.

El comportamiento general puede configurarse mediante la variable:

```powershell
$ErrorActionPreference
```

Algunos valores habituales son:

| Valor              | Comportamiento                     |
| ------------------ | ---------------------------------- |
| `Continue`         | Muestra el error y continúa        |
| `SilentlyContinue` | No muestra el error y continúa     |
| `Stop`             | Convierte el error en terminante   |
| `Inquire`          | Pregunta al usuario qué debe hacer |

Por ejemplo:

```powershell
$ErrorActionPreference = "Stop"

Get-Content "C:\datos\fichero.txt"

Write-Host "El script continúa"
```

Si el fichero no existe, la ejecución se detendrá.

También podemos establecer este comportamiento únicamente para un cmdlet concreto:

```powershell
Get-Content "C:\datos\fichero.txt" -ErrorAction Stop
```

Esto suele ser preferible cuando únicamente queremos controlar una determinada operación.

---

## Gestión de errores con `try`, `catch` y `finally`

Una de las técnicas más importantes para crear scripts robustos consiste en utilizar bloques:

```text
try
catch
finally
```

Su estructura general es:

```powershell
try {

    # Código que puede provocar un error

}
catch {

    # Código que se ejecutará si aparece un error

}
finally {

    # Código que se ejecutará siempre

}
```

Por ejemplo:

```powershell
try {

    Get-Content "C:\datos\usuarios.csv" -ErrorAction Stop

    Write-Host "Fichero leído correctamente"

}
catch {

    Write-Host "Se ha producido un error"

}
finally {

    Write-Host "Fin de la operación"

}
```

Si el fichero no existe, `Get-Content` generará un error terminante porque hemos utilizado:

```powershell
-ErrorAction Stop
```

En ese caso se ejecutará el bloque `catch`.

El bloque `finally` se ejecutará siempre, independientemente de que se haya producido un error.

---

### Obtener información sobre el error

Dentro del bloque `catch` podemos acceder al error mediante:

```powershell
$_
```

Por ejemplo:

```powershell
try {

    Get-Content "C:\datos\usuarios.csv" -ErrorAction Stop

}
catch {

    Write-Host "Error:"
    Write-Host $_

}
```

También podemos obtener información concreta:

```powershell
try {

    Get-Content "C:\datos\usuarios.csv" -ErrorAction Stop

}
catch {

    Write-Host "Mensaje:"
    Write-Host $_.Exception.Message

}
```

Esto resulta especialmente útil para registrar errores en scripts de administración.

---

## Ejemplo: creación de un usuario con control de errores

Supongamos que queremos crear un usuario local.

```powershell
param(
    [Parameter(Mandatory)]
    [string]$Usuario
)

Set-StrictMode -Version Latest

try {

    New-LocalUser `
        -Name $Usuario `
        -NoPassword `
        -ErrorAction Stop

    Write-Host "Usuario $Usuario creado correctamente"

}
catch {

    Write-Host "No se ha podido crear el usuario $Usuario"
    Write-Host $_.Exception.Message

}
```

Con esta estructura evitamos que el script continúe silenciosamente cuando se produce un error.

En un entorno empresarial podríamos sustituir `Write-Host` por un mecanismo de registro en un fichero o sistema centralizado de logs.

---

# Mostrar información durante la ejecución

Cuando estamos desarrollando o depurando un script puede resultar útil mostrar información adicional.

PowerShell proporciona diferentes mecanismos.

---

## `Write-Verbose`

Permite generar mensajes informativos que normalmente permanecen ocultos.

Ejemplo:

```powershell
Write-Verbose "Leyendo fichero de usuarios"
```

Para visualizarlos debemos ejecutar el script con:

```powershell
.\script.ps1 -Verbose
```

Para utilizar correctamente `-Verbose` en nuestros scripts podemos definirlos como funciones avanzadas o utilizar:

```powershell
[CmdletBinding()]
param()
```

Ejemplo:

```powershell
[CmdletBinding()]
param(
    [string]$Fichero
)

Write-Verbose "Procesando fichero $Fichero"

$datos = Import-Csv $Fichero

Write-Verbose "Se han leído $($datos.Count) registros"
```

Ejecución:

```powershell
.\procesarUsuarios.ps1 `
    -Fichero ".\usuarios.csv" `
    -Verbose
```

La ventaja es que la información de depuración no aparece durante una ejecución normal.

---

## `Write-Debug`

También podemos insertar mensajes específicamente destinados a depuración:

```powershell
Write-Debug "Valor de la variable contador: $contador"
```

Para visualizarlos:

```powershell
$DebugPreference = "Continue"
```

o mediante las opciones de depuración disponibles en el entorno de desarrollo.

---

# Depuración mediante Visual Studio Code

Visual Studio Code permite ejecutar scripts PowerShell de forma controlada y analizar su comportamiento.

Una de las herramientas más importantes son los **breakpoints** o puntos de interrupción.

Un breakpoint permite detener temporalmente la ejecución del script en una determinada línea.

Por ejemplo, imaginemos:

```powershell
$usuarios = Import-Csv ".\usuarios.csv"

foreach ($usuario in $usuarios) {

    $login = "$($usuario.nombre).$($usuario.apellido)"

    Write-Host "Procesando $login"

}
```

Podemos establecer un breakpoint dentro del `foreach` para comprobar:

* el contenido de `$usuario`;
* el valor generado en `$login`;
* el número de iteración;
* cualquier otra variable disponible.

Durante la depuración podremos ejecutar el código:

* línea a línea;
* entrando en funciones;
* continuando hasta el siguiente breakpoint;
* inspeccionando las variables existentes.

Este proceso permite localizar errores mucho más rápidamente que utilizando únicamente mensajes mediante `Write-Host`.

---

# Documentación de scripts

Un script utilizado en administración de sistemas debe indicar claramente:

* para qué sirve;
* qué parámetros necesita;
* qué devuelve;
* cómo debe ejecutarse;
* qué requisitos necesita;
* quién lo mantiene;
* qué operaciones realiza sobre el sistema.

PowerShell permite incorporar documentación directamente dentro del propio script mediante **Comment-Based Help**.

La estructura puede ser:

```powershell
<#
.SYNOPSIS
Descripción breve del script.

.DESCRIPTION
Descripción detallada de su funcionamiento.

.PARAMETER Nombre
Descripción del parámetro.

.EXAMPLE
Ejemplo de ejecución.

.NOTES
Información adicional.
#>
```

---

## Ejemplo de documentación

```powershell
<#
.SYNOPSIS
Crea usuarios locales a partir de un fichero CSV.

.DESCRIPTION
El script importa un fichero CSV que contiene información
de usuarios y crea automáticamente las correspondientes
cuentas locales en el servidor.

.PARAMETER Fichero
Ruta del fichero CSV que contiene los usuarios.

.EXAMPLE
.\crearUsuarios.ps1 -Fichero ".\usuarios.csv"

.NOTES
El script debe ejecutarse con permisos de administrador.
#>

param(
    [Parameter(Mandatory)]
    [string]$Fichero
)

$usuarios = Import-Csv $Fichero

foreach ($usuario in $usuarios) {

    Write-Host "Creando usuario $($usuario.nombre)"

}
```

---

# Consultar la ayuda de nuestro propio script

Si el script está correctamente documentado podemos consultar su ayuda mediante:

```powershell
Get-Help .\crearUsuarios.ps1
```

Para obtener información más detallada:

```powershell
Get-Help .\crearUsuarios.ps1 -Detailed
```

Para visualizar los ejemplos:

```powershell
Get-Help .\crearUsuarios.ps1 -Examples
```

De esta forma nuestros scripts se comportan de forma similar a los propios cmdlets de PowerShell.

---

# Ejemplo completo

Podemos combinar documentación, parámetros, control de errores y mensajes de diagnóstico en un único script.

```powershell
<#
.SYNOPSIS
Comprueba el estado de un servicio.

.DESCRIPTION
El script consulta un servicio de Windows y muestra su estado.
Si el servicio no existe se captura el error y se muestra
información sobre el problema.

.PARAMETER NombreServicio
Nombre del servicio que se desea consultar.

.EXAMPLE
.\comprobarServicio.ps1 -NombreServicio Spooler

.NOTES
Script de ejemplo para administración de sistemas.
#>

[CmdletBinding()]
param(

    [Parameter(Mandatory)]
    [string]$NombreServicio

)

Set-StrictMode -Version Latest

try {

    Write-Verbose "Consultando servicio $NombreServicio"

    $servicio = Get-Service `
        -Name $NombreServicio `
        -ErrorAction Stop

    Write-Host "Servicio: $($servicio.Name)"
    Write-Host "Estado: $($servicio.Status)"

}
catch {

    Write-Host "No se ha podido consultar el servicio"
    Write-Host $_.Exception.Message

}
```

Podemos ejecutarlo normalmente:

```powershell
.\comprobarServicio.ps1 -NombreServicio Spooler
```

O visualizar información adicional:

```powershell
.\comprobarServicio.ps1 `
    -NombreServicio Spooler `
    -Verbose
```

---

## Buenas prácticas

En los scripts desarrollados durante el módulo se recomienda:

* utilizar nombres de variables descriptivos;
* evitar valores fijos cuando puedan utilizarse parámetros;
* validar la información recibida;
* controlar las operaciones susceptibles de producir errores;
* utilizar `try/catch` cuando sea necesario;
* emplear `-ErrorAction Stop` cuando queramos capturar errores;
* utilizar `Write-Verbose` para mensajes de diagnóstico;
* documentar los parámetros del script;
* proporcionar al menos un ejemplo de ejecución;
* utilizar comentarios únicamente cuando aporten información útil;
* probar el script con situaciones correctas y con situaciones de error.

!!! warning "Importante"
Que un script funcione correctamente en una situación concreta no significa que sea robusto. También debemos comprobar cómo se comporta cuando faltan ficheros, existen usuarios duplicados, un servicio no está disponible, se introducen parámetros incorrectos o el usuario no dispone de permisos suficientes.

---

## Relación con el currículo

Los contenidos de esta sección permiten trabajar específicamente los siguientes criterios del **RA7 — Utiliza lenguajes de guiones (scripts) en sistemas operativos, describiendo su aplicación y administrando servicios del sistema operativo**:

* **CE2-RA7:** Se han utilizado herramientas para depurar errores sintácticos y de ejecución.
* **CE9-RA7:** Se han documentado los guiones creados.

Además, el uso de control de errores, parámetros, funciones y técnicas de diagnóstico refuerza transversalmente:

* **CE1-RA7:** utilización y combinación de estructuras del lenguaje;
* **CE4-RA7:** modificación y adaptación de guiones;
* **CE5-RA7:** creación y prueba de guiones de administración de servicios;
* **CE6-RA7:** creación y prueba de guiones de automatización de tareas.

De esta forma, el desarrollo de scripts durante los diferentes sprints no se limita a conseguir que una automatización funcione, sino que persigue crear soluciones **robustas, mantenibles, reutilizables y correctamente documentadas**, tal y como se requiere en un entorno profesional de administración de sistemas.
