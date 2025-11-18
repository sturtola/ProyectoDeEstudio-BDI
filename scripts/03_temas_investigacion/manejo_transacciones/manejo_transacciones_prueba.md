# Tema: Manejo de transacciones y transacciones anidadas en SIC_UNNE

## Objetivos de aprendizaje

- Entender la **consistencia** y **atomicidad** de las transacciones.
- Implementar transacciones simples y anidadas para garantizar la integridad de los datos.

---

## 1. Transacción consistente (caso correcto)

En el archivo `manejo_transacciones.sql`, el **CASO 1** implementa una transacción que cumple la consigna:

> Insertar un registro en una tabla, luego otro en otra tabla y por último actualizar registros en otra tabla.  
> Actualizar los datos solamente si toda la operación es completada con éxito.

En el ejemplo:

1. Se comienza una transacción llamada `Transaccion_SIC_01`.
2. Se insertan datos en la tabla **Edificio**:
   - Dirección: `Av. Transacciones 100`
   - Nombre: `Edificio TX 01`
3. Se guarda el `id_edificio` creado con `SCOPE_IDENTITY()`.
4. Se insertan datos en la tabla **Aula** usando el `id_edificio` recién creado.
5. Se actualiza el nombre del aula agregando el texto "`- ACTUALIZADA`".
6. Si todo sale bien, se ejecuta `COMMIT` y los tres pasos quedan grabados.

Si ocurre algún error en cualquiera de las operaciones, se entra en el bloque `CATCH`:

- Se ejecuta `ROLLBACK` y **ningún cambio es guardado**.
- Se muestra el número y mensaje del error.

Después, se hacen `SELECT` sobre `Edificio` y `Aula` para comprobar que los datos del caso 1 fueron efectivamente insertados y actualizados.

---

## 2. Transacción con error intencional (consistencia de datos)

El **CASO 2** cumple con la parte de la consigna que pide:

> Provocar intencionalmente un error luego del insert y verificar que los datos queden consistentes (no se debería realizar ningún insert).

Pasos:

1. Se inicia la transacción `Transaccion_SIC_02`.
2. Se inserta un nuevo registro en **Edificio** con nombre `Edificio TX ERROR`.
3. Inmediatamente después se lanza un **error intencional** usando:

   ```sql
   THROW 50001, 'Error intencional para probar el ROLLBACK.', 1;

