# Introducción a Scripts en PowerShell

## ¿Qué es un script?

Un administrador de sistemas debe buscar el modo de automatizar aquellas tareas que realiza de forma repetitiva. Una tarea a menudo se compone de varias acciones (comandos) que siguen un orden, una secuencia, que resulta óptima o adecuada (lógica de programación).

Por ejemplo, para crear un usuario local en el equipo debo conocer en primer lugar los datos del usuario, a continuación lanzar el comando de creación del usuario con los datos anteriores y por último, verificar que se ha creado correctamente.

Si la tarea es repetitiva, es decir, los comandos lanzados siempre son los mismos y cambian únicamente en los datos o valores de sus parámetros, además de seguir siempre una misma lógica, se considera adecuado reunir la tarea en uno o varios scripts.

Un script es un **fichero de texto** que contiene todas las acciones de la tarea y en su orden.

- El fichero será **ejecutable**. Es decir, se podrá lanzar para ser interpretado por PowerShell que lo leerá y llevará a cabo las acciones.
- Podrá admitir **parámetros de entrada** para recoger los datos adicionales que necesite.

## Seguridad en los Scripts

Las extensiones de ficheros scripts en PowerShell son: `.ps1`, `.psm1`, `.ps1xml`. La aplicación más sencilla para crear scripts en PowerShell es el Bloc de Notas (Notepad). Sin embargo, se recomienda encarecidamente utilizar entornos integrados como **PowerShell ISE** o **Visual Studio Code**, ya que colorean la sintaxis y facilitan la depuración.

Para lanzar un script:

- Se debe lanzar indicando su ruta completa (con el directorio delante).
- **Por defecto, PowerShell no lanza scripts.**

### Política de Ejecución

Existen diferentes grados de restricción en cuanto a la ejecución de scripts en PowerShell:

- **Restricted**: No se pueden ejecutar scripts. Es lo que tendremos inicialmente.
- **RemoteSigned**: Permite la ejecución de scripts localmente y también los descargados de internet que estén firmados digitalmente por alguna autoridad reconocida. Es seguro si el acceso al servidor está restringido y la ejecución local de scripts controlada.
- **AllSigned**: Todos los scripts, locales o descargados, deben estar firmados digitalmente e incluso, si se modifican, se deben volver a firmar. Lo más seguro en entornos en producción.
- **Unrestricted**: Sin restricciones, se puede ejecutar cualquier script, local o descargado, sin necesidad de que esté firmado. Para pruebas puede ser válido pero no en producción.
- **ByPass**: No se bloquea ninguna ejecución ni se muestran avisos o notificaciones. Se usa cuando el script forma parte de una aplicación más grande que lleva su propio control de seguridad y no es necesario el de PowerShell.

Para ver la política de seguridad actual:
```powershell
Get-ExecutionPolicy
```

Para cambiar la política de seguridad:
```powershell
Set-ExecutionPolicy Política_de_Seguridad
```
*(Nota: En nuestro curso utilizaremos `RemoteSigned`)*.

### Ejecución de Scripts

Se debe usar la ruta del script para su ejecución:

- `C:\scripts\prueba.ps1`
- `\scripts\prueba.ps1`
- O si nos encontramos ya en la ruta `C:\scripts`:
  `.\prueba.ps1`

*(El punto `.` representa el directorio actual en el que nos encontramos, indicando a PowerShell explícitamente que busque el script ahí)*.

Al indicar explícitamente la ruta se consigue que no haya dudas del fichero que ejecutamos y evitar *hijacking* (secuestro, es decir, que otro script con el mismo nombre se ejecute en vez del nuestro). No se requiere la extensión del fichero aunque es recomendable.

## Ámbito (*Scope*) de los Scripts

Cuando se lanza un script, las variables que crea se quedan dentro del ámbito de ejecución (*scope*), es decir, que si la ejecución finaliza, las variables se borran y desaparecen.

Al iniciar PowerShell:

- Se crea un ámbito **Global** (`$global:`).
- Los scripts que se lancen dentro crearán un ámbito local para ese script (`$script:`).

Cuando se referencia una variable dentro de un script, esta se busca en el ámbito del script y:

