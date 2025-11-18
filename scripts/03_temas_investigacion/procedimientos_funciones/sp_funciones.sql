/*********************************************
TEMA 1: PROCEDIMIENTOS Y FUNCIONES ALMACENADAS
PROYECTO: SIC - UNNE
*********************************************/


----------------------------------------------
-----------BLOQUE 1: PROCEDIMIENTOS-----------
----------------------------------------------

-- USUARIO --

-- 1) Insertar Usuario - Estudiante (con Constancia y carrera, rol 'Estudiante' y estado = 0)

IF OBJECT_ID('sp_insertar_estudiante', 'P') IS NOT NULL
    DROP PROCEDURE sp_insertar_estudiante;
GO

CREATE PROCEDURE sp_insertar_estudiante
    @nombre NVARCHAR(100),
    @apellido NVARCHAR(100),
    @documento INT,
    @correo NVARCHAR(100),
    @contrasena NVARCHAR(100),
    @id_carrera INT,
    @constancia_url NVARCHAR(255),
    @fecha_constancia DATETIME,
    @newId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @hash VARBINARY(32);

    BEGIN TRY
        BEGIN TRAN;

        -- VALIDACIONES
        IF EXISTS (SELECT 1 FROM Usuario WHERE documento = @documento)
        BEGIN
            RAISERROR('Documento ya registrado.', 16, 1);
            ROLLBACK TRAN; RETURN;
        END

        IF EXISTS (SELECT 1 FROM Usuario WHERE correo = @correo)
        BEGIN
            RAISERROR('Correo ya registrado.', 16, 1);
            ROLLBACK TRAN; RETURN;
        END

        IF NOT EXISTS (SELECT 1 FROM Carrera WHERE id_carrera = @id_carrera)
        BEGIN
            RAISERROR('Carrera no encontrada.', 16, 1);
            ROLLBACK TRAN; RETURN;
        END

        -- HASH DE CONTRASEÑA
        SET @hash = HASHBYTES('SHA2_512', @contrasena);

        -- INSERTAR USUARIO
        INSERT INTO Usuario (nombre, apellido, documento, correo, contrasena, estado, rol, id_carrera)
        VALUES (@nombre, @apellido, @documento, @correo, @hash, 0, 'Estudiante', @id_carrera);

        SET @newId = SCOPE_IDENTITY();

        -- INSERTAR CONSTANCIA SOLO SI NO ES NULL
        IF @constancia_url IS NOT NULL AND @fecha_constancia IS NOT NULL
        BEGIN
            INSERT INTO Constancia (id_constancia, constancia_url, fecha_constancia)
            VALUES (@newId, @constancia_url, @fecha_constancia);

            
            PRINT 'Estudiante registrado con constancia.';
        END
        ELSE
        BEGIN
            PRINT 'Estudiante registrado sin constancia.';
        END

        -- FIN
        COMMIT TRAN;
        PRINT 'Registro completado exitosamente.';

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 
            ROLLBACK TRAN;

        -- Propaga el error original
        THROW;
    END CATCH
END
GO



-- 2) Insertar Usuario - Personal Administrativo (rol 'Indefinido', estado 0)

IF OBJECT_ID('sp_insertar_personal', 'P') IS NOT NULL
    DROP PROCEDURE sp_insertar_personal;
GO

