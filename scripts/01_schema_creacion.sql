/****************************************************************************************
* PROYECTO:         SIC-UNNE (Bases de Datos I)
* AUTOR:            [Grupo 9]
* FECHA:            [05/11/2025]
* DESCRIPCIÓN:
* Script SQL para el sistema SIC.
****************************************************************************************/

CREATE DATABASE SIC_UNNE;
GO
USE SIC_UNNE;
GO

-- Usuario
CREATE TABLE Usuario (
    id_usuario INT IDENTITY 
        CONSTRAINT pk_id_usuario PRIMARY KEY,
    nombre NVARCHAR (100) NOT NULL,
    apellido NVARCHAR (100) NOT NULL,
    documento INT NOT NULL,
    correo NVARCHAR (100) NOT NULL,
    contrasena NVARCHAR (50) NOT NULL,
    estado BIT DEFAULT 1,
    rol NVARCHAR (30) NOT NULL
)

-- Restricciones para Usuario

ALTER TABLE Usuario
ADD 
    -- Documento y Correo deben ser únicos
    CONSTRAINT uq_usuario_documento UNIQUE (documento),
    CONSTRAINT uq_usuario_correo UNIQUE (correo),

    CONSTRAINT ck_usuario_rol CHECK (rol IN ('Administrador', 'Estudiante', 'Verificador')),

    -- Documento debe tener entre 6 y 8 dígitos
    CONSTRAINT ck_usuario_documento CHECK (
        LEN(CAST(documento AS NVARCHAR(10))) BETWEEN 6 AND 8
    ),

    -- Nombre y apellido: solo letras y más de 8 caracteres
    CONSTRAINT ck_usuario_nombre CHECK (
        nombre NOT LIKE '%[^A-Za-zÁÉÍÓÚáéíóúÑñ ]%' AND LEN(nombre) > 3
    ),
    CONSTRAINT ck_usuario_apellido CHECK (
        apellido NOT LIKE '%[^A-Za-zÁÉÍÓÚáéíóúÑñ ]%'
    ),

    -- Correo con formato válido (simplificado)
    CONSTRAINT ck_usuario_correo CHECK (
        correo LIKE '_%@_%._%'
    ),

    -- Contraseña mínimo 8 caracteres
    CONSTRAINT ck_usuario_contrasena CHECK (
        LEN(contrasena) >= 8
    ),

    -- Estado solo puede ser 1 o 0
    CONSTRAINT ck_usuario_estado CHECK (estado IN (0, 1));
GO

-- Tabla Profesor

CREATE TABLE Profesor (
    id_profesor INT
        CONSTRAINT pk_id_profesor PRIMARY KEY
        CONSTRAINT fk_profesor_usuario FOREIGN KEY REFERENCES Usuario(id_usuario)
    )
GO

-- Tabla Estudiante

CREATE TABLE Estudiante (
    id_estudiante INT
       CONSTRAINT pk_id_estudiante PRIMARY KEY
       CONSTRAINT fk_estudiante_usuario FOREIGN KEY REFERENCES Usuario(id_usuario),
    constancia_url NVARCHAR(200) NOT NULL,
    fecha_constancia DATE NOT NULL
)
GO

-- Restricciones para Estudiante

ALTER TABLE Estudiante 
ADD 

    -- Verifica que la fecha de constancia no sea futura y hasta 6 meses antes
    CONSTRAINT CK_Estudiante_FechaConstancia CHECK (
        fecha_constancia <= GETDATE()
        AND fecha_constancia >= DATEADD(MONTH, -6, GETDATE())
    ),

    -- Verifica que la URL tenga formato de archivo válido (simplificada)
    CONSTRAINT CK_Estudiante_UrlFormato CHECK (
        constancia_url LIKE '%.pdf' OR 
        constancia_url LIKE '%.jpg' OR 
        constancia_url LIKE '%.jpeg' OR 
        constancia_url LIKE '%.png'
    );
GO

-- Tabla Verificador

CREATE TABLE Verificador (
    id_verificador INT
       CONSTRAINT pk_id_verificador PRIMARY KEY
       CONSTRAINT fk_verificador_usuario FOREIGN KEY REFERENCES Usuario(id_usuario)
)
GO

-- Tabla Edificio

CREATE TABLE Edificio (
    id_edificio INT IDENTITY
        CONSTRAINT pk_id_edificio PRIMARY KEY,
    direccion NVARCHAR (250) NOT NULL,
    nombre NVARCHAR (200) NOT NULL
)
GO

-- Tabla Facultad

CREATE TABLE Facultad (
    id_facultad INT IDENTITY 
        CONSTRAINT pk_id_facultad PRIMARY KEY,
    nombre NVARCHAR (200) NOT NULL,
    ciudad NVARCHAR (200) NOT NULL,
    id_edificio INT NOT NULL
        CONSTRAINT fk_facultad_edificio FOREIGN KEY REFERENCES Edificio(id_edificio)
)
GO

-- Restricciones para Facultad

ALTER TABLE Facultad
ADD 
    -- Nombre debe ser único
    CONSTRAINT uq_facultad_nombre UNIQUE (nombre);
GO

-- Tabla Carrera

