# Instalación de Windows Server 2025 en Proxmox VE

## 🎯 Relación con el Currículo (RA y CE)
El despliegue e instalación del sistema operativo base en un entorno de virtualización corporativa da soporte técnico y sirve de base operativa para la consecución de los siguientes elementos del currículo oficial:

* **Resultado de Aprendizaje 1 (RA1):** Administra el servicio de directorio interpretando especificaciones e integrándolo en una red.
    * **CE3-RA1:** Se ha realizado la instalación del servicio de directorio en el servidor (fase de despliegue e instalación del S.O. huésped en modo Server Core).
    * **CE8-RA1:** Se ha realizado la configuración del cliente para su integración en el servicio de directorio (preparación del entorno de red virtualizada).
* **Resultado de Aprendizaje 2 (RA2):** Administra procesos del sistema describiéndolos y aplicando criterios de seguridad y eficiencia.
    * **CE7-RA2:** Se ha comprobado la secuencia de arranque del sistema, los procesos implicados y la relación entre ellos (interacción del núcleo con los drivers paravirtualizados VirtIO).
* **Resultado de Aprendizaje 9 (RA9):** Cumple con las exigencias laborales transversales relativas a autonomía, trabajo en equipo, organización y seguridad.
    * **CE4-RA9:** Ha entregado y estructurado el trabajo con una temporalización y organización adecuada (respeto a las cuotas de hardware asignadas al equipo en el host Proxmox).
---

## 🏢 Contexto: Despliegue virtualizado

En nuestro laboratorio, Windows Server 2025 no se instala sobre hardware físico, sino como **máquina virtual (MV)** dentro del hipervisor **Proxmox VE**. Este enfoque permite replicar entornos de producción, aislar servicios y recuperar rápidamente el sistema ante fallos.

Para obtener un rendimiento adecuado en entorno virtualizado, es imprescindible instalar los **drivers VirtIO** durante el despliegue. Estos drivers permiten que Windows reconozca el disco, la tarjeta de red y otros dispositivos paravirtualizados que Proxmox expone a la MV.

