
# Fundamentos de Administración de Proxmox VE

## 🎯 Relación con el Currículo (RA y CE)
La asimilación de los conceptos integrados en este bloque teórico-práctico permite verificar y evaluar el grado de consecución de los siguientes objetivos curriculares vinculados a la virtualización y la administración remota:

* **Resultado de Aprendizaje 8 (RA8):** Utiliza sistemas operativos en la nube (cloud) y los integra con sistemas locales. (Aplicado a nuestra infraestructura de nube privada on-premise).
    * *Criterios de evaluación vinculados:* CE1-RA8 (Crea sistemas virtualizados), CE2-RA8 (Instala y configura servicios en virtualización), CE3-RA8 (Monitoriza recursos).
* **Resultado de Aprendizaje 4 (RA4):** Administra de forma remota el sistema operativo en red valorando su importancia y aplicando criterios de seguridad.
    * *Criterios de evaluación vinculados:* CE1-RA4, CE3-RA4 y CE5-RA4 (Uso de interfaces web y CLI para acceso remoto al hipervisor).
* **Resultado de Aprendizaje 2 (RA2):** Administra procesos del sistema describiéndolos y aplicando criterios de seguridad y eficiencia.
    * *Criterios de evaluación vinculados:* CE6-RA2 (Control de recursos asignados a las MVs y contenedores).

## 🏢 Aspectos Clave en la Administración de Proxmox VE

La administración de un hipervisor de grado empresarial de Tipo 1 (Bare-Metal) como Proxmox VE es el pilar de nuestra infraestructura de aula. Al estar basado en Debian GNU/Linux, permite aunar la gestión de redes definidas por software (SDN), almacenamiento de alto rendimiento y virtualización híbrida en un único punto centralizado.

Basándonos en la arquitectura didáctica y los sprints de nuestro proyecto integrador, estructuramos estos principios fundamentales en tres grandes bloques operativos.

---

## 📑 Bloque I: Arquitectura y Modelos de Virtualización

### 1. Virtualización Completa (KVM - Kernel-based Virtual Machine)
Tecnología que convierte el kernel de Linux en un hipervisor, emulando el hardware físico de forma completa. Aísla totalmente el sistema operativo invitado.

- **Uso en nuestro proyecto:** Es la tecnología obligatoria para desplegar sistemas propietarios como Windows Server. Se utilizará en el **Sprint 1** para el Controlador de Dominio (`DC01`) y en el **Sprint 2** para el servidor de bases de datos (`SQLSERVER01`).
- **Consideraciones de Hardware:** Consume más recursos (sobrecarga de emulación). Requiere una asignación estricta de vCPUs y memoria RAM para no saturar los 32 GB disponibles en el nodo físico.
- **Tipo de CPU (Administración Real):** En producción, es vital cambiar el tipo de CPU emulada de `kvm64` (por defecto) a `Host` para que las MVs aprovechen las instrucciones avanzadas del procesador Intel Core i7-14700KF.

### 2. Virtualización por Contenedores (LXC - Linux Containers)
A diferencia de KVM, LXC no emula hardware. Comparte el kernel del sistema operativo del servidor Proxmox anfitrión (Debian), aislando procesos mediante *cgroups* y *namespaces*.

- **Uso en nuestro proyecto:** Despliegue de servicios eficientes basados en Linux, como el servidor Samba (**Sprint 4:** `FILESERVER` con Ubuntu Server 22.04).
- **Ventajas Operativas:** Arranque casi instantáneo (segundos) y un consumo residual de CPU y RAM, permitiendo consolidar múltiples servicios en un mismo servidor físico.

---

## ⚙️ Bloque II: Infraestructura (Redes y Almacenamiento)

### 3. Redes Definidas por Software (SDN) y Bridges
La conectividad en Proxmox se gestiona mediante *Linux Bridges* (puentes de red), que actúan como switches virtuales de Capa 2.

- **Puente por defecto (`vmbr0`):** En nuestros servidores, este puente conecta las interfaces virtuales de las máquinas (KVM/LXC) con la tarjeta de red física del Intel i7.
- **Interoperabilidad de Aula:** Permite que los portátiles físicos del alumnado (clientes con Windows 11 / i5) se comuniquen directamente mediante SSH (Linux) o WinRM (Windows) con los servidores virtualizados, como si estuvieran en el mismo switch físico.

### 4. Gestión del Almacenamiento Rápido (NVMe)
El aprovisionamiento de almacenamiento debe ser eficiente para evitar cuellos de botella en operaciones de entrada/salida (IOPS).

