/****************************************************************************************
* NOMBRE:           03_triggers_logica.sql
* DESCRIPCIÓN:      Crea la lógica de negocio (Triggers) necesaria para que la carga
* de datos funcione (validaciones automáticas).
****************************************************************************************/
USE SIC_UNNE;
GO
-- 1. TRIGGER DE HABILITACIÓN (Valida fecha de constancia)
CREATE OR ALTER TRIGGER tr_estudiante_verificar_constancia
ON Constancia
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Definimos fecha límite (6 meses atrás)
    DECLARE @fechaLimite DATE = DATEADD(MONTH, -6, GETDATE());

    -- Caso 1: Constancia NUEVA -> Habilitar Usuario (Estado 1)
    UPDATE U
    SET estado = 1
    FROM Usuario U  
    INNER JOIN inserted I ON U.id_usuario = I.id_usuario 
    WHERE I.fecha_constancia >= @fechaLimite;

    -- Caso 2: Constancia VIEJA -> Deshabilitar Usuario (Estado 0)
    UPDATE U
    SET estado = 0
    FROM Usuario U
    INNER JOIN inserted I ON U.id_usuario = I.id_usuario
    WHERE I.fecha_constancia < @fechaLimite;
    
    PRINT '>> Trigger de Constancia ejecutado: Estados de usuario actualizados.';
END
GO
-- TRIGGER DE MATCHMAKING
CREATE OR ALTER TRIGGER TR_ListaEspera_TryMatchOnInsert
ON Lista_Espera
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. INSERTAR EN PROPUESTA (Detecta el match automáticamente usando JOIN)
    INSERT INTO Propuesta (id_listaEspera_1, id_listaEspera_2, estado, fecha_alta)
    SELECT 
        -- Nos aseguramos que el ID menor vaya primero (ID1 < ID2)
        IIF(I.id_lista_espera < Match.id_lista_espera, I.id_lista_espera, Match.id_lista_espera),
        IIF(I.id_lista_espera < Match.id_lista_espera, Match.id_lista_espera, I.id_lista_espera),
        'Pendiente',
        GETDATE()
    FROM inserted I
    INNER JOIN Lista_Espera Match 
        ON  Match.id_comision_origen = I.id_comision_destino  -- El tiene lo que yo quiero
        AND Match.id_comision_destino = I.id_comision_origen  -- Yo tengo lo que el quiere
        AND Match.estado = 'En espera'                        -- Esta esperando
        AND Match.id_usuario != I.id_usuario;                 -- No soy yo mismo

    -- Si hubo inserciones arriba, avisamos
    IF @@ROWCOUNT > 0
    BEGIN
        PRINT '>> ¡MATCH EXITOSO DETECTADO Y CREADO!';
        
        -- 2. ACTUALIZAR ESTADOS A 'PENDIENTE'
        -- Actualizamos tanto al que acaba de entrar (Inserted) como al que estaba esperando (Match)
        UPDATE L
        SET estado = 'Pendiente'
        FROM Lista_Espera L
        INNER JOIN Propuesta P 
            ON L.id_lista_espera = P.id_listaEspera_1 OR L.id_lista_espera = P.id_listaEspera_2
        WHERE P.estado = 'Pendiente' AND L.estado = 'En espera';
    END
    ELSE
    BEGIN
        PRINT '>> Usuario ingresado a Lista de Espera (Sin coincidencia por ahora).';
    END
END

