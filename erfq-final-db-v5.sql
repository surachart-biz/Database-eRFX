-- =============================================
-- E-RFQ System Complete Database Schema v5.0
-- Production Ready Version
-- Database: erfq_system
-- PostgreSQL Version: 14+
-- Last Updated: January 2025
-- =============================================

-- =============================================
-- DATABASE CONFIGURATION
-- =============================================
--CREATE DATABASE erfq_system
--  WITH
--  OWNER = postgres
--  ENCODING = 'UTF8'
--  LC_COLLATE = 'en_US.UTF-8'
--  LC_CTYPE = 'en_US.UTF-8'
--  TABLESPACE = pg_default
--  CONNECTION LIMIT = -1;

-- Enable Required Extensions
--CREATE EXTENSION IF NOT EXISTS "uuid-ossp";    -- สำหรับ generate UUID
-- EXTENSION IF NOT EXISTS "pgcrypto";     -- สำหรับ encryption

-- =============================================
-- SECTION 1: MASTER DATA & LOOKUPS
-- ตารางหลักสำหรับข้อมูลอ้างอิงพื้นฐานของระบบ
-- =============================================

-- 1.1 Currencies
-- ตาราง: สกุลเงินที่ใช้ในระบบ
CREATE TABLE Currencies (
  Id BIGSERIAL PRIMARY KEY,
  CurrencyCode VARCHAR(3) UNIQUE NOT NULL,     -- รหัสสกุลเงิน (USD, THB)
  CurrencyName VARCHAR(100) NOT NULL,          -- ชื่อสกุลเงิน
  CurrencySymbol VARCHAR(10),                  -- สัญลักษณ์ ($, ฿)
  DecimalPlaces SMALLINT DEFAULT 2,            -- จำนวนทศนิยม
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UpdatedAt TIMESTAMP,
  
  CONSTRAINT chk_currency_code CHECK (LENGTH(CurrencyCode) = 3),
  CONSTRAINT chk_decimal_places CHECK (DecimalPlaces BETWEEN 0 AND 4)
);

COMMENT ON TABLE Currencies IS 'สกุลเงินที่ใช้ในระบบ';
COMMENT ON COLUMN Currencies.CurrencyCode IS 'รหัสสกุลเงิน 3 ตัว ISO 4217';
COMMENT ON COLUMN Currencies.DecimalPlaces IS 'จำนวนทศนิยมที่แสดง';

-- 1.2 Countries
-- ตาราง: ข้อมูลประเทศ
CREATE TABLE Countries (
  Id BIGSERIAL PRIMARY KEY,
  CountryCode VARCHAR(2) UNIQUE NOT NULL,      -- รหัสประเทศ ISO 3166
  CountryNameEn VARCHAR(100) NOT NULL,         -- ชื่อประเทศ (อังกฤษ)
  CountryNameTh VARCHAR(100),                  -- ชื่อประเทศ (ไทย)
  DefaultCurrencyId BIGINT REFERENCES Currencies(Id),  -- สกุลเงินหลัก
  Timezone VARCHAR(50) DEFAULT 'Asia/Bangkok', -- โซนเวลา
  PhoneCode VARCHAR(5),                        -- รหัสโทรศัพท์ (+66, +1)
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT chk_country_code CHECK (LENGTH(CountryCode) = 2)
);

COMMENT ON TABLE Countries IS 'ข้อมูลประเทศ';
COMMENT ON COLUMN Countries.CountryCode IS 'รหัสประเทศ 2 ตัว ISO 3166';

