# Administración Avanzada de Proxmox VE

## 🎯 Relación con el Currículo (RA y CE)

La asimilación de los conceptos integrados en este bloque teórico-práctico permite verificar y evaluar el grado de consecución de los siguientes objetivos curriculares vinculados a las operaciones de mantenimiento, seguridad y optimización del entorno:

* **Resultado de Aprendizaje 3 (RA3):** Gestiona la automatización de tareas del sistema, aplicando criterios de eficiencia y utilizando comandos y herramientas gráficas.
    * *Criterios de evaluación vinculados:* CE1-RA3 (Planificación de tareas y backups automatizados) y CE2-RA3 (Estrategias de retención).
* **Resultado de Aprendizaje 8 (RA8):** Utiliza sistemas operativos en la nube (cloud) y los integra con sistemas locales.
    * *Criterios de evaluación vinculados:* CE3-RA8 (Monitoriza recursos y optimiza el rendimiento general del nodo).
* **Resultado de Aprendizaje 2 (RA2):** Administra procesos del sistema describiéndolos y aplicando criterios de seguridad y eficiencia.
    * *Criterios de evaluación vinculados:* CE6-RA2 (Control de cuotas y recuperación ante desastres).

## 🏢 Aspectos Clave en la Administración

Si la instalación es el "Día 0", la administración continua engloba las **Operaciones de Día 2 (*Day 2 Operations*)**. En nuestra infraestructura de aula, los equipos gestionan servicios críticos (Controladores de Dominio, Bases de Datos, Servidores de Archivos). Perder estos servidores por una mala configuración o un fallo de hardware supondría paralizar todo el proyecto integrador.

Desde la perspectiva de **ASO INNOVATEC**, la administración profesional de Proxmox se divide en tres bloques vitales: seguridad de datos (backups), agilidad en el despliegue (clones/templates) y auditoría constante de rendimiento.

---

## 📑 Bloque I: Estrategia de Copias de Seguridad y Recuperación

El subsistema nativo de respaldos de Proxmox (VZDump) es extremadamente potente y permite realizar copias completas tanto de máquinas virtuales (KVM) como de contenedores (LXC).

### 1. Tipos de Respaldo y Consistencia de Datos
No todos los backups son iguales. Al configurar un respaldo, debemos elegir el **Modo (*Mode*)** adecuado según la criticidad del sistema:
- **Snapshot (En vivo):** Se realiza la copia sin apagar el servidor. Proxmox congela las escrituras temporalmente y utiliza el *agente QEMU* para coordinarse con el VSS de Windows. Es ideal para el `DC01` si no queremos cortes de red, pero puede causar inconsistencias menores en bases de datos con transacciones pesadas.
- **Suspend (Pausa):** La máquina se congela momentáneamente mientras se copia la memoria y el estado actual.
- **Stop (Apagado):** La máquina se apaga de forma limpia, se hace el respaldo y vuelve a arrancar de forma automática. Proporciona la **máxima consistencia** de datos (obligatorio para respaldar grandes instancias como `SQLSERVER01` antes de un Sprint importante).

### 2. Programación (*Backup Jobs*) y Políticas de Retención
El administrador de sistemas no debe depender de hacer backups manuales. Estos se deben automatizar en la pestaña *Datacenter -> Backup*.
- **Planificación (Schedule):** Ejecutar respaldos en ventanas de mantenimiento (ej. viernes a las 23:00h).
- **Retención (Retention):** Configurar políticas para evitar saturar el almacenamiento físico. Una buena práctica en nuestro entorno es:
  - Mantener los últimos 3 backups diarios (`Keep Last: 3`).
  - Mantener 1 backup semanal (`Keep Weekly: 1`).
  - Mantener 1 backup mensual (`Keep Monthly: 1`).

---

## ⚙️ Bloque II: Snapshots, Plantillas y Clonación

Para agilizar el trabajo colaborativo en los Sprints y evitar tener que instalar Windows Server desde cero cada vez que hay un fallo, explotamos al máximo las herramientas de clonación del hipervisor.

### 3. El peligro de los Snapshots
- **¿Qué es?** Un Snapshot es una "fotografía" del estado exacto de la RAM y disco de una MV en un segundo concreto. Si un alumno va a instalar un nuevo rol peligroso en Windows Server y rompe el sistema, puede hacer un *Rollback* al Snapshot anterior en 2 segundos.
- **⚠️ Advertencia Técnica:** **Un Snapshot NO es un Backup.** Los snapshots se guardan de forma diferencial encadenada en el mismo disco NVMe físico. Si el disco físico falla, el snapshot desaparece. Además, dejar un snapshot abierto durante semanas degrada drásticamente el rendimiento de lectura/escritura (IOPS).

### 4. Plantillas (*Templates*) y Clonado Enlazado (*Linked Clones*)
Cuando un equipo termina de configurar una MV de Windows Server con su sistema limpio (*Sysprep*) y actualizado, debe convertirla en **Plantilla (*Convert to Template*)**. A partir de una plantilla, se pueden generar clones instantáneos:
- **Full Clone (Clon Completo):** Crea una copia idéntica e independiente. Tarda varios minutos y consume el 100% del espacio (ej. copiando los 32 GB del sistema).
- **Linked Clone (Clon Enlazado):** El nuevo clon solo guarda las diferencias (deltas) respecto a la plantilla de solo-lectura original. Se crea en menos de 1 segundo y apenas consume unos MBs de inicio. **Es la técnica obligatoria en el aula** para que 4 alumnos puedan levantar 4 Windows Servers sin agotar masivamente la capacidad NVMe del servidor físico.

