# Administración de políticas de grupo (GPO)

## 🎯 Relación con el currículo

> **RA1. Administra el servicio de directorio interpretando especificaciones e integrándolo en una red.**

Especialmente se trabajan estos criterios de la programación del módulo:

- **CE4-RA1.** Se ha realizado la configuración y personalización del servicio de directorio.
- **CE9-RA1.** Se han utilizado herramientas gráficas y comandos para la administración del servicio de directorio.
- **CE10-RA1.** Se ha documentado la estructura e implantación del servicio de directorio.

La automatización, administración remota e impresión pueden aportar evidencias de RA3, RA4, RA5 y RA7, según las operaciones realmente realizadas y sus comprobaciones. En particular, se trabajan restricciones de seguridad, guiones de automatización, herramientas remotas y gestión de colas; su valoración requiere los observables correspondientes. Utilizar una GPO no supone evaluar automáticamente todos los criterios de automatización o administración remota.

!!! info "Objetivo práctico"
    Configurar una GPO, justificar a quién afecta, demostrar su aplicación, diagnosticar un fallo y revertir el cambio. Utilizaremos principalmente **Administración de directivas de grupo (`gpmc.msc`)**. PowerShell permitirá consultar, crear y configurar GPO, generar informes y automatizar su mantenimiento. Se distinguirán los ajustes que admite cada herramienta.

---

## 1. Escenario y preparación

- **Dominio DNS:** `int.empresa.asix`.
- **Nombre NetBIOS de ejemplo:** `ASIX`. Comprueba el real con `(Get-ADDomain).NetBIOSName`; no lo deduzcas del nombre DNS.
- **Inicio de sesión:** `ASIX\usuario` o `usuario@int.empresa.asix`.
- **Nombre distinguido:** `DC=int,DC=empresa,DC=asix`.

Los ejemplos presuponen un controlador **DC01**, un cliente Windows 11 y esta estructura de UO:

```text
int.empresa.asix
├── Alumnado
│   └── ASIX
│       ├── asix1alu
│       └── asix2alu
├── Profesorado
└── Aulas
    ├── aula01
    └── aula02
```

Comprueba que existen los objetos y recursos antes de utilizarlos. Si el controlador tiene otro nombre, adapta las rutas con `DC01`. Los nombres de GPO y recursos son ejemplos de laboratorio.

### 1.1. Equipo de administración

1. Utiliza un Windows 11 de una edición compatible con RSAT, unido al dominio, o un servidor con experiencia de escritorio.
2. Comprueba que utiliza el DNS del dominio y localiza sus controladores.
3. En **Configuración → Características opcionales**, instala **RSAT: Herramientas de administración de directivas de grupo**. La ubicación puede variar entre versiones.
4. Instala también las herramientas de AD DS si necesitas administrar usuarios, grupos y UO.
5. Abre `gpmc.msc` con una cuenta autorizada. Crear GPO, editarlas y vincularlas requiere permisos diferentes que pueden delegarse.

!!! tip "Administrar Server Core gráficamente"
    El controlador puede ejecutar Windows Server Core. GPMC se ejecuta en el equipo de administración y trabaja sobre el dominio de forma remota. Server Core no obliga a configurar todas las GPO mediante scripts.

### 1.2. Preparar las pruebas

- Utiliza dos cuentas estándar de `asix2alu` y otra de `asix1alu`.
- Sitúa el objeto del cliente en `Aulas/aula01`, mediante **Usuarios y equipos de Active Directory (`dsa.msc`)**, si todavía está en `Computers`.
- Comprueba sus inicios de sesión antes de introducir restricciones.
- Comprueba la experiencia de usuario con cuentas estándar, no con la cuenta administrativa.

!!! warning "Usuarios y equipos tienen ubicaciones independientes"
    Mover un usuario no mueve la cuenta del ordenador en el que inicia sesión. Comprueba ambos objetos. Los contenedores genéricos `Users` y `Computers` no son UO y no admiten vínculos directos de GPO, aunque sus objetos pueden recibir las GPO del dominio.

---

## 2. Qué es una GPO

Una **GPO (Group Policy Object)** agrupa configuraciones que Windows procesa para usuarios y equipos. Los servidores también tienen cuentas de equipo y pueden recibir configuraciones.

Distinguimos:

- **Objeto GPO:** contiene configuraciones y propiedades; aparece en **Objetos de directiva de grupo**.
- **Vínculo:** asocia una GPO a un sitio, dominio o UO. Una GPO puede tener varios vínculos.
- **Ámbito efectivo:** destinatarios que reciben la GPO después de considerar herencia, permisos, filtros y estado.

Una GPO sin vínculos no despliega sus ajustes. Editar una GPO con varios vínculos modifica el mismo objeto para todos sus ámbitos.

### 2.1. Configuración del equipo y del usuario

- **Configuración del equipo:** se selecciona normalmente según la ubicación del objeto del ordenador. Ejemplos: seguridad y firewall.
- **Configuración del usuario:** se selecciona normalmente según la ubicación de su cuenta. Ejemplos: fondo, restricciones del Panel de control y unidades de red.

Una GPO solo de usuario, vinculada únicamente a la UO de ordenadores, no configura automáticamente a todos sus usuarios. Existe una excepción avanzada, el **procesamiento de bucle invertido (loopback)**, que permite seleccionar ajustes de usuario según el equipo. No se necesita para las prácticas básicas de esta página.

### 2.2. Directivas y preferencias

Las **directivas** establecen configuraciones administradas. Muchas impiden modificar la opción desde su interfaz habitual mientras están en vigor. Sus categorías principales son:

- **Configuración de software:** instalación administrada de paquetes compatibles.
- **Configuración de Windows:** seguridad, scripts, redirección de carpetas y otras funciones, según la rama.
- **Plantillas administrativas:** ajustes de Windows y aplicaciones descritos mediante ADMX y ADML.

Las **preferencias** despliegan unidades de red, archivos, accesos directos, tareas programadas y otros elementos. Generalmente admiten cambios del usuario, pero pueden volver a aplicar lo configurado en el siguiente procesamiento. No son simplemente opciones que el destinatario decide si recibe.

Las categorías **Configuración de Windows** y **Configuración del Panel de control** de las preferencias agrupan elementos configurables; no habilitan genéricamente la capacidad de configurar Windows.

!!! note "GPO y registro"
    Muchas plantillas administrativas se traducen en valores del registro, pero no todas las configuraciones funcionan así. Windows utiliza distintas extensiones para procesar seguridad, software, scripts y preferencias. `regedit` es el editor del registro, no el destino de las directivas.

### 2.3. GPO predeterminadas

- **Default Domain Policy:** vinculada a la raíz del dominio; se utiliza especialmente para su política de cuentas.
- **Default Domain Controllers Policy:** vinculada a **Domain Controllers**, donde se encuentran normalmente los controladores.

Crearemos GPO específicas para escritorio y restricciones, con nombres y comentarios claros, sin incorporar esos ajustes a las predeterminadas.

### 🎬 Vídeo demostración: Introducción a GPO

Vídeo complementario con la introducción teórica y práctica a los conceptos básicos de las directivas de grupo (GPO) en Active Directory.

<div class="video-embed">
  <iframe 
    src="https://www.youtube.com/embed/4rOScEiJ1ik" 
    title="Active Directory - Introducción GPO" 
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
    allowfullscreen>
  </iframe>
</div>

!!! info "Ver en YouTube"
    Si prefieres abrir el tutorial directamente en la plataforma o guardarlo en tus listas de reproducción, puedes acceder a través del siguiente enlace:  
    **[▶ Abrir vídeo directamente en YouTube](https://youtu.be/4rOScEiJ1ik)**

---

## 3. Primera práctica: fondo corporativo

**Objetivo:** aplicar un fondo a segundo sin afectar a primero.

### 3.1. Imagen y permisos

Prepara este recurso:

```text
\\DC01\Corporativo\Fondos\fondo-asix.jpg
```

Debe existir previamente. DC01 simplifica el laboratorio; si hay servidor de archivos dedicado, utiliza ese servidor.

1. Copia la imagen en la carpeta correspondiente.
2. En permisos del recurso compartido, concede **Lectura** a los destinatarios.
3. En **Seguridad**, comprueba permisos NTFS de lectura sobre carpeta y archivo.
4. Desde el cliente y con la cuenta estándar, abre la ruta UNC completa. Debes visualizarla sin introducir otras credenciales.

Ambos niveles de permisos se evalúan conjuntamente. Modificar uno no corrige necesariamente el otro. Los destinatarios necesitan lectura, no permiso para sustituir la imagen.

Para automatizar esta preparación desde **PowerShell** en el servidor (`DC01`):

```powershell
# 1. Crear las carpetas locales en el servidor (si no existen)
$rutaBase = 'C:\Corporativo'
$rutaFondos = 'C:\Corporativo\Fondos'

if (-not (Test-Path -LiteralPath $rutaFondos)) {
    New-Item -ItemType Directory -Path $rutaFondos -Force | Out-Null
}

# (Copia la imagen fondo-asix.jpg en $rutaFondos antes de continuar)

# 2. Crear o configurar el recurso compartido SMB con acceso de lectura
$recurso = Get-SmbShare -Name 'Corporativo' -ErrorAction SilentlyContinue
if (-not $recurso) {
    New-SmbShare -Name 'Corporativo' -Path $rutaBase `
        -ReadAccess 'Usuarios del Dominio' `
        -FullAccess 'Administradores' -ErrorAction Stop
} else {
    Grant-SmbShareAccess -Name 'Corporativo' -AccountName 'Usuarios del Dominio' `
        -AccessRight Read -Force
}

