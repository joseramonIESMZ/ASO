# Supervisión de recursos en Windows Server

En este tema aprenderemos a obtener, interpretar y conservar mediciones de **CPU, memoria y almacenamiento** en Windows Server mediante contadores de rendimiento y consultas CIM.

Primero comprobaremos cómo se obtienen las mediciones y cómo se conservan en archivos para consultarlas posteriormente. También introduciremos su recogida periódica mediante tareas programadas.

El estudio detallado de eventos y registro de incidencias, alertas, mantenimiento y diagnóstico en Proxmox se abordará en secciones independientes. Aquí nos centraremos en la obtención e interpretación de datos del sistema.

## 🎯 Relación con el currículo (RA y CE)

Los contenidos se relacionan con los siguientes resultados de aprendizaje del módulo **Administración de Sistemas Operativos (ASO, código 0374)**. La tabla resume su aplicación didáctica; no reproduce literalmente los criterios de evaluación.

| Resultado de aprendizaje | CE relacionados | Aplicación en este tema |
| :--- | :--- | :--- |
| **RA2. Administración de procesos del sistema** | **2.f** | Utilización de herramientas gráficas y comandos para el control y seguimiento de procesos. |
| **RA3. Automatización de tareas del sistema** | **3.a, 3.b, 3.c, 3.d y 3.h**; **3.g** si se utiliza la consola gráfica | Justificación de la automatización, planificación de comprobaciones, restricciones de seguridad y documentación de las tareas. |
| **RA7. Utilización de lenguajes de guiones** | **7.a, 7.b, 7.d, 7.f y 7.i** | Creación, adaptación, depuración, prueba y documentación de scripts de supervisión. |
| **RA4. Administración remota** | **4.c y 4.e**, cuando la práctica se realiza a distancia | Uso de herramientas y comandos para administrar el servidor desde el equipo cliente. |

La monitorización general también conecta con el **RA6 de Implantación de Sistemas Operativos**. Esta conexión no convierte dicho RA en un resultado propio de ASO. La lectura de los apuntes, por sí sola, no acredita la consecución de los criterios: es necesario observar su aplicación práctica.

## 🏢 1. Fundamentos de la supervisión

### 1.1. Qué supervisamos

La **supervisión** consiste en obtener e interpretar información sobre el funcionamiento del sistema. Incluye tres perspectivas complementarias:

| Perspectiva | Pregunta | Ejemplo |
| :--- | :--- | :--- |
| **Rendimiento** | ¿Cómo utiliza sus recursos? | CPU, memoria disponible, latencia de disco y tráfico de red. |
| **Estado y disponibilidad** | ¿Están disponibles los componentes y funcionan los servicios? | Estado del servicio DNS y respuesta a una consulta real. |
| **Eventos** | ¿Qué ha sucedido y cuándo? | Error de un servicio, fallo de una tarea o incidencia de almacenamiento. |

Una CPU poco utilizada no garantiza que DNS responda correctamente. Del mismo modo, un servicio en ejecución puede presentar errores funcionales. Por eso combinamos métricas, estados, eventos y pruebas del servicio.

### 1.2. Recursos y magnitudes

- **CPU:** porcentaje global de utilización del procesador.
- **Memoria:** memoria física disponible y porcentaje estimado de ocupación de RAM.
- **Disco:** capacidad y porcentaje de ocupación de las unidades lógicas locales fijas.

La latencia de disco, la actividad por proceso y el tráfico de red aportan información complementaria. Cada magnitud describe un aspecto diferente del funcionamiento del sistema.

!!! tip "Mediciones con significado"
    Cada valor debe indicar qué representa, su unidad, el equipo y el momento de captura. Un porcentaje aislado o una captura fallida sustituida por cero pueden llevar a conclusiones incorrectas.

## 🛠️ 2. Herramientas y entorno de trabajo