CREATE PROCEDURE sp_insertar_personal
    @nombre NVARCHAR(100),
    @apellido NVARCHAR(100),
    @documento INT,
    @correo NVARCHAR(100),
    @contrasena NVARCHAR(100),   -- texto plano, se hashea
    @newId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @hash VARBINARY(32);

    PRINT 'Iniciando inserción de personal...';

    BEGIN TRY
        BEGIN TRAN;

        PRINT 'Validando documento...';
        IF EXISTS (SELECT 1 FROM Usuario WHERE documento = @documento)
        BEGIN
            PRINT 'Error: documento ya registrado.';
            RAISERROR('Documento ya registrado.', 16, 1);
            ROLLBACK TRAN; RETURN;
        END

        PRINT 'Validando correo...';
        IF EXISTS (SELECT 1 FROM Usuario WHERE correo = @correo)
        BEGIN
            PRINT 'Error: correo ya registrado.';
            RAISERROR('Correo ya registrado.', 16, 1);
            ROLLBACK TRAN; RETURN;
        END

        PRINT 'Generando hash de contraseña...';
        SET @hash = HASHBYTES('SHA2_512', @contrasena);

        PRINT 'Insertando usuario con rol Indefinido...';
        INSERT INTO Usuario (nombre, apellido, documento, correo, contrasena, estado, rol, id_carrera)
        VALUES (@nombre, @apellido, @documento, @correo, @hash, 0, 'Indefinido', NULL);

        SET @newId = SCOPE_IDENTITY();
        PRINT 'Usuario insertado. Nuevo ID: ' + CAST(@newId AS NVARCHAR(20));

        COMMIT TRAN;

        PRINT 'Inserción completada correctamente.';

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 
        BEGIN
            PRINT 'Ocurrió un error. Realizando rollback...';
            ROLLBACK TRAN;
        END

        PRINT 'Error propagado: ' + ERROR_MESSAGE();
        THROW;  -- Propaga el error real del sistema
    END CATCH
END
GO




-- 3) Actualizar datos básicos de Usuario (nombre, apellido, correo, documento, contraseña)

IF OBJECT_ID('sp_actualizar_usuario', 'P') IS NOT NULL
    DROP PROCEDURE sp_actualizar_usuario;
GO

