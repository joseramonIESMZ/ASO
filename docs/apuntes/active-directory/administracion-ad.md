# Administración de Active Directory

Una vez instalado el servicio **Active Directory Domain Services (AD DS)**, creado el dominio y definida su estructura mediante **Unidades Organizativas (UO), usuarios, grupos y equipos**, comienza el trabajo habitual de administración.

En un entorno empresarial, Active Directory no es una infraestructura estática. Los usuarios cambian de departamento, se incorporan nuevos trabajadores, se retiran equipos, se modifican permisos, aparecen incidencias de autenticación y los controladores de dominio deben mantenerse operativos.

En este apartado se trabajará la administración cotidiana del directorio, prestando especial atención a:

- mantenimiento de usuarios, grupos y equipos;
- administración de Unidades Organizativas;
- administración del dominio y del bosque;
- controladores de dominio;
- roles FSMO;
- replicación;
- delegación administrativa;
- comprobación del estado del servicio;
- diagnóstico y resolución de problemas.

---

## 🎯 Relación con el currículo

Este contenido se relaciona principalmente con el siguiente resultado de aprendizaje:

> **RA1. Administra el servicio de directorio interpretando especificaciones e integrándolo en una red.**

Especialmente se trabajan los siguientes criterios de evaluación:

- **CE4-RA1.** Se ha realizado la configuración y personalización del servicio de directorio.
- **CE7-RA1.** Se ha utilizado el servicio de directorio como mecanismo de acreditación centralizada de los usuarios en una red.
- **CE9-RA1.** Se han utilizado herramientas gráficas y comandos para la administración del servicio de directorio.
- **CE10-RA1.** Se ha documentado la estructura e implantación del servicio de directorio.

!!! info "Administrar no es solamente crear"\
Instalar un dominio y crear sus objetos es únicamente el comienzo. En una empresa real, la mayor parte del trabajo de un administrador consiste en **mantener, modificar, comprobar y solucionar problemas** sobre una infraestructura que ya existe.

---

## 1. Administración de objetos del directorio

Los objetos creados en Active Directory tienen un **ciclo de vida**.

Por ejemplo, una cuenta de usuario puede pasar por diferentes situaciones:

```text
Alta → Uso normal → Cambio de departamento → Bloqueo
     → Baja temporal → Reactivación → Baja definitiva
```

Un administrador debe ser capaz de gestionar estas situaciones sin tener que eliminar y volver a crear constantemente los objetos.

Para trabajar mediante PowerShell utilizaremos principalmente el módulo:

```powershell
Import-Module ActiveDirectory
```

Podemos comprobar los comandos disponibles mediante:

```powershell
Get-Command -Module ActiveDirectory
```

---

### 1.1. Consulta de usuarios

```powershell
Get-ADUser -Identity "juan.perez"
```

Por defecto no se muestran todas sus propiedades.

Podemos solicitar propiedades adicionales:

```powershell
Get-ADUser -Identity "juan.perez" `
    -Properties Department,Title,Enabled,LastLogonDate
```

También podemos seleccionar únicamente aquellas que nos interesan:

```powershell
Get-ADUser -Identity "juan.perez" `
    -Properties Department,Title,LastLogonDate |
    Select-Object SamAccountName,Department,Title,Enabled,LastLogonDate
```

---

### 1.2. Modificación de usuarios

Para modificar propiedades de una cuenta utilizaremos principalmente:

```powershell
Set-ADUser
```

Por ejemplo:

```powershell
Set-ADUser `
    -Identity "juan.perez" `
    -Department "TIC" `
    -Title "Administrador de sistemas"
```

También podemos modificar información como:

- departamento;
- puesto de trabajo;
- teléfono;
- correo electrónico;
- empresa;
- descripción.

---

### 1.3. Deshabilitar y habilitar cuentas

Cuando un trabajador abandona temporalmente la empresa, generalmente **no es recomendable eliminar inmediatamente su cuenta**.

Podemos deshabilitarla:

```powershell
Disable-ADAccount -Identity "juan.perez"
```

Para volver a activarla:

```powershell
Enable-ADAccount -Identity "juan.perez"
```

Podemos comprobar su estado:

```powershell
Get-ADUser -Identity "juan.perez" |
    Select-Object Name,Enabled
```

!!! warning "Deshabilitar no es eliminar"\
Una cuenta deshabilitada continúa existiendo en Active Directory y conserva sus propiedades y pertenencias a grupos, pero no puede utilizarse para iniciar sesión.

---

### 1.4. Restablecimiento de contraseñas

Una de las operaciones más habituales del administrador es restablecer la contraseña de un usuario.

Primero creamos un objeto `SecureString`:

```powershell
$password = ConvertTo-SecureString `
    "Temporal-2026!" `
    -AsPlainText `
    -Force
```

