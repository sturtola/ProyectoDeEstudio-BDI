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

-- Usuario
CREATE TABLE Usuario (
    id_usuario INT IDENTITY 
        CONSTRAINT pk_id_usuario PRIMARY KEY,
    nombre NVARCHAR (100) NOT NULL,
    apellido NVARCHAR (100) NOT NULL,
    documento INT NOT NULL,
    correo NVARCHAR (100) NOT NULL,
    contrasena VARBINARY(64) NOT NULL,
    estado BIT DEFAULT 0,
    rol NVARCHAR (30) NOT NULL,
    id_carrera INT 
        CONSTRAINT fk_usuario_carrera FOREIGN KEY REFERENCES Carrera(id_carrera)
)
GO

-- Restricciones para Usuario

ALTER TABLE Usuario
ADD 
    -- Documento y Correo deben ser únicos
    CONSTRAINT uq_usuario_documento UNIQUE (documento),
    CONSTRAINT uq_usuario_correo UNIQUE (correo),

    CONSTRAINT ck_usuario_rol CHECK (rol IN ('Administrador', 'Estudiante', 'Verificador', 'Indefinido')),

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

    -- Estado solo puede ser 1 o 0
    CONSTRAINT ck_usuario_estado CHECK (estado IN (0, 1));
GO

-- Tabla Profesor

CREATE TABLE Profesor (
    id_profesor INT IDENTITY
        CONSTRAINT pk_id_profesor PRIMARY KEY,
    nombre NVARCHAR (100) NOT NULL,
    apellido NVARCHAR (100) NOT NULL,
    documento INT NOT NULL,
    correo NVARCHAR (100) NOT NULL,
    estado BIT DEFAULT 1
)
GO

-- Tabla Constancia (para rol estudiante)

CREATE TABLE Constancia (
    id_constancia INT
       CONSTRAINT pk_id_constancia PRIMARY KEY
       CONSTRAINT fk_constancia_usuario FOREIGN KEY REFERENCES Usuario(id_usuario),
    constancia_url NVARCHAR(200) NOT NULL,
    fecha_constancia DATE NOT NULL
)
GO

-- Restricciones para Constancia

ALTER TABLE Constancia
ADD 
    -- Verifica que la URL tenga formato de archivo válido (simplificada)
    CONSTRAINT ck_constancia_urlFormato CHECK (
        constancia_url LIKE '%.pdf' OR 
        constancia_url LIKE '%.jpg' OR 
        constancia_url LIKE '%.jpeg' OR 
        constancia_url LIKE '%.png'
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
    id_usuario INT NOT NULL
        CONSTRAINT fk_inscripcion_usuario FOREIGN KEY REFERENCES Usuario(id_usuario)
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
    id_usuario INT NOT NULL
        CONSTRAINT fk_listaEspera_usuario FOREIGN KEY REFERENCES Usuario(id_usuario),
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
    id_usuario INT NOT NULL
        CONSTRAINT fk_respuestaPropuesta_usuario FOREIGN KEY REFERENCES Usuario(id_usuario)
)
GO

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
        CONSTRAINT fk_reporte_verificador FOREIGN KEY REFERENCES Usuario(id_usuario),
    receptor INT NOT NULL
        CONSTRAINT fk_reporte_usuario FOREIGN KEY REFERENCES Usuario(id_usuario),
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
    id_usuario_1 INT NOT NULL
        CONSTRAINT fk_comprobante_usuario1 FOREIGN KEY REFERENCES Usuario(id_usuario),
    id_usuario_2 INT NOT NULL
        CONSTRAINT fk_comprobante_usuario2 FOREIGN KEY REFERENCES Usuario(id_usuario)
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
    CONSTRAINT ck_comprobante_usuario_distintos
        CHECK (id_usuario_1 <> id_usuario_2),

    -- Normalizamos el par para evitar (A,B) y (B,A)
    CONSTRAINT ck_comprobante_orden_par
        CHECK (id_usuario_1 < id_usuario_2);
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
GO

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

