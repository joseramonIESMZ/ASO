# Parámetros de Scripts en PowerShell

## Introducción a los Parámetros

Los scripts también admiten parámetros de entrada, del mismo modo que lo hacen los cmdlets integrados de PowerShell. Esto permite crear herramientas reutilizables y flexibles.

Para configurar parámetros en un script:

- Se debe poner una sección `Param ()` al inicio del script. **Nota importante:** El bloque `Param()` debe ser obligatoriamente la primera instrucción ejecutable del script (después de los comentarios); de lo contrario, PowerShell devolverá un error.
- Se debe definir una variable para cada parámetro y, si hay más de uno, se deben separar por coma (`,`).
- Se puede establecer un **valor por defecto** para cada parámetro.
- Se debe especificar el **tipo de dato** del parámetro, para que el dato introducido sea convertido automáticamente al que se espera.
- El atributo `Mandatory` se utiliza para indicar que el parámetro es de **introducción obligatoria**. Es decir, si el usuario no lo escribe al llamar al script, la ejecución se pausará para pedírselo.

## Tipos de Datos Comunes

Algunos tipos de datos muy utilizados al definir parámetros son:

- `[string]`: Cadena de caracteres unicode.
- `[int32]`: Números enteros de 32 bits con signo (positivos y negativos).
- `[int]`: Alias de `int32`.
- `[int64]`: Números enteros de 64 bits con signo (positivos y negativos).
- `[single]`: Para números con decimales (precisión simple).
- `[float]`: Alias de `single`.
- `[bool]`: Verdadero (`$true`) o falso (`$false`).
- `[switch]`: Aunque podríamos usar `[bool]`, para opciones del tipo "encendido/apagado" (como los modificadores `-Force` o `-Recurse`) se recomienda usar `[switch]`. Esto permite que el usuario simplemente tenga que escribir el nombre del parámetro (ej. `-Opcion`) para activarlo, sin necesidad de escribir explícitamente `$true` o `$false`.
- `[datetime]`: Fecha y hora.

Se pueden conocer los valores mínimos y máximos admitidos por los tipos numéricos a través de sus propiedades `MinValue` y `MaxValue`.
Por ejemplo: `[int]::MinValue`, `[int]::MaxValue`.

> **Más información:** Puedes consultar la guía detallada sobre [cómo entender los números en PowerShell](https://devblogs.microsoft.com/scripting/understanding-numbers-in-powershell/).

## Importancia de los Parámetros

¿Por qué son importantes los parámetros?

- **Reutilización:** Evita tener que modificar el código fuente cada vez que cambia algún dato de entrada.
- **Seguridad:** Evita insertar contraseñas o credenciales en duro en el interior del script, donde podrían ser visualizadas por cualquier persona con acceso al archivo.

## Ejemplo Práctico: Añadir Parámetros a un Script

A continuación, vamos a tomar el script que generaba un reporte HTML de eventos del sistema y le vamos a añadir parámetros, creando el script `logsystemhtmlParam.ps1`.

### Código del Script (`logsystemhtmlParam.ps1`)

```powershell
# Ejemplo de uso de parámetros
# Realizar una ruptura de fuentes de error en el log System
# Empezar con un comando que trabaja en la consola

Param (
    [String]$Log = "System",
    [String]$NombreEquipo = $env:COMPUTERNAME,
    [int32]$NivelError = 2,
    [String]$Titulo = "Análisis del log System",
    [Parameter(Mandatory, HelpMessage = "Introduce la ruta para el archivo html.")][String]$Ruta
)

$datos = Get-WinEvent -FilterHashtable @{ LogName=$Log;Level=$NivelError } | Group-Object -Property ProviderName -NoElement

# Crear un informe HTML
$piedepagina = "<h5>Informe generado el $(Get-Date)</h5>"
$css = "http://jdhitsolutions.com/sample.css"

$datos | Sort-Object -Property Count,Name -Descending | Select-Object Count,Name |
ConvertTo-Html -Title $Titulo -PreContent "<H1>$NombreEquipo</H1>" -PostContent $piedepagina -CssUri $css |
Out-File $Ruta
```

### Consultar la Ayuda

Al tener los parámetros definidos mediante el bloque `Param()`, PowerShell genera automáticamente la ayuda básica. Podemos ver la lista de parámetros ejecutando:

```powershell
PS C:\scripts\Logs> help .\logsystemhtmlParam.ps1

logsystemhtmlParam.ps1 [[-Log] <string>] [[-NombreEquipo] <string>] [[-NivelError] <int>] [[-Titulo] <string>] [-Ruta] <string> [<CommonParameters>]
```

> **¿Qué es `[<CommonParameters>]`?** Al usar un bloque `Param()`, PowerShell añade automáticamente a nuestro script unos *parámetros comunes* integrados en el sistema (como `-Verbose`, `-Debug`, `-ErrorAction`, etc.) que el usuario puede emplear, aunque nosotros no los hayamos programado explícitamente.

### Ejecutar el Script con Parámetros

Al lanzar el script, podemos suministrar valores distintos a los establecidos por defecto. Por ejemplo, podemos pedir que analice el log `Application` del equipo `localhost`:

```powershell
PS C:\scripts\Logs> .\logsystemhtmlParam.ps1 -NombreEquipo localhost -Log application -NivelError 2 -Titulo "Análisis del log Application" -Ruta "C:\scripts\logs\reporteLogApplication.html"
```

!!! tip "Autocompletado con la tecla TAB"
    Una vez que el script tiene sus parámetros definidos, se comporta de forma idéntica a un comando nativo. Si en la consola escribimos `.\logsystemhtmlParam.ps1 -` y pulsamos la **tecla TAB**, PowerShell nos irá autocompletando automáticamente los nombres de nuestros parámetros (`-Log`, `-NombreEquipo`, `-NivelError`, etc.).

---

## 📚 Referencias y Fuentes Consultadas

!!! info "Documentación Oficial y Autoría"
    * **Material Base:** Presentación de clase *«PowerShell. Scripts (parámetros)»*.
    * **Autoría del Temario:** José Ramón Soria Nieto.
    * **Marco Curricular:** Programación didáctica para el módulo de *Administración de Sistemas Operativos (ASO)* del Ciclo Formativo de Grado Superior en *Administración de Sistemas Informáticos en Red (ASIR/ASIX)*.
    * **Documentación Oficial:** [Documentación oficial de PowerShell (Microsoft Learn)](https://learn.microsoft.com/es-es/powershell/)

!!! abstract "Cofinanciación y Soporte Institucional"
    * **Entidad Educativa:** Generalitat Valenciana — Conselleria d'Educació, Cultura i Esport.
    * **Fondo de Financiación:** Proyecto cofinanciado por la **Unión Europea** a través del **Fondo Social Europeo (FSE)**. 
    * *«El FSE invierte en tu futuro»* — Acciones orientadas al impulso de la educación, formación avanzada y preparación para el mercado laboral técnico.