CREATE TABLE Carrera (
    id_carrera INT IDENTITY 
        CONSTRAINT pk_id_carrera PRIMARY KEY,
    nombre NVARCHAR (200) NOT NULL,
    id_facultad INT NOT NULL
        CONSTRAINT fk_carrera_facultad FOREIGN KEY REFERENCES Facultad(id_facultad)
)
GO

-- Restricciones para Carrera

ALTER TABLE Carrera
ADD 
    -- Nombre debe ser único
    CONSTRAINT uq_carrera_nombre UNIQUE (nombre),
    
    -- Nombre solo puede contener letras y debe ser mayor a 8 caracteres
    CONSTRAINT ck_carrera_nombre CHECK (
        nombre NOT LIKE '%[^A-Za-zÁÉÍÓÚáéíóúÑñ ]%' AND LEN(nombre) > 8
    );
GO

-- Tabla Periodo

CREATE TABLE Periodo (
    id_periodo INT IDENTITY 
        CONSTRAINT pk_id_periodo PRIMARY KEY,
    nombre NVARCHAR (50) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL
)
GO

-- Restricciones para Periodo

ALTER TABLE Periodo
ADD 
    -- Nombre solo puede tener los siguientes valores
    CONSTRAINT ck_periodo_nombre CHECK (
        nombre IN ('1er Cuatrimestre', '2do Cuatrimestre', '1er Trimestre', '2do Trimestre', '3er Trimestre', 'Anual', '1er Semestre', '2do Semestre')
    ),

    -- Fecha inicio debe ser mayor a fecha fin y viceversa
    CONSTRAINT ck_periodo_fechas CHECK (
        fecha_inicio < fecha_fin
    );
GO

-- Tabla Asignatura

CREATE TABLE Asignatura (
    id_asignatura INT IDENTITY 
        CONSTRAINT pk_id_asignatura PRIMARY KEY,
    nombre NVARCHAR (100) NOT NULL,
    anio_dictado NVARCHAR (100) NOT NULL,
    id_periodo INT NOT NULL
        CONSTRAINT fk_asignatura_periodo FOREIGN KEY REFERENCES Periodo(id_periodo)
)
GO

-- Restricciones para Asignatura

ALTER TABLE Asignatura
ADD
    -- Nombre único dentro del conjunto de asignaturas
    CONSTRAINT uq_asignatura_nombre UNIQUE (nombre),

    -- Solo permite letras, espacios y acentos en el nombre
    CONSTRAINT ck_asignatura_nombre CHECK (
        nombre NOT LIKE '%[^A-Za-zÁÉÍÓÚáéíóúÑñ ]%'
    ),

    -- El año dictado solo puede ser uno de los valores establecidos
    CONSTRAINT ck_asignatura_anio CHECK (
        anio_dictado IN ('Primer Año', 'Segundo Año', 'Tercer Año', 'Cuarto Año', 'Quinto Año', 'Sexto Año')
    );
GO

-- Tabla Comision

CREATE TABLE Comision (
    id_comision INT IDENTITY
        CONSTRAINT pk_id_comision PRIMARY KEY,
    nombre NVARCHAR (50) NOT NULL,
    letra_desde CHAR(1) NOT NULL,
    letra_hasta CHAR(1) NOT NULL,
    id_asignatura INT NOT NULL
        CONSTRAINT fk_comision_asignatura FOREIGN KEY REFERENCES Asignatura(id_asignatura)
)
GO

-- Restricciones para Comision

ALTER TABLE Comision
ADD
    -- Solo permite letras A–Z (sin acentos ni números)
    CONSTRAINT ck_comision_letrasValidas CHECK (
        letra_desde LIKE '[A-Z]' AND letra_hasta LIKE '[A-Z]'
    ),

    -- Verifica que la letra inicial esté antes que la final en el abecedario
    CONSTRAINT ck_comision_rangoLetras CHECK (
        ASCII(letra_desde) < ASCII(letra_hasta)
    );
GO

-- Tabla Aula

CREATE TABLE Aula (
    id_aula INT IDENTITY
        CONSTRAINT pk_id_aula PRIMARY KEY,
    nombre NVARCHAR (50) NOT NULL,
    id_edificio INT NOT NULL
        CONSTRAINT fk_aula_edificio FOREIGN KEY REFERENCES Edificio(id_edificio)
)
GO

-- Tabla Horario

CREATE TABLE Horario (
    id_horario INT IDENTITY
        CONSTRAINT pk_id_horario PRIMARY KEY,
    dia NVARCHAR (50) NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    modalidad NVARCHAR (50) NOT NULL
)
GO

-- Restricciones para Horario