-- ============================================================================
-- 3. TRIGGER DE ACEPTACIÓN DE PROPUESTAS (Ejecuta el intercambio)
-- ============================================================================
CREATE OR ALTER TRIGGER TR_RespuestaPropuesta_ProcesarAceptacion
ON Respuesta_Propuesta
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Verificar si AMBOS estudiantes ya aceptaron
    DECLARE @idPropuesta INT = (SELECT id_propuesta FROM inserted);
    DECLARE @totalRespuestas INT = (SELECT COUNT(*) FROM Respuesta_Propuesta WHERE id_propuesta = @idPropuesta);
    DECLARE @totalAceptadas INT = (SELECT COUNT(*) FROM Respuesta_Propuesta WHERE id_propuesta = @idPropuesta AND decision = 'Aceptar');
    
    -- Si hay 2 respuestas y AMBAS son "Aceptar" -> EJECUTAR INTERCAMBIO
    IF (@totalRespuestas = 2 AND @totalAceptadas = 2)
    BEGIN
        PRINT '   >> ¡AMBOS ACEPTARON! Ejecutando intercambio...';
        
        -- Obtener los IDs necesarios
        DECLARE @idLE1 INT, @idLE2 INT, @idUsuario1 INT, @idUsuario2 INT;
        DECLARE @idComOrigen1 INT, @idComDestino1 INT, @idComOrigen2 INT, @idComDestino2 INT;
        
        SELECT 
            @idLE1 = id_listaEspera_1,
            @idLE2 = id_listaEspera_2
        FROM Propuesta WHERE id_propuesta = @idPropuesta;
        
        SELECT @idUsuario1 = id_usuario, @idComOrigen1 = id_comision_origen, @idComDestino1 = id_comision_destino
        FROM Lista_Espera WHERE id_lista_espera = @idLE1;
        
        SELECT @idUsuario2 = id_usuario, @idComOrigen2 = id_comision_origen, @idComDestino2 = id_comision_destino
        FROM Lista_Espera WHERE id_lista_espera = @idLE2;
        
        -- ========== PASO 1: Dar de baja inscripciones actuales ==========
        UPDATE Inscripcion 
        SET estado = 0, fecha_baja = CAST(GETDATE() AS DATE)
        WHERE id_usuario = @idUsuario1 AND id_comision = @idComOrigen1 AND estado = 1;
        
        UPDATE Inscripcion 
        SET estado = 0, fecha_baja = CAST(GETDATE() AS DATE)
        WHERE id_usuario = @idUsuario2 AND id_comision = @idComOrigen2 AND estado = 1;
        
        PRINT '     ✓ Inscripciones antiguas dadas de baja.';
        
        -- ========== PASO 2: Crear nuevas inscripciones ==========
        INSERT INTO Inscripcion (id_comision, id_usuario, estado)
        VALUES (@idComDestino1, @idUsuario1, 1),
               (@idComDestino2, @idUsuario2, 1);
        
        PRINT '     ✓ Nuevas inscripciones creadas.';
        
        -- ========== PASO 3: Actualizar estado de propuesta ==========
        UPDATE Propuesta 
        SET estado = 'Aceptada', fecha_baja = GETDATE()
        WHERE id_propuesta = @idPropuesta;
        
        PRINT '     ✓ Propuesta marcada como Aceptada.';
        
        -- ========== PASO 4: Finalizar listas de espera ==========
        UPDATE Lista_Espera 
        SET estado = 'Finalizada', fecha_baja = CAST(GETDATE() AS DATE)
        WHERE id_lista_espera IN (@idLE1, @idLE2);
        
        PRINT '     ✓ Listas de espera finalizadas.';
        
        -- ========== PASO 5: Generar comprobante ==========
        INSERT INTO Comprobante (id_propuesta, id_usuario_1, id_usuario_2)
        VALUES (@idPropuesta, 
                IIF(@idUsuario1 < @idUsuario2, @idUsuario1, @idUsuario2),
                IIF(@idUsuario1 < @idUsuario2, @idUsuario2, @idUsuario1));
        
        PRINT '     ✓ Comprobante generado.';
        PRINT '   >> ¡INTERCAMBIO COMPLETADO EXITOSAMENTE!';
    END
    ELSE IF (@totalRespuestas = 2 AND @totalAceptadas < 2)
    BEGIN
        -- Al menos uno rechazó
        PRINT '   >> Propuesta rechazada por al menos un estudiante.';
        
        UPDATE Propuesta 
        SET estado = 'Rechazada', fecha_baja = GETDATE()
        WHERE id_propuesta = @idPropuesta;
        
        -- Volver a poner las listas en "En espera"
        UPDATE Lista_Espera 
        SET estado = 'En espera'
        WHERE id_lista_espera IN (
            SELECT id_listaEspera_1 FROM Propuesta WHERE id_propuesta = @idPropuesta
            UNION
            SELECT id_listaEspera_2 FROM Propuesta WHERE id_propuesta = @idPropuesta
        );
    END
END
GO
GO