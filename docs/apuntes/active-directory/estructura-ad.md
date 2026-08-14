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

Una vez tenemos nuestro Controlador de Dominio (`int.asix.info`) operativo, el siguiente paso lógico es organizarlo. Un directorio sin organizar se vuelve inmanejable a medida que la organización crece.

Para este caso práctico, vamos a modelar el departamento de informática (ciclo de ASIX), estructurado de la siguiente forma:

* 🏢 **ASIX** (Unidad Organizativa principal)
    * 🎓 **Alumnado** (OU)
        * 📘 **Primero** (OU)
        * 📗 **Segundo** (OU)
    * 👨‍🏫 **Profesorado** (OU)
    * 🖥️ **Aulas** (OU principal de aulas)
        * 💻 **aula01** (OU)
        * 💻 **aula02** (OU)

---

## 💻 Implementación con PowerShell

Para automatizar la creación de toda esta estructura de una sola vez en nuestro Windows Server Core, vamos a utilizar un script de PowerShell. 

### 1. Creación de Unidades Organizativas (OUs)

Usaremos el cmdlet `New-ADOrganizationalUnit`. Empezaremos creando la OU raíz (`ASIX`) y luego colgaremos el resto de sub-OUs de ella modificando el parámetro `-Path`.

```powershell
# Importamos el módulo de Active Directory por si no está cargado
Import-Module ActiveDirectory

# 1. Crear la OU Raíz protegida contra borrado accidental
New-ADOrganizationalUnit -Name "ASIX" -Path "DC=int,DC=asix,DC=info" -ProtectedFromAccidentalDeletion $true

# 2. Crear las OUs principales dentro de ASIX
New-ADOrganizationalUnit -Name "Alumnado" -Path "OU=ASIX,DC=int,DC=asix,DC=info"
New-ADOrganizationalUnit -Name "Profesorado" -Path "OU=ASIX,DC=int,DC=asix,DC=info"
New-ADOrganizationalUnit -Name "Aulas" -Path "OU=ASIX,DC=int,DC=asix,DC=info"

# 3. Crear las OUs de los cursos dentro de Alumnado
New-ADOrganizationalUnit -Name "Primero" -Path "OU=Alumnado,OU=ASIX,DC=int,DC=asix,DC=info"
New-ADOrganizationalUnit -Name "Segundo" -Path "OU=Alumnado,OU=ASIX,DC=int,DC=asix,DC=info"

# 4. Crear las OUs de las aulas
New-ADOrganizationalUnit -Name "aula01" -Path "OU=Aulas,OU=ASIX,DC=int,DC=asix,DC=info"
New-ADOrganizationalUnit -Name "aula02" -Path "OU=Aulas,OU=ASIX,DC=int,DC=asix,DC=info"
```

### 2. Creación de Grupos de Seguridad

Los grupos son esenciales para asignar permisos (por ejemplo, a carpetas compartidas) o aplicar directivas (GPOs) más adelante. Usaremos `New-ADGroup`.

```powershell
# Crear grupo global para Profesores
New-ADGroup -Name "GG_Profesores" -GroupCategory Security -GroupScope Global -Path "OU=Profesorado,OU=ASIX,DC=int,DC=asix,DC=info"

# Crear grupos globales para el alumnado de cada curso
New-ADGroup -Name "GG_Alumnado1" -GroupCategory Security -GroupScope Global -Path "OU=Primero,OU=Alumnado,OU=ASIX,DC=int,DC=asix,DC=info"
New-ADGroup -Name "GG_Alumnado2" -GroupCategory Security -GroupScope Global -Path "OU=Segundo,OU=Alumnado,OU=ASIX,DC=int,DC=asix,DC=info"
```

### 3. Creación de Usuarios y Equipos de prueba

Finalmente, poblamos nuestras nuevas OUs con algunos objetos de muestra: usuarios (`New-ADUser`) y equipos (`New-ADComputer`).

!!! warning "Gestión de Contraseñas Seguras"
    En PowerShell, el parámetro `-AccountPassword` requiere un objeto de tipo `SecureString`. Por eso, utilizamos `ConvertTo-SecureString` antes de pasarle la contraseña en texto plano.

```powershell
# Crear un usuario Profesor y añadirlo a su grupo
New-ADUser -Name "Ana Garcia" -GivenName "Ana" -Surname "Garcia" -SamAccountName "agarcia" -UserPrincipalName "agarcia@int.asix.info" -Path "OU=Profesorado,OU=ASIX,DC=int,DC=asix,DC=info" -AccountPassword (ConvertTo-SecureString "Asix2026!!" -AsPlainText -Force) -Enabled $true -ChangePasswordAtLogon $true
Add-ADGroupMember -Identity "GG_Profesores" -Members "agarcia"

# Crear un usuario del alumnado en Primero y añadirlo a su grupo
New-ADUser -Name "Luis Perez" -GivenName "Luis" -Surname "Perez" -SamAccountName "lperez" -UserPrincipalName "lperez@int.asix.info" -Path "OU=Primero,OU=Alumnado,OU=ASIX,DC=int,DC=asix,DC=info" -AccountPassword (ConvertTo-SecureString "Alumno2026!!" -AsPlainText -Force) -Enabled $true -ChangePasswordAtLogon $true
Add-ADGroupMember -Identity "GG_Alumnado1" -Members "lperez"

# Pre-crear cuentas de equipo para las aulas
New-ADComputer -Name "PC-AULA01-01" -Path "OU=aula01,OU=Aulas,OU=ASIX,DC=int,DC=asix,DC=info"
New-ADComputer -Name "PC-AULA01-02" -Path "OU=aula01,OU=Aulas,OU=ASIX,DC=int,DC=asix,DC=info"
New-ADComputer -Name "PC-AULA02-01" -Path "OU=aula02,OU=Aulas,OU=ASIX,DC=int,DC=asix,DC=info"
New-ADComputer -Name "PC-AULA02-02" -Path "OU=aula02,OU=Aulas,OU=ASIX,DC=int,DC=asix,DC=info"
```

!!! info "Explicación de parámetros útiles"
    * `-ChangePasswordAtLogon $true`: Obliga al usuario a cambiar su contraseña genérica la primera vez que inicia sesión en cualquier equipo.
    * `-ProtectedFromAccidentalDeletion $true`: Es muy recomendable aplicarlo en la OU raíz (en este caso, `ASIX`) para evitar desastres si se borra por error, ya que eliminaría todo el árbol que cuelga de ella.

---

## ✅ Verificación

Para comprobar que toda la estructura se ha creado correctamente desde la consola de Windows Server Core, puedes listar el contenido de la OU raíz ejecutando:

```powershell
Get-ADObject -SearchBase "OU=ASIX,DC=int,DC=asix,DC=info" -Filter * | Select-Object Name, ObjectClass
```

Este comando te devolverá un listado con las Unidades Organizativas, Grupos, Usuarios y Equipos que acabamos de generar en nuestro directorio activo.