---

## 💾 Bloque III: Monitorización, Telemetría y CLI

Un buen administrador debe anticiparse a las caídas del sistema monitorizando constantemente las gráficas de *Summary* en la GUI o la terminal de comandos.

### 5. Lectura Avanzada de Rendimiento
En nuestro Intel i7-14700KF de 32GB RAM, los indicadores críticos a vigilar son:
- **CPU Usage:** Un uso sostenido del 100% de la CPU anfitriona puede indicar un bucle infinito en una MV o escasez de recursos asignados a servicios críticos.
- **IO Delay (Retardo de Entrada/Salida):** Es el indicador de hardware más revelador. Mide el tiempo que la CPU debe esperar pasivamente a que el disco NVMe termine de escribir o leer. Si el IO Delay supera habitualmente el 5% - 10%, el bus del disco está colapsado por demasiadas MVs haciendo operaciones masivas simultáneas (ej. *Windows Updates* concurrentes).
- **SWAP:** Si el sistema físico empieza a usar el espacio de intercambio Swap, significa que la memoria física se ha agotado y el *OOM Killer* está a punto de matar instancias. Esto indica un claro fallo de sobreaprovisionamiento (*Overprovisioning*) en la RAM.

### 6. Auditoría y Logs por Consola (SSH)
Cuando la interfaz gráfica de Proxmox deja de cargar (Error 500) o un backup falla sin motivo aparente, debemos bajar al nivel de terminal (Debian OS):

```bash
# Ver los últimos 50 eventos del log del sistema en tiempo real para buscar cuelgues
journalctl -n 50 -f

# Seguir en vivo el log de tareas específicas de la interfaz web de Proxmox (pveproxy)
tail -f /var/log/syslog | grep pveproxy

# Mostrar el uso real de espacio ocupado y disponible de las particiones LVM y ZFS
df -h && lvs
```

---

## 🔍 Laboratorio de Desafíos y Troubleshooting (Entorno Proxmox)

### 💥 Caso Práctico: El Candado Maldito y la MV Bloqueada (Status: Locked)

- **Síntoma:** Durante el ecuador del proyecto, un grupo intenta encender o eliminar su base de datos `SQLSERVER01` (ID 103). Sin embargo, la interfaz de Proxmox rechaza la acción, muestra un icono de un candado cerrado superpuesto a la MV y lanza un error similar a: `CT/VM is locked (backup)`. La máquina no responde a ningún botón gráfico.
- **Causa Raíz:** Esto ocurre cuando una tarea automatizada pesada (como un Backup programado, creación de Snapshot o migración de almacenamiento) estaba bloqueando temporalmente el archivo de configuración de la máquina en el clúster (`pmxcfs`) para asegurar la consistencia. Si durante ese proceso el alumno apaga forzosamente el host físico, pierde la red, o el disco se queda sin espacio, el demonio de Proxmox "olvida" quitar el flag del candado de seguridad, dejando la máquina eternamente bloqueada.
- **Solución Operativa en Clase:** Ningún clic en la interfaz web lo solucionará; se requiere intervención del administrador (*Tier 3*) mediante SSH.
    1. **Auditoría de tareas fantasmas:** Entrar al host y comprobar si realmente hay un proceso enganchado en segundo plano ejecutándose:
       ```bash
       ps aux | grep vzdump
       ```
       *(Si existe un proceso zombi, debe matarse con `kill -9 PID` antes de continuar).*
    2. **Liberación manual del candado (Unlock):** Usar la utilidad gestora de KVM (`qm`) o LXC (`pct`) para eliminar a la fuerza el flag de bloqueo en el archivo de configuración del sistema virtual.
        ```bash
        # Desbloquear manualmente la Máquina Virtual KVM bloqueada con el ID 103
        qm unlock 103
        
        # En caso de que el sistema afectado fuera un Contenedor LXC (ej. ID 102)
        pct unlock 102
        ```
    3. Tras ejecutar el comando, el candado de la interfaz gráfica desaparecerá de inmediato y el equipo de alumnos recuperará el control total sobre su máquina.

---

## 📚 Referencias y Fuentes Consultadas

!!! info "Documentación Oficial y Autoría"
    * **Material Base:** Diseñado e implementado para la arquitectura didáctica de la infraestructura de virtualización de las unidades del Departamento de Informática del **IES Marcos Zaragoza**.
    * **Autoría del Temario:** José Ramón.
    * **Marco Curricular:** Programación didáctica para el módulo de *Administración de Sistemas Operativos (ASO)* del Ciclo Formativo de Grado Superior en *Administración de Sistemas Informáticos en Red (ASIR/ASIX)*.
    * **Material adicional:** [Documentación Oficial de Administración de Proxmox VE (Wiki)](https://pve.proxmox.com/pve-docs/pve-admin-guide.html).

!!! abstract "Cofinanciación y Soporte Institucional"
    * **Entidad Educativa:** Generalitat Valenciana — Conselleria d'Educació, Cultura i Esport.
    * **Fondo de Financiación:** Proyecto cofinanciado por la **Unión Europea** a través del **Fondo Social Europeo (FSE)**.
    * *«El FSE invierte en tu futuro»* — Acciones orientadas al impulso de la educación, formación avanzada y preparación para el mercado laboral técnico.
