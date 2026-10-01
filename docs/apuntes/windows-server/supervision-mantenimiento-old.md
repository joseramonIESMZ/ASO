# Supervisión y Mantenimiento de Sistemas

## 🎯 Relación con el Currículo (RA y CE)

* **Resultado de Aprendizaje 2 (RA2):** Gestiona la automatización de tareas del sistema, aplicando criterios de eficiencia y utilizando comandos y herramientas gráficas.
    * **CE 2.a:** Se han identificado los objetos del sistema que pueden ser supervisados.
    * **CE 2.b:** Se ha monitorizado el uso de los recursos del sistema en tiempo real.
    * **CE 2.c:** Se han generado gráficos y alertas de rendimiento.
    * **CE 2.g:** Se han programado tareas de mantenimiento preventivo y correctivo.

---

## 🏢 Fundamentos de la Supervisión y el Mantenimiento

La supervisión y el mantenimiento en sistemas operativos son procesos esenciales para garantizar el funcionamiento estable, seguro y eficiente de los equipos y servicios informáticos. Ambos conceptos abarcan tareas técnicas y organizativas, y forman parte del trabajo continuo de administración de sistemas. En el ámbito empresarial, estas tareas diferencian un entorno reactivo (operar solo cuando hay fallos) de un entorno proactivo (prevenir incidentes).

### 📊 Funciones de la Supervisión

La supervisión consiste en vigilar y controlar el estado de los sistemas, con el objetivo de detectar, prevenir y resolver problemas antes de que afecten al rendimiento o a la disponibilidad.

Las principales funciones de supervisión incluyen:

* **Monitoreo de recursos de hardware:** CPU, memoria, disco, red, procesos y uso de aplicaciones.
* **Detección de anomalías y auditoría:** Fallos de hardware, saturación de recursos, intentos de acceso no autorizados o interrupciones de servicio.
* **Generar alertas y reportes:** Cuando se supera un umbral de uso o se produce un fallo, el sistema informa al operador para que actúe rápidamente.

En resumen, supervisar un sistema operativo equivale a ejercer una vigilancia sobre su rendimiento, seguridad y disponibilidad, permitiendo tomar decisiones informadas para mantener su correcto funcionamiento.

### ⚙️ Áreas de Mantenimiento Preventivo y Evolutivo

El mantenimiento complementa la supervisión, y se centra en conservar el buen estado del sistema a lo largo del tiempo. Implica aplicar acciones correctivas, preventivas y evolutivas.

Entre las tareas más comunes destacan:

* **Hardening y parches:** Despliegue automatizado de actualizaciones del sistema con parches de seguridad y mejoras del sistema operativo.
* **Resiliencia de datos:** Ejecución de copias de seguridad (*Backups*) automatizadas y verificación estricta de la integridad de los datos replicados.
* **Optimización de recursos:** Liberación de espacio, limpieza de procesos inactivos y configuración de recursos.
* **Gestión de usuarios y permisos:** Control de accesos y auditoría de privilegios.
* **Revisión de hardware asociado:** Detección temprana de fallas en discos, memoria o componentes físicos.
* **Documentación técnica:** Registro de incidencias, configuraciones y cambios realizados.
---

## 🛠️ Herramientas de Supervisión en Windows Server

Windows Server provee un conjunto de consolas nativas optimizadas para analizar la telemetría del sistema sin necesidad de cargar agentes de terceros en entornos de producción:

| Herramienta | Binario / Comando | Ámbito de Aplicación |
| :--- | :--- | :--- |
| **Monitor de Rendimiento** | `perfmon.msc` | Recolecta métricas de CPU, memoria, disco y red, entre otras, y las representa gráficamente. |
| **Monitor de Recursos** | `resmon.exe` | Muestra actividad por proceso, hilos, y uso de recursos en tiempo real. |
| **Visor de Eventos** | `eventvwr.msc` | Auditoría de registros de sistema, seguridad, aplicaciones y servicios del directorio. |
| **Administrador de Tareas** | `taskmgr` | Supervisión de procesos en ejecución, rendimiento y usuarios conectados. |
| **PowerShell** | `pwsh.exe` | Herramienta de línea de comandos para la gestión y automatización de tareas.  |
| **Windows Admin Center** | Servicios Web | Consola centralizada web idónea para la supervisión y administración para entornos híbridos o múltiples servidores. |

