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

## 📝 Ejercicios Prácticos

A continuación se plantean 5 ejercicios prácticos basados en escenarios reales de administración de sistemas para afianzar el uso de la sentencia `foreach`, el cmdlet `ForEach-Object` en tuberías, el control de errores con `try/catch` y el procesamiento masivo de objetos en PowerShell.

### Ejercicio 1. Limpieza Automatizada de Archivos Temporales (`Limpiar-Temporales.ps1`)

**Problema:**  
Desarrolla un script llamado `Limpiar-Temporales.ps1` para realizar el mantenimiento preventivo de una o varias rutas del sistema de archivos:

- Recibe un parámetro obligatorio `-RutasCarpetas` (un array de cadenas `[string[]]`) con las rutas a limpiar y un parámetro opcional `-DiasAntiguedad` con valor predeterminado `7`.
- Recorre cada ruta utilizando una sentencia `foreach ($ruta in $RutasCarpetas)`.
- Comprueba si la ruta existe en el disco mediante `Test-Path`. Si no existe, emite una advertencia con `Write-Warning` y salta a la siguiente ruta mediante `continue`.
- Para cada carpeta válida, busca de forma recursiva todos los archivos (`Get-ChildItem -File -Recurse`) cuya fecha de última modificación (`LastWriteTime`) sea anterior a la fecha límite calculada con `(Get-Date).AddDays(-$DiasAntiguedad)`.
- Itera sobre los archivos caducados para eliminarlos de forma segura (`Remove-Item`) capturando posibles errores (como archivos bloqueados o permisos denegados) mediante un bloque `try/catch`.
- Muestra en pantalla cada archivo eliminado junto con su tamaño, y al concluir cada carpeta presenta un resumen con el total de archivos borrados y el volumen en MB liberado.

**Ejemplo de ejecución esperado:**

```powershell
> .\Limpiar-Temporales.ps1 -RutasCarpetas "C:\Temp", "D:\LogsApp" -DiasAntiguedad 15
=== Iniciando limpieza de archivos anteriores a: 26/08/2026 23:45:00 ===

Procesando directorio: C:\Temp
  [ELIMINADO] cache_old.tmp (1420.55 KB)
  [ELIMINADO] debug_backup.log (3045.12 KB)
Resumen para 'C:\Temp': 2 archivo(s) eliminados, 4.36 MB liberados.

Procesando directorio: D:\LogsApp
No se encontraron archivos con más de 15 días de antigüedad.
```

??? success "Ver solución"
    ```powershell
    # Limpiar-Temporales.ps1
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Introduce las rutas de las carpetas a limpiar")]
        [string[]]$RutasCarpetas,

        [int]$DiasAntiguedad = 7
    )

    $fechaLimite = (Get-Date).AddDays(-$DiasAntiguedad)
    Write-Host "=== Iniciando limpieza de archivos anteriores a: $($fechaLimite.ToString('dd/MM/yyyy HH:mm:ss')) ===" -ForegroundColor Cyan

    foreach ($ruta in $RutasCarpetas) {
        if (-not (Test-Path -LiteralPath $ruta)) {
            Write-Warning "La ruta '$ruta' no existe. Se omitirá."
            continue
        }

        Write-Host "`nProcesando directorio: $ruta" -ForegroundColor Yellow
        $archivosCaducados = Get-ChildItem -Path $ruta -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -lt $fechaLimite }

        if (-not $archivosCaducados) {
            Write-Host "No se encontraron archivos con más de $DiasAntiguedad días de antigüedad." -ForegroundColor Green
            continue
        }

        $totalBorrados = 0
        $bytesLiberados = 0

        foreach ($archivo in $archivosCaducados) {
            try {
                $tamano = $archivo.Length
                Remove-Item -LiteralPath $archivo.FullName -Force -ErrorAction Stop
                $totalBorrados++
                $bytesLiberados += $tamano
                Write-Host "  [ELIMINADO] $($archivo.Name) ($([math]::Round($tamano / 1KB, 2)) KB)" -ForegroundColor Gray
            }
            catch {
                Write-Warning "  [ERROR] No se pudo eliminar '$($archivo.FullName)': $($_.Exception.Message)"
            }
        }

        $mbLiberados = [math]::Round($bytesLiberados / 1MB, 2)
        Write-Host "Resumen para '$ruta': $totalBorrados archivo(s) eliminados, $mbLiberados MB liberados." -ForegroundColor Green
    }
    ```

    **Ejemplo de ejecución:**
    ```powershell
    .\Limpiar-Temporales.ps1 -RutasCarpetas "C:\Temp", "C:\inetpub\logs" -DiasAntiguedad 10
    ```

---

### Ejercicio 2. Auditoría de Conectividad con Registro en Log (`Auditar-Servidores.ps1`)

**Problema:**  
Crea un script llamado `Auditar-Servidores.ps1` que compruebe el estado de conectividad de una lista de servidores leída desde un archivo de texto plano y genere un archivo de registro (*log*):

- Recibe un parámetro obligatorio `-RutaArchivo` con la ubicación del archivo de texto (un host o IP por línea).
- Recibe un parámetro opcional `-ArchivoLog` con la ruta del archivo donde se guardará el registro (por defecto: `$env:TEMP\informe-conectividad.log`).
- Comprueba que el archivo de entrada exista con `Test-Path`; si no existe, muestra un mensaje de error y termina con `exit 1`.
- Carga los nombres de los equipos con `Get-Content` y utiliza un bucle `foreach ($equipo in $servidores)` para evaluar la conectividad de cada uno.
- Para cada equipo, ejecuta `Test-Connection -ComputerName $equipo -Count 1 -TimeoutSeconds 2 -ErrorAction Stop` dentro de un bloque `try/catch`.
- Si el ping responde, imprime en verde por consola y añade al log una línea con el formato: `[YYYY-MM-DD HH:mm:ss] [ONLINE]  <equipo> respondió correctamente.`
- Si no responde o falla la resolución DNS, captura la excepción en el `catch`, imprimiendo en rojo y registrando: `[YYYY-MM-DD HH:mm:ss] [OFFLINE] <equipo> inaccesible: <mensaje_error>.`

**Ejemplo de ejecución esperado:**

```powershell
> .\Auditar-Servidores.ps1 -RutaArchivo ".\servidores.txt"
=== Auditando conectividad de 3 servidores ===
Registrando eventos en: C:\Users\Admin\AppData\Local\Temp\informe-conectividad.log

