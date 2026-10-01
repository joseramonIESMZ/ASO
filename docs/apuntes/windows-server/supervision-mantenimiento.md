# Supervisión y mantenimiento de sistemas

La administración de un servidor continúa después de instalar sus servicios. Es necesario comprobar cómo funciona, reconocer desviaciones, investigar sus causas y realizar tareas que mantengan su disponibilidad y seguridad.

En este tema aprenderemos a supervisar Windows Server mediante contadores de rendimiento, eventos y consultas CIM; conservar mediciones; programar comprobaciones; y verificar el resultado de las actuaciones de mantenimiento.

## 🎯 Relación con el currículo (RA y CE)

Los contenidos se relacionan con los siguientes resultados de aprendizaje del módulo **Administración de Sistemas Operativos (ASO, código 0374)**. La tabla resume su aplicación didáctica; no reproduce literalmente los criterios de evaluación.

| Resultado de aprendizaje | CE relacionados | Aplicación en este tema |
| :--- | :--- | :--- |
| **RA2. Administración de procesos del sistema** | **2.f** | Utilización de herramientas gráficas y comandos para el control y seguimiento de procesos. |
| **RA3. Automatización de tareas del sistema** | **3.a, 3.b, 3.c, 3.d y 3.h**; **3.g** si se utiliza la consola gráfica | Justificación de la automatización, planificación de comprobaciones, restricciones de seguridad y documentación de las tareas. |
| **RA7. Utilización de lenguajes de guiones** | **7.a, 7.b, 7.d, 7.f y 7.i** | Creación, adaptación, depuración, prueba y documentación de scripts de supervisión. |
| **RA4. Administración remota** | **4.c y 4.e**, cuando la práctica se realiza a distancia | Uso de herramientas y comandos para administrar el servidor desde el equipo cliente. |

La monitorización general también conecta con el **RA6 de Implantación de Sistemas Operativos**. Esta conexión no convierte dicho RA en un resultado propio de ASO. La lectura de los apuntes, por sí sola, no acredita la consecución de los criterios: es necesario observar su aplicación práctica.

## 🏢 1. Fundamentos de la supervisión y el mantenimiento

### 1.1. Qué supervisamos

La **supervisión** consiste en obtener e interpretar información sobre el funcionamiento del sistema. Incluye tres perspectivas complementarias:

| Perspectiva | Pregunta | Ejemplo |
| :--- | :--- | :--- |
| **Rendimiento** | ¿Cómo utiliza sus recursos? | CPU, memoria disponible, latencia de disco y tráfico de red. |
| **Estado y disponibilidad** | ¿Están disponibles los componentes y funcionan los servicios? | Estado del servicio DNS y respuesta a una consulta real. |
| **Eventos** | ¿Qué ha sucedido y cuándo? | Error de un servicio, fallo de una tarea o incidencia de almacenamiento. |

Una CPU poco utilizada no garantiza que DNS responda correctamente. Del mismo modo, un servicio en ejecución puede presentar errores funcionales. Por eso combinamos métricas, estados, eventos y pruebas del servicio.

### 1.2. Tipos de mantenimiento

- **Preventivo:** reduce la probabilidad de incidentes. Incluye comprobar copias, revisar capacidad, aplicar actualizaciones planificadas y verificar tareas programadas.
- **Correctivo:** resuelve una incidencia identificada. Por ejemplo, corregir una configuración que impide iniciar un servicio.
- **Evolutivo:** adapta el sistema a nuevas necesidades, como ampliar capacidad o modificar su configuración ante un crecimiento de la carga.

Toda actuación debe tener un objetivo, una comprobación previa y una validación posterior. Cuando modifica el sistema, también necesita una previsión de su impacto y un procedimiento de recuperación.

!!! tip "Supervisar para decidir"
    El objetivo no es reunir el mayor número de contadores, sino obtener información suficiente para detectar un problema, formular una hipótesis y comprobar si la actuación realizada lo resuelve.

## 🛠️ 2. Herramientas y entorno de trabajo

| Herramienta | Comando o acceso | Utilidad |
| :--- | :--- | :--- |
| Monitor de rendimiento | `perfmon.exe` | Visualizar contadores y analizar registros históricos. |
| Monitor de recursos | `resmon.exe` | Relacionar procesos con actividad de CPU, memoria, disco y red. |
| Visor de eventos | `eventvwr.msc` | Consultar registros del sistema, aplicaciones y servicios. |
| Administrador de tareas | `taskmgr.exe` | Primera revisión de procesos y recursos en entornos con interfaz gráfica. |
| Windows PowerShell 5.1 | `powershell.exe` | Ejecutar los ejemplos de administración de este tema. |
| PowerShell 7 | `pwsh.exe` | Entorno adicional que se instala por separado; debe comprobarse la compatibilidad de los módulos utilizados. |
| Recopiladores por comandos | `logman.exe` | Crear, iniciar y detener conjuntos de recopiladores de datos. |
| Programador de tareas | `taskschd.msc` o módulo `ScheduledTasks` | Ejecutar comprobaciones y mantenimiento de forma planificada. |
| Windows Admin Center | Navegador y puerta de enlace previamente desplegada | Administración y supervisión remotas. |

**Entorno de referencia:** Windows Server del laboratorio, preferentemente Server Core, y clientes Windows 11. Los ejemplos utilizan Windows PowerShell 5.1 y contadores de una instalación en español, salvo indicación expresa.

!!! info "Aclaración: Server Core no equivale a .NET Core / PowerShell 7"
    El término **Server Core** hace referencia a la modalidad de instalación mínima sin interfaz gráfica de escritorio (GUI), no al runtime *.NET Core*. Incluso en Windows Server 2025, el sistema incluye de forma nativa **Windows PowerShell 5.1** (basado en .NET Framework), que es el entorno que procesa los comandos por defecto cuando nos conectamos mediante PowerShell Remoting (WinRM). PowerShell 7 (`pwsh.exe`) es opcional y requiere instalación explícita.

