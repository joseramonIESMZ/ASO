# Scripting en PowerShell: Arrays

Un array es una colección de elementos (normalmente del mismo tipo: objetos, strings, enteros, etc.), aunque en PowerShell no es un requisito estricto que todos sus elementos compartan el mismo tipo de dato.

Existen diferentes formas de definir un array:

*   **Mediante rangos:** `$ejeArray = 1..5`
*   **Listando elementos (strings):** `$eje2Array = "hola","buenos días","adiós"`
*   **Listando elementos (enteros):** `$eje3Array = 24,12,34,56`
*   **Array vacío o inicialización:** `$eje4Array = @()`
    > **Nota:** La notación `@()` es muy útil si queremos crear un array vacío, si desconocemos cuántos elementos tendrá inicialmente, o si queremos garantizar que la salida de un comando se recoja obligatoriamente como array.

---

## Acceso y Modificación de Elementos

*   **Referencia por índice:** Se puede acceder a los elementos del array indicando su índice entre corchetes (empezando siempre por `0`). 
*   **Propiedad Count:** Para saber cuántos elementos tiene, se usa la propiedad `.count` (ej. `$n.count`).
*   **Añadir elementos:** Se pueden añadir elementos a un array existente mediante el operador `+=` o empleando el método `SetValue`.
*   **Eliminar elementos:** En los arrays estándar de PowerShell de tamaño fijo, no se puede "eliminar" un elemento directamente. La forma de hacerlo es creando un **nuevo array** que excluya el elemento no deseado.

**Ejemplo de uso de índices y `+=`:**
```powershell
PS C:\> $n = 1..5
PS C:\> $n.count
5
PS C:\> $n[0]
1
PS C:\> $a = @(0,3,4,2,5,8)
PS C:\> $a
0
3
4
2
5
8
PS C:\> $a.count
6
PS C:\> $a += 4
PS C:\> $a.count
7
PS C:\> $nuevoa = $a[0..3 + ($a.length - 1)]
```

---

## Operaciones Avanzadas y Tipos de Arrays

### Concatenación y Arrays de Objetos

*   **Concatenar:** El operador `+` permite concatenar arrays, incluso si almacenan distintos tipos de datos.
    ```powershell
    $eje5Array = $eje4Array + $eje3Array
    ```
*   **Almacenar ejecución de cmdlets:** Podemos guardar directamente la ejecución de cualquier cmdlet en un array, lo que genera un array de objetos.
    ```powershell
    $eje6Array = @(Get-Process)
    ```
    Si ejecutamos `$eje6Array.Count`, obtendremos el número exacto de procesos existentes.

## Tablas Hash (Diccionarios)

PowerShell soporta nativamente arrays asociativos o diccionarios (pares clave-valor), conocidos como **Tablas Hash** (*Hash tables*). A diferencia de los arrays normales que se inicializan con `@()`, las tablas hash se definen utilizando llaves `@{}`.

```powershell
$eje7Array = @{Ancho = 20; Alto = 30}
```

### Acceso y Modificación

Para acceder a un elemento concreto, usamos su clave entre corchetes o la notación de punto (como si fuera una propiedad):

```powershell
# Acceso mediante corchetes
PS C:\> $eje7Array["Ancho"]
20

# Acceso mediante notación de punto
PS C:\> $eje7Array.Alto
30
```

Para **añadir o modificar** elementos, la sintaxis es igualmente sencilla. No se usa `+=`, sino que se asigna directamente a la nueva clave o se usa el método `.Add()`:

```powershell
# Añadir o modificar asignando directamente a la clave
PS C:\> $eje7Array["Profundidad"] = 50

# Añadir usando el método Add
PS C:\> $eje7Array.Add("Peso", 15)
```

### Recorriendo una Tabla Hash

> **⚠️ Error común:** Si intentas recorrer una tabla hash usando un `foreach ($item in $eje7Array)` convencional, PowerShell tratará la tabla como un único objeto y el bucle solo dará una vuelta.

Para iterar correctamente por todos los pares de una tabla hash, debes recorrer sus **claves** (`.Keys`) o usar su enumerador. Puedes ver más sobre los bucles en [Estructuras de Control: Foreach](estructura-foreach.md).

```powershell
# Recorrer por claves
foreach ($clave in $eje7Array.Keys) {
    Write-Host "La clave $clave tiene el valor $($eje7Array[$clave])"
}

# Recorrer por el enumerador (pipeline)
$eje7Array.GetEnumerator() | ForEach-Object {
    Write-Host "Clave: $($_.Name) - Valor: $($_.Value)"
}
```

*Para profundizar en estos temas, se puede recurrir a los comandos de ayuda:* `Get-Help about_arrays` y `Get-Help about_hash_tables`.

---

## Ejemplos Prácticos

### Ejemplo 1: Array Hash para User y Pass

A continuación, crearemos un array tipo tabla hash con usuarios y contraseñas (hashes generados), y veremos un script para validarlos.

> [!NOTE]
> En este ejemplo usamos el término **hash** con dos significados diferentes:

> 1. Para referirnos a la estructura de datos (**tabla hash** o array asociativo) donde guardamos los usuarios y contraseñas.
> 2. Para referirnos al proceso de **codificación** unidireccional de contraseñas (por ejemplo, el *hash* resultante de aplicar SHA256).


**Paso 1: Script para hacer hash de cualquier string (`GeneraHash.ps1`)**

