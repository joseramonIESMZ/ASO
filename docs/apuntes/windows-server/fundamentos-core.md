# Fundamentos de Administración de Windows Server

## 🎯 Relación con el Currículo (RA y CE)
La asimilación de los conceptos integrados en este bloque teórico-práctico permite verificar y evaluar el grado de consecución de los siguientes objetivos curriculares:

* **Resultado de Aprendizaje 3 (RA3):** Gestiona la automatización de tareas del sistema, aplicando criterios de eficiencia y utilizando comandos y herramientas gráficas.
    * *Criterios de evaluación vinculados:* CE1-RA3, CE2-RA3 y CE3-RA3.
* **Resultado de Aprendizaje 4 (RA4):** Administra de forma remota el sistema operativo en red valorando su importancia y aplicando criterios de seguridad.
    * *Criterios de evaluación vinculados:* CE1-RA4, CE3-RA4 y CE5-RA4.
* **Resultado de Aprendizaje 1 (RA1) (Soporte Transversal):** Administra el servicio de directorio integrándolo en una red.
    * *Criterios de evaluación vinculados:* CE1-RA1 (Identificación de estructuras lógicas y funciones base).

## 🏢 Aspectos Clave en la Administración de Servidores

La administración de cualquier sistema operativo de servidor, y especialmente de Windows Server, implica una serie de ámbitos de actuación clave que permiten mantener un entorno seguro, eficiente y bien organizado dentro de la infraestructura de red corporativa.

Basándonos en la arquitectura didáctica de la especialidad, estructuramos estos principios fundamentales en tres grandes bloques operativos.

---

## 📑 Bloque I: Despliegue e Identidades

### 1. Instalación y Configuración Inicial
El ciclo de vida de cualquier infraestructura comienza con un despliegue optimizado y adaptado a las necesidades de cómputo de la organización.

- **Selección de la edición:** Elección fundamentada entre versiones (*Standard*, *Datacenter*, etc.), priorizando el uso de modos de instalación mínimos (**Server Core - Sin interfaz gráfica**) en entornos de producción.
- **Roles y características de infraestructura:** Aprovisionamiento base de servicios de red críticos como Active Directory Domain Services (AD DS), DNS y DHCP.
- **Hardening (endurecimiento) inicial:** Configuración de directivas de seguridad iniciales, cortafuegos y despliegue regular de parches.

### 2. Gestión de Usuarios y Grupos
La centralización de identidades es el pilar sobre el que descansa el control de accesos y la auditoría de la red empresarial.

- **Servicios de Directorio:** Uso de **Active Directory** para la administración centralizada de cuentas de usuario, equipos y objetos de red.
- **Políticas de Grupo (GPOs):** Control automatizado de las configuraciones de entorno de los usuarios y de las directivas de seguridad de las máquinas miembro.
- **Seguridad RBAC:** Delegación estructurada de permisos y control de acceso basado en roles.

---

## ⚙️ Bloque II: Servicios Esenciales y Seguridad

### 3. Administración de Roles y Servicios
Configuración y mantenimiento de los servicios de red esenciales para dar soporte y conectividad a los clientes de la organización:

- **DNS (Domain Name System):** Servicio crítico y obligatorio para la resolución de nombres de host dentro del dominio. Debe estar operativo antes de cualquier promoción.
- **DHCP (Dynamic Host Configuration Protocol):** Mecanismo de asignación automática y dinámica de direccionamiento IP a los terminales de la subred.
- **File Server (Servidor de archivos):** Roles destinados a la compartición segura de archivos. *(Nota de proyecto: En nuestra arquitectura híbrida, este rol se delega en un contenedor LXC con Ubuntu y Samba integrado en el AD).*
- **Web Server (IIS):** Entorno nativo de Microsoft para el alojamiento de sitios web y portales de intranet corporativos.
- **Supervisión analítica:** Control constante del estado de ejecución de los servicios y del rendimiento general del sistema.

### 4. Seguridad y Control de Acceso
Aplicación de directivas de endurecimiento del sistema operativo de red para mitigar vectores de ataque internos y externos:

- Implementación de **Firewalls** perimetrales y reglas estrictas de filtrado de tráfico.
- Uso de **BitLocker** para el cifrado de volúmenes de disco, protegiendo los datos almacenados ante sustracciones físicas de los soportes de almacenamiento.
- Auditoría activa de eventos mediante el control y centralización de los registros de seguridad (*Logs*).
- Aplicación calendarizada de actualizaciones y parches del sistema para mitigar vulnerabilidades críticas.

---

## 💾 Bloque III: Almacenamiento, Resiliencia y Virtualización

### 5. Administración de Almacenamiento
Diseño y aprovisionamiento eficiente de los recursos de disco físicos y lógicos de la organización:

- Configuración avanzada de discos, volúmenes y sistemas de archivos empresariales (**NTFS** / **ReFS**).
- Uso de **Storage Spaces** (Espacios de almacenamiento) y arreglos **RAID** para garantizar la redundancia y la tolerancia a fallos de hardware.
- Establecimiento de cuotas de espacio en disco por departamento y tareas de desduplicación de datos.

### 6. Virtualización
Abstracción del hardware físico para maximizar el rendimiento, aislamiento y consolidación de los servidores:

