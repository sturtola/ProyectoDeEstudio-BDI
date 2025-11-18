# TEMA 3 — Manejo de Transacciones

## 1. Introducción a las Transacciones

En SQL Server, una transacción representa una unidad lógica de trabajo que agrupa una o más operaciones que deben ejecutarse de forma atómica. Es decir, todas deben completarse con éxito o ninguna debe aplicarse. Esta propiedad es fundamental para sistemas donde la integridad es prioritaria, como en el SIC-UNNE, donde un error durante un intercambio, una inscripción o un rechazo podría dejar a un estudiante en un estado inconsistente.
Las transacciones garantizan que los procesos críticos de la base de datos respeten las propiedades ACID:

- **Atomicidad:** todo ocurre o no ocurre.
- **Consistencia:** los datos siempre pasan de un estado válido a otro.
- **Aislamiento:** los procesos concurrentes no interfieren entre sí.
- **Durabilidad:** una vez confirmado, el cambio es permanente.

### 2. Transacciones en el contexto del SIC-UNNE

El SIC-UNNE realiza numerosas operaciones que requieren confiabilidad absoluta. Entre ellas:

- inscripción de estudiantes a comisiones,
- asignación a listas de espera,
- generación de propuestas de intercambio,
- aceptación o rechazo de propuestas,
- actualización de cupos,
- notificaciones al verificador.

En todos estos casos, un fallo a mitad de proceso no puede dejar datos sin coherencia, por lo que el uso de transacciones es indispensable.

Ejemplo:
Si dos estudiantes aceptan un intercambio pero el sistema falla justo después de mover solo a uno, quedaría un estado imposible de recuperar sin una transacción.

### 3. BEGIN TRAN… COMMIT… ROLLBACK en el SIC-UNNE

El manejo básico de transacciones se realiza mediante:

- BEGIN TRANSACTION → inicia la transacción
- COMMIT → confirma los cambios
- ROLLBACK → revierte todo lo realizado desde el BEGIN

En el SIC-UNNE esto es útil para:

✔ **Registrar inscripciones**
```sql
BEGIN TRAN
    -- validar estudiante
    -- validar cupo
    -- insertar inscripción
    -- actualizar contadores
COMMIT
````
✔ **Mover un estudiante a lista de espera**
```sql
BEGIN TRAN
    -- verificar requisitos
    -- insertar en lista de espera
    -- actualizar estados previos
    -- generar notificación
COMMIT
````
✔ **Procesar una propuesta aceptada**
```sql
BEGIN TRAN
    -- validar compatibilidad
    -- intercambiar comisiones
    -- actualizar lista de espera
    -- registrar cambios
COMMIT
````
Si ocurre cualquier error en el proceso:
```sql
ROLLBACK  -- nada cambia
````
Esto protege totalmente la integridad del sistema.

### 4. Savepoints dentro del SIC-UNNE

Un **SAVEPOINT** permite deshacer sólo una parte de la transacción sin revertir todo lo anterior.
Es muy útil en procesos complejos donde algunas validaciones pueden fallar.

Ejemplo aplicado al intercambio de estudiantes:
```sql
BEGIN TRAN

SAVE TRAN validaciones
-- Validaciones críticas
IF (@compatible = 0)
    ROLLBACK TRAN validaciones

-- Cambios definitivos
UPDATE Inscripcion ...
UPDATE Lista_Espera ...
INSERT Auditoria ...
COMMIT
````
Esto permite:

- revertir solo la sección que falló,
- mantener datos que sí eran correctos,
- evitar reiniciar todo el proceso.

### 5. Aislamiento de transacciones en el SIC-UNNE

SQL Server ofrece distintos niveles de aislamiento:

- **READ COMMITTED** (por defecto)
- **READ UNCOMMITTED**
- **REPEATABLE READ**
- **SERIALIZABLE**
- **SNAPSHOT**

En el SIC-UNNE se recomienda READ COMMITTED, ya que evita lecturas inconsistentes sin bloquear completamente el sistema.

Ejemplo donde es indispensable:

- Cuando dos estudiantes intentan inscribirse al último cupo de una comisión.
- Cuando dos propuestas se generan simultáneamente sobre el mismo par de alumnos.

Sin un aislamiento correcto podrían ocurrir:

- sobreasignación de cupos,
- propuestas duplicadas,
- inconsistencias en lista de espera.

### 6. Transacciones + Trigger = Protección doble

El SIC-UNNE utiliza triggers en:

- **Inscripciones (auditoría)**
- **Propuesta (bloqueo de DELETE y restricción de UPDATE)**

Cuando un procedimiento usa transacciones y ese procedimiento activa un trigger:

- el trigger **hereda la transacción,**
- si el trigger falla → **se hace ROLLBACK de toda la operación,**
- si la transacción falla → **se revierte lo hecho por el trigger.**

Esta combinación garantiza que:

✔ no se rompa el historial,

✔ no desaparezcan propuestas,

✔ no queden inscripciones incompletas,

✔ no se dupliquen operaciones críticas.

Esto es especialmente útil en:

- manejo de rechazos,
- generación de propuestas automáticas,
- intercambios aceptados por ambas partes.

### 7. Ejemplo completo: Aceptación de propuesta con transacción

```sql
BEGIN TRAN intercambiar

-- Validar propuesta
IF NOT EXISTS(SELECT 1 FROM Propuesta WHERE id = @propuesta AND estado = 'pendiente')
BEGIN
    ROLLBACK TRAN intercambiar
    RETURN
END

-- Intercambiar comisiones
UPDATE Inscripcion SET comision_id = @nuevaA WHERE estudiante_id = @estudianteA
UPDATE Inscripcion SET comision_id = @nuevaB WHERE estudiante_id = @estudianteB

-- Registrar en auditoría
INSERT INTO Auditoria_Inscripcion (...)

-- Cambiar estado de la propuesta
UPDATE Propuesta SET estado = 'aceptada' WHERE id = @propuesta

COMMIT TRAN intercambiar
````
**Si cualquier parte falla → se revierte todo**

### 8. Conclusión

El manejo de transacciones es uno de los componentes esenciales del SIC-UNNE, ya que garantiza que los procesos académicos críticos —como inscripciones, listas de espera, propuestas, rechazos e intercambios— se ejecuten de manera consistente, segura y confiable.

Las transacciones permiten:

- preservar la integridad de los datos,
- evitar estados intermedios inválidos,
- manejar errores de forma controlada,
- asegurar que las reglas académicas se cumplan siempre,
- mantener coherencia incluso en escenarios concurrentes.

En conjunto con triggers, procedimientos, funciones e índices, las transacciones consolidan un sistema robusto, confiable y resistente a fallos, asegurando la transparencia y eficiencia del proceso de intercambio de comisiones dentro de la UNNE.