# 3. Verificar los permisos asignados al recurso
Get-SmbShareAccess -Name 'Corporativo'
```

!!! note "Permisos NTFS y herencia"
    En esta práctica no es necesario modificar la ACL de NTFS. Las carpetas creadas en `C:\` heredan automáticamente los permisos de `BUILTIN\Usuarios` (que incluye a los usuarios del dominio) con permisos de **Lectura y ejecución**, impidiendo además que un usuario estándar modifique o borre la imagen. Para escenarios avanzados con control de acceso restrictivo mediante ACLs de NTFS, consulta el [apartado 14](#14-recursos-compartidos-y-mapeo-por-grupos).

!!! tip "Comprobación del acceso desde el cliente"
    Desde el equipo cliente (Windows 11) y con la sesión iniciada por un usuario estándar del dominio, verifica que la ruta es accesible y legible:
    ```powershell
    Test-Path -LiteralPath '\\DC01\Corporativo\Fondos\fondo-asix.jpg'
    ```
    Si devuelve `True`, la directiva de GPO podrá leer la imagen y aplicar el fondo correctamente al iniciar sesión. En sistemas en inglés, sustituye `'Usuarios del Dominio'` por `'Domain Users'`.

### 3.2. Crear y configurar

1. En GPMC, despliega **Bosque → Dominios → int.empresa.asix**.
2. En **Objetos de directiva de grupo**, selecciona **Nuevo**.
3. Nómbrala `USR-ASIX2-FondoCorporativo`.
4. Abre **Editar**. En las propiedades del nodo raíz del editor añade un comentario sobre finalidad, destinatarios y dependencia del recurso.
5. Navega hasta:

```text
Configuración de usuario
└── Directivas
    └── Plantillas administrativas
        └── Active Desktop
            └── Active Desktop
                └── Tapiz del escritorio
```

Puede aparecer como **Desktop Wallpaper** con plantillas en inglés.

6. Selecciona **Habilitada** e introduce `\\DC01\Corporativo\Fondos\fondo-asix.jpg`.
7. Selecciona el estilo y lee la ayuda sobre requisitos y compatibilidad.

No necesitas buscar ni escribir manualmente claves del registro.

### 3.3. Vincular y comprobar

1. Localiza **Alumnado → ASIX → asix2alu** en GPMC.
2. Selecciona **Vincular un GPO existente** y elige `USR-ASIX2-FondoCorporativo`.
3. Comprueba **Vínculo habilitado** y revisa **Ámbito** y **Configuración**.
4. Actualiza las directivas en el cliente como indica el apartado 7. Cierra sesión y vuelve a entrar con el destinatario.
5. Comprueba fondo y GPO aplicadas.
6. Prueba la cuenta de `asix1alu`: esta GPO no debe aplicarse a ella.

!!! warning "Configurar no demuestra aplicación"
    La pestaña Configuración de GPMC muestra el contenido de la GPO. Para demostrar que llegó al cliente necesitas resultados del usuario y equipo afectados.

### 🎬 Vídeo demostración: Cambio de fondo de pantalla mediante GPO

Vídeo complementario con la demostración práctica paso a paso para configurar y aplicar un fondo corporativo mediante directivas de grupo (GPO) en Active Directory.

<div class="video-embed">
  <iframe 
    src="https://www.youtube.com/embed/kVoxQ9ZUynE" 
    title="Active Directory - GPO - Cambio de fondo de pantalla" 
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
    allowfullscreen>
  </iframe>
</div>

!!! info "Ver en YouTube"
    Si prefieres abrir el tutorial directamente en la plataforma o guardarlo en tus listas de reproducción, puedes acceder a través del siguiente enlace:  
    **[▶ Abrir vídeo directamente en YouTube](https://youtu.be/kVoxQ9ZUynE)**

---

## 4. Segunda práctica: restringir el Panel de control

**Objetivo:** impedir a segundo acceder al Panel de control y a Configuración.

1. Crea `USR-ASIX2-RestriccionPanelControl` y documenta su finalidad.
2. Edita:

```text
Configuración de usuario
└── Directivas
    └── Plantillas administrativas
        └── Panel de control
            └── Prohibir el acceso a Configuración de PC y a Panel de control
```

3. Selecciona **Habilitada**. Aquí habilitar activa una prohibición: lee siempre el nombre y la ayuda.
4. Vincula a `Alumnado/ASIX/asix2alu`.
5. Actualiza y comprueba resultado e informe con la cuenta estándar.
6. Comprueba que el usuario de primero no recibe la restricción.

### 4.1. Estados de una directiva

- **Habilitada:** aplica el comportamiento definido para ese estado.
- **Deshabilitada:** aplica el comportamiento definido como deshabilitado, que puede contradecir un ajuste heredado.
- **No configurada:** esta GPO no establece la opción; otra puede seguir configurándola.

No confundas estos estados con deshabilitar el vínculo o una rama de la GPO. Restringir una interfaz no sustituye permisos de seguridad ni convierte una cuenta administrativa en limitada.

### 🎬 Vídeo demostración: Restringir el Panel de control mediante GPO

Vídeo complementario con la demostración práctica paso a paso para prohibir el acceso al Panel de control y a Configuración mediante directivas de grupo (GPO) en Active Directory.

<div class="video-embed">
  <iframe 
    src="https://www.youtube.com/embed/G3ggUjwHUiw" 
    title="Active Directory - GPO - Restringir el Panel de control" 
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
    allowfullscreen>
  </iframe>
</div>

!!! info "Ver en YouTube"
    Si prefieres abrir el tutorial directamente en la plataforma o guardarlo en tus listas de reproducción, puedes acceder a través del siguiente enlace:  
    **[▶ Abrir vídeo directamente en YouTube](https://youtu.be/G3ggUjwHUiw)**

---

## 5. Tercera práctica: unidad de red mediante preferencias

**Objetivo:** conectar `P:` a los proyectos de segundo.

Prepara `\\DC01\ProyectosASIX2` y comprueba permisos compartidos y NTFS. La preferencia conecta la unidad; **no concede acceso a los archivos**.

1. Crea `USR-ASIX2-UnidadProyectos`.
2. Edita:

```text
Configuración de usuario
└── Preferencias
    └── Configuración de Windows
        └── Asignaciones de unidades
