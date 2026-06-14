# Fundamentos de Administración de Linux Server

## 🎯 Relación con el Currículo (RA y CE)

* **Resultado de Aprendizaje 2 (RA2):** Gestiona la automatización de tareas del sistema, aplicando criterios de eficiencia y utilizando comandos y herramientas gráficas.
* **Resultado de Aprendizaje 3 (RA3):** Administra de forma remota el sistema operativo en red valorando su importancia y aplicando criterios de seguridad.

---

## 🏢 Arquitectura y Fundamentos del Ecosistema GNU/Linux

La administración de entornos Linux en servidores corporativos difiere de los entornos Windows al priorizar el uso radical de la interfaz de línea de comandos (**CLI**) sobre la interfaz gráfica (**GUI**). Esto optimiza el consumo de memoria RAM y CPU en los nodos de virtualización y mitiga vectores de ataque.

Estructuramos los pilares operativos de Linux en tres grandes bloques didácticos para la gestión de servidores en producción.

---

## 📑 Bloque I: Estructura del Sistema, Shell e Identidades

### 1. El Árbol de Directorios Estándar (FHS)
A diferencia de Windows y sus unidades físicas (`C:\`, `D:\`), Linux organiza todo su almacenamiento de forma lógica partiendo de un único directorio raíz unificado (`/`) siguiendo el estándar **FHS (Filesystem Hierarchy Standard)**:

* `/etc`: Directorio crítico que alberga los archivos de configuración estáticos de todos los servicios del sistema (ej: sshd, interfaces de red).
* `/var`: Almacena información de datos variables y persistentes, como las colas de correo, bases de datos y, principalmente, los registros del sistema (`/var/log`).
* `/home`: Contenedor de las carpetas personales de los usuarios del sistema.
* `/root`: Directorio home exclusivo para el superusuario administrador del sistema.

### 2. Gestión de Usuarios y Permisos POSIX
La seguridad local descansa sobre el control estricto de identidades y el sistema tradicional de permisos de archivos:

* **Estructura de Identidades:** Los usuarios y grupos se definen y validan localmente analizando los archivos de texto plano `/etc/passwd` y `/etc/group`.
* **Criptografía de Credenciales:** Las contraseñas de red se almacenan de forma segura e ilegible mediante hashes dentro de `/etc/shadow`.
* **Tríada de Permisos:** Cada fichero y directorio cuenta con una máscara de permisos segmentada para el Propietario (**User**), el Grupo (**Group**) y el Resto (**Others**), gobernada por las directivas de Lectura (`r`), Escritura (`w`) y Ejecución (`x`).

---

## ⚙️ Bloque II: Control de Servicios y Red de Infraestructura

### 3. Orquestación del Sistema con systemd
La supervisión de demonios y servicios en las distribuciones de producción modernas (como Ubuntu Server o Debian) se centraliza mediante el gestor de sistema y servicios **systemd**.

A través del binario `systemctl`, el administrador controla el ciclo de vida de los roles del servidor:

```bash
# Inicializar y habilitar en el arranque el servicio SSH
systemctl start sshd
systemctl enable sshd

# Auditar el estado de salud y telemetría de un demonio
systemctl status sshd
```

### 4. Configuración de Red e Interfaces Lógicas
El direccionamiento IP permanente y el enrutamiento se configuran alterando archivos de configuración específicos según la distribución (ej: Netplan mediante archivos YAML en Ubuntu o ifcfg en entornos RedHat), interactuando con la CLI para su diagnóstico:

```bash
# Inspeccionar las direcciones IP de las interfaces del servidor
ip a

# Auditar la tabla de enrutamiento de la infraestructura del aula
ip route
```

## 💾 Bloque III: Almacenamiento, Resiliencia y Virtualización
### 5. Gestión de Discos y Sistemas de Archivos
Linux implementa capas avanzadas de abstracción de almacenamiento físico para dotar de tolerancia a fallos y flexibilidad a los servidores compartidos:

Sistemas de Archivos: Uso de formatos empresariales de alta resiliencia y registro diario como EXT4 o XFS.

LVM (Logical Volume Manager): Capa intermedia de software que permite agrupar discos físicos (Physical Volumes) en pools virtuales para redimensionar particiones en caliente sin necesidad de apagar la máquina virtual en Proxmox.

6. Integración en Entornos Híbridos (Samba)
Para entornos mixtos de aula, el servidor Linux puede integrarse con el Active Directory de Windows actuando como miembro del dominio. El servicio Samba expone recursos compartidos a la red aplicando las ACLs directamente desde el árbol LDAP del dominio corporativo.

## 🔍 Laboratorio de Desafíos y Troubleshooting (Entorno Proxmox)
### 💥 Caso Práctico: Pérdida de conectividad WinRM/SSH por desconfiguración del cortafuegos local (UFW)
Síntoma: Tras aplicar directivas de endurecimiento de seguridad en un contenedor LXC con Ubuntu Server que actúa como File Server, los alumnos pierden instantáneamente la sesión SSH remota. Las conexiones de red son rechazadas de forma sistemática y el servicio deja de responder a los scripts de automatización.

Causa Raíz: Aplicación incorrecta de políticas de filtrado perimetral. Al inicializar el cortafuegos local mediante el comando ufw enable sin haber registrado previamente una regla de excepción explícita para habilitar el tráfico entrante de administración, el kernel bloquea de forma predeterminada todo el tráfico en el puerto TCP 22 (SSH), aislando el nodo.

Solución Operativa en Clase: Al haber perdido el acceso por red, el alumno debe abrir de forma imperativa la Consola Virtualizada directamente desde la interfaz web del hipervisor Proxmox VE para saltarse el bloqueo de red interactuando de forma local como root:

```bash
# 1. Acceder vía consola de Proxmox y habilitar la excepción de gestión
ufw allow 22/tcp

# 2. Recargar las tablas de filtrado del cortafuegos para aplicar los cambios
ufw reload

# 3. Validar las reglas activas de la infraestructura
ufw status verbose
```

📚 Referencias y Fuentes Consultadas
!!! info "Documentación Oficial y Autoría"
* Material Base: Basado en las guías técnicas y unidades de formación del Departamento de Informática del IES Marcos Zaragoza.
* Diseño y Adaptación de Contenidos: José Ramón Soria Nieto.
* Contexto de Aplicación: Módulo profesional de Administración de Sistemas Operativos (ASO), correspondiente al bloque práctico del Segundo Curso de Administración de Sistemas Informáticos en Red (ASIR/ASIX).

!!! abstract "Soporte Institucional y Fondos Europeos"
* Entidad Reguladora: Generalitat Valenciana — Conselleria d'Educació, Cultura i Esport.
* Financiación de Infraestructura: Proyecto cofinanciado por la Unión Europea a través del Fondo Social Europeo (FSE).
* «El FSE invierte en tu futuro» — Acciones destinadas a impulsar la educación digital avanzada, el despliegue de laboratorios de virtualización de alto rendimiento y la capacitación técnica cualificada.