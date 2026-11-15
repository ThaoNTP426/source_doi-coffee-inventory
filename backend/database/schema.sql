/*
  Schema DOICoffeeDB - dung lai tu cac cau SQL trong backend/routes, services.
  Chay duoc tren Azure SQL Database va SQL Server 2016+.
  Script chi tao bang con thieu (IF OBJECT_ID ... IS NULL), chay lai nhieu lan khong mat du lieu.
*/
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---------- Tai khoan ---------- */
IF OBJECT_ID(N'dbo.TAIKHOAN', N'U') IS NULL
CREATE TABLE dbo.TAIKHOAN (
    maTK          CHAR(7)        NOT NULL CONSTRAINT PK_TAIKHOAN PRIMARY KEY,
    tenDangNhap   NVARCHAR(100)  NOT NULL CONSTRAINT UQ_TAIKHOAN_tenDangNhap UNIQUE,
    matKhauHash   CHAR(64)       NOT NULL,              -- SHA-256 hex (utils/passwordHash.js)
    vaiTro        NVARCHAR(30)   NOT NULL CONSTRAINT DF_TAIKHOAN_vaiTro DEFAULT N'Quản lý',
    email         VARCHAR(50)    NULL
);
GO

/* ---------- Nha cung cap ---------- */
IF OBJECT_ID(N'dbo.NHACUNGCAP', N'U') IS NULL
CREATE TABLE dbo.NHACUNGCAP (
    maNCC         CHAR(7)        NOT NULL CONSTRAINT PK_NHACUNGCAP PRIMARY KEY,   -- NCCxxxx
    tenNCC        NVARCHAR(100)  NOT NULL,
    soDienThoai   CHAR(10)       NOT NULL,
    diaChi        NVARCHAR(200)  NULL,
    email         VARCHAR(50)    NULL,
    trangThaiXoa  BIT            NOT NULL CONSTRAINT DF_NHACUNGCAP_trangThaiXoa DEFAULT 0
);
GO

/* ---------- Nguyen vat lieu ---------- */
IF OBJECT_ID(N'dbo.NGUYENVATLIEU', N'U') IS NULL
CREATE TABLE dbo.NGUYENVATLIEU (
    maNVL           CHAR(7)        NOT NULL CONSTRAINT PK_NGUYENVATLIEU PRIMARY KEY,  -- NVLxxxx
    tenNVL          NVARCHAR(100)  NOT NULL,
    nhomNVL         NVARCHAR(50)   NOT NULL,
    maNCC           CHAR(7)        NOT NULL CONSTRAINT FK_NGUYENVATLIEU_NHACUNGCAP REFERENCES dbo.NHACUNGCAP(maNCC),
    donViTinh       NVARCHAR(20)   NOT NULL,
    donViQuyDoi     NVARCHAR(20)   NULL,
    tyLeQuyDoi      DECIMAL(10, 2) NULL,
    tonHienTai      DECIMAL(14, 4) NOT NULL CONSTRAINT DF_NGUYENVATLIEU_tonHienTai DEFAULT 0,
    mucTonToiThieu  INT            NOT NULL CONSTRAINT DF_NGUYENVATLIEU_mucTonToiThieu DEFAULT 0,
    trangThaiXoa    BIT            NOT NULL CONSTRAINT DF_NGUYENVATLIEU_trangThaiXoa DEFAULT 0,
    CONSTRAINT CK_NGUYENVATLIEU_tonHienTai CHECK (tonHienTai >= 0)
);
GO

/* ---------- Phieu nhap kho ---------- */
IF OBJECT_ID(N'dbo.PHIEUNHAPKHO', N'U') IS NULL
CREATE TABLE dbo.PHIEUNHAPKHO (
    maPhieuNhap   CHAR(7)        NOT NULL CONSTRAINT PK_PHIEUNHAPKHO PRIMARY KEY,  -- PNxxxxx
    maNCC         CHAR(7)        NOT NULL CONSTRAINT FK_PHIEUNHAPKHO_NHACUNGCAP REFERENCES dbo.NHACUNGCAP(maNCC),
    ngayNhap      DATE           NOT NULL,
    tongTien      DECIMAL(11, 2) NOT NULL CONSTRAINT DF_PHIEUNHAPKHO_tongTien DEFAULT 0,
    ghiChu        NVARCHAR(300)  NULL,
    trangThaiXoa  BIT            NOT NULL CONSTRAINT DF_PHIEUNHAPKHO_trangThaiXoa DEFAULT 0
);
GO