```powershell
# Se introduce una cadena de texto y devuelve el hash
Param(
    [Parameter(Mandatory,HelpMessage = 'Palabra para hacer hash')][string]$palabra,
    [Parameter(Mandatory,HelpMessage = 'Tipo de Hash (0=SHA1,1=SHA256,2=SHA384,3=SHA512,4=MD5)')][int]$Codificacion
)

$ArrayCodificacion = @('SHA1', 'SHA256', 'SHA384', 'SHA512', 'MD5')
$TipoCodificacion = $ArrayCodificacion[$Codificacion]

$stringAsStream = [System.IO.MemoryStream]::new()
$writer = [System.IO.StreamWriter]::new($stringAsStream)
$writer.Write($palabra)
$writer.Flush()
$stringAsStream.Position = 0
(Get-FileHash -InputStream $stringAsStream -Algorithm $TipoCodificacion | Select-Object Hash | Format-Table -HideTableHeaders | Out-String).Trim()
```

> **💡 Potencia de .NET en PowerShell:** Fíjate en cómo este script utiliza clases nativas de .NET (ej. `[System.IO.MemoryStream]::new()`). Esto demuestra la tremenda flexibilidad de PowerShell: cuando no existe un cmdlet nativo simple para lo que buscamos (como transformar texto a un flujo en memoria "al vuelo"), siempre podemos recurrir y apoyarnos en las clases del framework subyacente.

**Paso 2: Comprobación de credenciales (`AutenticaPasswordHASH.ps1`)**

Usaremos una tabla hash con los índices representando los nombres de usuario y los valores siendo sus contraseñas encriptadas en hash.

```powershell
# Script que comprueba que verifica user/pass

$HashUserPass = @{
    joseramon = '7B561A0E70E67935E28119795BF3F0EE535B2E4F';
    alumno = '684B10AB8DA41B83690BD96F9A846B9814D8A288'
}

$Usuario = Read-Host "Usuario:"
$Password = Read-Host "Contraseña:"

if ( $HashUserPass[$Usuario] ) {
    $PasswordHASH = .\GeneraHASH.ps1 -palabra $Password -Codificacion 0
    if ( $HashUserPass[$Usuario] -eq $PasswordHASH ) {
        Write-Host "Usuario y contraseña correctas. Puedes acceder"
    } else {
        Write-Host "Password incorrecto. No puedes acceder."
    }
} else {
    Write-Host "Usuario $Usuario no existe."
}
```

### Ejemplo 2: Array para creación masiva de usuarios locales

En este script partimos de un array clásico con nombres de usuarios y los creamos localmente. La contraseña será igual para todos, pero primero debe pasarse al tipo de dato encriptado `SecureString`.

```powershell
# Creación de usuarios locales

$Usuarios = @('maricarmen','pablo')

Foreach ($usuario in $Usuarios) {
    if ( Get-LocalUser $usuario -ErrorAction:SilentlyContinue) {
        Write-Host "El usuario $usuario ya existe."
    } else {
        $claveSegura = ConvertTo-SecureString '12345678' -AsPlainText -Force
        New-LocalUser -Name $usuario -Password $claveSegura -AccountNeverExpires | Out-Null
        Add-LocalGroupMember -Group usuarios -Member $usuario
    }
}
```

### Ejemplo 3: Variante del anterior utilizando un fichero externo (CSV)

Una variante muy utilizada consiste en no "quemar" el usuario y contraseña dentro del código (`hardcode`), sino utilizar un fichero externo, importarlo con `Import-Csv` (que nos devolverá un array de objetos con las propiedades definidas en la cabecera) y recorrerlo con un bucle `foreach`.

```powershell
# Creación masiva de usuarios a partir de fichero

$Usuarios = Import-Csv -Path '.\usuariosACrear.txt'

Foreach ($usuario in $Usuarios) {
    if ( Get-LocalUser $usuario.nombre -ErrorAction:SilentlyContinue) {
        Write-Host "El usuario $($usuario.nombre) ya existe."
    } else {
        $claveSegura = ConvertTo-SecureString $usuario.clave -AsPlainText -Force
        New-LocalUser -Name $usuario.nombre -Password $claveSegura -AccountNeverExpires | Out-Null
        Add-LocalGroupMember -Group usuarios -Member $usuario.nombre
    }
}
```

> **Nota importante:** `Import-Csv` devuelve las propiedades correspondientes a las cabeceras. En el ejemplo anterior, asume que la primera fila del fichero contiene las columnas `nombre` y `clave`, que se asignan a cada objeto iterado.

---

## 📚 Referencias y Fuentes Consultadas

!!! info "Documentación Oficial y Autoría"
    * **Material Base:** Presentación de clase *«Scripting en PowerShell. Arrays»*.
    * **Autoría del Temario:** José Ramón Soria Nieto.
    * **Marco Curricular:** Programación didáctica para el módulo de *Administración de Sistemas Operativos (ASO)* del Ciclo Formativo de Grado Superior en *Administración de Sistemas Informáticos en Red (ASIR/ASIX)*.
    * **Documentación Oficial:** [Documentación oficial de PowerShell (Microsoft Learn)](https://learn.microsoft.com/es-es/powershell/)

!!! abstract "Cofinanciación y Soporte Institucional"
    * **Entidad Educativa:** Generalitat Valenciana — Conselleria d'Educació, Cultura i Esport.
    * **Fondo de Financiación:** Proyecto cofinanciado por la **Unión Europea** a través del **Fondo Social Europeo (FSE)**. 
    * *«El FSE invierte en tu futuro»* — Acciones orientadas al impulso de la educación, formación avanzada y preparación para el mercado laboral técnico.
