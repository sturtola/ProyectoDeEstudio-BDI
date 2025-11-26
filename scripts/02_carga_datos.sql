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
    * 2. USUARIOS
    ****************************************************************************************/
    PRINT 'Cargando: 2. Usuarios (Todos nacen inactivos - estado 0)...';
    
    -- Admin (estado 0)
    EXEC sp_insertar_personal 'Admin', 'Sistema', 9999999, 'admin@unne.edu.ar', 'AdminPass123!', @idAdmin OUTPUT;
    
    -- Debemos activar manualmente al admin
    ALTER TABLE Usuario WHERE id_usuario = @idAdmin SET estado = 1;

    -- Verificador (estado 0)
    EXEC sp_insertar_personal 'Valeria', 'Verificadora', 8888888, 'verificador@unne.edu.ar', 'VerifPass123!', @idVerif OUTPUT;
    
    -- El admin habilita al verificador
    EXEC sp_actualizar_estado @idAdmin, @idVerif, 1;

    -- Estudiante 1 (VÁLIDO, 'G' para Com A)
    EXEC sp_insertar_estudiante 'Gabriel', 'Gonzalez', 30111222, 'g.gonzalez@alu.unne.edu.ar', 'UserPass123!', @idCarreraLSI, 'constancias/gonzalez.pdf', GETDATE(), @idEst1_Gonzalez OUTPUT;
    
    -- Estudiante 2 (VÁLIDO, 'R' para Com B)
    EXEC sp_insertar_estudiante 'Romina', 'Ramirez', 31222333, 'r.ramirez@alu.unne.edu.ar','UserPass123!', @idCarreraLSI, 'constancias/ramirez.pdf', GETDATE(), @idEst2_Ramirez OUTPUT;
 
    
    -- Estudiante 3 (INVÁLIDO - Constancia Vencida)
    EXEC sp_insertar_estudiante 'Ines', 'Ibañez', 34555666, 'i.ibañez@alu.unne.edu.ar', 'UserPass123!', @idCarreraLSI, 'constancias/ibanez.pdf', DATEADD(MONTH, -7, GETDATE()), @idEst3_Ibanez_Invalido OUTPUT;

    -- Estudiante 4 (Lucas Lopez - Comision A, igual que Gonzalez)
    EXEC sp_insertar_estudiante 'Lucas', 'Lopez', 32000111, 'l.lopez@alu.unne.edu.ar', 'Pass!', @idCarreraLSI, 'constancias/lopez.pdf', GETDATE(), @idEst4_Lopez OUTPUT;

    -- Estudiante 5, 6, 7 (Nuevos usuarios para pruebas de lista de espera)
    EXEC sp_insertar_estudiante 'Martina', 'Martinez', 35000111, 'm.martinez@alu.unne.edu.ar', 'Pass!', @idCarreraLSI, 'ok.pdf', GETDATE(), @idEst5_Martinez OUTPUT;

    EXEC sp_insertar_estudiante 'Pedro', 'Pascal', 36000111, 'p.pascal@alu.unne.edu.ar', 'Pass!', @idCarreraLSI, 'ok.pdf', GETDATE(), @idEst6_Pascal OUTPUT;

    EXEC sp_insertar_estudiante 'Sofia', 'Vergara', 37000111, 's.vergara@alu.unne.edu.ar', 'Pass!', @idCarreraLSI, 'ok.pdf', GETDATE(), @idEst7_Vergara OUTPUT;
     
     
   /****************************************************************************************
   * 4. INSCRIPCIONES (SP Y PRUEBA DE TRIGGER DE APELLIDO)
   ****************************************************************************************/
   PRINT 'Cargando: 4. Inscripciones...';
   PRINT '   (Se debe disparar el trigger tr_inscripcion_validar_letra_apellido)';  

   -- Inscribimos los estudiantes en las comisiones 
   EXEC sp_inscribir_estudiante @idEst1_Gonzalez, @idComision_BD1_A;  -- Gonzalez en A
   EXEC sp_inscribir_estudiante @idEst2_Ramirez, @idComision_BD1_B;   -- Ramirez en B
   EXEC sp_inscribir_estudiante @idEst4_Lopez, @idComision_BD1_A;    -- Lopez en A
   EXEC sp_inscribir_estudiante @idEst5_Martinez, @idComision_BD1_B; -- Martinez en B
   EXEC sp_inscribir_estudiante @idEst6_Pascal, @idComision_BD1_A;   -- Pascal en A
   EXEC sp_inscribir_estudiante @idEst7_Vergara, @idComision_BD1_A;  -- Vergara en A

   -- Unico alumno por el cual el trigger impide la inscripcion
   EXEC sp_inscribir_estudiante @idEst3_Ibanez_Invalido, @idComision_BD1_A; -- Ibañez en A (Inválido)


    /****************************************************************************************
    * 5. LISTA DE ESPERA (PRUEBA DE TRIGGER DE MATCHMAKING)
    ****************************************************************************************/
    PRINT 'Cargando: 5. Lista de Espera...';

    -- CASO 1: Match Inmediato
    PRINT ' -> Gonzalez (A->B) espera...';
    EXEC sp_inscribir_en_lista_espera @idEst1_Gonzalez, @idComision_BD1_A, @idComision_BD1_B;
    
    PRINT ' -> Ramirez (B->A) entra. ¡MATCH con Gonzalez!';
    EXEC sp_inscribir_en_lista_espera @idEst2_Ramirez, @idComision_BD1_B, @idComision_BD1_A;

    -- CASO 2: Match Diferido 
    PRINT ' -> Lucas Lopez (A->B) espera... (Nadie disponible)';
    EXEC sp_inscribir_en_lista_espera @idEst4_Lopez, @idComision_BD1_A, @idComision_BD1_B;

    PRINT ' -> Martina Martinez (B->A) entra. ¡MATCH con Lucas Lopez!';
    EXEC sp_inscribir_en_lista_espera @idEst5_Martinez, @idComision_BD1_B, @idComision_BD1_A;
   

    -- CASO 3: Cola de Espera (Sin match)
    PRINT ' -> Pedro Pascal (A->B) espera...';
    EXEC sp_inscribir_en_lista_espera @idEst6_Pascal, @idComision_BD1_A, @idComision_BD1_B;

    PRINT ' -> Sofia Vergara (A->B) espera... (Detras de Pedro)';
    EXEC sp_inscribir_en_lista_espera @idEst7_Vergara, @idComision_BD1_A, @idComision_BD1_B;

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