A continuación establecemos la nueva contraseña:

```powershell
Set-ADAccountPassword `
    -Identity "juan.perez" `
    -Reset `
    -NewPassword $password
```

Normalmente obligaremos al usuario a modificarla en el siguiente inicio de sesión:

```powershell
Set-ADUser `
    -Identity "juan.perez" `
    -ChangePasswordAtLogon $true
```

---

### 1.5. Desbloqueo de cuentas

Una cuenta puede quedar bloqueada debido a varios intentos fallidos de autenticación.

Podemos desbloquearla con:

```powershell
Unlock-ADAccount -Identity "juan.perez"
```

Y consultar previamente su estado:

```powershell
Get-ADUser `
    -Identity "juan.perez" `
    -Properties LockedOut |
    Select-Object Name,LockedOut
```

---

## 2. Administración de grupos

Los grupos permiten gestionar permisos de manera colectiva.

En lugar de asignar permisos directamente a numerosos usuarios, es preferible:

```text
USUARIO → GRUPO → RECURSO
```

Esto facilita enormemente la administración.

---

### 2.1. Consultar los miembros de un grupo

```powershell
Get-ADGroupMember -Identity "TIC"
```

Podemos obtener únicamente determinada información:

```powershell
Get-ADGroupMember -Identity "TIC" |
    Select-Object Name,ObjectClass
```

---

### 2.2. Añadir usuarios a un grupo

```powershell
Add-ADGroupMember `
    -Identity "TIC" `
    -Members "juan.perez"
```

También podemos añadir varios usuarios:

```powershell
Add-ADGroupMember `
    -Identity "TIC" `
    -Members "juan.perez","ana.garcia"
```

---

### 2.3. Eliminar usuarios de un grupo

```powershell
Remove-ADGroupMember `
    -Identity "TIC" `
    -Members "juan.perez"
```

---

### 2.4. Tipos y ámbitos de grupo

En Active Directory debemos diferenciar entre el **tipo** y el **ámbito** de un grupo.

#### Tipos

Los grupos pueden ser:

- **Seguridad**: utilizados para asignar permisos.
- **Distribución**: utilizados fundamentalmente para distribución de correo.

#### Ámbitos

Los grupos de seguridad pueden tener diferentes ámbitos:

- **Global**
- **Domain Local**
- **Universal**

En una infraestructura con un único dominio será habitual trabajar principalmente con grupos **Global** y **Domain Local**.

---

### 2.5. Estrategia AGDLP

Una estrategia muy utilizada para organizar permisos en Active Directory es:

```text
A → G → DL → P
```

donde:

```text
A  = Accounts
G  = Global Groups
DL = Domain Local Groups
P  = Permissions
```

Por ejemplo:

```text
juan.perez
    ↓
GG_TIC
    ↓
DL_FS_TIC_RW
    ↓
\\FILESERVER\TIC
```

De esta forma, los permisos sobre el recurso se asignan al grupo local de dominio y no directamente a usuarios concretos.

Esto facilita los cambios organizativos.

Si Juan deja el departamento TIC, bastará con eliminarlo de `GG_TIC`.

---

## 3. Administración de equipos

Los equipos unidos al dominio también están representados mediante objetos de tipo **Computer** dentro de Active Directory.

Podemos consultar un equipo:

```powershell
Get-ADComputer -Identity "PC-TIC01"
```

O mostrar información adicional:

```powershell
Get-ADComputer `
    -Identity "PC-TIC01" `
    -Properties OperatingSystem,IPv4Address,LastLogonDate
```

---

### 3.1. Deshabilitar un equipo

Si un ordenador deja temporalmente de utilizarse:

```powershell
Disable-ADAccount -Identity "PC-TIC01$"
```

Para habilitarlo:

```powershell
Enable-ADAccount -Identity "PC-TIC01$"
```

---

### 3.2. Eliminar un equipo

Si el equipo deja definitivamente de pertenecer a la organización:

```powershell
Remove-ADComputer -Identity "PC-TIC01"
```

!!! warning\
Eliminar el objeto del equipo en Active Directory **no equivale a apagar, borrar o retirar físicamente el ordenador**.

---

## 4. Administración de Unidades Organizativas

Las Unidades Organizativas permiten estructurar los objetos del dominio.

Pero una UO no debe entenderse únicamente como una carpeta donde guardar usuarios.

Una UO constituye también un **límite administrativo** sobre el que posteriormente podremos:

- delegar administración;
- aplicar políticas de grupo;
- organizar usuarios;
- organizar equipos;
- separar departamentos;
- automatizar tareas administrativas.

---

### 4.1. Consultar las UO existentes

```powershell
Get-ADOrganizationalUnit -Filter *
```

Podemos visualizar su Distinguished Name:

```powershell
Get-ADOrganizationalUnit -Filter * |
    Select-Object Name,DistinguishedName
