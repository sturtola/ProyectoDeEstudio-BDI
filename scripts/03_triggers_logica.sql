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
GO