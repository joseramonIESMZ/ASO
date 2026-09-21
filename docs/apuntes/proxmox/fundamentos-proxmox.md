# Fundamentos de virtualización con Proxmox VE

## 🎯 Introducción

La **virtualización** permite ejecutar varios sistemas informáticos independientes utilizando un mismo servidor físico. Los recursos reales del equipo —procesador, memoria, almacenamiento y tarjetas de red— se abstraen y se presentan a los sistemas invitados como recursos virtuales.

En una infraestructura tradicional podríamos necesitar un servidor físico diferente para cada servicio: un servidor web, un servidor de bases de datos, un controlador de dominio, un servidor de ficheros, etc. Mediante virtualización, varios de estos sistemas pueden coexistir sobre una misma máquina física manteniendo un grado elevado de aislamiento entre ellos.

En este bloque utilizaremos **Proxmox Virtual Environment (Proxmox VE)** como plataforma de virtualización.

Proxmox VE permite trabajar principalmente con dos tecnologías:

* **KVM/QEMU**, utilizada para crear máquinas virtuales completas.
* **LXC**, utilizada para ejecutar contenedores Linux.

Además, integra en una misma plataforma la gestión del almacenamiento, las redes virtuales, usuarios y permisos, copias de seguridad, monitorización, clustering y automatización.

> **Objetivo**
>
> El objetivo de este tema no es aprender todavía todos los comandos o procedimientos de administración de Proxmox, sino comprender **qué estamos virtualizando, cómo funciona la infraestructura y qué decisiones debe tomar un administrador de sistemas antes de desplegarla**.

---

## 🧩 1. ¿Qué significa virtualizar?

Virtualizar consiste en crear una representación lógica de un recurso físico.

Podemos virtualizar diferentes elementos de una infraestructura:

* servidores;
* sistemas operativos;
* procesadores;
* memoria;
* discos;
* redes;
* aplicaciones;
* dispositivos.

En nuestro caso nos centraremos principalmente en la **virtualización de servidores**.

Supongamos un servidor físico con:

```text
CPU:             20 núcleos
RAM:             32 GiB
Almacenamiento:  1 TB NVMe
Red:             1 Gbit/s
```

Sobre ese servidor podríamos desplegar:

```text
Servidor físico
│
├── VM 100 · Windows Server
│   ├── 2 vCPU
│   ├── 4 GiB RAM
│   └── 64 GiB disco
│
├── VM 101 · Linux Server
│   ├── 2 vCPU
│   ├── 2 GiB RAM
│   └── 32 GiB disco
│
└── CT 102 · Ubuntu + Samba
    ├── 2 vCPU
    ├── 2 GiB RAM
    └── 32 GiB rootfs
```

Los tres sistemas utilizan el mismo hardware real, pero cada uno percibe un conjunto de recursos propio.

### 1.1. Ventajas de la virtualización

Entre sus ventajas encontramos:

* **Consolidación:** varios servidores lógicos utilizan un único servidor físico.
* **Aprovechamiento del hardware:** se reduce el número de equipos infrautilizados.
* **Aislamiento:** el fallo de un sistema invitado no debería afectar directamente a los demás.
* **Flexibilidad:** resulta sencillo crear, eliminar o modificar sistemas.
* **Portabilidad:** una máquina virtual puede trasladarse entre sistemas compatibles.
* **Automatización:** las operaciones pueden realizarse mediante CLI, API o herramientas de orquestación.
* **Recuperación:** snapshots y copias de seguridad facilitan determinados escenarios de recuperación.
* **Laboratorios:** es posible reproducir infraestructuras complejas utilizando pocos servidores físicos.

### 1.2. La virtualización no elimina las limitaciones físicas

La virtualización **no crea recursos físicos nuevos**.

Si el servidor dispone de 32 GiB de RAM, todas las máquinas virtuales, contenedores y procesos del propio hipervisor terminan compitiendo por esa memoria.

Lo mismo ocurre con:

* capacidad de CPU;
* espacio en disco;
* IOPS del almacenamiento;
* ancho de banda de red.

Por ello, uno de los trabajos fundamentales del administrador consiste en realizar un **dimensionamiento adecuado de los recursos**.

> ⚠️ **Importante**
>
> Virtualizar permite compartir los recursos de forma flexible, pero un mal dimensionamiento puede provocar que varias máquinas compitan entre sí y que disminuya el rendimiento de toda la infraestructura.

---

## 📑 Bloque I. Arquitectura de virtualización

## 2. Host, guest e hipervisor

Antes de trabajar con Proxmox debemos distinguir tres conceptos.

### Host

El **host** o anfitrión es el sistema físico que aporta los recursos reales:

* CPU;
* memoria RAM;
* almacenamiento;
* interfaces de red;
* dispositivos PCIe;
* etc.

