# Programación de Tareas Automatizadas

## 🎯 Relación con el Currículo (RA y CE)

* **Resultado de Aprendizaje 2 (RA2):** Gestiona la automatización de tareas del sistema, aplicando criterios de eficiencia y utilizando comandos y herramientas gráficas.
    * **CE 2.e:** Se han utilizado estructuras de control y variables en la creación de scripts.
    * **CE 2.f:** Se han depurado y documentado los scripts realizados.
    * **CE 2.g:** Se han programado tareas de mantenimiento preventivo y correctivo utilizando las herramientas del sistema operativo.

---

## 🏢 Arquitectura del Programador de Tareas (Task Scheduler)

La automatización de procesos recurrentes y scripts administrativos en Windows Server se centraliza a través del **Programador de Tareas (Task Scheduler)**. Este servicio subyacente (`Taskschd.msc`) se ejecuta de manera permanente en segundo plano con el propósito de vigilar eventos y lanzar acciones de control sin requerir la intervención humana o la apertura de interfaces de usuario.

Cualquier objeto tarea registrado dentro del sistema está compuesto estructuralmente por cuatro componentes lógicos definidos en un esquema almacén XML:

* **Desencadenadores (Triggers):** Especifican las condiciones de tiempo o evento que dictaminan cuándo debe inicializarse la ejecución (ej: a una hora exacta, al arrancar el host, al iniciar sesión).
* **Acciones (Actions):** Definen la operación física concreta que va a realizar el sistema operativo (ejecutar un binario, lanzar un script de PowerShell Core, inicializar un ejecutable).
* **Condiciones (Conditions):** Requisitos de estado adicionales que validan si el contexto de hardware es apto para la tarea (ej: evaluar si el equipo está inactivo o conectado a la red eléctrica).
* **Configuraciones (Settings):** Parámetros avanzados de comportamiento operativo (conmutación en paralelo, reintentos automatizados ante fallos o detención por tiempo de seguridad).

---

## 🛠️ Laboratorio Técnico: Registro de Eventos desde Scripts

Para auditar de forma fehaciente que nuestras tareas programadas se ejecutan en los tiempos estipulados por la organización, utilizaremos el **Visor de Eventos (Event Viewer)** como mecanismo de validación centralizado.

A continuación, se detalla el script base de verificación de infraestructura que los alumnos deben implementar en el volumen de almacenamiento del servidor. Este código se encarga de dar de alta una nueva fuente de registro en el log de *Aplicación* y escribir una entrada informativa cada vez que es invocado:

```powershell
# E:\scripts\pruebatarea.ps1
# Script de validación operativa para tareas programadas

$Mensaje = "La tarea programada se ha ejecutado correctamente en $(Get-Date)"
$Fuente  = "MiTareaProgramada"

# Validar la existencia de la fuente de eventos en el registro del sistema operativo
if (-not [System.Diagnostics.EventLog]::SourceExists($Fuente)) {
    # Requiere privilegios elevados de Administrador para su inicialización
    New-EventLog -LogName Application -Source $Fuente
}

# Inyectar la entrada informativa en el log de Aplicación
Write-EventLog -LogName Application -Source $Fuente -EntryType Information -EventId 1000 -Message $Mensaje
```

💻 Gestión Operativa mediante PowerShell Core
El aprovisionamiento de tareas programadas en entornos Server Core se realiza utilizando el módulo nativo de administración de tareas.

1. Programación Básica (Contexto de Sesión Interactiva)
Por defecto, si registramos una tarea de forma simplificada, el sistema asume de manera automática que la acción se ejecutará bajo el contexto del usuario actual y únicamente si dicho usuario mantiene una sesión interactiva abierta en el equipo.

```powershell
# Paso 1: Definir la acción (Lanzar el motor de PowerShell pasando el script por parámetro)
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File E:\scripts\pruebatarea.ps1"

# Paso 2: Definir el disparador cronológico (Ejecución diaria a las 16:30)
$Trigger = New-ScheduledTaskTrigger -Daily -At 4:30pm

# Paso 3: Registrar de forma persistente la tarea lista para ejecución
Register-ScheduledTask -TaskName "PruebaTarea" -Action $Action -Trigger $Trigger -Description "Tarea de prueba básica"
```

2. Programación Avanzada (Sin Sesión Iniciada y Usuario Específico)
Para scripts de infraestructura críticos (como las tareas de monitorización centralizada contra SQL Server), las acciones deben ejecutarse independientemente de si el administrador tiene la sesión abierta en el servidor.

Para independizar la tarea del inicio de sesión, debemos instanciar un objeto de seguridad tipo Principal (New-ScheduledTaskPrincipal), asignando el tipo de logon mediante contraseña persistente (-LogonType Password).

```powershell
# Paso 1: Configurar la acción y el trigger (En este caso, ejecución única en 5 minutos)
$Action  = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File E:\scripts\pruebatarea.ps1"
$Trigger = New-ScheduledTaskTrigger -Once -At ((Get-Date).AddMinutes(5))

# Paso 2: Forzar el contexto de seguridad desatendido mediante un Principal
$Principal = New-ScheduledTaskPrincipal -UserId "MIEMPRESA\joseramon" -LogonType Password

# Paso 3: Ensamblar la estructura completa del objeto Tarea
$ObjectTarea = New-ScheduledTask -Action $Action -Trigger $Trigger -Principal $Principal -Description "Tarea desatendida"

# Paso 4: Registrar en el sistema inyectando de forma segura las credenciales de ejecución
Register-ScheduledTask -TaskName "PruebaTareaDesatendida" -InputObject $ObjectTarea -User "MIEMPRESA\joseramon" -Password (Read-Host "Introduce contraseña de red")
```