ALTER TABLE Horario
ADD
    -- Dias de la semana
    CONSTRAINT ck_horario_dia CHECK (
        dia IN ('Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'Sabado')),

    -- Hora inicio debe ser antes que hora fin
    CONSTRAINT ck_horario_horas CHECK (hora_inicio < hora_fin),

    -- Modalidad solo puede tomar estos valores
    CONSTRAINT ck_horario_modalidad CHECK (
        modalidad IN  ('Presencial', 'Virtual', 'Asincronica', 'Sincronica', 'Mixta')
    );
GO

-- Tabla Horario_Comision

CREATE TABLE Horario_Comision (
    id_horario INT NOT NULL
        CONSTRAINT fk_horarioCom_horario FOREIGN KEY REFERENCES Horario(id_horario),
    id_comision INT NOT NULL
        CONSTRAINT fk_horarioCom_comision FOREIGN KEY REFERENCES Comision(id_comision),
    id_aula INT NOT NULL
        CONSTRAINT fk_horarioCom_aula FOREIGN KEY REFERENCES Aula(id_aula),
        CONSTRAINT pk_horario_comision PRIMARY KEY (id_horario, id_comision)    
);
GO

-- Tabla Inscripcion

CREATE TABLE Inscripcion (
    id_inscripcion INT IDENTITY
        CONSTRAINT pk_id_inscripcion PRIMARY KEY,
    fecha_alta DATE NOT NULL,
    estado BIT DEFAULT 1,
    fecha_baja DATE NULL,
    id_comision INT NOT NULL
        CONSTRAINT fk_inscripcion_comision FOREIGN KEY REFERENCES Comision(id_comision),
    id_estudiante INT NOT NULL
        CONSTRAINT fk_inscripcion_estudiante FOREIGN KEY REFERENCES Estudiante(id_estudiante)
)
GO

-- Restricciones para Inscripcion

ALTER TABLE Inscripcion
ADD 
    -- La fecha es definida cuando se genera la inscripcion
    CONSTRAINT df_inscripcion_fechaAlta
        DEFAULT (CAST(GETDATE() AS DATE)) FOR fecha_alta,
    
    -- La fecha de baja es null o si existe es mayor o igual a la fecha de inscripcion
    CONSTRAINT ck_inscripcion_fechas 
        CHECK (fecha_baja IS NULL OR fecha_baja >= fecha_alta),

    -- Coherencia: si el estado es activo (1) no puede tener fecha_baja; si la inscripcion es dada de baja (0) debe tener fecha_baja
    CONSTRAINT ck_inscripcion_coherenciaBaja
        CHECK ( (estado = 1 AND fecha_baja IS NULL) OR (estado = 0 AND fecha_baja IS NOT NULL) );
GO

-- Tabla Lista de Espera

CREATE TABLE Lista_Espera (
    id_lista_espera INT IDENTITY
        CONSTRAINT pk_id_lista_espera PRIMARY KEY,
    fecha_alta DATE NOT NULL,
    fecha_baja DATE NULL,
    estado NVARCHAR (50) NOT NULL,
    id_estudiante INT NOT NULL
        CONSTRAINT fk_listaEspera_estudiante FOREIGN KEY REFERENCES Estudiante(id_estudiante),
    id_comision_origen INT NOT NULL
        CONSTRAINT fk_listaEspera_comisionOrigen FOREIGN KEY REFERENCES Comision(id_comision),
    id_comision_destino INT NOT NULL
        CONSTRAINT fk_listaEspera_comisionDestino FOREIGN KEY REFERENCES Comision(id_comision)
)
GO

-- Restricciones para Lista de Espera

ALTER TABLE Lista_Espera
ADD
    -- Fecha de alta por defecto (momento en que entra en la lista)
    CONSTRAINT df_listaEspera_fechaAlta DEFAULT (CAST(GETDATE() AS DATE)) FOR fecha_alta,

    -- Estado limitado a tres valores válidos
    CONSTRAINT ck_listaEspera_estado CHECK (
        estado IN ('En espera', 'Pendiente', 'Finalizada')
    ),

    -- Fecha de baja nula o posterior a la fecha de alta
    CONSTRAINT ck_listaEspera_fechas CHECK (
        fecha_baja IS NULL OR fecha_baja >= fecha_alta
    );
GO

-- Tabla Propuesta

CREATE TABLE Propuesta (
    id_propuesta INT IDENTITY
        CONSTRAINT pk_id_propuesta PRIMARY KEY,
    fecha_alta DATETIME NOT NULL,
    fecha_baja DATETIME NULL,
    estado NVARCHAR (50) NOT NULL,
    id_listaEspera_1 INT NOT NULL
        CONSTRAINT fk_propuesta_listaEspera_1 FOREIGN KEY REFERENCES Lista_Espera(id_lista_espera),
    id_listaEspera_2 INT NOT NULL
        CONSTRAINT fk_propuesta_listaEspera_2 FOREIGN KEY REFERENCES Lista_Espera(id_lista_espera)
)
GO

-- Restricciones para Propuesta

ALTER TABLE Propuesta
ADD
    -- Fecha de alta por defecto (actual)
    CONSTRAINT df_propuesta_fechaAlta
        DEFAULT (GETDATE()) FOR fecha_alta,

    -- Estados válidos
    CONSTRAINT ck_propuesta_estado
        CHECK (estado IN ('Pendiente','Aceptada','Rechazada')),

    -- fecha_baja nula o >= fecha_alta
    CONSTRAINT ck_propuesta_fechas
        CHECK (fecha_baja IS NULL OR fecha_baja >= fecha_alta),

    -- Coherencia fecha_baja según estado:
    -- si Pendiente -> fecha_baja debe ser NULL
    -- si Aceptada/Rechazada -> fecha_baja NO debe ser NULL
    CONSTRAINT ck_propuesta_estadoFecha
        CHECK (
            (estado = 'Pendiente'  AND fecha_baja IS NULL)
         OR (estado IN ('Aceptada','Rechazada') AND fecha_baja IS NOT NULL)
        ),

    -- Las dos listas deben ser distintas
    CONSTRAINT ck_propuesta_listasDistintas
        CHECK (id_listaEspera_1 <> id_listaEspera_2),

    -- Normalizar el par para evitar duplicados (A,B) y (B,A)
    CONSTRAINT ck_propuesta_ordenPar
        CHECK (id_listaEspera_1 < id_listaEspera_2);
GO

-- Uniques para Propuesta

-- Unicidad: no puede existir más de UNA propuesta PENDIENTE para el mismo par
CREATE UNIQUE INDEX ix_propuesta_parPendiente
ON Propuesta(id_listaEspera_1, id_listaEspera_2)
WHERE estado = 'Pendiente';
GO

-- Una misma lista no puede estar en dos propuestas PENDIENTES a la vez
CREATE UNIQUE INDEX ix_propuesta_pendiente_l1
ON Propuesta(id_listaEspera_1)
WHERE estado = 'Pendiente';
GO

CREATE UNIQUE INDEX ix_propuesta_pendiente_l2
ON Propuesta(id_listaEspera_2)
WHERE estado = 'Pendiente';
GO

-- Tabla Respuesta_Propuesta

CREATE TABLE Respuesta_Propuesta (
    id_respuesta INT IDENTITY
        CONSTRAINT pk_id_respuesta PRIMARY KEY,
    decision NVARCHAR (50) NOT NULL,
    motivo_rechazo NVARCHAR (250),
    fecha DATETIME NOT NULL,
    id_propuesta INT NOT NULL
        CONSTRAINT fk_respuestaPropuesta_propuesta FOREIGN KEY REFERENCES Propuesta(id_propuesta),
    id_estudiante INT NOT NULL
        CONSTRAINT fk_respuestaPropuesta_estudiante FOREIGN KEY REFERENCES Estudiante(id_estudiante)
)

-- Restricciones para Respuesta_Propuesta

ALTER TABLE Respuesta_Propuesta
ADD 
    -- fecha por defecto (momento en que responde)
    CONSTRAINT df_respuestaPropuesta_fecha
        DEFAULT (GETDATE()) FOR fecha,

    -- decision solo puede ser Aceptar o Rechazar
    CONSTRAINT ck_respuestaPropuesta_decision
        CHECK (decision IN ('Aceptar', 'Rechazar')),

    -- motivo_rechazo solo válido si decision = Rechazar
    CONSTRAINT ck_respuestaPropuesta_motivoValido
        CHECK (
            (decision LIKE 'Rechazar' AND LEN(LTRIM(RTRIM(motivo_rechazo))) > 30)
            OR (decision LIKE 'Aceptar' AND motivo_rechazo IS NULL)
        );
GO

-- Tabla Reporte

CREATE TABLE Reporte (
    id_reporte INT IDENTITY
        CONSTRAINT pk_reporte PRIMARY KEY,
    emisor INT NULL
        CONSTRAINT fk_reporte_verificador FOREIGN KEY REFERENCES Verificador(id_verificador),
    receptor INT NOT NULL
        CONSTRAINT fk_reporte_estudiante FOREIGN KEY REFERENCES Estudiante(id_estudiante),
    id_periodo INT NOT NULL
        CONSTRAINT fk_reporte_periodo FOREIGN KEY REFERENCES Periodo(id_periodo),
    motivo NVARCHAR(300) NOT NULL,
    estado NVARCHAR(20) NOT NULL, 
    fecha_alta DATETIME NOT NULL,
    fecha_fin DATE NOT NULL
);
GO

-- Restricciones para Reporte

ALTER TABLE Reporte
ADD
    -- Fecha automática de creación
    CONSTRAINT df_reporte_fechaAlta DEFAULT (GETDATE()) FOR fecha_alta,

    -- Estado del reporte: solo dos posibles
    CONSTRAINT ck_reporte_estado
        CHECK (estado IN ('Vigente', 'Finalizado')),

    -- El motivo debe tener al menos 20 caracteres útiles
    CONSTRAINT ck_reporte_motivo
        CHECK (LEN(motivo) >= 20),

    -- Fecha de finalización no puede ser antes de la fecha de inicio
    CONSTRAINT ck_reporte_fechas
        CHECK (fecha_fin >= CAST(fecha_alta AS DATE));
GO

-- Tabla Comprobante

CREATE TABLE Comprobante (
    id_comprobante INT IDENTITY
        CONSTRAINT pk_id_comprobante PRIMARY KEY,
    fecha_emision DATETIME NOT NULL,
    id_propuesta INT NOT NULL
        CONSTRAINT fk_comprobante_propuesta FOREIGN KEY REFERENCES Propuesta(id_propuesta),
    id_estudiante_1 INT NOT NULL
        CONSTRAINT fk_comprobante_estudiante1 FOREIGN KEY REFERENCES Estudiante(id_estudiante),
    id_estudiante_2 INT NOT NULL
        CONSTRAINT fk_comprobante_estudiante2 FOREIGN KEY REFERENCES Estudiante(id_estudiante)
)
GO

-- Restricciones para Comprobante

ALTER TABLE Comprobante
ADD
    -- Fecha por defecto ahora
    CONSTRAINT df_comprobante_fecha
        DEFAULT (GETDATE()) FOR fecha_emision,

    -- Solo un comprobante por propuesta
    CONSTRAINT uq_comprobante_propuesta
        UNIQUE (id_propuesta),

    -- Estudiantes deben ser distintos
    CONSTRAINT ck_comprobante_estudiantes_distintos
        CHECK (id_estudiante_1 <> id_estudiante_2),

    -- Normalizamos el par para evitar (A,B) y (B,A)
    CONSTRAINT ck_comprobante_orden_par
        CHECK (id_estudiante_1 < id_estudiante_2);
GO

-- Tabla Notificacion

CREATE TABLE Notificacion (
    id_notificacion INT IDENTITY
        CONSTRAINT pk_id_notificacion PRIMARY KEY,
    tipo NVARCHAR (100) NOT NULL,
    mensaje NVARCHAR (500) NOT NULL,
    fecha DATETIME NOT NULL,
    id_usuario INT NOT NULL
        CONSTRAINT fk_notificacion_usuario FOREIGN KEY REFERENCES Usuario(id_usuario)
)

-- Restricciones para Notificacion

ALTER TABLE Notificacion
ADD
    -- Fecha por defecto (momento de generar la notificación)
    CONSTRAINT df_notificacion_fecha DEFAULT (GETDATE()) FOR fecha,

    -- Tipos permitidos (podés ajustar la lista si querés)
    CONSTRAINT ck_notificacion_tipo CHECK (
        tipo IN (
            'Propuesta',      -- cuando se arma un match "¡Tenemos una propuesta para vos!"
            'Reporte',        -- reportes del sistema o del verificador "Has sido reportado"
            'Comprobante',    -- comprobante emitido "Aqui esta el comprobante de tu intercambio"
            'Aviso',          -- avisos generales 
            'Aceptacion',     -- aceptación de propuesta "¡En horabuena!, han aceptado la propuesta"
            'Rechazo',        -- rechazo de propuesta "Han rechazado la propuesta"
            'Vencimiento',    -- constancia vencida / plazos "¡No olvides aceptar la propuesta! Tenes tiempo hasta ..."
            'Habilitacion',     -- alumno habilitado "Ya puedes empezar a realizar intercambios con SIC-UNNE :)"
            'Recordatorio',   -- recordatorios 
            'Sistema',        -- eventos automáticos del sistema
            'Bloqueo'         
        )
    )
GO



-- PROCESAMIENTOS ALMACENADOS: 

-- Generar coincidencias FIFO entre dos colas complementarias

CREATE OR ALTER PROCEDURE SIC_GenerarMatches
    @id_comision_A INT,      -- comisión destino A (por ej., 2A)
    @id_comision_C INT       -- comisión destino C (la contraparte, por ej., 2C)
AS
BEGIN
    SET NOCOUNT ON;                          -- evita rowcounts intermedios
    SET XACT_ABORT ON;                       -- si hay error, aborta la transacción

    DECLARE @leA INT;                         -- id de lista en cola C->A (quiere ir a A, viene de C)
    DECLARE @leC INT;                         -- id de lista en cola A->C (quiere ir a C, viene de A)

    BEGIN TRAN;                               -- inicia transacción explícita
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;  -- nivel más estricto para evitar condiciones de carrera

    WHILE 1 = 1                               -- bucle: intenta emparejar tantos pares como sea posible
    BEGIN
        -- toma el PRIMER (FIFO) de la cola C->A (estado 'En espera')
        SELECT TOP 1 @leA = leA.id_lista_espera
        FROM Lista_Espera AS leA WITH (UPDLOCK, READPAST, ROWLOCK) -- bloquea fila tomada, ignora bloqueadas
        WHERE leA.estado = 'En espera'
          AND leA.id_comision_origen  = @id_comision_C
          AND leA.id_comision_destino = @id_comision_A
        ORDER BY leA.fecha_alta, leA.id_lista_espera; -- orden FIFO

        -- toma el PRIMER (FIFO) de la cola A->C (estado 'En espera')
        SELECT TOP 1 @leC = leC.id_lista_espera
        FROM Lista_Espera AS leC WITH (UPDLOCK, READPAST, ROWLOCK)
        WHERE leC.estado = 'En espera'
          AND leC.id_comision_origen  = @id_comision_A
          AND leC.id_comision_destino = @id_comision_C
        ORDER BY leC.fecha_alta, leC.id_lista_espera;

        IF @leA IS NULL OR @leC IS NULL   -- si falta alguno, no hay pareja: termina el bucle
            BREAK;

        -- normaliza el par (menor primero) para respetar el CHECK (id_listaEspera_1 < id_listaEspera_2)
        DECLARE @l1 INT = IIF(@leA < @leC, @leA, @leC); -- el menor va en id_listaEspera_1
        DECLARE @l2 INT = IIF(@leA < @leC, @leC, @leA); -- el mayor va en id_listaEspera_2

        -- crea la propuesta en estado 'Pendiente' (fecha_alta por DEFAULT si lo definiste; acá la seteamos explícita)
        INSERT INTO Propuesta(fecha_alta, estado, id_listaEspera_1, id_listaEspera_2)
        VALUES (GETDATE(), 'Pendiente', @l1, @l2);

        -- marca ambas listas participantes como 'Pendiente' (salen temporalmente de la cola)
        UPDATE Lista_Espera
           SET estado = 'Pendiente'
         WHERE id_lista_espera IN (@leA, @leC);

        -- el WHILE continúa para intentar más emparejamientos si hay stock en ambas colas
    END

    COMMIT TRAN;                               -- confirma la transacción
END
GO

-- Responder propuesta (aceptar / rechazar) y ejecutar consecuencias

CREATE OR ALTER PROCEDURE SIC_ResponderPropuesta
    @id_propuesta INT,                        -- propuesta a responder
    @id_usuario   INT,                        -- usuario (estudiante) que responde
    @decision     NVARCHAR(20),               -- 'Aceptar' o 'Rechazar' (según tu CHECK)
    @motivo       NVARCHAR(400) = NULL        -- motivo en caso de rechazo (validado por CHECK)
AS
BEGIN
    SET NOCOUNT ON;                           -- evita rowcounts
    SET XACT_ABORT ON;                        -- aborta transacción si hay error

    -- valida que la decisión sea correcta
    IF @decision NOT IN ('Aceptar','Rechazar')
    BEGIN
        RAISERROR('Decisión inválida. Use "Aceptar" o "Rechazar".', 16, 1);
        RETURN;
    END

    BEGIN TRAN;                               -- inicia la transacción

    -- inserta la respuesta (tu tabla tiene CHECKs que validan motivo/longitud)
    INSERT INTO Respuesta_Propuesta(id_propuesta, id_estudiante, decision, motivo_rechazo, fecha)
    SELECT
        @id_propuesta,                        -- id_propuesta que llega por parámetro
        e.id_estudiante,                      -- mapeo: obtengo el id_estudiante a partir del id_usuario
        @decision,
        @motivo,
        GETDATE()
    FROM Estudiante AS e
    WHERE e.id_estudiante = @id_usuario       -- OJO: si Estudiante.id_estudiante == Usuario.id_usuario (como definiste)
       OR EXISTS (SELECT 1 FROM Usuario u WHERE u.id_usuario = @id_usuario AND u.id_usuario = e.id_estudiante);
    -- ↑ Si tu Estudiante.id_estudiante es FK=PK a Usuario(id_usuario), la comparación directa vale.

    -- obtengo la propuesta y sus dos listas + estudiantes y comisiones
    DECLARE @estado NVARCHAR(50);
    DECLARE @l1 INT, @l2 INT;
    DECLARE @e1 INT, @e2 INT;
    DECLARE @origen1 INT, @dest1 INT, @origen2 INT, @dest2 INT;

    -- bloqueo la propuesta (UPDLOCK) para evitar carreras entre las dos respuestas
    SELECT @estado = p.estado,
           @l1 = p.id_listaEspera_1, @l2 = p.id_listaEspera_2
    FROM Propuesta AS p WITH (UPDLOCK, ROWLOCK)
    WHERE p.id_propuesta = @id_propuesta;

    IF @estado IS NULL
    BEGIN
        RAISERROR('Propuesta inexistente.', 16, 1);
        ROLLBACK TRAN; RETURN;
    END

    -- carga datos de las listas: estudiantes y comisiones de origen/destino
    SELECT @e1 = le1.id_estudiante, @origen1 = le1.id_comision_origen, @dest1 = le1.id_comision_destino
    FROM Lista_Espera AS le1 WHERE le1.id_lista_espera = @l1;

    SELECT @e2 = le2.id_estudiante, @origen2 = le2.id_comision_origen, @dest2 = le2.id_comision_destino
    FROM Lista_Espera AS le2 WHERE le2.id_lista_espera = @l2;

    -- si alguien rechazó: cerrar propuesta y reingresar al otro al final de su cola
    IF @decision = 'Rechazar'
    BEGIN
        -- marca la propuesta como Rechazada (trigger pondrá fecha_baja)
        UPDATE Propuesta
           SET estado = 'Rechazada'
         WHERE id_propuesta = @id_propuesta;

        -- determina quién rechazó: comparamos @id_usuario (Usuario) con el Estudiante vinculado
        DECLARE @rechaza_est INT = CASE 
            WHEN @id_usuario = @e1 THEN @e1
            WHEN @id_usuario = @e2 THEN @e2
            ELSE @e1 -- fallback por si vino id_usuario de otra forma (ajusta si usás otro mapping)
        END;

        DECLARE @otro_est INT = CASE WHEN @rechaza_est = @e1 THEN @e2 ELSE @e1 END;
        DECLARE @otro_le  INT = CASE WHEN @rechaza_est = @e1 THEN @l2 ELSE @l1 END;

        -- el que NO rechazó vuelve a 'En espera' y al final (fecha_alta ahora y baja NULL)
        UPDATE Lista_Espera
           SET estado = 'En espera',
               fecha_baja = NULL,
               fecha_alta = CAST(GETDATE() AS DATE)
         WHERE id_lista_espera = @otro_le;

        -- el que rechazó queda finalizado en su lista
        UPDATE Lista_Espera
           SET estado = 'Finalizada',
               fecha_baja = CAST(GETDATE() AS DATE)
         WHERE id_lista_espera IN (@l1, @l2)
           AND id_estudiante = @rechaza_est;

        -- notifica a ambos
        INSERT INTO Notificacion(tipo, mensaje, fecha, id_usuario)
        VALUES
          ('Rechazo', CONCAT('Has rechazado la propuesta #', @id_propuesta, COALESCE(CONCAT(' (motivo: ', @motivo, ')'),'')), GETDATE(), @id_usuario);

        INSERT INTO Notificacion(tipo, mensaje, fecha, id_usuario)
        SELECT 'Rechazo', CONCAT('La propuesta #', @id_propuesta, ' fue rechazada. Regresaste a la lista en última posición.'), GETDATE(), u.id_usuario
        FROM Estudiante es
        JOIN Usuario u ON u.id_usuario = es.id_estudiante
        WHERE es.id_estudiante = @otro_est;

        -- si este usuario acumula 3 rechazos en el mismo período, crear reporte e inhabilitar (lógica simplificada)
        DECLARE @rechazos INT;
        SELECT @rechazos = COUNT(*)
        FROM Respuesta_Propuesta
        WHERE id_estudiante = @rechaza_est
          AND decision = 'Rechazar'
          AND fecha >= DATEADD(MONTH, -6, GETDATE());  -- ejemplo: ventana 6 meses / período

        IF @rechazos >= 3
        BEGIN
            -- hallar un período asociado (simplificado: se toma período de una inscripción activa del estudiante)
            DECLARE @id_periodo INT;
            SELECT TOP 1 @id_periodo = a.id_periodo
            FROM Inscripcion i
            JOIN Comision c ON c.id_comision = i.id_comision
            JOIN Asignatura a ON a.id_asignatura = c.id_asignatura
            WHERE i.id_estudiante = @rechaza_est AND i.estado = 1
            ORDER BY i.fecha_alta DESC;

            -- crear reporte vigente hasta fin de período (si encontramos período)
            IF @id_periodo IS NOT NULL
            BEGIN
                DECLARE @fecha_fin DATE;
                SELECT @fecha_fin = p.fecha_fin FROM Periodo p WHERE p.id_periodo = @id_periodo;

                INSERT INTO Reporte(emisor, receptor, id_periodo, motivo, estado, fecha_alta, fecha_fin)
                VALUES (NULL, @rechaza_est, @id_periodo,
                        'El estudiante acumuló 3 rechazos de intercambio en el mismo período.',
                        'Vigente', GETDATE(), @fecha_fin);

                -- inhabilitar usuario (estado=0)
                UPDATE Usuario
                   SET estado = 0
                 WHERE id_usuario = @rechaza_est;

                -- notificar bloqueo
                INSERT INTO Notificacion(tipo, mensaje, fecha, id_usuario)
                VALUES ('Bloqueo', 'Has sido inhabilitado para intercambios hasta el fin del período vigente.', GETDATE(), @rechaza_est);
            END
        END

        COMMIT TRAN;   -- confirma todo el flujo de rechazo
        RETURN;        -- termina el SP
    END

    -- si la decisión fue 'Aceptar', verificamos si ya están las dos aceptaciones registradas
    DECLARE @aceptas INT;
    SELECT @aceptas = COUNT(*)
    FROM Respuesta_Propuesta
    WHERE id_propuesta = @id_propuesta
      AND decision = 'Aceptar';

    IF @aceptas < 2
    BEGIN
        -- aún falta la otra respuesta: solo guardamos esta y salimos
        COMMIT TRAN;
        RETURN;
    END

    -- ambos aceptaron: concretar intercambio (swap)
    -- 1) dar de baja inscripciones de origen de ambos (si están activas)
    UPDATE Inscripcion
       SET estado = 0, fecha_baja = CAST(GETDATE() AS DATE)
     WHERE (id_estudiante = @e1 AND id_comision = @origen1 AND estado = 1)
        OR (id_estudiante = @e2 AND id_comision = @origen2 AND estado = 1);

    -- 2) dar de alta inscripciones destino para ambos
    INSERT INTO Inscripcion(fecha_alta, estado, fecha_baja, id_comision, id_estudiante)
    VALUES (CAST(GETDATE() AS DATE), 1, NULL, @dest1, @e1),
           (CAST(GETDATE() AS DATE), 1, NULL, @dest2, @e2);

    -- 3) cerrar listas y propuesta
    UPDATE Lista_Espera
       SET estado = 'Finalizada', fecha_baja = CAST(GETDATE() AS DATE)
     WHERE id_lista_espera IN (@l1, @l2);

    UPDATE Propuesta
       SET estado = 'Aceptada'           -- TR_Propuesta_SetFechaBaja pondrá fecha_baja
     WHERE id_propuesta = @id_propuesta;

    -- 4) crear comprobante (único por propuesta) y notificar a ambos
    DECLARE @id_comprobante INT;
    INSERT INTO Comprobante(fecha_emision, id_propuesta, id_estudiante_1, id_estudiante_2)
    VALUES (GETDATE(), @id_propuesta, IIF(@e1 < @e2, @e1, @e2), IIF(@e1 < @e2, @e2, @e1));  -- normaliza el par
    SET @id_comprobante = SCOPE_IDENTITY();

    -- notifica a ambos estudiantes que ya tienen comprobante
    INSERT INTO Notificacion(tipo, mensaje, fecha, id_usuario)
    VALUES
      ('Comprobante', CONCAT('Intercambio aceptado. Comprobante #', @id_comprobante, '.'), GETDATE(), @e1),
      ('Comprobante', CONCAT('Intercambio aceptado. Comprobante #', @id_comprobante, '.'), GETDATE(), @e2);

    COMMIT TRAN;   -- confirma todo el flujo de aceptación