En nuestro laboratorio, el servidor sobre el que instalamos Proxmox es el **host**.

### Guest

Un **guest** o invitado es uno de los sistemas ejecutados sobre el host.

Puede tratarse de:

* una máquina virtual;
* un contenedor.

Ejemplos:

```text
Host:
    Servidor Proxmox

Guests:
    Windows Server
    Ubuntu Server
    Debian
    contenedor Samba
    servidor web Linux
```

### Hipervisor

El **hipervisor** es la capa tecnológica que permite ejecutar y controlar las máquinas virtuales.

Se encarga, entre otras funciones, de proporcionar a cada VM:

* procesadores virtuales;
* memoria;
* discos virtuales;
* interfaces de red virtuales;
* otros dispositivos virtualizados.

---

## 3. Hipervisores de tipo 1 y tipo 2

Tradicionalmente se distinguen dos grandes modelos.

### Hipervisor de tipo 1

Se instala como plataforma de virtualización directamente sobre el servidor destinado a ejecutar las cargas.

Ejemplos habituales en entornos profesionales:

* Proxmox VE;
* VMware ESXi;
* Microsoft Hyper-V Server/Hyper-V;
* plataformas basadas en KVM.

Su objetivo principal es actuar como infraestructura de virtualización.

```text
+-----------------------------+
| VM 1 | VM 2 | VM 3 | ...   |
+-----------------------------+
| Hipervisor / plataforma     |
+-----------------------------+
| Hardware físico             |
+-----------------------------+
```

Proxmox VE se utiliza de esta manera en nuestro laboratorio.

### Hipervisor de tipo 2

Se ejecuta sobre un sistema operativo de propósito general ya instalado.

Ejemplos habituales:

* VirtualBox;
* VMware Workstation.

```text
+-----------------------------+
| VM 1 | VM 2                 |
+-----------------------------+
| Software de virtualización  |
+-----------------------------+
| Sistema operativo host      |
+-----------------------------+
| Hardware físico             |
+-----------------------------+
```

Son especialmente útiles para:

* estaciones de trabajo;
* desarrollo;
* pruebas;
* pequeños laboratorios personales.

### ¿Cuál es mejor?

No existe una respuesta universal.

Depende del objetivo.

Para un portátil de desarrollo puede resultar adecuado un hipervisor de escritorio. Para concentrar numerosos servidores y prestar servicios de infraestructura, normalmente utilizaremos una plataforma dedicada como Proxmox VE.

---

## 🏗️ Bloque II. Arquitectura de Proxmox VE

## 4. ¿Qué es Proxmox VE?

**Proxmox Virtual Environment** es una plataforma de virtualización de código abierto basada en GNU/Linux.

Integra dentro de un único entorno:

```text
                    Proxmox VE
                        │
       ┌────────────────┼────────────────┐
       │                │                │
     Cómputo           Red        Almacenamiento
       │                │                │
   ┌───┴────┐       Bridges          LVM-Thin
   │        │       VLAN              ZFS
  KVM      LXC      Firewall          NFS
   │        │       SDN               CIFS
  VM       CT                         Ceph
```

Junto a estas funciones encontramos:

* administración web;
* herramientas CLI;
* API REST;
* usuarios y permisos;
* snapshots;
* copias de seguridad;
* plantillas;
* monitorización;
* clústeres;
* migraciones;
* replicación;
* alta disponibilidad.

Por tanto, Proxmox no debe entenderse únicamente como «un programa para crear máquinas virtuales».

Es una **plataforma para administrar infraestructura virtualizada**.

---

## 5. Componentes fundamentales

De forma simplificada podemos representar un nodo Proxmox así:

```text
+------------------------------------------------+
|              Herramientas de gestión           |
|                                                |
|    Web GUI       CLI       REST API             |
+------------------------------------------------+
|              Servicios de Proxmox              |
|                                                |
| usuarios · storage · cluster · backup · red    |
+----------------------+-------------------------+
|      QEMU / KVM      |           LXC           |
|          VM          |      Contenedores       |
+----------------------+-------------------------+
|             Kernel Linux / Debian              |
+------------------------------------------------+
| CPU | RAM | NVMe/SSD | NIC | dispositivos PCI |
+------------------------------------------------+
```

Es importante comprender que la interfaz web **no es el hipervisor**.

Cerrar el navegador no apaga las máquinas virtuales.

La interfaz web es simplemente uno de los mecanismos disponibles para comunicarnos con los servicios de Proxmox.

---

## 🖥️ Bloque III. Máquinas virtuales con KVM/QEMU

## 6. Virtualización completa

Proxmox utiliza **KVM** junto con **QEMU** para ejecutar máquinas virtuales.

KVM aprovecha las extensiones de virtualización de los procesadores modernos, como:

* Intel VT-x;
* AMD-V.

QEMU proporciona gran parte de los dispositivos que forman el hardware virtual presentado al sistema invitado.

