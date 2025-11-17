# Tema 4: Triggers (Disparadores)
## Definición general

Un trigger (o disparador) es un objeto especial de la base de datos que se ejecuta automáticamente ante un evento determinado, sin intervención directa del usuario o de la aplicación. Su propósito principal es permitir la ejecución automática de instrucciones SQL cuando ocurren operaciones como inserciones, actualizaciones o eliminaciones, reforzando reglas de negocio, mecanismos de integridad y auditoría.

Según la documentación oficial de Microsoft (Microsoft Learn, CREATE TRIGGER – Transact-SQL), un trigger es un procedimiento almacenado que se ejecuta automáticamente cuando ocurre un evento DML (INSERT, UPDATE, DELETE) o DDL (CREATE, ALTER, DROP) dentro de la base de datos.

Desde el punto de vista de diseño de sistemas, los triggers permiten complementar las restricciones declarativas (CHECK, FOREIGN KEY, UNIQUE, etc.), proporcionando un nivel adicional de control lógico y operativo que no puede garantizarse únicamente a través de dichas restricciones.

---

## Estructura y sintaxis general

En SQL Server, la instrucción CREATE TRIGGER define la creación de un trigger.
La sintaxis general —basada en Microsoft Learn— se expresa de la siguiente forma:

```sql
-- Fuente: Microsoft Learn – CREATE TRIGGER (Transact-SQL)
CREATE [ OR ALTER ] TRIGGER [ schema_name . ] trigger_name        -- Crea o modifica un trigger existente
ON { table | view }                                               -- Tabla o vista sobre la cual actuará el trigger
[ WITH <dml_trigger_option> [ , ...n ] ]                          -- Opciones adicionales
{ FOR | AFTER | INSTEAD OF }                                      -- Momento de ejecución del trigger
{ [ INSERT ] [ , ] [ UPDATE ] [ , ] [ DELETE ] }                  -- Tipo(s) de operación DML que activan el trigger
[ WITH APPEND ]                                                   -- Permite agregar más triggers sin sobrescribir
[ NOT FOR REPLICATION ]                                           -- Evita ejecución durante replicaciones
AS
{
    sql_statement [ ; ] [ , ...n ]                                -- Instrucciones SQL que ejecutará automáticamente
  | EXTERNAL NAME <method_specifier [ ; ] >                       -- Para triggers CLR
}

<dml_trigger_option> ::=
        [ ENCRYPTION ]                                            -- Oculta el código del trigger
      | [ EXECUTE AS Clause ]                                     -- Define el contexto de seguridad

<method_specifier> ::=                                            -- Solo aplicable para triggers CLR
        assembly_name.class_name.method_name
````
## Elementos clave de la sintaxis

- FOR / AFTER → el trigger se ejecuta después de la operación DML. Ideal para auditoría.

- INSTEAD OF → reemplaza la operación original. Comúnmente usado para impedir DELETE.

- inserted → tabla virtual interna con valores nuevos.

- deleted → tabla virtual interna con valores previos.

- sql_statement → bloque de instrucciones ejecutadas automáticamente.

Esta sintaxis se utilizó como base para todos los triggers implementados en el proyecto SIC-UNNE.

## Usos comunes de los triggers
- ✔ Validación automática de datos

Permiten implementar reglas complejas que no pueden resolverse únicamente con restricciones declarativas.
Ejemplo: impedir modificaciones no autorizadas sobre propuestas.

- ✔ Auditoría de cambios

Registran quién modificó un registro, cuándo y qué valores fueron afectados.
En SIC-UNNE se utiliza para auditar el estado anterior de una inscripción ante un UPDATE o DELETE.

- ✔ Sincronización y coherencia de datos

Pueden actualizar otras tablas dependientes de manera automática.

- ✔ Ejecución automática de reglas de negocio

Ejemplo: impedir eliminar propuestas existentes y obligar a gestionar estados válidos.

- ✔ Prevención de operaciones no permitidas

Un trigger INSTEAD OF DELETE puede impedir la eliminación física de registros sensibles.

## Ventajas y desventajas
**Ventajas**

Automatización completa: ejecutan lógica sin intervención de la aplicación.

Integridad reforzada: aseguran reglas de negocio críticas.

Auditoría interna: registran cambios sensibles sin modificar la aplicación.

Centralización de reglas: la lógica está en el motor, no en el código.

**Desventajas**

Dificultad de depuración: se ejecutan automáticamente y pueden generar efectos ocultos.

Impacto en rendimiento: triggers complejos pueden ralentizar operaciones DML.

Dependencia del motor: pueden dificultar la migración a otros SGBD.

Complejidad adicional: mal diseñados pueden generar comportamientos inesperados.

## Implementación en SIC-UNNE

Los triggers diseñados para SIC-UNNE cumplen dos roles principales:

**1. Auditoría automática de inscripciones (UPDATE y DELETE)**

Se implementó la tabla Auditoria_Inscripcion, donde los triggers registran:

El estado anterior de la inscripción (deleted)

La fecha del evento (GETDATE())

El usuario del motor de BD (SUSER_SNAME())

El tipo de operación (UPDATE o DELETE)

Esto garantiza trazabilidad y facilita revisiones administrativas.

**2. Control y protección de operaciones sobre propuestas**

Se implementaron dos triggers principales.

- ✔ Bloqueo de eliminación física (INSTEAD OF DELETE)

Una propuesta no puede eliminarse porque:

Es la base del mecanismo de matching

Su eliminación rompe relaciones con listas de espera, notificaciones y comprobantes

Se pierde trazabilidad y coherencia administrativa

El trigger bloquea el DELETE y muestra un mensaje de error.

- ✔ Restricción de actualizaciones (AFTER UPDATE)

Solo se permite modificar el estado de la propuesta.
El trigger verifica que no cambien:

Las listas de espera involucradas

La fecha de creación

Otros atributos esenciales

Cualquier otro cambio revierte la operación.

## Conclusiones

Los triggers desarrollados en SIC-UNNE cumplen con los objetivos planteados:

Los triggers de auditoría mantienen un registro confiable de modificaciones en las inscripciones.

El trigger que bloquea la eliminación de propuestas garantiza coherencia y cumplimiento de las reglas de matching.

El trigger que restringe actualizaciones evita manipulación indebida de información crítica.

En conjunto, estos triggers fortalecen la integridad, seguridad y consistencia del sistema académico, proporcionando un nivel de control indispensable en un entorno donde las operaciones deben quedar registradas y protegidas.