```

También podemos comprobar si están protegidas frente al borrado accidental:

```powershell
Get-ADOrganizationalUnit `
    -Filter * `
    -Properties ProtectedFromAccidentalDeletion |
    Select-Object Name,ProtectedFromAccidentalDeletion
```

---

### 4.2. Mover objetos entre UO

Supongamos que Juan Pérez deja el departamento de Ventas y comienza a trabajar en TIC.

No tendría sentido eliminar su cuenta y crear otra nueva.

Podemos moverla:

```powershell
Get-ADUser -Identity "juan.perez" |
    Move-ADObject `
        -TargetPath "OU=TIC,OU=Departamentos,DC=int,DC=empresa,DC=asix"
```

Podemos verificar posteriormente su ubicación:

```powershell
Get-ADUser -Identity "juan.perez" |
    Select-Object Name,DistinguishedName
```

Este tipo de operación es habitual cuando cambia la estructura organizativa de una empresa.

---

### 4.3. Mover equipos entre UO

También podemos reorganizar los equipos:

```powershell
Get-ADComputer -Identity "PC-TIC01" |
    Move-ADObject `
        -TargetPath "OU=EquiposTIC,DC=int,DC=empresa,DC=asix"
```

Esta operación tendrá especial importancia cuando se utilicen **GPO diferentes dependiendo de la UO en la que se encuentre el equipo**.

---

### 4.4. Renombrar una UO

Supongamos que el departamento `Informatica` pasa a denominarse `TIC`.

Localizamos primero la UO:

```powershell
$ou = Get-ADOrganizationalUnit `
    -Identity "OU=Informatica,OU=Departamentos,DC=int,DC=empresa,DC=asix"
```

Y la renombramos:

```powershell
Rename-ADObject `
    -Identity $ou.DistinguishedName `
    -NewName "TIC"
```

---

### 4.5. Protección frente al borrado accidental

Las UO importantes deberían estar protegidas frente a eliminaciones accidentales.

```powershell
Set-ADOrganizationalUnit `
    -Identity "OU=TIC,OU=Departamentos,DC=int,DC=empresa,DC=asix" `
    -ProtectedFromAccidentalDeletion $true
```

Podemos comprobarlo:

```powershell
Get-ADOrganizationalUnit `
    -Identity "OU=TIC,OU=Departamentos,DC=int,DC=empresa,DC=asix" `
    -Properties ProtectedFromAccidentalDeletion
```

---

### 4.6. Eliminar una UO

Para eliminar una UO protegida será necesario retirar previamente la protección:

```powershell
Set-ADOrganizationalUnit `
    -Identity "OU=TIC,OU=Departamentos,DC=int,DC=empresa,DC=asix" `
    -ProtectedFromAccidentalDeletion $false
```

Y posteriormente:

```powershell
Remove-ADOrganizationalUnit `
    -Identity "OU=TIC,OU=Departamentos,DC=int,DC=empresa,DC=asix"
```

!!! danger "Operación destructiva"\
Antes de eliminar una UO debe comprobarse qué objetos contiene y qué GPO, delegaciones o procesos administrativos dependen de ella.

---

## 5. Administración del dominio

Además de los objetos individuales, un administrador debe conocer el estado del propio dominio.

Podemos obtener información mediante:

```powershell
Get-ADDomain
```

Algunas propiedades especialmente interesantes son:

```powershell
Get-ADDomain |
    Select-Object `
        DNSRoot,
        NetBIOSName,
        DomainMode,
        PDCEmulator,
        RIDMaster,
        InfrastructureMaster
```

Por ejemplo:

```text
DNSRoot              int.empresa.asix
NetBIOSName          EMPRESA
DomainMode           Windows2016Domain
PDCEmulator          DC01.int.empresa.asix
RIDMaster            DC01.int.empresa.asix
InfrastructureMaster DC01.int.empresa.asix
```

---

## 6. Administración del bosque

Un **bosque** constituye el nivel lógico superior de una infraestructura Active Directory.

Puede contener uno o varios dominios.

En nuestro entorno tendremos inicialmente una estructura similar a:

