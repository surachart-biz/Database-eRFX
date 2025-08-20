-- =============================================
-- E-RFQ System Complete Database Schema v3.0
-- Database: erfq_system
-- PostgreSQL Version: 14+
-- Character Set: UTF8
-- Last Updated: January 2025
-- =============================================

-- =============================================
-- DATABASE CONFIGURATION
-- =============================================
CREATE DATABASE erfq_system
  WITH
  OWNER = postgres
  ENCODING = 'UTF8'
  LC_COLLATE = 'en_US.UTF-8'
  LC_CTYPE = 'en_US.UTF-8'
  TABLESPACE = pg_default
  CONNECTION LIMIT = -1;

-- Enable Required Extensions
\c erfq_system;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";    -- สำหรับ generate UUID
CREATE EXTENSION IF NOT EXISTS "pgcrypto";     -- สำหรับ encryption

-- =============================================
-- SECTION 1: MASTER DATA & LOOKUPS
-- ตารางหลักสำหรับข้อมูลอ้างอิงพื้นฐานของระบบ
-- =============================================

-- 1.1 Currencies Table
-- ตาราง: เก็บข้อมูลสกุลเงินที่ใช้ในระบบ
CREATE TABLE Currencies (
  Id BIGSERIAL PRIMARY KEY,
  CurrencyCode VARCHAR(3) UNIQUE NOT NULL,     -- รหัสสกุลเงิน 3 ตัว (USD, THB, EUR)
  CurrencyName VARCHAR(100) NOT NULL,          -- ชื่อสกุลเงิน
  CurrencySymbol VARCHAR(10),                  -- สัญลักษณ์ ($, ฿, €)
  DecimalPlaces SMALLINT DEFAULT 2,            -- จำนวนทศนิยม
  IsActive BOOLEAN DEFAULT TRUE,               -- สถานะการใช้งาน
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UpdatedAt TIMESTAMP,
  
  CONSTRAINT chk_currency_code CHECK (LENGTH(CurrencyCode) = 3),
  CONSTRAINT chk_decimal_places CHECK (DecimalPlaces BETWEEN 0 AND 4)
);
CREATE INDEX idx_currencies_code ON Currencies(CurrencyCode) WHERE IsActive = TRUE;

-- 1.2 Countries Table
-- ตาราง: เก็บข้อมูลประเทศ
CREATE TABLE Countries (
  Id BIGSERIAL PRIMARY KEY,
  CountryCode VARCHAR(2) UNIQUE NOT NULL,      -- รหัสประเทศ 2 ตัว (TH, US, JP)
  CountryNameEn VARCHAR(100) NOT NULL,         -- ชื่อประเทศภาษาอังกฤษ
  CountryNameTh VARCHAR(100),                  -- ชื่อประเทศภาษาไทย
  DefaultCurrencyId BIGINT REFERENCES Currencies(Id),  -- สกุลเงินหลัก
  Timezone VARCHAR(50) DEFAULT 'Asia/Bangkok', -- โซนเวลา
  PhoneCode VARCHAR(5),                        -- รหัสโทรศัพท์ (+66, +1)
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT chk_country_code CHECK (LENGTH(CountryCode) = 2)
);
CREATE INDEX idx_countries_code ON Countries(CountryCode) WHERE IsActive = TRUE;