```

3. Selecciona **Nuevo → Unidad asignada**.
4. Configura **Actualizar**, ubicación `\\DC01\ProyectosASIX2`, letra `P:` y una etiqueta.
5. En **Comunes**, activa **Quitar este elemento cuando deje de aplicarse** si quieres retirarlo al salir del ámbito. Si el editor cambia automáticamente la acción a **Reemplazar**, conserva ese comportamiento y observa que puede recrear la conexión en cada procesamiento.
6. Vincula a `asix2alu`, actualiza y comprueba desde el Explorador.

### 5.1. Acciones y retirada

- **Crear:** crea el elemento si no existe.
- **Actualizar:** modifica propiedades indicadas y, para una unidad asignada, puede crearla si no existe.
- **Reemplazar:** elimina y vuelve a crear; puede interrumpir conexiones abiertas.
- **Eliminar:** elimina el elemento.

Las preferencias pueden conservar valores al dejar de aplicarse si no defines su retirada. Planifica y prueba la reversión. **Aplicar una vez y no volver a aplicar** tiene otra finalidad; no lo actives automáticamente.

La **segmentación a nivel de elemento** permite limitar una unidad por pertenencia a grupo sin filtrar toda la GPO. Se desarrolla en el apartado 14, junto con los permisos de los recursos y el mapeo de varias ubicaciones.

### 🎬 Vídeo demostración: Unidad de red mediante preferencias de GPO

Vídeo complementario con la demostración práctica paso a paso para asignar y configurar una unidad de red mediante preferencias de directivas de grupo (GPO) en Active Directory.

<div class="video-embed">
  <iframe 
    src="https://www.youtube.com/embed/dc4_vOHmmfI" 
    title="Active Directory - GPO - Unidad de red mediante preferencias" 
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
    allowfullscreen>
  </iframe>
</div>

!!! info "Ver en YouTube"
    Si prefieres abrir el tutorial directamente en la plataforma o guardarlo en tus listas de reproducción, puedes acceder a través del siguiente enlace:  
    **[▶ Abrir vídeo directamente en YouTube](https://youtu.be/dc4_vOHmmfI)**

---

## 6. Ámbito, herencia y filtrado

### 6.1. Orden de procesamiento

```text
Local → Sitio → Dominio → UO padre → UO hija
```

Los ajustes se acumulan. En un conflicto normalmente prevalece el procesado después; la última GPO no sustituye por completo las anteriores.

En un mismo contenedor, el vínculo con **orden 1** tiene mayor precedencia. Revisa los vínculos y **Herencia de directivas de grupo**.

- **Bloquear herencia:** evita recibir vínculos heredados no exigidos.
- **Exigido (Enforced):** protege el vínculo frente al bloqueo de herencia y evita que sus ajustes se sobrescriban desde niveles inferiores.

Antes de usarlos, revisa ubicación, vínculos y resultados. Los filtros siguen siendo relevantes aunque un vínculo esté exigido.

### 6.2. UO y grupos

Las GPO se vinculan a sitios, dominios o UO, no directamente a grupos. Los grupos de seguridad filtran qué usuarios o equipos, dentro del ámbito del vínculo, pueden aplicarlas.

Colocar un grupo en una UO no sitúa allí a sus miembros. Un filtro no amplía el ámbito. Los usuarios pueden recibir una GPO por herencia desde una UO superior, sin estar directamente en ella.

### 6.3. Filtrado por grupo

Utiliza la GPO del Panel de control:

1. En `dsa.msc`, crea el grupo global de seguridad `GG-GPO-RestriccionPanel`.
2. Añade solo una de las dos cuentas de prueba de `asix2alu`.
3. En **Ámbito → Filtrado de seguridad** de la GPO, añade el grupo.
4. Retira **Usuarios autentificados** del filtrado para quitar su aplicación general.
5. En **Delegación → Agregar**, añade de nuevo **Usuarios autentificados**, solo con **Lectura**. En las opciones avanzadas comprueba que no tenga **Aplicar directiva de grupo**.
6. Comprueba **Leer** y **Aplicar directiva de grupo** para el grupo destinatario.
7. Cierra sesión y vuelve a entrar para renovar pertenencias efectivas. Actualiza y comprueba ambas cuentas.

Solo la cuenta miembro debe recibir la restricción. Ambas siguen dentro del ámbito.

!!! warning "Lectura para los equipos"
    Recuperar las GPO de usuario requiere que la cuenta del equipo pueda leerlas. Lectura para Usuarios autenticados permite esa recuperación sin conceder aplicación a todos. Evita denegaciones explícitas como solución habitual: pueden anular permisos concedidos mediante otros grupos.

Los filtros WMI seleccionan equipos según características consultables y quedan como ampliación.

### 🎬 Vídeo demostración: Filtrado de seguridad por grupo en GPO

Vídeo complementario con la demostración práctica paso a paso de un ejemplo de filtrado de seguridad por grupo en directivas de grupo (GPO) de Active Directory.

<div class="video-embed">
  <iframe 
    src="https://www.youtube.com/embed/kJyh_DRc4j4" 
    title="Active Directory - GPO - Filtrado de seguridad por grupo" 
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
    allowfullscreen>
  </iframe>
</div>

!!! info "Ver en YouTube"
    Si prefieres abrir el tutorial directamente en la plataforma o guardarlo en tus listas de reproducción, puedes acceder a través del siguiente enlace:  
    **[▶ Abrir vídeo directamente en YouTube](https://youtu.be/kJyh_DRc4j4)**

---

## 7. Comprobación y diagnóstico

### 7.1. Actualizar desde el cliente

```console
gpupdate
```
Por defecto, Windows comprueba y actualiza las directivas en segundo plano periódicamente (normalmente cada 90 a 120 minutos, con un desfase aleatorio). Este comando fuerza a que esa comprobación ocurra en el instante en que lo ejecutas.

```console
gpupdate /force
```

El parámetro /force: A diferencia de ejecutar simplemente gpupdate (que solo descarga y aplica las políticas nuevas o modificadas), el modificador /force vuelve a descargar y reaplicar todas las directivas, tanto del equipo como del usuario, sin importar si han cambiado o no en el controlador de dominio.

Para un informe del usuario, ejecuta en **su propia sesión**, desde **Símbolo del sistema (`cmd.exe`)**:

```console
gpresult /scope user /h "%TEMP%\resultado-gpo-usuario.html" /f
```

Abre el archivo desde el Explorador. Para la rama de equipo, abre una consola elevada:

```console
gpresult /scope computer /h C:\Windows\Temp\resultado-gpo-equipo.html /f
```

Examina GPO aplicadas y filtradas y razones de exclusión. Si elevas con otra cuenta, no confundas sus resultados de usuario con los de la cuenta de prueba.

### 7.2. Resultados gráficos

1. En GPMC, abre **Resultados de directivas de grupo** e inicia su asistente desde el menú contextual.
2. Selecciona equipo y usuario que haya iniciado sesión en él.
3. Examina resumen y configuración resultante.

La consulta remota requiere permisos, servicios y reglas de firewall adecuados. Si falla, genera el informe local antes de concluir que la GPO no funciona.

**Modelado de directivas de grupo** simula escenarios; no sustituye resultados reales.

### 7.3. Secuencia de diagnóstico

1. **Identidad:** usuario y equipo utilizados.
2. **Ubicación:** UO de ambas cuentas.
3. **Vínculo:** ámbito correcto y vínculo habilitado.
4. **Contenido:** rama correcta y habilitada, configuración guardada.
5. **Filtros:** Leer y Aplicar para destinatarios, lectura del equipo y filtros WMI.
6. **Precedencia:** otra GPO ganadora, bloqueo de herencia o vínculos exigidos.
7. **Infraestructura:** DNS, autenticación, SYSVOL y replicación de AD y SYSVOL si hay varios controladores.
8. **Procesamiento:** necesidad de cerrar sesión o reiniciar y mensajes de informes y eventos.

En el cliente, abre **Visor de eventos → Registros de aplicaciones y servicios → Microsoft → Windows → GroupPolicy → Operational**. Conserva mensaje, hora e identificador del evento relevante.

### 7.4. Caso: el fondo no aparece

Un fondo negro o sin cambios no demuestra un fallo de permisos. Comprueba:

1. Que `USR-ASIX2-FondoCorporativo` figura como aplicada al usuario.
2. Que el resultado contiene la ruta correcta y no gana otra GPO.
3. Que el usuario puede abrir `\\DC01\Corporativo\Fondos\fondo-asix.jpg` desde su sesión.
4. Que DC01 se resuelve y el recurso está disponible.
5. Que permisos compartidos y NTFS permiten lectura.
6. Que se ha cerrado y reabierto la sesión.

Si la GPO se aplica pero la imagen no se abre, investiga ruta y permisos. Cambia solo lo necesario y repite la prueba.

---

## 8. Contraseñas y bloqueo

La política de cuentas tiene un tratamiento especial: **una GPO de contraseñas vinculada a la UO de usuarios no define una política distinta para esas cuentas del dominio**.

### 8.1. Configuración gráfica

Realiza antes una copia y anota valores actuales.

1. Localiza la GPO que define la política de cuentas, habitualmente **Default Domain Policy**, vinculada a `int.empresa.asix`.
2. Edita:

```text
Configuración del equipo
└── Directivas
    └── Configuración de Windows
        └── Configuración de seguridad
            └── Directivas de cuenta
                ├── Directiva de contraseñas
                └── Directiva de bloqueo de cuenta
