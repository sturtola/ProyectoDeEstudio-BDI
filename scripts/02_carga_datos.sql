/****************************************************************************************
* PROYECTO:         SIC-UNNE (Bases de Datos I)
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

PRINT 'Iniciando el lote de carga de datos...';
PRINT '==================================================';
PRINT GETDATE();

BEGIN TRY
    BEGIN TRAN CargaDatos;

    -- Declaración de variables para IDs 
    DECLARE @idAdmin INT, @idVerif INT;
    DECLARE @idEstudianteValido1 INT, @idEstudianteValido2 INT, @idEstudianteValido3 INT, @idEstudianteValido4 INT;
    DECLARE @idEstudianteInvalido INT, @idEstudianteBloqueado INT;
    
    DECLARE @idEdificioCentral INT;
    DECLARE @idFacuIngenieria INT;
    DECLARE @idPeriodo_2C_2025 INT;
    DECLARE @idAsig_BD1 INT;
    DECLARE @idComision_BD1_A INT, @idComision_BD1_B INT;

    /****************************************************************************************
    * 1. TABLAS DE CONFIGURACIÓN (INDEPENDIENTES)
    ****************************************************************************************/
    PRINT 'Cargando: 1. Tablas de Configuración (Edificio, Periodo, Horario)...';

    -- Edificio
    INSERT INTO Edificio (direccion, nombre)
    VALUES ('Av. Las Heras 727, Resistencia, Chaco', 'Campus Resistencia'),
           ('Sargento Cabral 2139, Corrientes', 'Campus Corrientes');
    
    SET @idEdificioCentral = (SELECT id_edificio FROM Edificio WHERE nombre = 'Campus Resistencia');

    -- Periodo
    INSERT INTO Periodo (nombre, fecha_inicio, fecha_fin)
    VALUES ('2do Cuatrimestre', '2025-08-01', '2025-12-20'); -- Asumimos un período actual
    
    SET @idPeriodo_2C_2025 = (SELECT id_periodo FROM Periodo WHERE nombre = '2do Cuatrimestre' AND YEAR(fecha_inicio) = 2025);

    -- Horario
    INSERT INTO Horario (dia, hora_inicio, hora_fin, modalidad)
    VALUES ('Lunes', '08:00:00', '10:00:00', 'Presencial'),
           ('Miercoles', '08:00:00', '10:00:00', 'Presencial'),
           ('Viernes', '16:00:00', '18:00:00', 'Virtual');

    /****************************************************************************************
    * 2. ESTRUCTURA ACADÉMICA (NIVEL 1)
    ****************************************************************************************/
    PRINT 'Cargando: 2. Estructura Académica N1 (Facultad, Aula, Asignatura)...';

    -- Facultad
    INSERT INTO Facultad (nombre, ciudad, id_edificio)
    VALUES ('Facultad de Ingeniería', 'Resistencia', @idEdificioCentral),
           ('Facultad de Ciencias Económicas', 'Resistencia', @idEdificioCentral);
    
    SET @idFacuIngenieria = (SELECT id_facultad FROM Facultad WHERE nombre = 'Facultad de Ingeniería');

    -- Aula
    INSERT INTO Aula (nombre, id_edificio)
    VALUES ('Salón de Actos', @idEdificioCentral),
           ('Aula 3', @idEdificioCentral);

    -- Asignatura
    INSERT INTO Asignatura (nombre, anio_dictado, id_periodo)
    VALUES ('Bases de Datos I', 'Tercer Año', @idPeriodo_2C_2025),
           ('Algebra y Geometría Analítica', 'Primer Año', @idPeriodo_2C_2025);
    
    SET @idAsig_BD1 = (SELECT id_asignatura FROM Asignatura WHERE nombre = 'Bases de Datos I');
    
    /****************************************************************************************
    * 3. ESTRUCTURA ACADÉMICA (NIVEL 2)
    ****************************************************************************************/
    PRINT 'Cargando: 3. Estructura Académica N2 (Carrera, Comision)...';
    
    -- Carrera
    INSERT INTO Carrera (nombre, id_facultad)
    VALUES ('Licenciatura en Sistemas de Información', @idFacuIngenieria),
           ('Contador Público', (SELECT id_facultad FROM Facultad WHERE nombre = 'Facultad de Ciencias Económicas'));

    -- Comision (¡Importante para el TRIGER de apellido!)
    INSERT INTO Comision (nombre, letra_desde, letra_hasta, id_asignatura)
    VALUES ('Comisión A (A-M)', 'A', 'M', @idAsig_BD1),
           ('Comisión B (N-Z)', 'N', 'Z', @idAsig_BD1);
    
    SET @idComision_BD1_A = (SELECT id_comision FROM Comision WHERE nombre = 'Comisión A (A-M)' AND id_asignatura = @idAsig_BD1);
    SET @idComision_BD1_B = (SELECT id_comision FROM Comision WHERE nombre = 'Comisión B (N-Z)' AND id_asignatura = @idAsig_BD1);

    /****************************************************************************************
    * 4. USUARIOS Y ROLES
    ****************************************************************************************/
    PRINT 'Cargando: 4. Usuarios y Roles...';

    -- 4.1. Administrador
    INSERT INTO Usuario (nombre, apellido, documento, correo, contrasena, estado, rol)
    VALUES ('Admin', 'Sistema', 9999999, 'admin@unne.edu.ar', HASHBYTES('SHA2_512', 'AdminPass123!'), 1, 'Administrador');
    SET @idAdmin = SCOPE_IDENTITY();

    -- 4.2. Verificador
    INSERT INTO Usuario (nombre, apellido, documento, correo, contrasena, estado, rol)
    VALUES ('Valeria', 'Verificadora', 8888888, 'verificador@unne.edu.ar', HASHBYTES('SHA2_512', 'VerifPass123!'), 1, 'Verificador');
    SET @idVerif = SCOPE_IDENTITY();
    
    INSERT INTO Verificador (id_verificador) VALUES (@idVerif);

    -- 4.3. Estudiantes (Datos de Prueba)
    -- El trigger tr_usuario_default_estado_por_rol pondrá estado = 0
    
    PRINT 'Cargando Estudiantes (válidos)...';
    
    -- Estudiante 1 (VÁLIDO, Apellido con 'G'. Quiere cambiar de A->B)
    INSERT INTO Usuario (nombre, apellido, documento, correo, contrasena, rol)
    VALUES ('Gabriel', 'Gonzalez', 30111222, 'g.gonzalez@alu.unne.edu.ar', HASHBYTES('SHA2_512', 'UserPass123!'), 'Estudiante');
    SET @idEstudianteValido1 = SCOPE_IDENTITY();
    
    -- Estudiante 2 (VÁLIDO, Apellido con 'R'. Quiere cambiar de B->A)
    INSERT INTO Usuario (nombre, apellido, documento, correo, contrasena, rol)
    VALUES ('Romina', 'Ramirez', 31222333, 'r.ramirez@alu.unne.edu.ar', HASHBYTES('SHA2_512', 'UserPass123!'), 'Estudiante');
    SET @idEstudianteValido2 = SCOPE_IDENTITY();

    -- Estudiante 3 (VÁLIDO, Apellido con 'C'. Quiere cambiar de A->B)
    INSERT INTO Usuario (nombre, apellido, documento, correo, contrasena, rol)
    VALUES ('Carla', 'Cáceres', 32333444, 'c.caceres@alu.unne.edu.ar', HASHBYTES('SHA2_512', 'UserPass123!'), 'Estudiante');
    SET @idEstudianteValido3 = SCOPE_IDENTITY();

    -- Estudiante 4 (VÁLIDO, Apellido con 'S'. Quiere cambiar de B->A)
    INSERT INTO Usuario (nombre, apellido, documento, correo, contrasena, rol)
    VALUES ('Sergio', 'Sosa', 33444555, 's.sosa@alu.unne.edu.ar', HASHBYTES('SHA2_512', 'UserPass123!'), 'Estudiante');
    SET @idEstudianteValido4 = SCOPE_IDENTITY();

    PRINT 'Cargando Estudiantes (inválidos)...';
    -- Estudiante 5 (INVÁLIDO - Constancia Vencida)
    INSERT INTO Usuario (nombre, apellido, documento, correo, contrasena, rol)
    VALUES ('Ines', 'Ibañez', 34555666, 'i.ibañez@alu.unne.edu.ar', HASHBYTES('SHA2_512', 'UserPass123!'), 'Estudiante');
    SET @idEstudianteInvalido = SCOPE_IDENTITY();

    -- Estudiante 6 (VÁLIDO, pero para ser bloqueado por rechazos)
    INSERT INTO Usuario (nombre, apellido, documento, correo, contrasena, rol)
    VALUES ('Bruno', 'Benitez', 35666777, 'b.benitez@alu.unne.edu.ar', HASHBYTES('SHA2_512', 'UserPass123!'), 'Estudiante');
    SET @idEstudianteBloqueado = SCOPE_IDENTITY();

    
    -- 4.4. Carga de Constancias (Esto dispara el TRIGGER de HABILITACIÓN)
    PRINT 'Cargando constancias (dispara TR_Estudiante_Verificar)...';
    
    DECLARE @fechaHoy DATE = GETDATE();
    DECLARE @fechaValida DATE = DATEADD(DAY, -30, @fechaHoy);  -- Constancia de hace 1 mes (válida)
    DECLARE @fechaVencida DATE = DATEADD(MONTH, -7, @fechaHoy); -- Constancia de hace 7 meses (vencida)

    INSERT INTO Estudiante (id_estudiante, constancia_url, fecha_constancia)
    VALUES (@idEstudianteValido1, 'constancias/ggonzalez.pdf', @fechaValida),
           (@idEstudianteValido2, 'constancias/rramirez.pdf', @fechaValida),
           (@idEstudianteValido3, 'constancias/ccaceres.pdf', @fechaValida),
           (@idEstudianteValido4, 'constancias/ssosa.pdf', @fechaValida),
           (@idEstudianteInvalido, 'constancias/iibañez.pdf', @fechaVencida), -- INVÁLIDO
           (@idEstudianteBloqueado, 'constancias/bbenitez.pdf', @fechaValida);

    PRINT '--> Se deben haber disparado los triggers de habilitación/notificación.';
    
    /****************************************************************************************
    * 5. ACCIONES DEL SISTEMA (INSCRIPCIONES)
    ****************************************************************************************/
    PRINT 'Cargando: 5. Inscripciones...';
    
    -- Inscribimos a los estudiantes VÁLIDOS.
    -- Esto debe disparar el TRIGGER tr_inscripcion_validar_letra_apellido
    
    -- Estudiante 1 ('G' en Com A [A-M]) -> OK
    INSERT INTO Inscripcion (id_comision, id_estudiante)
    VALUES (@idComision_BD1_A, @idEstudianteValido1);
    
    -- Estudiante 2 ('R' en Com B [N-Z]) -> OK
    INSERT INTO Inscripcion (id_comision, id_estudiante)
    VALUES (@idComision_BD1_B, @idEstudianteValido2);
    
    -- Estudiante 3 ('C' en Com A [A-M]) -> OK
    INSERT INTO Inscripcion (id_comision, id_estudiante)
    VALUES (@idComision_BD1_A, @idEstudianteValido3);

    -- Estudiante 4 ('S' en Com B [N-Z]) -> OK
    INSERT INTO Inscripcion (id_comision, id_estudiante)
    VALUES (@idComision_BD1_B, @idEstudianteValido4);

    -- (Opcional) Prueba de Falla de Trigger de Apellido:
    -- Descomentar la línea de abajo para probar que el trigger falla
    -- PRINT '--> Probando falla de trigger de apellido (debe fallar y hacer ROLLBACK)...';
    -- INSERT INTO Inscripcion (id_comision, id_estudiante) VALUES (@idComision_BD1_A, @idEstudianteValido2); -- Falla (Ramirez 'R' no va en Com A)
    
    PRINT '--> Se deben haber disparado los triggers de validación de apellido.';
    
    /****************************************************************************************
    * 6. ESCENARIO DE PRUEBA (LISTA DE ESPERA Y MATCHES)
    ****************************************************************************************/
    PRINT 'Cargando: 6. Escenario de Prueba (Lista de Espera)...';
    PRINT '--> Esto disparará TR_ListaEspera_TryMatchOnInsert y creará Propuestas automáticamente.';

    -- Escenario 1: Match Perfecto (e1 vs e2)
    -- e1 (Gonzalez, Com A) quiere ir a Com B
    INSERT INTO Lista_Espera (estado, id_estudiante, id_comision_origen, id_comision_destino)
    VALUES ('En espera', @idEstudianteValido1, @idComision_BD1_A, @idComision_BD1_B);
    
    -- e2 (Ramirez, Com B) quiere ir a Com A
    INSERT INTO Lista_Espera (estado, id_estudiante, id_comision_origen, id_comision_destino)
    VALUES ('En espera', @idEstudianteValido2, @idComision_BD1_B, @idComision_BD1_A);

    -- Escenario 2: Match Perfecto (e3 vs e4)
    -- e3 (Caceres, Com A) quiere ir a Com B
    INSERT INTO Lista_Espera (estado, id_estudiante, id_comision_origen, id_comision_destino)
    VALUES ('En espera', @idEstudianteValido3, @idComision_BD1_A, @idComision_BD1_B);

    -- e4 (Sosa, Com B) quiere ir a Com A
    INSERT INTO Lista_Espera (estado, id_estudiante, id_comision_origen, id_comision_destino)
    VALUES ('En espera', @idEstudianteValido4, @idComision_BD1_B, @idComision_BD1_A);
    
    -- Escenario 3: Estudiante solo en la cola (sin match)
    -- e6 (Benitez, Com A) quiere ir a Com B (quedará 'En espera')
    INSERT INTO Lista_Espera (estado, id_estudiante, id_comision_origen, id_comision_destino)
    VALUES ('En espera', @idEstudianteBloqueado, @idComision_BD1_A, @idComision_BD1_B);

    PRINT '--> ¡Triggers de Matchmaking ejecutados!';
    
    -- Fin de la transacción
    COMMIT TRAN CargaDatos;
    
    PRINT '';
    PRINT '==================================================';
    PRINT '¡LOTE DE CARGA FINALIZADO EXITOSAMENTE!';
    PRINT '==================================================';

    -- Verificación final (¡La prueba de que funcionó!)
    PRINT 'Estado final de la Tabla de Propuestas:';
    SELECT id_propuesta, 
           estado, 
           id_listaEspera_1, 
           id_listaEspera_2
    FROM Propuesta
    WHERE estado = 'Pendiente';
    
    PRINT 'Estado final de la Lista de Espera:';
    SELECT id_lista_espera,
           estado,
           id_estudiante,
           id_comision_origen,
           id_comision_destino
    FROM Lista_Espera
    ORDER BY estado, fecha_alta;

END TRY
BEGIN CATCH
    -- Si algo falló, deshace todo
    IF @@TRANCOUNT > 0
    BEGIN
        ROLLBACK TRAN CargaDatos;
    END

    PRINT '';
    PRINT '==================================================';
    PRINT '¡ERROR! El lote de carga falló. Se revirtió la transacción.';
    PRINT '==================================================';
    PRINT 'Error: ' + ERROR_MESSAGE();
    PRINT 'Línea: ' + CAST(ERROR_LINE() AS VARCHAR);
    PRINT GETDATE();
END CATCH
GO