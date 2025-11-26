/****************************************************************************************
* PROYECTO:         SIC-UNNE (Versión 2.0)
* AUTOR:            [Grupo 9]
* FECHA:            [05/11/2025]
* DESCRIPCIÓN:
* Lote de carga de datos iniciales para el sistema SIC.
* El script es transaccional: si alguna inserción falla, se revierte todo.
****************************************************************************************/

USE SIC_UNNE;
GO

SET NOCOUNT ON;     -- Evita que SQL Server devuelva el conteo de filas afectadas
SET XACT_ABORT ON;  -- Asegura que, si hay un error, la transacción completa haga ROLLBACK

PRINT 'Iniciando: 02_carga_datos.sql...';
PRINT '==================================================';
PRINT 'Fecha: ' + CONVERT(VARCHAR, GETDATE(), 120);

BEGIN TRY
    BEGIN TRAN CargaDatos;

    -- Declaración de variables para IDs
    DECLARE @idAdmin INT, @idVerif INT;
    DECLARE @idEst1_Gonzalez INT, @idEst2_Ramirez INT, @idEst3_Ibanez_Invalido INT;
    DECLARE @idEst4_Lopez INT, @idEst5_Martinez INT,@idEst6_Pascal INT, @idEst7_Vergara INT;
    
    DECLARE @idEdificioCentral INT;
    DECLARE @idFacuIngenieria INT;
    DECLARE @idCarreraLSI INT;
    DECLARE @idPeriodo_2C_2025 INT;
    DECLARE @idAsig_BD1 INT;
    DECLARE @idComision_BD1_A INT, @idComision_BD1_B INT;
    DECLARE @idHorarioLunes INT, @idHorarioMiercoles INT;
    DECLARE @idAula3 INT;

    /****************************************************************************************
    * 1. ESTRUCTURA ACADÉMICA (Respetando el orden de FKs)
    ****************************************************************************************/
    PRINT 'Cargando: 1. Estructura Académica (Edificio, Facultad, Carrera...).';

    -- 1.1. Estructura Física
    INSERT INTO Edificio (direccion, nombre) VALUES ('Av. Las Heras 727, Resistencia, Chaco', 'Campus Resistencia');
    SET @idEdificioCentral = SCOPE_IDENTITY();

    INSERT INTO Aula (nombre, id_edificio) VALUES ('Aula 3', @idEdificioCentral);
    SET @idAula3 = SCOPE_IDENTITY();

    -- 1.2. Estructura Académica
    INSERT INTO Facultad (nombre, ciudad, id_edificio) VALUES ('Facultad de Ingeniería', 'Resistencia', @idEdificioCentral);
    SET @idFacuIngenieria = SCOPE_IDENTITY();

    INSERT INTO Carrera (nombre, id_facultad) VALUES ('Licenciatura en Sistemas de Información', @idFacuIngenieria);
    SET @idCarreraLSI = SCOPE_IDENTITY();

    INSERT INTO Periodo (nombre, fecha_inicio, fecha_fin) VALUES ('2do Cuatrimestre', '2025-08-01', '2025-12-20');
    SET @idPeriodo_2C_2025 = SCOPE_IDENTITY();

    INSERT INTO Asignatura (nombre, anio_dictado, id_periodo) VALUES ('Bases de Datos I', 'Tercer Año', @idPeriodo_2C_2025);
    SET @idAsig_BD1 = SCOPE_IDENTITY();

    INSERT INTO Comision (nombre, letra_desde, letra_hasta, id_asignatura)
    VALUES ('Comisión A (A-M)', 'A', 'M', @idAsig_BD1),
           ('Comisión B (N-Z)', 'N', 'Z', @idAsig_BD1);
    SET @idComision_BD1_A = (SELECT id_comision FROM Comision WHERE nombre = 'Comisión A (A-M)');
    SET @idComision_BD1_B = (SELECT id_comision FROM Comision WHERE nombre = 'Comisión B (N-Z)');

    -- 1.3. Horarios y Profesores
    INSERT INTO Horario (dia, hora_inicio, hora_fin, modalidad) 
    VALUES ('Lunes', '08:00:00', '10:00:00', 'Presencial'), ('Miercoles', '08:00:00', '10:00:00', 'Presencial');
    SET @idHorarioLunes = (SELECT id_horario FROM Horario WHERE dia = 'Lunes');
    SET @idHorarioMiercoles = (SELECT id_horario FROM Horario WHERE dia = 'Miercoles');
    
    INSERT INTO Horario_Comision (id_horario, id_comision, id_aula)
    VALUES (@idHorarioLunes, @idComision_BD1_A, @idAula3),
           (@idHorarioMiercoles, @idComision_BD1_A, @idAula3);
           
    INSERT INTO Profesor (nombre, apellido, documento, correo, estado)
    VALUES ('Ricardo', 'Perez', 15111222, 'r.perez@prof.unne.edu.ar', 1);

    /****************************************************************************************
    * 2. USUARIOS (con HASHBYTES)
    ****************************************************************************************/
    PRINT 'Cargando: 2. Usuarios (Todos nacen inactivos - estado 0)...';
    
    -- Admin (estado 0)
    INSERT INTO Usuario (nombre, apellido, documento, correo, contrasena, rol, id_carrera)
    VALUES ('Admin', 'Sistema', 9999999, 'admin@unne.edu.ar', HASHBYTES('SHA2_512', 'AdminPass123!'), 'Administrador', NULL);
    SET @idAdmin = SCOPE_IDENTITY();

    -- Verificador (estado 0)
    INSERT INTO Usuario (nombre, apellido, documento, correo, contrasena, rol, id_carrera)
    VALUES ('Valeria', 'Verificadora', 8888888, 'verificador@unne.edu.ar', HASHBYTES('SHA2_512', 'VerifPass123!'), 'Verificador', NULL);
    SET @idVerif = SCOPE_IDENTITY();

    -- Estudiante 1 (VÁLIDO, 'G' para Com A)
    INSERT INTO Usuario (nombre, apellido, documento, correo, contrasena, rol, id_carrera)
    VALUES ('Gabriel', 'Gonzalez', 30111222, 'g.gonzalez@alu.unne.edu.ar', HASHBYTES('SHA2_512', 'UserPass123!'), 'Estudiante', @idCarreraLSI);
    SET @idEst1_Gonzalez = SCOPE_IDENTITY();
    
    -- Estudiante 2 (VÁLIDO, 'R' para Com B)
    INSERT INTO Usuario (nombre, apellido, documento, correo, contrasena, rol, id_carrera)
    VALUES ('Romina', 'Ramirez', 31222333, 'r.ramirez@alu.unne.edu.ar', HASHBYTES('SHA2_512', 'UserPass123!'), 'Estudiante', @idCarreraLSI);
    SET @idEst2_Ramirez = SCOPE_IDENTITY();
    
    -- Estudiante 3 (INVÁLIDO - Constancia Vencida)
    INSERT INTO Usuario (nombre, apellido, documento, correo, contrasena, rol, id_carrera)
    VALUES ('Ines', 'Ibañez', 34555666, 'i.ibañez@alu.unne.edu.ar', HASHBYTES('SHA2_512', 'UserPass123!'), 'Estudiante', @idCarreraLSI);
    SET @idEst3_Ibanez_Invalido = SCOPE_IDENTITY();

    -- Estudiante 4 (Lucas Lopez - Comision A, igual que Gonzalez)
    INSERT INTO Usuario (nombre, apellido, documento, correo, contrasena, rol, id_carrera) 
    VALUES ('Lucas', 'Lopez', 32000111, 'l.lopez@alu.unne.edu.ar', HASHBYTES('SHA2_512', 'Pass!'), 'Estudiante', @idCarreraLSI),
       -- NUEVOS USUARIOS
            ('Martina', 'Martinez', 35000111, 'm.martinez@alu.unne.edu.ar', HASHBYTES('SHA2_512', 'Pass!'), 'Estudiante', @idCarreraLSI),
            ('Pedro', 'Pascal', 36000111, 'p.pascal@alu.unne.edu.ar', HASHBYTES('SHA2_512', 'Pass!'), 'Estudiante', @idCarreraLSI),
            ('Sofia', 'Vergara', 37000111, 's.vergara@alu.unne.edu.ar', HASHBYTES('SHA2_512', 'Pass!'), 'Estudiante', @idCarreraLSI);
    SET @idEst4_Lopez = (SELECT id_usuario FROM Usuario WHERE apellido='Lopez');
    SET @idEst5_Martinez = (SELECT id_usuario FROM Usuario WHERE apellido='Martinez');
    SET @idEst6_Pascal = (SELECT id_usuario FROM Usuario WHERE apellido='Pascal');
    SET @idEst7_Vergara = (SELECT id_usuario FROM Usuario WHERE apellido='Vergara');

    -- Activación Manual de Admin/Verificador (necesario por el DEFAULT 0)
    PRINT 'Cargando: 2.1. Activación manual de Admin y Verificador...';
    UPDATE Usuario SET estado = 1 WHERE id_usuario IN (@idAdmin, @idVerif);

    /****************************************************************************************
    * 3. CONSTANCIAS (PRUEBA DE TRIGGER DE HABILITACIÓN)
    ****************************************************************************************/
    PRINT 'Cargando: 3. Constancias...';
    PRINT '   (Se debe disparar el trigger tr_estudiante_verificar_constancia)';
    
    DECLARE @fechaHoy DATE = GETDATE();
    DECLARE @fechaValida DATE = DATEADD(DAY, -30, @fechaHoy);  -- Válida
    DECLARE @fechaVencida DATE = DATEADD(MONTH, -7, @fechaHoy); -- Vencida

    -- Casos VÁLIDOS (El trigger debería poner Usuario.estado = 1)
    INSERT INTO Constancia (id_usuario, constancia_url, fecha_constancia)
    VALUES (@idEst1_Gonzalez, 'constancias/gonzalez.pdf', @fechaValida),
           (@idEst2_Ramirez, 'constancias/ramirez.pdf', @fechaValida),
           (@idEst4_Lopez, 'constancias/lopez.pdf', @fechaValida),
           (@idEst5_Martinez, 'ok.pdf', @fechaValida),
           (@idEst6_Pascal, 'ok.pdf', @fechaValida),
           (@idEst7_Vergara, 'ok.pdf', @fechaValida);

    -- Caso INVÁLIDO (El trigger debería dejar Usuario.estado = 0)
    INSERT INTO Constancia (id_usuario, constancia_url, fecha_constancia)
    VALUES (@idEst3_Ibanez_Invalido, 'constancias/ibanez.pdf', @fechaVencida);

    /****************************************************************************************
    * 4. INSCRIPCIONES (PRUEBA DE TRIGGER DE APELLIDO)
    ****************************************************************************************/
    PRINT 'Cargando: 4. Inscripciones...';
    PRINT '   (Se debe disparar el trigger tr_inscripcion_validar_letra_apellido)';
    
    -- Inscribimos a los estudiantes que AHORA SÍ están VÁLIDOS (1 y 2)
    INSERT INTO Inscripcion (id_comision, id_usuario)
    VALUES (@idComision_BD1_A, @idEst1_Gonzalez),  -- Gonzalez ('G') en Com A (A-M) -> OK
           (@idComision_BD1_B, @idEst2_Ramirez),   -- Ramirez ('R') en Com B (N-Z) -> OK
           (@idComision_BD1_A, @idEst4_Lopez),    -- Lucas en A
           (@idComision_BD1_B, @idEst5_Martinez), -- B (Nueva)
           (@idComision_BD1_A, @idEst6_Pascal),   -- A (Nuevo)
           (@idComision_BD1_A, @idEst7_Vergara);  -- A (Nueva)
           
    -- (No inscribimos a Ibañez porque su trigger de constancia lo dejó en estado = 0)

    /****************************************************************************************
    * 5. LISTA DE ESPERA (PRUEBA DE TRIGGER DE MATCHMAKING)
    ****************************************************************************************/
    PRINT 'Cargando: 5. Lista de Espera...';
    -- CASO 1: Match Inmediato
    PRINT ' -> Gonzalez (A->B) espera...';
    INSERT INTO Lista_Espera (estado, id_usuario, id_comision_origen, id_comision_destino)
    VALUES ('En espera', @idEst1_Gonzalez, @idComision_BD1_A, @idComision_BD1_B);
    
    PRINT ' -> Ramirez (B->A) entra. ¡MATCH con Gonzalez!';
    INSERT INTO Lista_Espera (estado, id_usuario, id_comision_origen, id_comision_destino)
    VALUES ('En espera', @idEst2_Ramirez, @idComision_BD1_B, @idComision_BD1_A);

    -- CASO 2: Match Diferido (El que espera encuentra novia despues)
    PRINT ' -> Lucas Lopez (A->B) espera... (Nadie disponible)';
    INSERT INTO Lista_Espera (estado, id_usuario, id_comision_origen, id_comision_destino)
    VALUES ('En espera', @idEst4_Lopez, @idComision_BD1_A, @idComision_BD1_B);

    PRINT ' -> Martina Martinez (B->A) entra. ¡MATCH con Lucas Lopez!';
    INSERT INTO Lista_Espera (estado, id_usuario, id_comision_origen, id_comision_destino)
    VALUES ('En espera', @idEst5_Martinez, @idComision_BD1_B, @idComision_BD1_A);

    -- CASO 3: Cola de Espera (Sin match)
    PRINT ' -> Pedro Pascal (A->B) espera...';
    INSERT INTO Lista_Espera (estado, id_usuario, id_comision_origen, id_comision_destino)
    VALUES ('En espera', @idEst6_Pascal, @idComision_BD1_A, @idComision_BD1_B);

    PRINT ' -> Sofia Vergara (A->B) espera... (Detras de Pedro)';
    INSERT INTO Lista_Espera (estado, id_usuario, id_comision_origen, id_comision_destino)
    VALUES ('En espera', @idEst7_Vergara, @idComision_BD1_A, @idComision_BD1_B);

    COMMIT TRAN CargaDatos;    
    PRINT '';
    PRINT '==================================================';
    PRINT '¡LOTE DE CARGA FINALIZADO EXITOSAMENTE!';
    PRINT '==================================================';


