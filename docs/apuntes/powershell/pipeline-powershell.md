# Uso del Pipeline y Manipulación de Datos

## Uso del Pipeline (`|`)

Al igual que en Linux, el uso del símbolo `|` (tubería o *pipe*, equivalente a la canalización de comandos) es muy frecuente entre los administradores de sistemas a la hora de enlazar la salida de un comando como entrada de otro.

```powershell
COMANDO 1 | COMANDO 2
```

En PowerShell, a diferencia de otros sistemas que envían flujos de texto, **el *pipe* transfiere objetos completos**. Los objetos de salida del "Comando 1" se convierten automáticamente en los objetos de entrada para el "Comando 2".

Se pueden encadenar tuberías para obtener un filtrado cada vez más selectivo.

```powershell
COMANDO 1 | COMANDO 2 | ... | COMANDO N
```
*Los objetos de salida del comando N-1 son la entrada para el comando N.*

Por ejemplo, el siguiente comando se representa gráficamente en el diagrama inferior:

```powershell
Get-Service | Where-Object Status -eq 'Running' | Select-Object Name, DisplayName
```

```mermaid
graph LR
    O1["📦 <b>Origen</b>"]
    
    Cmd1["⚙️ <b>Cmdlet 1 (Generador)</b><br>Ej. <i>Get-Service</i>"]
    Int1["📦📦📦<br><i>Muchos objetos íntegros</i>"]
    
    Cmd2["🔍 <b>Cmdlet 2 (Filtro)</b><br>Ej. <i>Where-Object</i>"]
    Int2["📦<br><i>Menos objetos íntegros</i>"]
    
    Cmd3["📋 <b>Cmdlet 3 (Recorte)</b><br>Ej. <i>Select-Object</i>"]
    
    O2["📝 <b>Resultado</b><br><i>Objetos filtrados<br>y con menos propiedades</i>"]

    O1 --> Cmd1
    Cmd1 -->|Tubería| Int1
    Int1 --> Cmd2
    Cmd2 -->|Tubería| Int2
    Int2 --> Cmd3
    Cmd3 -->|Tubería| O2

    style O1 fill:#f3f4f6,stroke:#9ca3af,stroke-width:2px,color:#000
    style Int1 fill:#f0fdf4,stroke:#16a34a,stroke-width:2px,color:#000,stroke-dasharray: 5 5
    style Int2 fill:#f0fdf4,stroke:#16a34a,stroke-width:2px,color:#000,stroke-dasharray: 5 5
    style O2 fill:#dbeafe,stroke:#3b82f6,stroke-width:2px,color:#000
    style Cmd1 fill:#e0e7ff,stroke:#4338ca,stroke-width:2px,color:#000,rx:10,ry:10
    style Cmd2 fill:#e0e7ff,stroke:#4338ca,stroke-width:2px,color:#000,rx:10,ry:10
    style Cmd3 fill:#e0e7ff,stroke:#4338ca,stroke-width:2px,color:#000,rx:10,ry:10
```

---

## Cmdlets principales para el procesamiento de objetos

A través de la tubería, solemos utilizar un conjunto de cmdlets fundamentales para filtrar, ordenar y agrupar la información. 

Los más utilizados son:

- `Select-Object`
- `Sort-Object`
- `Group-Object`
- `Where-Object`
- `Measure-Object`
- `ForEach-Object`