END
GO

-- TRIGGERS: 

-- Cambiar el estado de los estudiantes cuando se registran a 0, hasta verificar
CREATE OR ALTER TRIGGER tr_usuario_default_estado_por_rol
ON Usuario
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- si el nuevo usuario es Estudiante, fuerza estado = 0
    UPDATE u
       SET u.estado = 0
    FROM Usuario u
    JOIN inserted i
      ON i.id_usuario = u.id_usuario
    WHERE i.rol = 'Estudiante';
END;
GO

-- Verificar constancia y habilitar estudiante

CREATE OR ALTER TRIGGER tr_estudiante_verificar_constancia
ON Estudiante
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Actualiza el estado del usuario según la validez de la constancia
    UPDATE u
       SET u.estado = 
           CASE 
               WHEN e.fecha_constancia <= GETDATE()
                    AND e.fecha_constancia >= DATEADD(MONTH, -6, GETDATE())
                    THEN 1   -- válida → habilitado
               ELSE 0        -- vencida o futura → inhabilitado
           END
    FROM Usuario u
    JOIN Estudiante e
      ON u.id_usuario = e.id_estudiante
    JOIN inserted i
      ON i.id_estudiante = e.id_estudiante;

    -- Opcional: genera notificaciones automáticas
    INSERT INTO Notificacion(tipo, mensaje, fecha, id_usuario)
    SELECT 
        CASE 
            WHEN e.fecha_constancia <= GETDATE()
                 AND e.fecha_constancia >= DATEADD(MONTH, -6, GETDATE())
                 THEN 'Habilitacion'
            ELSE 'Vencimiento'
        END AS tipo,
        CASE 
            WHEN e.fecha_constancia <= GETDATE()
                 AND e.fecha_constancia >= DATEADD(MONTH, -6, GETDATE())
                 THEN CONCAT('Tu constancia fue verificada exitosamente el ', 
                             CONVERT(VARCHAR, GETDATE(), 103), 
                             '. Ya podés participar en intercambios.')
            ELSE 'Tu constancia no es válida (vencida o incorrecta). Actualízala para poder participar en intercambios.'
        END AS mensaje,
        GETDATE(),
        e.id_estudiante
    FROM Estudiante e
    JOIN inserted i ON i.id_estudiante = e.id_estudiante;