- **Estrategia en Proxmox:** El almacenamiento local de 1 TB NVMe se divide lógicamente (usando LVM-Thin o ZFS) para alojar los discos virtuales (`.qcow2` o volúmenes raw) y los rootfs de los contenedores LXC.
- **Aprovisionamiento Fino (Thin Provisioning):** Permite asignar discos virtuales más grandes que el espacio físico real, ya que solo se consume el espacio que realmente se escribe. Requiere monitorización constante para evitar llenar el disco físico al 100%.

---

## 💾 Bloque III: Monitorización, CLI y Automatización

### 5. Consola de Comandos (CLI) y Bash Scripting
Aunque la interfaz web (GUI) en el puerto `8006` es cómoda, la administración real y el troubleshooting a menudo requieren el uso de SSH contra el host físico de Proxmox.

- **Comandos KVM (`qm` - QEMU/KVM Virtual Machine Manager):**
    Gestión operativa de máquinas virtuales desde Bash.
    ```bash
    # Iniciar el Controlador de Dominio (Asumiendo que su ID es 100)
    qm start 100

    # Forzar el apagado si Windows Server sufre un BSOD o cuelgue severo
    qm stop 100

    # Monitorizar el estado y recursos consumidos
    qm status 100 --verbose
    ```

- **Comandos LXC (`pct` - Proxmox Container Toolkit):**
    Gestión de contenedores directamente desde el hipervisor.
    ```bash
    # Listar todos los contenedores en ejecución
    pct list

    # Ejecutar comandos directamente en el FILESERVER (ID 102) sin usar SSH
    pct exec 102 -- bash -c "systemctl status smbd"

    # Entrar a la consola root del contenedor para emergencias (Troubleshooting)
    pct enter 102
    ```

### 6. Monitorización y Telemetría Interna
Proxmox almacena la configuración de todo el clúster (o nodo standalone) en un sistema de archivos especial montado en memoria: `pmxcfs` (ubicado en `/etc/pve/`). Su monitorización es crítica para la integridad de las MVs.

---

## 🔍 Laboratorio de Desafíos y Troubleshooting (Entorno Proxmox)

### 💥 Caso Práctico: Saturación de Memoria (OOM Killer) por Overprovisioning

- **Síntoma:** Un equipo de trabajo informa que su máquina virtual `SQLSERVER01` y el `DC01` se apagan solos inesperadamente o desaparecen de la interfaz de Proxmox. La GUI de Proxmox se vuelve lenta.
- **Causa Raíz:** En nuestro entorno, cada servidor físico tiene **32 GB de RAM** compartida por 4 alumnos. Si cada alumno despliega varias MVs Windows Server (ej. 4 GB RAM cada una) sin coordinación, la suma total de RAM demandada supera la memoria física del nodo. Cuando Linux (Proxmox host) se queda sin RAM, invoca al proceso de emergencia **OOM Killer** (*Out of Memory Killer*), el cual sacrifica (mata) los procesos de QEMU/KVM que más memoria consumen para salvar el sistema anfitrión.
- **Solución Operativa en Clase:** 1. Acceder por SSH al servidor Proxmox.
    2. Verificar en los logs del kernel si el OOM Killer actuó sobre la MV afectada:
    ```bash
    # Filtrar los logs del sistema buscando intervenciones del OOM Killer
    dmesg -T | grep -i "out of memory"
    # O revisar los logs nativos de Proxmox
    journalctl -k | grep -i killed
    ```
    3. **Ajuste de Infraestructura:** El equipo debe aplicar límites estrictos. En Proxmox, deben configurar el **Memory Ballooning** en las opciones de Hardware de la MV (KVM) e instalar los controladores de *VirtIO* correspondientes dentro de Windows. Esto permite que el hipervisor reclame memoria RAM no utilizada de forma dinámica, optimizando los 32 GB del servidor para todo el equipo.

---

## 📚 Referencias y Fuentes Consultadas

!!! info "Documentación Oficial y Autoría"
    * **Material Base:** Basado en la arquitectura didáctica para la infraestructura de virtualización de las unidades del Departamento de Informática del **IES Marcos Zaragoza**.
    * **Autoría del Temario:** José Ramón.
    * **Marco Curricular:** Programación didáctica para el módulo de *Administración de Sistemas Operativos (ASO)* del Ciclo Formativo de Grado Superior en *Administración de Sistemas Informáticos en Red (ASIR/ASIX)*.
    * **Material adicional:** [Documentación Oficial de Proxmox VE (Wiki)](https://pve.proxmox.com/wiki/Main_Page).

!!! abstract "Cofinanciación y Soporte Institucional"
    * **Entidad Educativa:** Generalitat Valenciana — Conselleria d'Educació, Cultura i Esport.
    * **Fondo de Financiación:** Proyecto cofinanciado por la **Unión Europea** a través del **Fondo Social Europeo (FSE)**.
    * *«El FSE invierte en tu futuro»* — Acciones orientadas al impulso de la educación, formación avanzada y preparación para el mercado laboral técnico.