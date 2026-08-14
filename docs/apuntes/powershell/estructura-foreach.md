# Estructuras de control: Enumeración Foreach

A menudo, interesa llevar a cabo una o varias operaciones sobre cada uno de los objetos o valores que se suministran en PowerShell. Esto se puede lograr de diferentes maneras:

1.  **Mediante los propios parámetros del cmdlet.**
    *   *Ejemplo:* Pasando múltiples valores a un parámetro que los soporta (como `-Path` en `Get-ChildItem`), el cmdlet los procesa internamente uno a uno.
    ```powershell
    Get-ChildItem -Path C:\Windows, C:\Users
    ```

2.  **Si no existen parámetros para ello, se puede usar Foreach-Object, Foreach:**
    *   **a)** Mediante una línea de comandos unidos con `|` (pipelining), donde los objetos que proporcionan se pasan uno a uno.
    *   **b)** Mediante un conjunto de valores conocido previamente que son procesados uno a uno, por ejemplo, un array.

---

## Uso con Pipelining (Foreach-Object)

En el caso **2.a)**, se utiliza `Foreach-Object` que a su vez, tiene dos alias: el propio `foreach` y `%`.

*   Con `$_` accedemos a cada uno de los objetos pasados por línea de comandos.

### Ejemplos

```powershell
Get-Service | Foreach-Object { if ($_.Status -eq 'Running') { Write-Host "El servicio $($_.Name) está ejecutándose" } }
```

Se observa que `Foreach-Object` aparece intercalado en la línea ya que su función es recoger uno a uno los objetos que va recibiendo a través del pipe `|`, a modo de *streaming* de objetos.

Otros ejemplos:

```powershell
1..5 | Foreach-Object {$_}
```

```powershell
Get-Content .\computers.txt | Foreach-Object { Get-SmbShare -CimSession $_ }
```

---

## Uso con conjunto de valores (Sentencia Foreach)

En el caso **2.b)**, se utiliza la sentencia `foreach`.

*   Suele ir a principios de línea pues no depende de la salida de comandos previos.

### Ejemplos

```powershell
$n = 1..10
foreach ($item in $n) {
    $file = "TestFile-$item.txt"
    New-Item $file
}
```

```powershell
ForEach ($number in 1..5){$number}
```

> **Nota:** Para no incurrir en errores, se puede usar `foreach` indistintamente como alias de `Foreach-Object` en el pipeline o como sentencia de control al inicio.

## ¿Cuándo usar cada uno?

*   **`Foreach-Object` (Pipeline):** Ideal cuando los objetos vienen de un comando anterior (`|`) y quieres procesarlos uno a uno, o cuando trabajas con streams de datos. Es más eficiente en el consumo de memoria para pipelines largos porque procesa los objetos a medida que llegan, sin cargar toda la colección en memoria a la vez.
*   **`foreach` (Sentencia):** Ideal cuando tienes una colección (como un array) ya cargada en una variable y quieres iterar sobre ella. Es más rápido en la ejecución global que el pipeline y resulta más limpio sintácticamente cuando no necesitas encadenar comandos.

### Relevancia frente a otros bucles (`for` o `while`)

En el trabajo diario de administración de sistemas con PowerShell, **`foreach`** y **`Foreach-Object`** son, con mucha diferencia, las estructuras de iteración más utilizadas. Su enorme relevancia radica en la propia naturaleza orientada a objetos de PowerShell:

*   **Manejo directo de colecciones:** A diferencia de `for` o `while`, que exigen crear contadores, evaluar condiciones matemáticas en cada vuelta y acceder a los elementos por su posición de índice (ej. `$array[$i]`), los iteradores `foreach` extraen directamente el objeto de la colección, dejándolo listo para trabajar.
*   **Simplicidad y legibilidad:** Al interactuar continuamente con grupos de elementos (usuarios de Active Directory, archivos de un directorio, procesos del sistema, buzones de correo), es mucho más rápido, seguro y natural iterar la colección completa directamente.
*   **Casos de uso específicos:** Los bucles clásicos como `for` y `while` suelen quedar relegados a escenarios concretos en los que **no se itera sobre una colección de objetos existente**. Por ejemplo: mantener una ejecución a la espera de que ocurra un evento o levante un servicio (ideal para un `while`), o repetir una acción (como un ping) un número exacto de veces predefinidas (ideal para un `for`).