En **Server Core**, utilizaremos principalmente PowerShell y comandos. Las consolas gráficas se emplearán desde un equipo de administración o un servidor con experiencia de escritorio; no se presupone que todas estén disponibles localmente en Core.

Antes de comenzar:

1. Identifica el servidor, sus roles, vCPU, RAM y discos asignados.
2. Comprueba la versión de PowerShell con `$PSVersionTable.PSVersion`.
3. Revisa los permisos de consulta. Algunos contadores y registros requieren privilegios adicionales.
4. Comprueba los nombres reales de los contadores de esa instalación.
5. Reserva una carpeta para las mediciones y otra para los scripts.

```powershell
New-Item -Path 'C:\ASO\Scripts', 'C:\ASO\Registros' -ItemType Directory -Force
```

Para consultar un Server Core desde una sesión remota ya configurada, puede ejecutarse el bloque en el servidor:

```powershell
# Sustituye el nombre por el de tu servidor. Requiere WinRM configurado.
Invoke-Command -ComputerName 'DC01.int.asix.info' -ScriptBlock {
    Get-CimInstance -ClassName Win32_OperatingSystem |
        Select-Object CSName, Caption, LastBootUpTime
}
```

`Get-Counter -ComputerName` y las conexiones remotas de las consolas pueden tener requisitos de comunicación distintos de WinRM. En los ejemplos con `Invoke-Command`, la consulta se ejecuta localmente dentro de la sesión del servidor.

## 💻 3. Contadores de rendimiento

### 3.1. Objeto, instancia y contador

Un contador es una métrica asociada a un componente del sistema. Su ruta habitual es:

```text
\Objeto(Instancia)\Contador
```

| Elemento | Significado | Ejemplo |
| :--- | :--- | :--- |
| Objeto | Componente que se supervisa | `Procesador` |
| Instancia | Elemento concreto de ese componente | `0`, `1` o `_Total` |
| Contador | Magnitud que se mide | `% de tiempo de procesador` |

Por ejemplo, `\Procesador(_Total)\% de tiempo de procesador` muestra la utilización global de CPU. En este contador, `_Total` representa el promedio de utilización de los procesadores lógicos. No debe interpretarse siempre como una suma: la agregación depende del contador.

Otros objetos, como `Memoria`, no necesitan instancia:

```text
\Memoria\MBytes disponibles
```

El comodín `*` selecciona varias instancias. En una instalación en inglés, la ruta correcta para el tráfico total de cada interfaz es:

```text
\Network Interface(*)\Bytes Total/sec
```

Esto devuelve **un resultado por interfaz**, cada uno con su tráfico enviado y recibido. No suma automáticamente todas las tarjetas. El nombre de la instancia se obtiene del sistema y no tiene por qué coincidir con el alias `Ethernet`.

### 3.2. Descubrir las rutas reales

Los nombres de los contadores están localizados. No basta con traducir una ruta inglesa al castellano: hay que consultar los conjuntos registrados.

```powershell
# Conjuntos disponibles. Pueden aparecer errores de acceso a algunos conjuntos.
Get-Counter -ListSet * | Select-Object CounterSetName

# Rutas del conjunto Memoria en una instalación en español.
(Get-Counter -ListSet 'Memoria').Paths

# Rutas con las instancias reales de discos e interfaces.
(Get-Counter -ListSet 'Disco físico').PathsWithInstances
(Get-Counter -ListSet 'Interfaz de red').PathsWithInstances
```

En las propiedades del contador de PerfMon también puede consultarse su descripción. Los nombres de esta página son referencias para localizar las métricas; **las rutas que devuelve tu servidor son las que debes utilizar**.

### 3.3. Leer las muestras

```powershell
$Muestra = Get-Counter -Counter '\Memoria\MBytes disponibles' -ErrorAction Stop
$Muestra.CounterSamples | Select-Object Path, InstanceName, CookedValue, Status
```

- **`Timestamp`:** momento de la medición, disponible en el conjunto de muestras.
- **`CounterSamples`:** colección de muestras de los contadores solicitados.
- **`Path` e `InstanceName`:** identifican qué se ha medido.
- **`CookedValue`:** valor calculado según el tipo de contador; no es simplemente un número bruto.
- **`Status`:** estado de validez de la muestra. Los estados `0` y `1` corresponden a datos válidos o nuevos datos válidos.

Para obtener solo la memoria disponible:

```powershell
$Muestra.CounterSamples.CookedValue
```

Este acceso puede devolver varios valores si la consulta contiene múltiples contadores o instancias. En esos casos hay que conservar la ruta para saber a qué corresponde cada dato.

Para observar la evolución:

```powershell
Get-Counter -Counter '\Procesador(_Total)\% de tiempo de procesador' `
    -SampleInterval 2 -MaxSamples 5
