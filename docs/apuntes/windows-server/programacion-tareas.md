# Programación de tareas automatizadas

## 🎯 Relación con el currículo (RA y CE)

**Resultado de Aprendizaje 3 (RA3):** Gestiona la automatización de tareas del sistema, aplicando criterios de eficiencia y utilizando comandos y herramientas gráficas.

En esta unidad se trabajan principalmente los siguientes criterios de evaluación:

- **CE1-RA3:** Se han descrito las ventajas de la automatización de las tareas repetitivas en el sistema.
- **CE2-RA3:** Se han utilizado los comandos del sistema para la planificación de tareas.
- **CE3-RA3:** Se han establecido restricciones de seguridad.
- **CE4-RA3:** Se han realizado planificaciones de tareas repetitivas o puntuales relacionadas con la administración del sistema.
- **CE8-RA3:** Se han documentado los procesos programados como tareas automáticas.

!!! note "Herramienta gráfica"
    Si la práctica se complementa con la consola gráfica **Programador de tareas**, también se trabajan **CE6-RA3** y **CE7-RA3**.

---

## 1. Introducción

En un servidor es habitual ejecutar de forma automática tareas como:

- copias de seguridad;
- generación y rotación de registros;
- comprobaciones periódicas del estado del sistema;
- scripts de mantenimiento;
- tareas de supervisión;
- ejecución de procesos al arrancar el servidor.

Windows incorpora el **Programador de tareas (Task Scheduler)** para ejecutar estas acciones de forma automática.

!!! important "Servicio y herramienta de administración"
    El **Programador de tareas** funciona mediante el servicio de Windows **Task Scheduler** (`Schedule`).

    La consola `taskschd.msc` es únicamente la herramienta gráfica utilizada para administrar las tareas. En **Windows Server Core** la administración se realiza normalmente mediante PowerShell.

Podemos comprobar el estado del servicio con:

```powershell
Get-Service -Name Schedule
```

---

## 2. Elementos de una tarea programada

Una tarea programada se construye a partir de varios elementos:

| Elemento | Función |
|---|---|
| **Acción (Action)** | Indica qué comando, programa o script se debe ejecutar. |
| **Desencadenador (Trigger)** | Define cuándo debe ejecutarse la tarea. |
| **Principal** | Determina la cuenta de usuario y el contexto de seguridad con el que se ejecutará. |
| **Configuración (Settings)** | Define opciones como reintentos, límite de tiempo o comportamiento ante ejecuciones simultáneas. |

Por ejemplo:

```text
Trigger
   │
   ▼
Tarea programada
   │
   ├── Principal
   ├── Settings
   │
   ▼
Action
   │
   ▼
Script de PowerShell
```

Una tarea puede disponer de **varios desencadenadores** y también de **varias acciones**.

---

## 3. Script de prueba

Antes de crear una tarea programada construiremos un script sencillo que deje constancia de cada ejecución.

Creamos la carpeta:

```powershell
New-Item -Path C:\ASO\scripts -ItemType Directory -Force
New-Item -Path C:\ASO\logs -ItemType Directory -Force
```

Creamos el fichero:

```text
C:\ASO\scripts\pruebatarea.ps1
```

con el siguiente contenido:

```powershell
$Fecha = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"$Fecha - Tarea ejecutada correctamente" |
    Add-Content -Path "C:\ASO\logs\pruebatarea.log"
```

Podemos comprobar primero su funcionamiento manualmente:

```powershell
C:\ASO\scripts\pruebatarea.ps1
```

y revisar el resultado:

```powershell
Get-Content C:\ASO\logs\pruebatarea.log
```

!!! tip "Primero el script, después la tarea"
    Antes de programar cualquier script conviene comprobar que funciona correctamente al ejecutarlo manualmente. De este modo resulta más sencillo distinguir entre un error del **script** y un error de **configuración de la tarea programada**.

---

## 4. Administración mediante PowerShell

Los cmdlets utilizados pertenecen al módulo **ScheduledTasks**:

```powershell
Get-Command -Module ScheduledTasks
```

Los más habituales son:

| Cmdlet | Función |
|---|---|
| `New-ScheduledTaskAction` | Crea una acción. |
| `New-ScheduledTaskTrigger` | Crea un desencadenador. |
| `New-ScheduledTaskPrincipal` | Define el contexto de seguridad. |
| `New-ScheduledTaskSettingsSet` | Define la configuración avanzada. |
| `New-ScheduledTask` | Construye el objeto tarea. |
| `Register-ScheduledTask` | Registra la tarea en el sistema. |
| `Get-ScheduledTask` | Consulta tareas registradas. |
| `Get-ScheduledTaskInfo` | Consulta información de ejecución. |
| `Start-ScheduledTask` | Ejecuta una tarea manualmente. |
| `Set-ScheduledTask` | Modifica una tarea. |
| `Unregister-ScheduledTask` | Elimina una tarea. |