---

## 💻 Telemetría Avanzada con Contadores de Rendimiento

El **Monitor de Rendimiento (PerfMon)** funciona extrayendo datos de objetos del sistema a través de métricas específicas denominadas **Contadores de Rendimiento**. Estas métricas pueden consultarse desde PowerShell mediante el cmdlet `Get-Counter`.

Por ejemplo,

```powershell
Get-Counter -Counter "\Memoria\MBytes disponibles"
```

**CounterSamples** nos proporciona el valor actual del contador. 

```powershell
(Get-Counter -Counter "\Memoria\MBytes disponibles" | Select-Object -ExpandProperty CounterSamples).CookedValue
```

### ⚠️ El Factor del Idioma en Producción (Localización)

Un error crítico habitual en la automatización de la monitorización es obviar que **los contadores de rendimiento se escriben en el idioma nativo de la instalación de Windows Server**. Si intentas ejecutar un script configurado con contadores en inglés sobre un servidor instalado en español, la ejecución fallará inmediatamente al no resolverse la ruta del objeto.

---

### 🧩 Estructura de los Contadores de Rendimiento: Objeto, Instancia y Contador

En Windows, los contadores de rendimiento se organizan de forma jerárquica. Cada métrica pertenece a un **objeto de rendimiento**, puede hacer referencia a una **instancia concreta** de ese objeto y finalmente mide un **contador específico**.

La estructura habitual de una ruta de contador es:

```text
\Objeto(Instancia)\Contador
```

Los tres elementos principales son:

* **Objeto:** representa el componente o subsistema del sistema que queremos supervisar. Por ejemplo, el procesador, la memoria, un disco físico, una interfaz de red o un proceso.
* **Instancia:** identifica un elemento concreto cuando existen varias unidades del mismo objeto. Por ejemplo, un servidor puede tener varios procesadores lógicos, discos, interfaces de red o procesos.
* **Contador:** representa la métrica concreta que queremos medir sobre ese objeto, como el porcentaje de uso de CPU, los MBytes de memoria disponibles o los bytes transmitidos por segundo.

Por ejemplo, la siguiente ruta:

```text
\Procesador(_Total)\% de tiempo de procesador
```

se interpreta de la siguiente forma:

```text
Objeto:     Procesador
Instancia:  _Total
Contador:   % de tiempo de procesador
```

La instancia `_Total` indica que el contador debe calcularse considerando el conjunto de todas las instancias disponibles.

Otro ejemplo es:

```text
\Network Interface(Ethernet)\Total Bytes/sec
```

que corresponde a:

```text
Objeto:     Network Interface
Instancia:  Ethernet
Contador:   Total Bytes/sec
```

En este caso, únicamente se está supervisando la interfaz de red denominada `Ethernet`. **Observa cómo el nombre de los objetos, instancias y contadores sigue estando en inglés.** En esta documentación, no obstante, indicaremos los contadores preferentemente en español.

También es posible utilizar el carácter comodín `*` para seleccionar todas las instancias disponibles de un objeto:

```text
\Network Interface(*)\Total Bytes/sec
```

De esta forma, Windows recopilará la métrica `Total Bytes/sec` para cada una de las interfaces de red existentes en el sistema.

Comprender esta estructura facilita tanto la utilización gráfica del **Monitor de Rendimiento (PerfMon)** como la automatización de la supervisión mediante PowerShell y el cmdlet `Get-Counter`.

### 📈 Línea Base de Rendimiento (*Performance Baseline*)

La supervisión de un servidor no debe limitarse a comprobar si determinados contadores superan unos valores predefinidos. Para determinar si el comportamiento de un sistema es anómalo es necesario conocer previamente **cómo se comporta cuando funciona correctamente**.

Una **línea base de rendimiento (*performance baseline*)** es un conjunto de mediciones recopiladas durante un periodo de tiempo que permite establecer el **comportamiento habitual de un sistema en condiciones normales de funcionamiento**.

