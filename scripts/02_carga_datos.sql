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

--SET NOCOUNT ON;     -- Evita que SQL Server devuelva el conteo de filas afectadas
SET XACT_ABORT ON;  -- Asegura que, si hay un error, la transacción completa haga ROLLBACK

PRINT 'Iniciando: 02_carga_datos.sql...';
PRINT '==================================================';
PRINT 'Fecha: ' + CONVERT(VARCHAR, GETDATE(), 120);

BEGIN TRY
    BEGIN TRAN CargaDatos;

    -- Declaración de variables para IDs
    DECLARE @idAdmin INT, @idVerif INT;
    DECLARE @idEst1_Gonzalez INT, @idEst2_Ramirez INT, @idEst3_Ibanez_Invalido INT;
    
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
    INSERT INTO Constancia (id_constancia, constancia_url, fecha_constancia)
    VALUES (@idEst1_Gonzalez, 'constancias/gonzalez.pdf', @fechaValida),
           (@idEst2_Ramirez, 'constancias/ramirez.pdf', @fechaValida);

    -- Caso INVÁLIDO (El trigger debería dejar Usuario.estado = 0)
    INSERT INTO Constancia (id_constancia, constancia_url, fecha_constancia)
    VALUES (@idEst3_Ibanez_Invalido, 'constancias/ibanez.pdf', @fechaVencida);

    /****************************************************************************************
    * 4. INSCRIPCIONES (PRUEBA DE TRIGGER DE APELLIDO)
    ****************************************************************************************/
    PRINT 'Cargando: 4. Inscripciones...';
    PRINT '   (Se debe disparar el trigger tr_inscripcion_validar_letra_apellido)';
    
    -- Inscribimos a los estudiantes que AHORA SÍ están VÁLIDOS (1 y 2)
    INSERT INTO Inscripcion (id_comision, id_usuario)
    VALUES (@idComision_BD1_A, @idEst1_Gonzalez),  -- Gonzalez ('G') en Com A (A-M) -> OK
           (@idComision_BD1_B, @idEst2_Ramirez);   -- Ramirez ('R') en Com B (N-Z) -> OK
           
    -- (No inscribimos a Ibañez porque su trigger de constancia lo dejó en estado = 0)

    /****************************************************************************************
    * 5. LISTA DE ESPERA (PRUEBA DE TRIGGER DE MATCHMAKING)
    ****************************************************************************************/
    PRINT 'Cargando: 5. Lista de Espera...';
    PRINT '   (Se debe disparar el trigger TR_ListaEspera_TryMatchOnInsert y el SP SIC_GenerarMatches)';

    -- Escenario 1: Match Perfecto (Gonzalez vs Ramirez)
    PRINT '   -> Creando par (Gonzalez A->B y Ramirez B->A)';
    
    -- Estudiante 1 (Gonzalez, Com A) quiere ir a Com B
    INSERT INTO Lista_Espera (estado, id_usuario, id_comision_origen, id_comision_destino)
    VALUES ('En espera', @idEst1_Gonzalez, @idComision_BD1_A, @idComision_BD1_B);
    
    -- Estudiante 2 (Ramirez, Com B) quiere ir a Com A
    INSERT INTO Lista_Espera (estado, id_usuario, id_comision_origen, id_comision_destino)
    VALUES ('En espera', @idEst2_Ramirez, @idComision_BD1_B, @idComision_BD1_A);
    -- (El trigger TR_ListaEspera_TryMatchOnInsert DEBE crear la Propuesta #1 aquí)

    
    -- Fin de la transacción
    PRINT 'Confirmando transacción (COMMIT)...';
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
PRINT '   (Gonzalez y Ramirez deben tener estado=1. Ibañez debe tener estado=0)';
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
PRINT '   (Debe existir 1 Propuesta en estado "Pendiente")';
SELECT 
    id_propuesta, 
    estado, 
    id_listaEspera_1, 
    id_listaEspera_2 
FROM Propuesta 
WHERE estado = 'Pendiente';
GO

PRINT '';
PRINT '   (Las 2 Listas de Espera deben estar en estado "Pendiente")';
SELECT 
    id_lista_espera, 
    estado, 
    id_usuario 
FROM Lista_Espera 
WHERE estado = 'Pendiente';
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