CREATE PROCEDURE sp_actualizar_usuario
    @id_usuario INT,
    @nombre NVARCHAR(100) = NULL,
    @apellido NVARCHAR(100) = NULL,
    @documento INT = NULL,
    @correo NVARCHAR(100) = NULL,
    @contrasena_actual NVARCHAR(100) = NULL,
    @contrasena_nueva NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    PRINT 'Inicio SP: sp_actualizar_usuario';
    PRINT 'ID usuario: ' + CAST(@id_usuario AS NVARCHAR);

    DECLARE @actual_nombre NVARCHAR(100),
            @actual_apellido NVARCHAR(100),
            @actual_documento INT,
            @actual_correo NVARCHAR(100),
            @actual_contrasena VARBINARY(32);

    DECLARE @hash_actual VARBINARY(32),
            @hash_nueva VARBINARY(32);

    IF @contrasena_actual IS NOT NULL
    BEGIN
        PRINT 'Calculando hash de la contraseña actual...';
        SET @hash_actual = HASHBYTES('SHA2_512', @contrasena_actual);
    END

    IF @contrasena_nueva IS NOT NULL
    BEGIN
        PRINT 'Calculando hash de la nueva contraseña...';
        SET @hash_nueva = HASHBYTES('SHA2_512', @contrasena_nueva);
    END

    BEGIN TRY
        BEGIN TRAN;
        PRINT 'Transacción iniciada.';

        -- Verificar existencia del usuario
        IF NOT EXISTS (SELECT 1 FROM Usuario WHERE id_usuario = @id_usuario)
        BEGIN
            PRINT 'ERROR: El usuario no existe.';
            ROLLBACK TRAN;
            RETURN;
        END
        PRINT 'Usuario encontrado.';

        -- Obtener datos actuales
        PRINT 'Obteniendo datos actuales del usuario...';
        SELECT @actual_nombre = nombre,
               @actual_apellido = apellido,
               @actual_documento = documento,
               @actual_correo = correo,
               @actual_contrasena = contrasena
        FROM Usuario
        WHERE id_usuario = @id_usuario;

        -- Validar documento duplicado
        IF @documento IS NOT NULL AND @documento <> @actual_documento
        BEGIN
            PRINT 'Validando posible duplicado de documento...';
            IF EXISTS (SELECT 1 FROM Usuario 
                       WHERE documento = @documento 
                         AND id_usuario <> @id_usuario)
            BEGIN
                PRINT 'ERROR: Documento duplicado.';
                ROLLBACK TRAN;
                RETURN;
            END
        END

        -- Validar correo duplicado
        IF @correo IS NOT NULL AND @correo <> @actual_correo
        BEGIN
            PRINT 'Validando posible duplicado de correo...';
            IF EXISTS (SELECT 1 FROM Usuario 
                       WHERE correo = @correo 
                         AND id_usuario <> @id_usuario)
            BEGIN
                PRINT 'ERROR: Correo duplicado.';
                ROLLBACK TRAN;
                RETURN;
            END
        END

        -- Validar contraseña actual
        IF @contrasena_nueva IS NOT NULL
        BEGIN
            PRINT 'Validando contraseña actual...';
            IF @hash_actual IS NULL OR @hash_actual <> @actual_contrasena
            BEGIN
                PRINT 'ERROR: Contraseña actual incorrecta.';
                ROLLBACK TRAN;
                RETURN;
            END
        END

        -- Detectar si no hay cambios
        PRINT 'Verificando si hay cambios...';
        IF (
            (@nombre IS NULL OR @nombre = @actual_nombre) AND
            (@apellido IS NULL OR @apellido = @actual_apellido) AND
            (@documento IS NULL OR @documento = @actual_documento) AND
            (@correo IS NULL OR @correo = @actual_correo) AND
            (@contrasena_nueva IS NULL)
        )
        BEGIN
            PRINT 'No se detectaron cambios. Cancelando actualización.';
            ROLLBACK TRAN;
            RETURN;
        END

        -- Actualizar SOLO los campos modificados
        PRINT 'Actualizando datos del usuario...';
        UPDATE Usuario
        SET nombre     = COALESCE(@nombre, nombre),
            apellido   = COALESCE(@apellido, apellido),
            documento  = COALESCE(@documento, documento),
            correo     = COALESCE(@correo, correo),
            contrasena = CASE WHEN @contrasena_nueva IS NOT NULL 
                              THEN @hash_nueva 
                              ELSE contrasena END
        WHERE id_usuario = @id_usuario;

        PRINT 'Actualización realizada correctamente.';

        COMMIT TRAN;
        PRINT 'Transacción finalizada con éxito.';
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 
        BEGIN
            PRINT 'ERROR en CATCH, haciendo ROLLBACK.';
            ROLLBACK TRAN;
        END
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH
END
GO



-- 4) Actualizar Estado (administrador solo cambia a verificador y verificador solo cambia a estudiante, 
-- estudiante puede cambiarse a si mismo de 1 a 0)

IF OBJECT_ID('sp_actualizar_estado', 'P') IS NOT NULL
    DROP PROCEDURE sp_actualizar_estado;
GO