Desde el punto de vista del sistema operativo invitado, una VM se comporta de forma parecida a un ordenador independiente.

Puede disponer de:

```text
CPU virtual
RAM
BIOS o UEFI
discos
tarjeta de red
controladora SCSI
TPM virtual
CD/DVD virtual
USB
otros dispositivos
```

### 6.1. El sistema invitado posee su propio kernel

Esta es una característica fundamental.

Una VM Windows utiliza el kernel de Windows.

Una VM Ubuntu utiliza su propio kernel Linux.

Por tanto:

```text
Proxmox
│
├── VM Windows Server
│       └── Kernel Windows
│
├── VM Debian
│       └── Kernel Linux Debian
│
└── VM Ubuntu
        └── Kernel Linux Ubuntu
```

Esto permite ejecutar simultáneamente sistemas operativos diferentes.

---

## 7. vCPU

A una máquina virtual no asignamos directamente «núcleos físicos», sino **CPU virtuales o vCPU**.

Por ejemplo:

```text
Host:
20 núcleos físicos/lógicos disponibles

VM1:
2 vCPU

VM2:
4 vCPU

VM3:
2 vCPU
```

La suma de vCPU asignadas puede superar en determinados escenarios el número de CPU físicas disponibles. Esto se denomina **overcommit** o sobreaprovisionamiento.

No significa que hayamos creado capacidad de proceso adicional.

Simplemente asumimos que todas las máquinas no utilizarán simultáneamente el 100 % de su CPU.

### Sobreaprovisionamiento razonable

```text
Muchas VM
      ↓
2 vCPU cada una
      ↓
Normalmente consumen poco
      ↓
El planificador reparte CPU
```

### Sobreaprovisionamiento excesivo

```text
Muchas VM
      ↓
Todas requieren CPU
      ↓
Contención
      ↓
Mayor latencia
      ↓
Peor rendimiento
```

Por tanto:

> **Asignar más vCPU no garantiza que una máquina virtual funcione más rápido.**

Un administrador debe dimensionar según la carga real.

---

## 8. Modelo de CPU

Proxmox puede presentar a una VM diferentes modelos de procesador virtual.

Una posibilidad es exponer características muy cercanas a la CPU física del host mediante un modelo equivalente a `host`.

Esto puede proporcionar acceso a más instrucciones del procesador real, pero introduce una consideración importante:

> Una configuración muy ligada al procesador físico puede dificultar la migración de la VM hacia un nodo con una CPU diferente.

Por ello, la elección del modelo de CPU es una **decisión de arquitectura**.

Debemos valorar:

* rendimiento;
* instrucciones requeridas;
* homogeneidad de los nodos;
* necesidad de migración;
* compatibilidad.

---

## 9. Memoria de una máquina virtual

Cada VM puede recibir una cantidad determinada de RAM.

Ejemplo:

```text
DC01          4 GiB
SQL01         6 GiB
WEB01         2 GiB
LINUX01       2 GiB
```

La memoria física sigue perteneciendo al host.

Si la suma de necesidades reales supera ampliamente la memoria disponible puede producirse presión de memoria y degradarse todo el nodo.

Proxmox puede utilizar mecanismos como **memory ballooning** en determinados invitados para modificar de forma dinámica la memoria disponible para una VM, siempre que el sistema invitado y sus controladores lo soporten adecuadamente.

El ballooning ayuda a gestionar memoria.

**No sustituye a un buen dimensionamiento.**

---

## 📦 Bloque IV. Contenedores LXC

## 10. Virtualización a nivel de sistema operativo

Un contenedor LXC funciona de forma diferente a una VM.

Los contenedores **comparten el kernel Linux del host**.

```text
              Host Proxmox
                   │
               Kernel Linux
        ┌──────────┼──────────┐
        │          │          │
     CT 100      CT 101     CT 102
     Debian      Ubuntu     Debian
```

El aislamiento se consigue utilizando mecanismos del kernel Linux como:

* namespaces;
* cgroups;
* capacidades;
* aislamiento de sistemas de archivos.

El contenedor percibe su propio entorno de:

* procesos;
* usuarios;
* red;
* sistema de archivos;
* recursos.

Pero no posee un kernel completamente independiente.

---

## 11. VM frente a LXC

Esta es una de las decisiones más importantes al diseñar una infraestructura Proxmox.

| Característica           | Máquina virtual KVM | Contenedor LXC              |
| ------------------------ | ------------------- | --------------------------- |
| Kernel propio            | Sí                  | No                          |
| Comparte kernel con host | No                  | Sí                          |
| Windows                  | Sí                  | No                          |
| Linux                    | Sí                  | Sí                          |
| Aislamiento              | Muy elevado         | A nivel de SO               |
| Consumo de recursos      | Mayor               | Menor                       |
| Tiempo de arranque       | Normalmente mayor   | Normalmente muy reducido    |
| Flexibilidad del kernel  | Alta                | Limitada al kernel del host |
| Densidad de servicios    | Menor               | Mayor                       |