```

Se obtienen cinco conjuntos de muestras, con un intervalo de dos segundos. Es una demostración del muestreo, no una línea base representativa.

## 📋 4. Interpretación de los contadores principales

### 4.1. Procesador

| Contador de referencia | Qué aporta | Cómo interpretarlo |
| :--- | :--- | :--- |
| `\Procesador(_Total)\% de tiempo de procesador` | Utilización global de CPU | Una carga alta y sostenida requiere investigar procesos, demanda y capacidad disponible. |
| `\Procesador(*)\% de tiempo de procesador` | Utilización por procesador lógico, además del agregado cuando existe | Permite detectar un procesador lógico saturado aunque el promedio sea moderado. |
| `\Proceso(*)\% de tiempo de procesador` | Tiempo de CPU de cada proceso | Relaciona el consumo con la aplicación responsable. |
| `\Procesador(_Total)\% de tiempo privilegiado` | Tiempo de CPU dedicado a ejecución en modo kernel | Interpretar junto con E/S, controladores e interrupciones. |
| `\Sistema\Longitud de la cola de la CPU` | Hilos preparados que esperan CPU | Considerar duración, procesadores lógicos y carga global. No existe un límite único válido para todos los equipos. |

El contador de CPU **por proceso puede superar el 100 %**, porque acumula actividad de varios procesadores lógicos. Por ejemplo, un 200 % equivale aproximadamente al uso completo de dos procesadores lógicos. En una VM con cuatro vCPU representaría aproximadamente el 50 % de su capacidad total. No se compara directamente con el porcentaje normalizado del Administrador de tareas.

Cuando existan varias instancias con el mismo nombre de proceso, hay que relacionarlas con su identificador mediante el contador de ID de proceso disponible en la instalación.

### 4.2. Memoria

**`\Memoria\MBytes disponibles`** indica cuánta memoria física puede ponerse inmediatamente a disposición del sistema o de los procesos. Incluye memoria libre y memoria reutilizable sin necesidad de escribirla antes en disco.

**`\Memoria\% de bytes confirmados en uso`** mide qué proporción del límite de memoria comprometida utiliza el sistema. La memoria comprometida exige respaldo que el sistema pueda proporcionar mediante RAM o archivos de paginación; el límite depende principalmente de ambos recursos.

```text
Porcentaje comprometido = bytes comprometidos / límite de compromiso × 100
```

**No es el porcentaje de RAM física ocupada.** Por ejemplo, con un límite de compromiso de 12 GiB y 6 GiB comprometidos, el contador será aproximadamente del 50 %. Esto no permite deducir cuánta RAM está ocupada en ese momento.

**`\Memoria\Páginas/s`** contabiliza páginas leídas del disco para resolver fallos de página duros y páginas escritas al disco para liberar memoria física. Un fallo de página duro requiere acceder al almacenamiento, pero puede implicar archivos mapeados o ejecutables, no solamente el archivo de paginación.

Una actividad elevada de paginación no demuestra por sí sola falta de RAM. Debe relacionarse con memoria disponible, carga de trabajo, latencia de disco y evolución temporal. Si se necesita profundizar, pueden consultarse por separado las páginas de entrada y salida por segundo.

### 4.3. Almacenamiento

| Contador de referencia | Interpretación |
| :--- | :--- |
| `\Disco físico(*)\Promedio de disco s/lectura` | Tiempo medio por lectura, expresado en segundos. |
| `\Disco físico(*)\Promedio de disco s/escritura` | Tiempo medio por escritura, expresado en segundos. |
| `\Disco físico(*)\Longitud media de la cola de disco` | Solicitudes de E/S en servicio o pendientes, como promedio del intervalo. |

Para expresar la latencia en milisegundos, multiplicamos por 1.000: **0,015 s = 15 ms**. Conviene añadir operaciones por segundo y bytes por segundo, descubriendo sus rutas en el conjunto correspondiente.

Una cola elevada con latencia baja puede reflejar una carga que el dispositivo atiende correctamente. Una cola elevada acompañada de latencia elevada y persistente puede señalar contención. La interpretación cambia según la carga y el tipo de almacenamiento, especialmente en SSD y NVMe.

El contador `% de tiempo de disco` puede consultarse como información complementaria, pero no debe tratarse como un porcentaje universal de saturación equivalente al de CPU. Para diagnosticar, priorizaremos latencia, operaciones, transferencia y su evolución.

Utiliza `_Total` para una primera visión y después examina cada disco. En una VM, el objeto **Disco físico describe los dispositivos que Windows ve**, que pueden ser discos virtuales. El almacenamiento real y la competencia entre VM también deben revisarse en Proxmox.

### 4.4. Red

Las métricas básicas son el tráfico enviado y recibido, los errores, los descartes y la capacidad del enlace. Busca sus nombres exactos en `Interfaz de red`; en inglés, las referencias son `Bytes Total/sec`, `Bytes Sent/sec`, `Bytes Received/sec` y `Packets Received Errors`.

- **Tráfico:** se mide en bytes por segundo. Para compararlo con bits por segundo, multiplica por ocho.
- **Envío y recepción:** en un enlace full-duplex pueden utilizarse simultáneamente ambas direcciones. Su suma no se interpreta como un porcentaje de ocupación de una sola dirección.
- **Errores de recepción:** el contador es acumulativo. Hay que observar su incremento entre mediciones; un valor histórico distinto de cero no prueba un fallo activo.
- **Adaptadores virtuales:** su velocidad anunciada no garantiza ese caudal hasta el destino. También influyen el bridge, el host, el enlace físico y el otro extremo.

Por ejemplo, 25.000.000 bytes/s equivalen a 200 Mbit/s. Antes de concluir que la red está saturada, comprueba la dirección del tráfico, la capacidad real del recorrido y los síntomas del servicio.

## 📈 5. Línea base de rendimiento

Una **línea base** recoge el comportamiento habitual del servidor cuando funciona correctamente bajo cargas conocidas. Permite reconocer desviaciones que un umbral fijo podría pasar por alto.

| Concepto | Función |
| :--- | :--- |
| Valor actual | Describe una medición concreta. |
| Umbral | Define cuándo una condición requiere atención. |
| Línea base | Describe el comportamiento esperado en un contexto comparable. |

Ejemplo ilustrativo de una VM, no valores objetivo para todos los servidores:

| Métrica | Comportamiento habitual | Observación posterior |
| :--- | :--- | :--- |
| CPU global | 10–25 % durante el trabajo normal | 65 % durante una hora con carga equivalente |
| Memoria disponible | 3–4 GiB | Menos de 1 GiB de forma sostenida |
| Latencia de lectura | 2–5 ms | 35 ms durante el mismo periodo |

La combinación merece investigación, pero no identifica por sí sola la causa. Una copia de seguridad o una importación de datos pueden explicar un comportamiento diferente.

Para construir la línea base:

1. Anota roles, versiones, recursos asignados y carga prevista.
2. Selecciona un conjunto pequeño de métricas relevantes.
3. Registra periodos representativos: actividad normal, picos esperados y mantenimiento.
4. Conserva las horas de las operaciones para interpretar las gráficas.
5. Resume rangos habituales y periodos de actividad elevada.
6. Actualiza la referencia después de cambios justificados en servicios o recursos.

!!! note "Duración e intervalo"
    En el aula puede hacerse una demostración de 10–15 minutos con muestras cada 5 segundos. Una línea base real debe abarcar los ciclos habituales del servicio, que pueden requerir varios días. Un intervalo más corto genera más datos y no siempre aporta información útil.

## 💾 6. Registrar y consultar mediciones históricas

### 6.1. Conjuntos de recopiladores de datos

Desde PerfMon, en un equipo con interfaz gráfica:

1. Abre **Conjuntos de recopiladores de datos → Definidos por el usuario**.
2. Crea un conjunto llamado `ASO-LineaBase` mediante creación manual.
3. Selecciona un recopilador de contadores de rendimiento.
4. Añade CPU global, memoria disponible y latencias por disco.
5. Establece el intervalo de muestreo y la carpeta de salida.
6. En las propiedades, configura una condición de parada y, cuando proceda, una programación.
7. Inicia la captura, realiza la actividad prevista y detén el conjunto.
8. En el Monitor de rendimiento, cambia la fuente a un archivo de registro y selecciona el `.blg` generado.

Para Server Core puede utilizarse `logman` localmente o recoger un archivo con PowerShell y analizarlo desde Windows 11.

### 6.2. Guardar un archivo BLG con PowerShell

Ejecuta este bloque en **Windows PowerShell 5.1**. Verifica primero las rutas en tu servidor.

```powershell
$Rutas = @(
    '\Procesador(_Total)\% de tiempo de procesador'
    '\Memoria\MBytes disponibles'
    '\Disco físico(*)\Promedio de disco s/lectura'
    '\Disco físico(*)\Promedio de disco s/escritura'
)
$Carpeta = 'C:\ASO\Registros'
New-Item -Path $Carpeta -ItemType Directory -Force | Out-Null
$Archivo = Join-Path $Carpeta ('LineaBase-{0}.blg' -f (Get-Date -Format 'yyyyMMdd-HHmmss'))