Para construir una línea base se recopilan periódicamente métricas representativas de los principales subsistemas del servidor, como:

* Utilización del procesador.
* Memoria disponible y actividad de paginación.
* Latencia y actividad de los dispositivos de almacenamiento.
* Utilización de las interfaces de red.
* Estado y consumo de recursos de procesos y servicios relevantes.

Por ejemplo, después de monitorizar durante varios días un servidor podemos observar que, durante su horario habitual de funcionamiento, presenta aproximadamente el siguiente comportamiento:

| Métrica            | Comportamiento habitual                      |
| :----------------- | :------------------------------------------- |
| Uso de CPU         | 10-25 %                                      |
| Memoria disponible | 3-4 GB                                       |
| Latencia de disco  | 2-5 ms                                       |
| Tráfico de red     | Estable durante la mayor parte de la jornada |

Estos valores constituyen una referencia con la que comparar mediciones posteriores.

Si posteriormente el servidor mantiene durante un periodo prolongado un uso de CPU del 65 %, una memoria disponible inferior a 1 GB y una latencia de disco de 35 ms, estos valores pueden indicar una anomalía aunque ninguno de ellos haya superado necesariamente un umbral de alerta previamente establecido.

Por tanto, durante el análisis del rendimiento debemos considerar tres elementos:

1. **Valor actual:** indica qué está ocurriendo en el sistema en un momento determinado.
2. **Umbral:** establece un valor a partir del cual una determinada métrica requiere atención.
3. **Línea base:** permite determinar si el comportamiento actual se desvía significativamente del comportamiento habitual del sistema.

!!! warning "Los umbrales no son valores universales"
    Los valores utilizados como umbrales de CPU, memoria, almacenamiento o red deben considerarse **referencias orientativas**. Su interpretación depende del hardware, la carga de trabajo, los servicios ejecutados y el comportamiento habitual del servidor.
    Un valor elevado de forma puntual no implica necesariamente un problema.
    Para realizar un diagnóstico adecuado deben analizarse su **duración**,
    su **evolución temporal** y su relación con otros contadores.


Por ejemplo, un servidor de bases de datos sometido a una operación intensiva puede alcanzar temporalmente valores elevados de CPU sin que exista ningún problema. Por el contrario, un controlador de dominio que habitualmente mantiene una utilización reducida de CPU y comienza a presentar valores significativamente superiores durante varias horas puede requerir investigación.

La línea base permite, por tanto, pasar de una supervisión basada únicamente en valores absolutos a una **supervisión basada en el comportamiento del sistema y en la detección de desviaciones**.

#### Recopilación de datos para establecer la línea base

Una única medición representa únicamente una fotografía del estado del servidor. Para construir una línea base es necesario recopilar métricas durante un periodo suficientemente representativo de su funcionamiento normal.

```powershell
Get-Counter `
    -Counter "\Procesador(_Total)\% de tiempo de procesador" `
    -SampleInterval 2 `
    -MaxSamples 5
```

```text
-SampleInterval 2 → una muestra cada 2 segundos
-MaxSamples 5     → obtener 5 muestras
```

El **Monitor de Rendimiento (PerfMon)** permite realizar esta recopilación mediante los **Conjuntos de recopiladores de datos (*Data Collector Sets*)**, almacenando los valores de los contadores durante un periodo determinado para analizarlos posteriormente mediante gráficos e informes.

PowerShell también permite automatizar la recopilación periódica de métricas mediante `Get-Counter`.

De esta forma, el proceso de supervisión puede resumirse como:

```text
Recopilar métricas
       ↓
Establecer el comportamiento habitual
       ↓
Definir la línea base
       ↓
Continuar monitorizando
       ↓
Detectar desviaciones
       ↓
Correlacionar diferentes métricas
       ↓