END;
GO

-- Verificar que la primera letra del Apellido se encuentre en letra_desde y letra_hasta de la comision

CREATE OR ALTER TRIGGER tr_inscripcion_validar_letra_apellido
ON Inscripcion
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Verifica por cada inscripción nueva
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Estudiante e ON i.id_estudiante = e.id_estudiante
        JOIN Usuario u ON u.id_usuario = e.id_estudiante
        JOIN Comision c ON c.id_comision = i.id_comision
        WHERE 
            -- Tomamos la primera letra del apellido
            UPPER(LEFT(LTRIM(u.apellido), 1)) COLLATE Latin1_General_CI_AI
            NOT BETWEEN 
                UPPER(c.letra_desde) COLLATE Latin1_General_CI_AI
                AND UPPER(c.letra_hasta) COLLATE Latin1_General_CI_AI
    )
    BEGIN
        RAISERROR('La inicial del apellido del estudiante no corresponde al rango de la comisión.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- Al insertar en Lista_Espera, intentar generar coincidencias del par

CREATE OR ALTER TRIGGER TR_ListaEspera_TryMatchOnInsert
ON Lista_Espera
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;                                          -- evita rowcounts intermedios

    DECLARE @origen INT;                                     -- comisión origen del insertado
    DECLARE @destino INT;                                    -- comisión destino del insertado

    -- toma los valores de la fila (si se insertan varias, acá podrías loopear; para simplicidad, tomamos una)
    SELECT TOP 1
           @origen  = i.id_comision_origen,
           @destino = i.id_comision_destino
    FROM inserted AS i;

    -- llama al generador de matches para las dos comisiones complementarias
    EXEC SIC_GenerarMatches
         @id_comision_A = @destino,       -- A es la comisión destino del que ingresó
         @id_comision_C = @origen;        -- C es su comisión origen (la contraparte)
END
GO


-- Al cerrar una Propuesta, setea fecha_baja automáticamente

CREATE OR ALTER TRIGGER TR_Propuesta_SetFechaBaja
ON Propuesta
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;                                                           -- evita rowcounts

    -- si el estado pasó de 'Pendiente' a 'Aceptada' o 'Rechazada', setea fecha_baja si vino NULL
    UPDATE p
       SET fecha_baja = ISNULL(p.fecha_baja, GETDATE())                       -- usa ahora si no vino seteada
    FROM Propuesta AS p
    JOIN inserted  AS ins ON ins.id_propuesta = p.id_propuesta                -- nuevos valores
    JOIN deleted   AS del ON del.id_propuesta = p.id_propuesta                -- valores previos
    WHERE del.estado = 'Pendiente'                                            -- antes estaba pendiente
      AND ins.estado IN ('Aceptada','Rechazada');                             -- ahora cerrada
END
GO