!!! info "Entorno de prácticas: Módulo PSTeachingTools"
    Para ilustrar el funcionamiento del pipeline de forma sencilla y didáctica, en los siguientes ejemplos utilizaremos datos ficticios sobre hortalizas (mediante comandos como `Get-Vegetable`) en lugar de comandos reales y complejos del sistema.
    
    Estos comandos de prueba pertenecen al módulo **`PSTeachingTools`**, alojado en el repositorio oficial de la comunidad (*PowerShell Gallery*).

    **1. Buscar el módulo**
    Antes de instalar nada, es una buena práctica comprobar que el módulo existe y está disponible en la galería:
    ```powershell
    Find-Module -Name PSTeachingTools
    ```
    
    **2. Instalar el módulo**
    Una vez comprobado, podemos descargarlo e instalarlo en nuestro equipo:
    ```powershell
    Install-Module -Name PSTeachingTools -Scope CurrentUser
    ```

    *(Nota: Si PowerShell te advierte de que PSGallery es un repositorio no de confianza, simplemente responde Sí `[Y]` o Sí a todo `[A]`).*

    - **`Install-Module`**: Se conecta a la PowerShell Gallery, descarga los archivos del módulo y los registra en tu equipo.
    - **`-Scope CurrentUser`**: Es un parámetro de seguridad crucial. Le indica a PowerShell que instale el módulo únicamente en la carpeta personal de tu usuario actual. Esto permite realizar la instalación **sin necesidad de permisos de Administrador** y evita alterar la configuración general del resto del sistema.
    
    **3. Comprobar los comandos que incluye el módulo**
    Antes de usar un módulo, es importante saber qué comandos nos ofrece. 
    ```powershell
    Get-Command -Module PSTeachingTools
    ```

### 1. `Select-Object` (alias: `select`)

Permite seleccionar solo las propiedades que nos interesan de un objeto o un subconjunto de los objetos (por ejemplo, los primeros 'x' objetos).

Antes de usar `Select-Object`, es fundamental saber cómo se llaman exactamente las propiedades. Para ello, siempre nos apoyaremos en `Get-Member`. 

Imagina que queremos seleccionar el estado de la hortaliza y probamos con la palabra `State` pero no funciona. Si examinamos el objeto, descubriremos su nombre real:

```powershell
# 1. Exploramos el objeto para ver sus propiedades reales
Get-Vegetable | Get-Member

# (Descubrimos que la propiedad del estado se llama "CookedState", no "State")

# 2. Ahora sí, seleccionamos las propiedades correctas
Get-Vegetable | Select-Object -Property Name, Count, CookedState

# Selecciona únicamente el primer objeto de la lista
Get-Vegetable | Select-Object -First 1

# Selecciona valores únicos (sin duplicados)
Get-Vegetable | Select-Object State -Unique
```

!!! tip "Select-Object vs Format-Table / Format-List"
    Es común confundir `Select-Object` con los comandos de formato (`Format-Table`, `Format-List`). 
    
    - **`Select-Object`** **modifica** la estructura real del objeto de datos (crea uno nuevo con menos propiedades) para seguir usándolo en la tubería o guardarlo en una variable.
    - **`Format-*`** destruye el objeto original y lo convierte en **simple texto** (directivas de formato visual) pensado exclusivamente para pintar tablas o listas por pantalla. **Regla general:** Nunca pongas un comando después de un `Format-*` en la tubería. Al haber perdido su estructura de objeto y haberse convertido en texto plano, los comandos posteriores serán incapaces de interpretar, entender o filtrar esos datos.

!!! tip "Visualización interactiva con Out-GridView (ogv)"
    Si trabajas en un entorno de escritorio Windows, puedes añadir `| Out-GridView` al final de tu pipeline para enviar los objetos a una ventana interactiva. Esta ventana te permite ordenar alfabéticamente haciendo clic en las columnas y aplicar filtros dinámicos en vivo sin tener que modificar tu código.

### 2. `Sort-Object` (alias: `sort`)

Permite ordenar los objetos basándose en los valores de una o varias de sus propiedades.

```powershell
# Ordena por defecto en orden ascendente
Get-Vegetable | Sort-Object -Property Count

# Ordena en orden descendente usando el parámetro -Descending
Get-Vegetable | Sort-Object Count -Descending

# Ordena por una propiedad, conservando solo ciertas propiedades visibles
Get-Vegetable | Sort-Object Count -Descending | Select-Object Count, Name
```

