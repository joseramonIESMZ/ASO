# Implementación de Active Directory en Windows Server Core

## 🎯 Relación con el Currículo (RA y CE)
La implementación del servicio de directorio y promoción a controlador de dominio da soporte técnico y sirve de base operativa para la consecución de los siguientes elementos del currículo oficial:

* **Resultado de Aprendizaje 1 (RA1):** Administra el servicio de directorio interpretando especificaciones e integrándolo en una red.
    * **CE3-RA1:** Se ha realizado la instalación del servicio de directorio en el servidor.
    * **CE4-RA1:** Se ha creado el dominio y los objetos básicos del directorio.
* **Resultado de Aprendizaje 9 (RA9):** Cumple con las exigencias laborales transversales relativas a autonomía, trabajo en equipo, organización y seguridad.

---

## 🏢 Contexto: Promoción a Controlador de Dominio

Continuando con el despliegue de nuestro servidor Windows Server 2025 en modo **Server Core**, el siguiente paso es dotarlo del rol de Controlador de Dominio (Domain Controller o DC). Esto implica instalar el rol de Servicios de Dominio de Active Directory (AD DS) y promover el servidor creando un nuevo bosque y dominio raíz.

Nuestro dominio se llamará `int.asix.info`. Todo el proceso se realizará mediante comandos de **PowerShell**, ya que es la forma adecuada de administrar entornos Server Core.

!!! note "Pasos previos ya realizados"
    Tal y como se documentó en la instalación base del servidor, asumimos que ya se han completado los pasos previos imprescindibles (fases del apartado "[Instalación de Windows Server](../windows-server/instalacion-windows-server.md)"):
    
    * Renombrar el equipo servidor (`Rename-Computer ...`).
    * Establecer configuración IP fija (`New-NetIPAddress ...`).
    * Configurar la zona horaria (`Set-Timezone`).
    * Sincronizar el reloj del sistema con un servidor NTP ( `Set-ItemProperty ...`)
    ...
---

## 🛠️ Fase I: Instalación del Rol AD DS

Antes de poder promover el servidor, necesitamos instalar los binarios y herramientas del rol de Active Directory Domain Services (AD DS).

1. Iniciamos sesión en nuestro Windows Server Core con la cuenta de administrador.
2. Abrimos una consola de PowerShell si no estamos ya en ella:
   ```cmd
   powershell
   ```
3. Ejecutamos el siguiente cmdlet para instalar el rol AD DS y sus herramientas de administración:
   ```powershell
   Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
   ```

!!! info "Verificación de la instalación"
    El comando tardará unos instantes en completarse. Al finalizar, mostrará una tabla indicando `Success: True` y si es necesario reiniciar (`Restart Needed: No` en este paso).

---

## 🌲 Fase II: Promoción a Controlador de Dominio y Creación del Bosque

Una vez instalado el rol, procedemos a promover el servidor creando el nuevo bosque.

1. Importamos el módulo necesario para el despliegue de AD DS:
   ```powershell
   Import-Module ADDSDeployment
   ```