END TRY
BEGIN CATCH
    -- Si algo falló, deshace todo
    IF @@TRANCOUNT > 0
    BEGIN
        ROLLBACK TRAN CargaDatos;
    END

    -- Muestra el error
    PRINT '';
    PRINT '==================================================';
    PRINT '¡ERROR! El lote de carga falló. Se revirtió la transacción.';
    PRINT '==================================================';
    PRINT 'Error: ' + ERROR_MESSAGE();
    PRINT 'Línea: ' + CAST(ERROR_LINE() AS VARCHAR);
    PRINT GETDATE();
END CATCH
GO

/****************************************************************************************
* 6. PRUEBAS (SELECTs)
* Esta sección comprueba el resultado de los triggers que se dispararon
* durante la carga de datos.
****************************************************************************************/
PRINT '';
PRINT '==================================================';
PRINT 'INICIANDO PRUEBAS (VERIFICACIÓN DE TRIGGERS)';
PRINT '==================================================';
GO

-- PRUEBA 1: Verificación del Trigger de Habilitación (Constancia)
PRINT '';
PRINT '--- PRUEBA 1: Trigger de Habilitación (tr_estudiante_verificar_constancia)';
PRINT '   (Gonzalez, Ramirez y Lopez deben tener estado=1. Ibañez debe tener estado=0)';
SELECT 
    id_usuario, 
    nombre, 
    apellido, 
    estado AS [Estado (1=Habilitado)]
