/****************************************************************************************
* NOMBRE:           04_visualizaciones_del_sistema.sql
* DESCRIPCIÓN:      Visualizaciones y simulación de aceptación de propuestas
****************************************************************************************/
USE SIC_UNNE;
GO

PRINT '==================================================';
PRINT 'VISUALIZACIONES DEL SISTEMA - ESTADO ACTUAL';
PRINT '==================================================';
PRINT '';

-- ============================================================================
-- 1. VISTA: MATCHES PENDIENTES (Con datos completos de los estudiantes)
-- ============================================================================
PRINT '--- 1. MATCHES PENDIENTES ---';
SELECT 
    P.id_propuesta AS [ID Propuesta],
    P.estado AS [Estado],
    P.fecha_alta AS [Fecha Creación],
    
    -- Estudiante 1
    U1.nombre + ' ' + U1.apellido AS [Estudiante 1],
    C1_Origen.nombre AS [Comisión Origen Est1],
    C1_Destino.nombre AS [Comisión Destino Est1],
    
    -- Estudiante 2
    U2.nombre + ' ' + U2.apellido AS [Estudiante 2],
    C2_Origen.nombre AS [Comisión Origen Est2],
    C2_Destino.nombre AS [Comisión Destino Est2]
    
FROM Propuesta P
    INNER JOIN Lista_Espera LE1 ON P.id_listaEspera_1 = LE1.id_lista_espera
    INNER JOIN Lista_Espera LE2 ON P.id_listaEspera_2 = LE2.id_lista_espera
    INNER JOIN Usuario U1 ON LE1.id_usuario = U1.id_usuario
    INNER JOIN Usuario U2 ON LE2.id_usuario = U2.id_usuario
    INNER JOIN Comision C1_Origen ON LE1.id_comision_origen = C1_Origen.id_comision
    INNER JOIN Comision C1_Destino ON LE1.id_comision_destino = C1_Destino.id_comision
    INNER JOIN Comision C2_Origen ON LE2.id_comision_origen = C2_Origen.id_comision
    INNER JOIN Comision C2_Destino ON LE2.id_comision_destino = C2_Destino.id_comision
WHERE P.estado = 'Pendiente';

PRINT '';

-- ============================================================================
-- 2. VISTA: COLA DE ESPERA (Sin match todavía)
-- ============================================================================
PRINT '--- 2. ESTUDIANTES EN COLA DE ESPERA ---';
SELECT 
    LE.id_lista_espera AS [ID Lista],
    U.nombre + ' ' + U.apellido AS [Estudiante],
    C_Origen.nombre AS [Comisión Actual],
    C_Destino.nombre AS [Comisión Deseada],
    LE.fecha_alta AS [Fecha Ingreso],
    LE.estado AS [Estado]
FROM Lista_Espera LE
    INNER JOIN Usuario U ON LE.id_usuario = U.id_usuario
    INNER JOIN Comision C_Origen ON LE.id_comision_origen = C_Origen.id_comision
    INNER JOIN Comision C_Destino ON LE.id_comision_destino = C_Destino.id_comision
WHERE LE.estado = 'En espera'
ORDER BY LE.fecha_alta ASC;

PRINT '';
PRINT '==================================================';
PRINT 'SIMULACIÓN: ACEPTACIÓN DE PROPUESTA (Gonzalez & Ramirez)';
PRINT '==================================================';
PRINT '';