# Unos diez minutos de captura. La consola permanece ocupada hasta finalizar.
Get-Counter -Counter $Rutas -SampleInterval 5 -MaxSamples 120 -ErrorAction Stop |
    Export-Counter -Path $Archivo -FileFormat BLG -ErrorAction Stop

$Archivo
```

`Export-Counter` conserva los conjuntos de muestras en un formato que PerfMon puede abrir. No se debe aplicar `Format-Table` antes de exportar: transformaría los objetos en información de presentación.

Al analizar las gráficas, revisa las unidades y el factor de escala de cada contador. Una línea situada a la misma altura que otra no significa que ambas midan la misma magnitud. Consulta también los valores numéricos del periodo seleccionado.

## 🔗 7. Correlación y diagnóstico

| Síntoma | Evidencias que interesa combinar | Hipótesis que se debe comprobar |
| :--- | :--- | :--- |
| Respuesta lenta y CPU alta | CPU global, por procesador lógico, por proceso y cola | Proceso intensivo, carga superior a la capacidad o competencia por CPU. |
| Menor memoria disponible | Compromiso, paginación, procesos y latencia de disco | Presión de memoria, crecimiento de un proceso o actividad temporal. |
| Operaciones de disco lentas | Latencia, cola, operaciones/s, procesos y métricas del host | Contención del almacenamiento o una carga de E/S concreta. |
| Transferencias lentas | Tráfico por dirección, errores, descartes y recorrido de red | Capacidad insuficiente, problemas del enlace o del destino. |
| Servicio que no responde | Estado, consulta funcional y eventos del mismo periodo | Error de configuración, dependencia o fallo de aplicación. |

El procedimiento de trabajo será: **detectar el síntoma, delimitar el periodo, recoger evidencias, formular una hipótesis, contrastarla y verificar el resultado de la actuación**.

No es necesario esperar a que la cola de CPU sea alta para investigar los procesos. Un único hilo puede limitar una aplicación mientras el promedio global y la cola parecen normales.

## 🛠️ 8. Script de captura con PowerShell

Guarda el siguiente código como `C:\ASO\Scripts\AuditarServidor.ps1`. Devuelve objetos, admite varias muestras y distingue datos no válidos de mediciones correctas. Las rutas deben ajustarse a la instalación antes de programar su ejecución.

```powershell
<#
.SYNOPSIS
    Recoge CPU, memoria y latencias globales del servidor local.
.DESCRIPTION
    Diseñado para Windows PowerShell 5.1 y contadores en español.
    Devuelve objetos; no diagnostica automáticamente la causa de una incidencia.
#>
[CmdletBinding()]
param(
    [ValidateRange(1, 3600)]
    [int]$Intervalo = 5,
    [ValidateRange(1, 10000)]
    [int]$Muestras = 12
)

$Definiciones = @(
    @{ Ruta = '\Procesador(_Total)\% de tiempo de procesador'; Nombre = 'CPU'; Unidad = '%'; Factor = 1 }
    @{ Ruta = '\Memoria\MBytes disponibles'; Nombre = 'MemoriaDisponible'; Unidad = 'MiB'; Factor = 1 }
    @{ Ruta = '\Disco físico(_Total)\Promedio de disco s/lectura'; Nombre = 'LatenciaLectura'; Unidad = 'ms'; Factor = 1000 }
    @{ Ruta = '\Disco físico(_Total)\Promedio de disco s/escritura'; Nombre = 'LatenciaEscritura'; Unidad = 'ms'; Factor = 1000 }
    @{ Ruta = '\Disco físico(_Total)\Longitud media de la cola de disco'; Nombre = 'ColaDisco'; Unidad = 'solicitudes'; Factor = 1 }
)