Diagnosticar la posible causa
```

El objetivo de la supervisión no consiste únicamente en **obtener valores de los contadores**, sino en ser capaz de **interpretarlos dentro del contexto de funcionamiento del servidor**.


## 📋 Catálogo de Contadores Esenciales para Servidores de Producción

Para monitorizar de forma automatizada los controladores de dominio y servidores de bases de datos del proyecto integrador, el administrador debe auditar los siguientes contadores nativos en castellano:

### 1. Subsistema de Procesador (CPU)

* **`\Procesador(_Total)\% de tiempo de procesador`:** porcentaje de tiempo durante el cual el conjunto de procesadores está ocupado ejecutando código. Una utilización elevada y sostenida puede indicar saturación de CPU y debe analizarse junto con la longitud de la cola de CPU, los procesos activos y la línea base del servidor.
* **`\Proceso(*)\% de tiempo de procesador`:** permite identificar qué procesos están consumiendo tiempo de CPU. Resulta útil cuando el contador global de procesador muestra una utilización elevada y es necesario determinar qué proceso puede estar originándola.

```text
\Procesador(_Total)\% de tiempo de procesador
             ↓
      CPU global elevada
             ↓
\Proceso(*)\% de tiempo de procesador
             ↓
       ¿Quién consume CPU?
```

* **`\Procesador(_Total)\% de tiempo privilegiado`:** mide el esfuerzo dedicado al código del anillo 0 del kernel (controladores, llamadas de entrada/salida). Un valor elevado indica que una proporción importante del tiempo de CPU se está consumiendo en modo kernel. Debe correlacionarse con actividad de E/S, controladores, interrupciones y otros contadores para determinar la causa.
* **`\Sistema\Longitud de la cola de la CPU`:** número de hilos preparados para ejecutarse que esperan tiempo de procesador. Una cola elevada y sostenida, especialmente cuando coincide con una utilización elevada de CPU, puede indicar contención de procesador. Debe interpretarse considerando el número de procesadores lógicos disponibles y la línea base del servidor.

### 2. Subsistema de Memoria RAM

* **`\Memoria\Mbytes disponibles`:** cantidad de memoria física que Windows puede poner inmediatamente a disposición de procesos o del propio sistema. Incluye tanto memoria libre como memoria reutilizable rápidamente.
* **`\Memoria\% de bytes confirmados en uso`:** muestra el porcentaje del límite de memoria comprometida que está siendo utilizado. Valores persistentemente elevados pueden indicar presión de memoria y deben analizarse junto con otros contadores, como MBytes disponibles y Páginas/s.
* **`\Memoria\Páginas/s`:** número de páginas de memoria por segundo que Windows lee del disco o escribe en él para resolver fallos de página duros (hard page faults). Un valor elevado y sostenido puede indicar presión de memoria, aunque debe analizarse junto con otros contadores, como MBytes disponibles, ya que por sí solo no demuestra que exista falta de memoria RAM.

### 3. Subsistema de Almacenamiento (Discos Físicos y Lógicos)

* **`\Disco físico(_Total)\% de tiempo de disco`:** porcentaje de tiempo que la unidad está procesando solicitudes de lectura o escritura.

* **`\Disco físico(_Total)\Promedio de disco s/lectura`:** tiempo medio que tarda el subsistema de almacenamiento en completar una operación de lectura. El valor se expresa en **segundos**, por lo que, por ejemplo, un valor de `0,015` equivale a **15 ms**. Una latencia elevada y sostenida puede indicar problemas de rendimiento en el almacenamiento, aunque debe interpretarse teniendo en cuenta el tipo de dispositivo, la carga de trabajo y la línea base del servidor.

* **`\Disco físico(_Total)\Promedio de disco s/escritura`:** tiempo medio que tarda el subsistema de almacenamiento en completar una operación de escritura. Al igual que en las lecturas, el valor se expresa en segundos. Una latencia de escritura elevada y persistente puede indicar saturación del almacenamiento, problemas en la infraestructura subyacente o una carga de escritura superior a la capacidad habitual del sistema.

* **`\Disco físico(_Total)\Longitud media de la cola de disco`:** indica el número medio de solicitudes de entrada/salida que se encuentran siendo atendidas o esperando ser procesadas por el subsistema de almacenamiento durante el intervalo de medición. Un valor elevado no implica necesariamente, por sí solo, que exista un problema de rendimiento, especialmente en dispositivos SSD o NVMe, capaces de procesar múltiples operaciones de E/S de forma concurrente. 
Por este motivo, este contador debe interpretarse junto con otros indicadores, los anteriores de **latencia de lectura y escritura** (`Promedio de disco s/lectura` y `Promedio de disco s/escritura`) y el volumen de operaciones realizadas.

De forma general:

```text
Cola elevada + latencia baja
        ↓
