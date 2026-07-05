-- ==============================================================================
-- 1. CREACIÓN DE ESTRUCTURAS DE TABLAS
-- ==============================================================================

-- Eliminación de tablas si ya existen (para evitar errores en ejecuciones múltiples)
IF OBJECT_ID('Comprobantes', 'U') IS NOT NULL DROP TABLE Comprobantes;
IF OBJECT_ID('Clientes', 'U') IS NOT NULL DROP TABLE Clientes;
IF OBJECT_ID('TiposComprobantes', 'U') IS NOT NULL DROP TABLE TiposComprobantes;
IF OBJECT_ID('TiposDocumentos', 'U') IS NOT NULL DROP TABLE TiposDocumentos;
GO

-- Tabla: Tipos Documentos
CREATE TABLE TiposDocumentos (
    id_tipo_documento INT PRIMARY KEY,
    descrip_documento VARCHAR(50)
);

-- Tabla: Tipos Comprobantes
CREATE TABLE TiposComprobantes (
    id_tipo_comprobante INT PRIMARY KEY,
    descrip_comprobante VARCHAR(50)
);

-- Tabla: Clientes (Incluye el campo "acumulado_compras" solicitado en UAI_TR)
CREATE TABLE Clientes (
    id_cliente INT PRIMARY KEY,
    apellido_nombre VARCHAR(100),
    id_tipo_documento INT,
    nro_documento VARCHAR(20),
    acumulado_compras DECIMAL(18,2) DEFAULT 0,
    FOREIGN KEY (id_tipo_documento) REFERENCES TiposDocumentos(id_tipo_documento)
);

-- Tabla: Comprobantes
CREATE TABLE Comprobantes (
    nro_comprobante INT PRIMARY KEY,
    fecha DATE,
    id_tipo_comprobante INT,
    id_cliente INT,
    importe DECIMAL(18,2),
    FOREIGN KEY (id_tipo_comprobante) REFERENCES TiposComprobantes(id_tipo_comprobante),
    FOREIGN KEY (id_cliente) REFERENCES Clientes(id_cliente)
);
GO

-- ==============================================================================
-- 2. RESOLUCIÓN DE LA ACTIVIDAD: TRIGGER (UAI_TR)
-- ==============================================================================
-- Definición: Actualizar automáticamente el atributo acumulado de compras de 
-- la entidad clientes en cada carga de comprobante.

IF OBJECT_ID('trg_ActualizarAcumulado', 'TR') IS NOT NULL DROP TRIGGER trg_ActualizarAcumulado;
GO

CREATE TRIGGER trg_ActualizarAcumulado
ON Comprobantes
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE c
    SET c.acumulado_compras = ISNULL(c.acumulado_compras, 0) + i.importe
    FROM Clientes c
    INNER JOIN inserted i ON c.id_cliente = i.id_cliente;
END;
GO

-- ==============================================================================
-- 3. CARGA DE DATOS DE EJEMPLO (Extraídos de los CSV)
-- ==============================================================================

INSERT INTO TiposDocumentos (id_tipo_documento, descrip_documento) VALUES 
(1, 'D.N.I.'), (2, 'C.U.I.L.'), (3, 'C.U.I.T.');

INSERT INTO TiposComprobantes (id_tipo_comprobante, descrip_comprobante) VALUES 
(1, 'Factura A'), (6, 'Factura B'), (11, 'Facturas C');

INSERT INTO Clientes (id_cliente, apellido_nombre, id_tipo_documento, nro_documento) VALUES 
(1, 'MAURICIO GARCIA', 3, '20256997991');

-- La inserción de este registro disparará automáticamente el Trigger creado arriba.
-- La fecha "45091" de Excel corresponde aproximadamente al '2023-06-15'.
INSERT INTO Comprobantes (nro_comprobante, fecha, id_tipo_comprobante, id_cliente, importe) VALUES 
(1, '2023-06-15', 1, 1, 7500.00);
INSERT INTO Comprobantes (nro_comprobante, fecha, id_tipo_comprobante, id_cliente, importe) VALUES 
(2, '2024-07-16', 1, 1, 10000.00);
INSERT INTO Comprobantes (nro_comprobante, fecha, id_tipo_comprobante, id_cliente, importe) VALUES 
(3, '2025-08-17', 1, 1, 15000.00);
GO

-- ==============================================================================
-- 4. RESOLUCIÓN DE LA ACTIVIDAD: FUNCIÓN (UAI_FN)
-- ==============================================================================
-- Definición: Función que muestre el comprobante con sus datos originales más 
-- la base imponible del mismo (IVA 21%).

IF OBJECT_ID('fn_ComprobanteBaseImponible', 'IF') IS NOT NULL DROP FUNCTION fn_ComprobanteBaseImponible;
GO

CREATE FUNCTION fn_ComprobanteBaseImponible ()
RETURNS TABLE
AS
RETURN (
    SELECT 
        nro_comprobante,
        fecha,
        id_tipo_comprobante,
        id_cliente,
        importe,
        CAST(importe / 1.21 AS DECIMAL(18,2)) AS base_imponible
    FROM Comprobantes
);
GO

