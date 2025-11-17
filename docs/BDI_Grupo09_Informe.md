# Proyecto de Estudio!
    
**Estructura del documento principal:**

# PRESENTACIÓN (SISTEMA DE INTERCAMBIO DE COMISIONES (SIC-UNNE))

*Universidad*: Universidad Nacional del Nordeste  
*Facultad*: Facultad de Ciencias Exactas y Naturales y Agrimensura  
*Carrera*: Licenciatura en Sistemas de Información  
*Asignatura*: Base de Datos I  
*Año Lectivo*: 2025

**Integrantes**:
 - Riveros, Lautaro Ezquiel.
 - Riveros, Maximo Tomas.
 - Scetti, Santiago.
 - Turtola, Sabrina.


## CAPÍTULO I: INTRODUCCIÓN

### Caso de estudio

**Tema — Diseño y desarrollo de la base de datos para el Sistema de Intercambio de Comisiones (SIC-UNNE) con aplicación de roles, permisos y procedimientos almacenados.**
El sistema busca resolver la gestión manual e informal de los intercambios de comisiones en la UNNE mediante una base de datos que:

- Define roles de usuario (administrador, verificador y estudiante).
- Asegura la integridad académica (carreras, asignaturas, comisiones, horarios y docentes).
- Registra y audita acciones (intercambios, rechazos, reportes).
- Incorpora controles de seguridad (permisos, restricciones, triggers, SPs).

### Definición o planteamiento del problema

Actualmente, los intercambios se realizan de forma informal (redes sociales, WhatsApp), generando:

- Falta de trazabilidad: sin registros oficiales.
- Errores frecuentes: duplicaciones, intercambios múltiples inválidos.
- Ausencia de control institucional.
- Riesgo de manipulación o abuso.

El sistema propone un flujo seguro y auditable mediante:

- Administrador: registra carreras, materias, comisiones y abecedario de apellidos.
- Verificador: controla y recibe notificaciones de intercambios, reportes y consultas.
- Estudiante: se inscribe con validación de datos, gestiona comisiones, participa en lista de espera y acepta/rechaza propuestas.
- Mecanismo de match: el sistema propone intercambios cuando dos estudiantes son compatibles. Se notifican a ambas partes y al verificador.

Casos de rechazo:

- Rechazo individual → justificación, el otro alumno vuelve a la lista.
- Rechazo doble → quedan registros, ambos salen de la lista.
- Tres rechazos → el sistema reporta e inhabilita al estudiante.

### Preguntas Generales
- ¿Cómo diseñar una base de datos que gestione de manera segura, consistente y eficiente el intercambio de comisiones en la UNNE, diferenciando roles y garantizando transparencia?

### Preguntas Específicas

- ¿Cómo organizar los roles y permisos para que cada usuario acceda solo a la información que le corresponde?
- ¿Qué procedimientos almacenados deben implementarse para gestionar inscripciones, listas de espera e intercambios?
- ¿Cómo asegurar la integridad de datos en los procesos de intercambio de comisiones?
- ¿Qué mecanismos garantizan la trazabilidad y auditoría de los intercambios y rechazos?
- ¿Qué índices optimizan las búsquedas de alumnos, comisiones e intercambios?
- ¿Cómo garantizar la atomicidad de los intercambios mediante transacciones y triggers?

### Objetivos Generales

Diseñar e implementar la base de datos del SIC-UNNE aplicando seguridad, eficiencia y consistencia, con permisos, procedimientos, índices y transacciones que aseguren un sistema confiable y auditable.

### Objetivos Específicos

Permisos y roles

 - Definir privilegios de administrador, verificador y estudiante (principio de menor privilegio).
 - Validar accesos con casos de prueba.

Procedimientos y funciones almacenadas

- SPs para inscripciones, lista de espera, generación/aceptación/rechazo de intercambios, emisión de comprobantes.
- Funciones de apoyo para validar estados y consultas frecuentes.

Optimización de consultas

- Identificar tablas críticas (comisiones, inscripciones, propuestas, notificaciones).
- Implementar índices clustered, nonclustered y filtrados.
- Medir el impacto en el rendimiento.

Transacciones y triggers

- Garantizar atomicidad en intercambios y comprobantes.
- Usar transacciones anidadas en procesos complejos.
- Probar escenarios de error para asegurar consistencia.

### Descripción del Sistema

El SIC-UNNE es un sistema diseñado para digitalizar y automatizar el proceso de intercambio de comisiones en la Universidad Nacional del Nordeste.
Integra el registro de estudiantes, comisiones, horarios y docentes, ofreciendo un flujo seguro y auditable.

**Módulos principales:**

- **Gestión de usuarios y roles** (administrador, verificador, estudiante).
- **Administración académica:** carreras, asignaturas, comisiones y horarios.
- **Intercambio de comisiones:** listas de espera, generación de propuestas, aceptación/rechazo.
- **Notificaciones y reportes a estudiantes y verificadores.**
- **Seguridad y auditoría:** permisos, triggers y procedimientos almacenados.

### Alcance

El sistema abarca la gestión completa del **intercambio de comisiones**, incluyendo:

- **Registro de usuarios institucionales** (administradores, verificadores, estudiantes).
- **Alta y control** de carreras, asignaturas, comisiones y docentes.
- **Inscripción** de estudiantes y validación de pertenencia a comisiones.
- **Listas** de espera para solicitudes de intercambio.
- **Propuestas automáticas** de match entre estudiantes.
- **Registro y control** de rechazos con justificación y sanciones.
- **Generación de reportes y notificaciones**.

**No incluye:**

- Integración con **sistemas externos** de gestión académica.
- **Validación legal** de los intercambios.
- Funcionalidades avanzadas de **predicción o análisis académico**.

## CAPITULO II: MARCO CONCEPTUAL O REFERENCIAL

**TEMA 1 " ---- "** 

**TEMA 2 " ----- "** 

...

## CAPÍTULO III: METODOLOGÍA SEGUIDA 

...


## CAPÍTULO IV: DESARROLLO DEL TEMA / PRESENTACIÓN DE RESULTADOS 

En este capítulo se exponen los datos y la información recolectada y organizada para el diseño del **SIC-UNNE (Sistema de Intercambio de Comisiones)**. El propósito central de este sistema es brindar una solución que permita ordenar y optimizar el proceso de intercambio de comisiones dentro de la Universidad Nacional del Nordeste, garantizando una gestión más ágil y confiable.

Para su desarrollo se recurrió a distintas herramientas y metodologías de modelado de datos. Entre ellas, destacan los **Diagramas Entidad–Relación (DER)**, que facilitan la representación visual de las entidades, sus atributos y los vínculos que las relacionan. Esta herramienta resultó clave para identificar la estructura general de la base de datos, su comportamiento y las restricciones necesarias para preservar la integridad de la información.

### Diagrama relacional
El **Modelo Relacional**, expresado a través del Diagrama Entidad–Relación (ER), constituye una representación conceptual de la base de datos que describe su organización lógica. En él se detallan las entidades principales, sus características más relevantes y las conexiones que mantienen entre sí.

En las páginas siguientes se presenta el Modelo Relacional del sistema **SIC-UNNE**, el cual muestra de manera gráfica las entidades definidas y sus relaciones en el contexto de la gestión académica y los procesos de intercambio de comisiones.

![diagrama_relacional](docs/der_SIC-UNNE.jpeg)




## CAPÍTULO V: CONCLUSIONES

...


## BIBLIOGRAFÍA DE CONSULTA

 1. List item
 2. List item
 3. List item
 4. List item
 5. List item
