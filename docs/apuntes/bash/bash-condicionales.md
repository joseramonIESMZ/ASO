# 3. Estructuras Condicionales (if / case)

## 🎯 Relación con el Currículo (RA y CE)

La asimilación de los conceptos integrados en este bloque teórico-práctico permite verificar y evaluar el grado de consecución de los siguientes objetivos curriculares vinculados a la automatización de la infraestructura:

* **Resultado de Aprendizaje 3 (RA3):** Gestiona la automatización de tareas del sistema, aplicando criterios de eficiencia y utilizando comandos y herramientas gráficas.
    * *Criterios de evaluación vinculados:* CE1-RA3 (Planificación de tareas), CE2-RA3 (Creación de scripts de administración), CE3-RA3 (Automatización de rutinas repetitivas).
* **Resultado de Aprendizaje 2 (RA2):** Administra procesos del sistema describiéndolos y aplicando criterios de seguridad y eficiencia.
    * *Criterios de evaluación vinculados:* CE6-RA2 (Mantenimiento de sistemas mediante ejecución por lotes).

La toma de decisiones permite que el script actúe de forma inteligente ante errores o casuísticas del servidor.

## La estructura `if`
Utilizamos los corchetes `[ ]` (que internamente llaman al comando `test`) para evaluar condiciones. **Deben tener espacios en blanco** antes y después de cada corchete.

```bash
#!/bin/bash
NOTA=8

# Operadores Numéricos: -eq (igual), -ne (distinto), -gt (mayor), -lt (menor)
if [ $NOTA -ge 5 ]; then
    echo "¡Aprobado!"
else
    echo "Suspenso, necesitas recuperar."
fi
```

## Comprobación de Archivos (Crítico en Administración)
Bash brilla en la administración porque permite preguntar directamente al sistema de archivos:
* `-e`: ¿Existe el archivo/directorio?
* `-d`: ¿Es un directorio?
* `-f`: ¿Es un archivo regular de texto/binario?

```bash
ARCHIVO="/etc/passwd"
if [ -f "$ARCHIVO" ]; then
    echo "El archivo de contraseñas base del sistema existe."
fi
```

## La estructura `case` (Interruptor)
Ideal para crear menús interactivos de operaciones o gestionar parámetros de entrada complejos de forma limpia.

```bash
case "$1" in
    start)
        echo "Iniciando servicio HTTP..."
        ;;
    stop)
        echo "Deteniendo servicio HTTP..."
        ;;
    *)
        echo "Uso obligatorio: $0 {start|stop}"
        ;;
esac
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