Puede corresponder a una carga elevada pero correctamente atendida.

Cola elevada + latencia elevada y sostenida
        ↓
Puede indicar saturación o contención en el subsistema de almacenamiento.
```

La interpretación debe realizarse teniendo en cuenta el tipo de almacenamiento utilizado, la carga habitual del servidor y su línea base de rendimiento.


### 4. Subsistema de Interfaz de Red

* **`\Interfaz de red(*)\Total de Bytes/s`:** tasa de transferencia total de datos de la interfaz, sumando tráfico enviado y recibido por las interfaces del servidor. Permite analizar el grado de utilización de la interfaz y detectar situaciones de saturación o incrementos anómalos de tráfico.
* **`\Interfaz de red(*)\Paquetes recibidos con errores`:** número de paquetes recibidos que contienen errores y no pueden procesarse correctamente. Un incremento sostenido puede indicar problemas en el adaptador, el enlace, controladores o la infraestructura de red.

## 🔗 Correlación de Métricas durante el Diagnóstico

Los contadores de rendimiento **no deben interpretarse de forma aislada**. Un valor elevado o anómalo en un único contador no permite determinar, por sí solo, la existencia ni la causa de un problema de rendimiento.

Durante el diagnóstico es necesario **correlacionar varias métricas relacionadas**, observar su evolución temporal y compararlas con la **línea base de rendimiento** del servidor. De esta forma es posible distinguir entre variaciones normales de la carga y situaciones que pueden indicar un cuello de botella.

| Posible problema                  | Métricas que conviene correlacionar                                                                     | Interpretación                                                                                                                                                                                                             |
| :-------------------------------- | :------------------------------------------------------------------------------------------------------ | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Saturación de CPU**             | `% de tiempo de procesador` + `Longitud de la cola de la CPU` + `% de tiempo de procesador` por proceso | Una utilización elevada de CPU acompañada de una cola elevada y sostenida puede indicar contención de procesador. El análisis por proceso permite identificar qué aplicaciones o servicios están consumiendo CPU.          |
| **Presión de memoria**            | `MBytes disponibles` + `% de bytes confirmados en uso` + `Páginas/s`                                    | Una cantidad reducida de memoria disponible, un porcentaje elevado de memoria comprometida y una actividad sostenida de paginación pueden indicar presión de memoria.                                                      |
| **Saturación del almacenamiento** | `Promedio de disco s/lectura` + `Promedio de disco s/escritura` + `Longitud media de la cola de disco`  | Una cola elevada no implica necesariamente un problema. Si además aumenta de forma sostenida la latencia de lectura o escritura, puede existir saturación o contención en el subsistema de almacenamiento.                 |
| **Problemas de red**              | `Total de Bytes/s` + `Paquetes recibidos con errores` + capacidad nominal de la interfaz                | Un tráfico elevado próximo a la capacidad de la interfaz puede indicar saturación. La aparición sostenida de paquetes con errores puede señalar problemas en el adaptador, controladores, enlace o infraestructura de red. |

Por ejemplo, si un servidor presenta una respuesta lenta y el contador de CPU muestra una utilización elevada, el administrador no debería concluir inmediatamente que existe falta de capacidad de procesamiento. El diagnóstico puede continuar analizando la longitud de la cola de CPU y posteriormente los contadores asociados a los diferentes procesos:

```text
CPU elevada
    ↓
¿La cola de CPU también es elevada de forma sostenida?
    ↓
Sí
    ↓
Analizar el consumo de CPU por proceso
    ↓
Identificar el proceso o servicio responsable
    ↓
Investigar la causa
```

Del mismo modo, una cola de disco elevada debe correlacionarse con la latencia de lectura y escritura antes de determinar que existe un cuello de botella de almacenamiento.

Por tanto, el proceso de diagnóstico puede resumirse como:

```text
Detectar una desviación
        ↓