### 3. `Group-Object` (alias: `group`)

Agrupa los objetos que contienen el mismo valor para las propiedades especificadas. Retorna nuevos objetos de agrupación (`GroupInfo`) que contienen tres propiedades principales: `Count` (cantidad), `Name` (el valor agrupado) y `Group` (una lista que encierra los objetos originales).

```powershell
# Agrupa los objetos por su color
Get-Vegetable | Group-Object -Property Color

# Agrupa y cuenta de forma ordenada
Get-Vegetable | Group-Object Color | Sort-Object Count -Descending
```

Si solo nos interesa el resumen estadístico (las columnas `Count` y `Name`) y queremos **obviar** la columna `Group` que contiene todos los objetos (muy útil para mejorar el rendimiento si hay miles de datos), usamos el parámetro `-NoElement`:
```powershell
Get-Vegetable | Group-Object Color -NoElement
```

Por el contrario, si nuestro objetivo es "desglosar" o extraer los elementos concretos que han quedado guardados dentro de una agrupación, usaremos `Select-Object`:
```powershell
Get-Vegetable | Group-Object Color | Select-Object -ExpandProperty Group
```

### 4. `Where-Object` (alias: `where` o `?`)

Permite filtrar objetos de una colección según el valor de sus propiedades.

!!! warning "IMPORTANTE: Regla de Oro en PowerShell (Filter Left, Format Right)"
    **¡NO uses `Where-Object` si el cmdlet origen tiene un parámetro para filtrar directamente!**
    Es mucho más eficiente que el comando origen ya traiga la información filtrada (usando sus propios parámetros, por ejemplo `-Filter` o `-Name`) antes que enviar miles de objetos por la tubería para que `Where-Object` los descarte después.
    
    Observa la diferencia de rendimiento (especialmente notable en búsquedas grandes):
    ```powershell
    # ❌ MAL: Lento y costoso (trae absolutamente todos los archivos y luego descarta)
    Get-ChildItem -Path C:\Windows | Where-Object Extension -eq '.txt'
    
    # ✅ BIEN: Rápido y eficiente (el sistema de archivos filtra directamente)
    Get-ChildItem -Path C:\Windows -Filter *.txt
    ```

**Formas de lanzar `Where-Object`**:

Existen sintaxis simplificadas y sintaxis de bloque de script (scriptblock).
```powershell
# Sintaxis básica especificando el nombre de la propiedad
Get-Vegetable | Where-Object -Property Color -eq 'yellow'

# Sintaxis simplificada
Get-Vegetable | Where Color -eq 'yellow'

# Sintaxis de ScriptBlock (usando $_ que representa "el objeto actual en el pipe")
Get-Vegetable | Where-Object { $_.Color -eq 'yellow' }
```

!!! info "Comprendiendo la variable `$_` (o `$PSItem`)"
    Al trabajar con bloques de script en la tubería (`{ ... }`), necesitas una forma de referirte al objeto que está pasando por ese "tramo" del tubo en cada iteración.
    
    Ahí entra **`$_`** (también puedes usar **`$PSItem`**; son exactamente lo mismo). Imagina que es un comodín que significa *"el objeto actual que estoy procesando"*. Así, `$_.Color` significa *"lee la propiedad Color del objeto actual"*.

Se pueden aplicar comparadores múltiples:
```powershell
Get-Vegetable | Where-Object { $_.Count -gt 10 -and $_.Color -eq 'green' } | Sort-Object Count -Descending
```

#### Comparadores en PowerShell

PowerShell utiliza operadores especiales para las comparaciones. Por defecto, **no distinguen entre mayúsculas y minúsculas** (case-insensitive). Si necesitas distinción, añade una `c` delante (ej. `-ceq`).

