# 5. Funciones en Bash

## 🎯 Relación con el Currículo (RA y CE)

La asimilación de los conceptos integrados en este bloque teórico-práctico permite verificar y evaluar el grado de consecución de los siguientes objetivos curriculares vinculados a la automatización de la infraestructura:

* **Resultado de Aprendizaje 3 (RA3):** Gestiona la automatización de tareas del sistema, aplicando criterios de eficiencia y utilizando comandos y herramientas gráficas.
    * *Criterios de evaluación vinculados:* CE1-RA3 (Planificación de tareas), CE2-RA3 (Creación de scripts de administración), CE3-RA3 (Automatización de rutinas repetitivas).
* **Resultado de Aprendizaje 2 (RA2):** Administra procesos del sistema describiéndolos y aplicando criterios de seguridad y eficiencia.
    * *Criterios de evaluación vinculados:* CE6-RA2 (Mantenimiento de sistemas mediante ejecución por lotes).

A medida que los scripts de automatización crecen (como un script de 300 líneas para inicializar el *File Server Samba* del Sprint 4), el "código espagueti" es insostenible. Las funciones modularizan y empaquetan rutinas operativas reutilizables.

## Sintaxis y Ámbito de Parámetros
En Bash, las funciones **no aceptan argumentos explicitados en los paréntesis**. Tienen su propio ecosistema de parámetros posicionales aislados (`$1`, `$2`), que sobreescriben temporalmente a los del script general al invocarse.

```bash
#!/bin/bash

# Definición de la función de auditoría de discos
verificar_espacio() {
    # 'local' limita el ámbito de la variable solo a las fronteras de esta función
    local DISCO=$1  
    echo "--- Verificando el porcentaje de ocupación del disco $DISCO ---"
    df -h | grep "$DISCO"
}

# Llamada directa a la función (pasando un argumento como si fuera un script)
verificar_espacio "/dev/sda1"
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