3. Programación con Configuración de Parámetros Adicionales (Settings)
Para entornos de movilidad o servidores de tolerancia a fallos, las propiedades avanzadas o Settings regulan contingencias de hardware críticas mediante el cmdlet New-ScheduledTaskSettingsSet:

```powershell
# Definir parámetros avanzados de tolerancia a fallos energéticos y reintentos
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances Parallel -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 5)

# El objeto settings se acopla directamente al instanciar el objeto de la tarea
$ObjectTareaCompleta = New-ScheduledTask -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Description "Tarea con políticas de resiliencia"
```

⏱️ Escenarios Comunes de Despliegue en el Proyecto
A. Repetición a Intervalos Regulares (Telemetría de Sprints)
Para flujos de monitorización continua automatizada, se programan disparadores basados en intervalos recurrentes combinando los parámetros -RepetitionInterval y -RepetitionDuration:

```powershell
# Definir lapsos temporales de repetición continuados
$Repite = New-TimeSpan -Minutes 1
$Dura   = New-TimeSpan -Minutes 5

$Action  = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File E:\scripts\pruebatarea.ps1"
$Trigger = New-ScheduledTaskTrigger -Once -At 11:01 -RepetitionInterval $Repite -RepetitionDuration $Dura

Register-ScheduledTask -TaskName "MétricasRecurrentes" -Action $Action -Trigger $Trigger
```

B. Ejecución Automatizada al Inicio del Servidor (-AtStartup)
Ideal para el script progTareaInicio.ps1, garantizando que los demonios de captura se inicialicen inmediatamente al arrancar el nodo de Proxmox, sin depender de accesos remotos WinRM manuales posteriores:

```powershell
$Action    = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File E:\scripts\pruebatarea.ps1"
$Trigger   = New-ScheduledTaskTrigger -AtStartup
$Principal = New-ScheduledTaskPrincipal -UserId "MIEMPRESA\Administrador" -LogonType Password

$ObjectTareaInicio = New-ScheduledTask -Action $Action -Trigger $Trigger -Principal $Principal
Register-ScheduledTask "TareaServicioInicio" -InputObject $ObjectTareaInicio -User "MIEMPRESA\Administrador" -Password "ContraseñaAdmin"
```

🔍 Validación Operativa e Inspección del Historial
Para certificar que el planificador de tareas ha coordinado correctamente las llamadas desatendidas y extraer los metadatos de las marcas de tiempo, auditamos el registro de seguridad mediante comandos lógicos de filtrado:

```powershell
# Consultar de forma analítica los eventos generados por nuestra tarea en el log
Get-WinEvent -LogName Application | Where-Object {
    $_.Id -eq 1000 -and 
    $_.ProviderName -eq "MiTareaProgramada"
} | Select-Object TimeCreated, Message | Format-List
```

🔍 Laboratorio de Desafíos y Troubleshooting (Entorno Proxmox)
💥 Caso Práctico: Detención de scripts de monitorización por límites de tiempo de CPU
Síntoma: Tras implementar el script de automatización del Sprint 3 destinado a capturar datos de rendimiento de forma indefinida, la tarea programada pasa repentinamente de estado Running a Ready transcurridas exactamente 72 horas, deteniendo por completo el volcado de métricas en la base de datos de SQL Server.

Causa Raíz: Configuración de directivas de seguridad implícitas en el sistema operativo. Por defecto, al instanciar una tarea programada sin especificar configuraciones avanzadas de entorno (Settings), Windows Server le asigna una propiedad oculta de limitación de tiempo de ejecución de seguridad (ExecutionTimeLimit) equivalente a 3 días (72 horas), procediendo a matar de forma imperativa los procesos hijos vinculados a PowerShell al expirar dicho temporizador.

Solución Operativa en Clase: El alumno debe modificar los metadatos de la tarea forzando la anulación del límite de tiempo. Para ello, debe generar un conjunto de parámetros avanzados deshabilitando la directiva de parada mediante una variable de tiempo en valor cero (`[TimeSpan]::Zero`) y actualizar el registro de la tarea:

```powershell
# Forzar la anulación estricta del límite de tiempo de ejecución en caliente
$SettingsModificados = New-ScheduledTaskSettingsSet -ExecutionTimeLimit [TimeSpan]::Zero

# Aplicar la reconfiguración sobre la tarea existente en el controlador de dominio
Set-ScheduledTask -TaskName "PruebaTareaDesatendida" -Settings $SettingsModificados
```

📚 Referencias y Fuentes Consultadas
!!! info "Documentación Oficial y Autoría"
* Material Base: Basado en la unidad temática empresarial "UD3. Fundamentos de administración de Windows Server - Programación de tareas" desarrollada por el Departamento de Informática del IES Marcos Zaragoza.
* Diseño Curricular y Cátedra: José Ramón Soria Nieto.
* Entorno Formativo: Módulo de Administración de Sistemas Operativos (ASO), correspondiente al Segundo Curso del Ciclo Formativo de Grado Superior en Administración de Sistemas Informáticos en Red (ASIR/ASIX).

!!! abstract "Soporte Institucional y Fondos Europeos"
* Entidad Reguladora: Generalitat Valenciana — Conselleria d'Educació, Cultura i Esport.
* Financiación Institucional: Proyecto cofinanciado por la Unión Europea a través del Fondo Social Europeo (FSE).
* «El FSE invierte en tu futuro» — Acciones enfocadas en la optimización tecnológica, la formación técnica avanzada y el desarrollo de habilidades de automatización digital para infraestructuras informáticas en red.

