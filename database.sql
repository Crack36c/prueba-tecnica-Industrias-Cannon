-- ============================================================
-- PRUEBA TÉCNICA – EMPAQUE DE CAJAS
-- Base de datos: SQL Server
-- ============================================================

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'EmpaqueDB')
BEGIN
    CREATE DATABASE EmpaqueDB;
END
GO

USE EmpaqueDB;
GO

SET QUOTED_IDENTIFIER ON;
GO

-- ============================================================
-- TABLA: Boxes (Cajas)
-- ============================================================
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Boxes' AND xtype='U')
BEGIN
    CREATE TABLE Boxes (
        BoxId       INT             NOT NULL IDENTITY(1,1) PRIMARY KEY,
        BoxCode     NVARCHAR(50)    NOT NULL,
        ProductCode NVARCHAR(50)    NOT NULL,
        Capacity    INT             NOT NULL,
        Status      NVARCHAR(10)    NOT NULL DEFAULT 'OPEN',   -- OPEN | CLOSED
        IsActive    BIT             NOT NULL DEFAULT 1,

        CONSTRAINT CK_Boxes_Capacity CHECK (Capacity > 0),
        CONSTRAINT CK_Boxes_Status   CHECK (Status IN ('OPEN', 'CLOSED'))
    );

    CREATE UNIQUE INDEX UIX_Boxes_BoxCode ON Boxes(BoxCode) WHERE IsActive = 1;
END
GO

-- ============================================================
-- TABLA: Towels (Unidades / Items)
-- ============================================================
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Towels' AND xtype='U')
BEGIN
    CREATE TABLE Towels (
        TowelId     INT             NOT NULL IDENTITY(1,1) PRIMARY KEY,
        ItemCode    NVARCHAR(50)    NOT NULL,
        ProductCode NVARCHAR(50)    NOT NULL,
        Status      NVARCHAR(10)    NOT NULL DEFAULT 'LOOSE',  -- LOOSE | PACKED
        BoxId       INT             NULL,
        IsActive    BIT             NOT NULL DEFAULT 1,

        CONSTRAINT FK_Towels_Boxes FOREIGN KEY (BoxId) REFERENCES Boxes(BoxId),
        CONSTRAINT CK_Towels_Status CHECK (Status IN ('LOOSE', 'PACKED'))
    );

    CREATE UNIQUE INDEX UIX_Towels_ItemCode ON Towels(ItemCode) WHERE IsActive = 1;
END
GO

-- ============================================================
-- SP: sp_GetActiveTowels
-- ============================================================
IF OBJECT_ID('sp_GetActiveTowels', 'P') IS NOT NULL DROP PROCEDURE sp_GetActiveTowels;
GO
CREATE PROCEDURE sp_GetActiveTowels
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TowelId, ItemCode, ProductCode, Status, BoxId
    FROM   Towels
    WHERE  IsActive = 1;
END
GO

