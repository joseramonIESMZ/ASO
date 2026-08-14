# Casos de Uso y Administración con PowerShell

## Metodología de Resolución de Incidencias

A la hora de enfrentarse a un problema en el sistema, es recomendable seguir un ciclo claro:

1. **Identificar el problema**
2. **Encontrar su causa**
3. **Determinar e implementar una solución**
4. **Verificar los resultados**

!!! caution "Regla de oro"
    **No implementar varias soluciones sin verificar primero cada una de ellas.** Si cambias muchas cosas a la vez, no sabrás qué acción solucionó el problema o si alguna de ellas causó efectos secundarios.

En PowerShell, buscar la solución suele implicar el uso consecutivo de tres comandos clave para descubrir qué herramienta necesitamos y cómo usarla:

1. `Get-Command` para encontrar el comando.
2. `Get-Help` para ver su ayuda y ejemplos.
3. `Get-Member` para observar las propiedades y métodos de los objetos devueltos.

---

## Escenario 1: Problemas con el Escritorio Remoto

**Problema**: No se puede conectar por escritorio remoto a otro equipo.

**Pasos de comprobación**:
1. En el equipo remoto comprobamos que el servicio de Escritorio Remoto (`TermService`) está en ejecución:
   ```powershell
   Get-Service -DisplayName "*Escritorio remoto*"
   ```
2. Verificamos que está escuchando en el puerto TCP/UDP 3389. Para ello buscamos comandos de red:
   ```powershell
   # Vemos los módulos disponibles y buscamos comandos de red
   Get-Module -ListAvailable
   Get-Command -Module NetTCPIP
   
   # Consultamos la ayuda y miramos las propiedades
   Help Get-NetTCPConnection
   Get-NetTCPConnection | Get-Member
   
   # Comprobamos el puerto 3389
   Get-NetTCPConnection -LocalPort 3389
   ```
3. Si los servicios están correctos, comprobamos el Firewall de Windows para verificar que permite la conexión entrante:
   ```powershell
   # Buscamos comandos de firewall
   Get-Command -Name *Fire*
   Help Get-NetFirewallRule
   
   # Buscamos la regla específica de Remote Desktop
   Get-NetFirewallRule -Name *RemoteDesktop* | Format-Table
   ```
4. Si la regla no está habilitada, la activamos:
   ```powershell
   Get-NetFirewallRule -Name *RemoteDesktop* | Set-NetFirewallRule -Enabled True
   ```

---

## Escenario 2: Monitor de Rendimiento (Contadores)

**Problema**: Queremos acceder a los contadores o parámetros del Monitor de Rendimiento de Windows.

**Pasos**:
1. Buscamos el comando adecuado para trabajar con contadores:
   ```powershell
   Get-Command -Name *Counter*
   ```
2. Los contadores de rendimiento están agrupados por listas (ListSet). Podemos listarlas:
   ```powershell
   Get-Counter -ListSet * | Select CounterSetName, Description | Sort CounterSetName
   ```
3. **Ejemplo 1: Memoria Física Disponible**. Buscamos el set de memoria y obtenemos el valor del contador específico:
   ```powershell
   Get-Counter -Counter "\Memoria\Bytes disponibles"
   ```
4. **Ejemplo 2: Uso de Procesador en tiempo real**. Nos interesa el porcentaje de tiempo de procesador cada 2 segundos y de forma continua:
   ```powershell
   Get-Counter -ListSet Procesador
   Get-Counter -Counter "\Procesador(*)\% de tiempo de procesador" -SampleInterval 2 -Continuous
   ```

