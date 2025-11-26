/****************************************************************************************
* NOMBRE:           00_reset_db.sql
* DESCRIPCIÓN:      ELIMINA la base de datos completa para empezar de cero.
* ¡CUIDADO! Esto borra todos los datos y tablas.
****************************************************************************************/
USE master;
GO

-- Si la base de datos existe, la ponemos en modo SINGLE_USER para echar a todos y borrarla
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'SIC_UNNE')
BEGIN
    PRINT 'Eliminando base de datos SIC_UNNE existente...';
    ALTER DATABASE SIC_UNNE SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE SIC_UNNE;
END
GO

PRINT 'Base de datos eliminada. Ahora ejecuta el script 01_schema_creacion.sql';
GO