### Ejemplo 1. Windows Server

Necesitamos instalar:

```text
Windows Server
```

Debe utilizarse una:

```text
Máquina virtual KVM
```

porque Windows necesita ejecutar su propio kernel.

### Ejemplo 2. Servidor Samba Linux

Queremos desplegar:

```text
Ubuntu
+
Samba
```

y no necesitamos modificar el kernel.

Un contenedor LXC puede ser una solución muy eficiente.

### Ejemplo 3. Laboratorio de kernels

Queremos probar una versión concreta de un kernel Linux.

Necesitamos una:

```text
VM
```

porque un contenedor utiliza el kernel del host.

---

## 12. Contenedores privilegiados y no privilegiados

LXC permite utilizar distintos modelos de aislamiento.

Un concepto especialmente importante es el de **contenedor no privilegiado**.

En él, los identificadores de usuario del contenedor se mapean a identificadores diferentes en el host.

Simplificando:

```text
Dentro del contenedor
root = UID 0

        ↓ mapeo ↓

En el host
UID diferente sin privilegios de root
```

Esto reduce el impacto potencial de determinados problemas de seguridad.

Como criterio general, siempre que el servicio lo permita, resulta preferible utilizar **contenedores no privilegiados**.

Algunas aplicaciones o configuraciones especiales pueden necesitar capacidades adicionales, por lo que la elección debe justificarse técnicamente.

---

## 🌐 Bloque V. Virtualización de red

## 13. El problema de la conectividad

Crear una VM no sirve de mucho si no podemos comunicarla.

Cada máquina virtual necesita una interfaz de red virtual.

En una VM KVM aparece normalmente una interfaz virtual que Proxmox conecta a un **bridge Linux**.

Podemos imaginar un bridge como un switch virtual.

```text
                 vmbr0
            Switch virtual
          ┌──────┼──────┐
          │      │      │
        VM100  VM101   CT102
          │
          │
       NIC física
          │
     Red del centro
```

---

## 14. Linux Bridge

Un bridge permite conectar entre sí interfaces de red en capa 2.

En muchas instalaciones encontramos un bridge denominado:

```text
vmbr0
```

La idea fundamental es:

```text
NIC física ── vmbr0 ── interfaces virtuales
```

De esta manera, una VM puede aparecer en la red física como otro equipo más.

Un bridge puede disponer o no de una interfaz física asociada.

Esto permite crear también redes completamente internas:

```text
vmbr1
│
├── VM1
├── VM2
└── VM3

sin salida directa a la red física
```

Esta característica resulta especialmente útil en laboratorios.

---

## 15. VLAN

Una **VLAN** permite crear varias redes lógicas utilizando una misma infraestructura física.

Por ejemplo:

```text
VLAN 10 → Gestión
VLAN 20 → Servidores
VLAN 30 → Clientes
VLAN 40 → DMZ
```

Las VLAN permiten trabajar conceptos muy importantes para ASIR:

* segmentación;
* aislamiento;
* routing;
* seguridad;
* diseño de redes empresariales.

Proxmox puede transportar y gestionar tráfico etiquetado mediante VLAN en sus interfaces y bridges.

Más adelante podremos construir una topología como:

```text
             Proxmox
                │
         Bridge VLAN-aware
       ┌────────┼────────┐
       │        │        │
    VLAN 10  VLAN 20  VLAN 30
       │        │        │
   Gestión  Servidores Clientes
```

---

## 16. SDN

Proxmox también incorpora funciones de **Software Defined Networking (SDN)**.

El objetivo de una red definida por software es desacoplar progresivamente la configuración lógica de red de la infraestructura física.

Permite definir conceptos como:

* zonas;
* redes virtuales;
* subredes;
* VNets;
* mecanismos de aislamiento.

En esta unidad únicamente necesitamos comprender la idea.

La configuración de topologías, VLAN y SDN se desarrollará posteriormente.

---

## 💾 Bloque VI. Virtualización del almacenamiento

## 17. Almacenamiento físico y almacenamiento virtual

Una máquina virtual necesita discos, pero estos no tienen por qué corresponderse directamente con discos físicos independientes.

Por ejemplo:

```text
NVMe físico 1 TB
        │
        └── almacenamiento Proxmox
                │
                ├── Disco VM100
                ├── Disco VM101
                ├── Disco VM102
                └── rootfs CT103
```

Proxmox introduce una capa de abstracción entre:

```text
almacenamiento físico
```

y:

```text
almacenamiento utilizado por VM y CT
```

---

## 18. Backends de almacenamiento

Proxmox admite diferentes tecnologías de almacenamiento.