- si no se encuentra, se pasa a buscar en el ámbito padre, que podría ser otro script que hubiera lanzado el actual.
- si tampoco se encuentra en el padre, se busca en el padre del padre, y así sucesivamente, hasta el ámbito Global.
- si finalmente lo encuentra, funciona (OK), y si no lo encuentra, devuelve error.

### Ejemplo de Ámbito: EstableceX.ps1

Por ejemplo, creamos el script `EstableceX.ps1`:

```powershell
Write-Host "Estoy ejecutando un script" -ForegroundColor Green
if ($x) {
    Write-Host "Encontrada una variable con un valor de $x" -ForegroundColor yellow
}
# Hacer algo con $x
$x + $x
```

En su ejecución, se observa en primer lugar que, al no existir la variable `$x` en el ámbito global, el script sólo muestra el mensaje inicial. Sin embargo, al crear `$x` directamente en la consola (ámbito global) y volver a lanzar el script, este la reconoce (la busca y la encuentra en el ámbito padre) y opera con ella:

```powershell
PS C:\> .\EstableceX.ps1
Estoy ejecutando un script

PS C:\> $x = 50
PS C:\> .\EstableceX.ps1
Estoy ejecutando un script
Encontrada una variable con un valor de 50
100
```

### Ejemplo de Ámbito: EstableceX2.ps1

Creamos otro script, `EstableceX2.ps1`, que además de leer la variable, le asigna un nuevo valor localmente:

```powershell
Write-Host "Estoy ejecutando un script" -ForegroundColor Green
if ($x) {
    Write-Host "Encontrada una variable con un valor de $x" -ForegroundColor yellow
}
[int32]$x = Read-Host "Introduce un nuevo valor para X"
Write-Host "Establezco `$x a $x" -ForegroundColor Green

# Hacer algo con $x
$x + $x
```

Si lo ejecutamos a continuación del paso anterior (donde el `$x` global valía 50):

```powershell
PS C:\> .\EstableceX2.ps1
Estoy ejecutando un script
Encontrada una variable con un valor de 50
Introduce un nuevo valor para X: 40
Establezco $x a 40
80

PS C:\> $x
50
```

En esta ejecución se observa que el script lee el valor global de `$x` (50), pero luego crea una **nueva variable local** `$x` dentro de su propio ámbito (asignándole el valor 40). Una vez finaliza el script, ese `$x` local desaparece, y si consultamos de nuevo `$x` en la consola, comprobaremos que el `$x` global se mantiene inalterado con su valor original de 50.

## Primeros Scripts

### Ejemplo 1: Operaciones básicas 

Ejemplo de script que almacena en una variable un número y lo multiplica por otro mostrando el resultado, numcalc.ps1,:
```powershell
$numero = 12
Write-Output "El número es $numero"
Write-Output "El cálculo $numero * 5 es $($numero * 5)"
```

### Ejemplo 2: Información de disco

Ejemplo de script que pide una letra de unidad de disco y muestra su tamaño libre, tamlibre.ps1,:
```powershell
[char]$Unidad = Read-Host "Indica la letra de la unidad de disco (C,D, ...)"
$ObjetoUnidad = Get-PSDrive $Unidad
$tamLibre = $ObjetoUnidad.Free
Write-Output "El espacio libre de $($Unidad): es $tamLibre"
```

### Ejemplo 3: Filtrado, agrupación y ordenamiento de Logs (Reporte HTML)

Podemos generar un reporte en HTML de la cuenta de logs de error según la aplicación que los proporciona, usando filtrado, agrupación y ordenación:

- El siguiente comando muestra logs con nivel 2 (error) en el log `System`:
  ```powershell
  Get-WinEvent -FilterHashTable @{ LogName = 'System'; Level = 2 }
  ```
- Con `Group-Object` podemos agrupar los errores en función del proveedor del error. De este modo, tendremos el número de errores de esa aplicación:
  ```powershell
  Get-WinEvent -FilterHashTable @{ LogName = 'System'; Level = 2 } | Group-Object -Property ProviderName -NoElement
  ```
- Y mediante `Sort-Object` podemos ordenar de forma descendente el resultado por el contador de errores.
  ```powershell
  Get-WinEvent -FilterHashTable @{ LogName = 'System'; Level = 2 } | Group-Object -Property ProviderName -NoElement | Sort-Object -Property Count -Descending
  ```

A continuación, uniendo estos comandos con el pipeline, generamos un documento HTML completo, script logsystemhtml.ps1:

```powershell
# Realizar una ruptura de fuentes de error en el log System
# Empezar con un comando que trabaja en la consola
$NombreEquipo = $env:COMPUTERNAME
$datos = Get-WinEvent -FilterHashtable @{ LogName='System';Level=2 } | Group-Object -Property ProviderName -NoElement

