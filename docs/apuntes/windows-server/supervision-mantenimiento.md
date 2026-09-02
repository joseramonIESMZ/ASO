# Supervisión y Mantenimiento de Sistemas

## 🎯 Relación con el Currículo (RA y CE)

* **Resultado de Aprendizaje 2 (RA2):** Gestiona la automatización de tareas del sistema, aplicando criterios de eficiencia y utilizando comandos y herramientas gráficas.
    * **CE 2.a:** Se han identificado los objetos del sistema que pueden ser supervisados.
    * **CE 2.b:** Se ha monitorizado el uso de los recursos del sistema en tiempo real.
    * **CE 2.c:** Se han generado gráficos y alertas de rendimiento.
    * **CE 2.g:** Se han programado tareas de mantenimiento preventivo y correctivo.

---

## 🏢 Fundamentos de la Supervisión y el Mantenimiento

La supervisión y mantenimiento en sistemas operativos son procesos esenciales para garantizar el funcionamiento estable, seguro y eficiente de los equipos y servicios informáticos. Ambos conceptos abarcan tareas técnicas y organizativas, y forman parte del trabajo continuo de administración de sistemas. En el ámbito empresarial, estas tareas diferencian un entorno reactivo (operar solo cuando hay fallos) de un entorno proactivo (prevenir incidentes).

### 📊 Funciones de la Supervisión

La supervisión consiste en vigilar y controlar el estado de los sistemas, con el objetivo de detectar, prevenir y resolver problemas antes de que afecten al rendimiento o a la disponibilidad.

Las principales funciones de supervisión incluyen:

* **Monitoreo de recursos de hardware:** CPU, memoria, disco, red, procesos y uso de aplicaciones.
* **Detección de anomalías y auditoría:** Fallos de hardware, saturación de recursos, intentos de acceso no autorizados o interrupciones de servicio.
* **Registrar y analizar métricas:** Logs/eventos del sistema y herramientas de monitorización.
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
| **Monitor de Rendimiento** | `perfmon.msc` | Recolecta métricas de CPU, memoria, disco, red, etc, y las muestra mediante gráficas. |
| **Monitor de Recursos** | `resmon.exe` | Muestra actividad por proceso, hilos, y uso de recursos en tiempo real. |
| **Visor de Eventos** | `eventvwr.msc` | Auditoría de registros de sistema, seguridad, aplicaciones y servicios del directorio. |
| **Administrador de Tareas** | `taskmgr` | Supervisión de procesos en ejecución, rendimiento y usuarios conectados. |
| **PowerShell Core** | `powershell.exe` | Herramienta de línea de comandos para la gestión y automatización de tareas.  |
| **Windows Admin Center** | Servicios Web | Consola centralizada web idónea para la supervisión y administración para entornos híbridos o múltiples servidores. |

---

## 💻 Telemetría Avanzada con Contadores de Rendimiento

El **Monitor de Rendimiento (PerfMon)** funciona extrayendo datos de objetos del sistema a través de métricas específicas denominadas **Contadores de Rendimiento**. Estas métricas se exponen directamente a la capa de administración y automatización de PowerShell Core mediante el cmdlet `Get-Counter`.

Por ejemplo,

```powershell
Get-Counter -Counter "\Memoria\Bytes disponibles"
```

**CounterSamples** nos proporciona el valor actual del contador. 

```powershell
(Get-Counter -Counter "\Memoria\Bytes disponibles" | Select-Object -ExpandProperty CounterSamples).CookedValue
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
\Network Interface(Ethernet)\Bytes Total/sec
```

que corresponde a:

```text
Objeto:     Network Interface
Instancia:  Ethernet
Contador:   Bytes Total/sec
```

En este caso, únicamente se está supervisando la interfaz de red denominada `Ethernet`.

También es posible utilizar el carácter comodín `*` para seleccionar todas las instancias disponibles de un objeto:

```text
\Network Interface(*)\Bytes Total/sec
```

De esta forma, Windows recopilará la métrica `Bytes Total/sec` para cada una de las interfaces de red existentes en el sistema.

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