-- ============================================================
-- SP: sp_CreateTowel
-- ============================================================
IF OBJECT_ID('sp_CreateTowel', 'P') IS NOT NULL DROP PROCEDURE sp_CreateTowel;
GO
CREATE PROCEDURE sp_CreateTowel
    @ItemCode      NVARCHAR(50),
    @ProductCode   NVARCHAR(50),
    @NewTowelId    INT              OUTPUT,
    @ErrorMessage  NVARCHAR(500)    OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorMessage = NULL;
    SET @NewTowelId   = NULL;

    IF @ItemCode IS NULL OR LEN(TRIM(@ItemCode)) = 0
    BEGIN
        SET @ErrorMessage = 'ItemCode es requerido.';
        RETURN;
    END

    IF @ProductCode IS NULL OR LEN(TRIM(@ProductCode)) = 0
    BEGIN
        SET @ErrorMessage = 'ProductCode es requerido.';
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM Towels WHERE ItemCode = @ItemCode AND IsActive = 1)
    BEGIN
        SET @ErrorMessage = 'Ya existe una unidad activa con ItemCode ''' + @ItemCode + '''.';
        RETURN;
    END

    INSERT INTO Towels (ItemCode, ProductCode, Status, IsActive)
    VALUES (@ItemCode, @ProductCode, 'LOOSE', 1);

    SET @NewTowelId = SCOPE_IDENTITY();
END
GO

-- ============================================================
-- SP: sp_DisableTowel
-- ============================================================
IF OBJECT_ID('sp_DisableTowel', 'P') IS NOT NULL DROP PROCEDURE sp_DisableTowel;
GO
CREATE PROCEDURE sp_DisableTowel
    @TowelId       INT,
    @ErrorMessage  NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorMessage = NULL;

    DECLARE @Status   NVARCHAR(10);
    DECLARE @IsActive BIT;

    SELECT @Status = Status, @IsActive = IsActive
    FROM   Towels
    WHERE  TowelId = @TowelId;

    IF @IsActive IS NULL OR @IsActive = 0
    BEGIN
        SET @ErrorMessage = 'Unidad no encontrada o ya está deshabilitada.';
        RETURN;
    END

    IF @Status = 'PACKED'
    BEGIN
        SET @ErrorMessage = 'No se puede deshabilitar una unidad empacada. Sáquela de la caja primero.';
        RETURN;
    END

    UPDATE Towels SET IsActive = 0 WHERE TowelId = @TowelId;
END
GO

-- ============================================================
-- SP: sp_GetActiveBoxes
-- ============================================================
IF OBJECT_ID('sp_GetActiveBoxes', 'P') IS NOT NULL DROP PROCEDURE sp_GetActiveBoxes;
GO
CREATE PROCEDURE sp_GetActiveBoxes
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        b.BoxId,
        b.BoxCode,
        b.ProductCode,
        b.Capacity,
        COUNT(CASE WHEN t.IsActive = 1 AND t.Status = 'PACKED' THEN 1 END) AS CurrentCount,
        b.Status
    FROM  Boxes b
    LEFT JOIN Towels t ON t.BoxId = b.BoxId
    WHERE b.IsActive = 1
    GROUP BY b.BoxId, b.BoxCode, b.ProductCode, b.Capacity, b.Status;
END
GO

-- ============================================================
-- SP: sp_CreateBox
-- ============================================================
IF OBJECT_ID('sp_CreateBox', 'P') IS NOT NULL DROP PROCEDURE sp_CreateBox;
GO
CREATE PROCEDURE sp_CreateBox
    @BoxCode       NVARCHAR(50),
    @ProductCode   NVARCHAR(50),
    @Capacity      INT,
    @NewBoxId      INT              OUTPUT,
    @ErrorMessage  NVARCHAR(500)    OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorMessage = NULL;
    SET @NewBoxId     = NULL;

    IF @BoxCode IS NULL OR LEN(TRIM(@BoxCode)) = 0
    BEGIN
        SET @ErrorMessage = 'BoxCode es requerido.';
        RETURN;
    END

    IF @ProductCode IS NULL OR LEN(TRIM(@ProductCode)) = 0
    BEGIN
        SET @ErrorMessage = 'ProductCode es requerido.';
        RETURN;
    END

    IF @Capacity IS NULL OR @Capacity <= 0
    BEGIN
        SET @ErrorMessage = 'Capacity debe ser mayor a 0.';
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM Boxes WHERE BoxCode = @BoxCode AND IsActive = 1)
    BEGIN
        SET @ErrorMessage = 'Ya existe una caja activa con BoxCode ''' + @BoxCode + '''.';
        RETURN;
    END

    INSERT INTO Boxes (BoxCode, ProductCode, Capacity, Status, IsActive)
    VALUES (@BoxCode, @ProductCode, @Capacity, 'OPEN', 1);

    SET @NewBoxId = SCOPE_IDENTITY();
END
GO

-- ============================================================
-- SP: sp_DisableBox
-- ============================================================
IF OBJECT_ID('sp_DisableBox', 'P') IS NOT NULL DROP PROCEDURE sp_DisableBox;
GO
CREATE PROCEDURE sp_DisableBox
    @BoxId         INT,
    @ErrorMessage  NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorMessage = NULL;

    DECLARE @IsActive    BIT;
    DECLARE @CurrentCount INT;

    SELECT @IsActive = IsActive FROM Boxes WHERE BoxId = @BoxId;

    IF @IsActive IS NULL OR @IsActive = 0
    BEGIN
        SET @ErrorMessage = 'Caja no encontrada o ya está deshabilitada.';
        RETURN;
    END

    SELECT @CurrentCount = COUNT(*)
    FROM   Towels
    WHERE  BoxId = @BoxId AND IsActive = 1 AND Status = 'PACKED';

    IF @CurrentCount > 0
    BEGIN
        SET @ErrorMessage = 'No se puede deshabilitar una caja con unidades empacadas.';
        RETURN;
    END

    UPDATE Boxes SET IsActive = 0 WHERE BoxId = @BoxId;
END
GO

-- ============================================================
-- SP: sp_PackTowel
-- ============================================================
IF OBJECT_ID('sp_PackTowel', 'P') IS NOT NULL DROP PROCEDURE sp_PackTowel;
GO
CREATE PROCEDURE sp_PackTowel
    @BoxId         INT,
    @TowelId       INT,
    @ErrorMessage  NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorMessage = NULL;

    DECLARE @BoxIsActive    BIT;
    DECLARE @BoxStatus      NVARCHAR(10);
    DECLARE @BoxProductCode NVARCHAR(50);
    DECLARE @BoxCapacity    INT;
    DECLARE @CurrentCount   INT;

    DECLARE @TowelIsActive    BIT;
    DECLARE @TowelStatus      NVARCHAR(10);
    DECLARE @TowelProductCode NVARCHAR(50);

    -- Validar caja
    SELECT @BoxIsActive    = IsActive,
           @BoxStatus      = Status,
           @BoxProductCode = ProductCode,
           @BoxCapacity    = Capacity
    FROM   Boxes
    WHERE  BoxId = @BoxId;

    IF @BoxIsActive IS NULL OR @BoxIsActive = 0
    BEGIN
        SET @ErrorMessage = 'Caja no encontrada.';
        RETURN;
    END

    IF @BoxStatus != 'OPEN'
    BEGIN
        SET @ErrorMessage = 'La caja debe estar en estado OPEN para empacar.';
        RETURN;
    END

    -- Validar item
    SELECT @TowelIsActive    = IsActive,
           @TowelStatus      = Status,
           @TowelProductCode = ProductCode
    FROM   Towels
    WHERE  TowelId = @TowelId;

    IF @TowelIsActive IS NULL OR @TowelIsActive = 0
    BEGIN
        SET @ErrorMessage = 'Unidad no encontrada.';
        RETURN;
    END

    IF @TowelStatus != 'LOOSE'
    BEGIN
        SET @ErrorMessage = 'La unidad debe estar en estado LOOSE para empacar.';
        RETURN;
    END

    IF @TowelProductCode != @BoxProductCode
    BEGIN
        SET @ErrorMessage = 'El ProductCode de la unidad (''' + @TowelProductCode + ''') no coincide con el de la caja (''' + @BoxProductCode + ''').';
        RETURN;
    END

    -- Validar capacidad
    SELECT @CurrentCount = COUNT(*)
    FROM   Towels
    WHERE  BoxId = @BoxId AND IsActive = 1 AND Status = 'PACKED';

    IF @CurrentCount >= @BoxCapacity
    BEGIN
        SET @ErrorMessage = 'Capacidad completa. La caja tiene ' + CAST(@CurrentCount AS NVARCHAR) + '/' + CAST(@BoxCapacity AS NVARCHAR) + ' unidades.';
        RETURN;
    END

    UPDATE Towels SET Status = 'PACKED', BoxId = @BoxId WHERE TowelId = @TowelId;
END
GO

-- ============================================================
-- SP: sp_UnpackTowel
-- ============================================================
IF OBJECT_ID('sp_UnpackTowel', 'P') IS NOT NULL DROP PROCEDURE sp_UnpackTowel;
GO
CREATE PROCEDURE sp_UnpackTowel
    @BoxId         INT,
    @TowelId       INT,
    @ErrorMessage  NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorMessage = NULL;

    DECLARE @BoxIsActive  BIT;
    DECLARE @BoxStatus    NVARCHAR(10);
    DECLARE @TowelStatus  NVARCHAR(10);
    DECLARE @TowelBoxId   INT;
    DECLARE @TowelActive  BIT;

    SELECT @BoxIsActive = IsActive, @BoxStatus = Status
    FROM   Boxes
    WHERE  BoxId = @BoxId;

    IF @BoxIsActive IS NULL OR @BoxIsActive = 0
    BEGIN
        SET @ErrorMessage = 'Caja no encontrada.';
        RETURN;
    END

    IF @BoxStatus != 'OPEN'
    BEGIN
        SET @ErrorMessage = 'La caja debe estar en estado OPEN para sacar unidades.';
        RETURN;
    END

    SELECT @TowelActive = IsActive, @TowelStatus = Status, @TowelBoxId = BoxId
    FROM   Towels
    WHERE  TowelId = @TowelId;

    IF @TowelActive IS NULL OR @TowelActive = 0
    BEGIN
        SET @ErrorMessage = 'Unidad no encontrada.';
        RETURN;
    END

    IF @TowelStatus != 'PACKED' OR @TowelBoxId != @BoxId
    BEGIN
        SET @ErrorMessage = 'La unidad no está empacada en esta caja.';
        RETURN;
    END

    UPDATE Towels SET Status = 'LOOSE', BoxId = NULL WHERE TowelId = @TowelId;
END
GO

-- ============================================================
-- SP: sp_CloseBox
-- ============================================================
IF OBJECT_ID('sp_CloseBox', 'P') IS NOT NULL DROP PROCEDURE sp_CloseBox;
GO
CREATE PROCEDURE sp_CloseBox
    @BoxId         INT,
    @ErrorMessage  NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @ErrorMessage = NULL;

    DECLARE @IsActive BIT;
    DECLARE @Status   NVARCHAR(10);

    SELECT @IsActive = IsActive, @Status = Status
    FROM   Boxes
    WHERE  BoxId = @BoxId;

    IF @IsActive IS NULL OR @IsActive = 0
    BEGIN
        SET @ErrorMessage = 'Caja no encontrada.';
        RETURN;
    END

    IF @Status != 'OPEN'
    BEGIN
        SET @ErrorMessage = 'La caja ya está cerrada.';
        RETURN;
    END

    UPDATE Boxes SET Status = 'CLOSED' WHERE BoxId = @BoxId;
END
GO
