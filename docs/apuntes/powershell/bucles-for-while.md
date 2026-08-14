# Estructuras de Control: Bucles For y While en PowerShell

Las estructuras de control de bucles (o ciclos) nos permiten ejecutar repetidamente un bloque de código. La elección del bucle adecuado depende de si conocemos de antemano el número de iteraciones o si la repetición depende de una condición dinámica.

## Bucle `For`

Cuando se requiere la ejecución de una serie de instrucciones de forma repetitiva durante un **número determinado de veces**, basándose en una condición numérica o un contador, se suele utilizar el bucle `for`.

La sintaxis básica es:

```powershell
For ( Inicio; Condición; Variador ) {
    # Instrucciones a repetir
}
```
* **Inicio:** Se ejecuta una única vez antes de empezar el bucle (generalmente se usa para inicializar la variable contador).
* **Condición:** Se evalúa antes de cada iteración. Si es `$true`, se ejecuta el bloque de instrucciones. Si es `$false`, el bucle termina.
* **Variador:** Se ejecuta al final de cada iteración (generalmente se usa para incrementar o decrementar el contador).

### Ejemplo de Bucle `For`

En este ejemplo inicializamos el contador `$i` a `0`. El bucle continuará mientras `$i` sea menor que `4` (`-lt 4`), e incrementará `$i` en 1 (`$i++`) en cada iteración.

```powershell
PS C:\> for ( $i = 0; $i -lt 4; $i++ ) {
>>     "`$i:$i"
>> }
$i:0
$i:1
$i:2
$i:3
```

## Bucle `While`

Cuando se requiere la ejecución de una serie de instrucciones de forma repetitiva **siempre y cuando se cumpla una determinada condición**, sin saber de antemano cuántas iteraciones habrá, se utiliza el bucle `while`.

La sintaxis básica es:

```powershell
while ( condición ) {
    # Instrucciones a repetir mientras la condición sea verdadera
}
```

### Ejemplo de Bucle `While`

En este ejemplo se recorre un array `$a`. Mientras que la variable de índice `$x` sea menor que el número total de elementos del array (`$a.Count`), se ejecutarán las instrucciones y se sumará 1 al índice.

```powershell
PS C:\> $a = @(0,1,2,3,4,5)
PS C:\> $x = 0
PS C:\> while ( $x -lt $a.Count ) {
>> Write-Host "Iteración $x. Valor de `$a[$x]: $($a[$x])"
>> $x++
>> }
Iteración 0. Valor de $a[0]: 0
Iteración 1. Valor de $a[1]: 1
Iteración 2. Valor de $a[2]: 2
Iteración 3. Valor de $a[3]: 3
Iteración 4. Valor de $a[4]: 4
Iteración 5. Valor de $a[5]: 5
```

!!! warning "El peligro de los bucles infinitos"
    Al usar bucles `while`, es fundamental asegurarse de que la condición evaluada cambiará en algún momento. En el ejemplo anterior, si olvidamos incluir la línea `$x++`, la variable `$x` siempre valdrá `0`, la condición `$x -lt $a.Count` siempre será verdadera, y el script se quedará atascado en un bucle infinito bloqueando la consola.

## Alterando el flujo: `Break` y `Continue`

En cualquier tipo de bucle (`for`, `while`, etc.), existen dos palabras clave que nos permiten alterar su comportamiento normal desde dentro del bloque de código:

* **`break`**: Detiene inmediatamente la ejecución del bucle por completo. El script continuará ejecutando lo que haya después del cierre del bucle.
* **`continue`**: Detiene inmediatamente la *iteración actual* y salta de nuevo arriba para evaluar la condición y continuar con la *siguiente* iteración.

## Otras Estructuras de Bucle (`Do-While` / `Do-Until`)

Además de `for` y `while`, existen otras estructuras de bucles que garantizan que el código se ejecute al menos una vez antes de evaluar la condición:

### Bucle `Do...While`
Ejecuta el bloque y **luego** comprueba la condición. Si la condición es `$true`, repite.
```powershell
do {
    # Instrucciones
} while ( condición )
```

### Bucle `Do...Until`
Ejecuta el bloque y **luego** comprueba la condición. Si la condición es `$false`, repite (repite *hasta que* sea verdadero).
```powershell
do {
    # Instrucciones
} until ( condición )
```

Estas estructuras son similares a las anteriores y presentan únicamente ligeras diferencias en cuanto a cuándo se lanzan las instrucciones (antes o después de comprobar la condición) o si la condición es de parada o de continuidad.

## Ejemplos Prácticos

### 1. Script con Parámetros y Bucle For

A continuación se muestra un ejemplo de un script que recibe un parámetro por línea de comandos e incluye un bucle `for` en su interior. En este caso, el script repetirá un mensaje tantas veces como se le indique en el parámetro `$NumeroVeces`.

```powershell
param (
    [Parameter(Mandatory=$false)]
    [int]$NumeroVeces = 3
)