try {
    $Rutas = @($Definiciones | ForEach-Object { $_.Ruta })
    Get-Counter -Counter $Rutas -SampleInterval $Intervalo -MaxSamples $Muestras -ErrorAction Stop |
        ForEach-Object {
            $Conjunto = $_
            foreach ($Definicion in $Definiciones) {
                # Get-Counter añade el nombre del equipo a la ruta devuelta.
                $Coincidencias = @($Conjunto.CounterSamples | Where-Object {
                    $_.Path.EndsWith($Definicion.Ruta, [StringComparison]::OrdinalIgnoreCase)
                })
                if ($Coincidencias.Count -ne 1) {
                    throw "No se encuentra una muestra única para $($Definicion.Ruta)"
                }
                $Dato = $Coincidencias[0]
                $Valida = ($Dato.Status -in @(0, 1)) -and
                    (-not [double]::IsNaN($Dato.CookedValue)) -and
                    (-not [double]::IsInfinity($Dato.CookedValue))
                $Valor = $null
                if ($Valida) {
                    $Valor = [Math]::Round(($Dato.CookedValue * $Definicion.Factor), 3)
                }
                [PSCustomObject]@{
                    Fecha     = $Conjunto.Timestamp.ToString('o')
                    Servidor  = $env:COMPUTERNAME
                    Metrica   = $Definicion.Nombre
                    Instancia = $Dato.InstanceName
                    Valor     = $Valor
                    Unidad    = $Definicion.Unidad
                    Valida    = $Valida
                    Estado    = $Dato.Status
                    Ruta      = $Dato.Path
                }
            }
        }
}
catch {
    throw "Captura interrumpida: $($_.Exception.Message). Comprueba rutas y permisos."
}
```

Ejemplos de utilización:

```powershell
# Consulta breve por pantalla.
C:\ASO\Scripts\AuditarServidor.ps1 -Muestras 3 | Format-Table -AutoSize

# Guardar unos cinco minutos de datos en CSV, con un nombre distinto por captura.
$Archivo = 'C:\ASO\Registros\Metricas-{0}.csv' -f (Get-Date -Format 'yyyyMMdd-HHmmss')
C:\ASO\Scripts\AuditarServidor.ps1 -Intervalo 5 -Muestras 60 |
    Export-Csv -Path $Archivo -NoTypeInformation -Encoding UTF8
```

El CSV contiene una fila por métrica y momento. Si una muestra no es válida, su valor queda vacío y se conserva el estado; **no se convierte un error en cero**. Un fallo posterior puede dejar un archivo parcial: revisa el error y el periodo realmente registrado antes de utilizarlo.

## 🔎 9. Estado y configuración mediante CIM

`Get-Counter` resulta cómodo para recoger series temporales. `Get-CimInstance` permite consultar clases que describen recursos, configuración y estado. La separación no es absoluta: también existen clases CIM de rendimiento.

### 9.1. Capacidad y espacio libre

```powershell
Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType=3' |
    Select-Object DeviceID,
        @{Name='Tamano_GiB'; Expression={[Math]::Round($_.Size / 1GB, 2)}},
        @{Name='Libre_GiB'; Expression={[Math]::Round($_.FreeSpace / 1GB, 2)}},
        @{Name='Libre_Porcentaje'; Expression={
            if ($_.Size -gt 0) {
                [Math]::Round(100 * $_.FreeSpace / $_.Size, 2)
            } else { $null }
        }}
```

`DriveType=3` selecciona discos locales fijos visibles para Windows. En PowerShell, `1GB` equivale a 1.073.741.824 bytes; por eso las columnas se rotulan en **GiB**. Para estudiar volúmenes montados sin letra conviene ampliar la consulta con herramientas de volúmenes, como `Get-Volume`.

En Proxmox también hay que supervisar la capacidad del almacenamiento del host. El espacio libre dentro de una VM no describe cuánto queda en el almacenamiento que contiene sus discos virtuales.

### 9.2. Procesos y memoria residente

```powershell
Get-CimInstance -ClassName Win32_Process |
    Sort-Object WorkingSetSize -Descending |
    Select-Object -First 5 ProcessId, Name, ExecutablePath,
        @{Name='WorkingSet_MiB'; Expression={[Math]::Round($_.WorkingSetSize / 1MB, 2)}}
```

`WorkingSetSize` representa memoria residente del proceso e incluye páginas que pueden compartirse. No debe sumarse sin más para calcular la RAM total ocupada. Algunas rutas de ejecutables pueden no estar disponibles con los permisos utilizados.

Un proceso grande o inactivo no debe finalizarse automáticamente. Primero se identifica su función, el servicio al que pertenece y si su comportamiento difiere de lo esperado.

### 9.3. Servicios esperados y ausentes

Este ejemplo corresponde a **un controlador de dominio que también presta DNS**. En otro servidor hay que adaptar la lista a sus roles.

```powershell
$Esperados = 'DNS', 'NTDS', 'DFSR', 'Kdc'
$Servicios = @(Get-CimInstance -ClassName Win32_Service -ErrorAction Stop)
foreach ($Nombre in $Esperados) {
    $Servicio = $Servicios | Where-Object Name -EQ $Nombre
    if ($null -eq $Servicio) {
        [PSCustomObject]@{
            Nombre = $Nombre; Presente = $false
            Estado = 'Ausente'; Inicio = $null
        }
    } else {
        [PSCustomObject]@{
            Nombre = $Servicio.Name; Presente = $true
            Estado = $Servicio.State; Inicio = $Servicio.StartMode
        }
    }
}
```

Compara el estado y el modo de inicio con la configuración esperada para cada rol. No cambies todos los servicios a automático de forma indiscriminada.

### 9.4. Prueba funcional

Un estado `Running` es una primera evidencia, pero no certifica que el servicio responda correctamente. Desde un cliente, comprueba una operación real:

```powershell
# Adapta dominio, nombre del servidor y registro a tu laboratorio.
Resolve-DnsName -Name 'DC01.int.asix.info' -Type A `
    -Server 'DC01.int.asix.info' -DnsOnly -ErrorAction Stop
```