```
Un valor elevado de forma puntual no implica necesariamente un problema. Para realizar un diagnóstico adecuado deben analizarse su **duración**, su **evolución temporal** y su relación con otros contadores.
```

Por ejemplo, un servidor de bases de datos sometido a una operación intensiva puede alcanzar temporalmente valores elevados de CPU sin que exista ningún problema. Por el contrario, un controlador de dominio que habitualmente mantiene una utilización reducida de CPU y comienza a presentar valores significativamente superiores durante varias horas puede requerir investigación.

La línea base permite, por tanto, pasar de una supervisión basada únicamente en valores absolutos a una **supervisión basada en el comportamiento del sistema y en la detección de desviaciones**.

#### Recopilación de datos para establecer la línea base

Una única medición representa únicamente una fotografía del estado del servidor. Para construir una línea base es necesario recopilar métricas durante un periodo suficientemente representativo de su funcionamiento normal.

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

* **`\Procesador(_Total)\% de tiempo de procesador`:** Carga de computación total del sistema. Si se mantiene de forma sostenida en torno al 100%, indica la necesidad de redimensionar los núcleos de la MV en Proxmox.
* **`\Procesador(_Total)\% de tiempo privilegiado`:** Mide el esfuerzo dedicado al código del anillo 0 del kernel (controladores, llamadas de entrada/salida). Valores altos indican problemas de compatibilidad de hardware virtualizado.
* **`\System\Longitud de la cola de la CPU`:** Número de hilos listos esperando ejecución. Si el valor supera de forma constante el doble de los núcleos físicos asignados, existe una saturación de CPU estructural.

### 2. Subsistema de Memoria RAM

* **`\Memoria\Mbytes disponibles`:** Cantidad de memoria física libre para asignación inmediata.
* **`\Memoria\% de bytes confirmados en uso`:** Muestra el porcentaje del límite de memoria comprometida que está siendo utilizado. Valores persistentemente elevados pueden indicar presión de memoria y deben analizarse junto con otros contadores, como MBytes disponibles y Páginas/s.
* **`\Memoria\Páginas/s`:** Número de páginas de memoria por segundo que Windows lee del disco o escribe en él para resolver fallos de página duros (hard page faults). Un valor elevado y sostenido puede indicar presión de memoria, aunque debe analizarse junto con otros contadores, como MBytes disponibles, ya que por sí solo no demuestra que exista falta de memoria RAM.

### 3. Subsistema de Almacenamiento (Discos Físicos y Lógicos)

* **`\PhysicalDisk(_Total)\% de tiempo de disco`:** Porcentaje de tiempo que la unidad está procesando solicitudes de lectura o escritura.
* **`\PhysicalDisk(_Total)\Longitud media de la cola de disco`:** Cantidad de operaciones pendientes en espera en el bus de almacenamiento. En discos de estado sólido (NVMe), valores superiores a **2 o 3** indican un cuello de botella en las controladoras lógicas de Proxmox.
* **`\PhysicalDisk(_Total)\Promedio de disco s/lectura`:** Latencia física de lectura expresada en milisegundos. En entornos empresariales y bases de datos SQL Server, valores superiores a **0.020 segundos (20 ms)** se consideran críticos.

### 4. Subsistema de Interfaz de Red

* **`\Network Interface(*)\Bytes totales/s`:** Ancho de banda consumido por las interfaces del servidor. Esencial para detectar ataques de denegación de servicio o saturación en las transferencias de copias de seguridad.
* **`\Network Interface(*)\Errores de recepción de paquetes`:** Contingencias físicas o descartes en la recepción de tramas de red.

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

Script de Auditoría de Contadores del Sistema (AuditarServidor.ps1)
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
$RutaDisco = "\PhysicalDisk(_Total)\Longitud media de la cola de disco"

Write-Host "[*] Recolectando muestras de rendimiento en tiempo real..." -ForegroundColor Yellow

# Captura de objetos
$MuestraCPU   = Get-Counter -Counter $RutaCPU
$MuestraRAM   = Get-Counter -Counter $RutaRAM
$MuestraDisco = Get-Counter -Counter $RutaDisco

