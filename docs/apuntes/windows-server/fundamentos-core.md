# Fundamentos de Administración de Windows Server

## 🎯 Relación con el Currículo (RA y CE)
* **Resultado de Aprendizaje 2 (RA2):** Gestiona la automatización de tareas del sistema, aplicando criterios de eficiencia y utilizando comandos y herramientas gráficas.
* **Resultado de Aprendizaje 3 (RA3):** Administra de forma remota el sistema operativo en red valorando su importancia y aplicando criterios de seguridad.

---

## 🏢 Fundamentos Clave en la administración de sistemas operativos de servidor

La administración de cualquier sistema operativo de servidor, y especialmente, de Windows Server, implica una serie de ámbitos de actuación clave que permiten mantener un entorno seguro, eficiente y bien organizado dentro de la infraestructura de red corporativa.



### 📑 Bloque I: Despliegue e Identidades

| Fundamento | Áreas de Operación | Tecnologías / Acciones Clave |
| :--- | :--- | :--- |
| **1. Instalación y Configuración inicial** | Despliegue de nodos del sistema | • Selección de la edición adecuada (**Standard**, **Datacenter**, etc).<br>• Configuración de roles y características (**Active Directory**, **DNS**, **DHCP**, etc).<br>• Priorización del modo **Server Core** para entornos de producción.<br>• Actualización del sistema y configuración de políticas de seguridad. |
| **2. Gestión de usuarios y grupos** | Centralización y control LDAP | • Uso de **Active Directory** para centralizar la administración de cuentas.<br>• Aplicación de políticas de grupo (**GPOs**) para controlar configuraciones de usuarios y equipos.<br>• Delegación de permisos y control de acceso basado en roles. |

---

### ⚙️ Bloque II: Servicios Esenciales y Seguridad

### 3. Administración de roles y servicios
Configuración y aprovisionamiento de los servicios de red esenciales para el soporte de los clientes:
* **DNS (Domain Name System):** Servicio crítico y obligatorio para la resolución de nombres de host dentro del dominio. Debe estar operativo antes de cualquier promoción.
* **DHCP (Dynamic Host Configuration Protocol):** Mecanismo de asignación automática de direcciones IP a los terminales de la subred.
* **File Server (Servidor de archivos):** Roles destinados a la compartición segura de archivos y recursos. *(Nota de proyecto: En nuestra arquitectura híbrida, este rol se delegará en un contenedor LXC con Ubuntu y Samba integrado en el AD).*
* **Web Server (IIS):** Entorno nativo de Microsoft para el alojamiento de sitios web y servicios de intranet.
* **Supervisión:** Control constante del estado de los servicios y del rendimiento general del sistema.

### 4. Seguridad y Control de Acceso
Aplicación de directivas de endurecimiento (*hardening*) del sistema operativo de red:
* Implementación de **firewalls** y reglas estrictas de filtrado de tráfico.
* Uso de **BitLocker** para el cifrado de volúmenes de disco, protegiendo los datos almacenados ante accesos físicos no autorizados.
* Auditoría activa de eventos y control de los registros de seguridad (*Logs*).
* Aplicación regular de actualizaciones y parches del sistema para corregir vulnerabilidades.

---

### 💾 Bloque III: Almacenamiento, Resiliencia y Virtualización

### 5. Administración de almacenamiento
* Configuración avanzada de discos, volúmenes y sistemas de archivos corporativos (NTFS / ReFS).
* Uso de **Storage Spaces** (Espacios de almacenamiento) y arreglos **RAID** para garantizar la redundancia y la tolerancia a fallos de hardware.
* Establecimiento de cuotas de disco por departamento y tareas de desduplicación de datos.

### 6. Virtualización
* Abstracción del hardware subyacente para maximizar el uso de los servidores físicos de la organización.
* Uso de soluciones nativas como **Hyper-V** o, en el caso de nuestro laboratorio de aula, el hipervisor de tipo 1 **Proxmox VE** para crear y administrar máquinas virtuales y contenedores aislados.
* Gestión de redes lógicas (Switches virtuales, VLANs) y almacenamiento virtualizado.
* Integración nativa con entornos híbridos o servicios de infraestructura en la nube.

### 7. Supervisión y mantenimiento
* Uso de herramientas nativas de diagnóstico del sistema: **Performance Monitor** (Contadores de rendimiento), **Event Viewer** (Visor de eventos) y **Task Scheduler** (Programador de tareas).
* Automatización de tareas administrativas recurrentes mediante scripts de PowerShell.
* Respaldo y recuperación de datos mediante **Windows Server Backup** o soluciones profesionales de terceros.

### 8. Alta disponibilidad y recuperación ante desastres
* Implementación de clústeres de conmutación por error (*Failover Clustering*) para servicios críticos que no pueden permitirse paradas.
* Replicación constante de datos y estado de servidores entre diferentes nodos geográficos.
* Diseño y simulacro de planes de recuperación rápida ante fallos catastróficos del sistema.

### 9. Administración remota
* Gestión a distancia prescindiendo de la consola física en el CPD, utilizando herramientas integradas: **PowerShell Remoting (WinRM)** y entornos web centralizados como **Windows Admin Center**.
* *(Nota sobre Server Core: Al carecer de entorno gráfico, el acceso por Escritorio Remoto - RDP se limita a la gestión de la consola de comandos subyacente).*
* Automatización de tareas masivas e infraestructura como código mediante el uso de scripts.
* Supervisión remota centralizada del estado de salud de los servidores y servicios de infraestructura.

---

## 🔍 Laboratorio de Desafíos y Troubleshooting (Entorno Proxmox)

### 💥 Caso Práctico: Bloqueo de hilos de disco por redundancia RAID mal aprovisionada
**Síntoma:** Durante el desarrollo del laboratorio de almacenamiento (Punto 5), al simular la pérdida de un disco virtualizado dentro de un pool de *Storage Spaces* o RAID, la máquina virtual del servidor entra en un estado de congelación (*Freeze*). Los comandos ejecutados vía PowerShell Remoting dejan de responder y el Visor de Eventos (*Event Viewer*) se llena de alertas críticas de tiempo de espera de E/S.

**Causa Raíz:** Incumplimiento del pilar nº 5 (Almacenamiento) y nº 6 (Virtualización). Al configurar los discos virtuales en el hipervisor sobre un almacenamiento NVMe físico compartido por varios alumnos, si se asignan tipos de aprovisionamiento fino (*Thin Provisioning*) sin controlar las cuotas físicas reales, las operaciones de sincronización y reconstrucción del RAID saturan el ancho de banda del bus de disco local, agotando los hilos de ejecución disponibles para el sistema operativo del Server Core.

**Solución Operativa en Clase:**
El alumno debe limitar el impacto de las operaciones de disco redimensionando los pools de almacenamiento y configurando discos virtuales con espacio reservado fijo (*Thick Provisioning*) para infraestructuras de servidores clave. Desde la CLI del hipervisor, audita el consumo de operaciones por segundo (IOPS) para verificar el cuello de botella:
```bash
# Monitorizar en tiempo real el rendimiento de lectura/escritura del disco de la MV en Proxmox
pvestatd parallel