!!! warning "Windows Server Core no significa PowerShell Core"
    **Windows Server Core** es una modalidad de instalación de Windows Server sin la interfaz gráfica completa.

    El ejecutable `powershell.exe` corresponde a **Windows PowerShell**. Si se instala PowerShell 7, su ejecutable es `pwsh.exe`.

---

## 5. Crear una tarea programada básica

Vamos a ejecutar el script todos los días a las 16:30.

### 5.1. Definir la acción

```powershell
$Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument '-NoProfile -File "C:\ASO\scripts\pruebatarea.ps1"'
```

### 5.2. Definir el desencadenador

```powershell
$Trigger = New-ScheduledTaskTrigger `
    -Daily `
    -At 16:30
```

### 5.3. Registrar la tarea

```powershell
Register-ScheduledTask `
    -TaskName "PruebaTarea" `
    -Action $Action `
    -Trigger $Trigger `
    -Description "Tarea de prueba de ASO"
```

Esta forma resulta adecuada para realizar **pruebas sencillas con el usuario actual**.

En tareas de administración reales conviene definir explícitamente **qué cuenta ejecutará la tarea** y con qué privilegios.

---

## 6. Comprobar una tarea

Podemos consultar la tarea creada:

```powershell
Get-ScheduledTask -TaskName "PruebaTarea"
```

Para consultar información de su última ejecución:

```powershell
Get-ScheduledTaskInfo -TaskName "PruebaTarea"
```

Las propiedades más útiles son:

- `LastRunTime`
- `LastTaskResult`
- `NextRunTime`
- `NumberOfMissedRuns`

También podemos provocar una ejecución manual:

```powershell
Start-ScheduledTask -TaskName "PruebaTarea"
```

y comprobar el fichero de registro:

```powershell
Get-Content C:\ASO\logs\pruebatarea.log
```

---

## 7. Ejecución desatendida con una cuenta específica

Una tarea administrativa puede necesitar ejecutarse aunque ningún usuario tenga una sesión iniciada.

Para ello debemos definir el **Principal**, es decir, la identidad con la que se ejecutará.

Supongamos que disponemos de la cuenta de dominio:

```text
INT\svc_tareas
```

Solicitamos sus credenciales:

```powershell
$Credencial = Get-Credential `
    -UserName 'INT\svc_tareas' `
    -Message "Credenciales para ejecutar la tarea"
```

El cmdlet `Get-Credential` devuelve un objeto de tipo `PSCredential` que contiene el nombre de usuario y la contraseña. La contraseña no se almacena como texto normal, sino como un objeto de tipo `SecureString`.

Podemos acceder directamente al nombre del usuario mediante:

```powershell
$Credencial.UserName
```

Definimos la acción y el desencadenador:

```powershell
$Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument '-NoProfile -File "C:\ASO\scripts\pruebatarea.ps1"'

$Trigger = New-ScheduledTaskTrigger `
    -Once `
    -At ((Get-Date).AddMinutes(5))
```

Creamos el principal utilizando como usuario el almacenado en el objeto `$Credencial`:

```powershell
$Principal = New-ScheduledTaskPrincipal `
    -UserId $Credencial.UserName `
    -LogonType Password
```

Construimos la tarea:

```powershell
$Tarea = New-ScheduledTask `
    -Action $Action `
    -Trigger $Trigger `
    -Principal $Principal `
    -Description "Tarea desatendida de ASO"
```

Finalmente, la registramos:

```powershell
Register-ScheduledTask `
    -TaskName "PruebaTareaDesatendida" `
    -InputObject $Tarea `
    -User $Credencial.UserName `
    -Password $Credencial.GetNetworkCredential().Password
```

!!! info "¿Por qué se utiliza `GetNetworkCredential()`?"
    La contraseña almacenada en `$Credencial` es un objeto `SecureString`, pero el parámetro `-Password` de `Register-ScheduledTask` necesita recibir una contraseña como cadena de texto (`String`).

    Por este motivo se utiliza:

    ```powershell
    $Credencial.GetNetworkCredential().Password
    ```

    El método `GetNetworkCredential()` permite obtener temporalmente las credenciales como un objeto de tipo `NetworkCredential`. A partir de este objeto podemos acceder a propiedades como:

    ```powershell
    $Credencial.GetNetworkCredential().UserName
    $Credencial.GetNetworkCredential().Domain
    $Credencial.GetNetworkCredential().Password
    ```

    En este caso utilizamos únicamente `.Password` para proporcionar a `Register-ScheduledTask` la contraseña en el formato que necesita.

    De esta forma, la contraseña **no queda escrita directamente en el script**, sino que se introduce de forma interactiva mediante `Get-Credential`.

