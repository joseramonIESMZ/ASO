# Estructura Organizativa en Active Directory

## 🎯 Relación con el Currículo (RA y CE)
La creación de unidades organizativas, usuarios, grupos y equipos informáticos mediante comandos o scripts contribuye a los siguientes elementos del currículo:

* **Resultado de Aprendizaje 1 (RA1):** Administra el servicio de directorio interpretando especificaciones e integrándolo en una red.
    * **CE5-RA1:** Se han creado y administrado cuentas de usuario y grupos.
    * **CE6-RA1:** Se han organizado y administrado los recursos del directorio mediante unidades organizativas (OUs).
    * **CE8-RA1:** Se han automatizado tareas de administración del servicio de directorio.
* **Resultado de Aprendizaje 9 (RA9):** Cumple con las exigencias laborales transversales relativas a autonomía, trabajo en equipo, organización y seguridad.

---

## 🏢 Diseño de la Estructura Organizativa

Una vez tenemos operativo nuestro dominio de Active Directory (`int.asix.info`) y su controlador de dominio, el siguiente paso lógico es organizarlo. Un directorio sin organizar se vuelve inmanejable a medida que la organización crece.

Para este caso práctico, vamos a modelar el departamento de informática (ciclo de ASIX), estructurado de la siguiente forma:

* 🎓 **Alumnado** (OU)
    * 📘 **ASIX** (OU)
        * **asix1alu** (OU)
        * **asix2alu** (OU) 
* 👨‍🏫 **Profesorado** (OU)
* 🖥️ **Aulas** (OU principal de aulas)
    * 💻 **aula01** (OU)
    * 💻 **aula02** (OU)

!!! tip "¿Por qué crear OUs y no usar los contenedores por defecto?"
    Por defecto, Active Directory crea contenedores genéricos como `CN=Users` y `CN=Computers`. Aunque podríamos dejar ahí nuestros nuevos usuarios y equipos, **no es una buena práctica**. La razón técnica principal es que **no se pueden vincular Directivas de Grupo (GPOs) directamente a los contenedores genéricos (`CN`)**, pero sí a las Unidades Organizativas (`OU`). Diseñar nuestra propia estructura de OUs nos permite aplicar configuraciones, seguridad y restricciones de manera granular a diferentes grupos de usuarios o equipos.

---

## 💻 Implementación con PowerShell

Para automatizar la creación de toda esta estructura de una sola vez en nuestro Windows Server Core, vamos a utilizar un script de PowerShell. 

### 1. Creación de Unidades Organizativas (OUs)

Usaremos el cmdlet `New-ADOrganizationalUnit`. Empezaremos creando las OUs principales y luego colgaremos el resto de sub-OUs de ellas modificando el parámetro `-Path`.

```powershell
# Importamos el módulo de Active Directory por si no está cargado
Import-Module ActiveDirectory

# 1. Crear las OUs principales protegidas contra borrado accidental
New-ADOrganizationalUnit -Name "Alumnado" -Path "DC=int,DC=asix,DC=info" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Profesorado" -Path "DC=int,DC=asix,DC=info" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "Aulas" -Path "DC=int,DC=asix,DC=info" -ProtectedFromAccidentalDeletion $true

# 2. Crear la OU del ciclo dentro de Alumnado
New-ADOrganizationalUnit -Name "ASIX" -Path "OU=Alumnado,DC=int,DC=asix,DC=info" -ProtectedFromAccidentalDeletion $true

# 3. Crear las OUs de los cursos dentro de ASIX
New-ADOrganizationalUnit -Name "asix1alu" -Path "OU=ASIX,OU=Alumnado,DC=int,DC=asix,DC=info" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "asix2alu" -Path "OU=ASIX,OU=Alumnado,DC=int,DC=asix,DC=info" -ProtectedFromAccidentalDeletion $true

# 4. Crear las OUs de las aulas
New-ADOrganizationalUnit -Name "aula01" -Path "OU=Aulas,DC=int,DC=asix,DC=info" -ProtectedFromAccidentalDeletion $true
New-ADOrganizationalUnit -Name "aula02" -Path "OU=Aulas,DC=int,DC=asix,DC=info" -ProtectedFromAccidentalDeletion $true
```

