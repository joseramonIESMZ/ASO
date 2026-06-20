# Implementación de Proxmox VE

## 🎯 Relación con el Currículo (RA y CE)

La asimilación de los conceptos integrados en este bloque teórico-práctico permite verificar y evaluar el grado de consecución de los siguientes objetivos curriculares vinculados a la instalación, configuración y despliegue del entorno de virtualización:

* **Resultado de Aprendizaje 8 (RA8):** Utiliza sistemas operativos en la nube (cloud) y los integra con sistemas locales. (Aplicado a nuestra infraestructura de nube privada on-premise).
    * *Criterios de evaluación vinculados:* CE1-RA8 (Instalación y parametrización de hipervisores), CE2-RA8 (Configuración de entornos virtuales y asignación de recursos).
* **Resultado de Aprendizaje 2 (RA2):** Administra procesos del sistema describiéndolos y aplicando criterios de seguridad y eficiencia.
    * *Criterios de evaluación vinculados:* CE5-RA2 (Instalación y actualización del software base del hipervisor bajo criterios de seguridad).
* **Resultado de Aprendizaje 4 (RA4):** Administra de forma remota el sistema operativo en red valorando su importancia y aplicando criterios de seguridad.
    * *Criterios de evaluación vinculados:* CE1-RA4 y CE3-RA4 (Configuración inicial de interfaces y accesos seguros al panel de administración y CLI).

## 🏢 Aspectos Clave en la Implementación

La implementación práctica de Proxmox VE en nuestra infraestructura de aula (Intel Core i7-14700KF, 32GB RAM, 1TB NVMe) es el paso crítico o "Día 0" (*Day 0 Operation*). Un hipervisor mal configurado desde la base heredará problemas de rendimiento a todas las máquinas virtuales de los Sprints posteriores. 

Basándonos en la metodología de **ASO INNOVATEC**, estructuramos este despliegue en tres grandes bloques operativos centrados en las mejores prácticas de la industria.

---

## 📑 Bloque I: Instalación Bare-Metal y Preparación del Host

### 1. Preparación de la BIOS/UEFI (Hardware Base)
Antes de insertar el USB de instalación, el administrador debe preparar la placa base del servidor para soportar entornos de virtualización anidados y paso a través de hardware:
- **Intel VT-x / VMX:** Habilitar la tecnología de virtualización principal. Obligatorio para ejecutar instancias KVM.
- **Intel VT-d (IOMMU):** Obligatorio si en el futuro se requiere hacer *PCI Passthrough* (asignar directamente una tarjeta de red o gráfica física a una MV).
- **Gestión de Energía:** Desactivar los estados "C-States" profundos si se busca el máximo rendimiento ininterrumpido en servidores de bases de datos.

### 2. Proceso de Instalación y Particionado
La instalación se realiza en la unidad **NVMe de 1TB**. Las decisiones tomadas aquí son irreversibles sin formatear:
- **Sistema de Archivos (Target Harddisk):** Seleccionaremos `ext4` sobre `LVM-Thin`. Esto nos permite hacer **Thin Provisioning** (aprovisionamiento fino). Si a una MV le damos un disco de 50GB pero solo usa 10GB, a nivel físico Proxmox solo reservará 10GB.
- **Parametrización de Red:**
    - **FQDN (Nombre de dominio cualificado):** Ej. `pve-aula.iesmarcoszaragoza.es`. No usar nombres cortos.
    - **IP Estática:** Fundamental. Proxmox no debe depender de un servidor DHCP externo para arrancar su interfaz de red. (Ej. `192.168.100.10/24`).

---

## ⚙️ Bloque II: Ajuste Fino Post-Instalación (CLI)

Una vez completada la instalación y accediendo vía SSH (o Consola Web local), debemos realizar el mantenimiento inicial. Proxmox, al ser de entorno empresarial, viene con repositorios de pago activados por defecto que darán error si no tenemos licencia.

### 3. Modificación de Repositorios (No-Subscription)
Para entornos académicos, usamos el repositorio comunitario. Lo haremos directamente automatizando desde la terminal de Bash del host:

```bash
# 1. Desactivamos el repositorio Enterprise (comentando la línea)
sed -i 's/^deb/#deb/' /etc/apt/sources.list.d/pve-enterprise.list

# 2. Añadimos el repositorio No-Subscription oficial
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" >> /etc/apt/sources.list

# 3. Desactivamos el repositorio de Ceph Enterprise (si no lo usamos en clase)
sed -i 's/^deb/#deb/' /etc/apt/sources.list.d/ceph.list
```

### 4. Actualización del Core
A continuación, sincronizamos repositorios y actualizamos el kernel y los paquetes base:

```bash
apt update && apt dist-upgrade -y
```

> **Nota de Administración:** Es vital usar `apt dist-upgrade` y no simplemente `apt upgrade`, ya que Proxmox necesita resolver dependencias complejas y actualizar el Kernel específico de virtualización (pve-kernel).

---

## 💾 Bloque III: Despliegue Estratégico de MVs y Contenedores

Cada Sprint del proyecto integrador exige una parametrización de hardware virtual distinta para evitar el temido *overprovisioning*.

