# 2. Parámetros Posicionales (Argumentos)

## 🎯 Relación con el Currículo (RA y CE)

La asimilación de los conceptos integrados en este bloque teórico-práctico permite verificar y evaluar el grado de consecución de los siguientes objetivos curriculares vinculados a la automatización de la infraestructura:

* **Resultado de Aprendizaje 3 (RA3):** Gestiona la automatización de tareas del sistema, aplicando criterios de eficiencia y utilizando comandos y herramientas gráficas.
    * *Criterios de evaluación vinculados:* CE1-RA3 (Planificación de tareas), CE2-RA3 (Creación de scripts de administración), CE3-RA3 (Automatización de rutinas repetitivas).
* **Resultado de Aprendizaje 2 (RA2):** Administra procesos del sistema describiéndolos y aplicando criterios de seguridad y eficiencia.
    * *Criterios de evaluación vinculados:* CE6-RA2 (Mantenimiento de sistemas mediante ejecución por lotes).

Para que nuestros scripts sean dinámicos y reutilizables, deben aceptar argumentos externos en el momento de la ejecución desde la terminal.

## Variables Especiales

* `$0`: Nombre del propio script que se está ejecutando.
* `$1`, `$2`, `$3`...: Primer, segundo y tercer argumento pasados al script.
* `$#`: Número total de argumentos recibidos.
* `$@`: Lista de todos los argumentos pasados (ideal para recorrerlos en un bucle).
* `$?`: Código de estado de salida (*Exit Status*) del último comando ejecutado (`0` significa éxito, distinto de `0` significa error).

## Ejemplo de Uso
Si ejecutamos en la terminal `./crear_usuario.sh joseramon ventas`:

```bash
#!/bin/bash
echo "Ejecutando el script: $0"         # Salida: Ejecutando el script: ./crear_usuario.sh
echo "Creando usuario $1 en grupo $2"   # Salida: Creando usuario joseramon en grupo ventas
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