```text
Bosque
└── int.empresa.asix
      └── DC01
```

Podemos consultar el bosque mediante:

```powershell
Get-ADForest
```

Por ejemplo:

```powershell
Get-ADForest |
    Select-Object `
        Name,
        ForestMode,
        RootDomain,
        Domains,
        GlobalCatalogs
```

---

### 6.1. Dominio y bosque no son lo mismo

Conviene diferenciar claramente ambos conceptos.

```text
BOSQUE
│
├── Esquema
├── Configuración
├── Catálogo global
│
└── DOMINIO
    ├── Usuarios
    ├── Grupos
    ├── Equipos
    ├── UO
    └── GPO
```

Un bosque puede contener varios dominios, aunque en nuestra infraestructura trabajaremos principalmente con **un bosque y un dominio**.

---

## 7. Controladores de dominio

Un dominio puede disponer de uno o varios controladores de dominio.

Podemos consultarlos mediante:

```powershell
Get-ADDomainController -Filter *
```

Una salida más clara puede obtenerse con:

```powershell
Get-ADDomainController -Filter * |
    Select-Object `
        HostName,
        IPv4Address,
        Site,
        IsGlobalCatalog
```

En nuestra infraestructura inicial tendremos:

```text
DC01.int.empresa.asix
```

Si posteriormente incorporásemos `DC02`, ambos controladores de dominio mantendrían copias de la información de Active Directory mediante **replicación**.

---

## 8. Roles FSMO

Active Directory utiliza un modelo de replicación **multimaestro**.

Esto significa que muchas modificaciones pueden realizarse en cualquiera de los controladores de dominio.

Sin embargo, existen determinadas operaciones que deben ser realizadas por un controlador concreto.

Estas funciones se denominan:

> **FSMO — Flexible Single Master Operations**

Existen cinco roles FSMO.

---

### 8.1. Roles FSMO del dominio

Son tres:

- **PDC Emulator**
- **RID Master**
- **Infrastructure Master**

Podemos localizarlos mediante:

```powershell
Get-ADDomain |
    Select-Object `
        PDCEmulator,
        RIDMaster,
        InfrastructureMaster
```

---

### 8.2. Roles FSMO del bosque

Son dos:

- **Schema Master**
- **Domain Naming Master**

Podemos localizarlos mediante:

```powershell
Get-ADForest |
    Select-Object `
        SchemaMaster,
        DomainNamingMaster
```

Por tanto:

| Ámbito  | Rol                   |
| ------- | --------------------- |
| Bosque  | Schema Master         |
| Bosque  | Domain Naming Master  |
| Dominio | PDC Emulator          |
| Dominio | RID Master            |
| Dominio | Infrastructure Master |

---

### 8.3. ¿Para qué sirve cada rol?

#### Schema Master

Controla las modificaciones realizadas sobre el esquema de Active Directory.

#### Domain Naming Master

Controla la incorporación y eliminación de dominios dentro del bosque.

#### RID Master

Proporciona bloques de identificadores RID a los controladores de dominio para que puedan crear identificadores de seguridad únicos.

#### PDC Emulator

Tiene varias funciones especialmente importantes, entre ellas determinadas operaciones relacionadas con:

- sincronización horaria;
- cambios de contraseña;
- bloqueos de cuentas;
- compatibilidad con determinadas funciones históricas.

#### Infrastructure Master

Mantiene determinadas referencias entre objetos pertenecientes a diferentes dominios.

!!! note\
En una infraestructura pequeña todos los roles FSMO pueden encontrarse en el mismo controlador de dominio, como ocurrirá inicialmente con `DC01`.

---

## 9. Catálogo global

Un controlador de dominio puede actuar también como **Global Catalog**.

Podemos comprobarlo:

```powershell
Get-ADDomainController -Filter * |
    Select-Object HostName,IsGlobalCatalog
```

El catálogo global contiene información que permite realizar búsquedas sobre objetos del bosque y participa también en determinados procesos de autenticación.

En una infraestructura con un único dominio, normalmente el controlador de dominio será también catálogo global.

---

## 10. Sites de Active Directory

Active Directory permite representar también la **estructura física de la red** mediante:

- Sites;
- Subnets;
- Site Links.

Podemos consultar los sites:

```powershell
Get-ADReplicationSite -Filter *
```

Y las subredes definidas:

```powershell
Get-ADReplicationSubnet -Filter *
```

Los Sites adquieren especial importancia en organizaciones distribuidas geográficamente.

Por ejemplo:

```text
EMPRESA
│
├── Sede Alicante
│   └── 10.10.10.0/24
│
└── Sede Valencia
    └── 10.20.10.0/24
```