Consultar métricas relacionadas
        ↓
Correlacionar los valores
        ↓
Comparar con la línea base
        ↓
Formular una hipótesis
        ↓
Obtener nuevas evidencias
        ↓
Identificar la posible causa
```

!!! tip "Principio básico de diagnóstico"
    **Un contador permite detectar un síntoma; la correlación de varios contadores permite aproximarse a su causa.**

---

## 🛠️ Automatización del Diagnóstico con PowerShell

El valor de producción de los contadores reside en la capacidad del administrador para capturar estos datos e inyectarlos de forma desatendida en bases de datos centralizadas de telemetría.

### Captura Básica y Extracción del Valor Cocinado (`CookedValue`)

El cmdlet `Get-Counter` devuelve un objeto complejo. Para extraer únicamente el valor numérico limpio (*CookedValue*), procesamos el objeto devuelto filtrando sus propiedades internas de la siguiente forma:

```powershell
# Capturar la métrica de memoria disponible en tiempo real
$MétricaRAM = Get-Counter -Counter "\Memoria\Mbytes disponibles"

# Extraer el valor numérico limpio procesando la colección de muestras
$RAMLimpia = ($MétricaRAM.CounterSamples).CookedValue
Write-Host "La memoria RAM disponible actual en el servidor es de: $RAMLimpia MB"
```

### Script de Auditoría de Contadores del Sistema (AuditarServidor.ps1)
Este script automatiza la consulta masiva de los subsistemas del servidor Core, capturando las métricas críticas del sistema:


```powershell
<#
.SYNOPSIS
    Script de captura de telemetría base para Windows Server Core.
.DESCRIPTION
    Extrae el estado operacional de los subsistemas de CPU, RAM y Almacenamiento
    para tareas de supervisión técnica preventiva.
#>

Clear-Host
Write-Host "========================================================" -ForegroundColor Indigo
Write-Host "   TELEMETRÍA OPERACIONAL DE INFRAESTRUCTURA WINDOWS   " -ForegroundColor White
Write-Host "========================================================" -ForegroundColor Indigo

# Definición de rutas de contadores en español de forma estricta
$RutaCPU  = "\Procesador(_Total)\% de tiempo de procesador"
$RutaRAM  = "\Memoria\Mbytes disponibles"
$RutaLatLectura   = "\Disco físico(_Total)\Promedio de disco s/lectura"
$RutaLatEscritura = "\Disco físico(_Total)\Promedio de disco s/escritura"
$RutaCola         = "\Disco físico(_Total)\Longitud media de la cola de disco"

Write-Host "[*] Recolectando muestras de rendimiento en tiempo real..." -ForegroundColor Yellow

# Captura de objetos
$MuestraCPU   = Get-Counter -Counter $RutaCPU
$MuestraRAM   = Get-Counter -Counter $RutaRAM
$MuestraCola = Get-Counter -Counter $RutaCola
$MuestraLatLectura   = Get-Counter -Counter $RutaLatLectura
$MuestraLatEscritura = Get-Counter -Counter $RutaLatEscritura

# Extracción de valores cocinados (Cooked Values)
$ValorCPU   = [Math]::Round(($MuestraCPU.CounterSamples).CookedValue, 2)
$ValorRAM = [Math]::Round(
    ($MuestraRAM.CounterSamples).CookedValue, 2
)
$ValorLatLectura = [Math]::Round(
    ($MuestraLatLectura.CounterSamples).CookedValue * 1000, 2
)
$ValorLatEscritura = [Math]::Round(
    ($MuestraLatEscritura.CounterSamples).CookedValue * 1000, 2
)
$ValorCola = [Math]::Round(($MuestraCola.CounterSamples).CookedValue, 2)