| Herramienta | Comando o acceso | Utilidad |
| :--- | :--- | :--- |
| Monitor de rendimiento | `perfmon.exe` | Visualizar contadores y analizar registros históricos. |
| Monitor de recursos | `resmon.exe` | Relacionar procesos con actividad de CPU, memoria, disco y red. |
| Administrador de tareas | `taskmgr.exe` | Primera revisión de procesos y recursos en entornos con interfaz gráfica. |
| Windows PowerShell 5.1 | `powershell.exe` | Ejecutar los ejemplos de administración de este tema. |
| PowerShell 7 | `pwsh.exe` | Entorno adicional que se instala por separado; debe comprobarse la compatibilidad de los módulos utilizados. |
| Recopiladores por comandos | `logman.exe` | Crear, iniciar y detener conjuntos de recopiladores de datos. |
| Programador de tareas | `taskschd.msc` o módulo `ScheduledTasks` | Ejecutar los scripts de recogida de forma periódica. |
| Windows Admin Center | Navegador y puerta de enlace previamente desplegada | Administración y supervisión remotas. |

**Entorno de referencia:** Windows Server del laboratorio, preferentemente Server Core, y clientes Windows 11. Los ejemplos utilizan Windows PowerShell 5.1 y contadores de una instalación en español, salvo indicación expresa.

!!! info "Aclaración: Server Core no equivale a .NET Core / PowerShell 7"
    El término **Server Core** hace referencia a la modalidad de instalación mínima sin interfaz gráfica de escritorio (GUI), no al runtime *.NET Core*. Incluso en Windows Server 2025, el sistema incluye de forma nativa **Windows PowerShell 5.1** (basado en .NET Framework), que es el entorno que procesa los comandos por defecto cuando nos conectamos mediante PowerShell Remoting (WinRM). PowerShell 7 (`pwsh.exe`) es opcional y requiere instalación explícita.

En **Server Core**, utilizaremos principalmente PowerShell y comandos. Las consolas gráficas se emplearán desde un equipo de administración o un servidor con experiencia de escritorio; no se presupone que todas estén disponibles localmente en Core.

Antes de comenzar:

1. Identifica el servidor, sus roles, vCPU, RAM y discos asignados.
2. Comprueba la versión de PowerShell con `$PSVersionTable.PSVersion`.
3. Revisa los permisos de consulta. Algunos contadores requieren privilegios adicionales.
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

Los contadores permiten observar CPU, memoria, actividad del almacenamiento y red. La capacidad y el espacio libre de las unidades se consultan mediante CIM en el apartado 7.3.

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

| Contador de referencia | Qué aporta | Cómo interpretarlo |
| :--- | :--- | :--- |
| `\Memoria\MBytes disponibles` | Memoria física disponible, expresada en MiB | Incluye memoria libre y memoria reutilizable sin necesidad de escribirla antes en disco. Una reducción sostenida debe relacionarse con la carga y los procesos del sistema. |
| `\Memoria\% de bytes confirmados en uso` | Porcentaje utilizado del límite de memoria comprometida | Indica la proporción entre bytes comprometidos y límite de compromiso. **No representa el porcentaje de RAM física ocupada.** |
| `\Memoria\Páginas/s` | Páginas leídas del disco para resolver fallos de página duros y páginas escritas para liberar memoria física, por segundo | Una actividad elevada no demuestra por sí sola falta de RAM. Debe relacionarse con memoria disponible, carga de trabajo, latencia de disco y evolución temporal. |

La memoria comprometida exige respaldo que el sistema pueda proporcionar mediante RAM o archivos de paginación; el límite depende principalmente de ambos recursos.

```text
Porcentaje comprometido = bytes comprometidos / límite de compromiso × 100
```

Por ejemplo, con un límite de compromiso de 12 GiB y 6 GiB comprometidos, el contador será aproximadamente del 50 %. Esto no permite deducir cuánta RAM está ocupada en ese momento.

Para estimar el porcentaje de ocupación de memoria física utilizaremos:

```text
RAM ocupada (%) = 100 × (RAM total − RAM disponible) / RAM total
```

La memoria total puede consultarse con `Win32_OperatingSystem.TotalVisibleMemorySize`, expresada en KiB, y la disponible con el contador `MBytes disponibles`, expresado en MiB. Antes de calcular, hay que convertirlas a la misma unidad. Se conservarán ambos valores para poder comprobar el porcentaje; no se sumarán los consumos de los procesos para obtenerlo.

Para consultar realmente la memoria total, obtenemos primero el objeto que representa el sistema operativo y después accedemos a su propiedad `TotalVisibleMemorySize`:

```powershell
$Sistema = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop

# Memoria física total visible para Windows, expresada en KiB.
$TotalKiB = $Sistema.TotalVisibleMemorySize
$TotalKiB

# Conversión a MiB para compararla con el contador MBytes disponibles.
$TotalMiB = $TotalKiB / 1024
$TotalMiB
```

`Win32_OperatingSystem` es el nombre de la clase consultada; `$Sistema` contiene el objeto devuelto. La expresión `$Sistema.TotalVisibleMemorySize` lee una propiedad de ese objeto, no ejecuta otro comando. El valor representa la memoria física que Windows tiene disponible para gestionar, que puede ser inferior a la RAM instalada o asignada a la máquina virtual.

También podemos mostrar ambas unidades en una sola consulta:

```powershell
Get-CimInstance -ClassName Win32_OperatingSystem |
    Select-Object CSName, TotalVisibleMemorySize,
        @{Name='MemoriaTotal_MiB'; Expression={
            [Math]::Round($_.TotalVisibleMemorySize / 1024, 2)
        }}
```

La columna `TotalVisibleMemorySize` conserva el valor original en KiB; `MemoriaTotal_MiB` es una propiedad calculada. Por ejemplo, `6291456` KiB equivalen a `6144` MiB, es decir, `6` GiB. La consulta obtiene los datos del equipo donde se ejecuta PowerShell; para consultar otro servidor, ejecuta el bloque en él mediante la sesión remota correspondiente.

Un fallo de página duro requiere acceder al almacenamiento, pero puede implicar archivos mapeados o ejecutables, no solamente el archivo de paginación. Si se necesita profundizar en la paginación, pueden consultarse por separado las páginas de entrada y salida por segundo.

### 4.3. Almacenamiento como ampliación

| Contador de referencia | Interpretación |
| :--- | :--- |
| `\Disco físico(*)\Promedio de segundos de disco\lectura` | Tiempo medio por lectura, expresado en segundos. |
| `\Disco físico(*)\Promedio de segundos de disco\escritura` | Tiempo medio por escritura, expresado en segundos. |
| `\Disco físico(*)\Longitud media de la cola de disco` | Solicitudes de E/S en servicio o pendientes, como promedio del intervalo. |

Para expresar la latencia en milisegundos, multiplicamos por 1.000: **0,015 s = 15 ms**. Conviene añadir operaciones por segundo y bytes por segundo, descubriendo sus rutas en el conjunto correspondiente.

Una cola elevada con latencia baja puede reflejar una carga que el dispositivo atiende correctamente. Una cola elevada acompañada de latencia elevada y persistente puede señalar contención. La interpretación cambia según la carga y el tipo de almacenamiento, especialmente en SSD y NVMe.

El contador `% de tiempo de disco` puede consultarse como información complementaria, pero no debe tratarse como un porcentaje universal de saturación equivalente al de CPU. Para diagnosticar, priorizaremos latencia, operaciones, transferencia y su evolución.

Utiliza `_Total` para una primera visión y después examina cada disco. En una VM, el objeto **Disco físico describe los dispositivos que Windows ve**, que pueden ser discos virtuales. El almacenamiento real y la competencia entre VM también deben revisarse en Proxmox.

---

### 4.4. Red como ampliación