Active Directory puede utilizar esta información para optimizar:

- autenticación;
- localización de controladores de dominio;
- replicación.

En nuestra infraestructura inicial trabajaremos normalmente con el site:

```text
Default-First-Site-Name
```

---

## 11. Replicación de Active Directory

Cuando existen varios controladores de dominio, la información debe mantenerse sincronizada entre ellos.

Este proceso se denomina **replicación**.

Por ejemplo:

```text
             REPLICACIÓN
DC01  <---------------------->  DC02
 |                                |
Usuarios                        Usuarios
Grupos                          Grupos
Equipos                         Equipos
UO                              UO
```

Si creamos un usuario en `DC01`, posteriormente deberá aparecer también en `DC02`.

---

### 11.1. Comprobar el estado general

Una de las herramientas fundamentales es:

```powershell
repadmin /replsummary
```

Permite obtener un resumen del estado de replicación.

---

### 11.2. Ver información detallada

```powershell
repadmin /showrepl
```

Con PowerShell también podemos utilizar:

```powershell
Get-ADReplicationPartnerMetadata `
    -Target * `
    -Scope Domain
```

Para comprobar errores:

```powershell
Get-ADReplicationFailure `
    -Target * `
    -Scope Domain
```

!!! info\
En una infraestructura con un único controlador de dominio no existe otro DC con el que replicar. Estos comandos adquirirán especial sentido cuando se incorpore un segundo controlador.

---

## 12. Relaciones de confianza

Los dominios pueden establecer **relaciones de confianza** que permiten que usuarios de un dominio puedan ser reconocidos por otro.

Podemos consultar las relaciones existentes mediante:

```powershell
Get-ADTrust -Filter *
```

En nuestra infraestructura inicial, con un único dominio:

```text
int.empresa.asix
```

no será necesario configurar relaciones de confianza adicionales.

Sin embargo, el administrador debe conocer su existencia para comprender infraestructuras Active Directory de mayor tamaño.

---

## 13. Delegación de administración

Uno de los errores habituales es considerar que cualquier persona que necesite realizar una tarea administrativa debe pertenecer al grupo:

```text
Domain Admins
```

Esto no es recomendable.

Debe aplicarse el:

> **Principio de mínimo privilegio**

Un usuario debe disponer únicamente de los permisos necesarios para realizar su trabajo.

---

### 13.1. Ejemplo

Supongamos la siguiente estructura:

```text
Departamentos
│
├── Direccion
├── TIC
├── Ventas
└── RRHH
```

El responsable de RRHH necesita:

- crear usuarios de RRHH;
- modificar algunos de sus atributos;
- restablecer sus contraseñas.

No necesita:

- administrar TIC;
- crear controladores de dominio;
- modificar el bosque;
- pertenecer a Domain Admins.

Podemos delegarle exclusivamente determinadas operaciones sobre:

```text
OU=RRHH,OU=Departamentos,DC=int,DC=empresa,DC=asix
```

---

### 13.2. Delegación mediante interfaz gráfica

Desde **Active Directory Users and Computers**:

```text
Botón derecho sobre la UO
        ↓
Delegate Control...
        ↓
Seleccionar usuario/grupo
        ↓
Seleccionar tareas permitidas
        ↓
Finalizar
```

Entre las tareas delegables se encuentran:

- crear y eliminar usuarios;
- restablecer contraseñas;
- modificar pertenencias a grupos;
- administrar determinados objetos.

---

### 13.3. Consultar permisos

Podemos utilizar también herramientas como:

```powershell
dsacls "OU=RRHH,OU=Departamentos,DC=int,DC=empresa,DC=asix"
```

La administración programática de ACL de Active Directory puede llegar a ser considerablemente más compleja y requiere conocer:

- SID;
- ACL;
- ACE;
- herencia;
- permisos sobre objetos del directorio.

---

## 14. Comprobación de la salud de Active Directory

Un administrador no debe limitarse a comprobar si puede iniciar sesión.

Debe verificar periódicamente el estado de la infraestructura.

Una herramienta fundamental es:

```powershell
dcdiag
```

---

### 14.1. Diagnóstico completo

```powershell
dcdiag /v
```

`dcdiag` realiza diferentes pruebas sobre el controlador de dominio.

Entre otros elementos puede comprobar:

- conectividad;
- servicios;
- DNS;
- replicación;
- SYSVOL;
- Netlogon;
- diferentes componentes de Active Directory.

---

### 14.2. Diagnóstico de DNS

Active Directory depende fuertemente del servicio DNS.

