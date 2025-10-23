-- SIC-UNNE: Sistema de Intercambio de Comisiones
-- Definición del modelo relacional

CREATE DATABASE SIC_UNNE;
GO
USE SIC_UNNE;
GO

CREATE TABLE Profesor
(
  id_profesor INT NOT NULL,
  dni INT NOT NULL,
  nombre VARCHAR(50) NOT NULL,
  apellido VARCHAR(50) NOT NULL,
  email VARCHAR(100) NOT NULL,
  CONSTRAINT PK_profesor PRIMARY KEY (id_profesor),
  CONSTRAINT UQ_profesor_dni UNIQUE (dni),
  CONSTRAINT UQ_profesor_email UNIQUE (email)
);

CREATE TABLE Periodo
(
  id_periodo INT NOT NULL,
  nombre_periodo VARCHAR(50) NOT NULL,
  fecha_inicio DATE NOT NULL,
  fecha_fin DATE NOT NULL,
  CONSTRAINT PK_periodo PRIMARY KEY (id_periodo),
  CONSTRAINT CK_periodo_fechas CHECK (fecha_fin > fecha_inicio)
);

CREATE TABLE Asignatura
(
  id_asignatura INT NOT NULL,
  nombre_asignatura VARCHAR(100) NOT NULL,
  anio_asignatura INT NOT NULL,
  id_periodo INT NOT NULL,
  CONSTRAINT PK_asignatura PRIMARY KEY (id_asignatura),
  CONSTRAINT UQ_asignatura_nombre UNIQUE (nombre_asignatura),
  CONSTRAINT CK_asignatura_anio CHECK (anio_asignatura BETWEEN 1 AND 6),
  CONSTRAINT FK_asignatura_periodo FOREIGN KEY (id_periodo) REFERENCES Periodo(id_periodo)
);

CREATE TABLE Comision
(
  id_comision INT NOT NULL,
  nombre_comision VARCHAR(50) NOT NULL,
  id_asignatura INT NOT NULL,
  CONSTRAINT PK_comision PRIMARY KEY (id_comision),
  CONSTRAINT FK_comision_asig FOREIGN KEY (id_asignatura) REFERENCES Asignatura(id_asignatura),
  CONSTRAINT UQ_comision_nombre UNIQUE (id_asignatura, nombre_comision)
);

CREATE TABLE Edificio
(
  id_edificio INT NOT NULL,
  nombre_edificio VARCHAR(100) NOT NULL,
  CONSTRAINT PK_edificio PRIMARY KEY (id_edificio),
  CONSTRAINT UQ_edificio_nombre UNIQUE (nombre_edificio)
);

CREATE TABLE Aula
(
  id_aula INT NOT NULL,
  nombre_aula VARCHAR(100) NOT NULL,
  id_edificio INT NOT NULL,
  CONSTRAINT PK_aula PRIMARY KEY (id_aula),
  CONSTRAINT FK_aula_edificio FOREIGN KEY (id_edificio) REFERENCES Edificio(id_edificio),
  CONSTRAINT UQ_aula_nombre UNIQUE (id_edificio, nombre_aula)
);

CREATE TABLE Asignatura_Profesor
(
  id_profesor INT NOT NULL,
  id_asignatura INT NOT NULL,
  CONSTRAINT PK_asig_prof PRIMARY KEY (id_profesor, id_asignatura),
  CONSTRAINT FK_asig_prof_prof FOREIGN KEY (id_profesor) REFERENCES Profesor(id_profesor),
  CONSTRAINT FK_asig_prof_asig FOREIGN KEY (id_asignatura) REFERENCES Asignatura(id_asignatura)
);

CREATE TABLE Universidad
(
  id_universidad INT NOT NULL,
  nombre_universidad VARCHAR(100) NOT NULL,
  CONSTRAINT PK_universidad PRIMARY KEY (id_universidad),
  CONSTRAINT UQ_universidad_nombre UNIQUE (nombre_universidad)
);

CREATE TABLE Carrera
(
  id_carrera INT NOT NULL,
  nombre_carrera VARCHAR(100) NOT NULL,
  duracion_carrera INT NOT NULL,
  CONSTRAINT PK_carrera PRIMARY KEY (id_carrera),
  CONSTRAINT UQ_carrera_nombre UNIQUE (nombre_carrera)
);