Verifica que la dirección devuelta sea la prevista. Para separar problemas de resolución del propio nombre del servidor DNS, puede indicarse su IP en `-Server`. Esta prueba valida una consulta concreta; no verifica por sí sola la salud completa de Active Directory ni su replicación.

## 📜 10. Eventos y registro de incidencias

Los contadores muestran tendencias; los eventos aportan contexto sobre lo ocurrido. Comienza por **Sistema** y **Aplicación**, y consulta después los registros específicos del rol. El registro de Seguridad depende de la política de auditoría configurada.

```powershell
$Filtro = @{
    LogName   = 'System'
    StartTime = (Get-Date).AddHours(-2)
    Level     = 1, 2, 3  # Crítico, error y advertencia
}
Get-WinEvent -FilterHashtable $Filtro -MaxEvents 50 |
    Select-Object TimeCreated, ProviderName, Id, LevelDisplayName, Message
```

La ausencia de coincidencias puede producir un mensaje indicando que no se encontraron eventos. Distínguelo de un error de permisos o de consulta.

Para investigar:

1. Delimita la hora del síntoma y comprueba la sincronización horaria.
2. Identifica **registro, proveedor e ID**; el número de evento aislado no basta.
3. Lee el mensaje completo y los eventos inmediatamente anteriores.
4. Relaciona la información con métricas y cambios realizados.
5. Documenta qué evidencia apoya o descarta la hipótesis.

No todas las advertencias requieren una intervención. Tampoco deben borrarse registros como procedimiento rutinario de solución: se perdería información útil.

## 🚨 11. Alertas: condición, duración y respuesta

Una alerta necesita una condición medible, un periodo de observación, una forma de registro y una actuación prevista. Los umbrales siguientes son ejemplos de aula que deben ajustarse a la línea base:

| Condición orientativa | Persistencia | Primera respuesta |
| :--- | :--- | :--- |
| CPU global superior al 85 % | 6 muestras consecutivas cada 10 s | Examinar procesos y carga del host. |
| Espacio libre inferior al 15 % | Confirmar la medición y estudiar su evolución | Estimar crecimiento e identificar su origen. |
| Servicio esperado ausente o detenido | Comprobación inmediata | Revisar rol, eventos y cambios recientes. |

Una alerta de CPU sostenida puede demostrarse con el siguiente bloque. Registra una sola alerta al alcanzar seis muestras consecutivas; una muestra válida por debajo del umbral permite volver a alertar si el problema reaparece.

```powershell
$RutaCPU = '\Procesador(_Total)\% de tiempo de procesador'
$Umbral = 85
$Consecutivas = 0
$Avisado = $false
$Registro = 'C:\ASO\Registros\AlertasCPU.csv'
New-Item -Path (Split-Path $Registro) -ItemType Directory -Force | Out-Null

Get-Counter -Counter $RutaCPU -SampleInterval 10 -MaxSamples 30 -ErrorAction Stop |
    ForEach-Object {
        $Dato = $_.CounterSamples[0]
        if (($Dato.Status -notin @(0, 1)) -or
            [double]::IsNaN($Dato.CookedValue) -or
            [double]::IsInfinity($Dato.CookedValue)) {
            $Consecutivas = 0
            Write-Warning 'Muestra no válida: no se utiliza para evaluar la persistencia.'
        } elseif ($Dato.CookedValue -gt $Umbral) {
            $Consecutivas++
            if (($Consecutivas -ge 6) -and (-not $Avisado)) {
                [PSCustomObject]@{
                    Fecha = $_.Timestamp.ToString('o')
                    Servidor = $env:COMPUTERNAME
                    Alerta = 'CPU alta durante seis muestras consecutivas'
                    CPU = [Math]::Round($Dato.CookedValue, 2)
                    Umbral = $Umbral
                } | Export-Csv -Path $Registro -Append -NoTypeInformation -Encoding UTF8
                Write-Warning 'CPU alta sostenida: revisar procesos y carga del host.'
                $Avisado = $true
            }
        } else {
            $Consecutivas = 0
            $Avisado = $false
        }
    }
```

La persistencia se define aquí por muestras, aproximadamente un minuto de observación. El registro CSV no envía una notificación a un administrador: en un despliegue centralizado debe añadirse el mecanismo de aviso correspondiente. Un fallo de recogida también requiere atención; no implica que el servidor esté sano.

## ⚙️ 12. Mantenimiento planificado y verificable

### 12.1. Plan de mantenimiento

Las frecuencias son orientativas y deben adaptarse a los servicios y al calendario del centro.

| Tarea | Frecuencia orientativa | Evidencia de finalización |
| :--- | :--- | :--- |
| Revisar servicios, alertas y tareas automáticas | Cada jornada de administración | Registro de comprobación e incidencias. |
| Revisar espacio libre y crecimiento | Semanal | Capacidad, tendencia y decisión adoptada. |
| Comprobar copias de seguridad | Tras cada copia | Resultado, destino y fecha de la última copia válida. |
| Probar restauraciones | Periódicamente y tras cambios relevantes | Archivo o servicio restaurado y prueba funcional. |
| Aplicar actualizaciones | Según criticidad y ventana acordada | Actualizaciones aplicadas y comprobaciones posteriores. |
| Revisar cuentas, permisos y configuración | Periódicamente | Cambios justificados y documentados. |
| Revisar recursos y línea base | Tras cambios relevantes | Comparación y referencia actualizada. |

### 12.2. Actualizaciones

1. Identifica las actualizaciones y su posible impacto en los roles instalados.
2. Comprueba las copias y el procedimiento de recuperación.
3. Planifica una ventana y comunica la interrupción prevista.
4. Aplica las actualizaciones mediante la herramienta establecida; en Core puede utilizarse SConfig cuando corresponda.
5. Reinicia si es necesario y comprueba eventos, servicios y operaciones reales.
6. Registra el resultado y las incidencias.

