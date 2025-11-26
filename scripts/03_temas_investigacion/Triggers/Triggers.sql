/* ============================================================
   TABLA DE AUDITORÍA PARA INSCRIPCIONES
   Guarda datos OLD + metadata cada vez que se modifica o elimina
   ============================================================ */

CREATE TABLE Auditoria_Inscripcion (
    id_auditoria INT IDENTITY(1,1) PRIMARY KEY,

    -- Copia del estado anterior de la inscripción
    id_inscripcion_old INT NOT NULL,
    fecha_alta_old DATE NOT NULL,
    fecha_baja_old DATE NULL,
    estado_old BIT NOT NULL,
    id_comision_old INT NOT NULL,
    id_usuario_old INT NOT NULL,

    -- Metadata de auditoría
    fecha_accion DATETIME NOT NULL DEFAULT(GETDATE()),
    usuario_bd SYSNAME NOT NULL DEFAULT(SUSER_SNAME()),
    tipo_operacion NVARCHAR(20) NOT NULL
);
GO


/* ============================================================
   TRIGGER DE AUDITORÍA – AFTER UPDATE EN INSCRIPCION
   Registra el estado anterior (OLD) cada vez que se modifique
   ============================================================ */
CREATE TRIGGER TR_Inscripcion_Auditoria_Update
ON Inscripcion
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Auditoria_Inscripcion (
        id_inscripcion_old, fecha_alta_old, fecha_baja_old,
        estado_old, id_comision_old, id_usuario_old,
        fecha_accion, usuario_bd, tipo_operacion
    )
    SELECT
        d.id_inscripcion,
        d.fecha_alta,
        d.fecha_baja,
        d.estado,
        d.id_comision,
        d.id_usuario,
        GETDATE(),
        SUSER_SNAME(),
        'UPDATE'
    FROM deleted d;
END;
GO


/* ============================================================
   TRIGGER DE AUDITORÍA – AFTER DELETE EN INSCRIPCION
   Registra el estado OLD antes de que el registro desaparezca
   ============================================================ */
CREATE TRIGGER TR_Inscripcion_Auditoria_Delete
ON Inscripcion
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Auditoria_Inscripcion (
        id_inscripcion_old, fecha_alta_old, fecha_baja_old,
        estado_old, id_comision_old, id_usuario_old,
        fecha_accion, usuario_bd, tipo_operacion
    )
    SELECT
        d.id_inscripcion,
        d.fecha_alta,
        d.fecha_baja,
        d.estado,
        d.id_comision,
        d.id_usuario,
        GETDATE(),
        SUSER_SNAME(),
        'DELETE'
    FROM deleted d;
END;
GO



/* ============================================================
   TRIGGER PARA BLOQUEAR DELETE EN PROPUESTA
   NO permite eliminar propuestas (solo cambio de estado)
   ============================================================ */
CREATE TRIGGER TR_Propuesta_Bloquear_Delete
ON Propuesta
INSTEAD OF DELETE
AS
BEGIN
    RAISERROR('No está permitido eliminar propuestas. Utilice manejo de estado.', 16, 1);
    ROLLBACK TRANSACTION;
END;
GO



/* ============================================================
   TRIGGER PARA RESTRINGIR UPDATES EN PROPUESTA
   Solo permite:
   - Cambio de estado (Pendiente ? Aceptada / Rechazada)
   NO permite modificar:
   - fecha_alta, fecha_baja
   - id_listaEspera_1 / id_listaEspera_2
   ============================================================ */
CREATE TRIGGER TR_Propuesta_Restringir_Update
ON Propuesta
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Si se modificaron campos prohibidos
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN deleted d ON d.id_propuesta = i.id_propuesta
        WHERE
            d.id_listaEspera_1 <> i.id_listaEspera_1 OR
            d.id_listaEspera_2 <> i.id_listaEspera_2 OR
            d.fecha_alta <> i.fecha_alta
    )
    BEGIN
        RAISERROR(
            'Solo se permite actualizar el estado de la propuesta. No se pueden modificar listas de espera ni fechas.',
            16, 1
        );
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO

/* ============================================================
   TRIGGER PARA VERIFICACIÓN DE VIGENCIA DE CONSTANCIA
   Actualiza el estado del Usuario (Estudiante) al insertar una constancia.
   Lógica de actualización:
   - Si la fecha es reciente (últimos 6 meses) -> HABILITA al usuario (Estado = 1).
   - Si la fecha es antigua (> 6 meses) -> INHABILITA al usuario (Estado = 0).
   ============================================================ */
CREATE TRIGGER tr_estudiante_verificar_constancia
ON Constancia
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Declaramos variables para evaluar la fecha
    DECLARE @fechaLimite DATE = GETDATE(); -- O la fecha que definas como límite

    -- Actualizamos a estado = 1 (Activo) a los usuarios que:
    -- 1. Acaban de presentar una constancia (están en la tabla 'inserted')
    -- 2. La constancia no es vieja (por ejemplo, tiene menos de 6 meses)
    -- 3. La extensión es válida (aunque esto ya lo valida tu CHECK constraint)
    
    UPDATE U
    SET U.estado = 1
    FROM Usuario U
    INNER JOIN inserted I ON U.id_usuario = I.id_usuario
    WHERE I.fecha_constancia >= DATEADD(MONTH, -6, GETDATE()) -- Ejemplo: validez de 6 meses
      AND U.rol = 'Estudiante';

    -- Opcional: Si la constancia es vieja, podrías forzar el estado 0
    UPDATE U
    SET U.estado = 0
    FROM Usuario U
    INNER JOIN inserted I ON U.id_usuario = I.id_usuario
    WHERE I.fecha_constancia < DATEADD(MONTH, -6, GETDATE())
      AND U.rol = 'Estudiante';
END;
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