CREATE TABLE Horario_Cursada
(
  id_horario INT NOT NULL,
  dia VARCHAR(15) NOT NULL,
  hora_desde TIME NOT NULL,
  hora_hasta TIME NOT NULL,
  modalidad VARCHAR(20) NOT NULL CHECK (modalidad IN ('PRESENCIAL','VIRTUAL','MIXTA')),
  CONSTRAINT PK_horario PRIMARY KEY (id_horario),
  CONSTRAINT CK_horario_rango CHECK (hora_hasta > hora_desde)
);

CREATE TABLE Cursada_Comision
(
  id_comision INT NOT NULL,
  id_aula INT NOT NULL,
  id_horario INT NOT NULL,
  CONSTRAINT PK_cursada_comision PRIMARY KEY (id_comision, id_aula, id_horario),
  CONSTRAINT FK_cursada_comision_comision FOREIGN KEY (id_comision) REFERENCES Comision(id_comision),
  CONSTRAINT FK_cursada_comision_aula FOREIGN KEY (id_aula) REFERENCES Aula(id_aula),
  CONSTRAINT FK_cursada_comision_horario FOREIGN KEY (id_horario) REFERENCES Horario_Cursada(id_horario)
);

CREATE TABLE Usuario
(
  id_usuario INT NOT NULL,
  dni INT NOT NULL,
  nombre VARCHAR(50) NOT NULL,
  apellido VARCHAR(50) NOT NULL,
  estado VARCHAR(50) NOT NULL,
  email VARCHAR(100) NOT NULL,
  contraseña VARCHAR(100) NOT NULL,
  CONSTRAINT PK_usuario PRIMARY KEY (id_usuario),
  CONSTRAINT UQ_usuario_dni UNIQUE (dni),
  CONSTRAINT UQ_usuario_email UNIQUE (email)
);

CREATE TABLE Inscripcion
(
  id_inscripcion INT NOT NULL,
  id_comision INT NOT NULL,
  id_usuario INT NOT NULL,
  activo BIT NOT NULL DEFAULT 1,
  fecha_inscripcion DATE NOT NULL DEFAULT GETDATE(),
  fecha_baja DATE NULL,
  CONSTRAINT PK_inscripcion PRIMARY KEY (id_inscripcion),
  CONSTRAINT FK_inscripcion_comision FOREIGN KEY (id_comision) REFERENCES Comision(id_comision),
  CONSTRAINT FK_inscripcion_usuario FOREIGN KEY (id_usuario) REFERENCES Usuario(id_usuario),
  CONSTRAINT UQ_inscripcion UNIQUE (id_usuario, id_comision)
);

CREATE TABLE Universidad_Carrera
(
  id_universidad INT NOT NULL,
  id_carrera INT NOT NULL,
  CONSTRAINT PK_universidad_carrera PRIMARY KEY (id_universidad, id_carrera),
  CONSTRAINT FK_uc_uni FOREIGN KEY (id_universidad) REFERENCES Universidad(id_universidad),
  CONSTRAINT FK_uc_car FOREIGN KEY (id_carrera) REFERENCES Carrera(id_carrera)
);

CREATE TABLE Carrera_Asignatura
(
  id_carrera_asig INT NOT NULL,
  id_carrera INT NOT NULL,
  id_asignatura INT NOT NULL,
  CONSTRAINT PK_carrera_asig PRIMARY KEY (id_carrera_asig),
  CONSTRAINT FK_ca_car FOREIGN KEY (id_carrera) REFERENCES Carrera(id_carrera),
  CONSTRAINT FK_ca_asig FOREIGN KEY (id_asignatura) REFERENCES Asignatura(id_asignatura),
  CONSTRAINT UQ_carrera_asig UNIQUE (id_carrera, id_asignatura)
);

CREATE TABLE Comision_Letra
(
  id_comision INT NOT NULL,
  letra CHAR(1) NOT NULL CHECK (letra BETWEEN 'A' AND 'Z'),
  CONSTRAINT PK_comision_letra PRIMARY KEY (id_comision, letra),
  CONSTRAINT FK_comision_letra FOREIGN KEY (id_comision) REFERENCES Comision(id_comision)
);