!!! note "Localización de los Contadores de Rendimiento"
    Los nombres de los contadores y conjuntos de contadores de rendimiento en Windows están vinculados al idioma original de la instalación del sistema operativo (*OS base language*). Si el sistema se instaló originalmente en inglés y posteriormente se aplicó un paquete de idioma (*Language Pack*) en español, es posible que los identificadores de los contadores permanezcan en inglés. En tal caso, las consultas requerirán el uso de los nombres en ese idioma; por ejemplo, `\Memory\Available Bytes` en lugar de `\Memoria\Bytes disponibles` o `\Processor(*)\% Processor Time` en lugar de `\Procesador(*)\% de tiempo de procesador`.

---

## Escenario 3: Identificación del Hardware (CIM/WMI)

**Problema**: Identificar memoria y tarjeta gráfica instalada en el equipo.

Se recomienda usar el estándar abierto **CIM** (Common Information Model) en lugar del antiguo WMI (`Win32_...`) propio de Microsoft, pensando en el uso actual y futuro. A diferencia de WMI (que usa DCOM y suele ser bloqueado por los cortafuegos), CIM utiliza el protocolo estándar WS-Man (WinRM), que es mucho más amigable con las redes modernas.

```powershell
# Búsqueda de clases CIM relacionadas con memoria
Get-CimClass -ClassName *memor*

# Consultar la Memoria Física
Get-CimInstance -ClassName CIM_PhysicalMemory | Select-Object Tag, Capacity

# Búsqueda y consulta de la Tarjeta Gráfica
Get-CimClass -ClassName *video*
Get-CimInstance -ClassName CIM_VideoController | Select-Object Name, DeviceID, VideoProcessor, AdapterRAM
```

Alternativamente, hay un cmdlet más genérico y moderno muy útil:
```powershell
Get-ComputerInfo -Property *memory*
```

---

## Escenario 4: Información de Red

**Problema**: Obtener información de la configuración de red y carpetas compartidas.

```powershell
# Búsqueda y consulta de IP y adaptadores
Get-Command Get-NetIP*
Get-NetIPAddress
Get-NetIPConfiguration | Select-Object InterfaceAlias, IPv4Address

# Consultas sobre DNS
Get-Command Get-*DNS*
Get-DnsClientCache
Get-DnsClientServerAddress

# Para gestión de carpetas compartidas (SMB)
Get-Command *SMB*
Help New-SmbMapping -Examples
```

---

## Escenario 5: Logs del Sistema (Reinicios)

**Problema**: Consultar el visor de eventos para encontrar los reinicios/apagados del equipo.

```powershell
# Buscar comandos de Eventos
Get-Command Get-*Event*

# Listar qué logs tenemos en el sistema
Get-WinEvent -ListLog *

# Buscar el evento 1074 (Apagado/Reinicio) en el log de 'System' y exportarlo
Get-WinEvent -LogName System | Get-Member
Get-WinEvent -FilterHashTable @{ LogName = 'System'; Id = 1074 } | Format-Table -Wrap -AutoSize | Out-File 'apagados.txt'

# Buena práctica: Exportar a CSV para guardar los objetos estructurados en lugar de texto plano
Get-WinEvent -FilterHashTable @{ LogName = 'System'; Id = 1074 } | Select-Object TimeCreated, Id, Message | Export-Csv -Path 'apagados.csv' -NoTypeInformation
```

---

## Escenario 6: Búsqueda de Archivos

**Problema**: Buscar archivos `.png` en la unidad "D".

Para listar archivos se usa `Get-ChildItem` (similar a `dir` o `ls`).

!!! important
    ¡No usar `Where-Object` cuando se puede hacer lo mismo con un parámetro nativo del propio cmdlet!

**FORMA CORRECTA (Usando el parámetro `-Filter` nativo):**
```powershell
Get-ChildItem -Path D:\ -Recurse -Filter *.png | Format-Table Directory, Name, LastWriteTime
```

**FORMA INCORRECTA (Lenta y poco eficiente):**
```powershell
# Esto es menos óptimo porque recoge TODOS los archivos primero y luego los filtra uno a uno.
Get-ChildItem -Path D:\ -Recurse | Where-Object Extension -eq '.png'
```