-- 1.3 BusinessTypes
-- ตาราง: ประเภทธุรกิจ
CREATE TABLE BusinessTypes (
  Id SMALLINT PRIMARY KEY,
  Code VARCHAR(20) UNIQUE NOT NULL,            -- INDIVIDUAL, CORPORATE
  NameTh VARCHAR(50) NOT NULL,                 -- บุคคลธรรมดา, นิติบุคคล
  NameEn VARCHAR(50),
  SortOrder SMALLINT,
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE BusinessTypes IS 'ประเภทธุรกิจ (บุคคลธรรมดา/นิติบุคคล)';

-- 1.4 JobTypes
-- ตาราง: ประเภทงาน
CREATE TABLE JobTypes (
  Id SMALLINT PRIMARY KEY,
  Code VARCHAR(20) UNIQUE NOT NULL,            -- BUY, SELL, BOTH
  NameTh VARCHAR(50) NOT NULL,                 -- ซื้อ, ขาย, ทั้งหมด
  NameEn VARCHAR(50),
  ForSupplier BOOLEAN DEFAULT TRUE,            -- ใช้กับ Supplier
  ForRfq BOOLEAN DEFAULT TRUE,                 -- ใช้กับ RFQ
  PriceComparisonRule VARCHAR(10),             -- MIN=ซื้อ, MAX=ขาย
  SortOrder SMALLINT,
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE JobTypes IS 'ประเภทงาน (ซื้อ/ขาย)';
COMMENT ON COLUMN JobTypes.PriceComparisonRule IS 'MIN=เลือกราคาต่ำสุด(ซื้อ), MAX=เลือกราคาสูงสุด(ขาย)';

-- 1.5 Roles  
-- ตาราง: บทบาทผู้ใช้งาน
CREATE TABLE Roles (
  Id BIGSERIAL PRIMARY KEY,
  RoleCode VARCHAR(30) UNIQUE NOT NULL,
  RoleName VARCHAR(100) NOT NULL,
  RoleNameTh VARCHAR(100),
  Description TEXT,
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT chk_role_code CHECK (RoleCode IN 
    ('SUPER_ADMIN','ADMIN','REQUESTER','APPROVER','PURCHASING',
     'PURCHASING_APPROVER','SUPPLIER','MANAGING_DIRECTOR'))
);

COMMENT ON TABLE Roles IS 'บทบาทผู้ใช้งานในระบบ';
-- Note: ลบ RoleLevel ออกเพราะไม่ได้ใช้งาน

-- 1.6 Permissions
-- ตาราง: สิทธิ์การใช้งาน
CREATE TABLE Permissions (
  Id BIGSERIAL PRIMARY KEY,
  PermissionCode VARCHAR(50) UNIQUE NOT NULL,
  PermissionName VARCHAR(100) NOT NULL,
  PermissionNameTh VARCHAR(100),
  Module VARCHAR(50),                          -- RFQ, SUPPLIER, REPORT
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE Permissions IS 'สิทธิ์การใช้งานในระบบ';

-- 1.7 RolePermissions
-- ตาราง: ความสัมพันธ์ระหว่าง Role และ Permission
CREATE TABLE RolePermissions (
  Id BIGSERIAL PRIMARY KEY,
  RoleId BIGINT NOT NULL REFERENCES Roles(Id),
  PermissionId BIGINT NOT NULL REFERENCES Permissions(Id),
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CreatedBy BIGINT,
  
  UNIQUE(RoleId, PermissionId)
);

COMMENT ON TABLE RolePermissions IS 'กำหนดสิทธิ์ให้แต่ละบทบาท';

-- 1.8 Categories
-- ตาราง: หมวดหมู่สินค้า/บริการ
CREATE TABLE Categories (
  Id BIGSERIAL PRIMARY KEY,
  CategoryCode VARCHAR(50) UNIQUE NOT NULL,
  CategoryNameTh VARCHAR(200) NOT NULL,
  CategoryNameEn VARCHAR(200),
  Description TEXT,
  SortOrder INT,                               -- ลำดับการแสดงผล
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UpdatedAt TIMESTAMP
);

COMMENT ON TABLE Categories IS 'หมวดหมู่สินค้า/บริการ';
COMMENT ON COLUMN Categories.SortOrder IS 'ลำดับการแสดงผลใน dropdown';

-- 1.9 Subcategories
-- ตาราง: หมวดหมู่ย่อย
CREATE TABLE Subcategories (
  Id BIGSERIAL PRIMARY KEY,
  CategoryId BIGINT NOT NULL REFERENCES Categories(Id),
  SubcategoryCode VARCHAR(50) NOT NULL,
  SubcategoryNameTh VARCHAR(200) NOT NULL,
  SubcategoryNameEn VARCHAR(200),
  IsUseSerialNumber BOOLEAN DEFAULT FALSE,     -- บังคับใส่ Serial Number
  Duration INT DEFAULT 7,                      -- ระยะเวลาตอบกลับ (วัน)
  ResponseTimeDays INT DEFAULT 2,              -- เวลาตอบสนอง (วัน)
  Description TEXT,
  SortOrder INT,
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UpdatedAt TIMESTAMP,
  
  UNIQUE(CategoryId, SubcategoryCode)
);

COMMENT ON TABLE Subcategories IS 'หมวดหมู่ย่อยของสินค้า/บริการ';
COMMENT ON COLUMN Subcategories.IsUseSerialNumber IS 'บังคับกรอก Serial Number';
COMMENT ON COLUMN Subcategories.Duration IS 'จำนวนวันสำหรับคำนวณ deadline';
COMMENT ON COLUMN Subcategories.ResponseTimeDays IS 'จำนวนวันที่ต้อง action';

-- 1.10 SubcategoryDocRequirements
-- ตาราง: เอกสารที่ต้องแนบตาม Subcategory
CREATE TABLE SubcategoryDocRequirements (
  Id BIGSERIAL PRIMARY KEY,
  SubcategoryId BIGINT NOT NULL REFERENCES Subcategories(Id),
  DocumentName VARCHAR(200) NOT NULL,
  DocumentNameEn VARCHAR(200),
  IsRequired BOOLEAN DEFAULT TRUE,
  MaxFileSize INT DEFAULT 30,                  -- MB
  AllowedExtensions TEXT,                      -- pdf,doc,xlsx
  SortOrder INT,
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE SubcategoryDocRequirements IS 'เอกสารที่ต้องแนบตาม Subcategory';

-- 1.11 Incoterms
-- ตาราง: เงื่อนไขการส่งมอบสินค้า
CREATE TABLE Incoterms (
  Id BIGSERIAL PRIMARY KEY,
  IncotermCode VARCHAR(3) UNIQUE NOT NULL,     -- FOB, CIF, EXW
  IncotermName VARCHAR(100) NOT NULL,
  Description TEXT,
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE Incoterms IS 'เงื่อนไขการส่งมอบสินค้าระหว่างประเทศ';

-- =============================================
-- SECTION 2: COMPANY & ORGANIZATION
-- =============================================

-- 2.1 Companies
-- ตาราง: บริษัทในระบบ
CREATE TABLE Companies (
  Id BIGSERIAL PRIMARY KEY,
  CompanyCode VARCHAR(20) UNIQUE NOT NULL,
  CompanyNameTh VARCHAR(150),
  CompanyNameEn VARCHAR(150),
  ShortNameEn VARCHAR(10) NOT NULL UNIQUE,     -- ใช้สร้างเลข RFQ
  TaxId VARCHAR(20) UNIQUE,
  
  -- Location & Currency
  CountryId BIGINT NOT NULL REFERENCES Countries(Id),
  DefaultCurrencyId BIGINT NOT NULL REFERENCES Currencies(Id),
  
  -- Business Information
  BusinessTypeId SMALLINT REFERENCES BusinessTypes(Id),
  RegisteredCapital DECIMAL(15,2),
  RegisteredCapitalCurrencyId BIGINT REFERENCES Currencies(Id),
  FoundedDate DATE,
  
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
  
  CONSTRAINT chk_company_status CHECK (Status IN ('ACTIVE','INACTIVE'))
);

COMMENT ON TABLE Companies IS 'บริษัทในระบบ (Multi-Company Support)';
COMMENT ON COLUMN Companies.ShortNameEn IS 'ชื่อย่อสำหรับสร้างเลข RFQ';

-- 2.2 Departments
-- ตาราง: แผนกภายในบริษัท
CREATE TABLE Departments (
  Id BIGSERIAL PRIMARY KEY,
  CompanyId BIGINT NOT NULL REFERENCES Companies(Id),
  DepartmentCode VARCHAR(50) NOT NULL,
  DepartmentNameTh VARCHAR(200) NOT NULL,
  DepartmentNameEn VARCHAR(200),
  ManagerUserId BIGINT,                        -- ผู้จัดการแผนก
  CostCenter VARCHAR(50),
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UpdatedAt TIMESTAMP,
  
  UNIQUE(CompanyId, DepartmentCode)
);

COMMENT ON TABLE Departments IS 'แผนกภายในบริษัท';
-- Note: ลบ ParentDepartmentId ออกเพราะไม่มี hierarchy

-- =============================================
-- SECTION 3: USER MANAGEMENT
-- =============================================

-- 3.1 Users
-- ตาราง: พนักงานภายในบริษัท
CREATE TABLE Users (
  Id BIGSERIAL PRIMARY KEY,
  EmployeeCode VARCHAR(50),
  Email VARCHAR(100) UNIQUE NOT NULL,          -- ใช้ login
  PasswordHash VARCHAR(255) NOT NULL,
  
  -- Personal Information
  FirstNameTh VARCHAR(100),
  LastNameTh VARCHAR(100),
  FirstNameEn VARCHAR(100),
  LastNameEn VARCHAR(100),
  PhoneNumber VARCHAR(20),
  MobileNumber VARCHAR(20),
  
  -- Authentication & Security
  IsEmailVerified BOOLEAN DEFAULT FALSE,
  EmailVerifiedAt TIMESTAMP,
  PasswordResetToken VARCHAR(255),
  PasswordResetExpiry TIMESTAMP,
  SecurityStamp VARCHAR(100),                  -- JWT invalidation
  LastLoginAt TIMESTAMP,
  LockoutEnabled BOOLEAN DEFAULT TRUE,
  LockoutEnd TIMESTAMP WITH TIME ZONE,
  AccessFailedCount INT DEFAULT 0,
  
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
  
  CONSTRAINT chk_user_status CHECK (Status IN ('ACTIVE','INACTIVE'))
);

COMMENT ON TABLE Users IS 'พนักงานภายในบริษัท (Internal Users)';
COMMENT ON COLUMN Users.Email IS 'ใช้เป็น username สำหรับ login';
COMMENT ON COLUMN Users.IsDeleted IS 'Soft delete flag';
-- Note: ลบ Username ออกเพราะใช้ Email login

-- 3.2 UserCompanyRoles
-- ตาราง: บทบาทของ User 
-- REQUESTER = 3, APPROVER = 4, PURCHASING = 5
--'Role IDs: 3=REQUESTER, 4=APPROVER, 5=PURCHASING - REQUESTER cannot be APPROVER or PURCHASING';
CREATE TABLE UserCompanyRoles (
  Id BIGSERIAL PRIMARY KEY,
  UserId BIGINT NOT NULL REFERENCES Users(Id),
  CompanyId BIGINT NOT NULL REFERENCES Companies(Id),
  DepartmentId BIGINT REFERENCES Departments(Id),
  
  -- Primary and Secondary Roles
  PrimaryRoleId BIGINT NOT NULL REFERENCES Roles(Id),
  SecondaryRoleId BIGINT REFERENCES Roles(Id),
  
  -- Role-specific configurations
  ApproverLevel SMALLINT CHECK (ApproverLevel BETWEEN 1 AND 3),
  
  -- Validity Period
  StartDate DATE NOT NULL,
  EndDate DATE,
  
  -- Status
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CreatedBy BIGINT,
  UpdatedAt TIMESTAMP,
  UpdatedBy BIGINT,
  
  UNIQUE(UserId, CompanyId),
  CONSTRAINT chk_role_rules CHECK (
  --ใช้ Hard-coded Role IDs (Simple but Less Flexible) + Application Layer Validation (Most Flexible)
    -- Requester cannot be Approver or Purchasing
    NOT (
        (PrimaryRoleId = 3 AND SecondaryRoleId IN (4, 5))
        OR 
        (SecondaryRoleId = 3 AND PrimaryRoleId IN (4, 5))
    )
  ),
  CONSTRAINT chk_date_validity CHECK (EndDate IS NULL OR EndDate > StartDate)
);

COMMENT ON TABLE UserCompanyRoles IS 'บทบาทของ User ในแต่ละบริษัท';
COMMENT ON COLUMN UserCompanyRoles.ApproverLevel IS 'ระดับการอนุมัติ 1-3';

-- 3.3 UserCategoryBindings
-- ตาราง: Category ที่ Purchasing รับผิดชอบ
CREATE TABLE UserCategoryBindings (
  Id BIGSERIAL PRIMARY KEY,
  UserCompanyRoleId BIGINT NOT NULL REFERENCES UserCompanyRoles(Id),
  CategoryId BIGINT NOT NULL REFERENCES Categories(Id),
  SubcategoryId BIGINT REFERENCES Subcategories(Id),
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE(UserCompanyRoleId, CategoryId, SubcategoryId)
);

COMMENT ON TABLE UserCategoryBindings IS 'กำหนด Category ที่ Purchasing รับผิดชอบ';

-- 3.4 Delegations
-- ตาราง: การมอบหมายงานชั่วคราว
CREATE TABLE Delegations (
  Id BIGSERIAL PRIMARY KEY,
  FromUserId BIGINT NOT NULL REFERENCES Users(Id),
  ToUserId BIGINT NOT NULL REFERENCES Users(Id),
  CompanyId BIGINT NOT NULL REFERENCES Companies(Id),
  RoleId BIGINT NOT NULL REFERENCES Roles(Id),
  StartDate TIMESTAMP NOT NULL,
  EndDate TIMESTAMP NOT NULL,
  Reason TEXT,
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CreatedBy BIGINT,
  
  CONSTRAINT chk_delegation_dates CHECK (EndDate > StartDate),
  CONSTRAINT chk_delegation_users CHECK (FromUserId != ToUserId)
);

COMMENT ON TABLE Delegations IS 'การมอบหมายงานชั่วคราว (เช่น ลางาน)';

-- =============================================
-- SECTION 4: SUPPLIER MANAGEMENT
-- =============================================

-- 4.1 Suppliers
-- ตาราง: ข้อมูล Supplier
CREATE TABLE Suppliers (
  Id BIGSERIAL PRIMARY KEY,
  
  -- Company Information
  TaxId VARCHAR(20) UNIQUE,
  CompanyNameTh VARCHAR(200) NOT NULL,
  CompanyNameEn VARCHAR(200),
  BusinessTypeId SMALLINT NOT NULL REFERENCES BusinessTypes(Id),
  JobTypeId SMALLINT NOT NULL REFERENCES JobTypes(Id),
  
  -- Financial Information
  RegisteredCapital DECIMAL(15,2),
  RegisteredCapitalCurrencyId BIGINT REFERENCES Currencies(Id),
  DefaultCurrencyId BIGINT REFERENCES Currencies(Id),
  
  -- Contact Information
  CompanyEmail VARCHAR(100),
  CompanyPhone VARCHAR(20),
  CompanyFax VARCHAR(20),
  CompanyWebsite VARCHAR(200),
  
  -- Address
  AddressLine1 VARCHAR(200),
  AddressLine2 VARCHAR(200),
  City VARCHAR(100),
  Province VARCHAR(100),
  PostalCode VARCHAR(20),
  CountryId BIGINT REFERENCES Countries(Id),
  
  -- Business Details
  BusinessScope TEXT,                          -- max 500 chars
  FoundedDate DATE,
  
  -- Registration & Approval
  InvitedByUserId BIGINT REFERENCES Users(Id), -- User ที่เชิญลงทะเบียน
  InvitedByCompanyId BIGINT REFERENCES Companies(Id),  -- บริษัทที่เชิญ
  InvitedAt TIMESTAMP,                         -- วันเวลาที่เชิญ
  RegisteredAt TIMESTAMP,                      -- วันเวลาที่ลงทะเบียน
  ApprovedByUserId BIGINT REFERENCES Users(Id),-- User ที่อนุมัติ
  ApprovedAt TIMESTAMP,                        -- วันเวลาที่อนุมัติ
  
  -- Status Management
  Status VARCHAR(20) DEFAULT 'PENDING',
  DeclineReason TEXT,
  
  -- System Fields
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UpdatedAt TIMESTAMP,
  
  CONSTRAINT chk_supplier_status CHECK (Status IN ('PENDING','COMPLETED','DECLINED'))
);

COMMENT ON TABLE Suppliers IS 'ข้อมูล Supplier ที่ลงทะเบียนในระบบ';
COMMENT ON COLUMN Suppliers.BusinessScope IS 'ขอบเขตธุรกิจ (max 500 ตัวอักษร)';

-- 4.2 SupplierContacts
-- ตาราง: ผู้ติดต่อของ Supplier
CREATE TABLE SupplierContacts (
  Id BIGSERIAL PRIMARY KEY,
  SupplierId BIGINT NOT NULL REFERENCES Suppliers(Id),
  
  -- Personal Information
  FirstName VARCHAR(100) NOT NULL,
  LastName VARCHAR(100) NOT NULL,
  Position VARCHAR(100),
  Email VARCHAR(100) NOT NULL,                 -- ใช้ login
  PhoneNumber VARCHAR(20),
  MobileNumber VARCHAR(20),
  
  -- Authentication
  PasswordHash VARCHAR(255),
  SecurityStamp VARCHAR(100),
  
  -- Security Settings
  IsEmailVerified BOOLEAN DEFAULT FALSE,
  EmailVerifiedAt TIMESTAMP,
  PasswordResetToken VARCHAR(255),
  PasswordResetExpiry TIMESTAMP,
  LastLoginAt TIMESTAMP,
  FailedLoginAttempts INT DEFAULT 0,
  LockoutEnd TIMESTAMP WITH TIME ZONE,
  
  -- Permissions
  CanSubmitQuotation BOOLEAN DEFAULT TRUE,
  CanViewReports BOOLEAN DEFAULT FALSE,
  IsPrimaryContact BOOLEAN DEFAULT FALSE,      -- Primary contact flag
  
  -- Status & Audit
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CreatedBy BIGINT,
  UpdatedAt TIMESTAMP,
  UpdatedBy BIGINT,
  
  UNIQUE(SupplierId, Email)
);

COMMENT ON TABLE SupplierContacts IS 'ผู้ติดต่อของ Supplier';
COMMENT ON COLUMN SupplierContacts.IsPrimaryContact IS 'เป็น Primary Contact หรือไม่';

-- 4.3 SupplierCategories
-- ตาราง: Category ที่ Supplier ให้บริการ
CREATE TABLE SupplierCategories (
  Id BIGSERIAL PRIMARY KEY,
  SupplierId BIGINT NOT NULL REFERENCES Suppliers(Id),
  CategoryId BIGINT NOT NULL REFERENCES Categories(Id),
  SubcategoryId BIGINT REFERENCES Subcategories(Id),
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE(SupplierId, CategoryId, SubcategoryId)
);

COMMENT ON TABLE SupplierCategories IS 'Category ที่ Supplier ให้บริการ';

-- 4.4 SupplierDocuments
-- ตาราง: เอกสารของ Supplier (Simplified)
CREATE TABLE SupplierDocuments (
  Id BIGSERIAL PRIMARY KEY,
  SupplierId BIGINT NOT NULL REFERENCES Suppliers(Id),
  DocumentType VARCHAR(50) NOT NULL,
  DocumentName VARCHAR(200) NOT NULL,
  FileName VARCHAR(255) NOT NULL,
  FilePath TEXT,
  FileSize BIGINT,
  MimeType VARCHAR(100),
  IsActive BOOLEAN DEFAULT TRUE,
  UploadedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UploadedBy BIGINT
);

COMMENT ON TABLE SupplierDocuments IS 'เอกสารของ Supplier';
-- Note: ลบ IssueDate, ExpiryDate, VerificationStatus ที่ไม่จำเป็น

-- =============================================
-- SECTION 5: RFQ MANAGEMENT
-- =============================================

-- 5.1 Rfqs
-- ตาราง: ใบขอเสนอราคา
CREATE TABLE Rfqs (
  Id BIGSERIAL PRIMARY KEY,
  RfqNumber VARCHAR(50) UNIQUE NOT NULL,       -- Format: XX-YY-MM-XXXX
  ProjectName VARCHAR(500) NOT NULL,
  
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
  BudgetAmount DECIMAL(15,2),
  BudgetCurrencyId BIGINT NOT NULL REFERENCES Currencies(Id),
  
  -- Important Dates
  CreatedDate DATE NOT NULL DEFAULT CURRENT_DATE,
  RequiredQuotationDate TIMESTAMP NOT NULL,    -- วันที่ต้องการใบเสนอราคา
  QuotationDeadline TIMESTAMP,                 -- Requester กำหนด
  SubmissionDeadline TIMESTAMP,                -- Purchasing กำหนด
  
  -- Serial Number (if required)
  SerialNumber VARCHAR(100),
  
  -- Status & Workflow
  Status VARCHAR(20) DEFAULT 'SAVE_DRAFT',
  CurrentLevel SMALLINT DEFAULT 0,
  CurrentActorId BIGINT REFERENCES Users(Id),
  CurrentActorReceivedAt TIMESTAMP,            -- วันที่ actor ได้รับ
  
  -- Re-Bid Fields
  ReBidCount INT DEFAULT 0,
  LastReBidAt TIMESTAMP,
  ReBidReason TEXT,
  
  -- Reminder Tracking
  LastActionAt TIMESTAMP,
  LastReminderSentAt TIMESTAMP,
  ProcessingDays INT GENERATED ALWAYS AS 
    (CASE 
        WHEN Status = 'COMPLETED' THEN 
            EXTRACT(DAY FROM UpdatedAt - CreatedAt)::INT
        ELSE NULL 
    END) STORED,
  
  -- Flags
  IsUrgent BOOLEAN DEFAULT FALSE,              -- งานเร่ง
  IsOntime BOOLEAN DEFAULT TRUE,               -- ทันเวลา
  IsOverdue BOOLEAN GENERATED ALWAYS AS        -- เลย deadline
    (RequiredQuotationDate < NOW()) STORED,
  
  -- Decline/Reject Reasons
  DeclineReason TEXT,
  RejectReason TEXT,
  
  -- Remarks
  Remarks TEXT,
  
  -- Audit
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CreatedBy BIGINT REFERENCES Users(Id),
  UpdatedAt TIMESTAMP,
  UpdatedBy BIGINT REFERENCES Users(Id),
  
  CONSTRAINT chk_rfq_status CHECK (Status IN 
    ('SAVE_DRAFT','PENDING','DECLINED','REJECTED','COMPLETED','RE_BID')),
  CONSTRAINT chk_rfq_job_type CHECK (JobTypeId IN (1, 2)),
  CONSTRAINT chk_rfq_dates CHECK (
    QuotationDeadline > CreatedDate 
    AND (SubmissionDeadline IS NULL OR SubmissionDeadline >= QuotationDeadline)
  )
);

COMMENT ON TABLE Rfqs IS 'ใบขอเสนอราคา';
COMMENT ON COLUMN Rfqs.IsOverdue IS 'เลยวันที่ต้องการใบเสนอราคาแล้ว';
COMMENT ON COLUMN Rfqs.CurrentActorReceivedAt IS 'วันที่ actor ปัจจุบันได้รับ RFQ';
-- Note: เปลี่ยน HasMedicineIcon เป็น IsOverdue

-- 5.2 RfqItems
-- ตาราง: รายการสินค้าใน RFQ (Updated structure)
CREATE TABLE RfqItems (
  Id BIGSERIAL PRIMARY KEY,
  RfqId BIGINT NOT NULL REFERENCES Rfqs(Id) ON DELETE CASCADE,
  ItemSequence INT NOT NULL,                   -- ลำดับ
  
  -- Item Details (ตรงกับ UI)
  ItemDescription TEXT NOT NULL,               -- สินค้า
  Brand VARCHAR(100),                          -- ยี่ห้อ
  Model VARCHAR(100),                          -- รุ่น
  Quantity DECIMAL(12,4) NOT NULL,             -- จำนวน
  UnitOfMeasure VARCHAR(50) NOT NULL,          -- หน่วย
  Specifications TEXT,                         -- รายละเอียด
  Remarks TEXT,                                -- หมายเหตุ
  
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UpdatedAt TIMESTAMP,
  
  UNIQUE(RfqId, ItemSequence),
  CONSTRAINT chk_rfq_items_quantity CHECK (Quantity > 0)
);

COMMENT ON TABLE RfqItems IS 'รายการสินค้า/บริการใน RFQ';
-- Note: ปรับ structure ให้ตรงกับ UI

-- 5.3 RfqDocuments
-- ตาราง: เอกสารแนบ RFQ
CREATE TABLE RfqDocuments (
  Id BIGSERIAL PRIMARY KEY,
  RfqId BIGINT NOT NULL REFERENCES Rfqs(Id) ON DELETE CASCADE,
  DocumentType VARCHAR(50) NOT NULL,
  DocumentName VARCHAR(200) NOT NULL,
  FileName VARCHAR(255) NOT NULL,
  FilePath TEXT,
  FileSize BIGINT,
  MimeType VARCHAR(100),
  UploadedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UploadedBy BIGINT REFERENCES Users(Id)
);

COMMENT ON TABLE RfqDocuments IS 'เอกสารแนบ RFQ';

-- 5.4 RfqRequiredFields
-- ตาราง: กำหนดข้อมูลที่ Supplier ต้องกรอก
CREATE TABLE RfqRequiredFields (
  Id BIGSERIAL PRIMARY KEY,
  RfqId BIGINT NOT NULL REFERENCES Rfqs(Id) ON DELETE CASCADE,
  
  -- Required Fields Configuration
  RequireMOQ BOOLEAN DEFAULT FALSE,
  RequireDLT BOOLEAN DEFAULT FALSE,
  RequireCredit BOOLEAN DEFAULT FALSE,
  RequireWarranty BOOLEAN DEFAULT FALSE,
  RequireIncoTerm BOOLEAN DEFAULT FALSE,
  
  -- Audit
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CreatedBy BIGINT REFERENCES Users(Id),
  UpdatedAt TIMESTAMP,
  UpdatedBy BIGINT REFERENCES Users(Id),
  
  CONSTRAINT uk_rfq_required_fields UNIQUE(RfqId)
);

COMMENT ON TABLE RfqRequiredFields IS 'กำหนดข้อมูลที่ Supplier ต้องระบุ';

-- =============================================
-- SECTION 6: WORKFLOW & APPROVAL
-- =============================================

-- 6.1 RfqStatusHistory
-- ตาราง: ประวัติการเปลี่ยนสถานะ
CREATE TABLE RfqStatusHistory (
  Id BIGSERIAL PRIMARY KEY,
  RfqId BIGINT NOT NULL REFERENCES Rfqs(Id),
  
  -- Status Change
  FromStatus VARCHAR(20),
  ToStatus VARCHAR(20) NOT NULL,
  ActionType VARCHAR(50) NOT NULL,
  
  -- Actor Information
  ActorId BIGINT NOT NULL REFERENCES Users(Id),
  ActorRole VARCHAR(30),
  ApprovalLevel SMALLINT,
  
  -- Decision Details
  Decision VARCHAR(20),
  Reason TEXT,
  Comments TEXT,
  
  -- Timestamp
  ActionAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT chk_decision CHECK (Decision IN ('APPROVED','DECLINED','REJECTED','SUBMITTED'))
);

COMMENT ON TABLE RfqStatusHistory IS 'ประวัติการเปลี่ยนสถานะ RFQ';

-- 6.2 RfqActorTimeline
-- ตาราง: Timeline การทำงานของแต่ละ Actor
CREATE TABLE RfqActorTimeline (
  Id BIGSERIAL PRIMARY KEY,
  RfqId BIGINT NOT NULL REFERENCES Rfqs(Id),
  ActorId BIGINT NOT NULL REFERENCES Users(Id),
  ActorRole VARCHAR(30) NOT NULL,
  ReceivedAt TIMESTAMP NOT NULL,
  ActionAt TIMESTAMP,
  ResponseTimeDays INT NOT NULL,
  IsOntime BOOLEAN,
  
  CONSTRAINT uk_rfq_actor UNIQUE(RfqId, ActorId, ReceivedAt)
);

COMMENT ON TABLE RfqActorTimeline IS 'Timeline การทำงานของแต่ละ Actor';

-- =============================================
-- SECTION 7: QUOTATION MANAGEMENT
-- =============================================

-- 7.1 RfqInvitations
-- ตาราง: การเชิญ Supplier เสนอราคา
CREATE TABLE RfqInvitations (
  Id BIGSERIAL PRIMARY KEY,
  RfqId BIGINT NOT NULL REFERENCES Rfqs(Id) ON DELETE CASCADE,
  SupplierId BIGINT NOT NULL REFERENCES Suppliers(Id),
  
  -- Invitation Information
  InvitedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  InvitedByUserId BIGINT NOT NULL REFERENCES Users(Id),
  
  -- Response Tracking
  ResponseStatus VARCHAR(30) DEFAULT 'NO_RESPONSE',
  RespondedAt TIMESTAMP,
  
  -- Decision Tracking
  Decision VARCHAR(30) DEFAULT 'PENDING',
  DecisionReason TEXT,
  RespondedByContactId BIGINT REFERENCES SupplierContacts(Id),  -- Contact ที่ตอบรับ
  
  -- Change Tracking
  DecisionChangeCount INT DEFAULT 0,
  LastDecisionChangeAt TIMESTAMP,
  
  -- Re-Bid Tracking
  ReBidCount INT DEFAULT 0,
  LastReBidAt TIMESTAMP,
  
  -- Audit Fields
  RespondedIpAddress INET,
  RespondedUserAgent TEXT,
  RespondedDeviceInfo TEXT,
  
  -- Auto Actions
  AutoDeclinedAt TIMESTAMP,
  
  -- System Fields
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UpdatedAt TIMESTAMP,
  
  CONSTRAINT uk_rfq_supplier UNIQUE(RfqId, SupplierId),
  CONSTRAINT chk_response_status CHECK (ResponseStatus IN ('NO_RESPONSE','RESPONDED')),
  CONSTRAINT chk_decision CHECK (Decision IN 
    ('PENDING','PARTICIPATING','NOT_PARTICIPATING','AUTO_DECLINED'))
);

COMMENT ON TABLE RfqInvitations IS 'การเชิญ Supplier เสนอราคา';

-- 7.2 RfqInvitationHistory
-- ตาราง: ประวัติการเปลี่ยนการตอบรับ
CREATE TABLE RfqInvitationHistory (
  Id BIGSERIAL PRIMARY KEY,
  InvitationId BIGINT NOT NULL REFERENCES RfqInvitations(Id),
  
  -- Change Information
  DecisionSequence INT NOT NULL,
  FromDecision VARCHAR(30),
  ToDecision VARCHAR(30) NOT NULL,
  ChangedByContactId BIGINT REFERENCES SupplierContacts(Id),
  ChangedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  ChangeReason TEXT,
  
  CONSTRAINT uk_invitation_sequence UNIQUE(InvitationId, DecisionSequence)
);

COMMENT ON TABLE RfqInvitationHistory IS 'ประวัติการเปลี่ยนการตอบรับคำเชิญ';

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
  PaymentTerms TEXT,
  DeliveryTerms TEXT,
  IncotermId BIGINT REFERENCES Incoterms(Id),
  
  -- Status (Simplified - no DRAFT, no REVISED)
  Status VARCHAR(20) DEFAULT 'SUBMITTED',
  SubmittedAt TIMESTAMP,
  IsWinner BOOLEAN DEFAULT FALSE,
  WinnerRanking INT,
  SelectionReason TEXT,
  SystemSuggestedRank INT,                     -- อันดับที่ระบบแนะนำ
  SelectionMatchSystem BOOLEAN,                -- เลือกตรงกับระบบหรือไม่
  
  -- Audit
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CreatedBy BIGINT,
  UpdatedAt TIMESTAMP,
  UpdatedBy BIGINT,
  
  UNIQUE(RfqId, SupplierId),
  CONSTRAINT chk_quotation_status CHECK (Status IN 
    ('SUBMITTED','SELECTED','NOT_SELECTED')),
  CONSTRAINT chk_quotation_amount CHECK (TotalAmount >= 0)
);

COMMENT ON TABLE Quotations IS 'ใบเสนอราคาจาก Supplier';
COMMENT ON COLUMN Quotations.SystemSuggestedRank IS 'อันดับที่ระบบแนะนำตาม JobType rule';
-- Note: ลบ DRAFT, REVISED และ RevisionCount ออก

-- 7.4 QuotationItems
-- ตาราง: รายการในใบเสนอราคา
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
  
  -- Terms (Required fields from Purchasing)
  MinOrderQty INT,                             -- MOQ
  DeliveryDays INT,                            -- DLT
  CreditDays INT,                              -- Credit
  WarrantyDays INT,                            -- Warranty
  
  -- Remarks
  Remarks TEXT,
  
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE(QuotationId, RfqItemId)
);

COMMENT ON TABLE QuotationItems IS 'รายการในใบเสนอราคา';

-- 7.5 QuotationDocuments
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

COMMENT ON TABLE QuotationDocuments IS 'เอกสารแนบใบเสนอราคา';

-- =============================================
-- SECTION 8: COMMUNICATION & Q&A
-- =============================================

-- 8.1 RfqQuestions (Renamed from RfqQnA)
-- ตาราง: คำถาม-คำตอบเกี่ยวกับ RFQ
CREATE TABLE RfqQuestions (
  Id BIGSERIAL PRIMARY KEY,
  RfqId BIGINT NOT NULL REFERENCES Rfqs(Id) ON DELETE CASCADE,
  SupplierId BIGINT NOT NULL REFERENCES Suppliers(Id),
  
  -- Question
  Question TEXT NOT NULL,
  AskedBy BIGINT NOT NULL REFERENCES SupplierContacts(Id),
  AskedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  -- Answer
  Answer TEXT,
  AnsweredBy BIGINT REFERENCES Users(Id),
  AnsweredAt TIMESTAMP,
  
  -- Status
  Status VARCHAR(20) DEFAULT 'AWAITING',
  IsPublic BOOLEAN DEFAULT FALSE,
  
  CONSTRAINT chk_question_status CHECK (Status IN ('AWAITING','ANSWERED'))
);

COMMENT ON TABLE RfqQuestions IS 'คำถาม-คำตอบระหว่าง Supplier และ Purchasing';
COMMENT ON COLUMN RfqQuestions.AskedBy IS 'Supplier Contact ที่ถาม';
COMMENT ON COLUMN RfqQuestions.AnsweredBy IS 'Purchasing User ที่ตอบ';

-- =============================================
-- SECTION 9: NOTIFICATION SYSTEM
-- =============================================

-- 9.1 Notifications
-- ตาราง: การแจ้งเตือน (Enhanced for SMS & SignalR)
CREATE TABLE Notifications (
  Id BIGSERIAL PRIMARY KEY,
  Type VARCHAR(50) NOT NULL,
  Priority VARCHAR(20) DEFAULT 'NORMAL',
  NotificationType VARCHAR(30) DEFAULT 'INFO',
  
  -- Target
  UserId BIGINT REFERENCES Users(Id),
  ContactId BIGINT REFERENCES SupplierContacts(Id),
  RfqId BIGINT REFERENCES Rfqs(Id),
  QuotationId BIGINT REFERENCES Quotations(Id),
  
  -- Content
  Title VARCHAR(200) NOT NULL,
  Message TEXT NOT NULL,
  IconType VARCHAR(20),
  ActionUrl TEXT,
  
  -- Status
  IsRead BOOLEAN DEFAULT FALSE,
  ReadAt TIMESTAMP,
  
  -- Delivery Channels
  Channels TEXT[],                             -- {IN_APP, EMAIL, SMS}
  EmailSent BOOLEAN DEFAULT FALSE,
  EmailSentAt TIMESTAMP,
  SmsSent BOOLEAN DEFAULT FALSE,
  SmsSentAt TIMESTAMP,
  
  -- SMS Support (New)
  RecipientPhone VARCHAR(20),
  SmsProvider VARCHAR(20),                     -- Twilio, etc.
  SmsCost DECIMAL(10,4),
  
  -- SignalR Support (New)
  SignalRConnectionId VARCHAR(100),
  MessageQueueId UUID,                         -- Wolverine message ID
  
  -- Scheduling
  ScheduledFor TIMESTAMP,                      -- กำหนดส่งเมื่อไหร่
  ProcessedAt TIMESTAMP,                       -- ประมวลผลเมื่อไหร่
  
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT chk_notification_priority CHECK (Priority IN ('CRITICAL','HIGH','NORMAL','LOW'))
);

COMMENT ON TABLE Notifications IS 'การแจ้งเตือนในระบบ';
COMMENT ON COLUMN Notifications.RecipientPhone IS 'เบอร์โทรสำหรับส่ง SMS';
COMMENT ON COLUMN Notifications.SignalRConnectionId IS 'Connection ID สำหรับ SignalR';
COMMENT ON COLUMN Notifications.MessageQueueId IS 'Wolverine message ID';

-- 9.2 NotificationRules
-- ตาราง: กฎการส่งการแจ้งเตือน
CREATE TABLE NotificationRules (
  Id BIGSERIAL PRIMARY KEY,
  RoleType VARCHAR(50) NOT NULL,               -- บทบาทที่เกี่ยวข้อง
  EventType VARCHAR(100) NOT NULL,             -- เหตุการณ์ที่ trigger
  
  -- Timing
  DaysAfterNoAction INT,                       -- จำนวนวันหลังไม่มีการ action
  HoursBeforeDeadline INT,                     -- จำนวนชั่วโมงก่อน deadline
  
  -- Recipients
  NotifyRecipients TEXT[],
  
  -- Configuration
  Priority VARCHAR(20) DEFAULT 'NORMAL',
  Channels TEXT[],
  
  -- Template
  TitleTemplate TEXT,
  MessageTemplate TEXT,
  
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE NotificationRules IS 'กฎการส่งการแจ้งเตือน';

-- 9.3 EmailTemplates
-- ตาราง: Template อีเมล
CREATE TABLE EmailTemplates (
  Id BIGSERIAL PRIMARY KEY,
  TemplateCode VARCHAR(50) UNIQUE NOT NULL,
  TemplateName VARCHAR(100) NOT NULL,
  
  -- Content
  SubjectTemplate TEXT NOT NULL,
  BodyTemplateHtml TEXT,
  BodyTemplateText TEXT,
  
  -- Variables
  AvailableVariables TEXT[],
  
  -- Language
  Language VARCHAR(5) DEFAULT 'th',
  
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UpdatedAt TIMESTAMP
);

COMMENT ON TABLE EmailTemplates IS 'Template สำหรับส่งอีเมล';

-- 9.4 NotificationQueue
-- ตาราง: คิวการส่งการแจ้งเตือน
CREATE TABLE NotificationQueue (
  Id BIGSERIAL PRIMARY KEY,
  NotificationId BIGINT REFERENCES Notifications(Id),
  Channel VARCHAR(20) NOT NULL,                -- ช่องทางส่ง
  Recipient VARCHAR(255) NOT NULL,             -- ผู้รับ (email/phone)
  
  -- Content
  Subject VARCHAR(500),
  Content TEXT,
  
  -- Processing
  Priority VARCHAR(20) DEFAULT 'NORMAL',
  Status VARCHAR(20) DEFAULT 'PENDING',
  Attempts INT DEFAULT 0,
  MaxAttempts INT DEFAULT 3,
  
  -- Scheduling
  ScheduledFor TIMESTAMP,
  ProcessedAt TIMESTAMP,
  
  -- Error Handling
  LastError TEXT,
  LastAttemptAt TIMESTAMP,
  
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT chk_queue_status CHECK (Status IN ('PENDING','PROCESSING','SENT','FAILED'))
);

COMMENT ON TABLE NotificationQueue IS 'คิวการส่งการแจ้งเตือน';

-- =============================================
-- SECTION 10: FINANCIAL & EXCHANGE RATES
-- =============================================

-- 10.1 ExchangeRates
-- ตาราง: อัตราแลกเปลี่ยน
CREATE TABLE ExchangeRates (
  Id BIGSERIAL PRIMARY KEY,
  FromCurrencyId BIGINT NOT NULL REFERENCES Currencies(Id),  -- สกุลเงินต้นทาง
  ToCurrencyId BIGINT NOT NULL REFERENCES Currencies(Id),    -- สกุลเงินปลายทาง
  Rate DECIMAL(15,6) NOT NULL,                               -- อัตราแลกเปลี่ยน
  EffectiveDate DATE NOT NULL,                               -- วันที่มีผล
  ExpiryDate DATE,                                          -- วันหมดอายุ
  
  -- Source Information
  Source VARCHAR(50) DEFAULT 'MANUAL',
  SourceReference VARCHAR(100),
  
  -- Audit
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CreatedBy BIGINT REFERENCES Users(Id),
  UpdatedAt TIMESTAMP,
  UpdatedBy BIGINT REFERENCES Users(Id),
  
  UNIQUE(FromCurrencyId, ToCurrencyId, EffectiveDate),
  CONSTRAINT chk_exchange_rate CHECK (Rate > 0),
  CONSTRAINT chk_exchange_dates CHECK (
    ExpiryDate IS NULL OR ExpiryDate > EffectiveDate
  )
);

COMMENT ON TABLE ExchangeRates IS 'อัตราแลกเปลี่ยน';

-- 10.2 ExchangeRateHistory
-- ตาราง: ประวัติการเปลี่ยนแปลงอัตรา
CREATE TABLE ExchangeRateHistory (
  Id BIGSERIAL PRIMARY KEY,
  ExchangeRateId BIGINT NOT NULL REFERENCES ExchangeRates(Id),
  OldRate DECIMAL(15,6),
  NewRate DECIMAL(15,6),
  ChangedBy BIGINT NOT NULL REFERENCES Users(Id),
  ChangedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  ChangeReason TEXT
);

COMMENT ON TABLE ExchangeRateHistory IS 'ประวัติการเปลี่ยนแปลงอัตราแลกเปลี่ยน';

-- =============================================
-- SECTION 11: AUTHENTICATION & SECURITY
-- =============================================

-- 11.1 RefreshTokens
-- ตาราง: JWT Refresh Tokens
CREATE TABLE RefreshTokens (
  Id BIGSERIAL PRIMARY KEY,
  Token VARCHAR(500) UNIQUE NOT NULL,
  
  -- User reference
  UserType VARCHAR(20) NOT NULL,
  UserId BIGINT,
  ContactId BIGINT,
  
  -- Token information
  ExpiresAt TIMESTAMP NOT NULL,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CreatedByIp VARCHAR(45),
  
  -- Revoke information
  RevokedAt TIMESTAMP,
  RevokedByIp VARCHAR(45),
  ReplacedByToken VARCHAR(500),
  ReasonRevoked VARCHAR(100),
  
  CONSTRAINT chk_refresh_user_type CHECK (UserType IN ('Employee', 'SupplierContact')),
  CONSTRAINT chk_refresh_user_ref CHECK (
    (UserType = 'Employee' AND UserId IS NOT NULL AND ContactId IS NULL) OR
    (UserType = 'SupplierContact' AND ContactId IS NOT NULL AND UserId IS NULL)
  )
);

COMMENT ON TABLE RefreshTokens IS 'JWT Refresh Tokens';

-- 11.2 LoginHistory
-- ตาราง: ประวัติการ Login/Logout
CREATE TABLE LoginHistory (
  Id BIGSERIAL PRIMARY KEY,
  
  -- User reference
  UserType VARCHAR(20) NOT NULL,
  UserId BIGINT,
  ContactId BIGINT,
  Email VARCHAR(100),
  
  -- Login information
  LoginAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  LoginIp VARCHAR(45),
  UserAgent TEXT,
  DeviceInfo TEXT,
  
  -- Location
  Country VARCHAR(100),
  City VARCHAR(100),
  
  -- Result
  Success BOOLEAN NOT NULL,
  FailureReason VARCHAR(200),
  
  -- Session information
  SessionId VARCHAR(100),
  RefreshTokenId BIGINT REFERENCES RefreshTokens(Id),
  LogoutAt TIMESTAMP,
  LogoutType VARCHAR(20),
  
  CONSTRAINT chk_login_user_type CHECK (UserType IN ('Employee', 'SupplierContact'))
);

COMMENT ON TABLE LoginHistory IS 'ประวัติการ Login/Logout';

-- =============================================
-- SECTION 12: SYSTEM & AUDIT (Hybrid Approach)
-- =============================================

-- 12.1 ActivityLogs
-- ตาราง: บันทึกกิจกรรมสำคัญ (Critical actions only)
CREATE TABLE ActivityLogs (
  Id BIGSERIAL PRIMARY KEY,
  UserId BIGINT REFERENCES Users(Id),
  CompanyId BIGINT REFERENCES Companies(Id),
  
  -- Activity Details
  Module VARCHAR(50),
  Action VARCHAR(100),
  EntityType VARCHAR(50),
  EntityId BIGINT,
  
  -- Additional Information
  OldValues JSONB,
  NewValues JSONB,
  IpAddress INET,
  UserAgent TEXT,
  SessionId VARCHAR(100),
  
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE ActivityLogs IS 'บันทึกกิจกรรมสำคัญ (Critical actions only)';

-- 12.2 SystemConfigurations
-- ตาราง: การตั้งค่าระบบ (UI configurable only)
CREATE TABLE SystemConfigurations (
  Id BIGSERIAL PRIMARY KEY,
  ConfigKey VARCHAR(100) UNIQUE NOT NULL,
  ConfigValue TEXT,
  ConfigType VARCHAR(20),
  Description TEXT,
  IsEncrypted BOOLEAN DEFAULT FALSE,
  
  -- Scope
  CompanyId BIGINT REFERENCES Companies(Id),
  
  -- Audit
  IsActive BOOLEAN DEFAULT TRUE,
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CreatedBy BIGINT REFERENCES Users(Id),
  UpdatedAt TIMESTAMP,
  UpdatedBy BIGINT REFERENCES Users(Id)
);

COMMENT ON TABLE SystemConfigurations IS 'การตั้งค่าระบบที่แก้ไขผ่าน UI';

-- 12.3 ErrorLogs
-- ตาราง: Business Critical Errors Only
CREATE TABLE ErrorLogs (
  Id BIGSERIAL PRIMARY KEY,
  ErrorCode VARCHAR(50),
  ErrorMessage TEXT NOT NULL,
  ErrorDetails TEXT,
  
  -- Context
  UserId BIGINT,
  Module VARCHAR(50),
  Action VARCHAR(100),
  
  -- Status
  IsResolved BOOLEAN DEFAULT FALSE,
  ResolvedBy BIGINT REFERENCES Users(Id),
  ResolvedAt TIMESTAMP,
  ResolutionNotes TEXT,
  
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE ErrorLogs IS 'บันทึก Business Critical Errors';

-- =============================================
-- SECTION 13: INFRASTRUCTURE TABLES
-- =============================================

-- 13.1 wolverine_outgoing_envelopes
-- ตาราง: Wolverine Transactional Outbox
CREATE TABLE wolverine_outgoing_envelopes (
  id UUID PRIMARY KEY,
  destination VARCHAR(500) NOT NULL,
  deliver_by TIMESTAMP,
  body JSONB NOT NULL,
  message_type VARCHAR(500) NOT NULL,
  attempts INT DEFAULT 0,
  status VARCHAR(50) DEFAULT 'Pending',
  owner_id INT,
  execution_time TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE wolverine_outgoing_envelopes IS 'Wolverine outbox for reliable messaging';

-- 13.2 wolverine_scheduled_envelopes
-- ตาราง: Wolverine Scheduled Messages
CREATE TABLE wolverine_scheduled_envelopes (
  id UUID PRIMARY KEY,
  scheduled_time TIMESTAMP NOT NULL,
  body JSONB NOT NULL,
  message_type VARCHAR(500) NOT NULL,
  destination VARCHAR(500),
  attempts INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE wolverine_scheduled_envelopes IS 'Wolverine scheduled messages';

-- 13.3 SignalRConnections
-- ตาราง: SignalR Connection Tracking
CREATE TABLE SignalRConnections (
  ConnectionId VARCHAR(100) PRIMARY KEY,
  UserType VARCHAR(20) NOT NULL,
  UserId BIGINT,
  ContactId BIGINT,
  ConnectedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  LastPingAt TIMESTAMP,
  UserAgent TEXT,
  IpAddress VARCHAR(45),
  IsActive BOOLEAN DEFAULT TRUE,
  
  CONSTRAINT chk_signalr_user_type CHECK (UserType IN ('Employee', 'SupplierContact'))
);

COMMENT ON TABLE SignalRConnections IS 'Track SignalR connections for real-time notifications';

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================

-- Currencies
CREATE INDEX idx_currencies_code ON Currencies(CurrencyCode) WHERE IsActive = TRUE;

-- Countries
CREATE INDEX idx_countries_code ON Countries(CountryCode) WHERE IsActive = TRUE;

-- Categories
CREATE INDEX idx_categories_active ON Categories(Id) WHERE IsActive = TRUE;

-- Subcategories
CREATE INDEX idx_subcategories_category ON Subcategories(CategoryId) WHERE IsActive = TRUE;

-- Companies
CREATE INDEX idx_companies_short_name ON Companies(ShortNameEn) WHERE IsActive = TRUE;
CREATE INDEX idx_companies_tax_id ON Companies(TaxId) WHERE TaxId IS NOT NULL;

-- Departments
CREATE INDEX idx_departments_company ON Departments(CompanyId) WHERE IsActive = TRUE;

-- Users
CREATE INDEX idx_users_email ON Users(Email) WHERE IsDeleted = FALSE;
CREATE INDEX idx_users_email_active ON Users(Email) WHERE IsDeleted = FALSE AND IsActive = TRUE;
CREATE INDEX idx_users_employee_code ON Users(EmployeeCode) WHERE EmployeeCode IS NOT NULL;

-- UserCompanyRoles
CREATE INDEX idx_user_company_roles_user ON UserCompanyRoles(UserId) WHERE IsActive = TRUE;
CREATE INDEX idx_user_company_roles_company ON UserCompanyRoles(CompanyId) WHERE IsActive = TRUE;

-- Suppliers
CREATE INDEX idx_suppliers_status ON Suppliers(Status) WHERE IsActive = TRUE;
CREATE INDEX idx_suppliers_tax_id ON Suppliers(TaxId) WHERE TaxId IS NOT NULL;
CREATE INDEX idx_suppliers_job_type ON Suppliers(JobTypeId) WHERE IsActive = TRUE;
CREATE INDEX idx_suppliers_company ON Suppliers(InvitedByCompanyId) WHERE InvitedByCompanyId IS NOT NULL;

-- SupplierContacts
CREATE INDEX idx_supplier_contacts_supplier ON SupplierContacts(SupplierId) WHERE IsActive = TRUE;
CREATE INDEX idx_supplier_contacts_email ON SupplierContacts(Email) WHERE IsActive = TRUE;
CREATE INDEX idx_supplier_contacts_email_active ON SupplierContacts(Email) WHERE IsActive = TRUE;

-- SupplierCategories
CREATE INDEX idx_supplier_categories_supplier ON SupplierCategories(SupplierId) WHERE IsActive = TRUE;
CREATE INDEX idx_supplier_categories_category ON SupplierCategories(CategoryId) WHERE IsActive = TRUE;

-- SupplierDocuments
CREATE INDEX idx_supplier_documents_supplier ON SupplierDocuments(SupplierId) WHERE IsActive = TRUE;

-- Rfqs
CREATE INDEX idx_rfqs_number ON Rfqs(RfqNumber);
CREATE INDEX idx_rfqs_status ON Rfqs(Status) WHERE Status != 'COMPLETED';
CREATE INDEX idx_rfqs_status_rebid ON Rfqs(Status) WHERE Status = 'RE_BID';
CREATE INDEX idx_rfqs_company ON Rfqs(CompanyId);
CREATE INDEX idx_rfqs_requester ON Rfqs(RequesterId);
CREATE INDEX idx_rfqs_current_actor ON Rfqs(CurrentActorId) WHERE Status = 'PENDING';
CREATE INDEX idx_rfqs_deadline ON Rfqs(QuotationDeadline) WHERE Status NOT IN ('COMPLETED','REJECTED');
CREATE INDEX idx_rfqs_submission_deadline ON Rfqs(SubmissionDeadline) WHERE Status IN ('PENDING', 'RE_BID');
CREATE INDEX idx_rfqs_reminder ON Rfqs(LastActionAt, Status) 
  WHERE Status IN ('PENDING', 'DECLINED') AND LastReminderSentAt IS NULL;
CREATE INDEX idx_rfqs_search ON Rfqs USING gin(to_tsvector('english', ProjectName || ' ' || COALESCE(Remarks, '')));

-- RfqItems
CREATE INDEX idx_rfq_items_rfq ON RfqItems(RfqId);

-- RfqDocuments
CREATE INDEX idx_rfq_documents_rfq ON RfqDocuments(RfqId);

-- RfqRequiredFields
CREATE INDEX idx_rfq_required_fields_rfq ON RfqRequiredFields(RfqId);

-- RfqStatusHistory
CREATE INDEX idx_rfq_status_history_rfq ON RfqStatusHistory(RfqId);
CREATE INDEX idx_rfq_status_history_actor ON RfqStatusHistory(ActorId);

-- RfqActorTimeline
CREATE INDEX idx_rfq_actor_timeline ON RfqActorTimeline(RfqId, ReceivedAt DESC);

-- RfqInvitations
CREATE INDEX idx_rfq_invitations_rfq ON RfqInvitations(RfqId);
CREATE INDEX idx_rfq_invitations_supplier ON RfqInvitations(SupplierId);
CREATE INDEX idx_rfq_invitations_responded_contact ON RfqInvitations(RespondedByContactId) 
  WHERE RespondedByContactId IS NOT NULL;
CREATE INDEX idx_rfq_invitations_pending ON RfqInvitations(RfqId) 
  WHERE ResponseStatus = 'NO_RESPONSE';
CREATE INDEX idx_rfq_invitations_decision_participating ON RfqInvitations(SupplierId, Decision)
  WHERE Decision = 'PARTICIPATING';

-- RfqInvitationHistory
CREATE INDEX idx_invitation_history_invitation ON RfqInvitationHistory(InvitationId);

-- Quotations
CREATE INDEX idx_quotations_rfq ON Quotations(RfqId);
CREATE INDEX idx_quotations_supplier ON Quotations(SupplierId);
CREATE INDEX idx_quotations_status ON Quotations(Status);
CREATE INDEX idx_quotations_comparison ON Quotations(RfqId, TotalAmount) 
  WHERE Status = 'SUBMITTED';

-- QuotationItems
CREATE INDEX idx_quotation_items_quotation ON QuotationItems(QuotationId);

-- QuotationDocuments
CREATE INDEX idx_quotation_documents_quotation ON QuotationDocuments(QuotationId);

-- RfqQuestions
CREATE INDEX idx_rfq_questions_rfq ON RfqQuestions(RfqId);
CREATE INDEX idx_rfq_questions_supplier ON RfqQuestions(SupplierId);
CREATE INDEX idx_rfq_questions_status ON RfqQuestions(Status) WHERE Status = 'AWAITING';

-- Notifications
CREATE INDEX idx_notifications_user ON Notifications(UserId) WHERE IsRead = FALSE;
CREATE INDEX idx_notifications_contact ON Notifications(ContactId) WHERE IsRead = FALSE;
CREATE INDEX idx_notifications_scheduled ON Notifications(ScheduledFor) 
  WHERE ProcessedAt IS NULL AND ScheduledFor IS NOT NULL;
CREATE INDEX idx_notifications_unread_count ON Notifications(UserId, IsRead) 
  WHERE IsRead = FALSE;

-- NotificationQueue
CREATE INDEX idx_notification_queue_pending ON NotificationQueue(ScheduledFor, Priority)
  WHERE Status = 'PENDING';

-- ExchangeRates
CREATE INDEX idx_exchange_rates_active ON ExchangeRates(FromCurrencyId, ToCurrencyId, EffectiveDate)
  WHERE IsActive = TRUE;

-- RefreshTokens
CREATE INDEX idx_refresh_tokens_user ON RefreshTokens(UserId) 
  WHERE UserType = 'Employee';
CREATE INDEX idx_refresh_tokens_contact ON RefreshTokens(ContactId) 
  WHERE UserType = 'SupplierContact';
CREATE INDEX idx_refresh_tokens_active ON RefreshTokens(Token) 
  WHERE RevokedAt IS NULL AND ExpiresAt > NOW();

-- LoginHistory
CREATE INDEX idx_login_history_user ON LoginHistory(UserId) 
  WHERE UserType = 'Employee';
CREATE INDEX idx_login_history_contact ON LoginHistory(ContactId) 
  WHERE UserType = 'SupplierContact';
CREATE INDEX idx_login_history_date ON LoginHistory(LoginAt DESC);
CREATE INDEX idx_login_history_email ON LoginHistory(Email);

-- ActivityLogs
CREATE INDEX idx_activity_logs_user ON ActivityLogs(UserId);
CREATE INDEX idx_activity_logs_entity ON ActivityLogs(EntityType, EntityId);
CREATE INDEX idx_activity_logs_date ON ActivityLogs(CreatedAt DESC);

-- SystemConfigurations
CREATE INDEX idx_system_config_key ON SystemConfigurations(ConfigKey) WHERE IsActive = TRUE;

-- ErrorLogs
CREATE INDEX idx_error_logs_date ON ErrorLogs(CreatedAt DESC);
CREATE INDEX idx_error_logs_unresolved ON ErrorLogs(CreatedAt DESC) WHERE IsResolved = FALSE;

-- Wolverine tables
CREATE INDEX idx_wolverine_outgoing_status ON wolverine_outgoing_envelopes(status, deliver_by);
CREATE INDEX idx_wolverine_scheduled_time ON wolverine_scheduled_envelopes(scheduled_time) 
  WHERE scheduled_time > NOW();

-- SignalR
CREATE INDEX idx_signalr_active ON SignalRConnections(IsActive, LastPingAt)
  WHERE IsActive = TRUE;

-- =============================================
-- VIEWS FOR REPORTING & PERFORMANCE
-- =============================================

-- View: RFQ Performance Statistics
CREATE VIEW vw_rfq_performance AS
SELECT 
    r.Id,
    r.RfqNumber,
    r.ProjectName,
    r.Status,
    r.CurrentActorId,
    u.FirstNameEn || ' ' || u.LastNameEn AS CurrentActor,
    r.CurrentActorReceivedAt,
    EXTRACT(DAY FROM NOW() - r.CurrentActorReceivedAt) AS DaysWithActor,
    s.ResponseTimeDays,
    CASE 
        WHEN EXTRACT(DAY FROM NOW() - r.CurrentActorReceivedAt) > s.ResponseTimeDays 
        THEN 'DELAY'
        ELSE 'ONTIME'
    END AS PerformanceStatus,
    r.IsUrgent,
    r.IsOverdue
FROM Rfqs r
LEFT JOIN Users u ON r.CurrentActorId = u.Id
LEFT JOIN Subcategories s ON r.SubcategoryId = s.Id
WHERE r.Status NOT IN ('COMPLETED', 'REJECTED');

-- View: Supplier Statistics per RFQ
CREATE VIEW vw_rfq_supplier_stats AS
SELECT 
    r.Id AS RfqId,
    COUNT(ri.Id) AS TotalInvited,
    COUNT(CASE WHEN ri.Decision = 'PARTICIPATING' THEN 1 END) AS TotalParticipating,
    COUNT(CASE WHEN ri.Decision = 'NOT_PARTICIPATING' THEN 1 END) AS TotalNotParticipating,
    COUNT(CASE WHEN ri.Decision = 'PARTICIPATING' 
               AND q.Id IS NULL THEN 1 END) AS TotalNoQuote,
    COUNT(CASE WHEN ri.Decision = 'AUTO_DECLINED' THEN 1 END) AS TotalAutoDeclined
FROM Rfqs r
LEFT JOIN RfqInvitations ri ON r.Id = ri.RfqId
LEFT JOIN Quotations q ON ri.RfqId = q.RfqId 
    AND ri.SupplierId = q.SupplierId
    AND q.Status = 'SUBMITTED'
GROUP BY r.Id;

-- =============================================
-- INITIAL DATA
-- =============================================

-- ============================================
-- 1. CURRENCIES (Initial Data มีแล้ว 6 สกุลเงิน)
-- ============================================
-- Insert Common Currencies
INSERT INTO Currencies (CurrencyCode, CurrencyName, CurrencySymbol, DecimalPlaces) VALUES
  ("THB", "Thai Baht", "฿", 2),
  ("USD", "US Dollar", "$", 2),
  ("EUR", "Euro", "€", 2),
  ("GBP", "British Pound", "£", 2),
  ("JPY", "Japanese Yen", "¥", 0),
  ("CNY", "Chinese Yuan", "¥", 2)
ON CONFLICT (CurrencyCode) DO NOTHING;

-- ============================================
-- 2. COUNTRIES
-- ============================================
INSERT INTO Countries (CountryCode, CountryNameEn, CountryNameTh, DefaultCurrencyId, Timezone, PhoneCode) VALUES
("TH", "Thailand", "ประเทศไทย", 1, "Asia/Bangkok", "+66"),
("US", "United States", "สหรัฐอเมริกา", 2, "America/New_York", "+1"),
("CN", "China", "จีน", 6, "Asia/Shanghai", "+86"),
("JP", "Japan", "ญี่ปุ่น", 5, "Asia/Tokyo", "+81"),
("GB", "United Kingdom", "อังกฤษ", 4, "Europe/London", "+44");

-- ============================================
-- 3. BUSINESSTYPES (Initial Data มีแล้ว)
-- ============================================
-- Insert Business Types
INSERT INTO BusinessTypes (Id, Code, NameTh, NameEn, SortOrder) VALUES
  (1, "INDIVIDUAL", "บุคคลธรรมดา", "Individual", 1),
  (2, "CORPORATE", "นิติบุคคล", "Corporate", 2)
ON CONFLICT (Id) DO NOTHING;

-- ============================================
-- 4. JOBTYPES (Initial Data มีแล้ว)
-- ============================================
-- Insert Job Types
INSERT INTO JobTypes (Id, Code, NameTh, NameEn, ForSupplier, ForRfq, PriceComparisonRule, SortOrder) VALUES
  (1, "BUY", "ซื้อ", "Buy", TRUE, TRUE, "MIN", 1),
  (2, "SELL", "ขาย", "Sell", TRUE, TRUE, "MAX", 2),
  (3, "BOTH", "ทั้งซื้อและขาย", "Both Buy and Sell", TRUE, FALSE, NULL, 3)
ON CONFLICT (Id) DO NOTHING;

-- ============================================
-- 5. ROLES (Initial Data มีแล้ว 8 roles)
-- ============================================
-- Insert Roles
INSERT INTO Roles (RoleCode, RoleName, RoleNameTh, Description) VALUES
  ("SUPER_ADMIN", "Super Administrator", "ผู้ดูแลระบบสูงสุด", "Full system access"),
  ("ADMIN", "Administrator", "ผู้ดูแลระบบ", "System administration"),
  ("REQUESTER", "Requester", "ผู้ขอเสนอราคา", "Create and submit RFQs"),
  ("APPROVER", "Approver", "ผู้อนุมัติ", "Approve RFQs"),
  ("PURCHASING", "Purchasing", "จัดซื้อ", "Manage RFQs and suppliers"),
  ("PURCHASING_APPROVER", "Purchasing Approver", "ผู้อนุมัติจัดซื้อ", "Approve supplier selection"),
  ("SUPPLIER", "Supplier", "ผู้ขาย/ผู้รับเหมา", "Submit quotations"),
  ("MANAGING_DIRECTOR", "Managing Director, Manager", "กรรมการผู้จัดการ", "ผู้จัดการ", "Executive dashboard and reports")
ON CONFLICT (RoleCode) DO NOTHING;

-- ============================================
-- 6. PERMISSIONS
-- ============================================
INSERT INTO Permissions (PermissionCode, PermissionName, PermissionNameTh, Module) VALUES
-- RFQ Module
("RFQ_CREATE", "Create RFQ", "สร้างใบขอเสนอราคา", "RFQ"),
("RFQ_VIEW", "View RFQ", "ดูใบขอเสนอราคา", "RFQ"),
("RFQ_EDIT", "Edit RFQ", "แก้ไขใบขอเสนอราคา", "RFQ"),
("RFQ_APPROVE", "Approve RFQ", "อนุมัติใบขอเสนอราคา", "RFQ"),
("RFQ_REJECT", "Reject RFQ", "ปฏิเสธใบขอเสนอราคา", "RFQ"),
("RFQ_INVITE_SUPPLIER", "Invite Suppliers", "เชิญผู้ขาย", "RFQ"),
("RFQ_SELECT_WINNER", "Select Winner", "เลือกผู้ชนะ", "RFQ"),

-- SUPPLIER Module
("SUPPLIER_VIEW", "View Suppliers", "ดูผู้ขาย", "SUPPLIER"),
("SUPPLIER_CREATE", "Create Supplier", "เพิ่มผู้ขาย", "SUPPLIER"),
("SUPPLIER_EDIT", "Edit Supplier", "แก้ไขผู้ขาย", "SUPPLIER"),
("SUPPLIER_APPROVE", "Approve Supplier", "อนุมัติผู้ขาย", "SUPPLIER"),
("QUOTATION_SUBMIT", "Submit Quotation", "ส่งใบเสนอราคา", "SUPPLIER"),
("QUOTATION_VIEW", "View Quotations", "ดูใบเสนอราคา", "SUPPLIER"),

-- REPORT Module
("REPORT_VIEW", "View Reports", "ดูรายงาน", "REPORT"),
("REPORT_EXPORT", "Export Reports", "ส่งออกรายงาน", "REPORT"),
("DASHBOARD_VIEW", "View Dashboard", "ดู Dashboard", "REPORT"),

-- SYSTEM Module
("SYSTEM_CONFIG", "System Configuration", "ตั้งค่าระบบ", "SYSTEM"),
("USER_MANAGE", "Manage Users", "จัดการผู้ใช้", "SYSTEM");

-- ============================================
-- 7. ROLEPERMISSIONS - กำหนดสิทธิ์ให้แต่ละ Role
-- ============================================
-- Get Role IDs first
DO $$
DECLARE
    requester_id BIGINT;
    approver_id BIGINT;
    purchasing_id BIGINT;
    purchasing_approver_id BIGINT;
    supplier_id BIGINT;
    admin_id BIGINT;
BEGIN
    SELECT Id INTO requester_id FROM Roles WHERE RoleCode = 'REQUESTER';
    SELECT Id INTO approver_id FROM Roles WHERE RoleCode = 'APPROVER';
    SELECT Id INTO purchasing_id FROM Roles WHERE RoleCode = 'PURCHASING';
    SELECT Id INTO purchasing_approver_id FROM Roles WHERE RoleCode = 'PURCHASING_APPROVER';
    SELECT Id INTO supplier_id FROM Roles WHERE RoleCode = 'SUPPLIER';
    SELECT Id INTO admin_id FROM Roles WHERE RoleCode = 'ADMIN';

    -- REQUESTER Permissions
    INSERT INTO RolePermissions (RoleId, PermissionId)
    SELECT requester_id, Id FROM Permissions 
    WHERE PermissionCode IN ('RFQ_CREATE', 'RFQ_VIEW', 'RFQ_EDIT', 'RFQ_DELETE');

    -- APPROVER Permissions
    INSERT INTO RolePermissions (RoleId, PermissionId)
    SELECT approver_id, Id FROM Permissions 
    WHERE PermissionCode IN ('RFQ_VIEW', 'RFQ_APPROVE', 'RFQ_REJECT');

    -- PURCHASING Permissions
    INSERT INTO RolePermissions (RoleId, PermissionId)
    SELECT purchasing_id, Id FROM Permissions 
    WHERE PermissionCode IN ('RFQ_VIEW', 'RFQ_INVITE_SUPPLIER', 'RFQ_SELECT_WINNER', 
                            'SUPPLIER_VIEW', 'QUOTATION_VIEW');

    -- PURCHASING_APPROVER Permissions
    INSERT INTO RolePermissions (RoleId, PermissionId)
    SELECT purchasing_approver_id, Id FROM Permissions 
    WHERE PermissionCode IN ('RFQ_VIEW', 'RFQ_APPROVE', 'RFQ_REJECT', 'QUOTATION_VIEW');

    -- SUPPLIER Permissions
    INSERT INTO RolePermissions (RoleId, PermissionId)
    SELECT supplier_id, Id FROM Permissions 
    WHERE PermissionCode IN ('QUOTATION_SUBMIT', 'QUOTATION_VIEW');
END $$;

-- ============================================
-- 8. CATEGORIES
-- ============================================
INSERT INTO Categories (CategoryCode, CategoryNameTh, CategoryNameEn, Description, SortOrder) VALUES
('IT', 'อุปกรณ์ไอที', 'IT Equipment', 'คอมพิวเตอร์และอุปกรณ์ไอที', 1),
('OFF', 'อุปกรณ์สำนักงาน', 'Office Supplies', 'เครื่องเขียนและอุปกรณ์สำนักงาน', 2),
('MNT', 'งานซ่อมบำรุง', 'Maintenance Services', 'บริการซ่อมบำรุงต่างๆ', 3),
('CON', 'งานก่อสร้าง', 'Construction', 'งานก่อสร้างและปรับปรุง', 4),
('MKT', 'การตลาด', 'Marketing', 'สื่อโฆษณาและการตลาด', 5),
('VEH', 'ยานพาหนะ', 'Vehicles', 'รถยนต์และอะไหล่', 6);

-- ============================================
-- 9. SUBCATEGORIES พร้อม Duration และ ResponseTimeDays
-- ============================================
-- IT Category
INSERT INTO Subcategories (CategoryId, SubcategoryCode, SubcategoryNameTh, SubcategoryNameEn, 
                          IsUseSerialNumber, Duration, ResponseTimeDays, SortOrder) VALUES
(1, 'IT-COM', 'คอมพิวเตอร์', 'Computer', TRUE, 7, 2, 1),
(1, 'IT-NET', 'อุปกรณ์เครือข่าย', 'Network Equipment', TRUE, 10, 3, 2),
(1, 'IT-SOFT', 'ซอฟต์แวร์', 'Software', FALSE, 14, 3, 3),
(1, 'IT-PRINT', 'เครื่องพิมพ์', 'Printer', TRUE, 7, 2, 4),

-- Office Category
(2, 'OFF-STA', 'เครื่องเขียน', 'Stationery', FALSE, 3, 1, 1),
(2, 'OFF-FURN', 'เฟอร์นิเจอร์', 'Furniture', FALSE, 14, 3, 2),
(2, 'OFF-PANT', 'งานสั่งพิมพ์', 'Printing Service', FALSE, 5, 2, 3),

-- Maintenance Category
(3, 'MNT-AC', 'ซ่อมแอร์', 'AC Maintenance', FALSE, 3, 1, 1),
(3, 'MNT-ELEC', 'ระบบไฟฟ้า', 'Electrical System', FALSE, 5, 2, 2),
(3, 'MNT-CLEAN', 'ทำความสะอาด', 'Cleaning Service', FALSE, 3, 1, 3),

-- Construction Category
(4, 'CON-BUILD', 'งานก่อสร้าง', 'Building Construction', FALSE, 30, 5, 1),
(4, 'CON-RENO', 'งานปรับปรุง', 'Renovation', FALSE, 21, 3, 2),

-- Marketing Category
(5, 'MKT-MEDIA', 'สื่อโฆษณา', 'Advertising Media', FALSE, 7, 2, 1),
(5, 'MKT-EVENT', 'จัดอีเวนต์', 'Event Management', FALSE, 14, 3, 2),

-- Vehicle Category
(6, 'VEH-CAR', 'รถยนต์', 'Cars', TRUE, 14, 3, 1),
(6, 'VEH-PART', 'อะไหล่', 'Spare Parts', FALSE, 7, 2, 2);

-- ============================================
-- 10. SUBCATEGORYDOCREQUIREMENTS
-- ============================================
-- IT-COM (Computer) ต้องแนบ
INSERT INTO SubcategoryDocRequirements (SubcategoryId, DocumentName, DocumentNameEn, IsRequired, MaxFileSize, AllowedExtensions, SortOrder) VALUES
(1, 'รายละเอียดสินค้า', 'Product Specification', TRUE, 10, 'pdf,doc,docx', 1),
(1, 'ใบรับประกัน', 'Warranty Certificate', TRUE, 5, 'pdf', 2),
(1, 'แคตตาล็อก', 'Product Catalog', FALSE, 20, 'pdf', 3),

-- MNT-AC (AC Maintenance) ต้องแนบ
(8, 'ขอบเขตการทำงาน', 'Scope of Work', TRUE, 10, 'pdf,doc,docx', 1),
(8, 'ตัวอย่างผลงาน', 'Work Portfolio', FALSE, 30, 'pdf,jpg,png', 2),

-- CON-BUILD (Construction) ต้องแนบ
(11, 'แบบแปลน', 'Blueprint', TRUE, 50, 'pdf,dwg', 1),
(11, 'BOQ', 'Bill of Quantities', TRUE, 20, 'xlsx,xls,pdf', 2),
(11, 'ใบอนุญาตก่อสร้าง', 'Construction Permit', TRUE, 10, 'pdf', 3);

-- ============================================
-- 11. INCOTERMS (Initial Data มีแล้ว)
-- ============================================
-- Insert Common Incoterms
INSERT INTO Incoterms (IncotermCode, IncotermName, Description) VALUES
  ('EXW', 'Ex Works', 'Seller makes goods available at their premises'),
  ('FOB', 'Free On Board', 'Seller delivers goods on board the vessel'),
  ('CIF', 'Cost, Insurance and Freight', 'Seller pays costs, insurance and freight'),
  ('DDP', 'Delivered Duty Paid', 'Seller delivers goods with all duties paid')
ON CONFLICT (IncotermCode) DO NOTHING;

-- Insert Notification Rules
INSERT INTO NotificationRules (RoleType, EventType, DaysAfterNoAction, NotifyRecipients, Channels) VALUES
  ('REQUESTER', 'NO_ACTION_2_DAYS', 2, '{SELF, APPROVER_SUPERVISOR}', '{IN_APP, EMAIL}'),
  ('APPROVER', 'NO_ACTION_2_DAYS', 2, '{SELF, REQUESTER}', '{IN_APP, EMAIL}'),
  ('PURCHASING', 'NO_ACTION_2_DAYS', 2, '{SELF, REQUESTER, PURCHASING_SUPERVISOR}', '{IN_APP, EMAIL}'),
  ('PURCHASING_APPROVER', 'NO_ACTION_2_DAYS', 2, '{SELF, REQUESTER, PURCHASING}', '{IN_APP, EMAIL}'),
  ('SUPPLIER', 'NO_ACTION_2_DAYS', 2, '{SUPPLIER_CONTACTS}', '{IN_APP, EMAIL}'),
  ('SUPPLIER', 'DEADLINE_24H', NULL, '{SUPPLIER_CONTACTS}', '{IN_APP, EMAIL, SMS}')
ON CONFLICT DO NOTHING;

-- =============================================
-- END OF DATABASE SCHEMA
-- Version: 5.0 (Production Ready)
-- Last Updated: January 2025
-- Total Tables: 57 (Core) + 3 (Infrastructure) = 60
-- 
-- Changes from v4.0:
-- - Removed unnecessary fields and tables
-- - Simplified status constraints
-- - Enhanced notification system for SMS & SignalR
-- - Optimized indexes for performance
-- - Added proper comments for all tables
-- =============================================