2. Ejecutamos el cmdlet `Install-ADDSForest` con todos los parámetros de configuración. Hemos adaptado los nombres al dominio solicitado (`int.asix.info` y NetBIOS `INT`):

   ```powershell
   Install-ADDSForest `
     -CreateDNSDelegation:$false `
     -DatabasePath "C:\Windows\NTDS" `
     -DomainMode 7 `
     -DomainName "int.asix.info" `
     -DomainNetbiosName "INT" `
     -ForestMode 7 `
     -InstallDNS:$true `
     -LogPath "C:\Windows\NTDS" `
     -NoRebootOnCompletion:$false `
     -SysVolPath "C:\Windows\SYSVOL" `
     -Force:$true
   ```

!!! warning "Contraseña del Modo de Restauración (DSRM)"
    Durante la ejecución del comando, el sistema pedirá (hasta dos veces) que introduzcas la contraseña para el modo de restauración de servicios de directorio (SafeModeAdministratorPassword). Esta contraseña es **crítica** para recuperar el directorio en caso de desastre. Asegúrate de documentarla de forma segura.

### Explicación de los parámetros utilizados:

* `-DomainMode 7` y `-ForestMode 7`: Establecen el nivel funcional del dominio y del bosque a Windows Server 2016 (el valor `7` corresponde a esta versión, garantizando compatibilidad).
* `-DatabasePath`, `-LogPath`, `-SysVolPath`: Se definen explícitamente las rutas por defecto para la base de datos (NTDS), los registros y la carpeta compartida SYSVOL.
* `-InstallDNS:$true`: Instala y configura automáticamente el rol de servidor DNS.
* `-NoRebootOnCompletion:$false`: Indica que el servidor se reiniciará automáticamente al finalizar la promoción, algo estrictamente necesario.

---

## 🛡️ Fase III: Configuración DNS Post-Instalación

Tras el reinicio automático, el servidor ya será un Controlador de Dominio y deberemos iniciar sesión con las credenciales del dominio (ej. `INT\AdminDom` o `INT\Administrador`).

Un paso crucial es verificar y configurar los **reenviadores (forwarders) de DNS**. Como nuestro servidor ahora es el DNS principal de la red, necesita saber a quién preguntar cuando intente resolver nombres externos (como `google.com`).

Dado que en los pasos previos (documentados en la instalación base) ya configuramos servidores DNS externos en nuestra tarjeta de red, el asistente de promoción debería haberlos establecido automáticamente como reenviadores. Podemos verificarlo con:

```powershell
Get-DnsServerForwarder
```

Si la lista está vacía o deseamos establecer unos servidores DNS externos específicos (como los del ejemplo), utilizaremos el siguiente comando para configurarlos manualmente:

```powershell
Set-DnsServerForwarder -IPAddress [IP_DNS_ADDRESS1],[IP_DNS_ADDRESS2]
```

*(Nota: Las IPs indicadas corresponden a los servidores DNS externos especificados en el documento de referencia. Puedes sustituirlas por `8.8.8.8` u otras de tu preferencia).*

---

## 🩺 Fase IV: Verificación del Estado del Controlador de Dominio (Health Check)

Tras la promoción y configuración, es una excelente práctica comprobar desde PowerShell que nuestro servidor está sano y los servicios de directorio funcionan correctamente antes de conectar clientes.

1. **Verificar el rol del servidor y el dominio**:
   ```powershell
   Get-ADDomainController
   ```
   *Debe devolver información detallada del servidor, indicando que es DC y el dominio asociado.*

2. **Comprobar carpetas compartidas esenciales (SYSVOL y NETLOGON)**:
   ```powershell
   Get-SmbShare
   ```
   *El directorio activo requiere que las carpetas `SYSVOL` y `NETLOGON` estén compartidas correctamente para distribuir las políticas de grupo y los scripts de inicio de sesión.*

3. **Diagnóstico completo con DCDiag**:
   ```powershell
   dcdiag /c
   ```
   *Esta herramienta clásica de línea de comandos realiza una batería de pruebas sobre el DC (conectividad, replicación, servicios DNS). Aunque devuelva algún aviso menor, lo importante es que las pruebas principales indiquen "passed" (superado).*

---

## 🎬 Vídeo demostración: Implementación de Active Directory

Vídeo complementario con el proceso paso a paso para instalar el rol de AD DS, promover el servidor a controlador de dominio y verificar la configuración DNS.

<div class="video-embed">
  <iframe 
    src="https://www.youtube.com/embed/uJwybywX090" 
    title="Implementación de Active Directory en Windows Server Core" 
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
    allowfullscreen>
  </iframe>
</div>

!!! info "Ver en YouTube"
    Si prefieres abrir el tutorial directamente en la plataforma o guardarlo en tus listas de reproducción, puedes acceder a través del siguiente enlace:  
    **[▶ Abrir vídeo directamente en YouTube](https://youtu.be/uJwybywX090)**

---

## 💻 Fase V: Unir un equipo cliente (Windows 10/11) al dominio

Una vez que el Controlador de Dominio está operativo, podemos unir equipos clientes a nuestra red corporativa.

### Requisitos previos en el cliente
* El equipo cliente debe tener acceso por red al servidor.
* La IP la podrá obtener por DHCP (o ser estática), pero **su DNS principal deberá ser obligatoriamente la IP de nuestro Controlador de Dominio**.

### Procedimiento mediante PowerShell en el cliente

1. **Renombrar el equipo cliente** (Opcional pero recomendado para mantener un inventario ordenado):
   ```powershell
   Rename-Computer -NewName PC-CLI-01
   Restart-Computer
   ```

2. **Establecer el Controlador de Dominio como DNS principal** (suponiendo que la interfaz se llama "Ethernet" y que la IP del DC es `[IP_ADDRESS_DOMAIN_CONTROLLER]`, ajusta estos valores a tu entorno real):
   ```powershell
   Set-DnsClientServerAddress -InterfaceAlias Ethernet -ServerAddress [IP_ADDRESS_DOMAIN_CONTROLLER]
   ```

3. **Unir el equipo al dominio**:
   ```powershell
   Add-Computer -DomainName int.asix.info -Credential (Get-Credential)
   Restart-Computer
   ```

!!! info "Credenciales de unión"
    Al ejecutar `Add-Computer`, se abrirá una ventana solicitando credenciales. Deberás introducir el usuario y contraseña del **Administrador del dominio** (el del servidor DC) para autorizar la unión de esta nueva máquina. Tras el reinicio, ya podrás iniciar sesión en el cliente con cualquier usuario creado en el Active Directory.

### Troubleshooting: Comprobación del Canal Seguro

En ocasiones, tras unir el cliente o pasado un tiempo, pueden surgir problemas de comunicación con el Directorio Activo (por ejemplo, fallos al iniciar sesión indicando que no hay servidores de inicio de sesión disponibles). Desde PowerShell en el equipo cliente (iniciando sesión como administrador local o del dominio si deja), puedes verificar que la relación de confianza con el DC está intacta usando:

```powershell
Test-ComputerSecureChannel -Verbose
```

Si el resultado es `True`, la comunicación encriptada bidireccional entre el cliente y el DC funciona correctamente. Si devuelve `False`, puedes intentar reparar el canal añadiendo el flag `-Repair` y suministrando credenciales de administrador de dominio.

---

## 🎬 Vídeo demostración: Unión de un equipo cliente al dominio

Vídeo complementario con el proceso paso a paso para unir un equipo cliente (Windows 10/11) al dominio de Active Directory.

<div class="video-embed">
  <iframe 
    src="https://www.youtube.com/embed/_MFCDqCAMEY" 
    title="Unión de un equipo cliente al dominio" 
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
    allowfullscreen>
  </iframe>
</div>

!!! info "Ver en YouTube"
    Si prefieres abrir el tutorial directamente en la plataforma o guardarlo en tus listas de reproducción, puedes acceder a través del siguiente enlace:  
    **[▶ Abrir vídeo directamente en YouTube](https://youtu.be/_MFCDqCAMEY)**


## 📚 Referencias y Fuentes Consultadas

!!! info "Documentación Oficial y Autoría"
    * **Autoría del Temario:** José Ramón Soria Nieto.
    * **Marco Curricular:** Programación didáctica para el módulo de *Administración de Sistemas Operativos (ASO)* del Ciclo Formativo de Grado Superior en *Administración de Sistemas Informáticos en Red (ASIR/ASIX)*.
    * **Material adicional:** [Documentación oficial de Active Directory Domain Services](https://learn.microsoft.com/es-es/windows-server/identity/ad-ds/active-directory-domain-services)
    * **PowerShell para AD DS:** [Instalación de AD DS con PowerShell](https://learn.microsoft.com/es-es/windows-server/identity/ad-ds/deploy/install-active-directory-domain-services--level-100-)

!!! abstract "Cofinanciación y Soporte Institucional"
    * **Entidad Educativa:** Generalitat Valenciana — Conselleria d'Educació, Cultura i Esport.
    * **Fondo de Financiación:** Proyecto cofinanciado por la **Unión Europea** a través del **Fondo Social Europeo (FSE)**. 
    * *«El FSE invierte en tu futuro»* — Acciones orientadas al impulso de la educación, formación avanzada y preparación para el mercado laboral técnico.