-- Mot phieu co the nhap cung NVL nhieu dong (khac han su dung) nen dung khoa tu tang.
IF OBJECT_ID(N'dbo.CHITIETPHIEUNHAP', N'U') IS NULL
CREATE TABLE dbo.CHITIETPHIEUNHAP (
    maChiTiet      INT IDENTITY(1, 1) NOT NULL CONSTRAINT PK_CHITIETPHIEUNHAP PRIMARY KEY,
    maPhieuNhap    CHAR(7)        NOT NULL CONSTRAINT FK_CHITIETPHIEUNHAP_PHIEUNHAPKHO REFERENCES dbo.PHIEUNHAPKHO(maPhieuNhap),
    maNVL          CHAR(7)        NOT NULL CONSTRAINT FK_CHITIETPHIEUNHAP_NGUYENVATLIEU REFERENCES dbo.NGUYENVATLIEU(maNVL),
    soLuong        DECIMAL(14, 4) NOT NULL,
    soLuongConLai  DECIMAL(14, 4) NOT NULL,
    donGia         DECIMAL(9, 2)  NOT NULL,
    hanSuDung      DATE           NULL,
    thanhTien      AS CAST(soLuong * donGia AS DECIMAL(18, 2)) PERSISTED
);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_CHITIETPHIEUNHAP_maPhieuNhap')
    CREATE INDEX IX_CHITIETPHIEUNHAP_maPhieuNhap ON dbo.CHITIETPHIEUNHAP(maPhieuNhap);
GO

/* ---------- Mon & cong thuc ---------- */
IF OBJECT_ID(N'dbo.MON', N'U') IS NULL
CREATE TABLE dbo.MON (
    maMon         CHAR(7)        NOT NULL CONSTRAINT PK_MON PRIMARY KEY,  -- MONxxxx
    tenMon        NVARCHAR(200)  NOT NULL,
    nhomMon       NVARCHAR(100)  NOT NULL,
    loaiCongThuc  NVARCHAR(50)   NOT NULL CONSTRAINT DF_MON_loaiCongThuc DEFAULT N'Món chính',
    donViTinh     NVARCHAR(50)   NOT NULL,
    trangThai     NVARCHAR(30)   NOT NULL CONSTRAINT DF_MON_trangThai DEFAULT N'Đang kinh doanh'
);
GO

IF OBJECT_ID(N'dbo.CONGTHUCMON', N'U') IS NULL
CREATE TABLE dbo.CONGTHUCMON (
    maMon         CHAR(7)        NOT NULL CONSTRAINT FK_CONGTHUCMON_MON REFERENCES dbo.MON(maMon),
    maNVL         CHAR(7)        NOT NULL CONSTRAINT FK_CONGTHUCMON_NGUYENVATLIEU REFERENCES dbo.NGUYENVATLIEU(maNVL),
    dinhLuong     DECIMAL(10, 3) NOT NULL,
    ghiChuPhaChe  NVARCHAR(1000) NULL,
    CONSTRAINT PK_CONGTHUCMON PRIMARY KEY (maMon, maNVL)
);
GO