!!! warning "Protección contra borrado accidental"
    Aunque actualmente el parámetro `-ProtectedFromAccidentalDeletion $true` es el comportamiento predeterminado al crear una nueva OU, lo incluimos explícitamente en el comando para resaltar la existencia de esta importante propiedad.

!!! note "SinOU en la raíz del dominio"
    Nota que no hemos creado una OU raíz del dominio (es decir, no hemos creado una OU `DC=int,DC=asix,DC=info` como hija del dominio). Esto se debe a que las OUs principales (`Alumnado`, `Profesorado`, `Aulas`, etc.) ya se crean directamente en el dominio.

### 2. Creación de Grupos de Seguridad

Los grupos son esenciales para asignar permisos (por ejemplo, a carpetas compartidas) o para realizar el **filtrado de seguridad** de las directivas (GPOs) más adelante. Usaremos `New-ADGroup`.

```powershell
# Crear grupo global para Profesores
New-ADGroup -Name "GrpProfesorado" `
            -SamAccountName "GrpProfesorado" `
            -GroupCategory Security `
            -GroupScope Global `
            -Path "OU=Profesorado,DC=int,DC=asix,DC=info"

# Crear grupos globales para el alumnado de cada curso
New-ADGroup -Name "AluGrpAsix1" `
            -SamAccountName "AluGrpAsix1" `
            -GroupCategory Security `
            -GroupScope Global `
            -Path "OU=asix1alu,OU=ASIX,OU=Alumnado,DC=int,DC=asix,DC=info"

New-ADGroup -Name "AluGrpAsix2" `
            -SamAccountName "AluGrpAsix2" `
            -GroupCategory Security `
            -GroupScope Global `
            -Path "OU=asix2alu,OU=ASIX,OU=Alumnado,DC=int,DC=asix,DC=info"
```

### 3. Creación de Usuarios y Equipos de prueba

Finalmente, poblamos nuestras nuevas OUs con algunos objetos de muestra: usuarios (`New-ADUser`) y equipos (`New-ADComputer`).

!!! warning "Gestión de Contraseñas Seguras"
    En PowerShell, el parámetro `-AccountPassword` requiere un objeto de tipo `SecureString`. Por eso, utilizamos `ConvertTo-SecureString` antes de pasarle la contraseña en texto plano.
    Para simplificar la práctica se incluye una contraseña en texto plano dentro del script. Este procedimiento es apropiado únicamente para un entorno de laboratorio y no debe utilizarse para almacenar credenciales reales.


```powershell
# Crear un usuario Profesor y añadirlo a su grupo
New-ADUser -Name "Ana Garcia" `
           -GivenName "Ana" `
           -Surname "Garcia" `
           -SamAccountName "agarcia" `
           -UserPrincipalName "agarcia@int.asix.info" `
           -Path "OU=Profesorado,DC=int,DC=asix,DC=info" `
           -AccountPassword (ConvertTo-SecureString "Asix2026!!" -AsPlainText -Force) `
           -Enabled $true `
           -ChangePasswordAtLogon $true

New-ADUser -Name "José Ramón Soria" `
           -GivenName "José Ramón" `
           -Surname "Soria" `
           -SamAccountName "jrsoria" `
           -UserPrincipalName "jrsoria@int.asix.info" `
           -Path "OU=Profesorado,DC=int,DC=asix,DC=info" `
           -AccountPassword (ConvertTo-SecureString "Asix2026!!" -AsPlainText -Force) `
           -Enabled $true `
           -ChangePasswordAtLogon $true

Add-ADGroupMember -Identity "GrpProfesorado" -Members "agarcia"
Add-ADGroupMember -Identity "GrpProfesorado" -Members "jrsoria"

# Crear un usuario del alumnado en asix1alu y añadirlo a su grupo
New-ADUser -Name "Luis Perez" `
           -GivenName "Luis" `
           -Surname "Perez" `
           -SamAccountName "lperez" `
           -UserPrincipalName "lperez@int.asix.info" `
           -Path "OU=asix1alu,OU=ASIX,OU=Alumnado,DC=int,DC=asix,DC=info" `
           -AccountPassword (ConvertTo-SecureString "Alumno2026!!" -AsPlainText -Force) `
           -Enabled $true `
           -ChangePasswordAtLogon $true

Add-ADGroupMember -Identity "AluGrpAsix1" -Members "lperez"

# Pre-crear cuentas de equipo para las aulas
New-ADComputer -Name "PC-AULA01-01" -Path "OU=aula01,OU=Aulas,DC=int,DC=asix,DC=info"
New-ADComputer -Name "PC-AULA01-02" -Path "OU=aula01,OU=Aulas,DC=int,DC=asix,DC=info"
New-ADComputer -Name "PC-AULA02-01" -Path "OU=aula02,OU=Aulas,DC=int,DC=asix,DC=info"
New-ADComputer -Name "PC-AULA02-02" -Path "OU=aula02,OU=Aulas,DC=int,DC=asix,DC=info"
```

