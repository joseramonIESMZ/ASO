# 6. Laboratorio de Desafíos y Troubleshooting

## 🎯 Relación con el Currículo (RA y CE)

La asimilación de los conceptos integrados en este bloque teórico-práctico permite verificar y evaluar el grado de consecución de los siguientes objetivos curriculares vinculados a la automatización de la infraestructura:

* **Resultado de Aprendizaje 3 (RA3):** Gestiona la automatización de tareas del sistema, aplicando criterios de eficiencia y utilizando comandos y herramientas gráficas.
    * *Criterios de evaluación vinculados:* CE1-RA3 (Planificación de tareas), CE2-RA3 (Creación de scripts de administración), CE3-RA3 (Automatización de rutinas repetitivas).
* **Resultado de Aprendizaje 2 (RA2):** Administra procesos del sistema describiéndolos y aplicando criterios de seguridad y eficiencia.
    * *Criterios de evaluación vinculados:* CE6-RA2 (Mantenimiento de sistemas mediante ejecución por lotes).

## 💥 Caso Práctico: El Desastre del "Word Splitting" y Parseo de `ls`

- **Síntoma:** Un alumno de ASO crea un script de respaldo masivo de las carpetas personales de todos los usuarios del sistema:
  ```bash
  for CARPETA in $(ls /home/alumnos/); do
      tar -czf "$CARPETA.tar.gz" "/home/alumnos/$CARPETA"
  done
  ```
  Al ejecutarlo, si un usuario se llama `Jose Ramon` (con un espacio en blanco en el nombre de su carpeta), el script colapsa violentamente arrojando los errores: `tar: /home/alumnos/Jose: No existe el archivo o el directorio` y `tar: Ramon: No existe...`.
- **Causa Raíz:** En Bash, la expansión y salida de subcomandos como `$(ls)` sufre un proceso nativo llamado **Word Splitting** (división de palabras). Bash interpreta cualquier espacio en blanco (como el que hay entre *Jose* y *Ramon*) como el delimitador natural del bucle `for`, creyendo que se trata de dos carpetas completamente distintas. Adicionalmente, tratar de procesar o parsear la salida de `ls` en scripts es considerado históricamente una de las peores prácticas de la industria.
- **Solución Operativa en Clase:** Para recorrer archivos y directorios con total seguridad, el alumno debe evitar usar herramientas visuales como `ls` en los bucles y dejar que Bash expanda y resuelva directamente las rutas mediante "Globbing" (el uso de asteriscos). Y fundamentalmente, **usar siempre comillas dobles** al invocar las variables que contengan rutas.

    ```bash
    # Solución profesional, resiliente y a prueba de espacios en blanco
    for CARPETA in /home/alumnos/*; do
        if [ -d "$CARPETA" ]; then
            # 'basename' extrae el nombre final quitando toda la ruta base
            BASE=$(basename "$CARPETA")
            
            # Las comillas dobles protegen el espacio en "$CARPETA"
            tar -czf "${BASE}.tar.gz" "$CARPETA"
            echo "[OK] Copia de seguridad comprimida exitosamente: $BASE"
        fi
    done
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