CREATE PROCEDURE sp_actualizar_estado
    @id_actor INT,       -- usuario que realiza la acción
    @id_usuario INT,     -- usuario cuyo estado se va a cambiar
    @newEstado BIT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE 
        @rol_actor NVARCHAR(30),
        @rol_objetivo NVARCHAR(30),
        @estado_actual BIT;

    BEGIN TRY
        BEGIN TRAN;

        PRINT 'Inicio SP: sp_actualizar_estado';

        -- Validar existencia del actor
        IF NOT EXISTS (SELECT 1 FROM Usuario WHERE id_usuario = @id_actor)
        BEGIN
            PRINT 'ERROR: El actor no existe.';
            ROLLBACK TRAN; RETURN;
        END

        -- Validar existencia del usuario objetivo
        IF NOT EXISTS (SELECT 1 FROM Usuario WHERE id_usuario = @id_usuario)
        BEGIN
            PRINT 'ERROR: El usuario objetivo no existe.';
            ROLLBACK TRAN; RETURN;
        END

        -- Obtener roles y estado actual
        SELECT @rol_actor = rol 
        FROM Usuario 
        WHERE id_usuario = @id_actor;

        SELECT 
            @rol_objetivo = rol, 
            @estado_actual = estado
        FROM Usuario
        WHERE id_usuario = @id_usuario;

        PRINT 'Rol actor: ' + @rol_actor +
              ' | Rol objetivo: ' + @rol_objetivo +
              ' | Estado actual: ' + CAST(@estado_actual AS NVARCHAR);


        -- REGLAS DE NEGOCIO

        -- 1) Estudiante: solo puede desactivarse 1 → 0 a sí mismo
        IF @rol_actor = 'Estudiante'
        BEGIN
            IF @id_actor <> @id_usuario
            BEGIN
                PRINT 'Regla fallida: un estudiante no puede modificar a otro usuario.';
                ROLLBACK TRAN; RETURN;
            END

            IF NOT (@estado_actual = 1 AND @newEstado = 0)
            BEGIN
                PRINT 'Regla fallida: estudiante solo puede desactivarse (1 → 0).';
                ROLLBACK TRAN; RETURN;
            END
        END

        -- 2) Verificador: solo modifica estudiantes
        IF @rol_actor = 'Verificador'
        BEGIN
            IF @rol_objetivo <> 'Estudiante'
            BEGIN
                PRINT 'Regla fallida: verificador solo puede modificar estudiantes.';
                ROLLBACK TRAN; RETURN;
            END
        END

        -- 3) Administrador: modifica verificadores y estudiantes
        IF @rol_actor = 'Administrador'
        BEGIN
            IF @rol_objetivo NOT IN ('Verificador', 'Estudiante')
            BEGIN
                PRINT 'Regla fallida: administrador solo puede modificar verificadores y estudiantes.';
                ROLLBACK TRAN; RETURN;
            END
        END


        --  Activar estudiante requiere constancia
        IF @newEstado = 1 AND @rol_objetivo = 'Estudiante'
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM Constancia WHERE id_constancia = @id_usuario)
            BEGIN
                PRINT 'Regla fallida: para activar un estudiante se requiere constancia.';
                ROLLBACK TRAN; RETURN;
            END
        END


        --  ACTUALIZAR
        UPDATE Usuario
        SET estado = @newEstado
        WHERE id_usuario = @id_usuario;

        PRINT 'Estado actualizado correctamente.';

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 
            ROLLBACK TRAN;

        PRINT 'Error: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END
GO




-- 5) Actualizar rol

IF OBJECT_ID('sp_actualizar_rol', 'P') IS NOT NULL
    DROP PROCEDURE sp_actualizar_rol;
GO

CREATE PROCEDURE sp_actualizar_rol
    @id_usuario INT,     -- usuario cuyo rol será modificado
    @newRole NVARCHAR(30),
    @id_actor INT        -- usuario que realiza la acción