# Extracción de valores cocinados (Cooked Values)
$ValorCPU   = [Math]::Round(($MuestraCPU.CounterSamples).CookedValue, 2)
$ValorRAM   = ($MuestraRAM.CounterSamples).CookedValue
$ValorDisco = [Math]::Round(($MuestraDisco.CounterSamples).CookedValue, 2)

# Volcado analítico por consola
Write-Host ""
Write-Host "  ► Carga Total de CPU:        $ValorCPU %" -ForegroundColor (if ($ValorCPU -gt 85) { "Red" } else { "Green" })
Write-Host "  ► Memoria RAM Disponible:    $ValorRAM MB" -ForegroundColor (if ($ValorRAM -lt 512) { "Red" } else { "Green" })
Write-Host "  ► Cola de Espera de Disco:   $ValorDisco op." -ForegroundColor (if ($ValorDisco -gt 3) { "Red" } else { "Green" })
Write-Host ""
Write-Host "========================================================" -ForegroundColor Indigo
```

🔍 Descubrimiento de Contadores vía Línea de Comandos
Cuando nos enfrentamos a un servidor con una instalación limpia de un rol específico (como SQL Server o Active Directory), el administrador necesita descubrir qué contadores se han registrado en el sistema.


```powershell
# Listar todos los conjuntos de contadores (Sets) registrados en la máquina
Get-Counter -ListSet * | Select-Object CounterSetName | Out-Host -Paging

# Listar de forma explícita todos los contadores individuales incluidos dentro del objeto Memoria
Get-Counter -ListSet Memoria | Select-Object -ExpandProperty Counter
```

Extracción de Metadatos y Descripciones del SO (lodctr.exe)
Para extraer la base de datos de descripciones técnicas de cada contador de rendimiento del servidor y filtrar los metadatos limpios, volcamos la configuración a un archivo Unicode y parseamos las cadenas mediante expresiones regulares:


```powershell
# 1. Exportar de forma binaria y segura las descripciones del sistema operativo
lodctr /s:descripcionPerfMon.txt

# 2. Parsear el archivo Unicode buscando patrones de cadenas descriptivas de los contadores
Get-Content -Path "descripcionPerfMon.txt" -Encoding Unicode | Select-String -Pattern ".*=.*" | Out-File -FilePath ".\descripContadoresLlimpias.txt"
```

---

## 💾 Supervisión Avanzada mediante Clases CIM (Common Information Model)

Aunque los contadores de rendimiento (`Get-Counter`) son ideales para métricas en tiempo real que varían segundo a segundo (como el % de uso de CPU), la infraestructura de administración **CIM/WMI** es la herramienta idónea para supervisar el **estado de salud estático y estructural** del servidor (hardware, almacenamiento permanente, procesos y servicios del sistema).

En entornos modernos de producción y arquitecturas *Server Core*, se prioriza el uso de los cmdlets `*-CimInstance` sobre los antiguos cmdlets de WMI, ya que CIM opera de forma nativa sobre el protocolo estándar **WS-Man (WinRM)** de administración remota, garantizando conexiones seguras, rápidas y eficientes a través del cortafuegos corporativo.

### 1. Supervisión del Almacenamiento Lógico (`CIM_LogicalDisk`)
Es fundamental supervisar de forma automatizada el espacio disponible en los volúmenes del sistema para evitar caídas críticas del controlador de dominio por falta de almacenamiento.

Mediante la clase `CIM_LogicalDisk`, podemos filtrar los discos lógicos del servidor. Para entornos reales, debemos discriminar y analizar únicamente aquellas unidades que correspondan a discos duros reales o arreglos RAID del hipervisor (las cuales devuelven un identificador de tipo de medio o `MediaType` igual a `12`), ignorando unidades ópticas o pendrives extraíbles.

```powershell
# Obtener el estado, tamaño total y espacio libre de los discos lógicos persistentes
Get-CimInstance -ClassName CIM_LogicalDisk | Where-Object { $_.MediaType -eq 12 } | Select-Object DeviceID, 
    @{Name="Tamaño_GB";Expression={[Math]::Round($_.Size / 1GB, 2)}}, 
    @{Name="Libre_GB";Expression={[Math]::Round($_.FreeSpace / 1GB, 2)}},
    @{Name="Ocupación_%";Expression={[Math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 2)}}
