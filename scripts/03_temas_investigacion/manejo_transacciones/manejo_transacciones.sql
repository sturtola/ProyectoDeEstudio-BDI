/****************************************************************************************
* PROYECTO:         SIC-UNNE (Bases de Datos I)
* TEMA:             Manejo de transacciones y transacciones anidadas
* ARCHIVO:          manejo_transacciones.sql
* DESCRIPCIÓN:
*   Script para:
*   - Definir una transacción consistente con varias operaciones (INSERT + INSERT + UPDATE)
*   - Provocar un error y comprobar el ROLLBACK
*   - Mostrar un ejemplo simple de transacción anidada usando SAVEPOINT
*
* NOTA:
*   Este script asume que la base de datos SIC_UNNE ya existe y que el esquema
*   fue creado por los scripts principales.
****************************************************************************************/

USE SIC_UNNE;
GO

/****************************************************************************************
* 0) PREPARACIÓN: LIMPIEZA DE DATOS DE PRUEBA
*    (por si el script se ejecuta varias veces)
****************************************************************************************/

-- Borramos edificios y aulas de pruebas anteriores
DELETE FROM Aula
WHERE nombre LIKE 'Aula TX%';

DELETE FROM Edificio
WHERE nombre LIKE 'Edificio TX%';
GO


/****************************************************************************************
* 1) TRANSACCIÓN CONSISTENTE (CASO CORRECTO)
*
* Requisito:
*   - Insertar 1 registro en una tabla
*   - Insertar 1 registro en otra tabla
*   - Actualizar uno o más registros en otra tabla
*   - Actualizar solo si TODA la operación se completa con éxito
*
* En este ejemplo:
*   1) INSERT en Edificio
*   2) INSERT en Aula (relacionada al edificio)
*   3) UPDATE de Aula (cambiamos el nombre)
*
* Si todo va bien -> COMMIT
* Si algo falla   -> ROLLBACK
****************************************************************************************/

PRINT '=== CASO 1: TRANSACCIÓN COMPLETA SIN ERRORES ===';

DECLARE @idEdificio INT;
DECLARE @idAula INT;

BEGIN TRY
    BEGIN TRAN Transaccion_SIC_01;

        -- 1) INSERT en Edificio
        INSERT INTO Edificio (direccion, nombre)
        VALUES (N'Av. Transacciones 100', N'Edificio TX 01');

        SET @idEdificio = SCOPE_IDENTITY();

        -- 2) INSERT en Aula (segunda tabla)
        INSERT INTO Aula (nombre, id_edificio)
        VALUES (N'Aula TX 01', @idEdificio);

        SET @idAula = SCOPE_IDENTITY();

        -- 3) UPDATE en Aula (tercera operación)
        UPDATE Aula
        SET nombre = nombre + N' - ACTUALIZADA'
        WHERE id_aula = @idAula;

    COMMIT TRAN Transaccion_SIC_01;
    PRINT 'Transacción 1 COMMIT: todos los cambios fueron confirmados.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRAN Transaccion_SIC_01;

    PRINT 'Transacción 1 ROLLBACK por error.';
    SELECT ERROR_NUMBER() AS NumeroError,
           ERROR_MESSAGE() AS MensajeError;
END CATCH;
GO

-- Verificamos resultados del CASO 1
PRINT '=== VERIFICACIÓN CASO 1 (DEBERÍA HABER UN EDIFICIO Y UN AULA DE PRUEBA) ===';

SELECT id_edificio, direccion, nombre
FROM Edificio
WHERE nombre LIKE 'Edificio TX 01%';

SELECT id_aula, nombre, id_edificio
FROM Aula
WHERE nombre LIKE 'Aula TX 01%';
GO


/****************************************************************************************
* 2) TRANSACCIÓN CON ERROR INTENCIONAL (DEBE HACER ROLLBACK)
*
* Requisito:
*   - Provocar un error luego de uno de los INSERT
*   - Verificar que los datos queden consistentes (no se realice ningún INSERT)
*
* En este caso:
*   1) INSERT en Edificio
*   2) Provocamos un error intencional con THROW
*   Resultado esperado:
*       -> Se ejecuta el CATCH
*       -> Se hace ROLLBACK
*       -> No queda insertado el edificio de prueba "Edificio TX ERROR"
****************************************************************************************/

PRINT '=== CASO 2: TRANSACCIÓN CON ERROR INTENCIONAL ===';