- Uso de soluciones nativas como **Hyper-V** para orquestar máquinas virtuales y contenedores aislados. No confundir con nuestro laboratorio de aula, donde el hipervisor de tipo 1 utilizado es **Proxmox VE**
- Gestión de redes lógicas (Switches virtuales, VLANs) y almacenamiento virtualizado compartido.
- Integración nativa con entornos híbridos o servicios de infraestructura en la nube.

### 7. Supervisión y Mantenimiento
Garantía de continuidad de los servicios de TI mediante la recolección de métricas analíticas y mantenimiento preventivo:

- Uso de herramientas nativas de diagnóstico del sistema: **Performance Monitor** (Contadores de rendimiento), **Event Viewer** (Visor de eventos) y **Task Scheduler** (Programador de tareas).
- Automatización de tareas administrativas recurrentes mediante scripts de PowerShell.
- Configuración de copias de seguridad mediante **Windows Server Backup** o soluciones profesionales de terceros.

### 8. Alta Disponibilidad y Recuperación ante Desastres
Estrategias tecnológicas orientadas a minimizar o eliminar el tiempo de inactividad de los servicios críticos:

- Implementación de clústeres de conmutación por error (**Failover Clustering**) para servicios de alta demanda.
- Replicación constante de datos y estado de servidores entre diferentes nodos geográficos.
- Diseño y simulacro de planes de contingencia para la recuperación rápida ante fallos catastróficos.

### 9. Administración Remota
La gestión moderna prescinde de la interacción física en la sala de servidores o terminales locales del CPD:

- Gestión a distancia utilizando herramientas integradas: **PowerShell Remoting (WinRM)** y entornos web centralizados como **Windows Admin Center**.
- *(Nota sobre Server Core: Al carecer de entorno gráfico, el acceso por Escritorio Remoto - RDP se limita a la gestión de la consola de comandos subyacente).*
- Automatización masiva e infraestructura como código (IaC) mediante el uso de scripts reutilizables.
- Supervisión remota centralizada del estado de salud de los servidores distribuidos.

---

## 🔍 Laboratorio de Desafíos y Troubleshooting (Entorno Proxmox)

### 💥 Caso Práctico: Bloqueo de hilos de disco por redundancia RAID mal aprovisionada

- **Síntoma:** Durante el desarrollo del laboratorio de almacenamiento (Punto 5), al simular la pérdida de un disco virtualizado dentro de un pool de *Storage Spaces* o RAID, la máquina virtual del servidor entra en un estado de congelación (*Freeze*). Los comandos ejecutados vía PowerShell Remoting dejan de responder y el Visor de Eventos (*Event Viewer*) se llena de alertas críticas de tiempo de espera de E/S.
- **Causa Raíz:** Incumplimiento del pilar nº 5 (Almacenamiento) y nº 6 (Virtualización). Al configurar los discos virtuales en el hipervisor sobre un almacenamiento NVMe físico compartido por varios alumnos, si se asignan tipos de aprovisionamiento fino (*Thin Provisioning*) sin controlar las cuotas físicas reales, las operaciones de sincronización y reconstrucción del RAID saturan el ancho de banda del bus de disco local, agotando los hilos de ejecución disponibles para el sistema operativo del Server Core.
- **Solución Operativa en Clase:** El alumno debe limitar el impacto de las operaciones de disco redimensionando los pools de almacenamiento y configurando discos virtuales con espacio reservado fijo (*Thick Provisioning*) para infraestructuras de servidores clave. Desde la CLI del hipervisor Proxmox, se debe auditar el consumo y latencia de operaciones por segundo (IOPS) para verificar el cuello de botella físico:

```bash
# Monitorizar en tiempo real el rendimiento extendido de lectura/escritura y latencia de los discos del host
iostat -xz 1
```

---

## 📚 Referencias y Fuentes Consultadas

!!! info "Documentación Oficial y Autoría"
    * **Material Base:** Basado en los contenidos de la unidad didáctica *[UD3. Fundamentos de administración de Windows Server](https://gvaedu-my.sharepoint.com/:b:/r/personal/jr_soria_edu_gva_es/Documents/MIS-APUNTES/ASO/GITHUB-AUX/Windows%20Server/Fundamentos-administracion/UD3.%20Fundamentos%20de%20administraci%C3%B3n%20de%20Windows%20Server.pdf?csf=1&web=1&e=xmL7aE)* del Departamento de Informática del **IES Marcos Zaragoza**.
    * **Autoría del Temario:** José Ramón Soria Nieto.
    * **Marco Curricular:** Programación didáctica para el módulo de *Administración de Sistemas Operativos (ASO)* del Ciclo Formativo de Grado Superior en *Administración de Sistemas Informáticos en Red (ASIR/ASIX)*.
    * **Material adicional:** [Windows Server learn oficial](https://learn.microsoft.com/es-es/windows-server/)

!!! abstract "Cofinanciación y Soporte Institucional"
    * **Entidad Educativa:** Generalitat Valenciana — Conselleria d'Educació, Cultura i Esport.
    * **Fondo de Financiación:** Proyecto cofinanciado por la **Unión Europea** a través del **Fondo Social Europeo (FSE)**. 
    * *«El FSE invierte en tu futuro»* — Acciones orientadas al impulso de la educación, formación avanzada y preparación para el mercado laboral técnico.