[2026-09-10 23:40:12] [ONLINE]  192.168.1.1 respondió correctamente.
[2026-09-10 23:40:14] [ONLINE]  dc01.empresa.local respondió correctamente.
[2026-09-10 23:40:17] [OFFLINE] srv-backup.empresa.local inaccesible: Testing connection to computer 'srv-backup.empresa.local' failed: Error due to lack of resources

Auditoría finalizada con éxito.
```

??? success "Ver solución"
    ```powershell
    # Auditar-Servidores.ps1
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Ruta del archivo de texto con la lista de servidores")]
        [string]$RutaArchivo,

        [string]$ArchivoLog = "$env:TEMP\informe-conectividad.log"
    )

    if (-not (Test-Path -LiteralPath $RutaArchivo)) {
        Write-Error "El archivo especificado '$RutaArchivo' no existe."
        exit 1
    }

    $servidores = Get-Content -Path $RutaArchivo | Where-Object { $_.Trim() -ne "" }
    $ahora = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

    Write-Host "=== Auditando conectividad de $($servidores.Count) servidores ===" -ForegroundColor Cyan
    Write-Host "Registrando eventos en: $ArchivoLog`n" -ForegroundColor DarkGray

    foreach ($equipo in $servidores) {
        $equipo = $equipo.Trim()
        try {
            $null = Test-Connection -ComputerName $equipo -Count 1 -TimeoutSeconds 2 -ErrorAction Stop
            $linea = "[$ahora] [ONLINE]  $equipo respondió correctamente."
            Write-Host $linea -ForegroundColor Green
            Add-Content -Path $ArchivoLog -Value $linea
        }
        catch {
            $linea = "[$ahora] [OFFLINE] $equipo inaccesible: $($_.Exception.Message)"
            Write-Host $linea -ForegroundColor Red
            Add-Content -Path $ArchivoLog -Value $linea
        }
    }

    Write-Host "`nAuditoría finalizada con éxito." -ForegroundColor Cyan
    ```

    **Ejemplo de ejecución:**
    ```powershell
    .\Auditar-Servidores.ps1 -RutaArchivo "C:\infra\hosts.txt" -ArchivoLog "C:\infra\ping_report.txt"
    ```

---

### Ejercicio 3. Supervisión y Recuperación de Servicios en Pipeline (`Reiniciar-ServiciosCriticos.ps1`)

**Problema:**  
Desarrolla un script de monitorización y recuperación llamado `Reiniciar-ServiciosCriticos.ps1` que procese una lista de servicios críticos a través del pipeline utilizando el cmdlet `ForEach-Object`:

- Recibe un parámetro opcional `-Servicios` con un array de nombres de servicios a vigilar (por defecto: `@('Spooler', 'wuauserv', 'Themes')`).
- Envía los nombres de los servicios a través del pipeline hacia `ForEach-Object`:
    - Para cada elemento recibido (`$_`), consulta el servicio mediante `Get-Service -Name $_ -ErrorAction SilentlyContinue`.
    - Si el servicio no existe, emite un mensaje de advertencia con `Write-Warning` y salta al siguiente elemento usando `return` (equivalente de `continue` dentro de un bloque de script de pipeline).
    - Si el servicio se encuentra en ejecución (`Running`), imprime un mensaje en verde indicando que el servicio opera con normalidad.
    - Si el servicio está detenido (`Stopped`), advierte en color amarillo e intenta arrancarlo con `Start-Service -ErrorAction Stop` protegido con un bloque `try/catch`. Si se inicia con éxito, lo confirma en verde; si falla (por ejemplo, por falta de privilegios de administrador), captura el error e imprime la causa en rojo.

**Ejemplo de ejecución esperado:**

```powershell
> .\Reiniciar-ServiciosCriticos.ps1 -Servicios "Spooler", "wuauserv", "ServicioInventado"
=== Comprobando estado de servicios críticos ===
[OK] El servicio 'Cola de impresión' (Spooler) está en ejecución.
[ADVERTENCIA] El servicio 'Windows Update' (wuauserv) está DETENIDO. Intentando iniciar...
[ÉXITO] El servicio 'wuauserv' se ha iniciado correctamente.
ADVERTENCIA: El servicio 'ServicioInventado' no existe o no está registrado en este equipo.
```

??? success "Ver solución"
    ```powershell
    # Reiniciar-ServiciosCriticos.ps1
    param(
        [string[]]$Servicios = @('Spooler', 'wuauserv', 'Themes')
    )

    Write-Host "=== Comprobando estado de servicios críticos ===" -ForegroundColor Cyan

    $Servicios | ForEach-Object {
        $nombre = $_
        $servicio = Get-Service -Name $nombre -ErrorAction SilentlyContinue

        if ($null -eq $servicio) {
            Write-Warning "El servicio '$nombre' no existe o no está registrado en este equipo."
            return  # En ForEach-Object se utiliza 'return' para saltar a la siguiente iteración
        }

        if ($servicio.Status -eq 'Running') {
            Write-Host "[OK] El servicio '$($servicio.DisplayName)' ($nombre) está en ejecución." -ForegroundColor Green
        }
        elseif ($servicio.Status -eq 'Stopped') {
            Write-Host "[ADVERTENCIA] El servicio '$($servicio.DisplayName)' está DETENIDO. Intentando iniciar..." -ForegroundColor Yellow
            try {
                Start-Service -Name $nombre -ErrorAction Stop
                Write-Host "[ÉXITO] El servicio '$nombre' se ha iniciado correctamente." -ForegroundColor Green
            }
            catch {
                Write-Host "[ERROR] No se pudo iniciar el servicio '$nombre': $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        else {
            Write-Host "[INFO] El servicio '$nombre' se encuentra en estado: $($servicio.Status)" -ForegroundColor Gray
        }
    }
    ```

    **Ejemplo de ejecución:**
    ```powershell
    .\Reiniciar-ServiciosCriticos.ps1 -Servicios "Dhcp", "Dnscache", "Spooler"
    ```

---

### Ejercicio 4. Creación Masiva de Usuarios Locales desde CSV (`Crear-UsuariosMasivos.ps1`)

**Problema:**  
Crea un script de aprovisionamiento masivo de identidades llamado `Crear-UsuariosMasivos.ps1` que lea un archivo CSV e itere para dar de alta cuentas de usuario local en el sistema Windows:

- Recibe como parámetro obligatorio `-RutaCsv` con la ruta al archivo `.csv`.
- El archivo CSV contiene las columnas: `Username`, `FullName`, `Description` y `Password`.
- Comprueba la existencia del archivo con `Test-Path`. Si no existe, cancela la ejecución con `exit 1`.
- Carga el contenido con `Import-Csv` y utiliza un bucle `foreach ($usuario in $listaUsuarios)` para procesar cada fila.
- En cada iteración:
    - Comprueba si el usuario ya existe mediante `Get-LocalUser -Name $usuario.Username -ErrorAction SilentlyContinue`.
    - Si la cuenta ya existe, muestra un aviso advirtiendo de que el usuario ya existe y salta a la siguiente fila mediante `continue`.
    - Si no existe, convierte la contraseña en texto claro a objeto seguro con `ConvertTo-SecureString -AsPlainText -Force` y crea el usuario local con `New-LocalUser`, estableciendo que la contraseña no caduque (`-PasswordNeverExpires`).
    - Envuelve la creación en un bloque `try/catch` para capturar cualquier incumplimiento de directivas de complejidad de contraseñas u otros errores del sistema operativo.

**Ejemplo de archivo `usuarios.csv`:**

```csv
Username,FullName,Description,Password
jlopez,Juan Lopez,Tecnico de Soporte,Temporal2026!
agarcia,Ana Garcia,Administradora de Red,Temporal2026!
mfernandez,Marta Fernandez,Desarrolladora Web,Temporal2026!
```

**Ejemplo de ejecución esperado:**

```powershell
> .\Crear-UsuariosMasivos.ps1 -RutaCsv ".\usuarios.csv"
=== Iniciando aprovisionamiento de 3 usuarios ===
[CREADO] Usuario 'jlopez' (Juan Lopez) creado con éxito.
[CREADO] Usuario 'agarcia' (Ana Garcia) creado con éxito.
ADVERTENCIA: El usuario 'mfernandez' ya existe en el sistema. Omitiendo...

Proceso de importación finalizado.
```

??? success "Ver solución"
    ```powershell
    # Crear-UsuariosMasivos.ps1
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Introduce la ruta al archivo CSV con los usuarios")]
        [string]$RutaCsv
    )

    if (-not (Test-Path -LiteralPath $RutaCsv)) {
        Write-Error "No se encuentra el archivo CSV en la ruta especificada: '$RutaCsv'."
        exit 1
    }

    $usuarios = Import-Csv -Path $RutaCsv -Delimiter ","
    Write-Host "=== Iniciando aprovisionamiento de $($usuarios.Count) usuarios ===" -ForegroundColor Cyan

    foreach ($usuario in $usuarios) {
        $nombreUsuario = $usuario.Username.Trim()

        # 1. Comprobamos si el usuario ya existe en el sistema local
        $existe = Get-LocalUser -Name $nombreUsuario -ErrorAction SilentlyContinue
        if ($existe) {
            Write-Warning "El usuario '$nombreUsuario' ya existe en el sistema. Omitiendo..."
            continue
        }

        try {
            # 2. Convertimos la contraseña en claro a SecureString
            $passSecure = ConvertTo-SecureString -String $usuario.Password -AsPlainText -Force

            # 3. Creamos el usuario local
            New-LocalUser -Name $nombreUsuario `
                          -FullName $usuario.FullName `
                          -Description $usuario.Description `
                          -Password $passSecure `
                          -PasswordNeverExpires `
                          -ErrorAction Stop | Out-Null

            Write-Host "[CREADO] Usuario '$nombreUsuario' ($($usuario.FullName)) creado con éxito." -ForegroundColor Green
        }
        catch {
            Write-Host "[ERROR] Falló la creación del usuario '$nombreUsuario': $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Write-Host "`nProceso de importación finalizado." -ForegroundColor Cyan
    ```

    **Ejemplo de ejecución:**
    ```powershell
    .\Crear-UsuariosMasivos.ps1 -RutaCsv "C:\datos\nuevos_empleados.csv"
    ```

---

### Ejercicio 5. Auditoría de Espacio en Disco con Umbrales de Alerta (`Auditar-DiscosForeach.ps1`)

**Problema:**  
Desarrolla un script de monitorización de almacenamiento llamado `Auditar-DiscosForeach.ps1` que examine el espacio libre de las unidades lógicas locales e informe si alguna desciende de un umbral de seguridad:

- **Parámetros:**
    - `-UmbralAlertaPorc`: Porcentaje mínimo de espacio libre tolerado (opcional, valor por defecto `15`).
    - `-Unidades`: Array opcional de letras de unidad a auditar (por ejemplo `@('C', 'D')`). Si no se especifica, el script consultará automáticamente todas las unidades locales de tipo disco fijo (`DriveType = 3`) mediante `Get-CimInstance Win32_LogicalDisk`.
- Utiliza un bucle `foreach ($disco in $discos)` para procesar cada unidad física detectada:
    - Calcula la capacidad total en Gigabytes: `[math]::Round($disco.Size / 1GB, 2)`.
    - Calcula el espacio libre en Gigabytes: `[math]::Round($disco.FreeSpace / 1GB, 2)`.
    - Calcula el porcentaje de espacio libre: `[math]::Round(($disco.FreeSpace / $disco.Size) * 100, 2)`.
- Muestra una ficha por consola para cada unidad con su identificador, etiqueta de volumen y valores calculados.
- Si el porcentaje de espacio libre es inferior o igual a `-UmbralAlertaPorc`, resalta la unidad con un mensaje en color rojo indicando `[CRÍTICO]`. En caso contrario, muestra un estado `[CORRECTO]` en verde.
- Al terminar el bucle, genera y proyecta por pantalla una tabla resumen con `Format-Table` que recopile todas las unidades analizadas y su diagnóstico.

**Ejemplo de ejecución esperado:**

```powershell
> .\Auditar-DiscosForeach.ps1 -UmbralAlertaPorc 20
=== Auditoría de Almacenamiento (Umbral mínimo de espacio libre: 20 %) ===

--------------------------------------------------
Unidad: C: [Sistema]
  Capacidad total: 476.12 GB
  Espacio ocupado: 395.20 GB
  Espacio libre:   80.92 GB (17.00 %)
  ESTADO: [CRÍTICO] Espacio libre por debajo del umbral del 20 %.
--------------------------------------------------
Unidad: D: [Datos]
  Capacidad total: 931.51 GB
  Espacio ocupado: 412.10 GB
  Espacio libre:   519.41 GB (55.76 %)
  ESTADO: [CORRECTO] Espacio libre suficiente.

=== Tabla Resumen de Unidades ===

Unidad Etiqueta Total (GB) Libre (GB) % Libre Estado
------ -------- ---------- ---------- ------- ------
C:     Sistema      476.12      80.92 17.00 % CRÍTICO
D:     Datos        931.51     519.41 55.76 % OK
```

??? success "Ver solución"
    ```powershell
    # Auditar-DiscosForeach.ps1
    param(
        [int]$UmbralAlertaPorc = 15,
        [string[]]$Unidades
    )

    # Obtenemos las unidades fijas locales (DriveType = 3) o filtramos las solicitadas
    if (-not $Unidades) {
        $discos = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType = 3"
    }
    else {
        $discos = foreach ($letra in $Unidades) {
            $devId = if ($letra.EndsWith(':')) { $letra } else { "$letra`:" }
            Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID = '$devId'"
        }
    }

    Write-Host "=== Auditoría de Almacenamiento (Umbral mínimo de espacio libre: $UmbralAlertaPorc %) ===`n" -ForegroundColor Cyan

    $resumenDiscos = @()

    foreach ($disco in $discos) {
        if ($null -eq $disco -or $disco.Size -eq 0) { continue }

        $totalGB = [math]::Round($disco.Size / 1GB, 2)
        $libreGB = [math]::Round($disco.FreeSpace / 1GB, 2)
        $usadoGB = [math]::Round(($disco.Size - $disco.FreeSpace) / 1GB, 2)
        $porcentajeLibre = [math]::Round(($disco.FreeSpace / $disco.Size) * 100, 2)

        Write-Host "--------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "Unidad: $($disco.DeviceID) [$($disco.VolumeName)]" -ForegroundColor White
        Write-Host "  Capacidad total: $totalGB GB"
        Write-Host "  Espacio ocupado: $usadoGB GB"
        Write-Host "  Espacio libre:   $libreGB GB ($porcentajeLibre %)"

        $estadoAlerta = $false
        if ($porcentajeLibre -le $UmbralAlertaPorc) {
            Write-Host "  ESTADO: [CRÍTICO] Espacio libre por debajo del umbral del $UmbralAlertaPorc %." -ForegroundColor Red
            $estadoAlerta = $true
        }
        else {
            Write-Host "  ESTADO: [CORRECTO] Espacio libre suficiente." -ForegroundColor Green
        }

        # Almacenamos el objeto personalizado para la tabla resumen
        $resumenDiscos += [PSCustomObject]@{
            Unidad         = $disco.DeviceID
            Etiqueta       = $disco.VolumeName
            'Total (GB)'   = $totalGB
            'Libre (GB)'   = $libreGB
            '% Libre'      = "$porcentajeLibre %"
            Estado         = if ($estadoAlerta) { "CRÍTICO" } else { "OK" }
        }
    }

    Write-Host "`n=== Tabla Resumen de Unidades ===" -ForegroundColor Cyan
    $resumenDiscos | Format-Table -AutoSize
    ```

    **Ejemplos de ejecución:**
    ```powershell
    # 1. Auditar todas las unidades con el umbral por defecto (15%)
    .\Auditar-DiscosForeach.ps1

    # 2. Auditar unidades específicas con un umbral del 20%
    .\Auditar-DiscosForeach.ps1 -Unidades "C", "D" -UmbralAlertaPorc 20
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