!!! warning "Principio de mínimo privilegio"
    No debemos utilizar una cuenta de **Domain Admins** para una tarea programada salvo que sea estrictamente necesario.

    Lo habitual es crear una cuenta específica de servicio y concederle únicamente los permisos necesarios para realizar su función.

### ¿Por qué utilizar `LogonType Password`?

Con este tipo de inicio de sesión, la tarea puede ejecutarse de forma **no interactiva**, aunque el usuario no tenga una sesión abierta.

Existe también `LogonType S4U`, que evita almacenar una contraseña, pero tiene una limitación importante: la tarea no puede acceder normalmente a recursos de red ni a archivos cifrados utilizando las credenciales del usuario.

---

## 8. Configuración avanzada de la tarea

Podemos controlar el comportamiento de una tarea mediante `New-ScheduledTaskSettingsSet`.

Por ejemplo:

```powershell
$Settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -MultipleInstances IgnoreNew `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 5)
```

Estas opciones indican que:

- si se pierde una ejecución, se intentará iniciar posteriormente;
- si la tarea anterior todavía está ejecutándose, no se iniciará otra instancia;
- si la tarea falla, se intentará reiniciar hasta tres veces;
- habrá cinco minutos entre reintentos.

!!! tip "Evitar ejecuciones simultáneas"
    En scripts de monitorización o mantenimiento suele ser conveniente impedir que se solapen varias instancias del mismo script.

Podemos utilizar los ajustes al crear la tarea:

```powershell
$Tarea = New-ScheduledTask `
    -Action $Action `
    -Trigger $Trigger `
    -Principal $Principal `
    -Settings $Settings
```

---

## 9. Ejecución periódica

Podemos ejecutar una tarea varias veces utilizando:

- `-RepetitionInterval`
- `-RepetitionDuration`

Ejemplo: ejecutar el script cada minuto durante cinco minutos.

```powershell
$Intervalo = New-TimeSpan -Minutes 1
$Duracion  = New-TimeSpan -Minutes 5

$Trigger = New-ScheduledTaskTrigger `
    -Once `
    -At ((Get-Date).AddMinutes(1)) `
    -RepetitionInterval $Intervalo `
    -RepetitionDuration $Duracion
```

Registramos la tarea:

```powershell
Register-ScheduledTask `
    -TaskName "PruebaRepeticion" `
    -Action $Action `
    -Trigger $Trigger
```

Este tipo de planificación resulta útil para tareas periódicas de **supervisión y mantenimiento**.

---

## 10. Ejecución al iniciar el servidor

También podemos ejecutar una tarea cada vez que arranca Windows Server:

```powershell
$Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument '-NoProfile -File "C:\ASO\scripts\pruebatarea.ps1"'

$Trigger = New-ScheduledTaskTrigger -AtStartup
```

Si el script solo necesita recursos locales del servidor, podemos utilizar la cuenta integrada **SYSTEM**:

```powershell
$Principal = New-ScheduledTaskPrincipal `
    -UserId "SYSTEM" `
    -LogonType ServiceAccount `
    -RunLevel Highest
```

Construimos y registramos la tarea:

```powershell
$Tarea = New-ScheduledTask `
    -Action $Action `
    -Trigger $Trigger `
    -Principal $Principal `
    -Description "Ejecución automática al iniciar el servidor"

Register-ScheduledTask `
    -TaskName "TareaInicioServidor" `
    -InputObject $Tarea
```

!!! note
    Si el script necesita acceder a recursos de red mediante una identidad de dominio, habrá que utilizar una cuenta adecuada y configurar correctamente su contexto de seguridad.

---

## 11. Límite de tiempo de ejecución

Las tareas programadas tienen un parámetro denominado `ExecutionTimeLimit`.

Si no se modifica, el Programador de tareas utiliza de forma predeterminada un límite de **tres días**.

Podemos comprobar la configuración de una tarea:

```powershell
(Get-ScheduledTask -TaskName "PruebaTarea").Settings.ExecutionTimeLimit
```

Para un proceso diseñado expresamente para permanecer ejecutándose de forma continua, podemos eliminar ese límite:

```powershell
$Settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit ([TimeSpan]::Zero)

Set-ScheduledTask `
    -TaskName "PruebaTareaDesatendida" `
    -Settings $Settings