BEGIN TRY
    BEGIN TRAN Transaccion_SIC_02;

        -- 1) INSERT de prueba
        INSERT INTO Edificio (direccion, nombre)
        VALUES (N'Av. Transacciones 200', N'Edificio TX ERROR');

        -- 2) Error intencional
        THROW 50001, 'Error intencional para probar el ROLLBACK.', 1;

        -- (Si llegáramos aquí, haríamos más operaciones, pero nunca se ejecutan)
        -- INSERT ...
        -- UPDATE ...

    COMMIT TRAN Transaccion_SIC_02; -- Nunca debería llegar acá
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRAN Transaccion_SIC_02;

    PRINT 'Transacción 2 ROLLBACK por error INTENCIONAL.';
    SELECT ERROR_NUMBER() AS NumeroError,
           ERROR_MESSAGE() AS MensajeError;
END CATCH;
GO

-- Verificamos resultados del CASO 2
PRINT '=== VERIFICACIÓN CASO 2 (NO DEBERÍA EXISTIR Edificio TX ERROR) ===';

SELECT id_edificio, direccion, nombre
FROM Edificio
WHERE nombre LIKE 'Edificio TX ERROR%';
GO


/****************************************************************************************
* 3) EJEMPLO SIMPLE DE TRANSACCIÓN ANIDADA
*
* Idea:
*   - Usar una transacción "externa"
*   - Crear un punto de guardado (SAVEPOINT) que actúa como "transacción interna"
*   - Provocar un error en la parte interna y revertir solo esa parte
*   - Mantener la parte externa
*
* Tablas usadas: Notificacion (ya existe en el modelo)
****************************************************************************************/

PRINT '=== CASO 3: TRANSACCIÓN ANIDADA CON SAVEPOINT ===';

-- Borramos notificaciones de prueba anteriores
DELETE FROM Notificacion
WHERE tipo = 'Transaccion'
  AND mensaje LIKE 'Notificacion TX%';
GO

DECLARE @idUsuarioPrueba INT;

-- Tomamos cualquier usuario existente para asociar las notificaciones
SELECT TOP 1 @idUsuarioPrueba = id_usuario
FROM Usuario;

IF @idUsuarioPrueba IS NULL
BEGIN
    PRINT 'No hay usuarios en la tabla Usuario. No se puede ejecutar el ejemplo de transacción anidada.';
END
ELSE
BEGIN
    BEGIN TRY
        BEGIN TRAN Transaccion_Externa;

            -- Parte externa: esta debería quedar confirmada
            INSERT INTO Notificacion (tipo, mensaje, fecha, id_usuario)
            VALUES ('Transaccion', 'Notificacion TX EXTERNA', GETDATE(), @idUsuarioPrueba);

            -- SAVEPOINT (punto de guardado) = "transacción interna"
            SAVE TRAN Transaccion_Interna;

            -- Parte interna: probamos un insert correcto...
            INSERT INTO Notificacion (tipo, mensaje, fecha, id_usuario)
            VALUES ('Transaccion', 'Notificacion TX INTERNA OK', GETDATE(), @idUsuarioPrueba);

            -- ...y ahora provocamos un error para simular fallo interno
            PRINT 'Provocando error en la parte interna...';
            THROW 50002, 'Error intencional en la parte interna.', 1;

            -- Esta parte nunca se ejecuta
            INSERT INTO Notificacion (tipo, mensaje, fecha, id_usuario)
            VALUES ('Transaccion', 'Notificacion TX QUE NO DEBERÍA EXISTIR', GETDATE(), @idUsuarioPrueba);

        COMMIT TRAN Transaccion_Externa;
    END TRY
    BEGIN CATCH

        -- Si hay transacción activa...
        IF XACT_STATE() = -1
        BEGIN
            -- Estado irrecuperable: hay que hacer ROLLBACK total
            ROLLBACK TRAN Transaccion_Externa;
            PRINT 'Transacción externa ROLLBACK (estado irrecuperable).';
        END
        ELSE IF XACT_STATE() = 1
        BEGIN
            -- Estado recuperable: podemos volver al SAVEPOINT y luego COMMIT
            PRINT 'Se revierte solo la parte interna (SAVEPOINT).';
            ROLLBACK TRAN Transaccion_Interna;

            -- Confirmamos la parte externa
            COMMIT TRAN Transaccion_Externa;
            PRINT 'Transacción externa COMMIT después de revertir la interna.';
        END

        SELECT ERROR_NUMBER() AS NumeroError,
               ERROR_MESSAGE() AS MensajeError;
    END CATCH;
END
GO

-- Verificación de las notificaciones del CASO 3
PRINT '=== VERIFICACIÓN CASO 3 (TRANSACCIÓN ANIDADA) ===';

SELECT id_notificacion, tipo, mensaje, fecha, id_usuario
FROM Notificacion
WHERE tipo = 'Transaccion'
  AND mensaje LIKE 'Notificacion TX%';
GO

PRINT '=== FIN DEL SCRIPT DE MANEJO DE TRANSACCIONES ===';