-- 1.3 Business Types
-- ตาราง: ประเภทธุรกิจ (บุคคลธรรมดา, นิติบุคคล)
CREATE TABLE BusinessTypes (
  Id SMALLINT PRIMARY KEY,
  Code VARCHAR(20) UNIQUE NOT NULL,            -- รหัสประเภท (INDIVIDUAL, CORPORATE)
  NameTh VARCHAR(50) NOT NULL,                 -- ชื่อภาษาไทย
  NameEn VARCHAR(50),                          -- ชื่อภาษาอังกฤษ
  SortOrder SMALLINT,                          -- ลำดับการแสดงผล
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 1.4 Job Types
-- ตาราง: ประเภทงาน (ซื้อ, ขาย, ทั้งซื้อและขาย)
CREATE TABLE JobTypes (
  Id SMALLINT PRIMARY KEY,
  Code VARCHAR(20) UNIQUE NOT NULL,            -- รหัส (BUY, SELL, BOTH)
  NameTh VARCHAR(50) NOT NULL,                 -- ชื่อภาษาไทย
  NameEn VARCHAR(50),                          -- ชื่อภาษาอังกฤษ
  ForSupplier BOOLEAN DEFAULT TRUE,            -- ใช้กับ Supplier ได้
  ForRfq BOOLEAN DEFAULT TRUE,                 -- ใช้กับ RFQ ได้
  PriceComparisonRule VARCHAR(10),             -- กฎการเปรียบเทียบราคา (MIN, MAX)
  SortOrder SMALLINT,
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 1.5 Roles
-- ตาราง: บทบาทผู้ใช้งานในระบบ
CREATE TABLE Roles (
  Id BIGSERIAL PRIMARY KEY,
  RoleCode VARCHAR(30) UNIQUE NOT NULL,        -- รหัสบทบาท
  RoleName VARCHAR(100) NOT NULL,              -- ชื่อบทบาทภาษาอังกฤษ
  RoleNameTh VARCHAR(100),                     -- ชื่อบทบาทภาษาไทย
  RoleLevel SMALLINT,                          -- ระดับบทบาท (สำหรับ hierarchy)
  Description TEXT,                            -- คำอธิบาย
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT chk_role_code CHECK (RoleCode IN 
    ('SUPER_ADMIN','ADMIN','REQUESTER','APPROVER','PURCHASING','PURCHASING_APPROVER',
     'SUPPLIER','MANAGING_DIRECTOR'))
);

-- 1.6 Permissions
-- ตาราง: สิทธิ์การใช้งานในระบบ
CREATE TABLE Permissions (
  Id BIGSERIAL PRIMARY KEY,
  PermissionCode VARCHAR(50) UNIQUE NOT NULL,  -- รหัสสิทธิ์
  PermissionName VARCHAR(100) NOT NULL,        -- ชื่อสิทธิ์
  PermissionNameTh VARCHAR(100),               -- ชื่อสิทธิ์ภาษาไทย
  Module VARCHAR(50),                          -- โมดูลที่เกี่ยวข้อง
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 1.7 Role Permissions Mapping
-- ตาราง: ความสัมพันธ์ระหว่างบทบาทและสิทธิ์
CREATE TABLE RolePermissions (
  Id BIGSERIAL PRIMARY KEY,
  RoleId BIGINT NOT NULL REFERENCES Roles(Id),
  PermissionId BIGINT NOT NULL REFERENCES Permissions(Id),
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CreatedBy BIGINT,
  
  UNIQUE(RoleId, PermissionId)
);

-- 1.8 Categories
-- ตาราง: หมวดหมู่สินค้า/บริการ
CREATE TABLE Categories (
  Id BIGSERIAL PRIMARY KEY,
  CategoryCode VARCHAR(50) UNIQUE NOT NULL,    -- รหัสหมวดหมู่
  CategoryNameTh VARCHAR(200) NOT NULL,        -- ชื่อหมวดหมู่ภาษาไทย
  CategoryNameEn VARCHAR(200),                 -- ชื่อหมวดหมู่ภาษาอังกฤษ
  Description TEXT,                            -- รายละเอียด
  SortOrder INT,                               -- ลำดับการแสดงผล
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UpdatedAt TIMESTAMP
);
CREATE INDEX idx_categories_active ON Categories(Id) WHERE IsActive = TRUE;

-- 1.9 Subcategories
-- ตาราง: หมวดหมู่ย่อย
CREATE TABLE Subcategories (
  Id BIGSERIAL PRIMARY KEY,
  CategoryId BIGINT NOT NULL REFERENCES Categories(Id),
  SubcategoryCode VARCHAR(50) NOT NULL,        -- รหัสหมวดหมู่ย่อย
  SubcategoryNameTh VARCHAR(200) NOT NULL,     -- ชื่อหมวดหมู่ย่อยภาษาไทย
  SubcategoryNameEn VARCHAR(200),              -- ชื่อหมวดหมู่ย่อยภาษาอังกฤษ
  IsUseSerialNumber BOOLEAN DEFAULT FALSE,     -- ใช้ Serial Number หรือไม่
  Duration INT DEFAULT 7,                      -- ระยะเวลาตอบกลับ (วัน)
  Description TEXT,
  SortOrder INT,
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UpdatedAt TIMESTAMP,
  
  UNIQUE(CategoryId, SubcategoryCode)
);
CREATE INDEX idx_subcategories_category ON Subcategories(CategoryId) WHERE IsActive = TRUE;

-- 1.10 Subcategory Document Requirements
-- ตาราง: เอกสารที่ต้องแนบตามหมวดหมู่ย่อย
CREATE TABLE SubcategoryDocRequirements (
  Id BIGSERIAL PRIMARY KEY,
  SubcategoryId BIGINT NOT NULL REFERENCES Subcategories(Id),
  DocumentName VARCHAR(200) NOT NULL,          -- ชื่อเอกสาร
  DocumentNameEn VARCHAR(200),                 -- ชื่อเอกสารภาษาอังกฤษ
  IsRequired BOOLEAN DEFAULT TRUE,             -- บังคับแนบหรือไม่
  MaxFileSize INT DEFAULT 30,                  -- ขนาดไฟล์สูงสุด (MB)
  AllowedExtensions TEXT,                      -- นามสกุลที่อนุญาต (pdf,doc,xlsx)
  SortOrder INT,
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 1.11 Incoterms
-- ตาราง: เงื่อนไขการส่งมอบสินค้าระหว่างประเทศ
CREATE TABLE Incoterms (
  Id BIGSERIAL PRIMARY KEY,
  IncotermCode VARCHAR(3) UNIQUE NOT NULL,     -- รหัส (FOB, CIF, EXW)
  IncotermName VARCHAR(100) NOT NULL,          -- ชื่อเต็ม
  Description TEXT,                            -- คำอธิบาย
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- SECTION 2: COMPANY & ORGANIZATION STRUCTURE
-- ตารางโครงสร้างองค์กรและบริษัท
-- =============================================

-- 2.1 Companies
-- ตาราง: ข้อมูลบริษัทในระบบ (Multi-Company Support)
CREATE TABLE Companies (
  Id BIGSERIAL PRIMARY KEY,
  CompanyCode VARCHAR(20) UNIQUE NOT NULL,     -- รหัสบริษัท
  CompanyNameTh VARCHAR(150),                  -- ชื่อบริษัทภาษาไทย
  CompanyNameEn VARCHAR(150),                  -- ชื่อบริษัทภาษาอังกฤษ
  ShortNameEn VARCHAR(10) NOT NULL UNIQUE,     -- ชื่อย่อ (ใช้สร้างเลข RFQ)
  TaxId VARCHAR(20) UNIQUE,                    -- เลขประจำตัวผู้เสียภาษี
  
  -- Location & Currency
  CountryId BIGINT NOT NULL REFERENCES Countries(Id),
  DefaultCurrencyId BIGINT NOT NULL REFERENCES Currencies(Id),
  
  -- Business Information
  BusinessTypeId SMALLINT REFERENCES BusinessTypes(Id),
  RegisteredCapital DECIMAL(15,2),             -- ทุนจดทะเบียน
  RegisteredCapitalCurrencyId BIGINT REFERENCES Currencies(Id),
  FoundedDate DATE,                            -- วันที่ก่อตั้ง
  
  -- Contact Information
  AddressLine1 VARCHAR(200),
  AddressLine2 VARCHAR(200),
  City VARCHAR(100),
  Province VARCHAR(100),
  PostalCode VARCHAR(20),
  Phone VARCHAR(20),
  Fax VARCHAR(20),
  Email VARCHAR(100),
  Website VARCHAR(200),
  
  -- Status & Audit
  Status VARCHAR(20) DEFAULT 'ACTIVE',
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CreatedBy BIGINT,
  UpdatedAt TIMESTAMP,
  UpdatedBy BIGINT,
  
  CONSTRAINT chk_company_status CHECK (Status IN ('ACTIVE','INACTIVE','SUSPENDED'))
);
CREATE INDEX idx_companies_short_name ON Companies(ShortNameEn) WHERE IsActive = TRUE;
CREATE INDEX idx_companies_tax_id ON Companies(TaxId) WHERE TaxId IS NOT NULL;

-- 2.2 Departments
-- ตาราง: แผนกภายในบริษัท
CREATE TABLE Departments (
  Id BIGSERIAL PRIMARY KEY,
  CompanyId BIGINT NOT NULL REFERENCES Companies(Id),
  DepartmentCode VARCHAR(50) NOT NULL,         -- รหัสแผนก
  DepartmentNameTh VARCHAR(200) NOT NULL,      -- ชื่อแผนกภาษาไทย
  DepartmentNameEn VARCHAR(200),               -- ชื่อแผนกภาษาอังกฤษ
  ParentDepartmentId BIGINT REFERENCES Departments(Id),  -- แผนกแม่ (สำหรับ hierarchy)
  ManagerUserId BIGINT,                        -- ผู้จัดการแผนก
  CostCenter VARCHAR(50),                      -- รหัส Cost Center
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UpdatedAt TIMESTAMP,
  
  UNIQUE(CompanyId, DepartmentCode)
);
CREATE INDEX idx_departments_company ON Departments(CompanyId) WHERE IsActive = TRUE;

-- =============================================
-- SECTION 3: USER MANAGEMENT
-- ตารางจัดการผู้ใช้งานระบบ (พนักงานภายใน)
-- =============================================

-- 3.1 Users
-- ตาราง: ผู้ใช้งานระบบ (พนักงานภายในบริษัท)
CREATE TABLE Users (
  Id BIGSERIAL PRIMARY KEY,
  EmployeeCode VARCHAR(50),                    -- รหัสพนักงาน
  Username VARCHAR(100) UNIQUE,                -- ชื่อผู้ใช้ (nullable - ใช้ Email login)
  Email VARCHAR(100) UNIQUE NOT NULL,          -- อีเมล (ใช้ login)
  PasswordHash VARCHAR(255) NOT NULL,          -- รหัสผ่านที่เข้ารหัสแล้ว
  
  -- Personal Information
  FirstNameTh VARCHAR(100),                    -- ชื่อภาษาไทย
  LastNameTh VARCHAR(100),                     -- นามสกุลภาษาไทย
  FirstNameEn VARCHAR(100),                    -- ชื่อภาษาอังกฤษ
  LastNameEn VARCHAR(100),                     -- นามสกุลภาษาอังกฤษ
  PhoneNumber VARCHAR(20),                     -- เบอร์โทรศัพท์
  MobileNumber VARCHAR(20),                    -- เบอร์มือถือ
  
  -- Authentication & Security (Updated)
  IsEmailVerified BOOLEAN DEFAULT FALSE,       -- ยืนยันอีเมลแล้วหรือยัง
  EmailVerifiedAt TIMESTAMP,                   -- วันที่ยืนยันอีเมล
  PasswordResetToken VARCHAR(255),             -- Token สำหรับรีเซ็ตรหัสผ่าน
  PasswordResetExpiry TIMESTAMP,               -- วันหมดอายุ Token
  SecurityStamp VARCHAR(100),                  -- Token สำหรับ invalidate JWT
  LastLoginAt TIMESTAMP,                       -- วันที่ login ล่าสุด
  LoginAttempts INT DEFAULT 0,                 -- จำนวนครั้งที่ login ผิด (ไม่ใช้แล้ว)
  LockedUntil TIMESTAMP,                       -- วันที่ปลดล็อค (ไม่ใช้แล้ว)
  LockoutEnabled BOOLEAN DEFAULT TRUE,         -- เปิดใช้งานการล็อคบัญชี
  LockoutEnd TIMESTAMP WITH TIME ZONE,         -- วันเวลาที่สิ้นสุดการล็อค
  AccessFailedCount INT DEFAULT 0,             -- จำนวนครั้งที่ login ผิด
  
  -- Status & Audit
  Status VARCHAR(20) DEFAULT 'ACTIVE',
  IsActive BOOLEAN DEFAULT TRUE,
  IsDeleted BOOLEAN DEFAULT FALSE,             -- Soft delete
  DeletedAt TIMESTAMP,
  DeletedBy BIGINT,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CreatedBy BIGINT,
  UpdatedAt TIMESTAMP,
  UpdatedBy BIGINT,
  
  CONSTRAINT chk_user_status CHECK (Status IN ('ACTIVE','INACTIVE','SUSPENDED','LOCKED'))
);

-- Create Indexes
CREATE INDEX idx_users_email ON Users(Email) WHERE IsDeleted = FALSE;
CREATE INDEX idx_users_email_active ON Users(Email) WHERE IsDeleted = FALSE AND IsActive = TRUE;
CREATE INDEX idx_users_username ON Users(Username) WHERE IsDeleted = FALSE;
CREATE INDEX idx_users_employee_code ON Users(EmployeeCode) WHERE EmployeeCode IS NOT NULL;

-- Comments
COMMENT ON COLUMN Users.Username IS 'ชื่อผู้ใช้ (Optional) - ระบบใช้ Email ในการ login';
COMMENT ON COLUMN Users.Email IS 'อีเมล - ใช้เป็น credential หลักในการ login';
COMMENT ON COLUMN Users.SecurityStamp IS 'Token สำหรับ invalidate JWT เมื่อเปลี่ยนรหัสผ่าน';
COMMENT ON COLUMN Users.LockoutEnabled IS 'เปิดใช้งานการล็อคบัญชี - TRUE = สามารถถูกล็อคได้';
COMMENT ON COLUMN Users.LockoutEnd IS 'วันเวลาที่สิ้นสุดการล็อค - NULL = ไม่ถูกล็อค';
COMMENT ON COLUMN Users.AccessFailedCount IS 'จำนวนครั้งที่ login ผิด - รีเซ็ตเป็น 0 เมื่อ login สำเร็จ';

-- 3.2 User Company Roles
-- ตาราง: บทบาทของผู้ใช้ในแต่ละบริษัท (Multi-Company, Multi-Role)
CREATE TABLE UserCompanyRoles (
  Id BIGSERIAL PRIMARY KEY,
  UserId BIGINT NOT NULL REFERENCES Users(Id),
  CompanyId BIGINT NOT NULL REFERENCES Companies(Id),
  DepartmentId BIGINT REFERENCES Departments(Id),
  
  -- Primary and Secondary Roles
  PrimaryRoleId BIGINT NOT NULL REFERENCES Roles(Id),    -- บทบาทหลัก
  SecondaryRoleId BIGINT REFERENCES Roles(Id),           -- บทบาทรอง (optional)
  
  -- Role-specific configurations
  ApproverLevel SMALLINT CHECK (ApproverLevel BETWEEN 1 AND 3),  -- ระดับอนุมัติ (1-3)
  
  -- Validity Period
  StartDate DATE NOT NULL,                     -- วันที่เริ่มมีสิทธิ์
  EndDate DATE,                                 -- วันที่สิ้นสุดสิทธิ์
  
  -- Status
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CreatedBy BIGINT,
  UpdatedAt TIMESTAMP,
  UpdatedBy BIGINT,
  
  -- Constraints
  UNIQUE(UserId, CompanyId),
  CONSTRAINT chk_role_rules CHECK (
    -- Requester cannot be Approver or Purchasing
    NOT (
      (PrimaryRoleId = (SELECT Id FROM Roles WHERE RoleCode = 'REQUESTER') 
       AND SecondaryRoleId IN (SELECT Id FROM Roles WHERE RoleCode IN ('APPROVER','PURCHASING')))
      OR
      (SecondaryRoleId = (SELECT Id FROM Roles WHERE RoleCode = 'REQUESTER') 
       AND PrimaryRoleId IN (SELECT Id FROM Roles WHERE RoleCode IN ('APPROVER','PURCHASING')))
    )
  ),
  CONSTRAINT chk_date_validity CHECK (EndDate IS NULL OR EndDate > StartDate)
);
CREATE INDEX idx_user_company_roles_user ON UserCompanyRoles(UserId) WHERE IsActive = TRUE;
CREATE INDEX idx_user_company_roles_company ON UserCompanyRoles(CompanyId) WHERE IsActive = TRUE;

-- 3.3 User Category Bindings
-- ตาราง: กำหนดหมวดหมู่ที่ Purchasing รับผิดชอบ
CREATE TABLE UserCategoryBindings (
  Id BIGSERIAL PRIMARY KEY,
  UserCompanyRoleId BIGINT NOT NULL REFERENCES UserCompanyRoles(Id),
  CategoryId BIGINT NOT NULL REFERENCES Categories(Id),
  SubcategoryId BIGINT REFERENCES Subcategories(Id),
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE(UserCompanyRoleId, CategoryId, SubcategoryId)
);

-- 3.4 Approver Bindings
-- ตาราง: กำหนดผู้อนุมัติสำหรับแต่ละแผนก/ผู้ขอ
CREATE TABLE ApproverBindings (
  Id BIGSERIAL PRIMARY KEY,
  ApproverUserCompanyRoleId BIGINT NOT NULL REFERENCES UserCompanyRoles(Id),
  DepartmentId BIGINT REFERENCES Departments(Id),       -- แผนกที่ดูแล
  RequesterUserId BIGINT REFERENCES Users(Id),          -- ผู้ขอที่ดูแล (specific)
  MaxApprovalAmount DECIMAL(15,2),                      -- วงเงินอนุมัติสูงสุด
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE(ApproverUserCompanyRoleId, DepartmentId, RequesterUserId)
);

-- 3.5 Delegation Settings
-- ตาราง: การมอบหมายงานชั่วคราว (เมื่อลางาน)
CREATE TABLE Delegations (
  Id BIGSERIAL PRIMARY KEY,
  FromUserId BIGINT NOT NULL REFERENCES Users(Id),      -- ผู้มอบหมาย
  ToUserId BIGINT NOT NULL REFERENCES Users(Id),        -- ผู้รับมอบหมาย
  CompanyId BIGINT NOT NULL REFERENCES Companies(Id),
  RoleId BIGINT NOT NULL REFERENCES Roles(Id),
  StartDate TIMESTAMP NOT NULL,                         -- วันที่เริ่ม
  EndDate TIMESTAMP NOT NULL,                           -- วันที่สิ้นสุด
  Reason TEXT,                                          -- เหตุผล
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CreatedBy BIGINT,
  
  CONSTRAINT chk_delegation_dates CHECK (EndDate > StartDate),
  CONSTRAINT chk_delegation_users CHECK (FromUserId != ToUserId)
);

-- =============================================
-- SECTION 4: SUPPLIER MANAGEMENT
-- ตารางจัดการข้อมูล Supplier และผู้ติดต่อ
-- =============================================

-- 4.1 Suppliers
-- ตาราง: ข้อมูล Supplier ที่ลงทะเบียนในระบบ
CREATE TABLE Suppliers (
  Id BIGSERIAL PRIMARY KEY,
  
  -- Company Information
  TaxId VARCHAR(20) UNIQUE,                    -- เลขประจำตัวผู้เสียภาษี
  CompanyNameTh VARCHAR(200) NOT NULL,         -- ชื่อบริษัทภาษาไทย
  CompanyNameEn VARCHAR(200),                  -- ชื่อบริษัทภาษาอังกฤษ
  BusinessTypeId SMALLINT NOT NULL REFERENCES BusinessTypes(Id),  -- ประเภทบุคคล
  JobTypeId SMALLINT NOT NULL REFERENCES JobTypes(Id),            -- ประเภทงาน (ซื้อ/ขาย)
  
  -- Financial Information
  RegisteredCapital DECIMAL(15,2),             -- ทุนจดทะเบียน
  RegisteredCapitalCurrencyId BIGINT REFERENCES Currencies(Id),
  DefaultCurrencyId BIGINT REFERENCES Currencies(Id),
  
  -- Contact Information
  CompanyEmail VARCHAR(100),                   -- อีเมลบริษัท
  CompanyPhone VARCHAR(20),                    -- เบอร์โทรศัพท์บริษัท
  CompanyFax VARCHAR(20),                      -- แฟกซ์
  CompanyWebsite VARCHAR(200),                 -- เว็บไซต์
  
  -- Address
  AddressLine1 VARCHAR(200),
  AddressLine2 VARCHAR(200),
  City VARCHAR(100),
  Province VARCHAR(100),
  PostalCode VARCHAR(20),
  CountryId BIGINT REFERENCES Countries(Id),
  
  -- Business Details
  BusinessScope TEXT,                          -- ขอบเขตการดำเนินธุรกิจ (max 500 chars)
  FoundedDate DATE,                            -- วันที่ก่อตั้งบริษัท
  
  -- Registration & Approval
  InvitedByUserId BIGINT REFERENCES Users(Id), -- User ที่เชิญลงทะเบียน
  InvitedByCompanyId BIGINT REFERENCES Companies(Id),  -- บริษัทที่เชิญ
  InvitedAt TIMESTAMP,                         -- วันเวลาที่เชิญ
  RegisteredAt TIMESTAMP,                      -- วันเวลาที่ลงทะเบียน
  ApprovedByUserId BIGINT REFERENCES Users(Id),-- User ที่อนุมัติ
  ApprovedAt TIMESTAMP,                        -- วันเวลาที่อนุมัติ
  
  -- Status Management
  Status VARCHAR(20) DEFAULT 'PENDING',        -- สถานะ: PENDING, COMPLETED, DECLINED
  DeclineReason TEXT,                          -- เหตุผลที่ปฏิเสธ
  
  -- System Fields
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UpdatedAt TIMESTAMP,
  
  CONSTRAINT chk_supplier_status CHECK (Status IN ('PENDING','COMPLETED','DECLINED'))
);

-- Create Indexes
CREATE INDEX idx_suppliers_status ON Suppliers(Status) WHERE IsActive = TRUE;
CREATE INDEX idx_suppliers_tax_id ON Suppliers(TaxId) WHERE TaxId IS NOT NULL;
CREATE INDEX idx_suppliers_job_type ON Suppliers(JobTypeId) WHERE IsActive = TRUE;
CREATE INDEX idx_suppliers_company ON Suppliers(InvitedByCompanyId) WHERE InvitedByCompanyId IS NOT NULL;

-- Comments
COMMENT ON TABLE Suppliers IS 'ตารางเก็บข้อมูล Supplier ที่ลงทะเบียนในระบบ';
COMMENT ON COLUMN Suppliers.Status IS 'PENDING=รอตรวจสอบ, COMPLETED=ตรวจสอบผ่าน, DECLINED=ปฏิเสธ';
COMMENT ON COLUMN Suppliers.BusinessScope IS 'ขอบเขตการดำเนินธุรกิจ max 500 ตัวอักษร';

-- 4.2 Supplier Contacts
-- ตาราง: ผู้ติดต่อของ Supplier (สามารถ login เข้าระบบ)
CREATE TABLE SupplierContacts (
  Id BIGSERIAL PRIMARY KEY,
  SupplierId BIGINT NOT NULL REFERENCES Suppliers(Id),
  
  -- Personal Information
  FirstName VARCHAR(100) NOT NULL,             -- ชื่อ
  LastName VARCHAR(100) NOT NULL,              -- นามสกุล
  Position VARCHAR(100),                       -- ตำแหน่งงาน
  Email VARCHAR(100) NOT NULL,                 -- อีเมล (ใช้ login)
  PhoneNumber VARCHAR(20),                     -- เบอร์โทรศัพท์
  MobileNumber VARCHAR(20),                    -- เบอร์มือถือ
  
  -- Authentication (Updated - ไม่มี Username)
  PasswordHash VARCHAR(255),                   -- รหัสผ่านที่เข้ารหัส
  SecurityStamp VARCHAR(100),                  -- Token สำหรับ invalidate JWT
  
  -- Security Settings
  IsEmailVerified BOOLEAN DEFAULT FALSE,       -- ยืนยันอีเมลแล้วหรือยัง
  EmailVerifiedAt TIMESTAMP,                   -- วันที่ยืนยันอีเมล
  PasswordResetToken VARCHAR(255),             -- Token รีเซ็ตรหัสผ่าน
  PasswordResetExpiry TIMESTAMP,               -- วันหมดอายุ Token
  LastLoginAt TIMESTAMP,                       -- วันที่ login ล่าสุด
  FailedLoginAttempts INT DEFAULT 0,           -- จำนวนครั้งที่ login ผิด
  LockoutEnd TIMESTAMP WITH TIME ZONE,         -- วันเวลาที่สิ้นสุดการล็อค
  
  -- Permissions
  CanSubmitQuotation BOOLEAN DEFAULT TRUE,     -- สิทธิ์เสนอราคา
  CanViewReports BOOLEAN DEFAULT FALSE,        -- สิทธิ์ดูรายงาน
  
  -- Status & Audit
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CreatedBy BIGINT,
  UpdatedAt TIMESTAMP,
  UpdatedBy BIGINT,
  
  UNIQUE(SupplierId, Email)
);

-- Create Indexes
CREATE INDEX idx_supplier_contacts_supplier ON SupplierContacts(SupplierId) WHERE IsActive = TRUE;
CREATE INDEX idx_supplier_contacts_email ON SupplierContacts(Email) WHERE IsActive = TRUE;
CREATE INDEX idx_supplier_contacts_email_active ON SupplierContacts(Email) WHERE IsActive = TRUE;

-- Comments
COMMENT ON TABLE SupplierContacts IS 'ผู้ติดต่อของ Supplier ที่สามารถ login เข้าระบบ';
COMMENT ON COLUMN SupplierContacts.Email IS 'อีเมล - ใช้เป็น credential หลักในการ login';
COMMENT ON COLUMN SupplierContacts.SecurityStamp IS 'Token สำหรับ invalidate JWT';
COMMENT ON COLUMN SupplierContacts.LockoutEnd IS 'วันเวลาที่สิ้นสุดการล็อค';
COMMENT ON COLUMN SupplierContacts.FailedLoginAttempts IS 'จำนวนครั้งที่ login ผิด';

-- 4.3 Supplier Categories
-- ตาราง: หมวดหมู่ที่ Supplier ให้บริการ (Many-to-Many)
CREATE TABLE SupplierCategories (
  Id BIGSERIAL PRIMARY KEY,
  SupplierId BIGINT NOT NULL REFERENCES Suppliers(Id),
  CategoryId BIGINT NOT NULL REFERENCES Categories(Id),
  SubcategoryId BIGINT REFERENCES Subcategories(Id),
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE(SupplierId, CategoryId, SubcategoryId)
);
CREATE INDEX idx_supplier_categories_supplier ON SupplierCategories(SupplierId) WHERE IsActive = TRUE;
CREATE INDEX idx_supplier_categories_category ON SupplierCategories(CategoryId) WHERE IsActive = TRUE;

-- 4.4 Supplier Documents
-- ตาราง: เอกสารของ Supplier
CREATE TABLE SupplierDocuments (
  Id BIGSERIAL PRIMARY KEY,
  SupplierId BIGINT NOT NULL REFERENCES Suppliers(Id),
  DocumentType VARCHAR(50) NOT NULL,           -- ประเภทเอกสาร
  DocumentName VARCHAR(200) NOT NULL,          -- ชื่อเอกสาร
  FileName VARCHAR(255) NOT NULL,              -- ชื่อไฟล์
  FilePath TEXT,                               -- path ที่เก็บไฟล์
  FileSize BIGINT,                             -- ขนาดไฟล์ (bytes)
  MimeType VARCHAR(100),                       -- ประเภทไฟล์
  
  -- Validity
  IssueDate DATE,                              -- วันที่ออกเอกสาร
  ExpiryDate DATE,                             -- วันหมดอายุ
  
  -- Status
  VerificationStatus VARCHAR(20) DEFAULT 'PENDING',  -- สถานะการตรวจสอบ
  VerifiedBy BIGINT REFERENCES Users(Id),
  VerifiedAt TIMESTAMP,
  
  -- Audit
  IsActive BOOLEAN DEFAULT TRUE,
  UploadedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UploadedBy BIGINT,
  
  CONSTRAINT chk_doc_verification CHECK (VerificationStatus IN ('PENDING','VERIFIED','REJECTED'))
);
CREATE INDEX idx_supplier_documents_supplier ON SupplierDocuments(SupplierId) WHERE IsActive = TRUE;

-- =============================================
-- SECTION 5: RFQ MANAGEMENT
-- ตารางจัดการใบขอเสนอราคา
-- =============================================

-- 5.1 RFQs (Request for Quotations)
-- ตาราง: ใบขอเสนอราคา
CREATE TABLE Rfqs (
  Id BIGSERIAL PRIMARY KEY,
  RfqNumber VARCHAR(50) UNIQUE NOT NULL,       -- เลขที่ RFQ (Format: ShortNameEn-yy-mm-xxxx)
  ProjectName VARCHAR(500) NOT NULL,           -- ชื่อโครงการ
  
  -- Company & Department
  CompanyId BIGINT NOT NULL REFERENCES Companies(Id),
  DepartmentId BIGINT NOT NULL REFERENCES Departments(Id),
  
  -- Category & Type
  CategoryId BIGINT NOT NULL REFERENCES Categories(Id),
  SubcategoryId BIGINT NOT NULL REFERENCES Subcategories(Id),
  JobTypeId SMALLINT NOT NULL REFERENCES JobTypes(Id),
  
  -- Requester Information
  RequesterId BIGINT NOT NULL REFERENCES Users(Id),      -- ผู้ขอเสนอราคา
  ResponsiblePersonId BIGINT REFERENCES Users(Id),        -- ผู้รับผิดชอบ
  RequesterEmail VARCHAR(100),                            -- อีเมลผู้ขอ
  RequesterPhone VARCHAR(20),                             -- เบอร์ผู้ขอ
  
  -- Budget & Currency
  BudgetAmount DECIMAL(15,2),                             -- งบประมาณ
  BudgetCurrencyId BIGINT NOT NULL REFERENCES Currencies(Id),
  
  -- Important Dates
  CreatedDate DATE NOT NULL DEFAULT CURRENT_DATE,
  RequiredQuotationDate TIMESTAMP NOT NULL,               -- วันที่ต้องการใบเสนอราคา
  QuotationDeadline TIMESTAMP,                           -- วันสิ้นสุดการเสนอราคา (Requester กำหนด)
  SubmissionDeadline TIMESTAMP,                          -- วันสิ้นสุดการเสนอราคา (Purchasing กำหนด)
  
  -- Serial Number (if required by subcategory)
  SerialNumber VARCHAR(100),
  
  -- Status & Workflow (Updated)
  Status VARCHAR(20) DEFAULT 'SAVE_DRAFT',
  CurrentLevel SMALLINT DEFAULT 0,                        -- ระดับการอนุมัติปัจจุบัน
  CurrentActorId BIGINT REFERENCES Users(Id),             -- ผู้ที่ต้อง action
  
  -- Re-Bid Fields (New)
  ReBidCount INT DEFAULT 0,                               -- จำนวนครั้งที่ Re-Bid
  LastReBidAt TIMESTAMP,                                  -- วันเวลาที่ Re-Bid ล่าสุด
  ReBidReason TEXT,                                       -- เหตุผลที่ Re-Bid
  
  -- Flags
  IsUrgent BOOLEAN DEFAULT FALSE,                         -- เร่งด่วน
  IsOntime BOOLEAN DEFAULT TRUE,                          -- ทันเวลา
  HasMedicineIcon BOOLEAN DEFAULT FALSE,                  -- มีไอคอนยา
  
  -- Decline/Reject Reasons
  DeclineReason TEXT,                                     -- เหตุผลที่ปฏิเสธ (Approver)
  RejectReason TEXT,                                      -- เหตุผลที่ Reject (Purchasing)
  
  -- Remarks
  Remarks TEXT,                                           -- หมายเหตุ
  
  -- Audit
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CreatedBy BIGINT REFERENCES Users(Id),
  UpdatedAt TIMESTAMP,
  UpdatedBy BIGINT REFERENCES Users(Id),
  
  CONSTRAINT chk_rfq_status CHECK (Status IN 
    ('SAVE_DRAFT','PENDING','DECLINED','REJECTED','COMPLETED','RE_BID')),
  CONSTRAINT chk_rfq_job_type CHECK (JobTypeId IN (1, 2))  -- Only Buy or Sell for RFQ
);

-- Create Indexes
CREATE INDEX idx_rfqs_number ON Rfqs(RfqNumber);
CREATE INDEX idx_rfqs_status ON Rfqs(Status) WHERE Status != 'COMPLETED';
CREATE INDEX idx_rfqs_status_rebid ON Rfqs(Status) WHERE Status = 'RE_BID';
CREATE INDEX idx_rfqs_company ON Rfqs(CompanyId);
CREATE INDEX idx_rfqs_requester ON Rfqs(RequesterId);
CREATE INDEX idx_rfqs_current_actor ON Rfqs(CurrentActorId) WHERE Status = 'PENDING';
CREATE INDEX idx_rfqs_deadline ON Rfqs(QuotationDeadline) WHERE Status NOT IN ('COMPLETED','REJECTED');
CREATE INDEX idx_rfqs_submission_deadline ON Rfqs(SubmissionDeadline) WHERE Status IN ('PENDING', 'RE_BID');

-- Comments
COMMENT ON COLUMN Rfqs.QuotationDeadline IS 'วันที่ต้องการใบเสนอราคา (Requester กำหนด)';
COMMENT ON COLUMN Rfqs.SubmissionDeadline IS 'วันที่สิ้นสุดการเสนอราคา (Purchasing กำหนดหลังจาก approve)';
COMMENT ON COLUMN Rfqs.ReBidCount IS 'จำนวนครั้งที่ Re-Bid';
COMMENT ON COLUMN Rfqs.LastReBidAt IS 'วันเวลาที่ Re-Bid ล่าสุด';
COMMENT ON COLUMN Rfqs.ReBidReason IS 'เหตุผลที่ Re-Bid';

-- 5.2 RFQ Items
-- ตาราง: รายการสินค้า/บริการใน RFQ
CREATE TABLE RfqItems (
  Id BIGSERIAL PRIMARY KEY,
  RfqId BIGINT NOT NULL REFERENCES Rfqs(Id) ON DELETE CASCADE,
  ItemSequence INT NOT NULL,                   -- ลำดับรายการ
  
  -- Item Details
  ItemCode VARCHAR(50),                        -- รหัสสินค้า
  ItemDescription TEXT NOT NULL,               -- รายละเอียดสินค้า
  Specifications TEXT,                         -- ข้อกำหนดเฉพาะ
  
  -- Quantity & Unit
  Quantity DECIMAL(12,4) NOT NULL,             -- จำนวน
  UnitOfMeasure VARCHAR(50) NOT NULL,          -- หน่วยนับ
  
  -- Delivery
  RequiredDeliveryDate DATE,                   -- วันที่ต้องการสินค้า
  DeliveryLocation VARCHAR(500),               -- สถานที่ส่งมอบ
  
  -- Budget (Optional)
  EstimatedUnitPrice DECIMAL(18,4),            -- ราคาต่อหน่วยโดยประมาณ
  EstimatedTotalPrice DECIMAL(18,4),           -- ราคารวมโดยประมาณ
  
  -- Additional Info
  Remarks TEXT,                                -- หมายเหตุ
  AttachmentPath TEXT,                         -- ไฟล์แนบ
  
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UpdatedAt TIMESTAMP,
  
  UNIQUE(RfqId, ItemSequence)
);
CREATE INDEX idx_rfq_items_rfq ON RfqItems(RfqId);

-- 5.3 RFQ Documents
-- ตาราง: เอกสารแนบ RFQ
CREATE TABLE RfqDocuments (
  Id BIGSERIAL PRIMARY KEY,
  RfqId BIGINT NOT NULL REFERENCES Rfqs(Id) ON DELETE CASCADE,
  DocumentType VARCHAR(50) NOT NULL,           -- ประเภทเอกสาร
  DocumentName VARCHAR(200) NOT NULL,          -- ชื่อเอกสาร
  FileName VARCHAR(255) NOT NULL,              -- ชื่อไฟล์
  FilePath TEXT,                               -- path ที่เก็บไฟล์
  FileSize BIGINT,                             -- ขนาดไฟล์ (bytes)
  MimeType VARCHAR(100),                       -- ประเภทไฟล์
  UploadedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UploadedBy BIGINT REFERENCES Users(Id)
);
CREATE INDEX idx_rfq_documents_rfq ON RfqDocuments(RfqId);

-- 5.4 RFQ Required Fields (New)
-- ตาราง: กำหนดข้อมูลที่ Supplier ต้องระบุในการเสนอราคา
CREATE TABLE RfqRequiredFields (
  Id BIGSERIAL PRIMARY KEY,
  RfqId BIGINT NOT NULL REFERENCES Rfqs(Id) ON DELETE CASCADE,
  
  -- Required Fields Configuration (Checkboxes)
  RequireMOQ BOOLEAN DEFAULT FALSE,            -- บังคับให้ระบุ MOQ
  RequireDLT BOOLEAN DEFAULT FALSE,            -- บังคับให้ระบุระยะเวลาส่งมอบ
  RequireCredit BOOLEAN DEFAULT FALSE,         -- บังคับให้ระบุเครดิตเทอม
  RequireWarranty BOOLEAN DEFAULT FALSE,       -- บังคับให้ระบุระยะเวลารับประกัน
  RequireIncoTerm BOOLEAN DEFAULT FALSE,       -- บังคับให้ระบุ Incoterms
  
  -- Audit
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CreatedBy BIGINT REFERENCES Users(Id),
  UpdatedAt TIMESTAMP,
  UpdatedBy BIGINT REFERENCES Users(Id),
  
  CONSTRAINT uk_rfq_required_fields UNIQUE(RfqId)
);

-- Create Index
CREATE INDEX idx_rfq_required_fields_rfq ON RfqRequiredFields(RfqId);

-- Comments
COMMENT ON TABLE RfqRequiredFields IS 'กำหนดข้อมูลที่ Supplier ต้องระบุในการเสนอราคา - Purchasing เลือกผ่าน checkbox';
COMMENT ON COLUMN RfqRequiredFields.RequireMOQ IS 'บังคับให้ระบุจำนวนสั่งซื้อขั้นต่ำ (หน่วย)';
COMMENT ON COLUMN RfqRequiredFields.RequireDLT IS 'บังคับให้ระบุระยะเวลาส่งมอบ (วัน)';
COMMENT ON COLUMN RfqRequiredFields.RequireCredit IS 'บังคับให้ระบุเครดิตเทอม (วัน)';
COMMENT ON COLUMN RfqRequiredFields.RequireWarranty IS 'บังคับให้ระบุระยะเวลารับประกัน (วัน)';
COMMENT ON COLUMN RfqRequiredFields.RequireIncoTerm IS 'บังคับให้ระบุเงื่อนไขการส่งมอบ (Incoterms)';

-- =============================================
-- SECTION 6: WORKFLOW & APPROVAL
-- ตารางจัดการ Workflow และการอนุมัติ
-- =============================================

-- 6.1 Approval Matrix
-- ตาราง: กำหนดระดับการอนุมัติตามวงเงิน
CREATE TABLE ApprovalMatrix (
  Id BIGSERIAL PRIMARY KEY,
  CompanyId BIGINT NOT NULL REFERENCES Companies(Id),
  CategoryId BIGINT REFERENCES Categories(Id),
  SubcategoryId BIGINT REFERENCES Subcategories(Id),
  
  -- Amount Range
  MinAmount DECIMAL(15,2),                     -- วงเงินขั้นต่ำ
  MaxAmount DECIMAL(15,2),                     -- วงเงินสูงสุด
  
  -- Required Approval Levels
  RequiredLevels SMALLINT NOT NULL,            -- จำนวนระดับที่ต้องอนุมัติ
  Level1RoleId BIGINT REFERENCES Roles(Id),    -- บทบาทระดับ 1
  Level2RoleId BIGINT REFERENCES Roles(Id),    -- บทบาทระดับ 2
  Level3RoleId BIGINT REFERENCES Roles(Id),    -- บทบาทระดับ 3
  
  -- Response Time (in days)
  ResponseTimeDays INT DEFAULT 2,              -- ระยะเวลาตอบกลับ (วัน)
  
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UpdatedAt TIMESTAMP
);

-- 6.2 RFQ Status History
-- ตาราง: ประวัติการเปลี่ยนสถานะ RFQ
CREATE TABLE RfqStatusHistory (
  Id BIGSERIAL PRIMARY KEY,
  RfqId BIGINT NOT NULL REFERENCES Rfqs(Id),
  
  -- Status Change
  FromStatus VARCHAR(20),                      -- สถานะเดิม
  ToStatus VARCHAR(20) NOT NULL,               -- สถานะใหม่
  ActionType VARCHAR(50) NOT NULL,             -- ประเภทการกระทำ
  
  -- Actor Information
  ActorId BIGINT NOT NULL REFERENCES Users(Id),
  ActorRole VARCHAR(30),                       -- บทบาทของผู้กระทำ
  ApprovalLevel SMALLINT,                      -- ระดับการอนุมัติ
  
  -- Decision Details
  Decision VARCHAR(20),                        -- APPROVED, DECLINED, REJECTED
  Reason TEXT,                                 -- เหตุผล
  Comments TEXT,                               -- ความคิดเห็น
  
  -- Timestamp
  ActionAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT chk_decision CHECK (Decision IN ('APPROVED','DECLINED','REJECTED','SUBMITTED'))
);
CREATE INDEX idx_rfq_status_history_rfq ON RfqStatusHistory(RfqId);
CREATE INDEX idx_rfq_status_history_actor ON RfqStatusHistory(ActorId);

-- 6.3 Workflow Rules
-- ตาราง: กฎการทำงานของ Workflow
CREATE TABLE WorkflowRules (
  Id BIGSERIAL PRIMARY KEY,
  CompanyId BIGINT REFERENCES Companies(Id),
  WorkflowType VARCHAR(50) NOT NULL,           -- ประเภท Workflow
  
  -- Conditions
  ConditionJson JSONB,                         -- เงื่อนไขในรูปแบบ JSON
  
  -- Actions
  ActionJson JSONB,                            -- การกระทำในรูปแบบ JSON
  
  -- Configuration
  Priority INT DEFAULT 0,                      -- ลำดับความสำคัญ
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UpdatedAt TIMESTAMP
);

-- =============================================
-- SECTION 7: QUOTATION MANAGEMENT
-- ตารางจัดการใบเสนอราคาจาก Supplier
-- =============================================

-- 7.1 RFQ Invitations
-- ตาราง: การเชิญ Supplier เสนอราคา
CREATE TABLE RfqInvitations (
  Id BIGSERIAL PRIMARY KEY,
  RfqId BIGINT NOT NULL REFERENCES Rfqs(Id) ON DELETE CASCADE,
  SupplierId BIGINT NOT NULL REFERENCES Suppliers(Id),
  
  -- Invitation Information
  InvitedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  InvitedByUserId BIGINT NOT NULL REFERENCES Users(Id),
  
  -- Response Tracking (Updated)
  ResponseStatus VARCHAR(30) DEFAULT 'NO_RESPONSE',
  RespondedAt TIMESTAMP,
  
  -- Decision Tracking
  Decision VARCHAR(30) DEFAULT 'PENDING',
  DecisionReason TEXT,
  RespondedByContactId BIGINT REFERENCES SupplierContacts(Id),  -- Contact ที่ตอบรับ
  
  -- Change Tracking
  DecisionChangeCount INT DEFAULT 0,           -- จำนวนครั้งที่เปลี่ยนใจ
  LastDecisionChangeAt TIMESTAMP,              -- เวลาที่เปลี่ยนใจล่าสุด
  
  -- Re-Bid Tracking (New)
  ReBidCount INT DEFAULT 0,                    -- จำนวนครั้งที่เข้าร่วม Re-Bid
  LastReBidAt TIMESTAMP,                       -- วันเวลาที่ตอบรับ Re-Bid ล่าสุด
  
  -- Audit Fields (New)
  RespondedIpAddress INET,                     -- IP Address ที่ตอบรับ
  RespondedUserAgent TEXT,                     -- Browser/Device info
  RespondedDeviceInfo TEXT,                    -- Device details
  
  -- Auto Actions
  AutoDeclinedAt TIMESTAMP,
  
  -- System Fields
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UpdatedAt TIMESTAMP,
  
  -- Constraints
  CONSTRAINT uk_rfq_supplier UNIQUE(RfqId, SupplierId),
  CONSTRAINT chk_response_status CHECK (ResponseStatus IN ('NO_RESPONSE','RESPONDED')),
  CONSTRAINT chk_decision CHECK (Decision IN 
    ('PENDING','PARTICIPATING','NOT_PARTICIPATING','AUTO_DECLINED'))
);

-- Create Indexes
CREATE INDEX idx_rfq_invitations_rfq ON RfqInvitations(RfqId);
CREATE INDEX idx_rfq_invitations_supplier ON RfqInvitations(SupplierId);
CREATE INDEX idx_rfq_invitations_responded_contact ON RfqInvitations(RespondedByContactId) 
  WHERE RespondedByContactId IS NOT NULL;
CREATE INDEX idx_rfq_invitations_pending ON RfqInvitations(RfqId) 
  WHERE ResponseStatus = 'NO_RESPONSE';
CREATE INDEX idx_rfq_invitations_decision_participating ON RfqInvitations(SupplierId, Decision)
  WHERE Decision = 'PARTICIPATING';

-- Comments
COMMENT ON TABLE RfqInvitations IS 'การเชิญ Supplier เสนอราคาสำหรับแต่ละ RFQ';
COMMENT ON COLUMN RfqInvitations.ResponseStatus IS 'NO_RESPONSE=ยังไม่ตอบ, RESPONDED=ตอบแล้ว';
COMMENT ON COLUMN RfqInvitations.Decision IS 'PENDING=รอ, PARTICIPATING=เข้าร่วม, NOT_PARTICIPATING=ไม่เข้าร่วม, AUTO_DECLINED=หมดเวลา';
COMMENT ON COLUMN RfqInvitations.RespondedByContactId IS 'Contact คนที่กดเข้าร่วม - คนนี้จะเป็นคนเสนอราคา';
COMMENT ON COLUMN RfqInvitations.RespondedIpAddress IS 'IP Address ของ Contact ที่ตอบรับ';
COMMENT ON COLUMN RfqInvitations.ReBidCount IS 'จำนวนครั้งที่เข้าร่วม Re-Bid';

-- 7.2 RFQ Invitation History
-- ตาราง: ประวัติการเปลี่ยนแปลงการตอบรับ
CREATE TABLE RfqInvitationHistory (
  Id BIGSERIAL PRIMARY KEY,
  InvitationId BIGINT NOT NULL REFERENCES RfqInvitations(Id),
  
  -- Change Information
  DecisionSequence INT NOT NULL,               -- ลำดับการเปลี่ยนแปลง (1,2,3,...)
  FromDecision VARCHAR(30),                    -- เปลี่ยนจากสถานะอะไร
  ToDecision VARCHAR(30) NOT NULL,             -- เปลี่ยนเป็นสถานะอะไร
  ChangedByContactId BIGINT REFERENCES SupplierContacts(Id),
  ChangedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  ChangeReason TEXT,
  
  CONSTRAINT uk_invitation_sequence UNIQUE(InvitationId, DecisionSequence)
);
CREATE INDEX idx_invitation_history_invitation ON RfqInvitationHistory(InvitationId);

-- 7.3 Quotations
-- ตาราง: ใบเสนอราคาจาก Supplier
CREATE TABLE Quotations (
  Id BIGSERIAL PRIMARY KEY,
  RfqId BIGINT NOT NULL REFERENCES Rfqs(Id),
  SupplierId BIGINT NOT NULL REFERENCES Suppliers(Id),
  QuotationNumber VARCHAR(50) UNIQUE,          -- เลขที่ใบเสนอราคา
  
  -- Quotation Details
  QuotationDate DATE DEFAULT CURRENT_DATE,
  ValidityDays INT DEFAULT 30,                 -- จำนวนวันที่ใบเสนอราคามีผล
  ExpiryDate DATE,                             -- วันหมดอายุ
  
  -- Total Amounts
  TotalAmount DECIMAL(18,4) NOT NULL,          -- ราคารวม
  CurrencyId BIGINT NOT NULL REFERENCES Currencies(Id),
  
  -- Converted Amounts (for comparison)
  ConvertedAmount DECIMAL(18,4),               -- ราคาที่แปลงเป็นสกุลเงินหลัก
  ConvertedCurrencyId BIGINT REFERENCES Currencies(Id),
  LockedExchangeRate DECIMAL(15,6),            -- อัตราแลกเปลี่ยนที่ล็อค
  LockedAt TIMESTAMP,
  
  -- Terms
  PaymentTerms TEXT,                           -- เงื่อนไขการชำระเงิน
  DeliveryTerms TEXT,                          -- เงื่อนไขการส่งมอบ
  IncotermId BIGINT REFERENCES Incoterms(Id),
  
  -- Status
  Status VARCHAR(20) DEFAULT 'DRAFT',
  SubmittedAt TIMESTAMP,
  IsWinner BOOLEAN DEFAULT FALSE,              -- เป็นผู้ชนะหรือไม่
  WinnerRanking INT,                           -- ลำดับที่ชนะ
  SelectionReason TEXT,                        -- เหตุผลที่เลือก
  
  -- Revision Tracking
  RevisionCount INT DEFAULT 0,                 -- จำนวนครั้งที่แก้ไข
  LastRevisedAt TIMESTAMP,
  
  -- Audit
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CreatedBy BIGINT,
  UpdatedAt TIMESTAMP,
  UpdatedBy BIGINT,
  
  UNIQUE(RfqId, SupplierId),
  CONSTRAINT chk_quotation_status CHECK (Status IN 
    ('DRAFT','SUBMITTED','REVISED','SELECTED','NOT_SELECTED'))
);

-- Create Indexes
CREATE INDEX idx_quotations_rfq ON Quotations(RfqId);
CREATE INDEX idx_quotations_supplier ON Quotations(SupplierId);
CREATE INDEX idx_quotations_status ON Quotations(Status);

-- 7.4 Quotation Items
-- ตาราง: รายการสินค้าในใบเสนอราคา
CREATE TABLE QuotationItems (
  Id BIGSERIAL PRIMARY KEY,
  QuotationId BIGINT NOT NULL REFERENCES Quotations(Id) ON DELETE CASCADE,
  RfqItemId BIGINT NOT NULL REFERENCES RfqItems(Id),
  
  -- Pricing
  UnitPrice DECIMAL(18,4) NOT NULL,            -- ราคาต่อหน่วย
  Quantity DECIMAL(12,4) NOT NULL,             -- จำนวน
  TotalPrice DECIMAL(18,4) NOT NULL,           -- ราคารวม
  
  -- Converted Pricing (Company Currency)
  ConvertedUnitPrice DECIMAL(18,4),
  ConvertedTotalPrice DECIMAL(18,4),
  
  -- Terms
  MinOrderQty INT,                             -- จำนวนสั่งซื้อขั้นต่ำ
  DeliveryDays INT,                            -- ระยะเวลาส่งมอบ (วัน)
  CreditDays INT,                              -- เครดิตเทอม (วัน)
  WarrantyDays INT,                            -- ระยะเวลารับประกัน (วัน)
  
  -- Remarks
  Remarks TEXT,
  
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE(QuotationId, RfqItemId)
);
CREATE INDEX idx_quotation_items_quotation ON QuotationItems(QuotationId);

-- 7.5 Quotation Documents
-- ตาราง: เอกสารแนบใบเสนอราคา
CREATE TABLE QuotationDocuments (
  Id BIGSERIAL PRIMARY KEY,
  QuotationId BIGINT NOT NULL REFERENCES Quotations(Id) ON DELETE CASCADE,
  DocumentType VARCHAR(50) NOT NULL,
  DocumentName VARCHAR(200) NOT NULL,
  FileName VARCHAR(255) NOT NULL,
  FilePath TEXT,
  FileSize BIGINT,
  MimeType VARCHAR(100),
  UploadedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UploadedBy BIGINT
);
CREATE INDEX idx_quotation_documents_quotation ON QuotationDocuments(QuotationId);

-- =============================================
-- SECTION 8: COMMUNICATION & Q&A
-- ตารางจัดการการสื่อสารระหว่าง Requester/Purchasing กับ Supplier
-- =============================================

-- 8.1 RFQ Questions and Answers
-- ตาราง: คำถาม-คำตอบเกี่ยวกับ RFQ
CREATE TABLE RfqQnA (
  Id BIGSERIAL PRIMARY KEY,
  RfqId BIGINT NOT NULL REFERENCES Rfqs(Id) ON DELETE CASCADE,
  SupplierId BIGINT NOT NULL REFERENCES Suppliers(Id),
  
  -- Question
  Question TEXT NOT NULL,                      -- คำถาม
  AskedBy BIGINT NOT NULL,                     -- ผู้ถาม (Contact ID)
  AskedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- วันเวลาที่ถาม
  
  -- Answer
  Answer TEXT,                                 -- คำตอบ
  AnsweredBy BIGINT,                           -- ผู้ตอบ (User ID)
  AnsweredAt TIMESTAMP,                        -- วันเวลาที่ตอบ
  
  -- Status
  Status VARCHAR(20) DEFAULT 'AWAITING',       -- สถานะ: AWAITING, ANSWERED
  IsPublic BOOLEAN DEFAULT FALSE,              -- แชร์กับ Supplier ทุกราย
  
  CONSTRAINT chk_qna_status CHECK (Status IN ('AWAITING','ANSWERED'))
);

-- Create Indexes
CREATE INDEX idx_rfq_qna_rfq ON RfqQnA(RfqId);
CREATE INDEX idx_rfq_qna_supplier ON RfqQnA(SupplierId);
CREATE INDEX idx_rfq_qna_status ON RfqQnA(Status) WHERE Status = 'AWAITING';

-- =============================================
-- SECTION 9: NOTIFICATION SYSTEM
-- ตารางจัดการการแจ้งเตือนในระบบ
-- =============================================

-- 9.1 Notifications
-- ตาราง: การแจ้งเตือน
CREATE TABLE Notifications (
  Id BIGSERIAL PRIMARY KEY,
  Type VARCHAR(50) NOT NULL,                   -- ประเภทการแจ้งเตือน
  Priority VARCHAR(20) DEFAULT 'NORMAL',       -- ระดับความสำคัญ
  NotificationType VARCHAR(30) DEFAULT 'INFO', -- ประเภทสำหรับแสดง icon (New)
  
  -- Target
  UserId BIGINT REFERENCES Users(Id),          -- ผู้รับ (User)
  RfqId BIGINT REFERENCES Rfqs(Id),            -- เกี่ยวกับ RFQ
  QuotationId BIGINT REFERENCES Quotations(Id),-- เกี่ยวกับใบเสนอราคา
  
  -- Content
  Title VARCHAR(200) NOT NULL,                 -- หัวข้อ
  Message TEXT NOT NULL,                       -- ข้อความ
  IconType VARCHAR(20),                        -- ไอคอน (✅, ❌, 🖊, 📨)
  ActionUrl TEXT,                               -- ลิงก์ไปยังหน้าที่เกี่ยวข้อง
  
  -- Status
  IsRead BOOLEAN DEFAULT FALSE,                -- อ่านแล้วหรือยัง
  ReadAt TIMESTAMP,                            -- วันเวลาที่อ่าน
  
  -- Delivery Channels
  Channels TEXT[],                             -- ช่องทางส่ง: {IN_APP, EMAIL, SMS}
  EmailSent BOOLEAN DEFAULT FALSE,
  EmailSentAt TIMESTAMP,
  SmsSent BOOLEAN DEFAULT FALSE,
  SmsSentAt TIMESTAMP,
  
  -- Scheduling
  ScheduledFor TIMESTAMP,                      -- กำหนดส่งเมื่อไหร่
  ProcessedAt TIMESTAMP,                       -- ประมวลผลเมื่อไหร่
  
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT chk_notification_priority CHECK (Priority IN ('CRITICAL','HIGH','NORMAL','LOW'))
);

-- Create Indexes
CREATE INDEX idx_notifications_user ON Notifications(UserId) WHERE IsRead = FALSE;
CREATE INDEX idx_notifications_scheduled ON Notifications(ScheduledFor) 
  WHERE ProcessedAt IS NULL AND ScheduledFor IS NOT NULL;

-- Comments
COMMENT ON COLUMN Notifications.NotificationType IS 'ประเภทการแจ้งเตือน: SUCCESS, ERROR, WARNING, INFO, MESSAGE - Frontend ใช้แสดง icon';

-- 9.2 Notification Rules
-- ตาราง: กฎการส่งการแจ้งเตือน
CREATE TABLE NotificationRules (
  Id BIGSERIAL PRIMARY KEY,
  RoleType VARCHAR(50) NOT NULL,               -- บทบาทที่เกี่ยวข้อง
  EventType VARCHAR(100) NOT NULL,             -- เหตุการณ์ที่ trigger
  
  -- Timing
  DaysAfterNoAction INT,                       -- จำนวนวันหลังไม่มีการ action
  HoursBeforeDeadline INT,                     -- จำนวนชั่วโมงก่อน deadline
  
  -- Recipients
  NotifyRecipients TEXT[],                     -- ผู้รับ: {SELF, REQUESTER, SUPERVISOR, ALL_SUPPLIERS}
  
  -- Configuration
  Priority VARCHAR(20) DEFAULT 'NORMAL',
  Channels TEXT[],                             -- ช่องทางส่ง: {IN_APP, EMAIL, SMS}
  
  -- Template
  TitleTemplate TEXT,                          -- template หัวข้อ
  MessageTemplate TEXT,                        -- template ข้อความ
  
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 9.3 Email Templates
-- ตาราง: Template อีเมล
CREATE TABLE EmailTemplates (
  Id BIGSERIAL PRIMARY KEY,
  TemplateCode VARCHAR(50) UNIQUE NOT NULL,    -- รหัส template
  TemplateName VARCHAR(100) NOT NULL,          -- ชื่อ template
  
  -- Content
  SubjectTemplate TEXT NOT NULL,               -- template หัวข้ออีเมล
  BodyTemplateHtml TEXT,                       -- template body HTML
  BodyTemplateText TEXT,                       -- template body Text
  
  -- Variables
  AvailableVariables TEXT[],                   -- ตัวแปรที่ใช้ได้
  
  -- Language
  Language VARCHAR(5) DEFAULT 'th',            -- ภาษา: th, en
  
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UpdatedAt TIMESTAMP
);

-- 9.4 Notification Queue
-- ตาราง: คิวการส่งการแจ้งเตือน
CREATE TABLE NotificationQueue (
  Id BIGSERIAL PRIMARY KEY,
  NotificationId BIGINT REFERENCES Notifications(Id),
  Channel VARCHAR(20) NOT NULL,                -- ช่องทางส่ง
  Recipient VARCHAR(255) NOT NULL,             -- ผู้รับ (email/phone)
  
  -- Content
  Subject VARCHAR(500),                        -- หัวข้อ
  Content TEXT,                                -- เนื้อหา
  
  -- Processing
  Priority VARCHAR(20) DEFAULT 'NORMAL',
  Status VARCHAR(20) DEFAULT 'PENDING',
  Attempts INT DEFAULT 0,                      -- จำนวนครั้งที่พยายามส่ง
  MaxAttempts INT DEFAULT 3,                   -- จำนวนครั้งสูงสุด
  
  -- Scheduling
  ScheduledFor TIMESTAMP,
  ProcessedAt TIMESTAMP,
  
  -- Error Handling
  LastError TEXT,                              -- error ล่าสุด
  LastAttemptAt TIMESTAMP,                     -- พยายามส่งล่าสุดเมื่อไหร่
  
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT chk_queue_status CHECK (Status IN ('PENDING','PROCESSING','SENT','FAILED'))
);

-- Create Index
CREATE INDEX idx_notification_queue_pending ON NotificationQueue(ScheduledFor, Priority)
  WHERE Status = 'PENDING';

-- =============================================
-- SECTION 10: FINANCIAL & EXCHANGE RATES
-- ตารางจัดการอัตราแลกเปลี่ยนและข้อมูลการเงิน
-- =============================================

-- 10.1 Exchange Rates
-- ตาราง: อัตราแลกเปลี่ยน
CREATE TABLE ExchangeRates (
  Id BIGSERIAL PRIMARY KEY,
  FromCurrencyId BIGINT NOT NULL REFERENCES Currencies(Id),  -- สกุลเงินต้นทาง
  ToCurrencyId BIGINT NOT NULL REFERENCES Currencies(Id),    -- สกุลเงินปลายทาง
  Rate DECIMAL(15,6) NOT NULL,                               -- อัตราแลกเปลี่ยน
  EffectiveDate DATE NOT NULL,                               -- วันที่มีผล
  ExpiryDate DATE,                                          -- วันหมดอายุ
  
  -- Source Information
  Source VARCHAR(50) DEFAULT 'MANUAL',         -- แหล่งที่มา: MANUAL, API, BOT, BANK
  SourceReference VARCHAR(100),                -- อ้างอิงแหล่งที่มา
  
  -- Audit
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CreatedBy BIGINT REFERENCES Users(Id),
  UpdatedAt TIMESTAMP,
  UpdatedBy BIGINT REFERENCES Users(Id),
  
  UNIQUE(FromCurrencyId, ToCurrencyId, EffectiveDate),
  CONSTRAINT chk_exchange_rate CHECK (Rate > 0)
);

-- Create Index
CREATE INDEX idx_exchange_rates_active ON ExchangeRates(FromCurrencyId, ToCurrencyId, EffectiveDate)
  WHERE IsActive = TRUE;

-- 10.2 Exchange Rate History
-- ตาราง: ประวัติการเปลี่ยนแปลงอัตราแลกเปลี่ยน
CREATE TABLE ExchangeRateHistory (
  Id BIGSERIAL PRIMARY KEY,
  ExchangeRateId BIGINT NOT NULL REFERENCES ExchangeRates(Id),
  OldRate DECIMAL(15,6),                       -- อัตราเดิม
  NewRate DECIMAL(15,6),                       -- อัตราใหม่
  ChangedBy BIGINT NOT NULL REFERENCES Users(Id),
  ChangedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  ChangeReason TEXT                            -- เหตุผลที่เปลี่ยน
);

-- =============================================
-- SECTION 11: AUTHENTICATION & SECURITY (New)
-- ตารางจัดการ Authentication และ Security
-- =============================================

-- 11.1 RefreshTokens (New)
-- ตาราง: JWT Refresh Tokens
CREATE TABLE RefreshTokens (
  Id BIGSERIAL PRIMARY KEY,
  Token VARCHAR(500) UNIQUE NOT NULL,          -- Refresh token
  
  -- User reference (รองรับทั้ง 2 user types)
  UserType VARCHAR(20) NOT NULL,               -- ประเภทผู้ใช้
  UserId BIGINT,                               -- For Employee users
  ContactId BIGINT,                            -- For Supplier contacts
  
  -- Token information
  ExpiresAt TIMESTAMP NOT NULL,                -- วันหมดอายุ
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CreatedByIp VARCHAR(45),                     -- IP ที่สร้าง token
  
  -- Revoke information
  RevokedAt TIMESTAMP,                         -- วันที่ revoke
  RevokedByIp VARCHAR(45),                     -- IP ที่ revoke
  ReplacedByToken VARCHAR(500),                -- Token ใหม่ที่แทนที่
  ReasonRevoked VARCHAR(100),                  -- เหตุผลที่ revoke
  
  -- Constraints
  CONSTRAINT chk_refresh_user_type CHECK (UserType IN ('Employee', 'SupplierContact')),
  CONSTRAINT chk_refresh_user_ref CHECK (
    (UserType = 'Employee' AND UserId IS NOT NULL AND ContactId IS NULL) OR
    (UserType = 'SupplierContact' AND ContactId IS NOT NULL AND UserId IS NULL)
  )
);

-- Create Indexes
CREATE INDEX idx_refresh_tokens_user ON RefreshTokens(UserId) 
  WHERE UserType = 'Employee';
CREATE INDEX idx_refresh_tokens_contact ON RefreshTokens(ContactId) 
  WHERE UserType = 'SupplierContact';
CREATE INDEX idx_refresh_tokens_active ON RefreshTokens(Token) 
  WHERE RevokedAt IS NULL AND ExpiresAt > NOW();

-- Comments
COMMENT ON TABLE RefreshTokens IS 'JWT Refresh Tokens สำหรับ Authentication';
COMMENT ON COLUMN RefreshTokens.UserType IS 'ประเภทผู้ใช้: Employee=พนักงาน, SupplierContact=ผู้ติดต่อ Supplier';
COMMENT ON COLUMN RefreshTokens.UserId IS 'User ID (ถ้าเป็นพนักงาน)';
COMMENT ON COLUMN RefreshTokens.ContactId IS 'Contact ID (ถ้าเป็น Supplier)';
COMMENT ON COLUMN RefreshTokens.ExpiresAt IS 'วันเวลาหมดอายุ';
COMMENT ON COLUMN RefreshTokens.RevokedAt IS 'วันเวลาที่ถูก revoke (NULL = ยังใช้งานอยู่)';
COMMENT ON COLUMN RefreshTokens.ReplacedByToken IS 'Token ใหม่ที่แทนที่ (Refresh Token Rotation)';
COMMENT ON COLUMN RefreshTokens.ReasonRevoked IS 'เหตุผล: Logout, Expired, Replaced, Revoked';

-- 11.2 LoginHistory (New)
-- ตาราง: ประวัติการ Login/Logout
CREATE TABLE LoginHistory (
  Id BIGSERIAL PRIMARY KEY,
  
  -- User reference
  UserType VARCHAR(20) NOT NULL,               -- ประเภทผู้ใช้
  UserId BIGINT,                               -- User ID (พนักงาน)
  ContactId BIGINT,                            -- Contact ID (Supplier)
  Email VARCHAR(100),                          -- อีเมลที่ใช้ login
  
  -- Login information
  LoginAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- วันเวลาที่ login
  LoginIp VARCHAR(45),                         -- IP Address
  UserAgent TEXT,                              -- Browser/Device info
  DeviceInfo TEXT,                             -- Device details
  
  -- Location (optional - จาก IP Geolocation)
  Country VARCHAR(100),                        -- ประเทศ
  City VARCHAR(100),                           -- เมือง
  
  -- Result
  Success BOOLEAN NOT NULL,                    -- สำเร็จหรือไม่
  FailureReason VARCHAR(200),                  -- เหตุผลที่ล้มเหลว
  
  -- Session information
  SessionId VARCHAR(100),                      -- Session ID
  RefreshTokenId BIGINT REFERENCES RefreshTokens(Id),
  LogoutAt TIMESTAMP,                          -- วันเวลาที่ logout
  LogoutType VARCHAR(20),                      -- ประเภท logout
  
  -- Constraints
  CONSTRAINT chk_login_user_type CHECK (UserType IN ('Employee', 'SupplierContact'))
);

-- Create Indexes
CREATE INDEX idx_login_history_user ON LoginHistory(UserId) 
  WHERE UserType = 'Employee';
CREATE INDEX idx_login_history_contact ON LoginHistory(ContactId) 
  WHERE UserType = 'SupplierContact';
CREATE INDEX idx_login_history_date ON LoginHistory(LoginAt DESC);
CREATE INDEX idx_login_history_email ON LoginHistory(Email);

-- Comments
COMMENT ON TABLE LoginHistory IS 'ประวัติการ Login/Logout ทุกครั้ง - Audit Trail';
COMMENT ON COLUMN LoginHistory.Success IS 'TRUE = login สำเร็จ, FALSE = login ล้มเหลว';
COMMENT ON COLUMN LoginHistory.FailureReason IS 'สาเหตุที่ login ไม่สำเร็จ';
COMMENT ON COLUMN LoginHistory.LogoutType IS 'MANUAL=ผู้ใช้ logout เอง, TIMEOUT=หมดเวลา, FORCED=ถูกบังคับ logout';

-- =============================================
-- SECTION 12: SYSTEM & AUDIT
-- ตารางสำหรับ Audit Trail และ System Configuration
-- =============================================

-- 12.1 Activity Logs
-- ตาราง: บันทึกกิจกรรมในระบบ
CREATE TABLE ActivityLogs (
  Id BIGSERIAL PRIMARY KEY,
  UserId BIGINT REFERENCES Users(Id),          -- ผู้ทำกิจกรรม
  CompanyId BIGINT REFERENCES Companies(Id),   -- บริษัทที่เกี่ยวข้อง
  
  -- Activity Details
  Module VARCHAR(50),                          -- โมดูลที่เกิดกิจกรรม
  Action VARCHAR(100),                         -- การกระทำ (CREATE, UPDATE, DELETE)
  EntityType VARCHAR(50),                      -- ประเภท Entity
  EntityId BIGINT,                             -- ID ของ Entity
  
  -- Additional Information
  OldValues JSONB,                             -- ค่าเดิม (JSON)
  NewValues JSONB,                             -- ค่าใหม่ (JSON)
  IpAddress INET,                              -- IP Address
  UserAgent TEXT,                              -- Browser/Device
  SessionId VARCHAR(100),                      -- Session ID
  
  -- Timestamp
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Indexes
CREATE INDEX idx_activity_logs_user ON ActivityLogs(UserId);
CREATE INDEX idx_activity_logs_entity ON ActivityLogs(EntityType, EntityId);
CREATE INDEX idx_activity_logs_date ON ActivityLogs(CreatedAt DESC);

-- 12.2 System Configurations
-- ตาราง: การตั้งค่าระบบ
CREATE TABLE SystemConfigurations (
  Id BIGSERIAL PRIMARY KEY,
  ConfigKey VARCHAR(100) UNIQUE NOT NULL,      -- คีย์การตั้งค่า
  ConfigValue TEXT,                            -- ค่าการตั้งค่า
  ConfigType VARCHAR(20),                      -- ประเภท: STRING, NUMBER, BOOLEAN, JSON
  Description TEXT,                            -- คำอธิบาย
  IsEncrypted BOOLEAN DEFAULT FALSE,           -- เข้ารหัสหรือไม่
  
  -- Scope
  CompanyId BIGINT REFERENCES Companies(Id),   -- การตั้งค่าเฉพาะบริษัท (NULL = ทั้งระบบ)
  
  -- Audit
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CreatedBy BIGINT REFERENCES Users(Id),
  UpdatedAt TIMESTAMP,
  UpdatedBy BIGINT REFERENCES Users(Id)
);

-- Create Index
CREATE INDEX idx_system_config_key ON SystemConfigurations(ConfigKey) WHERE IsActive = TRUE;

-- 12.3 Error Logs
-- ตาราง: บันทึก Error ในระบบ
CREATE TABLE ErrorLogs (
  Id BIGSERIAL PRIMARY KEY,
  ErrorCode VARCHAR(50),                       -- รหัส Error
  ErrorMessage TEXT NOT NULL,                  -- ข้อความ Error
  ErrorDetails TEXT,                           -- รายละเอียด Error
  StackTrace TEXT,                             -- Stack trace
  
  -- Context
  UserId BIGINT,                               -- User ที่เกิด error
  Module VARCHAR(50),                          -- โมดูลที่เกิด error
  Action VARCHAR(100),                         -- การกระทำที่ทำให้เกิด error
  RequestUrl TEXT,                             -- URL ที่ request
  RequestMethod VARCHAR(10),                   -- HTTP Method
  RequestData TEXT,                            -- ข้อมูลที่ส่งมา
  
  -- Environment
  ServerName VARCHAR(100),                     -- ชื่อ Server
  Environment VARCHAR(20),                     -- Environment: DEV, UAT, PROD
  IpAddress INET,                              -- IP Address
  UserAgent TEXT,                              -- Browser/Device
  
  -- Status
  IsResolved BOOLEAN DEFAULT FALSE,            -- แก้ไขแล้วหรือยัง
  ResolvedBy BIGINT REFERENCES Users(Id),
  ResolvedAt TIMESTAMP,
  ResolutionNotes TEXT,                        -- บันทึกการแก้ไข
  
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Indexes
CREATE INDEX idx_error_logs_date ON ErrorLogs(CreatedAt DESC);
CREATE INDEX idx_error_logs_unresolved ON ErrorLogs(CreatedAt DESC) WHERE IsResolved = FALSE;

-- =============================================
-- SECTION 13: REPORTING & ANALYTICS
-- ตารางสำหรับ Reports และ Analytics
-- =============================================

-- 13.1 Report Templates
-- ตาราง: Template รายงาน
CREATE TABLE ReportTemplates (
  Id BIGSERIAL PRIMARY KEY,
  ReportCode VARCHAR(50) UNIQUE NOT NULL,      -- รหัสรายงาน
  ReportName VARCHAR(200) NOT NULL,            -- ชื่อรายงาน
  ReportNameTh VARCHAR(200),                   -- ชื่อรายงานภาษาไทย
  Category VARCHAR(50),                        -- หมวดหมู่รายงาน
  
  -- Configuration
  QueryTemplate TEXT,                          -- SQL Query template
  Parameters JSONB,                            -- พารามิเตอร์ที่ใช้
  OutputFormat VARCHAR(20),                    -- รูปแบบ output: PDF, EXCEL, CSV
  
  -- Permissions
  RequiredRoles TEXT[],                        -- บทบาทที่ดูได้
  
  -- Scheduling
  IsScheduled BOOLEAN DEFAULT FALSE,           -- มีการตั้งเวลาหรือไม่
  ScheduleCron VARCHAR(100),                   -- Cron expression
  
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UpdatedAt TIMESTAMP
);

-- 13.2 Report Executions
-- ตาราง: ประวัติการรันรายงาน
CREATE TABLE ReportExecutions (
  Id BIGSERIAL PRIMARY KEY,
  ReportTemplateId BIGINT NOT NULL REFERENCES ReportTemplates(Id),
  
  -- Execution Details
  ExecutedBy BIGINT NOT NULL REFERENCES Users(Id),
  ExecutedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  Parameters JSONB,                            -- พารามิเตอร์ที่ใช้
  
  -- Results
  Status VARCHAR(20) DEFAULT 'RUNNING',        -- RUNNING, COMPLETED, FAILED
  RecordCount INT,                             -- จำนวน record
  FilePath TEXT,                               -- path ไฟล์ผลลัพธ์
  FileSize BIGINT,                             -- ขนาดไฟล์
  ExecutionTime INT,                           -- เวลาที่ใช้ (milliseconds)
  
  -- Error Handling
  ErrorMessage TEXT,
  
  CONSTRAINT chk_report_status CHECK (Status IN ('RUNNING','COMPLETED','FAILED'))
);

-- Create Indexes
CREATE INDEX idx_report_executions_template ON ReportExecutions(ReportTemplateId);
CREATE INDEX idx_report_executions_user ON ReportExecutions(ExecutedBy);
CREATE INDEX idx_report_executions_date ON ReportExecutions(ExecutedAt DESC);

-- =============================================
-- INITIAL DATA INSERTION
-- ข้อมูลเริ่มต้นสำหรับระบบ
-- =============================================

-- Insert Roles (Including new Managing Director role)
INSERT INTO Roles (RoleCode, RoleName, RoleNameTh, RoleLevel, Description) VALUES
  ('SUPER_ADMIN', 'Super Administrator', 'ผู้ดูแลระบบสูงสุด', 0, 'Full system access'),
  ('ADMIN', 'Administrator', 'ผู้ดูแลระบบ', 1, 'System administration'),
  ('REQUESTER', 'Requester', 'ผู้ขอเสนอราคา', 5, 'Create and submit RFQs'),
  ('APPROVER', 'Approver', 'ผู้อนุมัติ', 3, 'Approve RFQs'),
  ('PURCHASING', 'Purchasing', 'จัดซื้อ', 4, 'Manage RFQs and suppliers'),
  ('PURCHASING_APPROVER', 'Purchasing Approver', 'ผู้อนุมัติจัดซื้อ', 2, 'Approve supplier selection'),
  ('SUPPLIER', 'Supplier', 'ผู้ขาย/ผู้รับเหมา', 10, 'Submit quotations'),
  ('MANAGING_DIRECTOR', 'Managing Director, Manager', 'กรรมการผู้จัดการ, ผู้จัดการ', 0, 'Executive dashboard and reports access')
ON CONFLICT (RoleCode) DO UPDATE
SET 
  RoleName = EXCLUDED.RoleName,
  RoleNameTh = EXCLUDED.RoleNameTh,
  RoleLevel = EXCLUDED.RoleLevel,
  Description = EXCLUDED.Description;

-- Insert Business Types
INSERT INTO BusinessTypes (Id, Code, NameTh, NameEn, SortOrder) VALUES
  (1, 'INDIVIDUAL', 'บุคคลธรรมดา', 'Individual', 1),
  (2, 'CORPORATE', 'นิติบุคคล', 'Corporate', 2)
ON CONFLICT (Id) DO NOTHING;

-- Insert Job Types
INSERT INTO JobTypes (Id, Code, NameTh, NameEn, ForSupplier, ForRfq, PriceComparisonRule, SortOrder) VALUES
  (1, 'BUY', 'ซื้อ', 'Buy', TRUE, TRUE, 'MIN', 1),
  (2, 'SELL', 'ขาย', 'Sell', TRUE, TRUE, 'MAX', 2),
  (3, 'BOTH', 'ทั้งซื้อและขาย', 'Both Buy and Sell', TRUE, FALSE, NULL, 3)
ON CONFLICT (Id) DO NOTHING;

-- Insert Common Currencies
INSERT INTO Currencies (CurrencyCode, CurrencyName, CurrencySymbol, DecimalPlaces) VALUES
  ('THB', 'Thai Baht', '฿', 2),
  ('USD', 'US Dollar', ', 2),
  ('EUR', 'Euro', '€', 2),
  ('GBP', 'British Pound', '£', 2),
  ('JPY', 'Japanese Yen', '¥', 0),
  ('CNY', 'Chinese Yuan', '¥', 2)
ON CONFLICT (CurrencyCode) DO NOTHING;

-- Insert Common Incoterms
INSERT INTO Incoterms (IncotermCode, IncotermName, Description) VALUES
  ('EXW', 'Ex Works', 'Seller makes goods available at their premises'),
  ('FOB', 'Free On Board', 'Seller delivers goods on board the vessel'),
  ('CIF', 'Cost, Insurance and Freight', 'Seller pays costs, insurance and freight'),
  ('DDP', 'Delivered Duty Paid', 'Seller delivers goods with all duties paid')
ON CONFLICT (IncotermCode) DO NOTHING;

-- =============================================
-- END OF DATABASE SCHEMA
-- Version: 3.0
-- Last Updated: January 2025
-- Total Tables: 62
-- =============================================