# Volcado analítico por consola
Write-Host ""
Write-Host "  ► Carga Total de CPU:                     $ValorCPU %"
Write-Host "  ► Memoria RAM Disponible:                 $ValorRAM MB"
Write-Host "  ► Longitud media de la cola de disco:     $ValorCola"
Write-Host "  ► Latencia Lectura:                       $ValorLatLectura ms"
Write-Host "  ► Latencia Escritura:                     $ValorLatEscritura ms"
Write-Host ""
Write-Host "========================================================" -ForegroundColor Indigo
```

### 🔍 Descubrimiento de Contadores vía Línea de Comandos
Cuando nos enfrentamos a un servidor con una instalación limpia de un rol específico (como SQL Server o Active Directory), el administrador necesita descubrir qué contadores se han registrado en el sistema.


```powershell
# Listar todos los conjuntos de contadores (Sets) registrados en la máquina
Get-Counter -ListSet * | Select-Object CounterSetName | Out-Host -Paging

# Listar de forma explícita todos los contadores individuales incluidos dentro del objeto Memoria
Get-Counter -ListSet Memoria | Select-Object -ExpandProperty Counter
```

---

## 💾 Supervisión Avanzada mediante Clases CIM (Common Information Model)

Aunque los contadores de rendimiento (`Get-Counter`) son especialmente adecuados para obtener **métricas de rendimiento que evolucionan con el tiempo**, como el porcentaje de uso de CPU, la actividad de memoria o la latencia de disco, la infraestructura **CIM/WMI** permite consultar principalmente **el estado, la configuración y las propiedades de los recursos del sistema**.

De forma simplificada, ambas tecnologías responden a preguntas diferentes:

* **`Get-Counter`:** ¿cómo se está comportando el sistema?
* **`Get-CimInstance`:** ¿qué recursos existen, cómo están configurados y cuál es su estado actual?

Por ejemplo, mediante CIM podemos consultar los discos disponibles y su espacio libre, los procesos que se encuentran en ejecución, el estado de los servicios del sistema, la memoria instalada, los adaptadores de red o las características del sistema operativo.

En entornos modernos de administración de Windows Server, se prioriza el uso de los cmdlets `*-CimInstance` frente a los antiguos cmdlets de WMI. Además, CIM facilita la administración remota mediante sesiones CIM y puede utilizar **WS-Man (WinRM)** como mecanismo de comunicación remota.

### 1. Supervisión del Almacenamiento Lógico (`Win32_LogicalDisk`)

Es fundamental supervisar de forma automatizada el espacio disponible en los volúmenes del sistema para evitar problemas derivados de la falta de almacenamiento.

Mediante la clase `Win32_LogicalDisk` podemos consultar las unidades lógicas disponibles en el sistema y obtener información como su identificador, tamaño total y espacio libre.

En este caso interesa analizar únicamente las unidades de almacenamiento fijo, excluyendo dispositivos extraíbles o unidades ópticas. Una forma sencilla de hacerlo es filtrar por aquellas unidades cuyo tipo corresponda a un disco local.

```powershell
# Obtener el estado, tamaño total y espacio libre de los discos locales
Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" |
    Select-Object DeviceID,
        @{Name="Tamaño_GB"; Expression={[Math]::Round($_.Size / 1GB, 2)}},
        @{Name="Libre_GB";  Expression={[Math]::Round($_.FreeSpace / 1GB, 2)}},
        @{Name="Ocupación_%"; Expression={
            if ($_.Size -gt 0) {
                [Math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 2)
            } else { 0 }
        }}
```

El valor `DriveType = 3` identifica unidades de disco local desde el punto de vista del sistema operativo. En una máquina virtual, estas unidades pueden corresponder a discos virtuales presentados por el hipervisor, por lo que esta consulta describe el almacenamiento lógico visible desde Windows, no necesariamente el dispositivo físico real subyacente.


### 2. Supervisión de Procesos Críticos en Ejecución (Win32_Process)
El administrador puede auditar qué procesos están consumiendo más memoria física en un momento determinado. Ejemplo de cómo la clase `Win32_Process` permite consultar propiedades como el identificador del proceso (ProcessId), su consumo de memoria física (WorkingSetSize) y otras características del proceso:

```powershell
# Listar los 5 procesos que más memoria RAM física están consumiendo en el servidor
Get-CimInstance -ClassName Win32_Process | 
    Sort-Object WorkingSetSize -Descending | 
    Select-Object ProcessId, Name, ExecutablePath, @{Name="RAM_Consumida_MB";Expression={[Math]::Round($_.WorkingSetSize / 1MB, 2)}} -First 5