Podemos ejecutar:

```powershell
dcdiag /test:dns /v
```

También podemos comprobar registros DNS mediante PowerShell:

```powershell
Resolve-DnsName `
    -Type SRV `
    "_ldap._tcp.dc._msdcs.int.empresa.asix"
```

Los registros SRV permiten localizar servicios como los controladores de dominio.

---

## 15. Servicios fundamentales de un controlador de dominio

Podemos comprobar determinados servicios mediante:

```powershell
Get-Service NTDS,DNS,Netlogon,KDC
```

En condiciones normales deberían aparecer en ejecución:

```text
Status   Name
------   ----
Running  DNS
Running  KDC
Running  Netlogon
Running  NTDS
```

Algunos de los servicios principales son:

| Servicio | Función                               |
| -------- | ------------------------------------- |
| NTDS     | Active Directory Domain Services      |
| DNS      | Resolución de nombres                 |
| Netlogon | Inicio de sesión y localización de DC |
| KDC      | Autenticación Kerberos                |

---

## 16. SYSVOL y NETLOGON

Los controladores de dominio publican dos recursos compartidos especialmente importantes:

```text
SYSVOL
NETLOGON
```

Podemos comprobarlos:

```powershell
Get-SmbShare -Name SYSVOL,NETLOGON
```

También desde un cliente:

```text
\\DC01\SYSVOL
```

y:

```text
\\DC01\NETLOGON
```

`SYSVOL` contiene, entre otros elementos, información necesaria para las **Políticas de Grupo**.

---

## 17. Diagnóstico desde un equipo cliente

Los problemas de Active Directory no siempre están en el controlador de dominio.

También debemos realizar comprobaciones desde el cliente.

---

### 17.1. Configuración IP

```powershell
ipconfig /all
```

Debemos comprobar especialmente:

- dirección IP;
- máscara;
- puerta de enlace;
- servidor DNS.

!!! danger "DNS"\
Un equipo unido al dominio debe utilizar como DNS un servidor capaz de resolver la zona DNS de Active Directory. Configurar incorrectamente el DNS es una de las causas más habituales de problemas con el dominio.

---

### 17.2. Resolver el dominio

```powershell
Resolve-DnsName int.empresa.asix
```

---

### 17.3. Localizar un controlador de dominio

```powershell
nltest /dsgetdc:int.empresa.asix
```

---

### 17.4. Comprobar el canal seguro

Los equipos unidos al dominio mantienen una relación de confianza con este.

Podemos comprobarla mediante:

```powershell
Test-ComputerSecureChannel -Verbose
```

Una respuesta correcta será:

```text
True
```

Si el canal seguro presenta problemas deberá estudiarse la causa antes de aplicar acciones correctivas.

---

## 18. Troubleshooting de Active Directory

Ante un problema con el dominio, es importante seguir un procedimiento ordenado.

No debemos empezar modificando configuraciones al azar.

Podemos utilizar el siguiente proceso.

---

### Paso 1. Comprobar conectividad

```powershell
Test-Connection DC01
```

---

### Paso 2. Comprobar DNS

```powershell
Resolve-DnsName DC01.int.empresa.asix
```

Y:

```powershell
Resolve-DnsName `
    -Type SRV `
    "_ldap._tcp.dc._msdcs.int.empresa.asix"
```

---

### Paso 3. Comprobar servicios del DC

```powershell
Get-Service NTDS,DNS,Netlogon,KDC
```

---

### Paso 4. Comprobar el dominio

```powershell
Get-ADDomain
```

---

### Paso 5. Comprobar el controlador

```powershell
Get-ADDomainController -Filter *
```

---

### Paso 6. Ejecutar diagnóstico

```powershell
dcdiag
```

---

### Paso 7. Comprobar replicación

Si existen varios DC:

```powershell
repadmin /replsummary
```

---

### Paso 8. Revisar eventos

Desde PowerShell podemos consultar, por ejemplo:

```powershell
Get-WinEvent `
    -LogName "Directory Service" `
    -MaxEvents 20
```

También pueden resultar relevantes los registros:

- Directory Service;
- DNS Server;
- System;
- Security.

---

## 19. Operaciones habituales de un administrador

Veamos algunos ejemplos completos.

---

### Caso 1. Un trabajador cambia de departamento

Situación:

```text
juan.perez

ANTES:
Ventas

DESPUÉS:
TIC
```

Acciones:

```powershell
Remove-ADGroupMember `
    -Identity "Ventas" `
    -Members "juan.perez" `
    -Confirm:$false