### Alterando el flujo: `Break` y `Continue`

Al igual que en los bucles `for` y `while`, podemos alterar el flujo de ejecución, pero es **muy importante** conocer una diferencia clave de comportamiento:

*   En una **sentencia `foreach`**, las palabras clave `break` (para abortar el bucle entero) y `continue` (para saltar a la siguiente iteración) funcionan de la forma esperada.
*   En **`Foreach-Object` (Pipeline)**, al tratarse de un bloque de script (ScriptBlock), **no funcionan igual**. Para simular un `continue`, debes usar la instrucción `return` (que finaliza el procesamiento del objeto actual y pasa al siguiente). Romper (hacer un `break`) un pipeline largo de forma limpia antes de que termine es complejo y no está soportado de forma nativa hasta versiones muy modernas de PowerShell.

## Ejemplos prácticos

### Ejemplo 1: Comparativa `foreach` vs `Foreach-Object` (Archivos y carpetas)

El siguiente ejemplo práctico ilustra la misma operación (añadir un archivo a una lista de carpetas y crear la carpeta si no existe) utilizando ambas estructuras.

#### Versión 1: Usando la sentencia `foreach`

```powershell
# Añade el archivo ejemploArchivo.txt a la carpeta que se recorre del array

$carpetas = @('C:\Destino\Carpeta1', 'C:\Destino\Carpeta2', 'c:\Destino\Carpeta3')

Foreach ( $carpeta in $carpetas ) {
    if ( -not (Test-Path -LiteralPath $carpeta) ) {New-Item -Path $carpeta -ItemType Directory -ErrorAction Stop | Out-Null }
    Add-Content -Path "$carpeta/ejemploArchivo.txt" -Value "Este es el contenido del archivo"
}
```

#### Versión 2: Usando el pipeline con `Foreach-Object`

```powershell
# Añade el archivo ejemploArchivo.txt a la carpeta que se recorre del array

$carpetas = @('C:\Destino\Carpeta1', 'C:\Destino\Carpeta2', 'c:\Destino\Carpeta3')

$carpetas |
    ForEach-Object {
        if ( -not (Test-Path -LiteralPath $_) ) { New-Item -Path $_ -ItemType Directory -ErrorAction Stop | Out-Null }
        Add-Content -Path "$_/ejemploArchivo.txt" -Value "Este es el contenido del archivo"
    }
```



