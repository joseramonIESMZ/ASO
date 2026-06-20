# 4. Bucles y Repetición (for / while)

## 🎯 Relación con el Currículo (RA y CE)

La asimilación de los conceptos integrados en este bloque teórico-práctico permite verificar y evaluar el grado de consecución de los siguientes objetivos curriculares vinculados a la automatización de la infraestructura:

* **Resultado de Aprendizaje 3 (RA3):** Gestiona la automatización de tareas del sistema, aplicando criterios de eficiencia y utilizando comandos y herramientas gráficas.
    * *Criterios de evaluación vinculados:* CE1-RA3 (Planificación de tareas), CE2-RA3 (Creación de scripts de administración), CE3-RA3 (Automatización de rutinas repetitivas).
* **Resultado de Aprendizaje 2 (RA2):** Administra procesos del sistema describiéndolos y aplicando criterios de seguridad y eficiencia.
    * *Criterios de evaluación vinculados:* CE6-RA2 (Mantenimiento de sistemas mediante ejecución por lotes).

Los bucles iteran sobre listas de elementos, líneas de un texto o rangos numéricos de red.

## Bucle `for`
Perfecto para crear múltiples usuarios de un departamento, carpetas o auditar servidores de una lista.

```bash
# Iterar sobre una lista estática de cadenas
for SERVIDOR in "web" "bd" "dns"; do
    echo "Reiniciando servidor $SERVIDOR..."
done

# Iterar sobre un rango numérico (Generación masiva)
for i in {1..5}; do
    echo "Creando directorio /COMPARTIDO/alumno_$i"
    mkdir -p "/COMPARTIDO/alumno_$i"
done
```

## Bucle `while`
Se ejecuta indefinidamente "mientras" una condición sea verdadera. Su uso estrella en administración es leer archivos de configuración o de datos (como CSVs) línea por línea.

```bash
# Leer un archivo de texto secuencialmente
while read -r LINEA; do
    echo "Procesando usuario importado: $LINEA"
done < "lista_usuarios_nuevos.txt"
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