Add-ADGroupMember `
    -Identity "TIC" `
    -Members "juan.perez"

Set-ADUser `
    -Identity "juan.perez" `
    -Department "TIC"

Get-ADUser -Identity "juan.perez" |
    Move-ADObject `
        -TargetPath "OU=TIC,OU=Departamentos,DC=int,DC=empresa,DC=asix"
```

Finalmente debemos verificar el resultado.

---

### Caso 2. Un usuario olvida la contraseña

```powershell
$password = ConvertTo-SecureString `
    "Temporal-2026!" `
    -AsPlainText `
    -Force

Set-ADAccountPassword `
    -Identity "juan.perez" `
    -Reset `
    -NewPassword $password

Set-ADUser `
    -Identity "juan.perez" `
    -ChangePasswordAtLogon $true
```

---

### Caso 3. Baja temporal

```powershell
Disable-ADAccount -Identity "juan.perez"
```

Posteriormente:

```powershell
Get-ADUser `
    -Identity "juan.perez" |
    Select-Object Name,Enabled
```

---

### Caso 4. Reincorporación

```powershell
Enable-ADAccount -Identity "juan.perez"
```

---

### Caso 5. Retirada de un equipo

Primero comprobamos el objeto:

```powershell
Get-ADComputer -Identity "PC-TIC01"
```

Y posteriormente, si realmente debe eliminarse:

```powershell
Remove-ADComputer `
    -Identity "PC-TIC01" `
    -Confirm:$false
```

---

## 20. Automatización del diagnóstico

Las comprobaciones administrativas también pueden automatizarse.

Por ejemplo, podemos comenzar un script denominado:

```text
diagnosticoAD.ps1
```

con el siguiente contenido:

```powershell
Write-Host "==================================" -ForegroundColor Cyan
Write-Host " DIAGNÓSTICO ACTIVE DIRECTORY"
Write-Host "==================================" -ForegroundColor Cyan

Write-Host "`n[1] INFORMACIÓN DEL DOMINIO" -ForegroundColor Yellow

Get-ADDomain |
    Select-Object `
        DNSRoot,
        DomainMode,
        PDCEmulator,
        RIDMaster,
        InfrastructureMaster

Write-Host "`n[2] INFORMACIÓN DEL BOSQUE" -ForegroundColor Yellow

Get-ADForest |
    Select-Object `
        Name,
        ForestMode,
        SchemaMaster,
        DomainNamingMaster

Write-Host "`n[3] CONTROLADORES DE DOMINIO" -ForegroundColor Yellow

Get-ADDomainController -Filter * |
    Select-Object `
        HostName,
        IPv4Address,
        Site,
        IsGlobalCatalog

Write-Host "`n[4] SERVICIOS" -ForegroundColor Yellow

Get-Service NTDS,DNS,Netlogon,KDC |
    Select-Object Name,Status

Write-Host "`n[5] REPLICACIÓN" -ForegroundColor Yellow

repadmin /replsummary

Write-Host "`n[6] DIAGNÓSTICO DEL DC" -ForegroundColor Yellow

dcdiag

Write-Host "`n==================================" -ForegroundColor Cyan
Write-Host " FIN DEL DIAGNÓSTICO"
Write-Host "==================================" -ForegroundColor Cyan
```

!!! tip "Automatización"\
Un administrador no debería repetir manualmente veinte comprobaciones cada vez que aparezca una incidencia. Si una secuencia de diagnóstico se utiliza habitualmente, es candidata a ser automatizada mediante PowerShell.

---

## 21. Flujo de administración recomendado

Ante cualquier modificación del directorio conviene seguir un procedimiento:

```text
1. Identificar la necesidad
          ↓
2. Consultar el estado actual
          ↓
3. Evaluar el impacto
          ↓
4. Realizar la modificación
          ↓
5. Verificar el resultado
          ↓
6. Documentar el cambio
```

Por ejemplo:

```text
Usuario cambia de departamento
          ↓
Consultar usuario
          ↓
Consultar grupos actuales
          ↓
Modificar pertenencia
          ↓
Mover a nueva UO
          ↓
Comprobar resultado
          ↓