!!! note "Pre-creación de cuentas de equipo"
    Es importante recalcar que el cmdlet `New-ADComputer` únicamente pre-crea el objeto del equipo (la cuenta de máquina) dentro de la base de datos de Active Directory en la OU especificada. **Estos comandos no realizan por sí mismos la unión de los equipos Windows físicos o virtuales al dominio**. Para completar el proceso, posteriormente cada equipo cliente deberá unirse al dominio desde su propio sistema operativo.

!!! info "Explicación de parámetros útiles"
    * `-ChangePasswordAtLogon $true`: Obliga al usuario a cambiar su contraseña genérica la primera vez que inicia sesión en cualquier equipo.
    * `-ProtectedFromAccidentalDeletion $true`: Es una buena práctica aplicarlo a **todas** las OUs. Evita desastres si se intentan borrar o mover por error. En caso de necesitar eliminar o mover una OU legítimamente, primero hay que desactivar esta protección desde sus propiedades o mediante PowerShell.
    * `-Name` vs `-SamAccountName`: El parámetro `-Name` define el nombre visual o completo del objeto en el directorio (ej. "Ana Garcia"). El parámetro `-SamAccountName` es el identificador corto o nombre de inicio de sesión (ej. "agarcia"). En los grupos suelen tener el mismo valor, pero en los usuarios son distintos.
---

## ✅ Verificación

Para comprobar que toda la estructura se ha creado correctamente desde la consola de Windows Server Core, puedes listar el contenido de las OUs principales, por ejemplo la de Alumnado, ejecutando:

```powershell
Get-ADObject `
    -SearchBase "DC=int,DC=asix,DC=info" `
    -Filter * |
    Select-Object Name, ObjectClass, DistinguishedName
```

Este comando te devolverá un listado con las Unidades Organizativas, Grupos, Usuarios y Equipos que acabamos de generar en nuestro directorio activo.

---

## 📚 Referencias y Fuentes Consultadas

!!! info "Documentación Oficial y Autoría"
    * **Material Base:** Basado en el documento *"UD4. Servicios de directorio. Administración básica"*, desarrollado por el Departamento de Informática del **IES Marcos Zaragoza**.
    * **Docente / Autor:** José Ramón Soria Nieto.
    * **Grado Formativo:** Módulo profesional de *Administración de Sistemas Operativos (ASO)*, Segundo Curso del Ciclo Formativo de Grado Superior en *Administración de Sistemas Informáticos en Red (2ASIR / 2ASIX)*.
    * **Microsoft Learn:** [Módulo ActiveDirectory para PowerShell](https://learn.microsoft.com/powershell/module/activedirectory/) e [Introducción a Active Directory Domain Services](https://learn.microsoft.com/es-es/windows-server/identity/ad-ds/get-started/virtual-dc/active-directory-domain-services-overview).

!!! abstract "Soporte Institucional y Fondo Social Europeo"
    * **Órgano Regulador:** Generalitat Valenciana — Conselleria d'Educació, Cultura i Esport.
    * **Acreditación de Financiación:** Proyecto tecnológico cofinanciado por la **Unión Europea** a través del **Fondo Social Europeo (FSE)**.
    * *«El FSE invierte en tu futuro»* — Acciones destinadas a la digitalización avanzada, el despliegue de infraestructuras críticas en las aulas y la formación técnica especializada para entornos laborales de Formación Profesional.