No basta con comprobar que el servidor vuelve a encenderse. El cierre de la tarea exige verificar los servicios que utiliza la organización.

### 12.3. Copias y restauraciones

Una copia se considera útil cuando permite recuperar lo necesario. Deben verificarse destino, fecha, resultado y restauración. La replicación puede propagar errores o borrados, y una instantánea de VM no sustituye una política de copias independiente.

En el aula, restaura un archivo de prueba en otra ubicación y compara su contenido. Las pruebas de recuperación de controladores de dominio requieren un procedimiento específico y un entorno aislado; no deben improvisarse sobre el dominio activo.

### 12.4. Capacidad y limpieza

Antes de liberar espacio, identifica qué crece y qué política de conservación se aplica. Trabaja únicamente sobre rutas conocidas y revisa primero la selección.

```powershell
# Solo informes CSV de métricas del laboratorio con más de 30 días.
$Limite = (Get-Date).AddDays(-30)
$Antiguos = Get-ChildItem -LiteralPath 'C:\ASO\Registros' -Filter 'Metricas-*.csv' -File |
    Where-Object LastWriteTime -LT $Limite
$Antiguos | Select-Object FullName, Length, LastWriteTime
$Antiguos | Remove-Item -WhatIf
```

`-WhatIf` simula la eliminación. Solo se retirará después de revisar la lista y confirmar que se cumple la política de conservación. No se deben borrar indiscriminadamente carpetas del sistema, bases de datos o registros de eventos.

### 12.5. Programar una comprobación de capacidad

Guarda como `C:\ASO\Scripts\ComprobarCapacidad.ps1` el siguiente script. Cada ejecución produce un informe diferente y devuelve un código que permite distinguir ejecución correcta de fallo técnico.

```powershell
$ErrorActionPreference = 'Stop'
try {
    $Carpeta = 'C:\ASO\Registros'
    New-Item -Path $Carpeta -ItemType Directory -Force | Out-Null
    $Fecha = Get-Date
    $Informe = foreach ($Disco in Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3') {
        if ($Disco.Size -gt 0) {
            $Libre = 100 * $Disco.FreeSpace / $Disco.Size
            [PSCustomObject]@{
                Fecha = $Fecha.ToString('o')
                Servidor = $env:COMPUTERNAME
                Unidad = $Disco.DeviceID
                Libre_GiB = [Math]::Round($Disco.FreeSpace / 1GB, 2)
                Libre_Porcentaje = [Math]::Round($Libre, 2)
                RequiereRevision = ($Libre -lt 15)
            }
        }
    }
    if (@($Informe).Count -eq 0) { throw 'No se han obtenido unidades con capacidad válida.' }
    $Archivo = Join-Path $Carpeta ('Capacidad-{0}.csv' -f $Fecha.ToString('yyyyMMdd-HHmmss-fff'))
    $Informe | Export-Csv -Path $Archivo -NoTypeInformation -Encoding UTF8
    exit 0
}
catch {
    Write-Error "No se pudo completar la comprobación: $($_.Exception.Message)" -ErrorAction Continue
    exit 1
}
```

Configura una tarea desde el Programador de tareas o utiliza, en una consola elevada del servidor, este ejemplo de laboratorio:

```powershell
$Ejecutable = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$Accion = New-ScheduledTaskAction -Execute $Ejecutable `
    -Argument '-NoProfile -NonInteractive -File "C:\ASO\Scripts\ComprobarCapacidad.ps1"'
$Disparador = New-ScheduledTaskTrigger -Daily -At '18:00'
$Principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount
$Ajustes = New-ScheduledTaskSettingsSet -StartWhenAvailable `
    -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 5)
Register-ScheduledTask -TaskName 'ASO-ComprobarCapacidad' -Action $Accion `
    -Trigger $Disparador -Principal $Principal -Settings $Ajustes `
    -Description 'Genera un informe diario del espacio libre del servidor.'
```

El ejemplo utiliza **SYSTEM** para una tarea local de laboratorio. Esta cuenta tiene amplios privilegios: la carpeta de scripts solo debe poder ser modificada por administradores y SYSTEM. En un despliegue real se elegirá una identidad con los permisos mínimos necesarios. Comprueba la política de ejecución y los permisos antes de registrar la tarea; no es necesario desactivar globalmente la política para este ejercicio.

Prueba y verifica:

```powershell
Start-ScheduledTask -TaskName 'ASO-ComprobarCapacidad'

# Consultar cuando la tarea haya finalizado.
Get-ScheduledTask -TaskName 'ASO-ComprobarCapacidad' | Select-Object TaskName, State
Get-ScheduledTaskInfo -TaskName 'ASO-ComprobarCapacidad' |
    Select-Object LastRunTime, LastTaskResult, NextRunTime
Get-ChildItem 'C:\ASO\Registros\Capacidad-*.csv' |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
```

Un `LastTaskResult` igual a `0` indica que el script terminó correctamente según sus códigos. **No significa que haya suficiente espacio**: el informe puede contener `RequiereRevision=True`. Comprueba fecha, contenido y estado de finalización; si falla, revisa el historial y el registro operativo del Programador de tareas.

## 🧩 13. Integración con la base de datos del proyecto

Una vez comprobada la captura local, los equipos pueden centralizarla en SQL Server. Cada registro debe conservar como mínimo **fecha con zona horaria o UTC, servidor, métrica, instancia, valor, unidad y validez**.

Primero valida el funcionamiento con CSV o BLG. Después incorpora la inserción mediante el mecanismo de acceso a SQL Server elegido. `Invoke-Sqlcmd` requiere el módulo `SqlServer`; no está disponible por el mero hecho de tener PowerShell instalado.

Separa la recogida de datos del almacenamiento: si la base de datos no está disponible, conserva temporalmente los registros para reenviarlos. La cuenta de monitorización necesita permisos limitados, y las credenciales no deben escribirse en claro dentro del script. Los valores externos se introducirán mediante consultas parametrizadas o un procedimiento de carga controlado.