```

### 2. Supervisión de Procesos Críticos en Ejecución (CIM_Process)
El administrador debe auditar de forma desatendida qué hilos o procesos están consumiendo los recursos de memoria y computación del servidor en un momento dado. La clase CIM_Process permite mapear el identificador del proceso (ProcessId), su consumo de memoria RAM física en el Working Set (WorkingSetSize) y la ruta del binario ejecutable:

```powershell
# Listar los 5 procesos que más memoria RAM física están consumiendo en el servidor
Get-CimInstance -ClassName CIM_Process | 
    Sort-Object WorkingSetSize -Descending | 
    Select-Object ProcessId, Name, @{Name="RAM_Consumida_MB";Expression={[Math]::Round($_.WorkingSetSize / 1MB, 2)}} -First 5
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

📈 Integración en la Base de Datos del Proyecto (Métricas Mixtas)
La combinación de ambas herramientas dota a la organización de un sistema de monitorización centralizado profesional:

Los scripts programados en PowerShell recolectan las métricas dinámicas con Get-Counter y los estados estructurales con Get-CimInstance.

Los datos limpios recopilados se procesan y se inyectan en la base de datos centralizada monitoriza de SQL Server mediante el comando Invoke-Sqlcmd, consolidando el cuadro de mando de salud de toda la red corporativa.

🔍 Laboratorio de Desafíos y Troubleshooting (Entorno Proxmox)

💥 Caso Práctico: Desbordamiento de la Cola de la CPU por sobreasignación de vCPUs en Proxmox
Síntoma: Al levantar de forma simultánea los servidores virtuales de bases de datos de los 4 equipos de alumnos sobre el hardware físico del host de aula, la latencia en las terminales PowerShell Remoting (WinRM) se eleva a niveles inaceptables. Al intentar capturar datos, el contador \System\Longitud de la cola de la CPU arroja valores de forma sostenida superiores a 15.

Causa Raíz: Incumplimiento del pilar de virtualización y análisis de recursos. Al disponer de procesadores físicos con configuraciones específicas de cores, si los scripts de despliegue automatizados de los alumnos asignan más CPUs virtuales de las físicas disponibles reales (Overcommitting), el planificador (Scheduler) del hipervisor Proxmox VE entra en un escenario de contención, obligando a las CPUs virtuales de los Windows Server a esperar en cola de forma prolongada antes de procesar los hilos del kernel.

Solución Operativa en Clase: El alumno debe apagar la máquina virtual del servidor afectado y reconfigurar la asignación de hardware desde la CLI o la interfaz web del entorno de virtualización de Proxmox. Desde la terminal del hipervisor, audita la carga real y reduce los sockets/cores lógicos asignados a la máquina virtual para equilibrar el pool de hilos de ejecución del host:

```bash
# Auditar desde Proxmox el uso real de tiempo de CPU y contención por máquina virtual
pct list   # Para contenedores LXC
qm list    # Para Máquinas Virtuales Windows Server
```

📚 Referencias y Fuentes Consultadas
!!! info "Documentación Oficial y Autoría"
* Material Base: Basado en la presentación didáctica empresarial "UD3. Fundamentos de administración de Windows Server - Supervisión y mantenimiento" del Departamento de Informática del IES Marcos Zaragoza.
* Diseño y Autoría: José Ramón Soria Nieto.
* Entorno de Aplicación: Módulo profesional de Administración de Sistemas Operativos (ASO), correspondiente al Segundo Curso del Ciclo Formativo de Grado Superior en Administración de Sistemas Informáticos en Red (ASIR/ASIX).

!!! abstract "Soporte Institucional y Fondos Europeos"
* Entidad Reguladora: Generalitat Valenciana — Conselleria d'Educació, Cultura i Esport.
* Financiación de Infraestructura: Proyecto cofinanciado por la Unión Europea a través del Fondo Social Europeo (FSE).
* «El FSE invierte en tu futuro» — Acciones destinadas a la modernización de entornos tecnológicos de Formación Profesional e inserción laboral avanzada en administración de sistemas.