FROM Usuario 
WHERE rol = 'Estudiante';
GO

-- PRUEBA 2: Verificación del Trigger de Matchmaking (TR_ListaEspera_TryMatchOnInsert)
PRINT '';
PRINT '--- PRUEBA 2: Trigger de Matchmaking (TR_ListaEspera_TryMatchOnInsert)';
PRINT '   (Debe existir 1 Propuesta en estado "Pendiente" entre Gonzalez y Ramirez)';
SELECT 
    id_propuesta, 
    estado, 
    id_listaEspera_1, 
    id_listaEspera_2 
FROM Propuesta 
WHERE estado = 'Pendiente';
GO

PRINT '';
PRINT '   (Listas: Gonzalez y Ramirez "Pendiente". Lopez debe estar "En espera")';
SELECT 
    id_lista_espera, 
    estado, 
    id_usuario 
FROM Lista_Espera 
WHERE estado IN ('Pendiente', 'En espera');
GO

-- PRUEBA 3: Verificación del Hasheo de Contraseñas
PRINT '';
PRINT '--- PRUEBA 3: Verificación de Hasheo de Contraseñas';
PRINT '   (La columna contrasena NO debe ser texto plano, debe ser VARBINARY)';
SELECT 
    id_usuario, 
    correo, 
    contrasena AS [Hash (VARBINARY(64))]