```

3. Revisa longitud mínima, historial, vigencias mínima y máxima y complejidad.
4. Revisa conjuntamente umbral, duración de bloqueo y tiempo para restablecer el contador.
5. Evita valores contradictorios definidos desde varias GPO de dominio.

!!! note "Parámetros del laboratorio"
    Deben responder a los requisitos de la organización y a una política justificada. No existe una combinación universal. Un umbral muy bajo facilita bloqueos provocados; la caducidad periódica no garantiza seguridad. Las recomendaciones actuales incluyen evitar contraseñas débiles y gestionar adecuadamente las identidades.

La complejidad nativa comprueba categorías de caracteres y partes del nombre de cuenta; no exige necesariamente todos los tipos simultáneamente. Combina historial y vigencia mínima para evitar cambios sucesivos destinados a reutilizar una contraseña.

Una duración **0** requiere desbloqueo administrativo; una positiva permite desbloqueo al transcurrir ese tiempo. La ventana de observación determina cuándo se restablece el contador. Si la duración no es cero, debe ser igual o superior a esa ventana.

La nueva política no demuestra que todas las contraseñas existentes ya cumplan requisitos. Prueba un cambio con una cuenta destinada a ello.

### 8.2. Políticas diferentes dentro del dominio

Las **directivas de contraseña específicas (FGPP)** permiten requisitos distintos para usuarios o grupos globales de seguridad. Se administran desde **Centro de administración de Active Directory (`dsac.exe`) → System → Password Settings Container**.

No se asignan directamente a UO ni son GPO vinculadas a departamentos. Son una ampliación.

---

## 9. Mantenimiento y reversión

### 9.1. Copias desde GPMC

1. En **Objetos de directiva de grupo**, selecciona una GPO y **Hacer copia de seguridad**.
2. Elige una carpeta protegida y describe el estado guardado.
3. Para todas, utiliza **Hacer copia de seguridad de todo** sobre el contenedor.
4. Usa **Administrar copias de seguridad** para revisar y restaurar en el dominio de origen.

No sustituye una copia del dominio. Los vínculos se almacenan en contenedores de AD y **no se incluyen en la copia de la GPO**. Documenta destinos, orden y herencia.

### 9.2. Revertir

- **Deshabilitar el vínculo:** interrumpe ese vínculo; la GPO puede llegar por otros.
- **Eliminar el vínculo:** elimina la asociación y conserva el objeto.
- **Eliminar desde Objetos de directiva de grupo:** elimina la GPO y afecta a todos sus usos.
- **Restaurar una copia:** recupera un estado anterior; revisa después vínculos y resultados.

Comprueba otros destinatarios antes de revertir. Actualiza y verifica después. Algunas configuraciones y preferencias persisten; retirar un vínculo no garantiza recuperar todos los valores anteriores.

---

## 10. Plantillas y almacén central

Los **ADMX** describen ajustes; los **ADML** contienen recursos de idioma.

Sin almacén central, el editor utiliza:

```text
C:\Windows\PolicyDefinitions
```

Con almacén central, utiliza:

```text
\\int.empresa.asix\SYSVOL\int.empresa.asix\Policies\PolicyDefinitions
```

### 10.1. Preparación gráfica

1. Abre Policies en SYSVOL desde una cuenta autorizada.
2. Si existe un almacén, cópialo antes de actualizarlo. No mezcles versiones sin revisar compatibilidad.
3. Prepara una colección completa y coherente desde una versión adecuada de Windows o un paquete oficial de Microsoft.
4. Coloca `.admx` en `PolicyDefinitions` y `.adml` en carpetas como `es-ES` y `en-US`, según los idiomas de las consolas.
5. Añade plantillas de aplicaciones desde su fabricante, respetando dependencias e idiomas.
6. Reabre el editor y comprueba que indica que las definiciones proceden del almacén central. Si hay varios controladores, verifica replicación de SYSVOL.

Unifica plantillas utilizadas **al editar**. No instala aplicaciones ni distribuye plantillas a todos los clientes. Que aparezca una opción no implica compatibilidad con todos los sistemas: revisa **Compatible con** y documentación del fabricante.

### 🎬 Vídeo demostración: Introducción al almacén central de GPO (ADMX/ADML)

Vídeo complementario con la introducción y configuración del almacén central de plantillas administrativas (ADMX y ADML) para directivas de grupo (GPO) en Active Directory.

<div class="video-embed">
  <iframe 
    src="https://www.youtube.com/embed/kJyh_DRc4j4" 
    title="Active Directory - GPO - Introducción al almacén central" 
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
    allowfullscreen>
  </iframe>
</div>

!!! info "Ver en YouTube"
    Si prefieres abrir el tutorial directamente en la plataforma o guardarlo en tus listas de reproducción, puedes acceder a través del siguiente enlace:  
    **[▶ Abrir vídeo directamente en YouTube](https://youtu.be/kJyh_DRc4j4)**

---

## 11. PowerShell como complemento

Los ejemplos del módulo **GroupPolicy** utilizan **Windows PowerShell 5.1** en Windows con las herramientas instaladas. Comprueba por separado qué módulos y comandos funcionan en PowerShell 7; no cambies de intérprete sin verificar las dependencias. Windows Server Core y PowerShell 7 son conceptos diferentes.

### 11.1. Consultar

```powershell
Import-Module GroupPolicy

Get-GPO -All -Domain 'int.empresa.asix' |
    Select-Object DisplayName, GpoStatus, ModificationTime, Description

Get-GPO -Name 'USR-ASIX2-FondoCorporativo' -Domain 'int.empresa.asix'
```

Muestra objetos y propiedades, no aplicación efectiva.

### 11.2. Informe de configuración

```powershell
$carpetaInformes = Join-Path $env:USERPROFILE 'Documents\InformesGPO'
New-Item -ItemType Directory -Path $carpetaInformes -Force | Out-Null

$informeGpo = Join-Path $carpetaInformes 'FondoCorporativo.html'
Get-GPOReport -Name 'USR-ASIX2-FondoCorporativo' `
    -Domain 'int.empresa.asix' -ReportType Html -Path $informeGpo

Invoke-Item -LiteralPath $informeGpo
```

**Get-GPOReport** describe una GPO; **gpresult** informa de su procesamiento en el usuario o equipo.

### 11.3. Copiar todas las GPO

```powershell
$carpetaCopias = Join-Path $env:USERPROFILE 'Documents\CopiasGPO'
New-Item -ItemType Directory -Path $carpetaCopias -Force | Out-Null

Backup-GPO -All -Domain 'int.empresa.asix' -Path $carpetaCopias `
    -Comment 'Copia previa a cambios del laboratorio'
```

Comprueba el resultado y conserva copia en la ubicación protegida prevista. La carpeta local no debe ser la única copia.

### 11.4. Consultar contraseñas y bloqueo

Utiliza **ActiveDirectory**, no GroupPolicy:

```powershell
Import-Module ActiveDirectory
Get-ADDefaultDomainPasswordPolicy -Identity 'int.empresa.asix' |
    Select-Object MinPasswordLength, ComplexityEnabled, PasswordHistoryCount,
        MinPasswordAge, MaxPasswordAge, LockoutThreshold,
        LockoutDuration, LockoutObservationWindow
```

Muestra la política predeterminada. Con FGPP, un usuario puede tener otra política resultante.

Para crear y configurar GPO utilizaremos también `New-GPO`, `New-GPLink` y `Set-GPRegistryValue`, desarrollados en el apartado 12. El último configura ajustes basados en registro dentro de una GPO; no edita todas las clases de directivas ni modifica directamente el registro local del cliente.

---

## 12. Automatizar la creación y configuración de GPO

La consola ayuda a descubrir y comprender cada ajuste. PowerShell permite reproducir la configuración y comprobarla sin repetir operaciones manuales. Antes de automatizar, identifica el ámbito, el tipo de ajuste, sus dependencias y la forma de revertirlo.

### 12.1. Crear y vincular sin duplicar

Este ejemplo utiliza Windows PowerShell 5.1 con RSAT, los módulos **ActiveDirectory** y **GroupPolicy** y una cuenta autorizada. Se ejecuta en el equipo de administración, no en todos los clientes. La UO del ejemplo debe existir.

```powershell
Import-Module ActiveDirectory
Import-Module GroupPolicy

$dominio = Get-ADDomain
$nombreGpo = 'USR-Laboratorio-Escritorio'
$destino = "OU=asix2alu,OU=ASIX,OU=Alumnado,$($dominio.DistinguishedName)"

# Confirmar el destino antes de modificar vínculos.
Get-ADOrganizationalUnit -Identity $destino -ErrorAction Stop | Out-Null

# En un dominio de laboratorio, la consulta completa permite distinguir
# ausencia de GPO de un error de acceso, que debe detener el script.
$gpo = Get-GPO -All -Domain $dominio.DNSRoot -ErrorAction Stop |
    Where-Object DisplayName -eq $nombreGpo
if (-not $gpo) {
    $gpo = New-GPO -Name $nombreGpo -Domain $dominio.DNSRoot `
        -Comment 'Escritorio del laboratorio de segundo' -ErrorAction Stop
}

$vinculos = (Get-GPInheritance -Target $destino `
    -Domain $dominio.DNSRoot -ErrorAction Stop).GpoLinks