# Crear un informe HTML
$Titulo = "Análisis del log System"
$piedepagina = "<h5>Informe generado el $(Get-Date)</h5>"
$css = "http://jdhitsolutions.com/sample.css"

$datos | Sort-Object -Property Count,Name -Descending | Select-Object Count,Name | 
ConvertTo-Html -Title $Titulo -PreContent "<H1>$NombreEquipo</H1>" -PostContent $piedepagina -CssUri $css | 
Out-File C:\scripts\Logs\origenErrorSystem.html
```

### Ejemplo 4: Consulta de hardware y configuración de red

Ejemplo de script que consulta características de hardware y configuración de red del equipo, script consultaEquipo.ps1:

```powershell
# Muestra características hardware y de configuración de red de un equipo

$NombreEquipo = $env:COMPUTERNAME
Write-Host "Equipo: $NombreEquipo"

# Tipo de Sistema Operativo
$TipoSO = (Get-CimInstance Win32_OperatingSystem -ComputerName $env:COMPUTERNAME).Caption
Write-Host "Tipo SO: $TipoSO"

# Espacio libre en dispositivo C:
$EspacioLibreC = ((Get-CimInstance CIM_LogicalDisk | Where-Object -Property DeviceID -eq 'C:').FreeSpace)/1gb
Write-Host "Espacio en C disponible: $EspacioLibreC GB"

# Cantidad de memoria del sistema
$Memoria = (((Get-CimInstance Win32_PhysicalMemory -ComputerName $env:COMPUTERNAME).Capacity | Measure-Object -Sum).Sum)/1gb
Write-Host "Memoria Total: $Memoria GB"

# Último reinicio del sistema
$UltimoInicio = (Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $env:COMPUTERNAME).LastBootUpTime
Write-Host "Último reinicio: $UltimoInicio"

# Nombre del interfaz de red, IP y servidores DNS
$esc = [char]27
$columna1 = 30
$columna2 = 60
$posicion1 = "$esc`[$($columna1)G"
$posicion2 = "$esc`[$($columna2)G"
$lineaRayas = "-------------------------------------------------------------------------------"

Get-NetIPAddress | Foreach-Object `
-Begin { Write-Host "Interfaz${posicion1}Dirección IP${posicion2}Dirección DNS`n$lineaRayas" } `
-Process { Write-Host ($_.InterfaceAlias, $posicion1, $_.IPAddress, $posicion2, [string]((Get-DnsClientServerAddress -InterfaceAlias $_.InterfaceAlias).ServerAddresses)) } `
-End { Write-Host "$lineaRayas" }
```

---

## 📚 Referencias y Fuentes Consultadas

!!! info "Documentación Oficial y Autoría"
    * **Material Base:** Presentación de clase *«PowerShell. Scripts»*.
    * **Autoría del Temario:** José Ramón Soria Nieto.
    * **Marco Curricular:** Programación didáctica para el módulo de *Administración de Sistemas Operativos (ASO)* del Ciclo Formativo de Grado Superior en *Administración de Sistemas Informáticos en Red (ASIR/ASIX)*.
    * **Documentación Oficial:** [Documentación oficial de PowerShell (Microsoft Learn)](https://learn.microsoft.com/es-es/powershell/)

!!! abstract "Cofinanciación y Soporte Institucional"
    * **Entidad Educativa:** Generalitat Valenciana — Conselleria d'Educació, Cultura i Esport.
    * **Fondo de Financiación:** Proyecto cofinanciado por la **Unión Europea** a través del **Fondo Social Europeo (FSE)**. 
    * *«El FSE invierte en tu futuro»* — Acciones orientadas al impulso de la educación, formación avanzada y preparación para el mercado laboral técnico.