FROM Usuario;
GO

/****************************************************************************************
* 7. PRUEBAS FINALES (VISUALIZACIÓN CLARA)
****************************************************************************************/
PRINT '';
PRINT '=======================================================';
PRINT '   REPORTE DE ESTADO DEL SISTEMA (NOMBRES REALES)';
PRINT '=======================================================';

PRINT '';
PRINT '>>> 1. PROPUESTAS DE INTERCAMBIO (MATCHES) <<<';
PRINT 'Debería haber 2 parejas: Gonzalez-Ramirez y Lopez-Martinez';

SELECT 
    P.id_propuesta,
    P.estado AS [Estado],
    -- Estudiante 1
    U1.apellido + ' ' + U1.nombre AS [Estudiante 1],
    C1_Dest.nombre AS [Quiere ir a],
    -- Estudiante 2
    ' <---> ' AS [VS],
    U2.apellido + ' ' + U2.nombre AS [Estudiante 2],
    C2_Dest.nombre AS [Quiere ir a]
FROM Propuesta P
JOIN Lista_Espera L1 ON P.id_listaEspera_1 = L1.id_lista_espera
JOIN Usuario U1 ON L1.id_usuario = U1.id_usuario
JOIN Comision C1_Dest ON L1.id_comision_destino = C1_Dest.id_comision
JOIN Lista_Espera L2 ON P.id_listaEspera_2 = L2.id_lista_espera
JOIN Usuario U2 ON L2.id_usuario = U2.id_usuario
JOIN Comision C2_Dest ON L2.id_comision_destino = C2_Dest.id_comision;

PRINT '';
PRINT '>>> 2. GENTE SOLA EN LISTA DE ESPERA <<<';
PRINT 'Deberían estar Pascal y Vergara esperando';

SELECT 
    L.id_lista_espera,
    U.apellido + ' ' + U.nombre AS [Estudiante],
    C_Orig.nombre AS [Actual],
    C_Dest.nombre AS [Busca],
    L.estado
FROM Lista_Espera L
JOIN Usuario U ON L.id_usuario = U.id_usuario
JOIN Comision C_Orig ON L.id_comision_origen = C_Orig.id_comision
JOIN Comision C_Dest ON L.id_comision_destino = C_Dest.id_comision
WHERE L.estado = 'En espera';
GO