Entre las que encontraremos con mayor frecuencia están:

* directorios sobre sistemas de archivos;
* LVM;
* LVM-Thin;
* ZFS;
* NFS;
* CIFS/SMB;
* iSCSI;
* Ceph.

No todas tienen las mismas características.

Debemos analizar aspectos como:

* rendimiento;
* snapshots;
* thin provisioning;
* redundancia;
* almacenamiento compartido;
* migración;
* replicación;
* facilidad de recuperación.

---

## 19. Thin provisioning

Con **thin provisioning** el espacio lógico asignado a los sistemas invitados puede superar inicialmente el espacio físico realmente ocupado.

Ejemplo:

```text
Almacenamiento físico:
500 GB

Discos virtuales definidos:
VM1 → 200 GB
VM2 → 200 GB
VM3 → 200 GB

Total lógico:
600 GB
```

Esto puede funcionar mientras el espacio realmente escrito sea inferior a la capacidad disponible.

Sin embargo:

```text
Espacio físico lleno
        ↓
fallos de escritura
        ↓
problemas en VM y servicios
```

Por tanto, thin provisioning requiere **monitorización**.

> ⚠️ **Asignar espacio virtual no equivale a disponer físicamente de ese espacio.**

---

## 20. RAW y QCOW2

Dependiendo del backend utilizado, Proxmox puede almacenar discos virtuales mediante distintos formatos o volúmenes.

Dos conceptos que aparecerán frecuentemente son:

* `raw`;
* `qcow2`.

No debemos concluir que uno es siempre mejor.

La elección depende de:

* backend de almacenamiento;
* prestaciones necesarias;
* snapshots;
* rendimiento;
* organización del almacenamiento.

Por ejemplo, un almacenamiento basado en LVM-Thin no gestiona los discos exactamente del mismo modo que un directorio basado en un sistema de archivos.

Por ello, antes de hablar del «archivo de una máquina virtual» debemos identificar **qué almacenamiento estamos utilizando**.

---

## ⚙️ Bloque VII. Gestión de Proxmox

## 21. Tres formas de administrar la plataforma

Proxmox puede administrarse principalmente mediante:

```text
GUI web
   │
CLI
   │
API REST
```

Las tres actúan sobre la misma infraestructura.

### Interfaz web

Facilita:

* visualización;
* configuración inicial;
* consulta de métricas;
* realización de operaciones;
* revisión de tareas y eventos.

Normalmente se accede al servicio web seguro proporcionado por Proxmox.

### Línea de comandos

Permite administrar el sistema desde una shell Linux.

Algunas herramientas importantes son:

```bash
qm
pct
pvesm
pvecm
pveum
pvesh
```

De forma orientativa:

| Herramienta | Función                                |
| ----------- | -------------------------------------- |
| `qm`        | Máquinas virtuales QEMU/KVM            |
| `pct`       | Contenedores LXC                       |
| `pvesm`     | Almacenamiento                         |
| `pvecm`     | Clúster                                |
| `pveum`     | Usuarios y permisos                    |
| `pvesh`     | Acceso desde shell a la API de Proxmox |

Podemos realizar consultas sencillas:

```bash
qm list
```

```bash
pct list
```

```bash
pvesm status
```

Todavía no es necesario memorizar estos comandos.

Lo importante es entender que la GUI **no es el único método de administración**.

### API

Proxmox dispone de una API que permite automatizar gran parte de las operaciones disponibles en la plataforma.

Esto abre la puerta a:

* scripts;
* automatización;
* infraestructura como código;
* integración con otras herramientas;
* aprovisionamiento automático.

---

## 🆔 Bloque VIII. Organización de los recursos

## 22. VMID

Cada máquina virtual o contenedor dispone de un identificador numérico denominado habitualmente **VMID**.

Ejemplo:

```text
100 → DC01
101 → SQL01
102 → FILESERVER
103 → WEB01
```

El identificador es especialmente importante porque muchas operaciones de administración utilizan directamente el VMID.

Ejemplo:

```bash
qm start 100
```

indicaría que queremos iniciar la máquina virtual identificada como `100`.

Por ello conviene adoptar una política ordenada de identificadores.

---

## 23. Nombres

El nombre de la máquina y su VMID son conceptos diferentes.

Por ejemplo:

```text
VMID:     100
Nombre:   dc01
FQDN:     dc01.int.empresa.test
IP:       192.168.20.10
```

En una infraestructura real deberíamos documentar, como mínimo:

| VMID | Nombre     | Tipo | Servicio   | CPU |   RAM |   Disco | Red        |
| ---- | ---------- | ---- | ---------- | --: | ----: | ------: | ---------- |
| 100  | dc01       | VM   | AD DS/DNS  |   2 | 4 GiB |  64 GiB | SERVIDORES |
| 101  | sql01      | VM   | SQL Server |   4 | 6 GiB | 100 GiB | SERVIDORES |
| 102  | fileserver | LXC  | Samba      |   2 | 2 GiB |  32 GiB | SERVIDORES |