AS
BEGIN
    SET NOCOUNT ON;

    PRINT 'Inicio SP: sp_actualizar_rol';
    PRINT 'Actor: ' + CAST(@id_actor AS NVARCHAR) +
          ' | Usuario objetivo: ' + CAST(@id_usuario AS NVARCHAR) +
          ' | Nuevo rol: ' + @newRole;

    -- Validar existencia de usuarios
    IF NOT EXISTS (SELECT 1 FROM Usuario WHERE id_usuario = @id_usuario)
    BEGIN
        PRINT 'ERROR: Usuario objetivo no existe.';
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Usuario WHERE id_usuario = @id_actor)
    BEGIN
        PRINT 'ERROR: Actor no existe.';
        RETURN;
    END

    -- Obtener roles actuales
    DECLARE @actorRol NVARCHAR(30);
    DECLARE @targetRol NVARCHAR(30);

    SELECT @actorRol = rol FROM Usuario WHERE id_usuario = @id_actor;
    SELECT @targetRol = rol FROM Usuario WHERE id_usuario = @id_usuario;

    PRINT 'Rol actor: ' + @actorRol + 
          ' | Rol objetivo actual: ' + @targetRol;

    -- Restricción: solo ciertos roles permitidos
    IF @newRole NOT IN ('Administrador','Verificador','Estudiante','Indefinido')
    BEGIN
        PRINT 'ERROR: Rol nuevo no permitido.';
        RETURN;
    END

    -- Datos del usuario objetivo
    DECLARE @tieneCarrera BIT = 0;
    DECLARE @tieneConstancia BIT = 0;

    PRINT 'Verificando carrera y constancia...';

    IF EXISTS (SELECT 1 FROM Usuario WHERE id_usuario = @id_usuario AND id_carrera IS NOT NULL)
    BEGIN
        SET @tieneCarrera = 1;
        PRINT 'Usuario objetivo TIENE carrera.';
    END
    ELSE PRINT 'Usuario objetivo NO tiene carrera.';

    IF EXISTS (SELECT 1 FROM Constancia WHERE id_constancia = @id_usuario)
    BEGIN
        SET @tieneConstancia = 1;
        PRINT 'Usuario objetivo TIENE constancia.';
    END
    ELSE PRINT 'Usuario objetivo NO tiene constancia.';

    -- REGLAS DE NEGOCIO

    -- ADMIN solo modifica verificadores SIN carrera NI constancia
    IF @actorRol = 'Administrador'
    BEGIN
        PRINT 'Validando reglas para ADMIN...';

        IF @targetRol = 'Verificador' AND @tieneCarrera = 0 AND @tieneConstancia = 0
        BEGIN
            PRINT 'Regla cumplida: ADMIN puede modificar a este Verificador.';
            PRINT 'Actualizando rol...';

            UPDATE Usuario
            SET rol = @newRole
            WHERE id_usuario = @id_usuario;

            PRINT 'Rol actualizado correctamente.';
            RETURN;
        END
        ELSE
        BEGIN
            PRINT 'Regla fallida: ADMIN NO puede modificar este usuario.';
            RETURN;
        END
    END

    -- VERIFICADOR modifica SOLO estudiantes CON carrera
    IF @actorRol = 'Verificador'
    BEGIN
        PRINT 'Validando reglas para VERIFICADOR...';

        IF @targetRol = 'Estudiante' AND @tieneCarrera = 1
        BEGIN
            PRINT 'Regla cumplida: Verificador puede modificar a este Estudiante.';
            PRINT 'Actualizando rol...';

            UPDATE Usuario
            SET rol = @newRole
            WHERE id_usuario = @id_usuario;

            PRINT 'Rol actualizado correctamente.';
            RETURN;
        END
        ELSE
        BEGIN
            PRINT 'Regla fallida: Verificador NO puede modificar este usuario.';
            RETURN;
        END
    END

    -- OTROS ROLES: no pueden modificar nada
    PRINT 'Ninguna regla permite que este actor modifique roles.';
    RETURN;
END
GO


-- 6) Activar verificador (cambia estado de 0 a 1 y de 'Indefinido' a 'Verificador')

CREATE OR ALTER PROCEDURE sp_activar_verificador
    @id_usuario INT,    -- Usuario al que se le cambiará el rol
    @id_admin INT       -- Usuario que realiza la acción (debe ser admin)