Las métricas básicas son el tráfico enviado y recibido, los errores, los descartes y la capacidad del enlace. Busca sus nombres exactos en `Interfaz de red`; en inglés, las referencias son `Bytes Total/sec`, `Bytes Sent/sec`, `Bytes Received/sec` y `Packets Received Errors`.

- **Tráfico:** se mide en bytes por segundo. Para compararlo con bits por segundo, multiplica por ocho.
- **Envío y recepción:** en un enlace full-duplex pueden utilizarse simultáneamente ambas direcciones. Su suma no se interpreta como un porcentaje de ocupación de una sola dirección.
- **Errores de recepción:** el contador es acumulativo. Hay que observar su incremento entre mediciones; un valor histórico distinto de cero no prueba un fallo activo.
- **Adaptadores virtuales:** su velocidad anunciada no garantiza ese caudal hasta el destino. También influyen el bridge, el host, el enlace físico y el otro extremo.

Por ejemplo, 25.000.000 bytes/s equivalen a 200 Mbit/s. Antes de concluir que la red está saturada, comprueba la dirección del tráfico, la capacidad real del recorrido y los síntomas del servicio.

### 🎬 Vídeo demostración: Observación de contadores de rendimiento con PowerShell

Vídeo complementario con la demostración práctica de la observación de contadores de rendimiento con PowerShell.

<div class="video-embed">
  <iframe 
    src="https://www.youtube.com/embed/tiAcCdp5-P4" 
    title="Observación de contadores de rendimiento con PowerShell" 
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
    allowfullscreen>
  </iframe>
</div>

