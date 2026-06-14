# Configuración Centralizada mediante Políticas de Grupo (GPO)

## 🎯 Relación con el Currículo (RA y CE)

* **Resultado de Aprendizaje 2 (RA2):** Gestiona la automatización de tareas del sistema, aplicando criterios de eficiencia y utilizando comandos y herramientas gráficas.
* **Resultado de Aprendizaje 3 (RA3):** Administra de forma remota el sistema operativo en red valorando su importancia y aplicando criterios de seguridad.
    * **CE 3.d:** Se han aplicado directivas de seguridad para la protección del servidor y de los recursos de red.

---

## 🏢 Fundamentos de las Directivas de Grupo en Active Directory

Las **Políticas de Grupo (Group Policies)** permiten aplicar configuraciones de forma remota, desde un lugar centralizado, a los objetos del directorio: usuarios, equipos y servidores. Estas configuraciones se dividen fundamentalmente en **directivas** (de obligado cumplimiento) y **preferencias** (opcionales de Windows).

### Ámbitos de Configuración Comunes
A través de las GPOs, un administrador puede gobernar por completo el comportamiento del entorno corporativo:
* Configuraciones de red y escritorio.
* Políticas de seguridad y auditoría de eventos.
* Redirección de carpetas y mapas de red.
* Despliegue automatizado de software y restricciones de aplicación.

### 🛠️ Mecanismo de Funcionamiento Subyacente
Las directivas del dominio guardan una relación directa con las **claves del registro de Windows (Registry)**. Al establecer una directiva dentro de una GPO y desplegarla en el dominio, esta se materializa en la modificación automática de la correspondiente clave en el `regedit` de cada uno de los equipos clientes afectados.


## 📐 Estructura, Precedencia y Filtrado de GPOs

Las directivas y preferencias se empaquetan en conjuntos denominados Directivas de grupo que se tratan de forma unificada como un **Objeto de Políticas de Grupo (GPO - Group Policy Object)**. El orden de procesamiento determina qué políticas tienen prioridad en caso de conflicto:

### Orden de Precedencia Jerárquico (Menor a Mayor prioridad)
1. **Local:** Configuración de la máquina local (`gpedit.msc` / MMC).
2. **Sitio:** Vinculado a la localización física o subred de Active Directory.
3. **Dominio:** Políticas aplicadas de forma global (ej: *Default Domain Policy*).
4. **Unidad Organizativa (UO):** **Es el nivel donde más se van a utilizar** y aplicar las GPOs para segmentar departamentos.
5. **Unidad Organizativa Secundaria:** Subcontenedores LDAP que heredan y refinan las directivas de la UO raíz[cite: 12].

!!! warning "Restricción de Filtrado Crítica (Group Policy Targeting)"
    Las GPO **únicamente actúan sobre objetos de tipo Usuario y Equipo, nunca sobre grupos de seguridad** de forma directa[cite: 12]. Si aplicas una GPO sobre una Unidad Organizativa que incluye un grupo de seguridad compuesto por varios usuarios, la GPO realmente **no tendrá efecto** sobre dichos usuarios[cite: 12]. La GPO tendrá que aplicarse sobre los usuarios del grupo, por lo que estos deberán estar incluidos en una UO de la que sí formen directamente parte los usuarios y no a través del grupo[cite: 12].

---

## 🗂️ Anatomía de un Objeto GPO: Directivas y Preferencias

Un objeto GPO se compone de dos grandes áreas de configuración que se subdividen según su propósito operativo[cite: 12]:

### 1. Área de Directivas (Policies)
Establecen restricciones estrictas que el usuario no puede saltarse o modificar[cite: 12]. Se dividen en:
* **Software:** Permite el despliegue e instalación de forma centralizada de aplicaciones en los equipos de la red[cite: 12].
* **Configuraciones de Windows:** Contiene un número amplio de configuraciones que se pueden realizar, tales como proporcionar permisos administrativos a los usuarios, seguridad de los equipos y usuarios, etc[cite: 12]. Se diferencia entre configuraciones para usuarios y configuraciones para equipos[cite: 12].
* **Plantillas Administrativas:** Normalmente se utilizan para configurar la interfaz de usuario (experiencia de escritorio, panel de control, acceso a hardware local), así como para parametrizar aplicaciones externas al sistema operativo (como Office, Google Chrome, Firefox, Adobe, y muchas otras)[cite: 12]. Para facilitar su búsqueda, portales externos como [admx.help](https://admx.help) disponen de un catálogo completo de directivas[cite: 12].

### 2. Área de Preferencias (Preferences)
Configuraciones no imperativas que el administrador define pero que el usuario puede llegar a alterar en local[cite: 12]:
* **Configuraciones de Windows:** Habilitan o no al usuario o equipo a que se puedan realizar configuraciones en Windows[cite: 12].
* **Configuraciones del Panel de Control:** Habilitan o no al usuario o equipo a que se puedan realizar configuraciones desde el Panel de Control[cite: 12].

---

## 🔒 Hardening Corporativo de Cuentas y Contraseñas

Siguiendo los requerimientos de la organización para mitigar ataques de fuerza bruta y asegurar la robustez de las identidades en los entornos de producción del aula, se deben implementar las siguientes directivas estrictas de seguridad de cuentas[cite: 8]:

* **Bloqueo de cuentas por reintentos:** Si un usuario se equivoca **3 veces** consecutivas al introducir su credencial, la cuenta quedará bloqueada de forma inmediata (solo la podrá desbloquear el administrador)[cite: 8].
* **Longitud mínima:** La contraseña de red requerirá de un tamaño mínimo de **8 caracteres**[cite: 8].
* **Requisitos de complejidad:** Obligatoriedad de cumplir los requisitos mínimos de seguridad (combinación de mayúsculas, minúsculas, caracteres numéricos y símbolos)[cite: 8].
* **Historial de contraseñas:** La contraseña que ya se haya utilizado no podrá volverse a utilizar hasta pasados al menos **10 cambios** de contraseña[cite: 8].
* **Vigencia de la credencial:** El usuario debe cambiar la contraseña de forma obligatoria cada **seis meses**[cite: 8].

---

## 🖥️ Herramientas Gráficas de Gestión del Dominio

La administración de las GPOs desde únicamente PowerShell suele ser complicada, por lo que a menudo se recurre también al uso de herramientas gráficas[cite: 12]. La consola principal es la **Administración de Directivas de Grupo (`gpmc.msc`)**[cite: 12].

!!! info "Nota de Laboratorio sobre Entornos de Dominio"
    En un entorno de dominio Windows, es necesario que las herramientas administrativas se lancen desde equipos conectados al dominio (ya sean terminales clientes o servidores de gestión dedicados)[cite: 12].

Al expandir el árbol del dominio en la herramienta gráfica, aparecerán dos GPOs configuradas por defecto en el sistema[cite: 12]:
* **Default Domain Policy:** Se aplica de manera global para todos los usuarios y equipos del dominio[cite: 12].
* **Default Domain Controllers Policy:** Aplicada de forma exclusiva sobre la OU que contiene los controladores de dominio del sistema[cite: 12].

Las GPOs se enlazan (*vinculan*) al dominio, unidad organizativa o sitio donde se quiere aplicar, y se editan de forma interactiva abriendo el **Editor de administración de directivas de grupo** para segmentar las políticas entre *Configuración del equipo* y *Configuración del usuario*[cite: 12].

---

## 💻 Automatización de GPOs mediante PowerShell Core

En arquitecturas *Server Core*, toda la orquestación inicial de políticas de seguridad e inyección de claves de registro debe automatizarse mediante el script `confini.ps1` del Sprint 5[cite: 8]:

### 1. Auditoría e Inspección de Objetos en Red
Para listar y analizar las GPOs existentes en el dominio y extraer sus propiedades base, ejecutamos los cmdlets del módulo `GroupPolicy`[cite: 12]:

```powershell
# Listar todas las GPOs disponibles en el dominio mostrando su estado y descripción
Get-GPO -all -Domain asix.info | ft DisplayName, GPOStatus, Description -AutoSize

# Inspeccionar las propiedades específicas de una directiva concreta
Get-GPO -Name "Default Domain Policy"
```

2. Generación de Informes Técnicos (Get-GPOReport)
Es una excelente práctica exportar la configuración de las directivas para su visualización externa o auditoría[cite: 12]. El informe se puede volcar tanto en formato XML estructurado (para ser visualizado con Notepad) como en formato HTML interactivo[cite: 12]:

```powershell
# Generar informe en formato XML y abrirlo con el Bloc de notas
Get-GPOReport -Name "Default Domain Policy" -ReportType Xml -Path C:\Compartir\GPODefecto.xml
Notepad C:\Compartir\GPODefecto.xml

# Generar informe en formato HTML para revisión visual en navegador
Get-GPOReport -Name "Default Domain Policy" -ReportType html -Path C:\Compartir\GPODefecto.html
```

3. Modificación del Registro y Despliegue Automatizado (confini.ps1)
Nota técnica de diseño: Aunque es factible alterar la directiva por defecto (Default Domain Policy), es aconsejable no modificar esta GPO por defecto y sí proceder con la creación de GPOs nuevas y vincularlas de forma selectiva donde se necesiten[cite: 12].

```powershell
# E:\scripts\confini.ps1
# Script de automatización de hardening e inyección de directivas corporativas

# 1. Configurar directivas de contraseñas globales del dominio
Set-ADDefaultDomainPasswordPolicy -Identity "int.empresa.asix" `
    -MinPasswordLength 8 -ComplexityEnabled $True -PasswordHistoryCount 10 -MaxPasswordAge (New-TimeSpan -Days 180) -Force

# 2. Configurar el bloqueo automático de cuentas ante intrusiones
Set-ADAccountLockoutPolicy -Identity "int.empresa.asix" `
    -LockoutThreshold 3 -LockoutDuration (New-TimeSpan -Minutes 30) -Force

# 3. Modificar directiva gráfica: Cambiar el fondo de escritorio a todos los usuarios
Set-GPRegistryValue -Name "Default Domain Policy" `
    -key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" `
    -ValueName "WallPaper" -Type String -Value "\\DC01\Compartir\Fondo-escritorio.jpg" -Verbose

# 4. Crear una nueva GPO dedicada para restringir accesos al Panel de Control
New-GPO -Name 'No panel de control' -Comment 'Para quitar acceso al Panel de Control de los alumnos'

# 5. Vincular la nueva GPO a la Unidad Organizativa destino (Inicialmente deshabilitada)
New-GPLink -Name 'No panel de control' -Target 'OU=alumnado,OU=segundo,OU=iesmz,DC=asix,DC=info' -LinkEnabled No

# 6. Modificar el valor del registro local (Type DWord: Valor 1 deshabilita el panel de control)
Set-GPRegistryValue -Name 'No panel de control' `
    -key 'HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' `
    -ValueName 'NoControlPanel' -Type DWord -Value 1

# 7. Habilitar definitivamente la GPO vinculada para su propagación
Set-GPLink -Name 'No panel de control' -Target 'OU=alumnado,OU=segundo,OU=iesmz,DC=asix,DC=info' -LinkEnabled Yes
```

🏛️ Gestión Avanzada: El Almacén Central (Central Store)
Los diferentes sistemas operativos de Microsoft llevan sus plantillas administrativas preinstaladas de forma local en la carpeta C:\Windows\PolicyDefinitions de cada equipo[cite: 12]. Adicionalmente, se pueden ampliar las directivas disponibles para aplicaciones instaladas mediante ficheros .admx descargados de internet[cite: 12].

Para evitar la desincronización y garantizar que todos los equipos de la organización dispongan exactamente de las mismas directivas centralizadas, se debe habilitar el Almacén Central (Central Store) en el servidor[cite: 12]:

Ruta del Almacén Central: Se debe crear manualmente el directorio corporativo en la ruta compartida del volumen SYSVOL: C:\Windows\SYSVOL\domain\sysvol\Policies\PolicyDefinitions[cite: 12].

Estructura del Almacén: En la raíz de esta carpeta se vuelcan los ficheros genéricos .admx de las plantillas (ej: controlpanel.admx, desktop.admx)[cite: 12].

Internacionalización: Los archivos de traducción de idioma .adml se deben estructurar dentro de subcarpetas nombradas de forma estricta según su código de región (ej: la carpeta es-ES para albergar las descripciones en castellano)[cite: 12].

🔍 Laboratorio de Desafíos y Troubleshooting (Entorno Proxmox)
💥 Caso Práctico: Bloqueo en la propagación de la GPO de fondo de pantalla por permisos NTFS en SYSVOL
Síntoma: Tras ejecutar de forma exitosa el script de automatización y validar mediante Get-GPOReport que la ruta del tapiz de escritorio apunta correctamente al recurso UNC (\\DC01\Compartir\Fondo-escritorio.jpg), los alumnos reinician sus máquinas clientes Windows 11 dentro de Proxmox y comprueban que el fondo permanece completamente en negro o con el tapiz por defecto del sistema[cite: 12].

Causa Raíz: Error de resolución en el contexto de seguridad informática. El script inyecta la directiva en la rama de usuario (HKCU), la cual se procesa bajo la identidad de la cuenta local del alumno[cite: 12]. Si la carpeta compartida o el archivo físico de la imagen no conceden explícitamente permisos de lectura al grupo de seguridad Usuarios del Dominio o al objeto especial Todos, el sistema operativo denegará el acceso al archivo en segundo plano durante el inicio de sesión, impidiendo que el explorador de Windows renderice la imagen.

Solución Operativa en Clase: El alumno debe auditar la lista de control de acceso (ACL) del recurso compartido de red y aplicar permisos de lectura estrictos para el correcto despliegue del entorno operativo:

```powershell
# Forzar la herencia y permisos de lectura para todos los usuarios autenticados en el recurso del fondo
Grant-SmbShareAccess -Name "Compartir" -AccountName "Usuarios del Dominio" -AccessRight Read -Force
```

📚 Referencias y Fuentes Consultadas
!!! info "Documentación Oficial y Autoría"
* Material Base: Basado de forma estricta en la presentación técnica institucional "UD3. Fundamentos de administración de Windows Server - GPO" estructurada por el Departamento de Informática del IES Marcos Zaragoza[cite: 12].
* Docente Catedrático / Autor: José Ramón Soria Nieto[cite: 12].
* Marco Académico: Temario de especialización teórica y práctica para el módulo de Administración de Sistemas Operativos (ASO) del Segundo Curso de Administración de Sistemas Informáticos en Red (2ASIR)[cite: 12].

!!! abstract "Soporte Institucional y Fondo Social Europeo"
* Organismo de Control: Generalitat Valenciana — Conselleria d'Educació, Investigació, Cultura i Esport[cite: 12].
* Fondo de Financiación de Infraestructura: Proyecto cofinanciado por la Unión Europea a través del Fondo Social Europeo (FSE)[cite: 12].
* «El FSE invierte en tu futuro» — Acciones orientadas al desarrollo técnico de alta calidad, la modernización de aulas informáticas y la capacitación profesional avanzada en infraestructuras operativas centralizadas[cite: 12].