if ($gpo.Id -notin @($vinculos | ForEach-Object GpoId)) {
    New-GPLink -Guid $gpo.Id -Target $destino `
        -Domain $dominio.DNSRoot -LinkEnabled Yes -ErrorAction Stop | Out-Null
}
```

No es suficiente comprobar que existe el objeto: un vínculo existente puede estar deshabilitado. Revisa su estado y utiliza `Set-GPLink` si procede. Una ejecución repetible conserva lo correcto y corrige únicamente las diferencias previstas; no elimina y recrea toda la infraestructura.

### 12.2. Configurar ajustes basados en registro

La documentación de cada directiva indica ruta, nombre, tipo y valores. `HKCU` selecciona la rama de usuario y `HKLM` la de equipo **dentro de la GPO**. No son operaciones sobre el registro del equipo administrador.

Para conocer la clave del registro concreta (`Key`), el nombre del valor (`ValueName`) y los datos admitidos a los que corresponde cada directiva de plantillas administrativas, se puede consultar la hoja de cálculo Excel de referencia (*Group Policy Settings Reference Spreadsheet*) que publica oficialmente Microsoft para cada versión concreta de Windows y Windows Server, o bien inspeccionar directamente el archivo `.admx` que la define.

#### 🎬 Vídeo demostración: Claves de registro de las plantillas administrativas

Vídeo complementario sobre cómo localizar las claves y valores del registro asociados a las directivas de las plantillas administrativas para su configuración mediante PowerShell.

<div class="video-embed">
  <iframe 
    src="https://www.youtube.com/embed/iUB50Bj2EsU" 
    title="Active Directory - GPO - Claves de registro de las plantillas administrativas" 
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
    allowfullscreen>
  </iframe>
</div>

!!! info "Ver en YouTube"
    Si prefieres abrir el tutorial directamente en la plataforma o guardarlo en tus listas de reproducción, puedes acceder a través del siguiente enlace:  
    **[▶ Abrir vídeo directamente en YouTube](https://youtu.be/iUB50Bj2EsU)**

Continuando el ejemplo anterior:

```powershell
$clave = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System'

Set-GPRegistryValue -Guid $gpo.Id -Domain $dominio.DNSRoot `
    -Key $clave -ValueName 'Wallpaper' -Type String `
    -Value '\\DC01\Corporativo\Fondos\laboratorio.jpg'

Set-GPRegistryValue -Guid $gpo.Id -Domain $dominio.DNSRoot `
    -Key $clave -ValueName 'WallpaperStyle' -Type String -Value '2'

Get-GPRegistryValue -Guid $gpo.Id -Domain $dominio.DNSRoot -Key $clave
```

El valor de estilo del ejemplo representa estirar la imagen. Comprueba el resultado desde una sesión destinataria y conserva el informe. Si cambias la imagen, verifica primero que esa cuenta pueda abrirla.

!!! warning "Límites del módulo GroupPolicy"
    `Set-GPRegistryValue` no configura automáticamente permisos NTFS, directivas de seguridad, preferencias de unidades, instalación de paquetes o colas de impresión. Elige la herramienta de cada componente. No inventes valores del registro para sustituir una función que requiere otra extensión.

#### 🎬 Vídeo demostración: Crear GPO, editar claves y vincular con PowerShell

Vídeo complementario con la demostración práctica de cómo crear objetos de directiva de grupo (GPO), configurar claves de registro y vincularlas a unidades organizativas mediante PowerShell.

<div class="video-embed">
  <iframe 
    src="https://www.youtube.com/embed/OvzjKkdZbHU" 
    title="Active Directory - GPO - Crear GPO, editar claves y vincular con PowerShell" 
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
    allowfullscreen>
  </iframe>
</div>

!!! info "Ver en YouTube"
    Si prefieres abrir el tutorial directamente en la plataforma o guardarlo en tus listas de reproducción, puedes acceder a través del siguiente enlace:  
    **[▶ Abrir vídeo directamente en YouTube](https://youtu.be/OvzjKkdZbHU)**

### 12.3. Reutilizar configuración gráfica

Cuando una configuración no tenga un cmdlet adecuado:

1. Configura y prueba una GPO modelo con GPMC.
2. Haz una copia con `Backup-GPO`.
3. Conserva el identificador de la copia y un inventario de vínculos y filtros.
4. Para recuperar la GPO original en el mismo dominio, usa `Restore-GPO`.
5. Para llevar los ajustes a otra GPO, usa `Import-GPO`, revisando antes el destino: puede sustituir ajustes que ya contenga.
6. Reconstruye y verifica vínculos y permisos. Importar ajustes no reproduce automáticamente todo el despliegue.

Si cambian dominios, cuentas o rutas UNC, estudia las tablas de migración y revisa las dependencias. No edites manualmente los archivos XML de SYSVOL como método habitual de administración.

---

## 13. Política de cuentas mediante comandos

### 13.1. Consultar antes de cambiar

```powershell
Import-Module ActiveDirectory
$dominio = Get-ADDomain

$politica = Get-ADDefaultDomainPasswordPolicy -Identity $dominio.DNSRoot
$politica | Select-Object MinPasswordLength, PasswordHistoryCount,
    ComplexityEnabled, MinPasswordAge, MaxPasswordAge,
    LockoutThreshold, LockoutDuration, LockoutObservationWindow

Get-ADUser -Identity 'usuario.prueba' `
    -Properties PasswordNeverExpires, PasswordLastSet, LockedOut |
    Select-Object SamAccountName, PasswordNeverExpires, PasswordLastSet, LockedOut

Get-ADUserResultantPasswordPolicy -Identity 'usuario.prueba'
```

La última consulta devuelve la FGPP resultante, si la hay. Si no devuelve una, consulta la política predeterminada del dominio. Una cuenta con `PasswordNeverExpires` requiere atención al comprobar caducidad.

### 13.2. Modificar la política predeterminada

Ejemplo alternativo de laboratorio: longitud de 12 caracteres, historial de 6, vigencia mínima de 1 día, máxima de 90 días y bloqueo temporal después de 5 fallos.

```powershell
$ajustes = @{
    Identity                = $dominio.DNSRoot
    MinPasswordLength       = 12
    PasswordHistoryCount    = 6
    ComplexityEnabled       = $true
    MinPasswordAge          = New-TimeSpan -Days 1
    MaxPasswordAge          = New-TimeSpan -Days 90
    LockoutThreshold        = 5
    LockoutDuration         = New-TimeSpan -Minutes 20
    LockoutObservationWindow = New-TimeSpan -Minutes 10
}

Set-ADDefaultDomainPasswordPolicy @ajustes -WhatIf
# Tras revisar el efecto previsto, ejecutar sin -WhatIf en el laboratorio.
```

!!! warning "Modificar el dominio no equivale a editar una GPO"
    Este cmdlet modifica los atributos de política predeterminada del dominio; no escribe el contenido de la sección de seguridad de una GPO. Una GPO de dominio que defina esos ajustes puede volver a establecerlos al procesarse. Si administras la política mediante GPO, esa será la configuración de referencia: consulta sus ajustes y el resultado efectivo. Para automatizar su despliegue puedes importar una GPO modelo probada y reconstruir sus vínculos. No mantengas dos configuraciones contradictorias.

Para solicitar desbloqueo administrativo se utiliza duración cero (`[TimeSpan]::Zero`). Para desbloquear una cuenta de prueba:

```powershell
Unlock-ADAccount -Identity 'usuario.prueba'
```

No pruebes el bloqueo con la única cuenta administrativa ni con cuentas de servicios o tareas. La aplicación de nuevos requisitos no valida retroactivamente el contenido de las contraseñas existentes; prueba un cambio controlado. La complejidad nativa no sustituye un sistema de detección de contraseñas filtradas.

---

## 14. Recursos compartidos y mapeo por grupos

La solución tiene tres capas independientes: **crear la carpeta**, **autorizar el acceso SMB y NTFS** y **presentarla al usuario mediante una GPO**. La tercera no corrige las dos anteriores.

### 14.1. Preparar un recurso con PowerShell

Ejemplo en un servidor de archivos Windows llamado `FS-AULA`: carpeta `C:\Recursos\Material`, recurso `MaterialAula` y grupo de seguridad `GG_Laboratorio`. Son nombres didácticos que deben existir o crearse expresamente en un entorno de prueba.

Ejecuta localmente en ese servidor con privilegios administrativos. El ejemplo requiere el módulo ActiveDirectory para obtener el NetBIOS real; también puedes pasar ese dato como parámetro validado desde el equipo administrador.

```powershell
Import-Module ActiveDirectory
$netbios = (Get-ADDomain).NetBIOSName
$grupo = "$netbios\GG_Laboratorio"
$ruta = 'C:\Recursos\Material'
$nombre = 'MaterialAula'

# Verificar que el grupo existe y resolver los nombres según el idioma.
Get-ADGroup -Identity 'GG_Laboratorio' -ErrorAction Stop | Out-Null
$administradores = ([System.Security.Principal.SecurityIdentifier]'S-1-5-32-544').Translate([System.Security.Principal.NTAccount]).Value
$sistema = ([System.Security.Principal.SecurityIdentifier]'S-1-5-18').Translate([System.Security.Principal.NTAccount]).Value

if (-not (Test-Path -LiteralPath $ruta)) {
    New-Item -ItemType Directory -Path $ruta -ErrorAction Stop | Out-Null
}

# Aplicar una ACL prevista para esta carpeta exclusiva de laboratorio.
# No reutilizar sobre carpetas del sistema o con permisos que deban conservarse.
$acl = Get-Acl -LiteralPath $ruta
$acl.SetAccessRuleProtection($true, $false)
foreach ($regla in @($acl.Access)) {
    [void]$acl.RemoveAccessRuleSpecific($regla)
}
foreach ($entrada in @(
    @{ Cuenta = $administradores; Permiso = 'FullControl' },
    @{ Cuenta = $sistema; Permiso = 'FullControl' },
    @{ Cuenta = $grupo; Permiso = 'Modify' }
)) {
    $regla = [System.Security.AccessControl.FileSystemAccessRule]::new(
        $entrada.Cuenta, $entrada.Permiso,
        'ContainerInherit,ObjectInherit', 'None', 'Allow'
    )
    $acl.AddAccessRule($regla)
}
Set-Acl -LiteralPath $ruta -AclObject $acl

$recurso = Get-SmbShare -ErrorAction Stop |
    Where-Object Name -eq $nombre
if (-not $recurso) {
    New-SmbShare -Name $nombre -Path $ruta `
        -ChangeAccess $grupo -FullAccess $administradores -ErrorAction Stop
} elseif ($recurso.Path -ne $ruta) {
    throw 'El recurso existente apunta a otra carpeta; revisar antes de continuar.'
}

Get-SmbShareAccess -Name $nombre
(Get-Acl -LiteralPath $ruta).Access
```

`Modify` permite lectura, escritura y eliminación; comprueba si corresponde al uso previsto. Una ACL solo de lectura requiere otros permisos. La ACL nueva protege la carpeta del ejemplo, pero no normaliza automáticamente permisos explícitos que pudieran existir en archivos hijos de una carpeta ya utilizada: revisa esos archivos antes de afirmar que todo el contenido está protegido.

Si el recurso SMB ya existía, el ejemplo **no sustituye sus permisos**: inspecciona y ajusta con `Grant-SmbShareAccess` y `Revoke-SmbShareAccess`. No confundas poder repetir un comando sin duplicar un objeto con corregir cualquier configuración anterior.

Desde un cliente autorizado comprueba lectura, creación y eliminación de un archivo de prueba. Con otra cuenta estándar comprueba el rechazo por UNC. Conserva SYSTEM y los administradores; no uses una denegación a «Todos» para excluir al resto, pues también puede afectar a los destinatarios.

### 14.2. Varias unidades y segmentación por grupo

En una GPO de usuario vinculada a un ámbito que contenga a los usuarios de prueba:

1. Crea una preferencia de unidad `P:` hacia `\\FS-AULA\MaterialAula`.
2. En **Comunes → Segmentación a nivel de elemento → Destinatarios**, añade **Grupo de seguridad**.
3. Selecciona `GG_Laboratorio` y que la condición se refiera al **usuario**, no a la cuenta del equipo.
4. Si necesitas otro recurso, crea otro elemento con una letra libre, por ejemplo `R:` hacia `\\FS-COPIAS\Intercambio`.
5. Decide retirada, reconexión y acción conforme al apartado 5. No utilices la misma letra para dos ubicaciones simultáneas.
6. Comprueba dos usuarios en el mismo cliente y uno de ellos en otro cliente. Revisa conexiones persistentes de sesiones anteriores.

La segmentación de un elemento no filtra todas las demás opciones de la GPO. El filtrado de seguridad y la segmentación pueden combinarse, pero ambos deben permitir el resultado previsto.

Los mapeos pertenecen a una sesión de usuario. Una tarea como SYSTEM o una sesión remota no debe depender de que exista `P:`: empleará rutas locales o UNC y su propia identidad de acceso. SYSTEM utiliza la cuenta del equipo al acceder a recursos de dominio; no hereda las credenciales del usuario interactivo.

### 14.3. Acceso remoto a los servidores

Para repetir la preparación en varios servidores puedes enviar un bloque mediante `Invoke-Command`, pasando servidor, carpeta, nombre del recurso y grupo como datos. Resuelve lo necesario en el equipo administrador y pasa los valores al bloque remoto.

No supongas que una sesión remota en el servidor puede autenticarse después en un tercer equipo con la cuenta original: ese segundo acceso puede requerir resolver el problema de doble salto. Una prueba de acceso desde la sesión real del cliente aporta una evidencia distinta.

---

## 15. Administrar Microsoft Edge

### 15.1. Plantillas y alcance

1. Descarga las plantillas de directiva oficiales de **Microsoft Edge para empresas** y comprueba su versión.
2. Extrae `msedge.admx` y los recursos `msedge.adml` del idioma de administración.
3. Incorpóralos al almacén central del apartado 10 o al almacén local si todavía no existe uno central. Si existe el central, añadir archivos solo al local no cambia las plantillas que utiliza el editor del dominio.
4. Reabre GPMC. Localiza **Plantillas administrativas → Microsoft Edge** en la rama de usuario o equipo según el alcance elegido.

La rama obligatoria aplica ajustes administrados. **Microsoft Edge — Configuración predeterminada que los usuarios pueden invalidar** contiene ajustes recomendados y no produce la misma restricción. Edge debe estar instalado: copiar ADMX no instala el navegador.

### 15.2. Inicio, botón de inicio y nueva pestaña

Son acciones diferentes. Consulta por nombre técnico la directiva si cambia su traducción:

- `HomepageLocation`: URL del botón Inicio.
- `HomepageIsNewTabPage`: determina si ese botón abre la nueva pestaña en lugar de la URL configurada.
- `ShowHomeButton`: muestra el botón Inicio.
- `RestoreOnStartup`: comportamiento al arrancar el navegador.
- `RestoreOnStartupURLs`: lista de páginas que se abren cuando el comportamiento de inicio selecciona una lista de URL.
- `NewTabPageLocation`: otra directiva distinta; no se necesita para definir solo el inicio.

Prueba con una página pública como `https://learn.microsoft.com/` para separar un fallo de política de un fallo de la web interna. Configura después una dirección accesible de tu laboratorio si existe.

### 15.3. Extensiones

En **Microsoft Edge → Extensiones**, configura la lista de extensiones bloqueadas (`ExtensionInstallBlocklist`). Cada fila contiene un identificador; `*` representa todas las extensiones ordinarias. No introduzcas una URL de una tienda donde se pide el identificador de extensión.

La lista permitida (`ExtensionInstallAllowlist`) puede establecer excepciones y la instalación forzada (`ExtensionInstallForcelist`) tiene su propio comportamiento. Revisa también `ExtensionSettings`: varias políticas contradictorias pueden impedir el resultado esperado. El bloqueo general no equivale a eliminar cualquier componente integrado del navegador.

### 15.4. Ejemplo automatizado de políticas de equipo

Este ejemplo configura un navegador del laboratorio; la UO de equipos y la GPO deben existir. Reutiliza la lógica de creación y vinculación del apartado 12 adaptada a `Aulas/aula01`. No vincules ajustes de equipo solo a la UO de sus usuarios.

```powershell
Import-Module GroupPolicy
$nombreGpo = 'EQ-Aula-Navegador'
$dominioDns = (Get-ADDomain).DNSRoot
$base = 'HKLM\Software\Policies\Microsoft\Edge'
$url = 'https://learn.microsoft.com/'

$valores = @(
    @{ Nombre = 'HomepageLocation'; Tipo = 'String'; Dato = $url },
    @{ Nombre = 'HomepageIsNewTabPage'; Tipo = 'DWord'; Dato = 0 },
    @{ Nombre = 'ShowHomeButton'; Tipo = 'DWord'; Dato = 1 },
    @{ Nombre = 'RestoreOnStartup'; Tipo = 'DWord'; Dato = 4 }
)
foreach ($v in $valores) {
    Set-GPRegistryValue -Name $nombreGpo -Domain $dominioDns -Key $base `
        -ValueName $v.Nombre -Type $v.Tipo -Value $v.Dato
}
Set-GPRegistryValue -Name $nombreGpo -Domain $dominioDns `
    -Key "$base\RestoreOnStartupURLs" -ValueName '1' -Type String -Value $url
Set-GPRegistryValue -Name $nombreGpo -Domain $dominioDns `
    -Key "$base\ExtensionInstallBlocklist" -ValueName '1' -Type String -Value '*'