Documentar
```

Este procedimiento es preferible a ejecutar directamente comandos sin comprobar previamente el estado del sistema.

---

## 22. Buenas prácticas de administración

Algunas recomendaciones básicas:

- Evitar trabajar habitualmente con cuentas pertenecientes a `Domain Admins`.
- Aplicar el principio de mínimo privilegio.
- Administrar permisos mediante grupos y no directamente mediante usuarios.
- Proteger las UO importantes frente al borrado accidental.
- No eliminar inmediatamente las cuentas de trabajadores que causan baja.
- Comprobar siempre DNS cuando aparezcan problemas con Active Directory.
- Verificar una modificación después de realizarla.
- Automatizar las tareas repetitivas.
- Mantener documentada la estructura del directorio.
- Registrar los cambios administrativos relevantes.
- Utilizar cuentas administrativas diferentes de las cuentas de uso cotidiano.
- Revisar periódicamente cuentas, grupos y permisos.

---

## 23. Laboratorio propuesto

Partimos del dominio:

```text
int.empresa.asix
```

con la siguiente estructura:

```text
int.empresa.asix
│
└── Departamentos
    ├── Direccion
    ├── TIC
    ├── Ventas
    └── RRHH
```

Se producen las siguientes incidencias:

### Incidencia 1

El usuario `juan.perez`, actualmente en Ventas, pasa al departamento TIC.

Deberás:

- modificar su departamento;
- modificar sus grupos;
- moverlo a la UO adecuada;
- verificar el resultado.

### Incidencia 2

El usuario `ana.garcia` ha olvidado su contraseña.

Deberás:

- establecer una contraseña temporal;
- obligarla a modificarla en el siguiente inicio;
- verificar el estado de su cuenta.

### Incidencia 3

El usuario `pedro.lopez` causa una baja temporal.

Deberás aplicar una solución que impida que pueda autenticarse sin eliminar su cuenta.

### Incidencia 4

El equipo `PC-VENTAS03` se traslada al departamento TIC.

Deberás reorganizar el objeto correspondiente dentro de Active Directory.

### Incidencia 5

Debes comprobar el estado general del controlador de dominio `DC01`.

Como mínimo, deberás revisar:

- dominio;
- bosque;
- FSMO;
- servicios;
- DNS;
- SYSVOL;
- NETLOGON;
- diagnóstico mediante `dcdiag`.

---

## 24. Resumen

La administración de Active Directory implica mucho más que crear usuarios.

Un administrador debe ser capaz de gestionar:

```text
ACTIVE DIRECTORY
│
├── Usuarios
├── Grupos
├── Equipos
├── Unidades Organizativas
│
├── Dominio
├── Bosque
├── Controladores de dominio
├── Roles FSMO
├── Catálogo global
├── Sites
├── Replicación
│
├── Delegación administrativa
│
└── Diagnóstico y resolución de problemas
```

El objetivo final es disponer de un servicio de directorio:

- organizado;
- seguro;
- administrable;
- automatizable;
- monitorizable;
- documentado.

En los siguientes apartados profundizaremos en mecanismos que permitirán administrar un gran número de objetos de forma eficiente, mediante **filtros, búsquedas avanzadas y automatización con PowerShell**.

---

## 📚 Referencias y Fuentes Consultadas

!!! info "Documentación Oficial y Recursos en Internet"
    * **Metodología y Fuentes:** Elaborado mediante recopilación de documentación técnica especializada de Internet, con el soporte de herramientas de Inteligencia Artificial para la síntesis y estructuración de contenidos, y posterior verificación técnica, adaptación curricular y diseño pedagógico por parte del docente.
    * **Microsoft Learn:** [Active Directory Domain Services Overview](https://learn.microsoft.com/es-es/windows-server/identity/ad-ds/active-directory-domain-services), [Referencia del Módulo ActiveDirectory de PowerShell](https://learn.microsoft.com/powershell/module/activedirectory/) y [Herramientas de diagnóstico de Active Directory (`dcdiag`, `repadmin`)](https://learn.microsoft.com/es-es/troubleshoot/windows-server/identity/dcdiag-tool).
    * **Docente / Autor:** José Ramón Soria Nieto — Departamento de Informática del **IES Marcos Zaragoza**.
    * **Marco Curricular:** Módulo profesional de *Administración de Sistemas Operativos (ASO)*, 2.º Curso del Ciclo Formativo de Grado Superior en *Administración de Sistemas Informáticos en Red (2ASIR / 2ASIX)*.

!!! abstract "Soporte Institucional y Fondo Social Europeo"
    * **Órgano Regulador:** Generalitat Valenciana — Conselleria d'Educació, Cultura i Esport.
    * **Acreditación de Financiación:** Proyecto educativo y tecnológico cofinanciado por la **Unión Europea** a través del **Fondo Social Europeo (FSE)**.
    * *«El FSE invierte en tu futuro»* — Acciones destinadas a impulsar la educación digital avanzada, la modernización de entornos y laboratorios informáticos de Formación Profesional y la capacitación técnica cualificada en infraestructuras de red.