| Operador | Descripción (Comparación) |
| :--- | :--- |
| `-eq` | Igual a (equals) |
| `-ne` | No igual a (not equals) |
| `-gt` | Mayor que (greater than) |
| `-ge` | Mayor o igual que (greater than or equal) |
| `-lt` | Menor que (less than) |
| `-le` | Menor o igual que (less than or equal) |
| `-like` | Coincidencia de cadenas con comodines (`*`, `?`) |
| `-notlike` | No coincidencia de cadenas con comodines |
| `-match` | Coincidencia con expresión regular (Regex) |
| `-notmatch`| No coincidencia con expresión regular |

Ejemplos numéricos y de texto:
```powershell
1 -eq 1           # True
1 -lt 5           # True
'jose' -eq 'Jose' # True
'jose' -ceq 'Jose'# False
'jose' -like 'jo*'# True
```

### 5. `Measure-Object` (alias: `measure`)

Calcula propiedades numéricas de los objetos o cuenta líneas, palabras o caracteres en los objetos de texto (cadenas).

Podemos obtener mediciones como suma, media, máximo y mínimo indicando los parámetros adecuados:

```powershell
# Realiza el conteo general y devuelve cálculos de la propiedad Count
Get-Vegetable | Measure-Object -Property Count -Sum -Average -Maximum -Minimum

# Ejemplo calculando la longitud de los archivos de una carpeta
dir c:\windows\*.exe | Measure-Object Length -Sum -Average -Maximum -Minimum

# Ejemplo analizando el uso de memoria de los procesos del sistema
Get-Process | Measure-Object WorkingSet, PeakWorkingSet -Sum -Average
```

### 6. `ForEach-Object` (alias: `foreach` o `%`)

Permite ejecutar un bloque de código (script block) específico para cada uno de los objetos que pasen por la tubería. Es indispensable cuando necesitas manipular los objetos uno a uno, invocar métodos en ellos o ejecutar acciones repetitivas que no pueden hacerse mediante otros cmdlets.

Al igual que en `Where-Object` con sintaxis de script block, utilizamos la variable `$_` para referirnos al objeto que estamos procesando en esa iteración concreta.

```powershell
# Recorre cada hortaliza e imprime un mensaje personalizado
Get-Vegetable | ForEach-Object { Write-Host "Tenemos $($_.Count) unidades de $($_.Name)" }

# También se puede usar para modificar datos al vuelo, crear nuevos objetos, etc.
Get-Vegetable | ForEach-Object { $_.Name = $_.Name.ToUpper(); $_ }
```

## 📝 Ejercicios Prácticos

A continuación se plantean una serie de ejercicios para poner en práctica el uso del pipeline y los cmdlets de manipulación de objetos.

### Agrupación (`Group-Object`)

1. **Agrupa y cuenta los objetos procesos existentes según el nombre del proceso. Elimina la columna Group.**
??? success "Ver solución"
    ```powershell
    Get-Process | Get-Member -Type Property
    Get-Process | Group-Object -Property Name -NoElement
    ```

2. **Agrupa y cuenta según su extensión los objetos ficheros dentro del directorio en el que te encuentres.**
??? success "Ver solución"
    ```powershell
    Get-ChildItem | Get-Member -Type Property
    Get-ChildItem -Recurse -File . | Group-Object -Property Extension
    ```

3. **Agrupa y cuenta los objetos servicios existentes según su estado (ejecución, parados, etc).**
??? success "Ver solución"
    ```powershell
    Get-Service | Get-Member -Type Property
    Get-Service | Group-Object -Property Status
    ```

4. **Agrupa y cuenta los objetos servicios existentes según su tipo de inicio (automático, manual, etc) y en orden descendente.**
??? success "Ver solución"
    ```powershell
    Get-Service | Get-Member -Type Property
    Get-Service | Group-Object -Property StartType
    ```

5. **Agrupa y cuenta los objetos servicios existentes según dos propiedades, estado y tipo de inicio.**
??? success "Ver solución"
    ```powershell
    Get-Service | Group-Object -Property Status,StartType
    ```

### Mediciones (`Measure-Object`)

