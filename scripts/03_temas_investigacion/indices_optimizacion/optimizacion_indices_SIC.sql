/****************************************************************************************
* PROYECTO:         SIC-UNNE (Tarea de Investigación de Índices)
* FECHA:            14/11/2025
* OBJETIVO:
* Demostrar el impacto real de un índice no agrupado (Nonclustered Index) sobre una
* consulta representativa del proceso de "matchmaking" del proyecto SIC-UNNE.
*
* Este script compara: 
*    - Rendimiento SIN índice (Table Scan / Clustered Index Scan)
*    - Rendimiento CON índice (Index Seek + Covering Index)
*
* El entorno se construye desde cero para garantizar reproducibilidad académica.
****************************************************************************************/

-----------------------------------------------
-- 1. CREACIÓN DEL ENTORNO DE PRUEBA
-----------------------------------------------
IF DB_ID('Tarea_Indices_SIC') IS NOT NULL
    DROP DATABASE Tarea_Indices_SIC;
GO

CREATE DATABASE Tarea_Indices_SIC;
GO
USE Tarea_Indices_SIC;
GO

-- Tabla simplificada basada en la real Lista_Espera
CREATE TABLE Lista_Espera_Demo (
    id_lista_espera INT IDENTITY(1,1),
    id_usuario INT NOT NULL,
    id_comision_origen INT NOT NULL,
    id_comision_destino INT NOT NULL,
    estado NVARCHAR(50) NOT NULL,
    fecha_alta DATETIME NOT NULL,

    -- Índice agrupado por defecto en la PK
    CONSTRAINT PK_Lista_Espera_Demo PRIMARY KEY CLUSTERED (id_lista_espera)
);
GO

-----------------------------------------------
-- 2. CARGA MASIVA DE DATOS (100,000 filas)
-----------------------------------------------
PRINT 'Iniciando carga masiva de 100,000 registros...';
SET NOCOUNT ON;

DECLARE @i INT = 1;
DECLARE @totalComisiones INT = 50;

BEGIN TRAN
    WHILE @i <= 100000
    BEGIN
        INSERT INTO Lista_Espera_Demo (
            id_usuario, id_comision_origen, id_comision_destino,
            estado, fecha_alta
        )
        VALUES (
            @i,
            (RAND() * @totalComisiones) + 1,
            (RAND() * @totalComisiones) + 1,
            'En espera',
            GETDATE()
        );

        SET @i = @i + 1;
    END
COMMIT TRAN;

SET NOCOUNT OFF;
PRINT 'Carga masiva finalizada.';
GO

-----------------------------------------------
-- 3. PRUEBA 1: CONSULTA SIN ÍNDICE (ESCENARIO BASE)
-----------------------------------------------
PRINT '--------------------------------------------------';
PRINT 'PRUEBA 1: Consultando SIN índice no agrupado';
PRINT 'Active el plan de ejecución y observe el Table/Clustered Index Scan.';
PRINT '--------------------------------------------------';

-- Limpiar el caché: garantiza mediciones justas
DBCC DROPCLEANBUFFERS;
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;

SELECT TOP (1) id_usuario, fecha_alta
FROM Lista_Espera_Demo
WHERE estado = 'En espera'
  AND id_comision_origen = 20
  AND id_comision_destino = 10
ORDER BY fecha_alta;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-----------------------------------------------
-- 4. CREACIÓN DEL ÍNDICE OPTIMIZADO
-----------------------------------------------
PRINT 'Creando IX_ListaEspera_Matchmaking...';

CREATE NONCLUSTERED INDEX IX_ListaEspera_Matchmaking
ON Lista_Espera_Demo (estado, id_comision_origen, id_comision_destino)
INCLUDE (id_usuario, fecha_alta);  -- Índice de cobertura

GO

-----------------------------------------------
-- 5. PRUEBA 2: CONSULTA CON ÍNDICE
-----------------------------------------------
PRINT '--------------------------------------------------';
PRINT 'PRUEBA 2: Consultando CON el índice no agrupado';
PRINT 'Observe el Index Seek y compare tiempos y lecturas.';
PRINT '--------------------------------------------------';

DBCC DROPCLEANBUFFERS;
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;

SELECT TOP (1) id_usuario, fecha_alta
FROM Lista_Espera_Demo
WHERE estado = 'En espera'
  AND id_comision_origen = 20
  AND id_comision_destino = 10
ORDER BY fecha_alta;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-----------------------------------------------
-- 6. LIMPIEZA DEL ENTORNO
-----------------------------------------------
PRINT 'Prueba finalizada. Eliminando base de datos de test...';

USE master;
GO
DROP DATABASE Tarea_Indices_SIC;
GO
