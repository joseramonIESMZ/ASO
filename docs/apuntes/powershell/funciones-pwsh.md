# Funciones en PowerShell

Las funciones en PowerShell son bloques de código reutilizables a los que se les asigna un nombre. Nos permiten agrupar comandos que realizan una tarea específica, de manera que podemos invocar esa funcionalidad varias veces sin tener que repetir el código.

## Sintaxis Básica

La sintaxis general para declarar una función es la siguiente:

```powershell
function Nombre-DeLaFuncion {
    # Instrucciones
}
```

Por convención, en PowerShell se utiliza el formato `Verbo-Sustantivo` (por ejemplo, `Get-Usuario`, `Start-Servicio`, `New-CopiaSeguridad`) para nombrar las funciones, aunque no es obligatorio.

Para llamar a la función, simplemente escribimos su nombre:

```powershell
Nombre-DeLaFuncion
```

### Ejemplo Simple

```powershell
function Mostrar-Saludo {
    Write-Host "¡Hola! Bienvenido a PowerShell."
}

# Llamada a la función
Mostrar-Saludo
```

## Uso de Parámetros

Al igual que los scripts, las funciones pueden recibir parámetros para trabajar de forma dinámica. Existen dos formas de definir parámetros en una función:

### 1. Parámetros simples (estilo antiguo)

```powershell
function Saludar-Usuario ($Nombre) {
    Write-Host "Hola, $Nombre"
}

Saludar-Usuario "Ana"
# O también:
Saludar-Usuario -Nombre "Ana"
```

### 2. Parámetros avanzados (Bloque `Param`)

Esta es la forma recomendada, ya que nos permite definir tipos de datos, especificar si un parámetro es obligatorio, añadir mensajes de ayuda, etc. Es idéntico a cómo se declaran en los scripts.

```powershell
function Saludar-Usuario {
    param (
        [Parameter(Mandatory=$true, HelpMessage="Introduce el nombre del usuario")]
        [string]$Nombre,

        [string]$Apellidos = "" # Parámetro opcional con valor por defecto
    )

    Write-Host "Hola, $Nombre $Apellidos"
}

Saludar-Usuario -Nombre "Carlos" -Apellidos "López"
```

## Devolver Valores (Return)

En PowerShell, casi cualquier salida de un comando que no se capture o se redirija (por ejemplo, al asignarlo a una variable o enviarlo a `$null`), se devuelve como resultado de la función. Sin embargo, podemos usar la palabra clave `return` para hacer el código más explícito y salir inmediatamente de la función.

```powershell
function Sumar-Numeros {
    param (
        [int]$Numero1,
        [int]$Numero2
    )
    
    $resultado = $Numero1 + $Numero2
    return $resultado
}

$suma = Sumar-Numeros -Numero1 5 -Numero2 10
Write-Host "La suma es: $suma"
```

> [!NOTE]
> En PowerShell, todo lo que "cae" al pipeline es devuelto. Por ejemplo, si haces un `Write-Output "Hola"` o simplemente pones una variable `$variable` sin asignarla a nada, su valor se añade al retorno de la función. El comando `return` no solo devuelve el valor indicado, sino que detiene la ejecución de la función.

## Cómo convertir un Script en una Función

A menudo, empezamos escribiendo un script (`.ps1`) para automatizar una tarea, y más tarde nos damos cuenta de que sería más útil tenerlo como una función para poder usarlo desde la consola u otros scripts repetidamente, y sin tener que llamarlo por su ruta completa.

Para convertir un script en una función:

1. **Añade la cabecera de la función:** Envuelve todo el código de tu script (incluyendo el bloque `param` si lo tiene) dentro de un bloque `function Nombre-Funcion { ... }`.
2. **Carga la función en memoria:** Para poder usar la función desde la consola u otro script, necesitas "cargarla" en tu sesión actual. A este proceso se le llama **dot-sourcing**.

### Ejemplo práctico

Imagina que tienes un script llamado `Calcula-Edad.ps1`:

**Calcula-Edad.ps1 (Versión Script)**
```powershell
param (
    [int]$AnioNacimiento
)

$anioActual = (Get-Date).Year
$edad = $anioActual - $AnioNacimiento
Write-Host "Tienes $edad años."
```

Para usar este script, normalmente ejecutarías: `.\Calcula-Edad.ps1 -AnioNacimiento 1990`

**Versión Función**

Puedes modificar el mismo fichero `Calcula-Edad.ps1` o crear uno nuevo llamado, por ejemplo, `MisFunciones.ps1`:

```powershell
function Get-Edad {
    param (
        [int]$AnioNacimiento
    )

    $anioActual = (Get-Date).Year
    $edad = $anioActual - $AnioNacimiento
    Write-Host "Tienes $edad años."
}
```

**¿Cómo usar esta función? (Dot Sourcing)**

Si ejecutas el script `MisFunciones.ps1` tal cual (escribiendo `.\MisFunciones.ps1`), no ocurrirá nada visible, porque el script solo contiene la definición de la función, pero nadie la está llamando.

Para poder usar la función en tu consola, debes ejecutar el script usando un punto `.` seguido de un espacio y la ruta del script. Esto ejecutará el script en el ámbito actual (*scope* actual), dejando la función disponible en memoria.

```powershell
# 1. Cargamos el fichero con la función en memoria (Dot Sourcing)
# Fíjate en el punto y el espacio al principio
. .\MisFunciones.ps1

# 2. Ahora podemos usar la función directamente como si fuera un cmdlet de PowerShell
Get-Edad -AnioNacimiento 1990
```

> [!TIP]
> Puedes tener un fichero `.ps1` con decenas de funciones útiles (como una librería de funciones). Al hacer *dot-sourcing* de ese único fichero al principio de tus scripts, tendrás acceso a todas esas funciones en el resto de tu código.

---

## 📚 Referencias y Fuentes Consultadas

!!! info "Documentación Oficial y Autoría"
    * **Material Base:** Apuntes sobre *«PowerShell. Funciones y Scripts»*.
    * **Autoría del Temario:** José Ramón Soria Nieto.
    * **Marco Curricular:** Programación didáctica para el módulo de *Administración de Sistemas Operativos (ASO)* del Ciclo Formativo de Grado Superior en *Administración de Sistemas Informáticos en Red (ASIR/ASIX)*.
    * **Documentación Oficial:** [Documentación oficial de PowerShell (Microsoft Learn)](https://learn.microsoft.com/es-es/powershell/)

!!! abstract "Cofinanciación y Soporte Institucional"
    * **Entidad Educativa:** Generalitat Valenciana — Conselleria d'Educació, Cultura i Esport.
    * **Fondo de Financiación:** Proyecto cofinanciado por la **Unión Europea** a través del **Fondo Social Europeo (FSE)**. 
    * *«El FSE invierte en tu futuro»* — Acciones orientadas al impulso de la educación, formación avanzada y preparación para el mercado laboral técnico.