1. **Cuenta los comandos de los módulos Microsoft.PowerShell.Security y Microsoft.PowerShell.Utility.**
??? success "Ver solución"
    ```powershell
    Get-Command -Module Microsoft.PowerShell.Security | Measure-Object
    Get-Command -Module Microsoft.PowerShell.Security,Microsoft.PowerShell.Utility | Measure-Object
    ```

2. **Muestra todas las estadísticas del tamaño de los archivos .pdf dentro de la carpeta `C:\Users\tu usuario`.**
??? success "Ver solución"
    ```powershell
    Get-ChildItem -File -Recurse -Include "*.pdf" C:\Users\joseramon | Measure-Object -Property Length -Sum -Average -Maximum -Minimum
    ```

3. **Arranca varias ventanas del navegador firefox (serán varios procesos). Muestra la suma y media de las propiedades WorkingSet y PeakWorkingSet de dichos procesos.**
??? success "Ver solución"
    ```powershell
    Get-Process -Name firefox | Measure-Object -Property WorkingSet,PeakWorkingSet -Sum -Average
    ```

4. **Cuenta los servicios en estado RUNNING.**
??? success "Ver solución"
    ```powershell
    Get-Service | Where Status -eq "Running" | Measure-Object
    ```

5. **Muestra la suma de CPU de los 5 primeros procesos que más usan CPU.**
??? success "Ver solución"
    ```powershell
    Get-Process | Sort-Object -Property CPU -Descending | Select -First 5 | Measure-Object -Property CPU -Sum
    ```

### Selección (`Select-Object`) y Cmdlets Básicos

1. **Con el cmdlet `Get-Process`:**
    * **Muestra la ayuda y explica en qué consiste.**
    * **Muestra las propiedades y métodos de los objetos que devuelve.**
    * **Muestra los objetos con las propiedades ProcessName, Id y Ws.**
??? success "Ver solución"
    ```powershell
    Get-Help Get-Process -Full
    # Get-Process muestra los procesos del sistema (programas en ejecución).
    
    Get-Process | Get-Member
    
    Get-Process | Select-Object ProcessName,Id,Ws
    ```

2. **Muestra los procesos del sistema pero donde únicamente aparezca su nombre y no repetido.**
??? success "Ver solución"
    ```powershell
    Get-Process | Select-Object -Unique Name
    ```