```

!!! warning
    Eliminar el límite de ejecución solo tiene sentido para procesos que hayan sido diseñados para permanecer activos durante largos periodos.

    En tareas de mantenimiento normales es preferible establecer un tiempo máximo razonable y detectar ejecuciones bloqueadas.

---

## 12. Diagnóstico y troubleshooting

Cuando una tarea no funciona, conviene revisar los elementos en este orden.

### 12.1. ¿Existe la tarea?

```powershell
Get-ScheduledTask -TaskName "PruebaTarea"
```

### 12.2. ¿Cuándo se ejecutó y qué resultado obtuvo?

```powershell
Get-ScheduledTaskInfo -TaskName "PruebaTarea"
```

### 12.3. ¿Funciona el script manualmente?

```powershell
C:\ASO\scripts\pruebatarea.ps1
```

### 12.4. ¿Es correcta la acción configurada?

```powershell
(Get-ScheduledTask -TaskName "PruebaTarea").Actions
```

### 12.5. ¿Es correcto el desencadenador?

```powershell
(Get-ScheduledTask -TaskName "PruebaTarea").Triggers
```

### 12.6. ¿Con qué usuario se ejecuta?

```powershell
(Get-ScheduledTask -TaskName "PruebaTarea").Principal
```

### 12.7. ¿Tiene acceso a las rutas utilizadas?

Una tarea programada puede ejecutarse correctamente de forma manual y fallar al ejecutarse de forma desatendida debido a:

- permisos insuficientes;
- rutas de red no disponibles;
- unidades de red mapeadas en una sesión interactiva;
- rutas relativas;
- perfiles o variables de entorno diferentes;
- credenciales incorrectas.

!!! tip "Utiliza rutas absolutas"
    En tareas programadas es recomendable utilizar rutas absolutas como:

    ```text
    C:\ASO\scripts\script.ps1
    ```

    y evitar depender del directorio actual o de unidades de red mapeadas.

---

## 13. Eliminación de una tarea

Para eliminar una tarea:

```powershell
Unregister-ScheduledTask `
    -TaskName "PruebaTarea" `
    -Confirm:$false
```

---

## 14. Actividad propuesta

Crea una tarea programada que cumpla los siguientes requisitos:

1. Ejecuta un script de PowerShell.
2. El script escribe la fecha y hora de ejecución en un fichero de registro.
3. La tarea se ejecuta cada dos minutos durante diez minutos.
4. Debe impedirse que se ejecuten simultáneamente dos instancias del script.
5. Debes provocar una ejecución manual para comprobar su funcionamiento.
6. Debes utilizar PowerShell para verificar:
   - la configuración de la tarea;
   - la última ejecución;
   - la siguiente ejecución;
   - el resultado de la última ejecución.

Como evidencia, muestra los comandos utilizados y el contenido final del fichero de registro.

---

## 📚 Referencias y Fuentes Consultadas

!!! info "Documentación Oficial y Autoría"
    * Material Base: Basado en la unidad temática empresarial "UD3. Fundamentos de administración de Windows Server - Programación de tareas" desarrollada por el Departamento de Informática del IES Marcos Zaragoza.
    * Diseño Curricular y Cátedra: José Ramón Soria Nieto.
    * Entorno Formativo: Módulo de Administración de Sistemas Operativos (ASO), correspondiente al Segundo Curso del Ciclo Formativo de Grado Superior en Administración de Sistemas Informáticos en Red (ASIR/ASIX).

!!! abstract "Soporte Institucional y Fondos Europeos"
    * Entidad Reguladora: Generalitat Valenciana — Conselleria d'Educació, Cultura i Esport.
    * Financiación Institucional: Proyecto cofinanciado por la Unión Europea a través del Fondo Social Europeo (FSE).
    * «El FSE invierte en tu futuro» — Acciones enfocadas en la optimización tecnológica, la formación técnica avanzada y el desarrollo de habilidades de automatización digital para infraestructuras informáticas en red.

### Documentación técnica

Para ampliar la información sobre la programación y administración de tareas automatizadas mediante PowerShell, puede consultarse la documentación oficial de Microsoft Learn:

* [ScheduledTasks — Módulo de PowerShell](https://learn.microsoft.com/powershell/module/scheduledtasks/)
* [New-ScheduledTaskAction](https://learn.microsoft.com/powershell/module/scheduledtasks/new-scheduledtaskaction)
* [New-ScheduledTaskTrigger](https://learn.microsoft.com/powershell/module/scheduledtasks/new-scheduledtasktrigger)
* [New-ScheduledTaskPrincipal](https://learn.microsoft.com/powershell/module/scheduledtasks/new-scheduledtaskprincipal)
* [New-ScheduledTaskSettingsSet](https://learn.microsoft.com/powershell/module/scheduledtasks/new-scheduledtasksettingsset)
* [Register-ScheduledTask](https://learn.microsoft.com/powershell/module/scheduledtasks/register-scheduledtask)
* [Get-ScheduledTask](https://learn.microsoft.com/powershell/module/scheduledtasks/get-scheduledtask)
* [Get-ScheduledTaskInfo](https://learn.microsoft.com/powershell/module/scheduledtasks/get-scheduledtaskinfo)
