# Administración de políticas de grupo (GPO)

## 🎯 Relación con el currículo

> **RA1. Administra el servicio de directorio interpretando especificaciones e integrándolo en una red.**

Especialmente se trabajan estos criterios de la programación del módulo:

- **CE4-RA1.** Se ha realizado la configuración y personalización del servicio de directorio.
- **CE9-RA1.** Se han utilizado herramientas gráficas y comandos para la administración del servicio de directorio.
- **CE10-RA1.** Se ha documentado la estructura e implantación del servicio de directorio.

El uso complementario de scripts puede contribuir al RA7, según la actividad. Utilizar una GPO no supone evaluar automáticamente todos los criterios de automatización o administración remota.

!!! info "Objetivo práctico"
    Configurar una GPO, justificar a quién afecta, demostrar su aplicación, diagnosticar un fallo y revertir el cambio. Utilizaremos principalmente **Administración de directivas de grupo (`gpmc.msc`)**. PowerShell será un complemento para consultas, informes y copias de seguridad.

---

## 1. Escenario y preparación

- **Dominio DNS:** `int.empresa.asix`.
- **Nombre NetBIOS:** `ASIX`.
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
        └── Escritorio
            └── Escritorio
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

Como ampliación, la **segmentación a nivel de elemento** permite limitar una unidad por pertenencia a grupo sin filtrar toda la GPO.

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
4. Retira **Usuarios autenticados** del filtrado para quitar su aplicación general.
5. En **Delegación → Agregar**, añade de nuevo **Usuarios autenticados**, solo con **Lectura**. En las opciones avanzadas comprueba que no tenga **Aplicar directiva de grupo**.
6. Comprueba **Leer** y **Aplicar directiva de grupo** para el grupo destinatario.
7. Cierra sesión y vuelve a entrar para renovar pertenencias efectivas. Actualiza y comprueba ambas cuentas.

Solo la cuenta miembro debe recibir la restricción. Ambas siguen dentro del ámbito.

!!! warning "Lectura para los equipos"
    Recuperar las GPO de usuario requiere que la cuenta del equipo pueda leerlas. Lectura para Usuarios autenticados permite esa recuperación sin conceder aplicación a todos. Evita denegaciones explícitas como solución habitual: pueden anular permisos concedidos mediante otros grupos.

Los filtros WMI seleccionan equipos según características consultables y quedan como ampliación.

---

## 7. Comprobación y diagnóstico

### 7.1. Actualizar desde el cliente

```console
gpupdate /force
```

Solicita reprocesar directivas; no repara DNS, permisos ni replicación. Algunas requieren cerrar sesión o reiniciar: atiende los mensajes.

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
    Deben responder al enunciado y a una política justificada. No existe una combinación universal. Un umbral muy bajo facilita bloqueos provocados; la caducidad periódica no garantiza seguridad. Las recomendaciones actuales incluyen evitar contraseñas débiles y gestionar adecuadamente las identidades.

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

---

## 11. PowerShell como complemento

Utilizaremos **Windows PowerShell 5.1** en Windows con las herramientas instaladas. Windows Server Core y PowerShell 7 son conceptos diferentes.

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

Como ampliación: `New-GPO`, `New-GPLink` y `Set-GPRegistryValue`. El último configura ajustes basados en registro dentro de una GPO; no edita todas las clases de directivas ni modifica directamente el registro local del cliente.

---

## 12. Propuesta de práctica de consolidación

Es una propuesta sobre los apuntes, no un nuevo entregable obligatorio de los sprints.

1. Despliega las tres GPO de usuario sobre `asix2alu` y demuestra que primero queda fuera del ámbito.
2. Limita la restricción mediante grupo y explica sus permisos.
3. Crea una GPO de equipo de prueba. En **Configuración del equipo → Directivas → Plantillas administrativas → Componentes de Windows → Directivas de reproducción automática**, localiza **Desactivar reproducción automática**. Configúrala, lee su ayuda, vincúlala a `Aulas/aula01` y comprueba resultados de equipo. Los nombres pueden variar con idioma y plantillas.
4. Provoca un fallo controlado: deshabilita un vínculo o utiliza temporalmente una imagen inexistente. Diagnostica antes de corregir.
5. Realiza una copia y prueba la reversión de un cambio.

Documenta usuario, equipo, UO, GPO, configuración, resultado esperado y observado. Adjunta evidencia y explica por qué demuestra el comportamiento. Una captura del editor por sí sola no acredita aplicación.

---

## 📚 Referencias y Fuentes Consultadas

!!! info "Documentación Oficial y Autoría"
    * **Material Base:** Basado en la presentación didáctica *"UD3. Fundamentos de administración de Windows Server - Políticas de grupo GPO"*, desarrollada por el Departamento de Informática del **IES Marcos Zaragoza**.
    * **Docente / Autor:** José Ramón Soria Nieto.
    * **Marco Curricular:** Módulo profesional de *Administración de Sistemas Operativos (ASO)*, 2.º Curso del Ciclo Formativo de Grado Superior en *Administración de Sistemas Informáticos en Red (2ASIR / 2ASIX)*.
    * **Metodología y Contenidos:** Reorganización y ampliación de contenidos para administración gráfica (`gpmc.msc`), comprobación práctica en laboratorio y automatización complementaria con PowerShell.

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