!!! info "Ver en YouTube"
    Si prefieres abrir el tutorial directamente en la plataforma o guardarlo en tus listas de reproducción, puedes acceder a través del siguiente enlace:  
    **[▶ Abrir vídeo directamente en YouTube](https://youtu.be/tiAcCdp5-P4)**

---

## 📈 5. Línea base de rendimiento

Una **línea base de rendimiento** describe cómo se comporta normalmente un servidor cuando funciona correctamente. Sirve como referencia para detectar cambios significativos.

No existe un valor universal que indique por sí solo que un servidor funciona bien o mal. Una utilización elevada de CPU, una reducción de memoria disponible o un aumento de la latencia de disco deben interpretarse teniendo en cuenta la carga de trabajo y el comportamiento habitual del sistema.

Por ejemplo:

| Métrica | Situación habitual | Situación que conviene investigar |
| :--- | :--- | :--- |
| CPU global | 10–25 % | 70 % de forma sostenida con una carga similar |
| Memoria disponible | 3–4 GiB | Menos de 1 GiB durante un periodo prolongado |
| Latencia de lectura | 2–5 ms | Aumento mantenido hasta 30–40 ms |

Estos valores son únicamente ilustrativos. Cada servidor debe compararse principalmente con su propio comportamiento anterior.

Para obtener una referencia básica:

1. selecciona unas pocas métricas relevantes;
2. registra varias muestras durante un periodo de funcionamiento normal;
3. conserva los resultados;
4. compara las mediciones posteriores con esos valores habituales.

!!! note "Línea base en el aula"
    Una captura de pocos minutos permite practicar el procedimiento, pero no constituye una línea base completa de un servidor real. En producción sería necesario observar periodos más largos y diferentes situaciones de carga.

### 5.1. Relacionar las métricas

Las siguientes relaciones orientan la interpretación; el diagnóstico completo de servicios e incidencias se trabajará por separado.

Una sola métrica rara vez permite identificar la causa de un problema.

Algunos ejemplos:

- **CPU elevada:** revisar qué procesos están consumiendo procesador.
- **Poca memoria disponible:** comprobar procesos, memoria comprometida y posible actividad de paginación.
- **Latencia de disco elevada:** relacionarla con la actividad y la cola del almacenamiento.
- **Servicio lento o inaccesible:** comprobar también su estado y los eventos producidos en ese periodo.

El procedimiento básico de diagnóstico será:

**detectar → medir → formular una hipótesis → comprobar → actuar → verificar**

---

## 🛠️ 6. Registrar mediciones con PowerShell

`Get-Counter` permite recoger varias muestras consecutivas y conservarlas para analizarlas posteriormente.

Un ejemplo sencillo:

```powershell
$Contadores = @(
    '\Procesador(_Total)\% de tiempo de procesador',
    '\Memoria\MBytes disponibles',
    '\Disco físico(_Total)\Promedio de segundos de disco/lectura'
)

Get-Counter `
    -Counter $Contadores `
    -SampleInterval 5 `
    -MaxSamples 12
```

Este ejemplo realiza una medición cada cinco segundos durante aproximadamente un minuto.

Para conservar históricos utilizaremos un script que transforma las muestras en objetos más fáciles de consultar y exportar.

Guarda el siguiente código como:

```text
C:\ASO\Scripts\AuditarServidor.ps1
```

```powershell
[CmdletBinding()]
param(
    [int]$Intervalo = 5,
    [int]$Muestras = 12,
    [string]$RutaExportacionCSV = ""
)
$Contadores = @{
    CPU = '\Procesador(_Total)\% de tiempo de procesador'
    Memoria = '\Memoria\MBytes disponibles'
    Disco = '\Disco físico(_Total)\Promedio de segundos de disco/lectura'
}
$Resultados = foreach (
    $Muestra in Get-Counter `
	    -Counter $($Contadores.Values) `
	-SampleInterval $Intervalo `
	-MaxSamples $Muestras
) {
    foreach ($Dato in $Muestra.CounterSamples) {
        $Nombre = switch -Wildcard ($Dato.Path) {
            '*\Procesador(_Total)\*' { 'CPU_Uso' }
            '*\Memoria\*'            { 'Memoria_Disponible' }
            '*\Disco físico(_Total)\*' { 'Disco_LatenciaLectura' }
        }
        # Solo procesamos muestras válidas:
        # 0 = dato válido
        # 1 = dato válido nuevo
        if ($Dato.Status -in @(0,1)) {
            $Valor = $Dato.CookedValue
            $Unidad = ''
            if ($Nombre -eq 'CPU_Uso') {
                $Unidad = '%'
            }
            elseif ($Nombre -eq 'Memoria_Disponible') {
                $Unidad = 'MiB'
            }
            elseif ($Nombre -eq 'Disco_LatenciaLectura') {
                $Valor = $Valor * 1000
                $Unidad = 'ms'
            }
            [PSCustomObject]@{
                Fecha    = $Muestra.Timestamp
                Servidor = $env:COMPUTERNAME
                Metrica  = $Nombre
                Valor    = [Math]::Round($Valor, 2)
                Unidad   = $Unidad
            }
        }
    }
}
if ($RutaExportacionCSV) {
    $Resultados |
        Export-Csv `
            -Path $RutaExportacionCSV `
            -NoTypeInformation `
            -Delimiter ';' `
            -Encoding UTF8
}
$Resultados
```

El script registra únicamente tres métricas fundamentales:

- utilización global de CPU;
- memoria disponible;
- latencia media de lectura del almacenamiento.

Este ejemplo permite practicar la recogida y exportación de contadores. Las métricas elegidas pueden adaptarse a la información que necesitemos observar.

### Ejemplos de utilización

```powershell
# Captura breve y visualización por pantalla.
C:\ASO\Scripts\AuditarServidor.ps1 `
    -Intervalo 5 `
    -Muestras 12 |
    Format-Table -AutoSize
```

```powershell
# Captura de aproximadamente cinco minutos y almacenamiento en CSV.
$Archivo = 'C:\ASO\Registros\Metricas-{0}.csv' `
    -f (Get-Date -Format 'yyyyMMdd-HHmmss')

C:\ASO\Scripts\AuditarServidor.ps1 `
    -Intervalo 5 `
    -Muestras 60 `
    -RutaExportacionCSV $Archivo
```

El archivo CSV contiene una fila por métrica y momento:

```text
Fecha;Servidor;Metrica;Valor;Unidad
09/10/2026 10:00:00;DC01;CPU_Uso;12,31;%
09/10/2026 10:00:00;DC01;Memoria_Disponible;2514;MiB
09/10/2026 10:00:00;DC01;Disco_LatenciaLectura;3,21;ms
```

Posteriormente puede importarse con PowerShell:

```powershell
$Datos = Import-Csv 'C:\ASO\Registros\Metricas-20261009-100000.csv' `
    -Delimiter ';'

$Datos |
    Where-Object Metrica -eq 'CPU_Uso'
```

O calcular una media sencilla:

```powershell
$Datos |
    Where-Object Metrica -eq 'CPU_Uso' |
    Measure-Object Valor -Average -Minimum -Maximum
```

Lo importante es comparar los valores obtenidos con el comportamiento habitual del servidor y relacionarlos con la actividad que se estaba realizando en ese momento.

### 🎬 Vídeo demostración: Registro de mediciones y línea base de rendimiento

Vídeo complementario con la demostración práctica del registro de mediciones y la obtención de la línea base de rendimiento con PowerShell.

<div class="video-embed">
  <iframe 
    src="https://www.youtube.com/embed/YDgtwSqiDYE" 
    title="Registro de mediciones y línea base de rendimiento" 
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
    allowfullscreen>
  </iframe>
</div>

!!! info "Ver en YouTube"
    Si prefieres abrir el tutorial directamente en la plataforma o guardarlo en tus listas de reproducción, puedes acceder a través del siguiente enlace:  
    **[▶ Abrir vídeo directamente en YouTube](https://youtu.be/YDgtwSqiDYE)**

---

## 🔎 7. Estado y configuración mediante CIM

Los contadores de rendimiento permiten observar **cómo evoluciona el sistema a lo largo del tiempo**. Sin embargo, para administrar un servidor también necesitamos conocer información como:

- qué sistema operativo está instalado;
- qué discos y adaptadores de red existen;
- cuánta memoria tiene el equipo;
- qué procesos se están ejecutando;
- qué servicios están instalados y cuál es su estado.

Windows permite consultar gran parte de esta información mediante **CIM (Common Information Model)**.

### 7.1. Modelo CIM

CIM define una forma común de representar mediante objetos los elementos administrables de un sistema. Cada tipo de elemento se describe mediante una **clase**, y cada elemento real del sistema aparece como una **instancia** de esa clase.

Por ejemplo:

| Clase CIM | Información que representa |
| :--- | :--- |
| `Win32_OperatingSystem` | Sistema operativo instalado |
| `Win32_ComputerSystem` | Equipo, memoria y configuración general |
| `Win32_Processor` | Procesadores |
| `Win32_LogicalDisk` | Unidades de disco |
| `Win32_NetworkAdapter` | Adaptadores de red |
| `Win32_Process` | Procesos en ejecución |
| `Win32_Service` | Servicios instalados |

Una clase contiene diferentes **propiedades**. Por ejemplo, las instancias de `Win32_Service` incluyen propiedades como `Name`, `State` o `StartMode`.

Podemos imaginarlo de forma simplificada como:

```text
Clase CIM
   │
   ├── Propiedades
   │
   └── Instancias
          │
          ├── Objeto 1
          ├── Objeto 2
          └── Objeto 3
```

Por ejemplo, `Win32_LogicalDisk` es la clase y `C:` o `D:` son posibles instancias:

```text
Win32_LogicalDisk
        │
        ├── C:
        │    ├── Size
        │    └── FreeSpace
        │
        └── D:
             ├── Size
             └── FreeSpace
```

En PowerShell utilizaremos principalmente:

```powershell
Get-CimInstance
```

Su funcionamiento básico es:

```powershell
Get-CimInstance -ClassName NombreClase
```

Por ejemplo:

```powershell
Get-CimInstance -ClassName Win32_OperatingSystem
```

PowerShell obtiene las instancias de esa clase y las devuelve como **objetos**, por lo que podemos utilizar las herramientas habituales del lenguaje para seleccionarlos, filtrarlos u ordenarlos:

```powershell
Get-CimInstance -ClassName Win32_OperatingSystem |
    Select-Object CSName, Caption, Version, LastBootUpTime
```

De la misma forma podemos consultar procesos:

```powershell
Get-CimInstance -ClassName Win32_Process |
    Select-Object ProcessId, Name, WorkingSetSize
```

o servicios:

```powershell
Get-CimInstance -ClassName Win32_Service |
    Select-Object Name, State, StartMode
```

!!! info "CIM y WMI"
    En Windows, muchas de las clases que utilizaremos conservan nombres históricos como `Win32_Process`, `Win32_Service` o `Win32_LogicalDisk`. Estas clases proceden de la infraestructura de administración de Windows tradicionalmente asociada a **WMI (Windows Management Instrumentation)**. En PowerShell moderno utilizaremos los cmdlets CIM, como `Get-CimInstance`, para acceder a esta información.

### 7.2. Descubrir clases y propiedades

No es necesario memorizar todas las clases CIM. Podemos descubrirlas desde PowerShell.

Por ejemplo, para buscar clases relacionadas con discos:

```powershell
Get-CimClass -ClassName '*Disk*' |
    Select-Object CimClassName
```

Para servicios:

```powershell
Get-CimClass -ClassName '*Service*' |
    Select-Object CimClassName
```

Una vez conocida una clase, podemos observar las propiedades que devuelve:

```powershell
Get-CimInstance -ClassName Win32_LogicalDisk |
    Get-Member
```

También podemos examinar directamente un objeto:

```powershell
Get-CimInstance -ClassName Win32_LogicalDisk |
    Select-Object -First 1 |
    Format-List *
```

En administración normalmente seguiremos este procedimiento:

```text
localizar la clase
        ↓
consultar sus instancias
        ↓
seleccionar las propiedades necesarias
        ↓
filtrar u ordenar la información
        ↓
interpretar el estado del sistema
```

A partir de aquí utilizaremos algunas clases CIM especialmente útiles para supervisar el servidor.

### 7.3. Capacidad y espacio libre

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

El porcentaje de espacio libre y el de ocupación son complementarios: ambos suman el 100 % cuando la capacidad es válida. Estas magnitudes describen el espacio disponible o utilizado, no la latencia ni la actividad del disco.

`DriveType=3` selecciona discos locales fijos visibles para Windows. En PowerShell, `1GB` equivale a 1.073.741.824 bytes; por eso las columnas se rotulan en **GiB**. Para estudiar volúmenes montados sin letra conviene ampliar la consulta con herramientas de volúmenes, como `Get-Volume`.

En Proxmox también hay que supervisar la capacidad del almacenamiento del host. El espacio libre dentro de una VM no describe cuánto queda en el almacenamiento que contiene sus discos virtuales.

### 7.4. Procesos y memoria residente como ampliación

```powershell
Get-CimInstance -ClassName Win32_Process |
    Sort-Object WorkingSetSize -Descending |
    Select-Object -First 5 ProcessId, Name, ExecutablePath,
        @{Name='WorkingSet_MiB'; Expression={[Math]::Round($_.WorkingSetSize / 1MB, 2)}}
```

`WorkingSetSize` representa memoria residente del proceso e incluye páginas que pueden compartirse. No debe sumarse sin más para calcular la RAM total ocupada. Algunas rutas de ejecutables pueden no estar disponibles con los permisos utilizados.

Un proceso grande o inactivo no debe finalizarse automáticamente. Primero se identifica su función, el servicio al que pertenece y si su comportamiento difiere de lo esperado.

### 7.5. Servicios esperados y ausentes como ampliación

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

!!! warning "Límite de la supervisión por CIM: verificación funcional"
    Un estado `Running` en CIM es una primera evidencia, pero no certifica que el servicio responda correctamente a las peticiones (el proceso podría estar bloqueado o no responder en la red).

    Siempre que sea posible, complementa la comprobación con una **prueba funcional** real desde un cliente. Por ejemplo, para verificar que el servicio DNS realmente resuelve consultas:

    ```powershell
    # Adapta dominio, nombre del servidor y registro a tu laboratorio.
    Resolve-DnsName -Name 'DC01.int.asix.info' -Type A `
        -Server 'DC01.int.asix.info' -DnsOnly -ErrorAction Stop
    ```

    Verifica que la dirección devuelta sea la prevista. Para separar problemas de resolución del propio nombre del servidor DNS, puede indicarse su IP en `-Server`. Esta prueba valida una consulta concreta; no verifica por sí sola la salud completa de Active Directory ni su replicación.

### 🎬 Vídeo demostración: Estado y configuración mediante el modelo CIM

Vídeo complementario con la demostración práctica de la consulta de estado y configuración del sistema mediante el modelo CIM con PowerShell.

<div class="video-embed">
  <iframe 
    src="https://www.youtube.com/embed/blIu2OdlJUs" 
    title="Estado y configuración mediante el modelo CIM" 
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
    allowfullscreen>
  </iframe>
</div>

!!! info "Ver en YouTube"
    Si prefieres abrir el tutorial directamente en la plataforma o guardarlo en tus listas de reproducción, puedes acceder a través del siguiente enlace:  
    **[▶ Abrir vídeo directamente en YouTube](https://youtu.be/blIu2OdlJUs)**

---

## ⚙️ 8. Ejecución periódica de los scripts

Una vez comprobada la captura manual, el **Programador de tareas de Windows** permite repetirla sin mantener una consola abierta. No es necesario dejar un bucle infinito ejecutándose en una sesión remota.

Para preparar la tarea:

1. Guarda los scripts y su configuración en una ruta estable, por ejemplo `C:\ASO\Scripts`.
2. Define el ejecutable de PowerShell, la ruta del script, sus argumentos y el directorio de trabajo. En Windows PowerShell 5.1 se utiliza `powershell.exe`; PowerShell 7 utiliza `pwsh.exe` y requiere instalación previa.
3. Elige una frecuencia adecuada al objetivo de la recogida y evita que se solapen ejecuciones.
4. Elige la identidad que ejecutará la tarea y comprueba sus permisos para consultar métricas y escribir los archivos de resultados.
5. Verifica una ejecución programada real: hora, estado final y datos nuevos. Poder lanzar el script manualmente no demuestra que la tarea funcione.

Después de registrar la tarea, puedes consultar su estado desde el servidor o dentro de una sesión remota:

```powershell
# Sustituye el nombre por el de la tarea registrada.
Get-ScheduledTask -TaskName 'ASO-Monitorizacion' |
    Select-Object TaskName, State

Get-ScheduledTaskInfo -TaskName 'ASO-Monitorizacion' |
    Select-Object LastRunTime, LastTaskResult, NextRunTime
```

El script debe distinguir una ejecución correcta de un fallo técnico mediante su código de salida. Un resultado `0` solo será significativo si el script comunica correctamente sus errores; comprueba también la fecha y el contenido de los registros generados.

!!! warning "Identidad de ejecución"
    La tarea no utiliza necesariamente la cuenta de tu consola. Elige una identidad con los permisos necesarios y comprueba el acceso a las carpetas de scripts y resultados. SYSTEM tiene amplios privilegios locales y no debe elegirse automáticamente para cualquier tarea. Protege los scripts frente a modificaciones por usuarios sin autorización y no guardes contraseñas en el código.

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