> **💡 Buenas prácticas con rutas:** En el código anterior se unen rutas combinando variables y cadenas (ej. `"$carpeta/ejemploArchivo.txt"`). Aunque PowerShell lo suele interpretar bien, en scripts profesionales la mejor práctica es usar siempre contrabarras en Windows (`\`) o, idealmente, utilizar el cmdlet `Join-Path` (ej. `Join-Path -Path $carpeta -ChildPath "ejemploArchivo.txt"`) para construir la ruta de forma segura y a prueba de errores.

### Ejemplo 2: Script de Backup con creación de subcarpetas

Este ejemplo muestra un script más completo (`BackupCarpeta.ps1`) que utiliza un bloque `Param` para solicitar una carpeta de origen y emplea un bucle `foreach` para realizar copias de seguridad en múltiples destinos, creando subcarpetas con la fecha actual.

```powershell
# Realiza backup dentro de una serie de carpetas. Si las carpetas no existen, las crea.
# Añade una subcarpeta con la fecha de hoy para introducir ahí la copia.

Param(
    [Parameter(Mandatory,HelpMessage = 'Introduce carpeta a copiar.')][string]$CarpetaOrig
)

$carpetasBackup = @('c:\backup1','c:\backup2')

$archivoBackupFecha = 'backupFinalizado.txt'
[string]$hoy = Get-Date -Format "ddMMyyyy"

if (Test-Path -LiteralPath $CarpetaOrig) {
    foreach ($carpeta in $carpetasBackup) {
        $carpetaDestino = $carpeta + "\" + $hoy
        if ( -not (Test-Path -LiteralPath $carpetaDestino) ) {
            if ( -not (Test-Path -LiteralPath $carpeta ) ) { New-Item -Path $carpeta -ItemType Directory -ErrorAction Stop | Out-Null }
            New-Item -Path $carpetaDestino -ItemType Directory -ErrorAction Stop | Out-Null
            Copy-Item -Path $CarpetaOrig -Destination $carpetaDestino -Recurse
            Write-Host "Copia de $CarpetaOrig realizada correctamente en $carpetaDestino."
        } else {
            Write-Host "Ya existe copia del día $hoy. No se copia de nuevo."
        }
    }
} else {
    Write-Host "Carpeta $CarpetaOrig no existe."
}
```

### Ejemplo 3: Chequeo de servidores con `Test-Connection` y `Try/Catch`

En ocasiones, al iterar sobre una lista de elementos (por ejemplo, servidores a los que queremos hacer ping con `Test-Connection`), un comando puede fallar. Es importante manejar estos errores correctamente para que el script no se interrumpa o muestre mensajes de error no deseados. Para ello, podemos usar `Try/Catch`.

#### Versión 1: Sin control de excepciones adecuado

En esta primera versión, si `Test-Connection` no puede completar la petición y generar el ping (o no encuentra el equipo), la ejecución generará un error no controlado en pantalla. 

```powershell
# Comprobar conexión con servidores

Param(
    [Parameter(Mandatory,HelpMessage = 'Introduce archivo.')][String]$Archivo
)

$Servidores = Get-Content $Archivo

foreach ($servidor in $Servidores) {
    if (Test-Connection -ComputerName $servidor -Count 1 -ErrorAction STOP) {
        Write-Output "$Servidor - OK"
    } else {
        Write-Output "Servidor - $($_.Exception.Message)"
    }
}
```

#### Versión 2: Manejo del error con `Try/Catch`

En esta segunda versión, capturamos el error devuelto por `Test-Connection` mediante la estructura `Try/Catch`. Al usar `-ErrorAction STOP`, garantizamos que si el ping falla, el flujo salte directamente al bloque `catch`, donde podemos mostrar el mensaje de error exacto y formateado de forma controlada.

```powershell
# Comprobar conexión con servidores

Param(
    [Parameter(Mandatory,HelpMessage = 'Introduce archivo.')][String]$Archivo
)

$Servidores = Get-Content $Archivo

foreach ($servidor in $Servidores) {
    try {
        $null = Test-Connection -ComputerName $servidor -Count 1 -ErrorAction STOP
        Write-Output "$Servidor - OK"
    } Catch {
        Write-Output "Servidor - $($_.Exception.Message)"
    }
}
```

### Ejemplo 4: Inicio de servicios automáticos inactivos

Este último ejemplo hace uso de `Foreach-Object` en el pipeline para procesar una colección de servicios filtrados. El script busca todos los servicios configurados con inicio automático que actualmente no estén en ejecución y los intenta iniciar, controlando cualquier posible fallo con un bloque `try/catch`.

```powershell
## Obtiene una lista de los servicios automáticos que no están arrancados y los inicia

$servicios = Get-Service | Where-Object {$_.StartType -eq 'Automatic' -and $_.Status -ne 'Running'}

## Pass each service object to the pipeline and process them with the Foreach-Object cmdlet
$servicios | ForEach-Object {
    try {
        Write-Host "Iniciando '$($_.DisplayName)' ..."
        #Start-Service -Name $_.Name -ErrorAction STOP
        Write-Host "EXITO: '$($_.DisplayName)' ha sido iniciado."
    } catch {
        Write-output "FALLO: $($_.exception.message)"
    }
}
```

---
## 📚 Referencias y Fuentes Consultadas

!!! info "Documentación Oficial y Autoría"
    * **Material Base:** Presentación de clase *«PowerShell. Estructuras de control. Foreach»*.
    * **Autoría del Temario:** José Ramón Soria Nieto.
    * **Marco Curricular:** Programación didáctica para el módulo de *Administración de Sistemas Operativos (ASO)* del Ciclo Formativo de Grado Superior en *Administración de Sistemas Informáticos en Red (ASIR/ASIX)*.
    * **Documentación Oficial:** [Documentación oficial de PowerShell (Microsoft Learn)](https://learn.microsoft.com/es-es/powershell/)

!!! abstract "Cofinanciación y Soporte Institucional"
    * **Entidad Educativa:** Generalitat Valenciana — Conselleria d'Educació, Cultura i Esport.
    * **Fondo de Financiación:** Proyecto cofinanciado por la **Unión Europea** a través del **Fondo Social Europeo (FSE)**. 
    * *«El FSE invierte en tu futuro»* — Acciones orientadas al impulso de la educación, formación avanzada y preparación para el mercado laboral técnico.