Write-Host "Se va a ejecutar el bucle $NumeroVeces veces." -ForegroundColor Cyan

for ($i = 1; $i -le $NumeroVeces; $i++) {
    Write-Host "Esta es la iteración número $i"
}

Write-Host "Fin de la ejecución." -ForegroundColor Green
```

### 2. Script con Parámetros y Bucle While

Este segundo ejemplo muestra un script que simula una cuenta hacia atrás utilizando un bucle `while`. Recibe por parámetro un valor inicial desde el cual comenzar la cuenta regresiva.

```powershell
param (
    [Parameter(Mandatory=$false)]
    [int]$CuentaAtras = 5
)

Write-Host "Iniciando cuenta atrás desde $CuentaAtras..." -ForegroundColor Yellow

$contador = $CuentaAtras
while ($contador -gt 0) {
    Write-Host $contador
    Start-Sleep -Seconds 1
    $contador--
}

Write-Host "¡Despegue!" -ForegroundColor Red
```

### 3. Script con Parámetros, Get-Service y Bucle For

Este ejemplo muestra un script de administración que recibe un array de nombres de servicios por parámetro y utiliza un bucle `for` para comprobar el estado de cada uno de ellos mediante el cmdlet `Get-Service`.

```powershell
param (
    [Parameter(Mandatory=$false)]
    [string[]]$Servicios = @("Spooler", "wuauserv", "Bits")
)

Write-Host "Comprobando el estado de $($Servicios.Count) servicios..." -ForegroundColor Cyan

for ($i = 0; $i -lt $Servicios.Count; $i++) {
    $nombreServicio = $Servicios[$i]
    $servicio = Get-Service -Name $nombreServicio -ErrorAction SilentlyContinue
    
    if ($servicio) {
        Write-Host "El servicio '$nombreServicio' está en estado: $($servicio.Status)"
    } else {
        Write-Host "El servicio '$nombreServicio' no se ha encontrado." -ForegroundColor Red
    }
}

Write-Host "Comprobación finalizada." -ForegroundColor Green
```

### 4. Script con Parámetros, Get-Process y Bucle While

Este script administrador recibe el nombre de un proceso y un tiempo máximo de espera. Utiliza un bucle `while` combinado con `Get-Process` para esperar hasta que el proceso especificado se esté ejecutando, comprobando cada segundo.

```powershell
param (
    [Parameter(Mandatory=$true)]
    [string]$NombreProceso,
    
    [Parameter(Mandatory=$false)]
    [int]$TiempoEsperaMaximo = 30
)

Write-Host "Esperando a que el proceso '$NombreProceso' se inicie (Máximo $TiempoEsperaMaximo segundos)..." -ForegroundColor Yellow

$segundosTranscurridos = 0
$procesoIniciado = $false

while ($segundosTranscurridos -lt $TiempoEsperaMaximo -and -not $procesoIniciado) {
    $proceso = Get-Process -Name $NombreProceso -ErrorAction SilentlyContinue
    
    if ($proceso) {
        $procesoIniciado = $true
        Write-Host "¡El proceso '$NombreProceso' se está ejecutando!" -ForegroundColor Green
    } else {
        Start-Sleep -Seconds 1
        $segundosTranscurridos++
        Write-Host "Esperando... ($segundosTranscurridos/$TiempoEsperaMaximo)"
    }
}

if (-not $procesoIniciado) {
    Write-Host "Se agotó el tiempo de espera y el proceso '$NombreProceso' no se inició." -ForegroundColor Red
}
```

---

## 📚 Referencias y Fuentes Consultadas

!!! info "Documentación Oficial y Autoría"
    * **Material Base:** Presentación de clase *«PowerShell. Estructuras de control Bucles For/While»*.
    * **Autoría del Temario:** José Ramón Soria Nieto.
    * **Marco Curricular:** Programación didáctica para el módulo de *Administración de Sistemas Operativos (ASO)* del Ciclo Formativo de Grado Superior en *Administración de Sistemas Informáticos en Red (ASIR/ASIX)*.
    * **Documentación Oficial:** [Documentación oficial de PowerShell (Microsoft Learn)](https://learn.microsoft.com/es-es/powershell/)

!!! abstract "Cofinanciación y Soporte Institucional"
    * **Entidad Educativa:** Generalitat Valenciana — Conselleria d'Educació, Cultura i Esport.
    * **Fondo de Financiación:** Proyecto cofinanciado por la **Unión Europea** a través del **Fondo Social Europeo (FSE)**. 
    * *«El FSE invierte en tu futuro»* — Acciones orientadas al impulso de la educación, formación avanzada y preparación para el mercado laboral técnico.