AS
BEGIN
    SET NOCOUNT ON;

    PRINT 'Inicio SP: sp_activar_verificador';
    PRINT 'Admin ejecutor: ' + CAST(@id_admin AS NVARCHAR);
    PRINT 'Usuario objetivo: ' + CAST(@id_usuario AS NVARCHAR);

    -- Verificar que el emisor sea administrador
    IF NOT EXISTS (
        SELECT 1
        FROM Usuario
        WHERE id_usuario = @id_admin
          AND rol = 'Administrador'
    )
    BEGIN
        PRINT 'ERROR: El usuario ejecutor NO es administrador.';
        RETURN;  -- No es admin → no hace nada
    END
    ELSE
        PRINT 'Validación OK: El ejecutor es Administrador.';

    PRINT 'Verificando que el usuario NO tenga carrera NI constancia...';

    -- Validar que el usuario NO tenga carrera y NO tenga constancia
    IF EXISTS (
        SELECT 1
        FROM Usuario u
        WHERE u.id_usuario = @id_usuario
          AND u.id_carrera IS NULL
          AND NOT EXISTS (
                SELECT 1
                FROM Constancia c
                WHERE c.id_constancia = u.id_usuario
          )
    )
    BEGIN
        PRINT 'Regla OK: Usuario SIN carrera y SIN constancia. Activando Verificador...';

        UPDATE Usuario
        SET rol = 'Verificador',
            estado = 1
        WHERE id_usuario = @id_usuario;

        PRINT 'Actualización realizada: rol = Verificador, estado = 1.';
    END
    ELSE
    BEGIN
        PRINT 'Regla NO cumplida: El usuario tiene carrera o constancia. No se modifica nada.';
    END
END;
GO



-- INSERTS DIRECTOS --

-- Administrador 
INSERT INTO Usuario (nombre, apellido, documento, correo, contrasena, rol, estado)
VALUES ('Marcos', 'Gómez', 10000001, 'admin@sicunne.edu.ar', HASHBYTES('SHA2_512','1234'), 'Administrador', 1);

-- Verificadores
INSERT INTO Usuario (nombre, apellido, documento, correo, contrasena, rol, estado) VALUES
('Lucía', 'Pérez', 20000001, 'lperez@sicunne.edu.ar', HASHBYTES('SHA2_512','1234'),'Verificador',1),
('Javier', 'Suárez', 20000002, 'jsuarez@sicunne.edu.ar', HASHBYTES('SHA2_512','1234'),'Indefinido',0),


-- Estudiantes
INSERT INTO Usuario (nombre, apellido, documento, correo, contrasena, rol, estado, id_carrera) VALUES
('Ana','Torres',30000001,'ana.torres@email.com',HASHBYTES('SHA2_512','1234'),'Estudiante',0, 3),
('Bruno','Martínez',30000002,'bruno.m@email.com',HASHBYTES('SHA2_512','1234'),'Estudiante',0, 2),
('Carla','Funes',30000003,'carla.f@email.com',HASHBYTES('SHA2_512','1234'),'Estudiante',0, 1),


-- Constancia para estudiante activo
INSERT INTO Constancia (id_constancia, constancia_url, fecha_constancia) VALUES
(9, 'docs/constancias/ana.pdf', GETDATE()),

-- Cambiamos el estado de Ana Torres a activo (1)
UPDATE Usuario SET estado = 1 WHERE documento = 30000001;



-- INSERTS MEDIANTE PROCEDIMIENTOS --

-- Administrador
DECLARE @admin3 INT;
EXEC sp_insertar_personal 'Lucia','Reyes',40909222,'admin3@sicunne.edu.ar', 'admin123', @admin3 OUTPUT;

-- Verificadores
DECLARE @ver4 INT, @ver5 INT, @ver6 INT;
EXEC sp_insertar_personal 'Tomas', 'Saucedo', 20008001, 'tsaucedo@sicunne.edu.ar', 'ver123', @ver4 OUTPUT;
EXEC sp_insertar_personal 'Martin', 'Hernandez', 20000002, 'martinh@sicunne.edu.ar', 'ver234', @ver5 OUTPUT;
EXEC sp_insertar_personal 'Adrian', 'Lopez', 33009283, 'adrianl@gmail.com', 'ver345', @ver6 OUTPUT;