```

El valor `4` selecciona la lista de URL. Para una lista más larga se utilizan valores `1`, `2`, etc. Al reducir una lista, revisa y elimina los valores sobrantes de la GPO; sobrescribir el primero no elimina los demás. Los ADMX ayudan a editar e interpretar los ajustes, pero escribir una clave errónea seguirá produciendo una configuración incorrecta.

### 15.5. Verificación y diagnóstico

1. Ejecuta `gpupdate`, cierra Edge completamente y vuelve a abrirlo para probar el arranque.
2. Abre `edge://policy` y pulsa **Volver a cargar directivas**.
3. Comprueba nombre, valor, origen, ámbito, nivel y estado de cada política.
4. Prueba el botón Inicio, el arranque y una nueva pestaña por separado.
5. Prueba una extensión ordinaria que no figure en excepciones y registra el resultado.

Una GPO puede figurar como aplicada y contener una ruta o un tipo incorrecto que Edge no reconoce. No confundas informe de GPO, valor del registro y comportamiento efectivo de la aplicación.

---

## 16. Distribuir aplicaciones de forma controlada

### 16.1. Elegir el mecanismo

- **MSI administrado mediante GPO:** en Configuración de software se puede asignar un paquete compatible a equipos; su instalación se procesa normalmente al arrancar. Utiliza una ruta UNC accesible para las cuentas de equipo. Las asignaciones de usuario tienen otro ciclo de procesamiento.
- **EXE con parámetros del fabricante:** no se añade como si fuera un MSI. Se utiliza un script o una tarea con permisos adecuados. Los parámetros silenciosos son propios de cada producto.
- **Programa portable o instalación por usuario:** puede no requerir privilegios administrativos, pero no equivale a instalar un servicio para todo el equipo.

Antes de desplegar, prueba el instalador en una VM o cliente de laboratorio, revisa su procedencia, versión, firma y condiciones de uso. No extraigas contraseñas ni licencias a archivos compartidos.

### 16.2. Arranque, inicio de sesión e identidad

Un script de **inicio del equipo** suele ejecutarse como SYSTEM; un script de **inicio de sesión** se ejecuta como el usuario. El segundo no adquiere privilegios administrativos por estar distribuido mediante una GPO. Pertenecer a administradores tampoco garantiza que ese proceso tenga un token elevado con UAC.

Las tareas programadas separan tres decisiones:

1. **Destino:** en qué ordenadores se registra la tarea.
2. **Desencadenador:** qué evento la activa, por ejemplo el inicio de sesión de una cuenta concreta.
3. **Principal:** con qué identidad se ejecuta y qué permisos tiene.

Una tarea SYSTEM vinculada a la UO de clientes no conoce automáticamente el grupo del usuario que inicia sesión. Una condición de grupo de equipo comprueba el ordenador, no al usuario. Tampoco sirve comprobar la pertenencia de SYSTEM mediante `whoami /groups` para decidir si ese usuario es destinatario.

### 16.3. Patrón de laboratorio con usuarios piloto

