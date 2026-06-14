# 💻 ASO Infraestructura de laboratorio

## 🚀 Presentación

Malvenido a la plataforma oficial de recursos técnicos de **Administración de Sistemas Operativos (ASO)** para el segundo curso de **ASIR** en el **I.E.S. Marcos Zaragoza**.

Esta documentación ha sido diseñada para servir como tu base de conocimiento e ingeniería en el despliegue de infraestructuras corporativas híbridas. Aquí encontrarás los apuntes detallados, guías operativas y configuraciones sobre cada uno de los ecosistemas tecnológicos del módulo.

---

## 🛠️ Arquitectura Tecnológica del Laboratorio

A lo largo del curso, operarás sobre un clúster físico de alta fidelidad empresarial, desplegando servicios críticos sin entorno gráfico y bajo esquemas de automatización estricta.

!!! info "Dimensionamiento de Hardware Real"
    * **Servidores Físicos (Por Equipo):** Intel Core i7-14700KF (20 Núcleos), 32 GB RAM DDR4, Almacenamiento NVMe de 1 TB corriendo **Proxmox VE Server**.
    * **Vector de Gestión Obligatorio:** Queda restringido el uso de la consola web gráfica del hipervisor. Toda la administración se canalizará mediante **WinRM**, **Invoke-Command** y terminales nativas **SSH**.

---

## 🎯 Metodología del Laboratorio

Aplicamos el marco **INNOVATEC**, un ecosistema de aprendizaje activo basado en la resolución de retos y problemas reales del entorno empresarial. 

> ⚠️ **Enfoque de Producción:** Operarás la infraestructura simulando un entorno real de administración remota de sistemas. La interfaz gráfica no estará disponible en los servidores de producción; tu terminal y tus scripts serán tus herramientas de ingeniería.