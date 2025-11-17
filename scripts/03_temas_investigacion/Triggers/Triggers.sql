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
   - Cambio de estado (Pendiente → Aceptada / Rechazada)
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