-- ==============================================================================
-- 5. RESOLUCIÓN DE LA ACTIVIDAD: STORED PROCEDURE (UAI_SP)
-- ==============================================================================
-- Definición: SP que muestre el total facturado en un rango de fechas.

IF OBJECT_ID('sp_TotalFacturadoRango', 'P') IS NOT NULL DROP PROCEDURE sp_TotalFacturadoRango;
GO

CREATE PROCEDURE sp_TotalFacturadoRango
    @FechaDesde DATE,
    @FechaHasta DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        ISNULL(SUM(importe), 0) AS TotalFacturado
    FROM Comprobantes
    WHERE fecha BETWEEN @FechaDesde AND @FechaHasta;
END;
GO

-- ==============================================================================
-- 6. RESOLUCIÓN DE LA ACTIVIDAD: VISTA (UAI_VISTA)
-- ==============================================================================
-- Definición: Vista Funcional al modelo (Nro, Fecha, Tipo, Cliente, Importe).

IF OBJECT_ID('vw_ComprobantesVista', 'V') IS NOT NULL DROP VIEW vw_ComprobantesVista;
GO

CREATE VIEW vw_ComprobantesVista
AS
SELECT 
    c.nro_comprobante,
    c.fecha,
    tc.descrip_comprobante AS tipo_comprobante,
    cl.apellido_nombre AS cliente,
    c.importe
FROM Comprobantes c
INNER JOIN TiposComprobantes tc ON c.id_tipo_comprobante = tc.id_tipo_comprobante
INNER JOIN Clientes cl ON c.id_cliente = cl.id_cliente;
GO

-- ==============================================================================
-- 7. RESOLUCIÓN DE LA ACTIVIDAD: ARCHIVO DE TEXTO FIJO (UAI_ARCHIVO)
-- ==============================================================================
-- Definición: Generación de Registro TXT con formato posicional estricto (Longitud: 118)

IF OBJECT_ID('vw_GenerarTXT_REGINFO', 'V') IS NOT NULL DROP VIEW vw_GenerarTXT_REGINFO;
GO

CREATE VIEW vw_GenerarTXT_REGINFO
AS
SELECT 
    -- 1. Fecha (AAAAMMDD) | Pos 1-8 | Cant 8
    FORMAT(c.fecha, 'yyyyMMdd') +
    
    -- 2. Tipo de comprobante | Pos 9-11 | Cant 3 (Completar izq)
    RIGHT('000' + CAST(c.id_tipo_comprobante AS VARCHAR(3)), 3) +
    
    -- 3. Nro Desde | Pos 12-31 | Cant 20 (Completar ceros izq)
    RIGHT(REPLICATE('0', 20) + CAST(c.nro_comprobante AS VARCHAR(20)), 20) +
    
    -- 4. Nro Hasta | Pos 32-51 | Cant 20 (Completar ceros izq)
    RIGHT(REPLICATE('0', 20) + CAST(c.nro_comprobante AS VARCHAR(20)), 20) +
    
    -- 5. Cod Documento | Pos 52-53 | Cant 2 (Completar izq)
    RIGHT('00' + CAST(cl.id_tipo_documento AS VARCHAR(2)), 2) +
    
    -- 6. Nro Documento Comprador | Pos 54-73 | Cant 20 (Completar ceros izq)
    RIGHT(REPLICATE('0', 20) + CAST(cl.nro_documento AS VARCHAR(20)), 20) +
    
    -- 7. Apellido y nombre | Pos 74-103 | Cant 30 (Completar espacios der)
    LEFT(CAST(cl.apellido_nombre AS VARCHAR(30)) + REPLICATE(' ', 30), 30) +
    
    -- 8. Importe (Sin separador, ej: 7500.00 -> 000000000750000) | Pos 104-118 | Cant 15 (Ceros izq)
    RIGHT(REPLICATE('0', 15) + CAST(CAST(c.importe * 100 AS BIGINT) AS VARCHAR(15)), 15)
    
    AS RegistroTXT_118_Caracteres
FROM Comprobantes c
INNER JOIN Clientes cl ON c.id_cliente = cl.id_cliente;
GO

-- ==============================================================================
-- COMPROBACIONES FINALES (Opcional: Ejecutar para ver resultados)
-- ==============================================================================

-- 1. Verificar Trigger (El cliente 1 debería tener 7500.00 en acumulado_compras)
SELECT * FROM Clientes;

-- 2. Verificar Función (Comprobante + Base Imponible)
SELECT * FROM fn_ComprobanteBaseImponible();

-- 3. Verificar Vista Funcional
SELECT * FROM vw_ComprobantesVista;

-- 4. Verificar Salida de Archivo TXT
SELECT * FROM vw_GenerarTXT_REGINFO;

-- 5. Probar Stored Procedure
EXEC sp_TotalFacturadoRango @FechaDesde = '2023-01-01', @FechaHasta = '2026-12-31';
