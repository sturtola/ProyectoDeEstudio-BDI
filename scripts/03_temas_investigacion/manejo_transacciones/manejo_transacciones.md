# TEMA 1 — Procedimientos y Funciones Almacenadas

## Procedimientos Almacenados

En el sistema SIC-UNNE, los procedimientos almacenados cumplen un rol central para gestionar las operaciones más importantes relacionadas con el intercambio de comisiones. Estos procedimientos permiten centralizar la lógica académica y administrativa en el servidor SQL, evitando errores en la aplicación cliente y garantizando resultados consistentes en cada operación.
Un procedimiento almacenado es un bloque de instrucciones SQL precompiladas que se ejecuta directamente en el motor de base de datos. En un sistema con múltiples usuarios —como administradores, verificadores y estudiantes— esto permite automatizar tareas críticas: validar inscripciones, mover estudiantes a la lista de espera, generar propuestas de intercambio o registrar rechazos, reduciendo significativamente la complejidad en el código externo.
En el SIC-UNNE, los procedimientos almacenados contribuyen a:

- **Mantener la integridad académica** durante altas y bajas de comisiones.
- **Evitar duplicaciones o inconsistencias** en inscripciones y solicitudes.
- **Ejecutar operaciones complejas como una unidad lógica**, garantizando que se cumplan todas las reglas del sistema.
- **Optimizar el rendimiento**, reduciendo llamadas repetitivas desde la aplicación.
- **Aplicar seguridad**, permitiendo que ciertos procesos solo puedan ser ejecutados por roles autorizados (como el verificador o el administrador).

### Creación y administración

En SQL Server, un procedimiento se define mediante CREATE PROCEDURE.
En el SIC-UNNE, esto permite encapsular procesos como:

- Validación de datos personales del estudiante.
- Registro de inscripciones a comisiones.
- Inserción en listas de espera.
- Generación automática de propuestas de intercambio.
- Actualización del estado de una propuesta (aceptada, rechazada, vencida).

Ejemplo conceptual aplicado al SIC-UNNE:
```sql
CREATE PROCEDURE sp_inscribir_estudiante
    @estudiante_id INT,
    @comision_id INT
AS
BEGIN
    -- Validaciones, verificaciones de cupo e inserción final.
END;
````
Cada procedimiento puede posteriormente modificarse (ALTER PROCEDURE) o eliminarse (DROP PROCEDURE) según se requiera.

### Características principales en el SIC-UNNE

Dentro del sistema, los procedimientos almacenados permiten:

- Ejecutar operaciones **CRUD controladas** sobre inscripciones y propuestas.
- Manejar **transacciones completas**, esenciales para el proceso de intercambio.
- Implementar **validaciones automáticas**, como evitar que un alumno esté en dos comisiones simultáneas.
- **Registrar rechazos**, justificarlos y actualizar el estado del estudiante en la lista de espera.
- Generar notificaciones internas hacia el verificador.

Al ejecutarse en el servidor, se reduce el tráfico entre la aplicación y la base de datos, y se aprovechan planes de ejecución precompilados, aumentando el rendimiento general.

### Tipos de procedimientos aplicados al proyecto

En el SIC-UNNE se pueden emplear:

- **Procedimientos definidos por el usuario**
(por ejemplo: sp_generar_propuesta, sp_registrar_rechazo, sp_actualizar_inscripcion).
- **Procedimientos temporales**, usados en pruebas o procesos auxiliares.
- **Procedimientos del sistema**, aprovechados para diagnósticos o consultas internas.

### Funciones Almacenadas

Las funciones almacenadas permiten calcular valores derivados, aplicar validaciones y procesar datos que luego pueden ser reutilizados en distintas consultas del sistema. En el contexto del SIC-UNNE, las funciones aportan coherencia y simplificación en tareas que se ejecutan constantemente, tales como:

- Determinar si un estudiante cumple los requisitos para una comisión.
- Evaluar si dos estudiantes tienen compatibilidad para un intercambio.
- Obtener el estado actual de una propuesta.
- Verificar si un estudiante está sancionado por rechazos múltiples.

A diferencia de los procedimientos, las funciones **siempre devuelven un valor y no pueden modificar datos**, lo cual garantiza un comportamiento determinista y seguro para la lógica del sistema.

### Creación y administración

Las funciones se crean con CREATE FUNCTION y requieren siempre un valor de retorno.
En el SIC-UNNE se utilizan para:

- Calcular disponibilidad de comisiones.
- Validar turnos compatibles.
- Obtener los rechazos acumulados de un estudiante.
- Consultar si ya existe una propuesta activa entre dos alumnos.

Ejemplo conceptual:
```sql
CREATE FUNCTION fn_tiene_cupo
(
    @comision_id INT
)
RETURNS BIT
AS
BEGIN
    DECLARE @cupoDisponible BIT;

    SELECT @cupoDisponible =
        CASE WHEN cupo > inscriptos THEN 1 ELSE 0 END
    FROM Comisiones
    WHERE id_comision = @comision_id;

    RETURN @cupoDisponible;
END;
````
### Características principales en el SIC-UNNE

Las funciones almacenadas contribuyen a:

- **Estandarizar reglas de negocio**, como validaciones de pertenencia a carrera o turno.
- **Reutilizar cálculos complejos** en diversas partes del sistema.
- Aumentar la **claridad y mantenibilidad** del código SQL.
- Evitar errores repetitivos en consultas escritas por diferentes usuarios o módulos.
- Mejorar el rendimiento al ejecutarse directamente en el motor.

### Tipos de funciones almacenadas utilizadas

- **Funciones escalares**, que devuelven valores como bit, entero, fecha o string.
- **Funciones con valor de tabla**, útiles para generar subconjuntos de datos, por ejemplo:
- alumnos en lista de espera por comisión,
- propuestas activas entre dos alumnos,
- coincidencias horarias entre comisiones.

### Conclusión

Los procedimientos y funciones almacenadas constituyen una parte esencial de la arquitectura del sistema SIC-UNNE. Ambos permiten centralizar la lógica de negocio en el servidor SQL, mejorar el rendimiento de las operaciones más utilizadas, garantizar coherencia en los cálculos y reducir la cantidad de validaciones necesarias desde la aplicación.

Los procedimientos resultan ideales para gestionar procesos críticos, como inscripciones, propuestas, aceptaciones, rechazos y movimientos en listas de espera, asegurando que cada operación respete las reglas principales del sistema.

Por otro lado, las funciones permiten validar condiciones internas —como cupos, compatibilidades y estados— de forma rápida y reutilizable, garantizando que todas las operaciones deriven de un mismo criterio académico-administrativo.

En conjunto, ambos componentes fortalecen la seguridad, coherencia lógica, eficiencia y control general del sistema, haciendo posible un flujo de intercambio transparente y confiable dentro de la UNNE.


