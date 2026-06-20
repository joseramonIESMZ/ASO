# 1. Fundamentos de Bash Scripting y Variables

## 🎯 Relación con el Currículo (RA y CE)

La asimilación de los conceptos integrados en este bloque teórico-práctico permite verificar y evaluar el grado de consecución de los siguientes objetivos curriculares vinculados a la automatización de la infraestructura:

* **Resultado de Aprendizaje 3 (RA3):** Gestiona la automatización de tareas del sistema, aplicando criterios de eficiencia y utilizando comandos y herramientas gráficas.
    * *Criterios de evaluación vinculados:* CE1-RA3 (Planificación de tareas), CE2-RA3 (Creación de scripts de administración), CE3-RA3 (Automatización de rutinas repetitivas).
* **Resultado de Aprendizaje 2 (RA2):** Administra procesos del sistema describiéndolos y aplicando criterios de seguridad y eficiencia.
    * *Criterios de evaluación vinculados:* CE6-RA2 (Mantenimiento de sistemas mediante ejecución por lotes).

## 🏢 Aspectos Clave: El Poder de Bash en ASO

En el entorno de administración real (*ASO INNOVATEC*), operar servidores Linux (como nuestros contenedores LXC Ubuntu Server) escribiendo comandos uno a uno en la terminal es ineficiente y propenso a errores humanos. **Bash** (*Bourne Again SHell*) no solo es nuestro intérprete de comandos por defecto, sino que es un lenguaje de programación estructurado completo. 

Escribir scripts en Bash nos permite estandarizar despliegues, automatizar copias de seguridad nocturnas y realizar auditorías masivas de seguridad en milisegundos. 

---

## 📑 Variables y Entorno

En Bash, las variables almacenan información en la memoria durante la ejecución del script. A diferencia de lenguajes como Java o C#, Bash no es tipado (todo se trata inicialmente como texto).

### Declaración y Asignación
La regla de oro de Bash es que **NO debe haber espacios** alrededor del signo igual `=`.

```bash
# Correcto
DIRECTORIO="/COMPARTIDO/backup"
EDAD=25

# Incorrecto (Lanzará el error: command not found)
DIRECTORIO = "/COMPARTIDO/backup"
```

### Comillas Simples vs. Comillas Dobles
- **Dobles Comillas (`""`):** Permiten la expansión de variables en su interior.
- **Comillas Simples (`''`):** Son literales estrictos. Muestran el texto tal cual y bloquean cualquier expansión.

```bash
USUARIO="root"
echo "Hola $USUARIO" # Salida: Hola root
echo 'Hola $USUARIO' # Salida: Hola $USUARIO
```

---

## 📚 Referencias y Fuentes Consultadas

!!! info "Documentación Oficial y Autoría"
    * **Material Base:** Basado en la arquitectura didáctica y los apuntes de automatización (Bash Scripting) del Departamento de Informática del **IES Marcos Zaragoza**.
    * **Autoría del Temario:** José Ramón.
    * **Marco Curricular:** Programación didáctica para el módulo de *Administración de Sistemas Operativos (ASO)* del Ciclo Formativo de Grado Superior en *Administración de Sistemas Informáticos en Red (ASIR/ASIX)*.
    * **Material adicional:** [GNU Bash Reference Manual (Oficial)](https://www.gnu.org/software/bash/manual/bash.html).

!!! abstract "Cofinanciación y Soporte Institucional"
    * **Entidad Educativa:** Generalitat Valenciana — Conselleria d'Educació, Cultura i Esport.
    * **Fondo de Financiación:** Proyecto cofinanciado por la **Unión Europea** a través del **Fondo Social Europeo (FSE)**.
    * *«El FSE invierte en tu futuro»* — Acciones orientadas al impulso de la educación, formación avanzada y preparación para el mercado laboral técnico.