La documentación de la infraestructura forma parte del trabajo del administrador.

---

## 📸 Bloque IX. Snapshot, copia de seguridad y plantilla

## 24. Snapshot

Un **snapshot** registra un estado determinado de un sistema virtualizado utilizando mecanismos proporcionados por el almacenamiento y la plataforma.

Resulta útil antes de determinados cambios:

```text
Estado correcto
      │
   snapshot
      │
 actualización
      │
 problema
      │
 posible rollback
```

Pero:

> **Un snapshot no debe considerarse por sí solo una estrategia de backup.**

Si perdemos el almacenamiento físico que contiene tanto la máquina como sus snapshots, podemos perder ambas cosas.

---

## 25. Backup

Una **copia de seguridad** pretende permitir la recuperación de los datos o sistemas frente a una pérdida.

Idealmente se almacena de forma independiente respecto del sistema protegido.

Conceptualmente:

```text
Snapshot
    ↓
punto de estado cercano a la VM

Backup
    ↓
copia diseñada para recuperación
```

Ambos mecanismos tienen objetivos relacionados, pero no idénticos.

---

## 26. Plantillas y clonación

Una **plantilla** permite preparar un sistema base para desplegar posteriormente nuevas máquinas de manera rápida y homogénea.

Por ejemplo:

```text
Ubuntu-template
       │
       ├── web01
       ├── web02
       ├── monitor01
       └── dns02
```

Esto permite:

* ahorrar tiempo;
* estandarizar configuraciones;
* reducir errores;
* automatizar despliegues.

En entornos más avanzados podremos combinar plantillas con tecnologías como **cloud-init**.

---

## 🏢 Bloque X. Nodo, clúster y alta disponibilidad

## 27. Nodo

Cada servidor físico con Proxmox instalado constituye un **nodo**.

Nuestro laboratorio puede comenzar perfectamente con:

```text
1 servidor físico
       ↓
1 nodo Proxmox
```

Sobre él podemos estudiar la mayor parte de los conceptos básicos:

* VM;
* LXC;
* almacenamiento;
* bridges;
* VLAN;
* snapshots;
* backups;
* automatización.

---

## 28. Clúster

Varios nodos Proxmox pueden agruparse formando un **clúster**.

```text
              Cluster Proxmox
                    │
       ┌────────────┼────────────┐
       │            │            │
     Nodo 1       Nodo 2       Nodo 3
       │            │            │
      VM           VM           CT
```

Un clúster facilita la administración conjunta de los nodos y habilita funcionalidades adicionales.

Proxmox utiliza componentes como **Corosync** para la comunicación y coordinación del clúster.

---

## 29. pmxcfs

Proxmox dispone de un sistema especial denominado **Proxmox Cluster File System (****`pmxcfs`****)**.

Expone configuraciones importantes en:

```text
/etc/pve/
```

En un clúster, estas configuraciones pueden sincronizarse entre los nodos.

Por eso `/etc/pve` no debe tratarse exactamente como un directorio Linux convencional.

Entre la información gestionada encontramos configuraciones relacionadas con:

* nodos;
* máquinas virtuales;
* contenedores;
* almacenamiento;
* usuarios;
* clúster.

---

## 30. Quorum

En sistemas distribuidos necesitamos evitar que diferentes partes del clúster actúen simultáneamente creyendo ser la parte válida.

Para ello aparece el concepto de **quorum**.

Simplificando:

> Un conjunto suficiente de nodos debe estar de acuerdo para que determinadas operaciones del clúster sean consideradas seguras.

Este concepto cobra especial importancia cuando aparecen:

* fallos de nodos;
* fallos de comunicaciones;
* particiones de red.

Se estudiará con mayor profundidad al trabajar clustering.

---

## 31. Clúster no significa alta disponibilidad

Es importante no confundir:

```text
CLUSTER
```

con:

```text
ALTA DISPONIBILIDAD
```

Un clúster permite agrupar y coordinar nodos.

La **alta disponibilidad (HA)** añade mecanismos para intentar mantener determinadas cargas disponibles cuando se produce el fallo de un nodo.

Por tanto:

```text
Varias VM en un nodo
        ≠
Alta disponibilidad

Varios nodos en un clúster
        ≠
Alta disponibilidad automática
```

La disponibilidad requiere además estudiar:

* almacenamiento;
* quorum;
* red;
* configuración HA;
* capacidad restante;
* recuperación de servicios.

---

## 🔐 Bloque XI. Seguridad y administración

## 32. Usuarios, roles y permisos

No todos los administradores deberían disponer de los mismos privilegios.

Proxmox permite aplicar control de acceso basado en roles.

Conceptualmente:

```text
Usuario
   +
Rol
   +
Objeto o ruta
   =
Permiso
```

Por ejemplo:

```text
Alumno A
    ↓
Administrar únicamente
    ↓
VM 100 y VM 101
```

mientras que un administrador del sistema puede gestionar todo el nodo.

Esto introduce conceptos profesionales como:

* mínimo privilegio;
* separación de funciones;
* delegación administrativa;
* auditoría.

---

## 33. Interfaces de administración

En una instalación Proxmox pueden coexistir distintos mecanismos de acceso:

* interfaz web;
* SSH;
* CLI local;
* API;
* tokens de API.

Cada uno requiere aplicar medidas de seguridad.

Entre las buenas prácticas generales se encuentran:

* utilizar credenciales individuales;
* limitar privilegios;
* evitar compartir contraseñas;
* aplicar autenticación multifactor cuando proceda;
* proteger la red de gestión;
* mantener actualizado el sistema;
* revisar logs y tareas;
* utilizar tokens específicos para automatización.

---

## 📊 Bloque XII. Dimensionamiento

## 34. El recurso más importante no siempre es la CPU

Un error habitual al diseñar un servidor de virtualización consiste en fijarse únicamente en el número de núcleos.

En realidad debemos dimensionar conjuntamente:

```text
CPU
RAM
almacenamiento
IOPS
red
```

Una infraestructura puede disponer de CPU libre y, sin embargo, funcionar lentamente porque el almacenamiento está saturado.

También puede disponer de disco libre, pero carecer de RAM suficiente.

---

## 35. Capacidad frente a rendimiento

No debemos confundir:

```text
capacidad
```

con:

```text
rendimiento
```

Ejemplo:

Un disco puede disponer de:

```text
500 GB libres
```

pero estar atendiendo tantas operaciones simultáneas que la latencia resulte demasiado elevada.

Por tanto, en almacenamiento interesan también indicadores como:

* IOPS;
* latencia;
* throughput.

La administración profesional requiere observar **cómo se utilizan los recursos**, no simplemente cuánto espacio queda disponible.

---

## 36. El problema del overprovisioning

Supongamos un host con:

```text
32 GiB RAM
```

y las siguientes VM:

```text
VM1 → 8 GiB
VM2 → 8 GiB
VM3 → 8 GiB
VM4 → 8 GiB
VM5 → 8 GiB
```

Hemos definido:

```text
40 GiB
```

de memoria para invitados sobre un host con solo:

```text
32 GiB
```

Esto no significa necesariamente que el problema sea inmediato, porque la utilización real puede ser inferior.

Pero introduce un riesgo.

Si todos los sistemas demandan simultáneamente gran cantidad de memoria, el host puede sufrir una situación crítica de presión de memoria.

En casos extremos el kernel Linux puede activar mecanismos como el **OOM Killer** para recuperar memoria finalizando procesos.

Entre esos procesos podrían encontrarse los correspondientes a máquinas virtuales.

---

## 🔍 Laboratorio de razonamiento

## 37. ¿VM o contenedor?

Para cada uno de los siguientes casos, decide qué tecnología utilizarías.

### Caso A

Necesitamos ejecutar Windows Server.

**Respuesta razonada:**

Máquina virtual KVM, ya que Windows necesita utilizar su propio kernel.

---

### Caso B

Queremos publicar una pequeña aplicación web sobre Debian consumiendo el mínimo de recursos posible.

**Posible solución:**

LXC.

Un contenedor puede proporcionar aislamiento suficiente con un consumo de recursos reducido.

La decisión definitiva dependerá de los requisitos de seguridad y aislamiento de la aplicación.

---

### Caso C

Necesitamos experimentar con diferentes kernels Linux.

**Respuesta razonada:**

Máquinas virtuales.

Los contenedores comparten el kernel del host y, por tanto, no proporcionan el aislamiento de kernel necesario para este laboratorio.

---

### Caso D

Queremos garantizar que un servicio continúe funcionando aunque se apague nuestro único servidor físico.

**Respuesta:**

Elegir entre VM y LXC **no resuelve el problema**.

Si solo disponemos de un nodo:

```text
falla el host
      ↓
se detienen VM y CT
```

Necesitaríamos diseñar una infraestructura con redundancia y estudiar clustering y alta disponibilidad.

---

## 💥 Caso de troubleshooting

## 38. «Las máquinas virtuales van lentas»

Supongamos que varios usuarios informan:

> «Proxmox va lento».

Esta descripción es insuficiente.

Un administrador debe transformar el síntoma en preguntas medibles.

### CPU

```text
¿Está saturada?
¿Existe demasiada carga?
¿Hay demasiadas vCPU compitiendo?
```

### Memoria

```text
¿Hay RAM disponible?
¿Se está utilizando swap?
¿Existe presión de memoria?
¿Ha intervenido el OOM Killer?
```