---

## Escenario 7 y 8: Gestión de Archivos y Carpetas

**Problema**: Crear, mover, copiar y borrar elementos del sistema de ficheros.

```powershell
# 1. Crear directorio y archivo
New-Item -Path 'c:\' -Name 'Origen' -ItemType Directory -Verbose
New-Item -Path 'c:\Origen' -Name 'fichero.txt' -ItemType File -Value 'Este es un fichero de texto' -Verbose

# 2. Mover archivo
New-Item -Path 'c:\' -Name 'Destino' -ItemType Directory -Verbose
Move-Item -Path 'C:\Origen\fichero.txt' -Destination 'C:\Destino\' -Verbose

# 3. Copiar archivo (lo copiamos de vuelta al origen)
Copy-Item -Path 'c:\Destino\fichero.txt' -Destination 'c:\Origen\' -Verbose

# 4. Eliminar archivo
Remove-Item -Path 'c:\Origen\fichero.txt' -Verbose
```

---

## Escenario 9: Rendimiento de Procesos (Consumo de RAM)

**Problema**: Obtener los 5 procesos que mayor uso de memoria (propiedad `WorkingSet` o `WS`) presentan en el sistema.

```powershell
Get-Process | Sort-Object -Property WorkingSet -Descending | Select-Object -First 5 ID, Name, WS, Handles
```

---

## Escenario 10: Acceso y Administración Remota

A menudo los técnicos acceden por consola a servidores alojados en CPDs o en la nube. Existen alternativas como WMI, SSH, RPC, pero en Windows el estándar utilizado es **WinRM** a través de PowerShell.

### 1. Habilitar el acceso en el Servidor
En el servidor al que nos queremos conectar, basta con habilitar la escucha:
```powershell
Enable-PSRemoting
```

### 2. Conexión desde el equipo Cliente
En la parte cliente, obtenemos credenciales, creamos la sesión y entramos en ella:
```powershell
$credencial = Get-Credential
$Sesion = New-PSSession -ComputerName NOMBRE-SERVIDOR -Credential $credencial
Enter-PSSession -Session $Sesion
```

!!! note
    Si el cliente **no está en el dominio** del servidor o no accede por dominio, debes añadir al servidor en los equipos de confianza (TrustedHosts) del cliente ejecutando:
    `Set-Item wsman:\localhost\Client\TrustedHosts -Value "nombre-servidor"`

### 3. Ejecución de comandos remotos en segundo plano
Resulta útil lanzar comandos remotamente sin tener que entrar en la sesión interactiva completa:
```powershell
Invoke-Command -ComputerName NOMBRE-SERVIDOR -Credential $credencial -ScriptBlock { Comando-PS }
```

---

## 📚 Referencias y Fuentes Consultadas

!!! info "Documentación Oficial y Autoría"
    * **Material Base:** Presentación de clase *«Administración de Sistemas. Casos de uso»* (PDF adjunto).
    * **Autoría del Temario:** José Ramón Soria Nieto.
    * **Marco Curricular:** Programación didáctica para el módulo de *Administración de Sistemas Operativos (ASO)* del Ciclo Formativo de Grado Superior en *Administración de Sistemas Informáticos en Red (ASIR/ASIX)*.
    * **Documentación Oficial:** [Documentación oficial de PowerShell (Microsoft Learn)](https://learn.microsoft.com/es-es/powershell/)

!!! abstract "Cofinanciación y Soporte Institucional"
    * **Entidad Educativa:** Generalitat Valenciana — Conselleria d'Educació, Cultura i Esport.
    * **Fondo de Financiación:** Proyecto cofinanciado por la **Unión Europea** a través del **Fondo Social Europeo (FSE)**. 
    * *«El FSE invierte en tu futuro»* — Acciones orientadas al impulso de la educación, formación avanzada y preparación para el mercado laboral técnico.