BEGIN TRY
    BEGIN TRAN SimulacionAceptacion;

    -- Obtenemos IDs necesarios
    DECLARE @idPropuesta1 INT = (SELECT TOP 1 id_propuesta FROM Propuesta WHERE estado = 'Pendiente' ORDER BY id_propuesta);
    DECLARE @idUsuario_Gonzalez INT = (SELECT id_usuario FROM Usuario WHERE apellido = 'Gonzalez');
    DECLARE @idUsuario_Ramirez INT = (SELECT id_usuario FROM Usuario WHERE apellido = 'Ramirez');
    
    DECLARE @idLE_Gonzalez INT = (SELECT id_lista_espera FROM Lista_Espera WHERE id_usuario = @idUsuario_Gonzalez AND estado = 'Pendiente');
    DECLARE @idLE_Ramirez INT = (SELECT id_lista_espera FROM Lista_Espera WHERE id_usuario = @idUsuario_Ramirez AND estado = 'Pendiente');
    
    DECLARE @idComision_A INT = (SELECT id_comision FROM Comision WHERE nombre LIKE '%A%');
    DECLARE @idComision_B INT = (SELECT id_comision FROM Comision WHERE nombre LIKE '%B%');
    
    PRINT 'IDs Obtenidos:';
    PRINT '  Propuesta: ' + CAST(@idPropuesta1 AS VARCHAR);
    PRINT '  Gonzalez: ' + CAST(@idUsuario_Gonzalez AS VARCHAR);
    PRINT '  Ramirez: ' + CAST(@idUsuario_Ramirez AS VARCHAR);
    PRINT '';
    
    -- ============================================================================
    -- PASO 1: Gonzalez Acepta
    -- ============================================================================
    PRINT '>> PASO 1: Gonzalez acepta la propuesta...';
    INSERT INTO Respuesta_Propuesta (decision, motivo_rechazo, id_propuesta, id_usuario)
    VALUES ('Aceptar', NULL, @idPropuesta1, @idUsuario_Gonzalez);
    PRINT '   ✓ Respuesta registrada.';
    PRINT '';
    
    -- ============================================================================
    -- PASO 2: Ramirez Acepta (Trigger debe dispararse aquí)
    -- ============================================================================
    PRINT '>> PASO 2: Ramirez acepta la propuesta...';
    INSERT INTO Respuesta_Propuesta (decision, motivo_rechazo, id_propuesta, id_usuario)
    VALUES ('Aceptar', NULL, @idPropuesta1, @idUsuario_Ramirez);
    PRINT '   ✓ Respuesta registrada.';
    PRINT '   ✓ ¡AMBOS ACEPTARON! Ejecutando intercambio...';
    PRINT '';
    
    COMMIT TRAN SimulacionAceptacion;
    
    PRINT '==================================================';
    PRINT '✓ SIMULACIÓN COMPLETADA EXITOSAMENTE';
    PRINT '==================================================';
    PRINT '';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN SimulacionAceptacion;
    PRINT '¡ERROR EN SIMULACIÓN!';
    PRINT ERROR_MESSAGE();
END CATCH
GO

-- ============================================================================
-- 3. VERIFICACIÓN POST-ACEPTACIÓN
-- ============================================================================
PRINT '==================================================';
PRINT 'VERIFICACIÓN: ESTADO DESPUÉS DE LA ACEPTACIÓN';
PRINT '==================================================';
PRINT '';

PRINT '--- 3.1. Estado de la Propuesta ---';
SELECT 
    id_propuesta,
    estado,
    fecha_alta,
    fecha_baja
FROM Propuesta;
PRINT '';

PRINT '--- 3.2. Respuestas Registradas ---';
SELECT 
    RP.id_respuesta,
    U.nombre + ' ' + U.apellido AS [Usuario],
    RP.decision,
    RP.fecha
FROM Respuesta_Propuesta RP
    INNER JOIN Usuario U ON RP.id_usuario = U.id_usuario
ORDER BY RP.fecha;
PRINT '';

PRINT '--- 3.3. Estado de Listas de Espera ---';
SELECT 
    LE.id_lista_espera,
    U.nombre + ' ' + U.apellido AS [Usuario],
    LE.estado,
    LE.fecha_baja
FROM Lista_Espera LE
    INNER JOIN Usuario U ON LE.id_usuario = U.id_usuario;
PRINT '';

PRINT '--- 3.4. Inscripciones Actuales (VERIFICAR INTERCAMBIO) ---';
SELECT 
    I.id_inscripcion,
    U.nombre + ' ' + U.apellido AS [Estudiante],
    C.nombre AS [Comisión],
    I.estado AS [Activa?],
    I.fecha_alta,
    I.fecha_baja
FROM Inscripcion I
    INNER JOIN Usuario U ON I.id_usuario = U.id_usuario
    INNER JOIN Comision C ON I.id_comision = C.id_comision
WHERE U.apellido IN ('Gonzalez', 'Ramirez')
ORDER BY U.apellido, I.fecha_alta;
PRINT '';

PRINT '--- 3.5. Comprobantes Generados ---';
SELECT 
    C.id_comprobante,
    C.fecha_emision,
    U1.nombre + ' ' + U1.apellido AS [Estudiante 1],
    U2.nombre + ' ' + U2.apellido AS [Estudiante 2]
FROM Comprobante C
    INNER JOIN Usuario U1 ON C.id_usuario_1 = U1.id_usuario
    INNER JOIN Usuario U2 ON C.id_usuario_2 = U2.id_usuario;
PRINT '';

PRINT '==================================================';
PRINT 'FIN DE VISUALIZACIONES';
PRINT '==================================================';