```

### 3. Supervisión del Estado de los Servicios del Sistema (Win32_Service)
Para certificar la disponibilidad de la infraestructura del aula, es necesario monitorizar que los servicios vitales de Active Directory (como el DNS o el servicio de replicación DFSR) se encuentren en estado de ejecución (Running) y configurados en inicio automático:

```powershell
# Auditar el estado de salud de los servicios de red esenciales del Controlador de Dominio
$ServiciosCríticos = "DNS", "NTDS", "DFSR", "Kdc"
Get-CimInstance -ClassName Win32_Service | 
    Where-Object { $_.Name -in $ServiciosCríticos } | 
    Select-Object Name, DisplayName, StartMode, State
```

### 📈 Integración en la Base de Datos del Proyecto (Métricas Mixtas)
La combinación de ambas herramientas dota a la organización de un sistema de monitorización centralizado profesional:

Los scripts programados en PowerShell recolectan métricas de rendimiento mediante Get-Counter y consultan el estado y las propiedades de los recursos del sistema mediante Get-CimInstance.

Los datos recopilados se procesan y almacenan en la base de datos centralizada de monitorización de SQL Server mediante Invoke-Sqlcmd, consolidando así la información de supervisión de los diferentes servidores de la infraestructura.

## 🔍 Laboratorio de Desafíos y Troubleshooting (Entorno Proxmox)

### 💥 Caso práctico: Contención de CPU por sobreasignación de vCPU en Proxmox
Síntoma: Al levantar de forma simultánea los servidores virtuales de bases de datos de los 4 equipos de alumnos sobre el hardware físico del host de aula, la latencia en las terminales PowerShell Remoting (WinRM) se eleva a niveles inaceptables. Al intentar capturar datos, el contador \Sistema\Longitud de la cola de la CPU arroja valores de forma sostenida superiores a 15.

Hipótesis de diagnóstico: Una posible causa es una sobreasignación excesiva de vCPU respecto a la capacidad disponible del host. Si los scripts de despliegue automatizados de los alumnos asignan un número de vCPU significativamente superior a la capacidad de CPU física disponible en el host (Overcommitting), puede provocarse contención de CPU en el host, lo que puede aumentar los tiempos de espera percibidos por las máquinas virtuales.

Solución Operativa en Clase: El alumno debe apagar la máquina virtual del servidor afectado y reconfigurar la asignación de hardware desde la CLI o la interfaz web del entorno de virtualización de Proxmox. Desde la terminal del hipervisor, audita la carga real y reduce el número de vCPU asignadas a la máquina virtual para reducir la contención de CPU en el host:

```bash
# Identificar las máquinas virtuales y contenedores activos
pct list   # Para contenedores LXC
qm list    # Para Máquinas Virtuales Windows Server
# Examinar la carga del host y los procesos que consumen CPU
top
# Revisar carga global del host
uptime
```

## 📚 Referencias y Fuentes Consultadas
!!! info "Documentación Oficial y Autoría"
* Material Base: Basado en la presentación didáctica empresarial "UD3. Fundamentos de administración de Windows Server - Supervisión y mantenimiento" del Departamento de Informática del IES Marcos Zaragoza.
* Diseño y Autoría: José Ramón Soria Nieto.
* Entorno de Aplicación: Módulo profesional de Administración de Sistemas Operativos (ASO), correspondiente al Segundo Curso del Ciclo Formativo de Grado Superior en Administración de Sistemas Informáticos en Red (ASIR/ASIX).

!!! abstract "Soporte Institucional y Fondos Europeos"
* Entidad Reguladora: Generalitat Valenciana — Conselleria d'Educació, Cultura i Esport.
* Financiación de Infraestructura: Proyecto cofinanciado por la Unión Europea a través del Fondo Social Europeo (FSE).
* «El FSE invierte en tu futuro» — Acciones destinadas a la modernización de entornos tecnológicos de Formación Profesional e inserción laboral avanzada en administración de sistemas.