-- Estudiantes
DECLARE @est7 INT, @est8 INT, @est9 INT;
EXEC sp_insertar_estudiante 'Claudia','Morales',30000001,'moralesc@email.com','est123', 1, NULL, NULL, @est7 OUTPUT;
EXEC sp_insertar_estudiante 'Ramiro','Centella',30000002,'ramiroc.m@email.com','est234', 1, 'docs/constancias/ramiro.pdf', GETDATE(), @est8 OUTPUT;
EXEC sp_insertar_estudiante 'Mia','Soto',30000003,'mia.s@email.com','est345', 1, NULL, NULL, @est9 OUTPUT;



-- UPDATE Y DELETE MEDIANTE PROCEDIMIENTOS --

-- Activar Admin
-- Hacemos que Marcos Gomez active a Lucia Reyes
EXEC sp_actualizar_rol @admin3, 'Administrador', @admin2;
EXEC sp_actualizar_estado @id_actor = 1, @admin3, 1;

-- Activar Verificador 
-- Hacemos que el admin Lucia Reyes active a Tomas Saucedo y a Adrian Lopez
EXEC sp_activar_verificador @ver4, @admin3;
EXEC sp_activar_verificador @ver6, @admin3;


-- Actualizar Estado
-- Hacemos que Tomas Saucedo active a Ramiro Centella (presento constancia)
EXEC sp_actualizar_estado @ver4, @est8, 1;


-- Actualizar Usuario
-- Cambiamos los datos de Tomas Saucedo
EXEC sp_actualizar_usuario @id_usuario = @ver4, @nombre = 'Juan Tomas', @correo = 'jtsaucedo@gmail.com';


-- Desactivar Usuario
-- Desactivamos a Adrian Lopez
EXEC sp_actualizar_estado @admin2, @ver6, 0;





----------------------------------------------
-------------BLOQUE 2: FUNCIONES--------------
----------------------------------------------

-- Calcular edad

IF OBJECT_ID('fn_calcularEdad', 'FN') IS NOT NULL
    DROP FUNCTION fn_calcularEdad;
GO

CREATE FUNCTION fn_calcularEdad (
    @fechaNacimiento DATE
)
RETURNS INT
AS
BEGIN
    DECLARE @edad INT;

    SET @edad = DATEDIFF(YEAR, @fechaNacimiento, GETDATE());

    -- Ajuste si no cumplió años aún
    IF (MONTH(@fechaNacimiento) > MONTH(GETDATE()))
        OR (MONTH(@fechaNacimiento) = MONTH(GETDATE()) AND DAY(@fechaNacimiento) > DAY(GETDATE()))
        SET @edad = @edad - 1;

    RETURN @edad;
END;
GO


-- Concatenar Nombre y Apellido

IF OBJECT_ID('fn_formatoNombre', 'FN') IS NOT NULL
    DROP FUNCTION fn_formatoNombre;
GO

CREATE FUNCTION fn_formatoNombre (
    @nombre NVARCHAR(100),
    @apellido NVARCHAR(100)
)
RETURNS NVARCHAR(210)
AS
BEGIN
    DECLARE @resultado NVARCHAR(210);

    SET @resultado = CONCAT(
        UPPER(LEFT(@apellido,1)),
        LOWER(SUBSTRING(@apellido,2,LEN(@apellido))),
        ', ',
        UPPER(LEFT(@nombre,1)),
        LOWER(SUBSTRING(@nombre,2,LEN(@nombre)))
    );

    RETURN @resultado;
END;
GO


-- Estudiante con constancia

IF OBJECT_ID('fn_tieneConstancia', 'FN') IS NOT NULL
    DROP FUNCTION fn_tieneConstancia;
GO

CREATE FUNCTION fn_tieneConstancia (
    @id_usuario INT
)
RETURNS BIT
AS
BEGIN
    DECLARE @resultado BIT = 0;

    IF EXISTS (SELECT 1 FROM Constancia WHERE id_constancia = @id_usuario)
        SET @resultado = 1;

    RETURN @resultado;
END;
GO