## 🔍 14. Laboratorio de diagnóstico en Proxmox

### 14.1. Escenario

Cada equipo de cuatro alumnos dispone de su propio host Proxmox, con varias VM del proyecto. Durante una operación simultánea en las VM de **un mismo equipo**, Windows Server responde lentamente y aparecen periodos de CPU elevada.

La sobreasignación es una hipótesis, pero asignar más vCPU en total que procesadores lógicos tiene el host no demuestra por sí solo un problema: influye cuánto demandan simultáneamente esas VM.

### 14.2. Investigación

**Dentro de Windows:** registra CPU global y por procesador lógico, procesos, cola, memoria y latencias durante el problema. Anota cuántas vCPU tiene asignadas la VM y qué operación se realiza.

**En el host Proxmox:** revisa las gráficas del nodo y de las VM en el mismo periodo. Desde su terminal:

```bash
# Inventario de máquinas virtuales y contenedores.
qm list
pct list

# Configuración de una VM. Sustituye 101 por su identificador real.
qm config 101

# Procesos y carga del host.
top
uptime
```

La carga media que muestra `uptime` no es un porcentaje de CPU: en Linux incluye tareas ejecutables y tareas en espera ininterrumpible, frecuentemente asociadas a E/S. Debe interpretarse junto con CPU, almacenamiento y otros datos del host.

| Evidencia | Línea de investigación |
| :--- | :--- |
| VM ocupada y host con capacidad disponible | Aplicación, paralelismo, límites y recursos de esa VM. |
| Varias VM con demanda simultánea y host ocupado | Competencia entre cargas y planificación de trabajos. |
| Latencias de disco altas durante copias o importaciones | Contención del almacenamiento compartido. |
| Lentitud con recursos aparentemente normales | Servicio, red, dependencias y eventos. |

### 14.3. Actuación y validación

Elige una sola modificación respaldada por los datos: escalonar trabajos, corregir una operación, ajustar límites o redistribuir recursos. Reducir vCPU no es una solución automática y puede empeorar una VM que necesita esa capacidad.

Si el cambio requiere apagar una VM, programa la interrupción. Repite después la misma operación con condiciones comparables y comprueba tanto el servidor afectado como las otras VM del host. Documenta también cómo volver a la configuración anterior.

## 🧪 15. Práctica integrada y evidencias

**Objetivo:** justificar con mediciones si un servidor funciona según lo esperado y comprobar que una tarea de mantenimiento se ejecuta correctamente.

1. **Inventario:** describe rol, recursos y servicios del servidor.
2. **Descubrimiento:** obtiene las rutas reales de CPU, memoria, disco y red.
3. **Captura inicial:** registra un periodo breve de actividad conocida y conserva el BLG o CSV.
4. **Carga controlada:** realiza una operación acordada, como una copia de archivos de prueba, anotando inicio y fin. No utilices datos de producción ni llenes el volumen del sistema.
5. **Interpretación:** compara ambos periodos y relaciona al menos dos métricas.
6. **Disponibilidad:** comprueba un servicio y realiza una operación funcional desde el cliente.
7. **Eventos:** consulta el periodo y distingue coincidencias temporales de posibles causas.
8. **Automatización:** programa la comprobación de capacidad, ejecútala y verifica su informe y resultado.
9. **Alerta:** prueba la lógica en una VM de laboratorio con un umbral temporal ajustado al ejercicio; documenta el cambio y restablece el valor previsto.
10. **Conclusión:** propone una actuación o justifica por qué no es necesario modificar nada.

| Evidencia que se entrega | Qué debe demostrar |
| :--- | :--- |
| Script utilizado y parámetros | Adaptación al entorno y comprensión de sus instrucciones. |
| Registro BLG o CSV | Datos identificados por servidor, instante, instancia y unidad. |
| Gráfica comentada | Selección del periodo y explicación de la tendencia. |
| Informe breve de diagnóstico | Síntoma, hipótesis, evidencias, decisión y comprobación posterior. |
| Informe de la tarea programada | Ejecución real, resultado e interpretación del contenido. |

El informe no necesita reproducir cada clic. Debe permitir verificar las decisiones y repetir la comprobación. Cada alumno deberá explicar una métrica y adaptar una consulta o una condición del script durante una breve comprobación individual.

## 📚 Referencias y autoría

### Documentación principal

- **Microsoft Learn.** [Get-Counter: consulta y descubrimiento de contadores](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.diagnostics/get-counter?view=powershell-5.1).
- **Microsoft Learn.** [Diagnóstico de problemas de rendimiento en Windows](https://learn.microsoft.com/en-us/troubleshoot/windows-server/performance/troubleshoot-performance-problems-in-windows).
- **Microsoft Learn.** [Memoria comprometida y archivo de paginación](https://learn.microsoft.com/en-us/troubleshoot/windows-client/performance/introduction-to-the-page-file).
- **Microsoft Learn.** [Export-Counter: registros de rendimiento](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.diagnostics/export-counter?view=powershell-5.1) y [principales de tareas programadas](https://learn.microsoft.com/en-us/powershell/module/scheduledtasks/new-scheduledtaskprincipal?view=windowsserver2025-ps).
- **BOE.** [Real Decreto 1629/2009: título de ASIR y enseñanzas mínimas](https://boe.es/buscar/doc.php?id=BOE-A-2009-18355), módulo 0374. Referencia para la correspondencia curricular indicada.

!!! info "Autoría y elaboración"
    Material docente de **José Ramón Soria Nieto**, Departamento de Informática del **IES Marcos Zaragoza**, para el módulo Administración de Sistemas Operativos de ASIR/ASIX. Basado en los materiales de la unidad de supervisión y mantenimiento de Windows Server.

    Esta revisión se ha elaborado con apoyo de inteligencia artificial y contraste con documentación oficial. Los ejemplos requieren adaptación y comprobación en el entorno del aula antes de su utilización; no se presenta ese contraste documental como una prueba de ejecución en Windows Server.