3. **El cmdlet `Get-ChildItem` permite ver el contenido de un directorio, similar al comando dir.exe. Busca en su ayuda los parámetros necesarios para lanzar este cmdlet y que muestre:**
    * **a) todos los ficheros y directorios dentro de `C:\Users\`**
    * **b) sólo los directorios y subdirectorios, no los archivos, de `C:\Users`**
??? success "Ver solución"
    ```powershell
    Get-Help Get-ChildItem # Encontramos las opciones -Recurse y -Directory
    
    # a)
    Get-ChildItem -Recurse C:\Users
    
    # b)
    Get-ChildItem -Recurse -Directory C:\Users 
    ```

4. **Para el comando anterior (sólo directorios), muestra únicamente:**
    * **a. los dos primeros directorios.**
    * **b. los dos últimos directorios.**
??? success "Ver solución"
    ```powershell
    # a)
    Get-ChildItem -Recurse -Directory C:\Users | Select-Object -First 2
    
    # b)
    Get-ChildItem -Recurse -Directory C:\Users | Select-Object -Last 2
    ```

### Ordenación (`Sort-Object`)

1. **Ordena por nombre los objetos archivos y carpetas contenidos en la carpeta `C:\Windows` (no subcarpetas).**
??? success "Ver solución"
    ```powershell
    Get-ChildItem C:\Windows | Get-Member -Type Property # -> Identificamos la propiedad Name
    Get-ChildItem C:\Windows | Sort-Object -Property Name
    ```

2. **Ordena por tamaños los objetos archivos y carpetas contenidos en la carpeta `C:\Users`, incluido subcarpetas y muestra únicamente los 3 últimos.**
??? success "Ver solución"
    ```powershell
    Get-ChildItem -Recurse C:\Users | Sort-Object -Property Length | Select-Object -Last 3
    
    # También de mayor a menor tamaño pero sólo muestra los 3 primeros.
    Get-ChildItem -Recurse C:\Users | Sort-Object -Property Length -Descending | Select-Object -First 3
    ```

3. **Mostrar los objetos comandos lanzados en el historial de comandos de forma que los más recientes aparezcan en primer lugar. Cmdlet es `Get-History`.**
??? success "Ver solución"
    ```powershell
    Get-History | Sort-Object -Property Id -Descending
    ```

4. **Muestra los objetos procesos ordenados de mayor a menor por el uso de memoria física (propiedad WS).**
??? success "Ver solución"
    ```powershell
    Get-Process | Sort-Object -Property WS -Descending
    ```

### Filtrado (`Where-Object`)

1. **Ver los archivos dentro de la carpeta `C:\Users` y subcarpetas cuya extensión es .png. Debes mostrar dos soluciones, una con `Get-ChildItem` y `Where-Object` y otra con el parámetro `-Include` de `Get-ChildItem` (revisa la ayuda).**
??? success "Ver solución"
    ```powershell
    Get-ChildItem | Get-Member
    
    # Con -Include
    Get-ChildItem -Recurse -Include "*.png" C:\Users
    
    # Con Where-Object
    Get-ChildItem -Recurse C:\Users | Where-Object Extension -eq ".png"
    ```

2. **Ver los servicios en estado de ejecución.**
??? success "Ver solución"
    ```powershell
    Get-Service | Get-Member
    Get-Service | Where-Object status -eq "Running"
    ```

3. **Ver los servicios cuyo tipo de inicio sea automático.**
??? success "Ver solución"
    ```powershell
    Get-Service | Where-Object StartType -eq "Automatic"
    ```

4. **Ver los procesos cuyo uso de CPU en ese instante sea mayor que 10.**
??? success "Ver solución"
    ```powershell
    Get-Process | Get-Member # -> Identificamos CPU
    Get-Process | Where-Object CPU -gt 10
    ```

5. **El comando `Get-CimInstance CIM_LogicalDisk` muestra las unidades lógicas del equipo. Utiliza `Where-Object` para filtrar únicamente las unidades lógicas con tamaño mayor de 500GB.**
??? success "Ver solución"
    ```powershell
    Get-CimInstance CIM_LogicalDisk | Get-Member # -> Identificamos Size
    Get-CimInstance CIM_LogicalDisk | Where-Object Size -gt 500GB
    ```

---

## 📚 Referencias y Fuentes Consultadas

!!! info "Documentación Oficial y Autoría"
    * **Material Base:** Presentación de clase *«Administración de Sistemas. Uso del pipeline. Cmdlets para el filtrado, ordenación, agrupación, estadística, de los objetos»* (PDF adjunto).
    * **Autoría del Temario:** José Ramón Soria Nieto.
    * **Marco Curricular:** Programación didáctica para el módulo de *Administración de Sistemas Operativos (ASO)* del Ciclo Formativo de Grado Superior en *Administración de Sistemas Informáticos en Red (ASIR/ASIX)*.
    * **Documentación Oficial:** [Documentación oficial de PowerShell (Microsoft Learn)](https://learn.microsoft.com/es-es/powershell/)

!!! abstract "Cofinanciación y Soporte Institucional"
    * **Entidad Educativa:** Generalitat Valenciana — Conselleria d'Educació, Cultura i Esport.
    * **Fondo de Financiación:** Proyecto cofinanciado por la **Unión Europea** a través del **Fondo Social Europeo (FSE)**. 
    * *«El FSE invierte en tu futuro»* — Acciones orientadas al impulso de la educación, formación avanzada y preparación para el mercado laboral técnico.