### 5. Despliegue de KVM: Windows Server 2022/2025 (DC01 y SQLSERVER01)
Windows no se lleva bien con los entornos virtualizados por defecto. Requiere los drivers de paravirtualización **VirtIO** para no sufrir cuellos de botella masivos en disco y red.

**Configuración Óptima en Proxmox:**
- **OS / System:** Tipo `Microsoft Windows`. BIOS en modo **OVMF (UEFI)**. Añadir dispositivo **TPM 2.0** (obligatorio para Windows Server 2025). Máquina Q35.
- **Disks:** Bus/Device: **SCSI**. Habilitar **Discard** (para soportar comandos TRIM del SSD) e **IO thread** (procesamiento de disco asíncrono).
- **CPU:** Tipo de procesador: **Host**. Esto expone las instrucciones nativas del i7-14700KF (como AES-NI) a Windows, multiplicando el rendimiento de los servidores criptográficos del Directorio Activo.
- **Hardware Adicional:** Es **obligatorio** añadir una segunda unidad de CD/DVD virtual e insertar la ISO `virtio-win.iso`.

### 6. Despliegue de LXC: Ubuntu Server (FILESERVER)
Para el servidor Samba del **Sprint 4**, usamos contenedores por su extremada ligereza.
- **Plantilla:** Descargar `ubuntu-22.04-standard` desde la sección *CT Templates*.
- **Contenedor "Unprivileged":** Marcar siempre la casilla "Unprivileged container" por seguridad. Aisla al usuario `root` del contenedor del `root` del host físico, minimizando riesgos en caso de intrusión.
- **Almacenamiento Compartido (Bind Mounts):** En lugar de crear discos virtuales enormes, para un File Server es mucho más eficiente mapear una carpeta del host físico NVMe directamente dentro del contenedor.
  ```bash
  # Ejecutar en el host Proxmox para montar el directorio local de datos en el LXC (ej. ID 102)
  pct set 102 -mp0 /mnt/datos-departamento,mp=/COMPARTIDO
  ```

---

## 🔍 Laboratorio de Desafíos y Troubleshooting (Entorno Proxmox)

### 💥 Caso Práctico: Windows Server "Ciego" ante Discos VirtIO SCSI

- **Síntoma:** Durante el **Sprint 1**, un alumno inicia la instalación de Windows Server 2022 Core. Al llegar a la pantalla "¿Dónde desea instalar Windows?", la lista de discos aparece completamente en blanco. Abajo se lee la advertencia: *"No se encontró ninguna unidad. Para conseguir un controlador de almacenamiento, haz clic en Cargar controlador"*.
- **Causa Raíz:** El alumno ha configurado correctamente el disco virtual bajo el bus **VirtIO SCSI** (que ofrece un rendimiento superior). Sin embargo, la ISO oficial de Microsoft no incluye drivers nativos para la controladora open-source de QEMU/RedHat. Windows está "ciego" y no puede ver el disco duro virtual.
- **Solución Operativa en Clase:**
    1. **Aprovisionar Drivers (Host):** El alumno debe asegurarse de que en la pestaña Hardware de la MV existe un segundo lector de CD/DVD virtual que contiene la ISO de drivers oficiales (`virtio-win.iso`).
    2. **Inyección en Instalación (Guest):**
        - En el instalador de Windows, pulsar en **Cargar controlador** -> **Examinar**.
        - Seleccionar la unidad de CD `virtio-win`.
        - Navegar a la ruta exacta del driver SCSI: `vioscsi\2k22\amd64\` (Para Server 2022, 64 bits).
        - Aceptar. Tras la inyección, el disco de 32GB provisionado en Proxmox aparecerá mágicamente listo para ser particionado.
    3. **Post-Instalación (Red y Ballooning):** Una vez dentro de Windows instalado, el alumno notará que no hay red. Debe ejecutar el instalador general `virtio-win-gt-x64.msi` desde el CD para inyectar el driver de red (NetKVM) y el servicio de gestión dinámica de memoria (Ballooning service), cerrando así el proceso de optimización.

---

## 📚 Referencias y Fuentes Consultadas

!!! info "Documentación Oficial y Autoría"
    * **Material Base:** Diseñado e implementado para la arquitectura didáctica de la infraestructura de virtualización de las unidades del Departamento de Informática del **IES Marcos Zaragoza**.
    * **Autoría del Temario:** José Ramón.
    * **Marco Curricular:** Programación didáctica para el módulo de *Administración de Sistemas Operativos (ASO)* del Ciclo Formativo de Grado Superior en *Administración de Sistemas Informáticos en Red (ASIR/ASIX)*.
    * **Material adicional:** [Documentación Oficial de Instalación de Proxmox VE (Wiki)](https://pve.proxmox.com/pve-docs/pve-admin-guide.html).

!!! abstract "Cofinanciación y Soporte Institucional"
    * **Entidad Educativa:** Generalitat Valenciana — Conselleria d'Educació, Cultura i Esport.
    * **Fondo de Financiación:** Proyecto cofinanciado por la **Unión Europea** a través del **Fondo Social Europeo (FSE)**.
    * *«El FSE invierte en tu futuro»* — Acciones orientadas al impulso de la educación, formación avanzada y preparación para el mercado laboral técnico.