/* ---------- Lich su ton kho ---------- */
IF OBJECT_ID(N'dbo.LICHSUTONKHO', N'U') IS NULL
CREATE TABLE dbo.LICHSUTONKHO (
    maLichSu        BIGINT IDENTITY(1, 1) NOT NULL CONSTRAINT PK_LICHSUTONKHO PRIMARY KEY,
    maNVL           CHAR(7)        NOT NULL CONSTRAINT FK_LICHSUTONKHO_NGUYENVATLIEU REFERENCES dbo.NGUYENVATLIEU(maNVL),
    loaiBienDong    NVARCHAR(30)   NOT NULL,
    nguonTacDong    NVARCHAR(50)   NOT NULL,
    soLuongThayDoi  DECIMAL(14, 4) NOT NULL,
    tonTruoc        DECIMAL(14, 4) NOT NULL,
    tonSau          DECIMAL(14, 4) NOT NULL,
    thoiGian        DATETIME       NOT NULL CONSTRAINT DF_LICHSUTONKHO_thoiGian DEFAULT GETDATE(),
    maThamChieu     VARCHAR(20)    NULL,
    ghiChu          NVARCHAR(1000) NULL,
    trangThai       NVARCHAR(20)   NOT NULL CONSTRAINT DF_LICHSUTONKHO_trangThai DEFAULT N'Hợp lệ',
    thoiGianXoa     DATETIME       NULL,
    nguoiXoa        CHAR(7)        NULL,
    maLichSuGoc     BIGINT         NULL CONSTRAINT FK_LICHSUTONKHO_goc REFERENCES dbo.LICHSUTONKHO(maLichSu)
);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_LICHSUTONKHO_maThamChieu')
    CREATE INDEX IX_LICHSUTONKHO_maThamChieu ON dbo.LICHSUTONKHO(maThamChieu, nguonTacDong);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_LICHSUTONKHO_maNVL_thoiGian')
    CREATE INDEX IX_LICHSUTONKHO_maNVL_thoiGian ON dbo.LICHSUTONKHO(maNVL, thoiGian);
GO

/* ---------- Phieu hao hut ---------- */
IF OBJECT_ID(N'dbo.PHIEUHAOHUT', N'U') IS NULL
CREATE TABLE dbo.PHIEUHAOHUT (
    maPhieuHaoHut  CHAR(7)        NOT NULL CONSTRAINT PK_PHIEUHAOHUT PRIMARY KEY,  -- HHxxxxx
    ngayLap        DATETIME       NOT NULL CONSTRAINT DF_PHIEUHAOHUT_ngayLap DEFAULT GETDATE(),
    ngayHaoHut     DATE           NOT NULL,
    lyDo           NVARCHAR(200)  NOT NULL,
    ghiChu         NVARCHAR(600)  NULL,
    trangThai      NVARCHAR(20)   NOT NULL CONSTRAINT DF_PHIEUHAOHUT_trangThai DEFAULT N'Hoàn thành'
);
GO

IF OBJECT_ID(N'dbo.CHITIETPHIEUHAOHUT', N'U') IS NULL
CREATE TABLE dbo.CHITIETPHIEUHAOHUT (
    maPhieuHaoHut  CHAR(7)        NOT NULL CONSTRAINT FK_CHITIETPHIEUHAOHUT_PHIEUHAOHUT REFERENCES dbo.PHIEUHAOHUT(maPhieuHaoHut),
    maNVL          CHAR(7)        NOT NULL CONSTRAINT FK_CHITIETPHIEUHAOHUT_NGUYENVATLIEU REFERENCES dbo.NGUYENVATLIEU(maNVL),
    soLuong        DECIMAL(8, 2)  NOT NULL,
    CONSTRAINT PK_CHITIETPHIEUHAOHUT PRIMARY KEY (maPhieuHaoHut, maNVL)
);
GO

IF OBJECT_ID(N'dbo.LICHSUCHINHSUAPHIEUHAOHUT', N'U') IS NULL
CREATE TABLE dbo.LICHSUCHINHSUAPHIEUHAOHUT (
    maLichSuSua    INT IDENTITY(1, 1) NOT NULL CONSTRAINT PK_LICHSUCHINHSUAPHIEUHAOHUT PRIMARY KEY,
    maPhieuHaoHut  CHAR(7)        NOT NULL CONSTRAINT FK_LSCSPHH_PHIEUHAOHUT REFERENCES dbo.PHIEUHAOHUT(maPhieuHaoHut),
    truongDuocSua  NVARCHAR(100)  NOT NULL,
    giaTriCu       NVARCHAR(1000) NULL,
    giaTriMoi      NVARCHAR(1000) NULL,
    nguoiSua       NVARCHAR(100)  NULL,   -- maTK hoac ten nguoi sua
    thoiGianSua    DATETIME       NOT NULL CONSTRAINT DF_LSCSPHH_thoiGianSua DEFAULT GETDATE()
);
GO