Ejemplo: distribuir una herramienta aprobada cuando inicie sesión una de las cuentas de un grupo piloto. Primero prepara el instalador y el script en una carpeta local modificable solo por administradores y SYSTEM. Distribúyelos mediante preferencias de archivos de una GPO de equipo o mediante administración remota autorizada. No ejecutes con privilegios elevados un archivo que un usuario estándar pueda sustituir.

En el equipo administrador, genera la lista de cuentas del grupo, incluyendo miembros anidados:

```powershell
Import-Module ActiveDirectory
$netbios = (Get-ADDomain).NetBIOSName
$usuariosPiloto = @(Get-ADGroupMember -Identity 'GG_PilotoApps' -Recursive |
    Where-Object objectClass -eq 'user' |
    ForEach-Object { "$netbios\$($_.SamAccountName)" })
if ($usuariosPiloto.Count -eq 0) {
    throw 'El grupo piloto no tiene cuentas de usuario.'
}
```

En cada cliente piloto, desde una consola elevada o un bloque remoto administrativo, utiliza esa lista como dato de entrada para registrar la tarea:

```powershell
# $usuariosPiloto debe contener la lista resuelta anteriormente.
# Los archivos indicados deben haberse distribuido antes.
$disparadores = @($usuariosPiloto | ForEach-Object {
    New-ScheduledTaskTrigger -AtLogOn -User $_
})
$accion = New-ScheduledTaskAction `
    -Execute "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -Argument '-NoProfile -NonInteractive -File "C:\ProgramData\Aula\Instalar-Herramienta.ps1"'
$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' `
    -LogonType ServiceAccount -RunLevel Highest
$opciones = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 15)

Register-ScheduledTask -TaskName 'Aula-InstalarHerramienta' `
    -Action $accion -Trigger $disparadores -Principal $principal `
    -Settings $opciones -Force
```

Este registro no solicita la contraseña de una cuenta administrativa. SYSTEM ya es una identidad local de servicio. Se puede distribuir una tarea equivalente mediante preferencias de GPO en **Configuración del equipo → Preferencias → Configuración del Panel de control → Tareas programadas**. Configura explícitamente los usuarios de los desencadenadores; no dejes «cualquier usuario» esperando que se filtre solo.

!!! warning "La lista es una instantánea del grupo"
    El patrón resuelve las pertenencias al preparar el despliegue. Si cambian los miembros del grupo, debes regenerar y redistribuir los desencadenadores antes de volver a probar. Para autorización dinámica se necesita un mecanismo adicional que identifique de forma fiable la sesión que activó la tarea y compruebe sus permisos actuales. No uses un archivo de solicitud escribible por cualquier usuario como prueba suficiente de autorización. El Programador de tareas admite un número limitado de desencadenadores; este patrón está pensado para un grupo pequeño de laboratorio.

Las tareas y sus archivos necesitan una política de actualización y retirada. Filtrar una GPO de usuario no elimina por sí mismo una tarea privilegiada que ya estaba registrada por otra vía.

### 16.4. Diseñar el instalador repetible

El script local `Instalar-Herramienta.ps1` deberá:

1. Comprobar si la versión requerida ya está instalada. Utiliza la ruta, versión, clave de desinstalación o identificador documentado del producto; evita `Win32_Product`, que puede provocar verificaciones y reparaciones MSI.
2. Verificar que el instalador esperado existe y comprobar su firma o hash conocido.
3. Ejecutarlo con argumentos oficiales, esperar a que finalice y registrar su código de salida.
4. Volver a comprobar la instalación: no crear una marca de éxito solo porque se lanzó el proceso.
5. Conservar un registro protegido, sin secretos, y terminar sin reinstalar cuando la versión correcta esté presente.

Para un MSI de prueba ya obtenido y validado, el núcleo de ejecución puede ser:

```powershell
$paquete = 'C:\ProgramData\Aula\Paquetes\Herramienta.msi'
$registro = 'C:\ProgramData\Aula\instalacion-herramienta.log'
if (-not (Test-Path -LiteralPath $paquete)) { throw 'Falta el paquete local.' }

$argumentos = '/i "{0}" /qn /norestart /L*v "{1}"' -f $paquete, $registro
$proceso = Start-Process -FilePath "$env:SystemRoot\System32\msiexec.exe" `
    -ArgumentList $argumentos -Wait -PassThru
if ($proceso.ExitCode -notin 0, 3010) {
    throw "Windows Installer devolvió $($proceso.ExitCode). Consulta el registro."
}
# 3010 indica éxito con reinicio necesario; planificarlo, no forzarlo aquí.
# Añadir aquí la comprobación específica del producto instalado.
```

Este fragmento enseña el control del proceso y no es un instalador completo para cualquier aplicación. Un EXE requiere adaptar ejecutable, argumentos, detección y códigos según su fabricante. «Silencioso» no significa «elevado» ni «sin errores».

### 16.5. Comprobar la selección

Prueba una cuenta destinataria, otra no destinataria y una segunda sesión de la primera. El cliente debe partir de un estado conocido cuando compruebes quién activa la instalación. Revisa historial de la tarea, código de salida, registro y detección posterior.

Instalar para el equipo al iniciar sesión una persona autorizada no restringe necesariamente quién puede utilizar después la aplicación. Si se requiere control de ejecución por usuario, hay que estudiar reglas de control de aplicaciones y su alcance como una decisión adicional.

---

## 17. Impresoras compartidas y GPO

### 17.1. Servidor, cola y conexión

El **servidor de impresión** administra colas; una **cola o impresora lógica** relaciona controlador, puerto y permisos; la **conexión del cliente** permite enviarle trabajos. Publicar una cola y conectar los clientes son operaciones diferentes.

Utiliza preferentemente un servidor miembro de laboratorio y conserva los otros servicios que aloje. Instala el rol desde administración remota o, en ese servidor Windows, mediante PowerShell elevado:

```powershell
Install-WindowsFeature Print-Server -IncludeManagementTools
Get-WindowsFeature Print-Server
Get-Service Spooler
Get-PrinterDriver | Select-Object Name, Manufacturer
```

En el cliente de administración puedes utilizar **Administración de impresión (`printmanagement.msc`)** con las herramientas RSAT correspondientes. Server Core no necesita un escritorio para alojar la cola.

### 17.2. Crear una cola de laboratorio

En Administración de impresión:

1. Agrega el servidor, por ejemplo `PRN-AULA`.
2. Comprueba e instala un controlador oficial y compatible con servidor y clientes.
3. Crea la cola, seleccionando el puerto adecuado para el destino real. Un puerto TCP/IP corresponde a un dispositivo de red; un LocalPort no crea por sí solo una impresora física.
4. Comparte la cola como `IMP_BIBLIOTECA` y anota `\\PRN-AULA\IMP_BIBLIOTECA`.
5. En **Seguridad**, concede **Imprimir** a los grupos destinatarios. Distingue **Administrar esta impresora** y **Administrar documentos**, que no deben concederse a todos los usuarios.

Si utilizas un puerto local ficticio para estudiar colas sin hardware, documenta que no habrá papel y que el trabajo puede quedar retenido o en error. No confundas una cola visible con una impresión física completada.

Consultas y operaciones de ejemplo, ejecutadas donde corresponda y con los permisos necesarios:

```powershell
# En el servidor de impresión.
Get-Printer | Select-Object Name, Shared, ShareName, DriverName, PortName
Get-PrinterPort
Get-PrintJob -PrinterName 'IMP_BIBLIOTECA'

# En la sesión de un cliente autorizado: prueba manual previa a la GPO.
Add-Printer -ConnectionName '\\PRN-AULA\IMP_BIBLIOTECA'
Get-Printer | Select-Object Name, Type, DriverName
```

Para automatizar la creación se utilizan `Add-PrinterPort`, `Add-PrinterDriver`, `Add-Printer` y `Set-Printer`, después de comprobar los objetos existentes. `Add-PrinterDriver` no descarga mágicamente un paquete ausente: puede requerir preparar antes el controlador en el almacén del sistema.

### 17.3. Desplegar la conexión

En una GPO de usuario destinada a la UO adecuada:

```text
Configuración de usuario
└── Preferencias
    └── Configuración del Panel de control
        └── Impresoras
```

1. Crea **Nueva → Impresora compartida**, con acción **Actualizar**.
2. Introduce la ruta UNC completa.
3. Segmenta por grupo si solo debe conectarse para ciertos usuarios.
4. Decide si debe ser predeterminada y cómo se retirará al dejar de aplicarse.
5. Actualiza y prueba tras iniciar sesión en dos clientes.

También existe **Implementar con directiva de grupo** desde Administración de impresión, donde se elige aplicación por usuario o por equipo. No mezcles varios mecanismos para la misma conexión sin revisar duplicados y retirada. Para conectar por equipo, asegúrate de que el mecanismo elegido admite ese alcance y vincúlalo a los equipos, no solo a las cuentas de usuario.

### 17.4. Controladores y permisos administrativos

En Windows actualizado, una conexión puede requerir que un administrador instale o actualice el controlador. Recibir la GPO no garantiza que un usuario estándar pueda hacer esa instalación.

Prepara el controlador con una identidad autorizada y prueba después la conexión con una cuenta estándar. Revisa compatibilidad, firma y políticas Point and Print. No uses como arreglo general desactivar las restricciones de instalación de controladores o permitir servidores de impresión arbitrarios.