!!! info "Referencias oficiales"
    * [Windows 2025 guest best practices — Proxmox VE](https://pve.proxmox.com/wiki/Windows_2025_guest_best_practices)
    * [Windows VirtIO Drivers — Proxmox VE](https://pve.proxmox.com/wiki/Windows_VirtIO_Drivers)

---

## 🛠️ Fase I: Preparación de la máquina virtual

Antes de arrancar el instalador de Windows, configuramos la MV en Proxmox con los parámetros recomendados para Windows Server 2025.

### 1. Creación de la VM y sistema huésped

1. Creamos una **nueva VM** en Proxmox.
2. Seleccionamos **Microsoft Windows 11/2022/2025** como sistema huésped (*Guest OS*).
3. Montamos en el **CD/DVD** la ISO de los **drivers VirtIO** correspondientes.

### 2. Configuración del sistema (pestaña *System*)

* Habilitamos el **QEMU Guest Agent**.
* Almacenamos **EFI** y **TPM** en `local-lvm`.
* Seleccionamos **SCSI** como disco duro virtual y el controlador de disco **VirtIO SCSI single**.

### 3. Configuración del disco

* **Cache:** `Write back` (mejor rendimiento de E/S).
* **Discard:** activado (optimiza el espacio en disco mediante **TRIM**).
* **IO Thread** debe estar habilitado.
* **Bus:** SCSI.
* **Tamaño:** 32 GB.

### 4. Procesador

* **Tipo de CPU:** `x86-64-v2-AES`.
* **Cores:** 2.

### 5. Memoria

* Asignamos **4 GB** de RAM.

### 6. Red

* Conectamos la MV al bridge **`vmbr0`** (LAN interna del laboratorio).
* Seleccionamos **VirtIO (paravirtualized)** como dispositivo de red.

### 7. Confirmación

Revisamos el resumen de opciones y finalizamos la creación de la MV.

---

## 🎬 Vídeo demostración: creación de la MV en Proxmox

Vídeo complementario con todo el proceso paso a paso para configurar e instalar la máquina virtual destinada a Windows Server 2025.

<div class="video-embed">
  <iframe 
    src="https://www.youtube.com/embed/Em1CgkHPx4g" 
    title="Instalación de Windows Server 2025 en MV de Proxmox" 
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
    allowfullscreen>
  </iframe>
</div>

!!! info "Ver en YouTube"
    Si prefieres abrir el tutorial directamente en la plataforma o guardarlo en tus listas de reproducción, puedes acceder a través del siguiente enlace:  
    **[▶ Abrir vídeo directamente en YouTube](https://youtu.be/Em1CgkHPx4g)**


## 💿 Fase II: Instalación del sistema operativo

### Arranque del instalador

1. Iniciamos la MV recién creada.
2. Abrimos la consola **noVNC** desde la interfaz web de Proxmox.
3. Pulsamos una tecla cuando el instalador lo solicite para iniciar la instalación de **Windows Server 2025**.

### Opciones iniciales del instalador

* Elegimos **Instalar** y la opción para **borrar todo lo anterior** en el disco.
* Continuamos **sin clave de producto** (evaluación o activación posterior).
* Seleccionamos la edición **Windows Server Standard** en modo **Server Core** (sin escritorio gráfico).

!!! tip "Elección de edición"
    En entornos de producción y en nuestro laboratorio se prioriza **Server Core** por su menor superficie de ataque, menor consumo de recursos y mayor estabilidad. Ver [Fundamentos de Administración de Windows Server](fundamentos-core.md).

### Carga de drivers VirtIO

En la pantalla **Seleccionar ubicación para instalar Windows Server**, Windows no reconocerá el disco hasta que carguemos los drivers paravirtualizados. Pulsamos **Load Drivers** (*Cargar controladores*) y accedemos a la unidad de CD-ROM donde está montada la ISO de VirtIO.

Aunque podríamos instalar todos los drivers de Virtio para Windows Server, en este momento, únicamente instalaremos los **tres drivers** imprescindibles para un funcionamiento correcto, antes de continuar con la partición del disco:

| Dispositivo | Carpeta del driver | Controlador a seleccionar |
|-------------|-------------------|---------------------------|
| Disco duro (SCSI) | `vioscsi\w2k25\amd64` | Red Hat VirtIO SCSI pass-through controller |
| Tarjeta de red | `NetKVM\w2k25\amd64` | Red Hat VirtIO Ethernet Adapter |
| Memory Ballooning | `Balloon\w2k25\amd64` | VirtIO Balloon Driver |

!!! warning "Orden de carga"
    Tras instalar el driver del disco y ver el volumen disponible, **volvemos a la pantalla de selección de ubicación** y cargamos el resto de drivers (red y balloon) **antes** de iniciar la instalación en la partición principal.

### Finalización

1. Seleccionamos la partición principal del disco detectado.
2. Continuamos con la instalación estándar de Windows Server 2025.
3. Al finalizar, el sistema arrancará en modo **Server Core**, listo para la configuración posterior (red, hostname, unión al dominio, roles, etc.).

---

## 📋 Resumen de parámetros de la MV

| Recurso | Valor configurado |
|---------|-------------------|
| Guest OS | Microsoft Windows 11/2022/2025 |
| Guest Agent | Habilitado |
| EFI / TPM | `local-lvm` |
| Disco | VirtIO SCSI, 32 GB, Write back, Discard |
| CPU | x86-64-v2-AES, 2 cores |
| RAM | 4 GB |
| Red | `vmbr1`, VirtIO |
| Edición instalada | Windows Server Standard (Server Core) |

---

## 🎬 Vídeo demostración: Instalación de Windows Server 2025 en MV en Proxmox

Vídeo complementario con todo el proceso paso a paso para instalar Windows Server 2025 en la MV de Proxmox.

<div class="video-embed">
  <iframe 
    src="https://www.youtube.com/embed/pwgOY9BaH5c" 
    title="Instalación de Windows Server 2025 en MV de Proxmox" 
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
    allowfullscreen>
  </iframe>
</div>

!!! info "Ver en YouTube"
    Si prefieres abrir el tutorial directamente en la plataforma o guardarlo en tus listas de reproducción, puedes acceder a través del siguiente enlace:  
    **[▶ Abrir vídeo directamente en YouTube](https://youtu.be/pwgOY9BaH5c)**


## 🔗 Próximos pasos

Una vez completada la instalación, el ciclo de vida del servidor continúa con:

* Configuración de red e identificación del host.
* Instalación de actualizaciones y hardening inicial.
* Promoción a controlador de dominio o instalación de roles (AD DS, DNS, DHCP…).

Consulta [Fundamentos de Administración de Windows Server](fundamentos-core.md) para el marco conceptual del despliegue y la administración posterior.


## 📚 Referencias y Fuentes Consultadas

!!! info "Documentación Oficial y Autoría"
    * **Material Base:** [Instalar Windows Server 2025 en MV de Proxmox (PDF)](https://gvaedu-my.sharepoint.com/:b:/r/personal/jr_soria_edu_gva_es/Documents/MIS-APUNTES/ASO/GITHUB-AUX/Windows%20Server/instalacion-windows-server/Instalar-WServer2025-en-MV-Proxmox.pdf?csf=1&web=1&e=YCoWne)
    * **Autoría del Temario:** José Ramón Soria Nieto.
    * **Marco Curricular:** Programación didáctica para el módulo de *Administración de Sistemas Operativos (ASO)* del Ciclo Formativo de Grado Superior en *Administración de Sistemas Informáticos en Red (ASIR/ASIX)*.
    * **Material adicional:** [Windows Server learn oficial](https://learn.microsoft.com/es-es/windows-server/)

!!! abstract "Cofinanciación y Soporte Institucional"
    * **Entidad Educativa:** Generalitat Valenciana — Conselleria d'Educació, Cultura i Esport.
    * **Fondo de Financiación:** Proyecto cofinanciado por la **Unión Europea** a través del **Fondo Social Europeo (FSE)**. 
    * *«El FSE invierte en tu futuro»* — Acciones orientadas al impulso de la educación, formación avanzada y preparación para el mercado laboral técnico.