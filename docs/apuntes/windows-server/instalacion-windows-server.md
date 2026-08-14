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
    * [Qemu Guest Agent - Proxmox VE](https://pve.proxmox.com/wiki/Qemu-guest-agent)

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
    src="https://www.youtube.com/embed/uuDBdHz9i-M" 
    title="Instalación de Windows Server 2025 en MV de Proxmox" 
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
    allowfullscreen>
  </iframe>
</div>

!!! info "Ver en YouTube"
    Si prefieres abrir el tutorial directamente en la plataforma o guardarlo en tus listas de reproducción, puedes acceder a través del siguiente enlace:  
    **[▶ Abrir vídeo directamente en YouTube](https://youtu.be/uuDBdHz9i-M)**


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

!!! info "Ballooning: Laboratorio vs Producción"
    La carga del controlador *Balloon* prepara el sistema para la **gestión dinámica de memoria**. 

    * **En el Aula / Laboratorio (Recomendado):** Es vital porque permite a Proxmox recuperar la memoria RAM que Windows no está usando en un momento dado, posibilitando arrancar más máquinas virtuales simultáneamente con recursos limitados.
    * **En Producción (Desaconsejado):** Para servidores críticos (Bases de datos, Exchange, Java, etc.), que Proxmox reclame memoria puede causar paginación masiva o bloqueos de la aplicación. En entornos reales se suele usar memoria estática (desactivando el Ballooning) para garantizar un rendimiento constante.

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
    src="https://www.youtube.com/embed/BJH33dhm81A" 
    title="Instalación de Windows Server 2025 en MV de Proxmox" 
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
    allowfullscreen>
  </iframe>
</div>

!!! info "Ver en YouTube"
    Si prefieres abrir el tutorial directamente en la plataforma o guardarlo en tus listas de reproducción, puedes acceder a través del siguiente enlace:  
    **[▶ Abrir vídeo directamente en YouTube](https://youtu.be/BJH33dhm81A)**


## 💿 Fase III: Instalación del resto de drivers VirtIO y QEMU Guest Agent

Una vez finalizada la instalación del sistema operativo, resulta crítico instalar los controladores paravirtualizados restantes junto con el **QEMU Guest Agent**. Este servicio es esencial para garantizar una integración óptima con el hipervisor Proxmox, ya que habilita funciones avanzadas como la realización de copias de seguridad consistentes, la visibilidad de las direcciones IP desde la consola web y la capacidad de ejecutar apagados controlados (*graceful shutdown*).

### Procedimiento en Server Core

Dado que la instalación recomendada es **Server Core**, realizaremos este proceso desde la línea de comandos:

1. Verificamos en Proxmox que la ISO de los drivers VirtIO sigue montada en la unidad de CD/DVD virtual.
2. Desde la consola de Windows Server, cambiamos a la unidad de CD/DVD (por defecto suele ser `D:` o `E:`).
3. Ejecutamos el instalador automático de las herramientas de invitado (*Guest Tools*), que instalará de golpe todos los drivers restantes. Este instalador abrirá una ventana gráfica (perfectamente funcional en Server Core) donde solo debemos aceptar los términos y seguir el asistente:

    ```cmd
    E:
    virtio-win-gt-x64.msi
    ```

    !!! tip "Diferencia con virtio-win-guest-tools.exe"
        En la ISO también encontrarás el archivo `virtio-win-guest-tools.exe`. Este es simplemente un ejecutable (*wrapper*) que detecta la arquitectura del sistema y lanza el instalador `.msi` correspondiente. Como Windows Server 2025 es un sistema exclusivamente de 64 bits, es más directo ejecutar `virtio-win-gt-x64.msi`.

    !!! info "El servicio blnsrv y la optimización de RAM"
        Al ejecutar el MSI de las herramientas de invitado, se instala automáticamente el **VirtIO Balloon Service** (`blnsrv`). Este servicio es vital para los laboratorios, ya que permite a Proxmox gestionar la memoria de forma dinámica (sobreasignación). Si la máquina virtual no está usando toda su RAM, Proxmox la recupera temporalmente para asignársela a otras máquinas (como clientes de red), optimizando drásticamente los recursos físicos del servidor.
        
        **Nota aclaratoria:** Aunque en la Fase II se haya inyectado manualmente el controlador "Balloon" en el instalador de Windows, aquello solo instala el driver del núcleo. Es estrictamente necesario ejecutar este paquete MSI en la Fase III para registrar el *servicio en segundo plano* (`blnsrv`), que es el que realmente permite la comunicación dinámica con Proxmox.

4. A continuación, procedemos a instalar de forma explícita el **QEMU Guest Agent**. Aunque a veces se distribuye o intenta instalar junto a las *Guest Tools*, instalar el paquete dedicado asegura de forma 100% fiable que el servicio se registre e inicie en el sistema. Navegamos a su carpeta en la ISO y lo instalamos:

    ```powershell
    cd guest-agent
    qemu-ga-x86_64.msi
    ```

5. **(Recomendado)** Una vez finalizadas ambas instalaciones, es una buena práctica reiniciar el servidor. Esto garantiza que los controladores del núcleo se asienten correctamente y que todos los nuevos servicios de integración (QEMU y Balloon) arranquen de forma limpia junto con el sistema operativo. Desde la misma terminal podemos lanzar el reinicio:

    ```powershell
    Restart-Computer
    ```

### Verificación

Para confirmar que la instalación ha sido un éxito:

* En la interfaz web de Proxmox (pestaña *Summary* de la MV), el apartado **IPs** debería mostrar las direcciones de red de la máquina.
* En la terminal del servidor, podemos listar los controladores de terceros instalados y comprobar que los de VirtIO (proveedor Red Hat) están presentes:
  ```powershell
  Get-WindowsDriver -Online | Where-Object { $_.ProviderName -like "*Red Hat*" -or $_.OriginalFileName -like "*virtio*" } | Select-Object OriginalFileName, ProviderName, ClassName, Status, Version
  ```
  
* Además, podemos verificar que el servicio del agente invitado (QEMU Guest Agent) está en ejecución:
  ```powershell
  Get-Service QEMU-GA
  ```
* Y, por último, confirmar que el servicio de gestión dinámica de memoria (VirtIO Balloon Service) también se encuentra activo:
  ```powershell
  Get-Service blnsrv
  ```

---

## 🎬 Vídeo demostración: Instalación del resto de drivers VirtIO y agente QEMU

Vídeo complementario con el procedimiento paso a paso para instalar los drivers VirtIO adicionales y el QEMU Guest Agent tras la instalación de Windows Server.

<div class="video-embed">
  <iframe 
    src="https://www.youtube.com/embed/N8zSO-DxBF4" 
    title="Instalación de drivers VirtIO en Windows Server" 
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
    allowfullscreen>
  </iframe>
</div>

!!! info "Ver en YouTube"
    Si prefieres abrir el tutorial directamente en la plataforma o guardarlo en tus listas de reproducción, puedes acceder a través del siguiente enlace:  
    **[▶ Abrir vídeo directamente en YouTube](https://youtu.be/embed/N8zSO-DxBF4)**

!!! tip "Momento ideal para realizar un Backup (Modo Stop)"
    Una vez instalados los drivers VirtIO y el agente QEMU, y **antes** de continuar con la configuración de red y del servidor, es el momento idóneo para realizar una copia de seguridad de la máquina virtual.
    
    Se recomienda realizar el backup en **modo Stop** para garantizar la máxima consistencia del sistema. Puedes consultar cómo realizar este proceso paso a paso en la sección de administración de Proxmox: [Procedimiento para realizar un Backup en modo Stop](../proxmox/administracion-proxmox.md#procedimiento-para-realizar-un-backup-en-modo-stop).

## 🌐 Fase IV: Configuración de red e identificación del host

Dado que nuestra instalación es **Server Core**, realizaremos las configuraciones iniciales de red y de nombre de equipo a través de la línea de comandos. Este paso es indispensable antes de unir la máquina a un dominio o asignarle roles de servidor.

Podemos realizar este proceso mediante la herramienta interactiva **`sconfig`** o utilizando **PowerShell** directamente.

### Opción A: Utilizando `sconfig` (Recomendado)

Microsoft incluye una utilidad en modo texto que facilita las tareas básicas de configuración de un servidor Core.

1. Desde la terminal, escribimos `sconfig` y pulsamos Enter.
2. En el menú principal, seleccionamos la opción **2 (Computer Name)** para cambiar el nombre del servidor (por ejemplo, `DC01`). El sistema nos pedirá reiniciar.
3. Tras el reinicio, volvemos a iniciar sesión y abrimos de nuevo `sconfig`. Esta vez seleccionamos la opción **8 (Network Settings)**.
4. Seleccionamos el índice del adaptador de red (suele ser el índice `1` de la lista mostrada).
5. Elegimos la opción para establecer la dirección IP, marcamos estática e introducimos la IP, la máscara de subred y la puerta de enlace correspondientes a la red de nuestro laboratorio.
6. A continuación, configuramos también los servidores DNS desde el mismo submenú.
7. Elegimos la opción de volver al menú principal y posteriormente la de salir a la línea de comandos.

### Opción B: Utilizando PowerShell

Para una configuración más directa y orientada a la automatización, podemos utilizar cmdlets de PowerShell. Desde la consola, abrimos PowerShell escribiendo `powershell` y ejecutamos los siguientes pasos:

**1. Configuración de Red (IP y DNS):**

Primero, identificamos el índice de nuestra tarjeta de red (`ifIndex`):
```powershell
Get-NetAdapter
```

Asignamos una dirección IP estática, longitud de prefijo (máscara) y puerta de enlace (sustituyendo el valor de `-InterfaceIndex` por el obtenido previamente):
```powershell
New-NetIPAddress -InterfaceIndex 1 -IPAddress [IP_ADDRESS] -PrefixLength 24 -DefaultGateway [IP_GW_ADDRESS]
```

Configuramos las direcciones de los servidores DNS:
```powershell
Set-DnsClientServerAddress -InterfaceIndex 1 -ServerAddresses ("[IP_DNS_ADDRESS1]","[IP_DNS_ADDRESS2]")
```

**2. Cambio de nombre y reinicio:**

Renombramos el servidor y forzamos el reinicio para aplicar el nuevo *hostname*:
```powershell
Rename-Computer -NewName "DC01" -Restart
```

## 🎬 Vídeo demostración: Cambio de nombre de equipo y configuración de red

Vídeo complementario con el procedimiento paso a paso para cambiar el nombre del equipo y configurar la red en Windows Server.

<div class="video-embed">
  <iframe 
    src="https://www.youtube.com/embed/NRV-Axf3Y1E" 
    title="Cambio de nombre de equipo y configuración de red en Windows Server" 
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
    allowfullscreen>
  </iframe>
</div>

!!! info "Ver en YouTube"
    Si prefieres abrir el tutorial directamente en la plataforma o guardarlo en tus listas de reproducción, puedes acceder a través del siguiente enlace:  
    **[▶ Abrir vídeo directamente en YouTube](https://youtu.be/NRV-Axf3Y1E)**

---

## 🛡️ Fase V: Instalación de actualizaciones y hardening inicial

Una vez configurada la red, el siguiente paso crítico en el ciclo de vida del servidor es garantizar su seguridad y estabilidad antes de exponerlo a servicios de producción o unirlo a un dominio.

### 1. Instalación de Actualizaciones (Windows Update)

Es fundamental aplicar los últimos parches de seguridad y actualizaciones acumulativas proporcionados por Microsoft.

**Mediante `sconfig` (Recomendado):**

1. Iniciamos la utilidad `sconfig` desde la línea de comandos.
2. En el menú, seleccionamos la opción **6 (Descargar e Instalar Actualizaciones)**.
3. El sistema nos preguntará si deseamos buscar todas las actualizaciones (opción `1`), solo las recomendadas (opción `2`) o solo las características opcionales (opción `3`). Pulsamos **`1`** y luego Enter.
4. Tras la búsqueda, mostrará una lista de las actualizaciones disponibles y nos preguntará cuáles instalar. Pulsamos **`T`** (Todo) y luego Enter.
5. Dependiendo de los parches instalados, es posible que el servidor solicite un reinicio automático al finalizar.

**Mediante PowerShell (Entornos automatizados):**
En despliegues sin intervención manual podemos utilizar el módulo `PSWindowsUpdate`. Para instalarlo y aplicar las actualizaciones con reinicio automático utilizamos estos cmdlets:
```powershell
Install-Module -Name PSWindowsUpdate -Force
Install-WindowsUpdate -AcceptAll -AutoReboot
```

## 🎬 Vídeo demostración: Instalación de actualizaciones mediante sconfig

Vídeo complementario con el procedimiento paso a paso para realizar la instalación de actualizaciones utilizando la herramienta sconfig en Windows Server.

<div class="video-embed">
  <iframe 
    src="https://www.youtube.com/embed/WG0rE4NHKAI" 
    title="Instalación de actualizaciones mediante sconfig en Windows Server" 
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
    allowfullscreen>
  </iframe>
</div>

!!! info "Ver en YouTube"
    Si prefieres abrir el tutorial directamente en la plataforma o guardarlo en tus listas de reproducción, puedes acceder a través del siguiente enlace:  
    **[▶ Abrir vídeo directamente en YouTube](https://youtu.be/WG0rE4NHKAI)**

### 2. Hardening Inicial (Configuraciones de Seguridad Base)

Aunque **Server Core** ya cuenta con una superficie de ataque significativamente reducida, es conveniente realizar algunas configuraciones básicas para afianzar la seguridad del sistema:

**a) Zona Horaria y Sincronización de Tiempo (NTP)**
Para el correcto funcionamiento del protocolo Kerberos en Active Directory, es vital tener la hora exacta (no se toleran desfases de más de 5 minutos). 

Primero, establecemos la **zona horaria** correcta (por ejemplo, para la España peninsular):
```powershell
Set-TimeZone -Id "Romance Standard Time"
```

A continuación, configuramos el **NTP** para asegurar que el reloj interno se sincroniza con exactitud. Utilizando cmdlets de PowerShell, configuramos el servidor de tiempo (ej. `pool.ntp.org`) en el registro y reiniciamos el servicio correspondiente:
```powershell
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" -Name "NtpServer" -Value "pool.ntp.org,0x8"
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" -Name "Type" -Value "NTP"
Restart-Service -Name W32Time
```

**b) Gestión Remota mediante PowerShell (PS Remoting)**
En lugar de Escritorio Remoto (RDP), es más eficiente y acorde a la filosofía de Server Core utilizar PowerShell Remoting para su administración. 

Para asegurarnos de que el servicio está listo y preparado para el futuro, forzamos su habilitación en el servidor:
```powershell
Enable-PSRemoting -Force
```

!!! note "Conexión remota pospuesta hasta Active Directory"
    En este punto (entorno de Grupo de Trabajo), conectarse por PS Remoting requeriría configuraciones adicionales y temporales de confianza (`TrustedHosts`) en el equipo cliente.
    
    Por lo tanto, **de momento no realizaremos acceso remoto**. Continuaremos administrando el sistema directamente desde la consola local del servidor (Proxmox) hasta que lo promocionemos a **Controlador de Dominio**. Una vez en el dominio, la autenticación se realizará de forma transparente y segura mediante **Kerberos**, permitiendo la conexión remota directa sin configuraciones extra. Este proceso se documentará en la sección de Active Directory.

#### 🎬 Vídeo demostración: Zona horaria y Gestión remota

Vídeo complementario con el procedimiento paso a paso para configurar el NTP y preparar la administración remota en el servidor.

<div class="video-embed">
  <iframe 
    src="https://www.youtube.com/embed/N2IGBx3QiJ8" 
    title="Configuración de Zona Horaria y PS Remoting en Windows Server Core" 
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
    allowfullscreen>
  </iframe>
</div>

!!! info "Ver en YouTube"
    Si prefieres abrir el tutorial directamente en la plataforma o guardarlo en tus listas de reproducción, puedes acceder a través del siguiente enlace:  
    **[▶ Abrir vídeo directamente en YouTube](https://youtu.be/N2IGBx3QiJ8)**

**c) Verificación de Microsoft Defender**
En Windows Server 2025, Microsoft Defender Antivirus está instalado y operativo por defecto (a menos que exista otro antivirus o se haya deshabilitado). Podemos auditar su estado con:
```powershell
Get-MpComputerStatus | Select-Object AMRunningMode, AMServiceEnabled, AntivirusEnabled, RealTimeProtectionEnabled
```
Y actualizar manualmente las firmas de detección de amenazas mediante:
```powershell
Update-MpSignature
```

**d) Renombrar la cuenta de Administrador Local**
Como medida básica para mitigar ataques de fuerza bruta automatizados, es muy recomendable cambiar el nombre por defecto de la cuenta del administrador local a uno que no sea tan predecible como `Administrador` o `Administrator`.

!!! note "Impacto al promocionar a Active Directory"
    Al realizar este cambio ahora, nos adelantamos a la configuración del dominio. Cuando se instala Active Directory, la base de datos de usuarios locales (SAM) se convierte en el directorio del dominio. Esto significa que **nuestra cuenta local renombrada pasará automáticamente a ser la cuenta principal de Administrador del Dominio**, manteniendo el nuevo nombre (`AdminDom`) y protegiendo la red desde el primer momento.

```powershell
Rename-LocalUser -Name "Administrador" -NewName "AdminDom"
```

**e) Configuración del Firewall (Windows Defender Firewall)**
Por defecto, Server Core bloquea el tráfico de entrada, incluyendo la respuesta al clásico comando ping (ICMPv4). Además, por seguridad, es conveniente limitar desde dónde se puede administrar remotamente el servidor.

*1. Permitir respuesta al Ping (ICMPv4) para monitorización:*
```powershell
Enable-NetFirewallRule -Name "CoreNet-Diag-ICMP4-EchoRequest-In" -Profile Domain,Private
```

*2. Restringir la administración remota a la VLAN correspondiente:*
Suponiendo que nuestra red (o VLAN de administración) es la `192.168.1.0/24`, podemos modificar las reglas de entrada de WinRM para que solo acepten conexiones desde ese rango de direcciones IP específico.
```powershell
Set-NetFirewallRule -DisplayGroup "Windows Remote Management" -RemoteAddress "192.168.1.0/24"
```

#### 🎬 Vídeo demostración: Defender, Cuentas y Firewall

Vídeo complementario con el procedimiento paso a paso para completar el hardening base del servidor revisando el antivirus, renombrando al administrador y ajustando el cortafuegos.

<div class="video-embed">
  <iframe 
    src="https://www.youtube.com/embed/BGI9tiRiai0" 
    title="Configuración de Defender, Cuentas y Firewall en Windows Server Core" 
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
    allowfullscreen>
  </iframe>
</div>

!!! info "Ver en YouTube"
    Si prefieres abrir el tutorial directamente en la plataforma o guardarlo en tus listas de reproducción, puedes acceder a través del siguiente enlace:  
    **[▶ Abrir vídeo directamente en YouTube](https://youtu.be/BGI9tiRiai0)**

---

## 🔗 Próximos pasos

Una vez completada la instalación, la configuración de red y el *hardening* del servidor, el sistema base está preparado. El ciclo de vida continúa con la asignación de roles y servicios.

!!! info "Siguientes fases de despliegue"
    La **promoción a controlador de dominio** o la instalación de los roles principales de infraestructura (AD DS, DNS, DHCP…) se documentan de forma específica en el apartado de **[Active Directory](../active-directory/implementacion-ad.md)**.

Consulta [Fundamentos de Administración de Windows Server](fundamentos-core.md) para el marco conceptual del despliegue y la administración posterior.


## 📚 Referencias y Fuentes Consultadas

!!! info "Documentación Oficial y Autoría"
    * **Material Base:** [Instalar Windows Server 2025 en MV de Proxmox (PDF)](https://gvaedu-my.sharepoint.com/:b:/r/personal/jr_soria_edu_gva_es/Documents/MIS-APUNTES/ASO/GITHUB-AUX/Windows%20Server/instalacion-windows-server/Instalar-WServer2025-en-MV-Proxmox.pdf?csf=1&web=1&e=YCoWne)
    * **Autoría del Temario:** José Ramón Soria Nieto.
    * **Marco Curricular:** Programación didáctica para el módulo de *Administración de Sistemas Operativos (ASO)* del Ciclo Formativo de Grado Superior en *Administración de Sistemas Informáticos en Red (ASIR/ASIX)*.
    * **Material adicional:** [Windows Server learn oficial](https://learn.microsoft.com/es-es/windows-server/)
    * **Servicio de Hora de Windows:** [Windows Time Service (W32Time)](https://learn.microsoft.com/en-us/windows-server/networking/windows-time-service/windows-time-service-top)

!!! abstract "Cofinanciación y Soporte Institucional"
    * **Entidad Educativa:** Generalitat Valenciana — Conselleria d'Educació, Cultura i Esport.
    * **Fondo de Financiación:** Proyecto cofinanciado por la **Unión Europea** a través del **Fondo Social Europeo (FSE)**. 
    * *«El FSE invierte en tu futuro»* — Acciones orientadas al impulso de la educación, formación avanzada y preparación para el mercado laboral técnico.