Diagnostica por capas: resolución del servidor, acceso de red, servicio Spooler, permisos de cola, controlador, conexión y trabajo. Obtén evidencia de **Microsoft → Windows → PrintService**, habilitando su registro operativo si necesitas seguir trabajos.

---

## 18. Mantener el servicio y demostrar el resultado

Una configuración centralizada puede afectar a cuentas de servicio, tareas, recursos y aplicaciones anteriores. Antes y después de un cambio comprueba los servicios que ya funcionaban; introducir una política no justifica perder acceso remoto o interrumpir otra automatización.

Para cada prueba registra:

- Identidad y equipo, incluida la identidad real si ejecuta una tarea o servicio.
- GPO, vínculo, filtros y rama utilizados.
- Estado previo y comportamiento esperado.
- Resultado efectivo y evidencia pertinente: informe, evento, acceso, versión instalada o trabajo de impresión.
- Resultado con un destinatario excluido.
- Reversión y comprobación posterior.

Prueba también cambios de usuario en un mismo ordenador. Una unidad, una impresora o un programa pueden permanecer después de retirar una política. Los informes de configuración no sustituyen comprobar el comportamiento y la ausencia de efectos en usuarios excluidos.

---

## 19. Propuesta de práctica de consolidación

Estas actividades permiten practicar y transferir las técnicas a otros escenarios. No constituyen una entrega obligatoria por sí mismas.

1. Despliega las tres GPO de usuario sobre `asix2alu` y demuestra que primero queda fuera del ámbito.
2. Limita la restricción mediante grupo y explica sus permisos.
3. Crea una GPO de equipo de prueba. En **Configuración del equipo → Directivas → Plantillas administrativas → Componentes de Windows → Directivas de reproducción automática**, localiza **Desactivar reproducción automática**. Configúrala, lee su ayuda, vincúlala a `Aulas/aula01` y comprueba resultados de equipo. Los nombres pueden variar con idioma y plantillas.
4. Provoca un fallo controlado: deshabilita un vínculo o utiliza temporalmente una imagen inexistente. Diagnostica antes de corregir.
5. Realiza una copia y prueba la reversión de un cambio.
6. Crea una GPO mediante PowerShell y comprueba qué ocurre al ejecutar de nuevo el script.
7. Presenta dos recursos con letras distintas a un grupo piloto y verifica la exclusión de una cuenta estándar.
8. Configura Edge con una página pública y explica la diferencia entre inicio, botón Inicio y nueva pestaña.
9. En un cliente de prueba, registra una tarea elevada activada por las cuentas piloto y comprueba los registros con y sin el destinatario. Utiliza un instalador de laboratorio aprobado.
10. Conecta una cola de impresión mediante GPO y diagnostica un trabajo retenido sin confundir conexión e impresión física.

Documenta usuario, equipo, UO, GPO, configuración, resultado esperado y observado. Adjunta evidencia y explica por qué demuestra el comportamiento. Una captura del editor por sí sola no acredita aplicación.

---

## 📚 Referencias y Fuentes Consultadas

!!! info "Documentación Oficial y Autoría"
    * **Material Base:** Basado en la presentación didáctica *"UD3. Fundamentos de administración de Windows Server - Políticas de grupo GPO"*, desarrollada por el Departamento de Informática del **IES Marcos Zaragoza**.
    * **Docente / Autor:** José Ramón Soria Nieto.
    * **Marco Curricular:** Módulo profesional de *Administración de Sistemas Operativos (ASO)*, 2.º Curso del Ciclo Formativo de Grado Superior en *Administración de Sistemas Informáticos en Red (2ASIR / 2ASIX)*.
    * **Metodología y Contenidos:** Reorganización y ampliación de contenidos para administración con GPMC y PowerShell, recursos compartidos, aplicaciones, impresión, comprobación efectiva y reversión en laboratorio.

!!! abstract "Soporte Institucional y Fondo Social Europeo"
    * **Órgano Regulador:** Generalitat Valenciana — Conselleria d'Educació, Cultura i Esport.
    * **Acreditación de Financiación:** Proyecto educativo y tecnológico cofinanciado por la **Unión Europea** a través del **Fondo Social Europeo (FSE)**.
    * *«El FSE invierte en tu futuro»* — Acciones destinadas a impulsar la educación digital avanzada, la modernización de entornos y laboratorios informáticos de Formación Profesional y la capacitación técnica cualificada en infraestructuras de red.

### Documentación técnica y Microsoft Learn

Para profundizar en la arquitectura, ciclo de vida, resolución de incidencias y administración automatizada de directivas de grupo:

* **Arquitectura, Procesamiento y Ámbito:**
    * [Group Policy processing — Procesamiento y precedencia de directivas](https://learn.microsoft.com/es-es/windows-server/identity/ad-ds/manage/group-policy/group-policy-processing)
    * [Group Policy scope — Ámbito, vinculación y filtrado de seguridad](https://learn.microsoft.com/es-es/windows-server/identity/ad-ds/manage/group-policy/group-policy-scope)
    * [Group Policy Preferences — Preferencias de directiva de grupo](https://learn.microsoft.com/es-es/windows-server/identity/ad-ds/manage/group-policy/group-policy-preferences)
* **Plantillas administrativas y Directivas de seguridad:**
    * [Almacén central para plantillas administrativas (ADMX/ADML)](https://learn.microsoft.com/es-es/troubleshoot/windows-client/group-policy/create-and-manage-central-store)
    * [Configuración de directivas de contraseñas de dominio](https://learn.microsoft.com/es-es/windows/security/threat-protection/security-policy-settings/password-policy)
    * [Guía y preguntas frecuentes sobre directivas de contraseñas](https://learn.microsoft.com/es-es/entra/identity/authentication/tutorial-password-policy-overview-frequently-asked-questions)
* **Mantenimiento, Copias de seguridad y Diagnóstico:**
    * [Copia de seguridad, restauración y migración de directivas de grupo](https://learn.microsoft.com/es-es/windows-server/identity/ad-ds/manage/group-policy/group-policy-backup-restore)
    * [Resolución de problemas de lectura del objeto equipo para GPO de usuario](https://learn.microsoft.com/es-es/troubleshoot/windows-server/group-policy/cannot-apply-user-gpo-when-computer-objects-dont-have-read-permissions)
* **Automatización con PowerShell (Módulo GroupPolicy):**
    * [Get-GPOReport — Generación de informes detallados de directivas](https://learn.microsoft.com/powershell/module/grouppolicy/get-gporeport)
    * [Backup-GPO — Copia de seguridad de directivas de grupo](https://learn.microsoft.com/powershell/module/grouppolicy/backup-gpo)

!!! note "Plantillas administrativas de terceros"
    Para el despliegue y control de aplicaciones de terceros (por ejemplo, Google Chrome, Mozilla Firefox, Adobe Reader, etc.), descarga e instala las plantillas administrativas oficiales (`.admx` y `.adml`) facilitadas por sus respectivos fabricantes. Los catálogos o repositorios externos no oficiales no sustituyen la documentación de la versión utilizada.


### Referencias de los procedimientos ampliados

- [Set-GPRegistryValue y ajustes basados en registro](https://learn.microsoft.com/powershell/module/grouppolicy/set-gpregistryvalue).
- [Import-GPO y reutilización de configuraciones](https://learn.microsoft.com/powershell/module/grouppolicy/import-gpo).
- [Política predeterminada de contraseñas con ActiveDirectory](https://learn.microsoft.com/powershell/module/activedirectory/set-addefaultdomainpasswordpolicy).
- [Creación de recursos SMB con New-SmbShare](https://learn.microsoft.com/powershell/module/smbshare/new-smbshare).
- [Preferencias y segmentación a nivel de elemento](https://learn.microsoft.com/windows-server/identity/ad-ds/manage/group-policy/group-policy-preferences).
- [Configuración de Edge mediante GPO y plantillas](https://learn.microsoft.com/deployedge/configure-microsoft-edge).
- [Catálogo de políticas de Edge y valores del registro](https://learn.microsoft.com/deployedge/microsoft-edge-policies).
- [Página del botón Inicio en Edge](https://learn.microsoft.com/deployedge/microsoft-edge-policies/HomepageLocation).
- [Comportamiento de arranque de Edge](https://learn.microsoft.com/deployedge/microsoft-edge-policies/RestoreOnStartup).
- [Administración de extensiones de Edge](https://learn.microsoft.com/deployedge/microsoft-edge-manage-extensions-policies).
- [Desencadenadores del Programador de tareas](https://learn.microsoft.com/powershell/module/scheduledtasks/new-scheduledtasktrigger).
- [Registro de tareas y principales de ejecución](https://learn.microsoft.com/powershell/module/scheduledtasks/register-scheduledtask).
- [Opciones estándar de Windows Installer](https://learn.microsoft.com/windows/win32/msi/standard-installer-command-line-options).
- [Administración de impresoras con PowerShell](https://learn.microsoft.com/powershell/module/printmanagement/add-printer).
- [Point and Print y paquetes de controladores](https://learn.microsoft.com/windows-hardware/drivers/print/point-and-print-with-driver-packages).