### Almacenamiento

```text
¿Está lleno?
¿Existe elevada latencia?
¿Hay demasiadas operaciones de E/S?
```

### Red

```text
¿Hay pérdida de paquetes?
¿Existe saturación?
¿La VLAN es correcta?
¿El bridge está correctamente configurado?
```

### Guest

```text
¿El problema ocurre en una única VM?
¿El sistema operativo invitado está saturado?
¿Existe un proceso consumiendo recursos?
```

Este procedimiento introduce uno de los principios más importantes de la administración de sistemas:

> **No debemos cambiar configuraciones al azar. Primero observamos, después formulamos una hipótesis, medimos y finalmente actuamos.**

---

## 🧠 Conceptos que debes dominar

Al finalizar este tema deberías poder explicar con tus propias palabras:

* qué es virtualización;
* qué diferencia existe entre host y guest;
* qué función cumple un hipervisor;
* qué es Proxmox VE;
* qué diferencia existe entre KVM y LXC;
* por qué Windows necesita una VM en Proxmox;
* qué es una vCPU;
* qué significa overcommit;
* por qué virtualizar no crea recursos físicos;
* qué función cumple un Linux Bridge;
* qué es una VLAN;
* qué significa thin provisioning;
* qué diferencia existe entre snapshot y backup;
* qué es un nodo;
* qué es un clúster;
* qué función cumple `pmxcfs`;
* por qué un clúster no implica automáticamente alta disponibilidad;
* por qué deben monitorizarse CPU, RAM, almacenamiento y red conjuntamente.

---

## 🚀 Relación con el Proyecto Intermodular

Estos fundamentos constituyen la base de la infraestructura que se utilizará durante el Proyecto Intermodular.

En **primer curso**, servirán para diseñar y desplegar la plataforma de virtualización sobre la que posteriormente se instalarán e interconectarán sistemas informáticos.

La secuencia general será:

```text
Comprender
   ↓
Diseñar
   ↓
Dimensionar
   ↓
Desplegar
   ↓
Interconectar
   ↓
Comprobar
   ↓
Documentar
```

En **segundo curso**, la misma infraestructura permitirá alojar servicios correspondientes a distintos módulos del ciclo, por ejemplo:

```text
Proxmox VE
│
├── Windows Server
│      └── Active Directory / DNS
│
├── SQL Server
│      └── Bases de datos
│
├── Linux / LXC
│      └── Samba
│
└── Servidores web
       └── Aplicaciones
```

Por tanto, Proxmox no constituye un fin aislado.

Actúa como **infraestructura tecnológica común sobre la que integrar sistemas, redes, bases de datos, servicios y aplicaciones**.

Esta característica lo convierte en una herramienta especialmente adecuada para un proyecto intermodular de ASIR.

> 📌 **Criterio profesional**
>
> Las versiones de Proxmox evolucionan. Los conceptos fundamentales permanecen relativamente estables, pero los procedimientos concretos, opciones disponibles y requisitos deben comprobarse siempre en la documentación correspondiente a la versión instalada.

---

## 📚 Referencias y Fuentes Consultadas

!!! info "Documentación Oficial y Autoría"
    * **Material Base:** Basado en la documentación oficial de [Proxmox Virtual Environment](https://pve.proxmox.com/pve-docs/), especialmente en *Proxmox VE Administration Guide*.
    * **Autoría y adaptación didáctica:** José Ramón Soria Nieto.
    * **Marco Curricular:** Programación didáctica del módulo de **Proyecto Intermodular** del Ciclo Formativo de Grado Superior en Administración de Sistemas Informáticos en Red (ASIR), en coordinación con los contenidos de virtualización del módulo de Administración de Sistemas Operativos (ASO).
    * **Material adicional:** [Proxmox VE Documentation](https://www.proxmox.com/en/downloads/proxmox-virtual-environment/documentation) y documentación oficial de [Linux Containers (LXC)](https://linuxcontainers.org/lxc/).
    * **Apoyo mediante Inteligencia Artificial:** Se han utilizado herramientas de Inteligencia Artificial generativa como apoyo en tareas de estructuración, redacción y revisión del material. Los contenidos técnicos generados o reformulados con su ayuda han sido **revisados, contrastados y validados por el autor**, utilizando como referencia la documentación oficial y las fuentes técnicas indicadas anteriormente.

!!! abstract "Cofinanciación y Soporte Institucional"
    * **Entidad Educativa:** Generalitat Valenciana — Conselleria d'Educació, Cultura, Universitats i Ocupació.
    * **Fondo de Financiación:** Proyecto cofinanciado por la **Unión Europea** a través del **Fondo Social Europeo (FSE)**.
    * *«El FSE invierte en tu futuro»* — Acciones orientadas al impulso de la educación, formación avanzada y preparación para el mercado laboral técnico.
