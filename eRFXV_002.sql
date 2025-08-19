📊 Database Design Report for E-RFQ System
PostgreSQL Database Schema with Best Practices
📋 Executive Summary
ระบบ E-RFQ (Electronic Request for Quotation) เป็นป็ ระบบจัดจั ซื้อซื้จัดจั จ้าจ้งอิเล็กทรอนิกส์ที่ส์ ที่
รองรับรั การ
ทำ งานแบบ Multi-Company, Multi-Role พร้อร้ มระบบ Workflow Approval และ Multi-Currency
Support
Key Features:
🏢 Multi-Company & Multi-Department Support
👥 Role-Based Access Control (RBAC)
💱 Multi-Currency with Exchange Rate Management
📝 Complete Audit Trail & Status History
🔄 Workflow Approval up to 3 Levels
📧 Notification System (In-App & Email)
🗂️ 1. Complete Database Schema (DDL Script)
1.1 Database Configuration
-- =============================================
-- Database: erfq_system
-- PostgreSQL Version: 14+
-- Character Set: UTF8
-- Collation: en_US.UTF-8
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
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
1.2 Master Data Tables
-- =============================================
-- SECTION 1: MASTER DATA & LOOKUPS
-- =============================================
-- 1.1 Currencies Table
CREATE TABLE Currencies (
 Id BIGSERIAL PRIMARY KEY,
 CurrencyCode VARCHAR(3) UNIQUE NOT NULL,
 CurrencyName VARCHAR(100) NOT NULL,
 CurrencySymbol VARCHAR(10),
 DecimalPlaces SMALLINT DEFAULT 2,
 IsActive BOOLEAN DEFAULT TRUE,
 CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 UpdatedAt TIMESTAMP,

 CONSTRAINT chk_currency_code CHECK (LENGTH(CurrencyCode) = 3),
 CONSTRAINT chk_decimal_places CHECK (DecimalPlaces BETWEEN 0 AND 4)
);
CREATE INDEX idx_currencies_code ON Currencies(CurrencyCode) WHERE IsActive = TRUE;
-- 1.2 Countries Table
CREATE TABLE Countries (
 Id BIGSERIAL PRIMARY KEY,
 CountryCode VARCHAR(2) UNIQUE NOT NULL,
 CountryNameEn VARCHAR(100) NOT NULL,
 CountryNameTh VARCHAR(100),
 DefaultCurrencyId BIGINT REFERENCES Currencies(Id),
 Timezone VARCHAR(50) DEFAULT 'Asia/Bangkok',
 PhoneCode VARCHAR(5),
 IsActive BOOLEAN DEFAULT TRUE,
 CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

 CONSTRAINT chk_country_code CHECK (LENGTH(CountryCode) = 2)
);
CREATE INDEX idx_countries_code ON Countries(CountryCode) WHERE IsActive = TRUE;
-- 1.3 Business Types
CREATE TABLE BusinessTypes (
 Id SMALLINT PRIMARY KEY,
 Code VARCHAR(20) UNIQUE NOT NULL,
 NameTh VARCHAR(50) NOT NULL,
 NameEn VARCHAR(50),
 SortOrder SMALLINT,
 IsActive BOOLEAN DEFAULT TRUE,
 CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- 1.4 Job Types
CREATE TABLE JobTypes (
 Id SMALLINT PRIMARY KEY,
 Code VARCHAR(20) UNIQUE NOT NULL,
 NameTh VARCHAR(50) NOT NULL,
 NameEn VARCHAR(50),
 ForSupplier BOOLEAN DEFAULT TRUE,
 ForRfq BOOLEAN DEFAULT TRUE,
 PriceComparisonRule VARCHAR(10), -- MIN, MAX
 SortOrder SMALLINT,
 IsActive BOOLEAN DEFAULT TRUE,
 CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- 1.5 Roles
CREATE TABLE Roles (
 Id BIGSERIAL PRIMARY KEY,
 RoleCode VARCHAR(30) UNIQUE NOT NULL,
 RoleName VARCHAR(100) NOT NULL,
 RoleNameTh VARCHAR(100),
 RoleLevel SMALLINT, -- For hierarchy
 Description TEXT,
 IsActive BOOLEAN DEFAULT TRUE,
 CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

 CONSTRAINT chk_role_code CHECK (RoleCode IN
('SUPER_ADMIN','ADMIN','REQUESTER','APPROVER','PURCHASING','PURCHASING_APPROVER',
'SUPPLIER'))
);
-- 1.6 Permissions
CREATE TABLE Permissions (
 Id BIGSERIAL PRIMARY KEY,
 PermissionCode VARCHAR(50) UNIQUE NOT NULL,
 PermissionName VARCHAR(100) NOT NULL,
 PermissionNameTh VARCHAR(100),
 Module VARCHAR(50),
 IsActive BOOLEAN DEFAULT TRUE,
 CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- 1.7 Role Permissions Mapping
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
CREATE TABLE Categories (
 Id BIGSERIAL PRIMARY KEY,
 CategoryCode VARCHAR(50) UNIQUE NOT NULL,
 CategoryNameTh VARCHAR(200) NOT NULL,
 CategoryNameEn VARCHAR(200),
 Description TEXT,
 SortOrder INT,
 IsActive BOOLEAN DEFAULT TRUE,
 CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 UpdatedAt TIMESTAMP
);
CREATE INDEX idx_categories_active ON Categories(Id) WHERE IsActive = TRUE;
-- 1.9 Subcategories
CREATE TABLE Subcategories (
 Id BIGSERIAL PRIMARY KEY,
 CategoryId BIGINT NOT NULL REFERENCES Categories(Id),
 SubcategoryCode VARCHAR(50) NOT NULL,
 SubcategoryNameTh VARCHAR(200) NOT NULL,
 SubcategoryNameEn VARCHAR(200),
 IsUseSerialNumber BOOLEAN DEFAULT FALSE,
 Duration INT DEFAULT 7, -- Days for RFQ response
 Description TEXT,
 SortOrder INT,
 IsActive BOOLEAN DEFAULT TRUE,
 CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 UpdatedAt TIMESTAMP,

 UNIQUE(CategoryId, SubcategoryCode)
);
CREATE INDEX idx_subcategories_category ON Subcategories(CategoryId) WHERE IsActive =
TRUE;
-- 1.10 Subcategory Document Requirements
CREATE TABLE SubcategoryDocRequirements (
 Id BIGSERIAL PRIMARY KEY,
 SubcategoryId BIGINT NOT NULL REFERENCES Subcategories(Id),
 DocumentName VARCHAR(200) NOT NULL,
 DocumentNameEn VARCHAR(200),
 IsRequired BOOLEAN DEFAULT TRUE,
 MaxFileSize INT DEFAULT 30, -- MB
 AllowedExtensions TEXT, -- comma separated
 SortOrder INT,
 IsActive BOOLEAN DEFAULT TRUE,
 CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- 1.11 Incoterms
CREATE TABLE Incoterms (
 Id BIGSERIAL PRIMARY KEY,
 IncotermCode VARCHAR(3) UNIQUE NOT NULL,
 IncotermName VARCHAR(100) NOT NULL,
 Description TEXT,
 IsActive BOOLEAN DEFAULT TRUE,
 CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
1.3 Company & Organization Tables
-- =============================================
-- SECTION 2: COMPANY & ORGANIZATION STRUCTURE
-- =============================================
-- 2.1 Companies
CREATE TABLE Companies (
 Id BIGSERIAL PRIMARY KEY,
 CompanyCode VARCHAR(20) UNIQUE NOT NULL,
 CompanyNameTh VARCHAR(150),
 CompanyNameEn VARCHAR(150),
 ShortNameEn VARCHAR(10) NOT NULL UNIQUE, -- For RFQ Number generation
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

 CONSTRAINT chk_company_status CHECK (Status IN ('ACTIVE','INACTIVE','SUSPENDED'))
);
CREATE INDEX idx_companies_short_name ON Companies(ShortNameEn) WHERE IsActive =
TRUE;
CREATE INDEX idx_companies_tax_id ON Companies(TaxId) WHERE TaxId IS NOT NULL;
-- 2.2 Departments
CREATE TABLE Departments (
 Id BIGSERIAL PRIMARY KEY,
 CompanyId BIGINT NOT NULL REFERENCES Companies(Id),
 DepartmentCode VARCHAR(50) NOT NULL,
 DepartmentNameTh VARCHAR(200) NOT NULL,
 DepartmentNameEn VARCHAR(200),
 ParentDepartmentId BIGINT REFERENCES Departments(Id),
 ManagerUserId BIGINT,
 CostCenter VARCHAR(50),
 IsActive BOOLEAN DEFAULT TRUE,
 CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 UpdatedAt TIMESTAMP,

 UNIQUE(CompanyId, DepartmentCode)
);
CREATE INDEX idx_departments_company ON Departments(CompanyId) WHERE IsActive =
TRUE;
1.4 User Management Tables
-- =============================================
-- SECTION 3: USER MANAGEMENT
-- =============================================
-- 3.1 Users
CREATE TABLE Users (
 Id BIGSERIAL PRIMARY KEY,
 EmployeeCode VARCHAR(50),
 Username VARCHAR(100) UNIQUE NOT NULL,
 Email VARCHAR(100) UNIQUE NOT NULL,
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
 LastLoginAt TIMESTAMP,
 LoginAttempts INT DEFAULT 0,
 LockedUntil TIMESTAMP,

 -- Status & Audit
 Status VARCHAR(20) DEFAULT 'ACTIVE',
 IsActive BOOLEAN DEFAULT TRUE,
 IsDeleted BOOLEAN DEFAULT FALSE, -- Soft delete
 DeletedAt TIMESTAMP,
 DeletedBy BIGINT,
 CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 CreatedBy BIGINT,
 UpdatedAt TIMESTAMP,
 UpdatedBy BIGINT,

 CONSTRAINT chk_user_status CHECK (Status IN
('ACTIVE','INACTIVE','SUSPENDED','LOCKED'))
);
CREATE INDEX idx_users_email ON Users(Email) WHERE IsDeleted = FALSE;
CREATE INDEX idx_users_username ON Users(Username) WHERE IsDeleted = FALSE;
CREATE INDEX idx_users_employee_code ON Users(EmployeeCode) WHERE EmployeeCode
IS NOT NULL;
-- 3.2 User Company Roles
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

 -- Constraints
 UNIQUE(UserId, CompanyId),
 CONSTRAINT chk_role_rules CHECK (
 -- Requester cannot be Approver or Purchasing
 NOT (
 (PrimaryRoleId = (SELECT Id FROM Roles WHERE RoleCode = 'REQUESTER')
 AND SecondaryRoleId IN (SELECT Id FROM Roles WHERE RoleCode IN
('APPROVER','PURCHASING')))
 OR
 (SecondaryRoleId = (SELECT Id FROM Roles WHERE RoleCode = 'REQUESTER')
 AND PrimaryRoleId IN (SELECT Id FROM Roles WHERE RoleCode IN
('APPROVER','PURCHASING')))
 )
 ),
 CONSTRAINT chk_date_validity CHECK (EndDate IS NULL OR EndDate > StartDate)
);
CREATE INDEX idx_user_company_roles_user ON UserCompanyRoles(UserId) WHERE
IsActive = TRUE;
CREATE INDEX idx_user_company_roles_company ON UserCompanyRoles(CompanyId)
WHERE IsActive = TRUE;
-- 3.3 User Category Bindings (for Purchasing roles)
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
CREATE TABLE ApproverBindings (
 Id BIGSERIAL PRIMARY KEY,
 ApproverUserCompanyRoleId BIGINT NOT NULL REFERENCES UserCompanyRoles(Id),
 DepartmentId BIGINT REFERENCES Departments(Id),
 RequesterUserId BIGINT REFERENCES Users(Id),
 MaxApprovalAmount DECIMAL(15,2),
 IsActive BOOLEAN DEFAULT TRUE,
 CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

 UNIQUE(ApproverUserCompanyRoleId, DepartmentId, RequesterUserId)
);
-- 3.5 Delegation Settings
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
1.5 Supplier Management Tables
-- =============================================
-- SECTION 4: SUPPLIER MANAGEMENT
-- =============================================
-- 4.1 Suppliers
-- =============================================
-- ตาราง Suppliers: เก็บข้อมูลผู้ขาย/ผู้ให้บริการที่ลงทะเบียนในระบบ
-- =============================================
DROP TABLE IF EXISTS Suppliers CASCADE;

CREATE TABLE Suppliers (
  Id BIGSERIAL PRIMARY KEY,
  
  -- Company Information
  TaxId VARCHAR(20) UNIQUE,                        -- เลขประจำตัวผู้เสียภาษี (จากเอกสาร: *เลขประจำตัวผู้เสียภาษี)
  CompanyNameTh VARCHAR(200) NOT NULL,             -- ชื่อบริษัท/หน่วยงาน ภาษาไทย (จากเอกสาร: *ชื่อบริษัท/หน่วยงาน)
  CompanyNameEn VARCHAR(200),                      -- ชื่อบริษัท/หน่วยงาน ภาษาอังกฤษ
  BusinessTypeId SMALLINT NOT NULL REFERENCES BusinessTypes(Id), -- ประเภทบุคคล (จากเอกสาร: *ประเภทบุคคล บุคคลธรรมดา/นิติบุคคล)
  JobTypeId SMALLINT NOT NULL REFERENCES JobTypes(Id),          -- ประเภทงานของบริษัท (จากเอกสาร: *ประเภทงานของบริษัท ซื้อ/ขาย/ทั้งซื้อและขาย)
  
  -- Financial Information
  RegisteredCapital DECIMAL(15,2),                              -- ทุนจดทะเบียน (จากเอกสาร: *ทุนจดทะเบียน xxx,xxx,xxx,xxx.00)
  RegisteredCapitalCurrencyId BIGINT REFERENCES Currencies(Id), -- สกุลเงินของทุนจดทะเบียน (จากเอกสาร: *สกุลเงิน dropdownlist)
  DefaultCurrencyId BIGINT REFERENCES Currencies(Id),           -- สกุลเงินหลักที่ใช้
  
  -- Contact Information
  CompanyEmail VARCHAR(100),                       -- อีเมลบริษัท (จากเอกสาร: *อีเมลบริษัท)
  CompanyPhone VARCHAR(20),                        -- เบอร์โทรศัพท์บริษัท (จากเอกสาร: *เบอร์โทรศัพท์บริษัท)
  CompanyFax VARCHAR(20),                          -- แฟกซ์
  CompanyWebsite VARCHAR(200),                     -- เว็บไซต์
  
  -- Address (ไม่มีในเอกสารโดยตรง แต่ใน UI มีที่อยู่)
  AddressLine1 VARCHAR(200),                       -- ที่อยู่บรรทัด 1
  AddressLine2 VARCHAR(200),                       -- ที่อยู่บรรทัด 2
  City VARCHAR(100),                               -- เมือง/อำเภอ
  Province VARCHAR(100),                           -- จังหวัด
  PostalCode VARCHAR(20),                          -- รหัสไปรษณีย์
  CountryId BIGINT REFERENCES Countries(Id),       -- ประเทศ
  
  -- Business Details
  BusinessScope TEXT,                              -- ขอบเขตการดำเนินธุรกิจ (จากเอกสาร: *ขอบเขตการดำเนินธุรกิจ ความยาว 500)
  FoundedDate DATE,                                -- วันที่ก่อตั้งบริษัท (จากเอกสาร: *วันที่ก่อตั้งบริษัท)
  
  -- Registration & Approval
  InvitedByUserId BIGINT REFERENCES Users(Id),    -- User (Purchasing) ที่เชิญลงทะเบียน
  InvitedByCompanyId BIGINT REFERENCES Companies(Id), -- บริษัทที่เชิญ (ใช้ track ว่า Supplier นี้ถูกเชิญโดยบริษัทไหน)
  InvitedAt TIMESTAMP,                             -- วันเวลาที่เชิญ
  RegisteredAt TIMESTAMP,                          -- วันเวลาที่ลงทะเบียน
  ApprovedByUserId BIGINT REFERENCES Users(Id),    -- User (Purchasing Approver) ที่อนุมัติ
  ApprovedAt TIMESTAMP,                            -- วันเวลาที่อนุมัติ
  
  -- Status Management
  Status VARCHAR(20) DEFAULT 'PENDING',            -- สถานะ: PENDING (รอตรวจ), COMPLETED (ผ่าน), DECLINED (ปฏิเสธ)
  DeclineReason TEXT,                              -- เหตุผลที่ปฏิเสธ (ถ้ามี)
  
  -- System Fields
  IsActive BOOLEAN DEFAULT TRUE,                   -- สถานะการใช้งาน
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,   -- วันเวลาที่สร้าง record
  UpdatedAt TIMESTAMP,                             -- วันเวลาที่แก้ไขล่าสุด
  
  CONSTRAINT chk_supplier_status CHECK (Status IN ('PENDING','COMPLETED','DECLINED'))
);

-- Indexes
CREATE INDEX idx_suppliers_status ON Suppliers(Status) WHERE IsActive = TRUE;
CREATE INDEX idx_suppliers_tax_id ON Suppliers(TaxId) WHERE TaxId IS NOT NULL;
CREATE INDEX idx_suppliers_job_type ON Suppliers(JobTypeId) WHERE IsActive = TRUE;
CREATE INDEX idx_suppliers_company ON Suppliers(InvitedByCompanyId) WHERE InvitedByCompanyId IS NOT NULL;

-- Comments
COMMENT ON TABLE Suppliers IS 'ตารางเก็บข้อมูล Supplier ที่ลงทะเบียนในระบบ';
COMMENT ON COLUMN Suppliers.Status IS 'PENDING=รอตรวจสอบ, COMPLETED=ตรวจสอบผ่าน, DECLINED=ปฏิเสธ';
COMMENT ON COLUMN Suppliers.JobTypeId IS 'อ้างอิงประเภทงานที่ Supplier ทำ (ซื้อ/ขาย/ทั้งสองอย่าง)';
COMMENT ON COLUMN Suppliers.RegisteredCapital IS 'ทุนจดทะเบียน format: xxx,xxx,xxx,xxx.00';
COMMENT ON COLUMN Suppliers.BusinessScope IS 'ขอบเขตการดำเนินธุรกิจ max 500 ตัวอักษร';
COMMENT ON COLUMN Suppliers.InvitedByCompanyId IS 'บริษัทที่เชิญ Supplier มาลงทะเบียน';
-- 4.2 Supplier Contacts
-- =============================================
-- ตาราง SupplierContacts: เก็บข้อมูลผู้ติดต่อของแต่ละ Supplier
-- ผู้ติดต่อแต่ละคนสามารถ login เข้าระบบด้วย email/password
-- =============================================
DROP TABLE IF EXISTS SupplierContacts CASCADE;

CREATE TABLE SupplierContacts (
  Id BIGSERIAL PRIMARY KEY,
  SupplierId BIGINT NOT NULL REFERENCES Suppliers(Id),  -- อ้างอิง Supplier ที่สังกัด
  
  -- Personal Information
  FirstName VARCHAR(100) NOT NULL,                       -- ชื่อ
  LastName VARCHAR(100) NOT NULL,                        -- นามสกุล
  Position VARCHAR(100),                                 -- ตำแหน่งงาน
  Email VARCHAR(100) NOT NULL,                          -- อีเมล (ใช้ login)
  PhoneNumber VARCHAR(20),                              -- เบอร์โทรศัพท์
  MobileNumber VARCHAR(20),                             -- เบอร์มือถือ
  
  -- Authentication (ไม่มี Username แล้ว ใช้ Email login)
  PasswordHash VARCHAR(255),                            -- รหัสผ่านที่เข้ารหัสแล้ว
  LastLoginAt TIMESTAMP,                                -- เข้าระบบล่าสุดเมื่อไหร่
  FailedLoginAttempts INT DEFAULT 0,                    -- จำนวนครั้งที่ login ผิด
  LockedUntil TIMESTAMP,                                -- lock account ถึงเวลานี้ (ถ้า login ผิดเกิน)
  
  -- Contact Settings  
  IsPrimaryContact BOOLEAN DEFAULT FALSE,               -- เป็นผู้ติดต่อหลักหรือไม่
  ReceiveRfqNotification BOOLEAN DEFAULT TRUE,          -- รับการแจ้งเตือน RFQ หรือไม่
  ReceiveSystemNotification BOOLEAN DEFAULT TRUE,       -- รับการแจ้งเตือนระบบหรือไม่
  
  -- Status
  IsActive BOOLEAN DEFAULT TRUE,                        -- สถานะการใช้งาน
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,        -- วันเวลาที่สร้าง
  UpdatedAt TIMESTAMP,                                  -- วันเวลาที่แก้ไขล่าสุด
  
  -- Constraints
  CONSTRAINT unique_supplier_contact_email UNIQUE(Email), -- Email ต้องไม่ซ้ำ (สำหรับ login)
  CONSTRAINT chk_one_primary_per_supplier               -- Supplier ละ 1 primary contact
    EXCLUDE USING btree (SupplierId WITH =) 
    WHERE (IsPrimaryContact = TRUE AND IsActive = TRUE)
);

-- Indexes
CREATE INDEX idx_supplier_contacts_supplier ON SupplierContacts(SupplierId) 
  WHERE IsActive = TRUE;
CREATE INDEX idx_supplier_contacts_email ON SupplierContacts(Email) 
  WHERE IsActive = TRUE;
CREATE INDEX idx_supplier_contacts_login ON SupplierContacts(Email, PasswordHash)
  WHERE IsActive = TRUE;

-- Comments
COMMENT ON TABLE SupplierContacts IS 'ผู้ติดต่อของ Supplier - สามารถมีหลายคนต่อ 1 Supplier';
COMMENT ON COLUMN SupplierContacts.Email IS 'ใช้เป็น username สำหรับ login (ต้อง unique)';
COMMENT ON COLUMN SupplierContacts.IsPrimaryContact IS 'ผู้ติดต่อหลัก - Supplier ละ 1 คนเท่านั้น';
-- 4.3 Supplier Categories
CREATE TABLE SupplierCategories (
 Id BIGSERIAL PRIMARY KEY,
 SupplierId BIGINT NOT NULL REFERENCES Suppliers(Id),
 CategoryId BIGINT NOT NULL REFERENCES Categories(Id),
 SubcategoryId BIGINT REFERENCES Subcategories(Id),
 IsActive BOOLEAN DEFAULT TRUE,
 CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

 UNIQUE(SupplierId, CategoryId, SubcategoryId)
);
CREATE INDEX idx_supplier_categories_supplier ON SupplierCategories(SupplierId) WHERE
IsActive = TRUE;
-- 4.4 Supplier Documents
CREATE TABLE SupplierDocuments (
 Id BIGSERIAL PRIMARY KEY,
 SupplierId BIGINT NOT NULL REFERENCES Suppliers(Id),
 DocumentType VARCHAR(50) NOT NULL,
 DocumentName VARCHAR(200) NOT NULL,
 FileName VARCHAR(255) NOT NULL,
 FilePath TEXT,
 FileSize BIGINT,
 MimeType VARCHAR(100),

 -- Document Details
 ExpiryDate DATE,
 IsVerified BOOLEAN DEFAULT FALSE,
 VerifiedBy BIGINT REFERENCES Users(Id),
 VerifiedAt TIMESTAMP,

 -- Status
 IsActive BOOLEAN DEFAULT TRUE,
 UploadedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 UploadedBy BIGINT
);
CREATE INDEX idx_supplier_documents_supplier ON SupplierDocuments(SupplierId)
WHERE IsActive = TRUE;
1.6 RFQ Management Tables
-- =============================================
-- SECTION 5: RFQ MANAGEMENT
-- =============================================
-- 5.1 RFQs (Request for Quotations)
CREATE TABLE Rfqs (
 Id BIGSERIAL PRIMARY KEY,
 RfqNumber VARCHAR(50) UNIQUE NOT NULL, -- Format: ShortNameEn-yy-mm-xxxx
 ProjectName VARCHAR(500) NOT NULL,

 -- Company & Department
 CompanyId BIGINT NOT NULL REFERENCES Companies(Id),
 DepartmentId BIGINT NOT NULL REFERENCES Departments(Id),

 -- Category & Type
 CategoryId BIGINT NOT NULL REFERENCES Categories(Id),
 SubcategoryId BIGINT NOT NULL REFERENCES Subcategories(Id),
 JobTypeId SMALLINT NOT NULL REFERENCES JobTypes(Id),

 -- Requester Information
 RequesterId BIGINT NOT NULL REFERENCES Users(Id),
 ResponsiblePersonId BIGINT REFERENCES Users(Id),
 RequesterEmail VARCHAR(100),
 RequesterPhone VARCHAR(20),

 -- Budget & Currency
 BudgetAmount DECIMAL(15,2),
 BudgetCurrencyId BIGINT NOT NULL REFERENCES Currencies(Id),

 -- Important Dates
 CreatedDate DATE NOT NULL DEFAULT CURRENT_DATE,
 RequiredQuotationDate TIMESTAMP NOT NULL,
 QuotationDeadline TIMESTAMP,
 SubmissionDeadline TIMESTAMP;  -- วันเวลาสิ้นสุดการเสนอราคา (Purchasing กำหนด)
 
 -- Serial Number (if required by subcategory)
 SerialNumber VARCHAR(100),

 -- Status & Workflow
 Status VARCHAR(20) DEFAULT 'SAVE_DRAFT',
 CurrentLevel SMALLINT DEFAULT 0,
 CurrentActorId BIGINT REFERENCES Users(Id),

 -- Flags
 IsUrgent BOOLEAN DEFAULT FALSE,
 IsOntime BOOLEAN DEFAULT TRUE,
 HasMedicineIcon BOOLEAN DEFAULT FALSE,

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
('SAVE_DRAFT','PENDING','DECLINED','REJECTED','COMPLETED')),
 CONSTRAINT chk_rfq_job_type CHECK (JobTypeId IN (1, 2)) -- Only Buy or Sell for RFQ
);
CREATE INDEX idx_rfqs_number ON Rfqs(RfqNumber);
CREATE INDEX idx_rfqs_status ON Rfqs(Status) WHERE Status != 'COMPLETED';
CREATE INDEX idx_rfqs_company ON Rfqs(CompanyId);
CREATE INDEX idx_rfqs_requester ON Rfqs(RequesterId);
CREATE INDEX idx_rfqs_current_actor ON Rfqs(CurrentActorId) WHERE Status = 'PENDING';
CREATE INDEX idx_rfqs_deadline ON Rfqs(QuotationDeadline) WHERE Status NOT IN
('COMPLETED','REJECTED');
-- Comments
COMMENT ON COLUMN Rfqs.QuotationDeadline IS 'วันที่ต้องการใบเสนอราคา (Requester กำหนด)';
COMMENT ON COLUMN Rfqs.SubmissionDeadline IS 'วันที่สิ้นสุดการเสนอราคา (Purchasing กำหนดหลังจาก approve)';
-- 5.2 RFQ Items
CREATE TABLE RfqItems (
 Id BIGSERIAL PRIMARY KEY,
 RfqId BIGINT NOT NULL REFERENCES Rfqs(Id) ON DELETE CASCADE,
 ItemSequence INT NOT NULL,

 -- Item Details
 ItemCode VARCHAR(50),
 ItemName VARCHAR(500) NOT NULL,
 ItemDescription TEXT,
 Brand VARCHAR(100),
 Model VARCHAR(100),

 -- Quantity & Unit
 Quantity DECIMAL(12,4) NOT NULL,
 Unit VARCHAR(50) NOT NULL,

 -- Additional Info
 Specifications TEXT,

 -- Status
 IsActive BOOLEAN DEFAULT TRUE,
 CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

 UNIQUE(RfqId, ItemSequence)
);
CREATE INDEX idx_rfq_items_rfq ON RfqItems(RfqId) WHERE IsActive = TRUE;
-- 5.3 RFQ Documents
CREATE TABLE RfqDocuments (
 Id BIGSERIAL PRIMARY KEY,
 RfqId BIGINT NOT NULL REFERENCES Rfqs(Id) ON DELETE CASCADE,
 DocumentType VARCHAR(50) NOT NULL,
 DocumentName VARCHAR(200) NOT NULL,
 FileName VARCHAR(255) NOT NULL,
 FilePath TEXT,
 FileSize BIGINT,
 MimeType VARCHAR(100),
 IsRequired BOOLEAN DEFAULT FALSE,
 UploadedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 UploadedBy BIGINT REFERENCES Users(Id)
);
CREATE INDEX idx_rfq_documents_rfq ON RfqDocuments(RfqId);
-- 5.4 RFQ Status History
CREATE TABLE RfqStatusHistory (
 Id BIGSERIAL PRIMARY KEY,
 RfqId BIGINT NOT NULL REFERENCES Rfqs(Id) ON DELETE CASCADE,
 FromStatus VARCHAR(20),
 ToStatus VARCHAR(20) NOT NULL,
 ActionBy BIGINT NOT NULL REFERENCES Users(Id),
 ActionRole VARCHAR(50),
 ActionLevel SMALLINT,
 ActionType VARCHAR(20), -- SUBMIT, APPROVE, DECLINE, REJECT
 Reason TEXT,
 CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

 INDEX idx_rfq_status_history_rfq (RfqId)
);
-- 5.5 RFQ Additional Requirements
CREATE TABLE RfqAdditionalRequirements (
 Id BIGSERIAL PRIMARY KEY,
 RfqId BIGINT NOT NULL REFERENCES Rfqs(Id) ON DELETE CASCADE,
 RequirementText TEXT NOT NULL,
 CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
1.7 Approval Workflow Tables
-- =============================================
-- SECTION 6: APPROVAL WORKFLOW
-- =============================================
-- 6.1 Approval Matrix
CREATE TABLE ApprovalMatrix (
 Id BIGSERIAL PRIMARY KEY,
 RfqId BIGINT NOT NULL REFERENCES Rfqs(Id) ON DELETE CASCADE,
 ApprovalLevel SMALLINT NOT NULL,
 RoleType VARCHAR(50) NOT NULL,
 AssignedUserId BIGINT REFERENCES Users(Id),

 -- Action Details
 Action VARCHAR(20), -- APPROVE, DECLINE, REJECT
 ActionDate TIMESTAMP,
 Comment TEXT,

 -- Performance Tracking
 AssignedAt TIMESTAMP,
 DueDate TIMESTAMP,
 ResponseTimeMinutes INT,
 IsOntime BOOLEAN,

 -- Reminder Tracking
 FirstReminderSent TIMESTAMP,
 SecondReminderSent TIMESTAMP,

 -- Status
 Status VARCHAR(20) DEFAULT 'PENDING',
 CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

 UNIQUE(RfqId, ApprovalLevel),
 CONSTRAINT chk_approval_action CHECK (Action IN ('APPROVE','DECLINE','REJECT'))
);
CREATE INDEX idx_approval_matrix_rfq ON ApprovalMatrix(RfqId);
CREATE INDEX idx_approval_matrix_user ON ApprovalMatrix(AssignedUserId) WHERE
Status = 'PENDING';
-- 6.2 Approval Rules Configuration
CREATE TABLE ApprovalRules (
 Id BIGSERIAL PRIMARY KEY,
 CompanyId BIGINT NOT NULL REFERENCES Companies(Id),
 CategoryId BIGINT REFERENCES Categories(Id),
 SubcategoryId BIGINT REFERENCES Subcategories(Id),

 -- Amount Range
 MinAmount DECIMAL(15,2),
 MaxAmount DECIMAL(15,2),

 -- Required Approval Levels
 RequiredLevels SMALLINT NOT NULL,
 Level1RoleId BIGINT REFERENCES Roles(Id),
 Level2RoleId BIGINT REFERENCES Roles(Id),
 Level3RoleId BIGINT REFERENCES Roles(Id),

 -- Response Time (in days)
 ResponseTimeDays INT DEFAULT 2,

 IsActive BOOLEAN DEFAULT TRUE,
 CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 UpdatedAt TIMESTAMP
);
1.8 Quotation Management Tables
-- =============================================
-- SECTION 7: QUOTATION MANAGEMENT
-- =============================================
-- 7.1 RFQ Invitations
-- =============================================
-- ตาราง RfqInvitations: เก็บข้อมูลการเชิญ Supplier เสนอราคา
-- Track การตอบรับและการเข้าร่วมของ Supplier
-- =============================================
DROP TABLE IF EXISTS RfqInvitations CASCADE;

CREATE TABLE RfqInvitations (
  Id BIGSERIAL PRIMARY KEY,
  RfqId BIGINT NOT NULL REFERENCES Rfqs(Id) ON DELETE CASCADE,  -- อ้างอิง RFQ
  SupplierId BIGINT NOT NULL REFERENCES Suppliers(Id),           -- Supplier ที่ถูกเชิญ
  
  -- Invitation Information
  InvitedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,        -- วันเวลาที่เชิญ
  InvitedByUserId BIGINT NOT NULL REFERENCES Users(Id),          -- User (Purchasing) ที่เชิญ
  
  -- Response Tracking (ระดับ Supplier)
  ResponseStatus VARCHAR(30) DEFAULT 'NO_RESPONSE',              -- สถานะการตอบกลับ
  RespondedAt TIMESTAMP,                                         -- วันเวลาที่ตอบกลับ
  
  -- Decision Tracking
  Decision VARCHAR(30) DEFAULT 'PENDING',                        -- การตัดสินใจ (เข้าร่วม/ไม่เข้าร่วม)
  DecisionReason TEXT,                                           -- เหตุผลที่ปฏิเสธ (ถ้ามี)
  RespondedByContactId BIGINT REFERENCES SupplierContacts(Id),   -- Contact ที่กดตอบรับ/ปฏิเสธ
  
  -- Change Tracking (ตามเอกสาร: สามารถเปลี่ยนใจได้ถ้ายังไม่หมดเวลา)
  DecisionChangeCount INT DEFAULT 0,                             -- จำนวนครั้งที่เปลี่ยนใจ
  LastDecisionChangeAt TIMESTAMP,                                -- เวลาที่เปลี่ยนใจล่าสุด
  
  -- Auto Actions
  AutoDeclinedAt TIMESTAMP,                                      -- วันเวลาที่ระบบ auto decline
  
  -- System Fields
  CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                 -- วันเวลาที่สร้าง
  UpdatedAt TIMESTAMP,                                          -- วันเวลาที่แก้ไขล่าสุด
  
  -- Constraints
  CONSTRAINT uk_rfq_supplier UNIQUE(RfqId, SupplierId),
  CONSTRAINT chk_response_status CHECK (ResponseStatus IN (
    'NO_RESPONSE',   -- ยังไม่ตอบรับ
    'RESPONDED'      -- ตอบรับแล้ว (ดูที่ Decision ว่าเข้าร่วมหรือไม่)
  )),
  CONSTRAINT chk_decision CHECK (Decision IN (
    'PENDING',          -- รอการตัดสินใจ
    'PARTICIPATING',    -- ตอบรับและเข้าร่วม
    'NOT_PARTICIPATING',-- ตอบรับแต่ปฏิเสธ (ไม่เข้าร่วม)
    'AUTO_DECLINED'     -- ระบบปฏิเสธอัตโนมัติ (หมดเวลา)
  ))
);

-- Indexes
CREATE INDEX idx_rfq_invitations_rfq ON RfqInvitations(RfqId);
CREATE INDEX idx_rfq_invitations_supplier ON RfqInvitations(SupplierId);
CREATE INDEX idx_rfq_invitations_responded_contact ON RfqInvitations(RespondedByContactId) 
  WHERE RespondedByContactId IS NOT NULL;
CREATE INDEX idx_rfq_invitations_pending ON RfqInvitations(RfqId) 
  WHERE ResponseStatus = 'NO_RESPONSE';

-- Comments
COMMENT ON TABLE RfqInvitations IS 'การเชิญ Supplier เสนอราคาสำหรับแต่ละ RFQ';
COMMENT ON COLUMN RfqInvitations.ResponseStatus IS 'NO_RESPONSE=ยังไม่ตอบ, RESPONDED=ตอบแล้ว';
COMMENT ON COLUMN RfqInvitations.Decision IS 'การตัดสินใจเข้าร่วม: PENDING=รอ, PARTICIPATING=เข้าร่วม, NOT_PARTICIPATING=ไม่เข้าร่วม, AUTO_DECLINED=หมดเวลา';
COMMENT ON COLUMN RfqInvitations.RespondedByContactId IS 'Contact คนที่กดเข้าร่วม - คนนี้จะเป็นคนเสนอราคาและคุยงานจนจบ';

-- =============================================
-- ตาราง RfqInvitationHistory: เก็บประวัติการเปลี่ยนแปลงการตอบรับ
-- ตามเอกสาร: Supplier สามารถเปลี่ยนใจได้ถ้ายังไม่หมดเวลา
-- =============================================
CREATE TABLE RfqInvitationHistory (
  Id BIGSERIAL PRIMARY KEY,
  InvitationId BIGINT NOT NULL REFERENCES RfqInvitations(Id),  -- อ้างอิง Invitation
  
  -- Change Information
  DecisionSequence INT NOT NULL,                                -- ลำดับการเปลี่ยนแปลง (1,2,3,...)
  FromDecision VARCHAR(30),                                     -- เปลี่ยนจากสถานะอะไร
  ToDecision VARCHAR(30) NOT NULL,                              -- เปลี่ยนเป็นสถานะอะไร
  ChangedByContactId BIGINT REFERENCES SupplierContacts(Id),    -- Contact ที่เปลี่ยน
  ChangedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,                -- วันเวลาที่เปลี่ยน
  ChangeReason TEXT,                                            -- เหตุผลที่เปลี่ยน (ถ้ามี)
  
  -- Unique constraint
  CONSTRAINT uk_invitation_sequence UNIQUE(InvitationId, DecisionSequence)
);

-- Index
CREATE INDEX idx_invitation_history_invitation ON RfqInvitationHistory(InvitationId);

-- Comments
COMMENT ON TABLE RfqInvitationHistory IS 'ประวัติการเปลี่ยนแปลงการตอบรับคำเชิญเสนอราคา';
COMMENT ON COLUMN RfqInvitationHistory.DecisionSequence IS 'ลำดับการเปลี่ยนแปลง เริ่มจาก 1';

-- 7.2 Quotations
CREATE TABLE Quotations (
 Id BIGSERIAL PRIMARY KEY,
 RfqId BIGINT NOT NULL REFERENCES Rfqs(Id),
 SupplierId BIGINT NOT NULL REFERENCES Suppliers(Id),
 QuotationNumber VARCHAR(50) UNIQUE,

 -- Quotation Details
 QuotationDate DATE DEFAULT CURRENT_DATE,
 ValidityDays INT DEFAULT 30,
 ExpiryDate DATE,

 -- Total Amounts
 TotalAmount DECIMAL(18,4) NOT NULL,
 CurrencyId BIGINT NOT NULL REFERENCES Currencies(Id),

 -- Converted Amounts (for comparison)
 ConvertedAmount DECIMAL(18,4),
 ConvertedCurrencyId BIGINT REFERENCES Currencies(Id),
 LockedExchangeRate DECIMAL(15,6),
 LockedAt TIMESTAMP,

 -- Terms
 PaymentTerms TEXT,
 DeliveryTerms TEXT,
 IncotermId BIGINT REFERENCES Incoterms(Id),

 -- Status
 Status VARCHAR(20) DEFAULT 'DRAFT',
 SubmittedAt TIMESTAMP,
 IsWinner BOOLEAN DEFAULT FALSE,
 WinnerRanking INT,
 SelectionReason TEXT,

 -- Revision Tracking
 RevisionCount INT DEFAULT 0,
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
CREATE INDEX idx_quotations_rfq ON Quotations(RfqId);
CREATE INDEX idx_quotations_supplier ON Quotations(SupplierId);
CREATE INDEX idx_quotations_status ON Quotations(Status);
-- 7.3 Quotation Items
CREATE TABLE QuotationItems (
 Id BIGSERIAL PRIMARY KEY,
 QuotationId BIGINT NOT NULL REFERENCES Quotations(Id) ON DELETE CASCADE,
 RfqItemId BIGINT NOT NULL REFERENCES RfqItems(Id),

 -- Pricing
 UnitPrice DECIMAL(18,4) NOT NULL,
 Quantity DECIMAL(12,4) NOT NULL,
 TotalPrice DECIMAL(18,4) NOT NULL,

 -- Converted Pricing (Company Currency)
 ConvertedUnitPrice DECIMAL(18,4),
 ConvertedTotalPrice DECIMAL(18,4),

 -- Terms
 MinOrderQty INT,
 DeliveryDays INT,
 CreditDays INT,
 WarrantyDays INT,

 -- Remarks
 Remarks TEXT,

 CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

 UNIQUE(QuotationId, RfqItemId)
);
CREATE INDEX idx_quotation_items_quotation ON QuotationItems(QuotationId);
-- 7.4 Quotation Documents
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
-- 7.5 Quotation Audit Logs
CREATE TABLE QuotationAuditLogs (
 Id BIGSERIAL PRIMARY KEY,
 QuotationId BIGINT NOT NULL REFERENCES Quotations(Id),
 RevisionNumber INT NOT NULL,
 Action VARCHAR(50) NOT NULL,

 -- Changed Fields (JSON format)
 ChangedFields JSONB,

 -- Audit Details
 ChangedBy BIGINT NOT NULL,
 ChangedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 ChangeReason TEXT,
 IpAddress INET,
 UserAgent TEXT
);
CREATE INDEX idx_quotation_audit_quotation ON QuotationAuditLogs(QuotationId);
1.9 Communication Tables
-- =============================================
-- SECTION 8: COMMUNICATION & Q&A
-- =============================================
-- 8.1 RFQ Questions and Answers
CREATE TABLE RfqQnA (
 Id BIGSERIAL PRIMARY KEY,
 RfqId BIGINT NOT NULL REFERENCES Rfqs(Id) ON DELETE CASCADE,
 SupplierId BIGINT NOT NULL REFERENCES Suppliers(Id),

 -- Question
 Question TEXT NOT NULL,
 AskedBy BIGINT NOT NULL,
 AskedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

 -- Answer
 Answer TEXT,
 AnsweredBy BIGINT,
 AnsweredAt TIMESTAMP,

 -- Status
 Status VARCHAR(20) DEFAULT 'AWAITING',
 IsPublic BOOLEAN DEFAULT FALSE, -- Share with all suppliers

 CONSTRAINT chk_qna_status CHECK (Status IN ('AWAITING','ANSWERED'))
);
CREATE INDEX idx_rfq_qna_rfq ON RfqQnA(RfqId);
CREATE INDEX idx_rfq_qna_supplier ON RfqQnA(SupplierId);
CREATE INDEX idx_rfq_qna_status ON RfqQnA(Status) WHERE Status = 'AWAITING';
1.10 Notification System Tables
-- =============================================
-- SECTION 9: NOTIFICATION SYSTEM
-- =============================================
-- 9.1 Notifications
CREATE TABLE Notifications (
 Id BIGSERIAL PRIMARY KEY,
 Type VARCHAR(50) NOT NULL,
 Priority VARCHAR(20) DEFAULT 'NORMAL',

 -- Target
 UserId BIGINT REFERENCES Users(Id),
 RfqId BIGINT REFERENCES Rfqs(Id),
 QuotationId BIGINT REFERENCES Quotations(Id),

 -- Content
 Title VARCHAR(200) NOT NULL,
 Message TEXT NOT NULL,
 IconType VARCHAR(20), -- '✅', '❌', '🖊', '📨'
 ActionUrl TEXT,

 -- Status
 IsRead BOOLEAN DEFAULT FALSE,
 ReadAt TIMESTAMP,

 -- Delivery Channels
 Channels TEXT[], -- {IN_APP, EMAIL, SMS}
 EmailSent BOOLEAN DEFAULT FALSE,
 EmailSentAt TIMESTAMP,
 SmsSent BOOLEAN DEFAULT FALSE,
 SmsSentAt TIMESTAMP,

 -- Scheduling
 ScheduledFor TIMESTAMP,
 ProcessedAt TIMESTAMP,

 CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

 CONSTRAINT chk_notification_priority CHECK (Priority IN
('CRITICAL','HIGH','NORMAL','LOW'))
);
CREATE INDEX idx_notifications_user ON Notifications(UserId) WHERE IsRead = FALSE;
CREATE INDEX idx_notifications_scheduled ON Notifications(ScheduledFor)
 WHERE ProcessedAt IS NULL AND ScheduledFor IS NOT NULL;
-- 9.2 Notification Rules
CREATE TABLE NotificationRules (
 Id BIGSERIAL PRIMARY KEY,
 RoleType VARCHAR(50) NOT NULL,
 EventType VARCHAR(100) NOT NULL,

 -- Timing
 DaysAfterNoAction INT,
 HoursBeforeDeadline INT,

 -- Recipients
 NotifyRecipients TEXT[], -- {SELF, REQUESTER, SUPERVISOR, ALL_SUPPLIERS}

 -- Configuration
 Priority VARCHAR(20) DEFAULT 'NORMAL',
 Channels TEXT[], -- {IN_APP, EMAIL, SMS}

 -- Template
 TitleTemplate TEXT,
 MessageTemplate TEXT,

 IsActive BOOLEAN DEFAULT TRUE,
 CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- 9.3 Email Templates
CREATE TABLE EmailTemplates (
 Id BIGSERIAL PRIMARY KEY,
 TemplateCode VARCHAR(50) UNIQUE NOT NULL,
 TemplateName VARCHAR(100) NOT NULL,

 -- Content
 SubjectTemplate TEXT NOT NULL,
 BodyTemplateHtml TEXT,
 BodyTemplateText TEXT,

 -- Variables
 AvailableVariables TEXT[], -- List of available variables

 -- Language
 Language VARCHAR(5) DEFAULT 'th',

 IsActive BOOLEAN DEFAULT TRUE,
 CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 UpdatedAt TIMESTAMP
);
-- 9.4 Notification Queue
CREATE TABLE NotificationQueue (
 Id BIGSERIAL PRIMARY KEY,
 NotificationId BIGINT REFERENCES Notifications(Id),
 Channel VARCHAR(20) NOT NULL,
 Recipient VARCHAR(255) NOT NULL,

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

 CONSTRAINT chk_queue_status CHECK (Status IN
('PENDING','PROCESSING','SENT','FAILED'))
);
CREATE INDEX idx_notification_queue_pending ON NotificationQueue(ScheduledFor,
Priority)
 WHERE Status = 'PENDING';
1.11 Financial Tables
-- =============================================
-- SECTION 10: FINANCIAL & EXCHANGE RATES
-- =============================================
-- 10.1 Exchange Rates
CREATE TABLE ExchangeRates (
 Id BIGSERIAL PRIMARY KEY,
 FromCurrencyId BIGINT NOT NULL REFERENCES Currencies(Id),
 ToCurrencyId BIGINT NOT NULL REFERENCES Currencies(Id),
 Rate DECIMAL(15,6) NOT NULL,
 EectiveDate DATE NOT NULL,
 ExpiryDate DATE,

 -- Source Information
 Source VARCHAR(50) DEFAULT 'MANUAL', -- MANUAL, API, BOT, BANK
 SourceReference VARCHAR(100),

 -- Audit
 IsActive BOOLEAN DEFAULT TRUE,
 CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 CreatedBy BIGINT REFERENCES Users(Id),
 UpdatedAt TIMESTAMP,
 UpdatedBy BIGINT REFERENCES Users(Id),

 UNIQUE(FromCurrencyId, ToCurrencyId, EectiveDate),
 CONSTRAINT chk_exchange_rate CHECK (Rate > 0)
);
CREATE INDEX idx_exchange_rates_active ON ExchangeRates(FromCurrencyId,
ToCurrencyId, EectiveDate)
 WHERE IsActive = TRUE;
-- 10.2 Exchange Rate History (For Audit)
CREATE TABLE ExchangeRateHistory (
 Id BIGSERIAL PRIMARY KEY,
 ExchangeRateId BIGINT NOT NULL REFERENCES ExchangeRates(Id),
 OldRate DECIMAL(15,6),
 NewRate DECIMAL(15,6),
 ChangedBy BIGINT NOT NULL REFERENCES Users(Id),
 ChangedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 ChangeReason TEXT
);
1.12 System & Audit Tables
-- =============================================
-- SECTION 11: SYSTEM & AUDIT
-- =============================================
-- 11.1 Activity Logs
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

 -- Timestamp
 CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_activity_logs_user ON ActivityLogs(UserId);
CREATE INDEX idx_activity_logs_entity ON ActivityLogs(EntityType, EntityId);
CREATE INDEX idx_activity_logs_date ON ActivityLogs(CreatedAt);
-- 11.2 System Settings
CREATE TABLE SystemSettings (
 Id BIGSERIAL PRIMARY KEY,
 CompanyId BIGINT REFERENCES Companies(Id), -- NULL for global settings
 SettingKey VARCHAR(100) NOT NULL,
 SettingValue TEXT,
 SettingType VARCHAR(20), -- STRING, NUMBER, BOOLEAN, JSON
 Description TEXT,
 IsEncrypted BOOLEAN DEFAULT FALSE,
 IsActive BOOLEAN DEFAULT TRUE,
 CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 UpdatedAt TIMESTAMP,
 UpdatedBy BIGINT REFERENCES Users(Id),

 UNIQUE(CompanyId, SettingKey)
);
CREATE INDEX idx_system_settings_key ON SystemSettings(SettingKey) WHERE IsActive =
TRUE;
-- 11.3 Error Logs
CREATE TABLE ErrorLogs (
 Id BIGSERIAL PRIMARY KEY,
 ErrorCode VARCHAR(50),
 ErrorMessage TEXT,
 ErrorDetails JSONB,
 StackTrace TEXT,

 -- Context
 UserId BIGINT REFERENCES Users(Id),
 Module VARCHAR(50),
 Function VARCHAR(100),

 -- Request Information
 RequestUrl TEXT,
 RequestMethod VARCHAR(10),
 RequestBody TEXT,
 IpAddress INET,
 UserAgent TEXT,

 -- Resolution
 IsResolved BOOLEAN DEFAULT FALSE,
 ResolvedBy BIGINT REFERENCES Users(Id),
 ResolvedAt TIMESTAMP,
 ResolutionNotes TEXT,

 CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_error_logs_unresolved ON ErrorLogs(CreatedAt) WHERE IsResolved =
FALSE;
CREATE INDEX idx_error_logs_user ON ErrorLogs(UserId) WHERE UserId IS NOT NULL;
1.13 Views and Functions
-- =============================================
-- SECTION 12: VIEWS & FUNCTIONS
-- =============================================
-- 12.1 Dashboard Summary View
CREATE MATERIALIZED VIEW DashboardSummary AS
SELECT
 r.CompanyId,
 r.Status,
 COUNT(*) as TotalCount,
 COUNT(CASE WHEN r.IsUrgent THEN 1 END) as UrgentCount,
 COUNT(CASE WHEN r.IsOntime = FALSE THEN 1 END) as DelayedCount,
 DATE(r.CreatedAt) as CreatedDate
FROM Rfqs r
WHERE r.CreatedAt >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY r.CompanyId, r.Status, DATE(r.CreatedAt);
CREATE INDEX idx_dashboard_summary ON DashboardSummary(CompanyId, CreatedDate);
-- 12.2 Function to Generate RFQ Number
CREATE OR REPLACE FUNCTION generate_rfq_number(p_company_id BIGINT)
RETURNS VARCHAR(50) AS $$
DECLARE
 v_short_name VARCHAR(10);
 v_year VARCHAR(2);
 v_month VARCHAR(2);
 v_sequence INT;
 v_rfq_number VARCHAR(50);
BEGIN
 -- Get company short name
 SELECT ShortNameEn INTO v_short_name
 FROM Companies
 WHERE Id = p_company_id;

 -- Get current year and month
 v_year := TO_CHAR(CURRENT_DATE, 'YY');
 v_month := TO_CHAR(CURRENT_DATE, 'MM');

 -- Get next sequence
 SELECT COALESCE(MAX(CAST(SUBSTRING(RfqNumber FROM '(\d{4})$') AS INT)), 0) + 1
 INTO v_sequence
 FROM Rfqs
 WHERE RfqNumber LIKE v_short_name || '-' || v_year || '-' || v_month || '-%';

 -- Generate RFQ number
 v_rfq_number := v_short_name || '-' || v_year || '-' || v_month || '-' || LPAD(v_sequence::TEXT,
4, '0');

 RETURN v_rfq_number;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- View: หน้า Dashboard - แสดงทุก RFQ ของ Supplier
-- ทุก Contact ของ Supplier เห็นรายการทั้งหมด
-- =============================================
CREATE OR REPLACE VIEW vw_supplier_dashboard AS
SELECT 
  ri.SupplierId,
  ri.RfqId,
  r.RfqNumber AS "เลขที่เอกสาร",
  r.ProjectName AS "ชื่อโครงงาน",
  c.NameTh AS "บริษัทผู้ร้องขอ",
  ri.InvitedAt AS "วันที่ได้รับเชิญ",
  r.QuotationDeadline AS "วันที่ต้องการใบเสนอราคา",
  
  -- สถานะการเข้าร่วม
  CASE 
    WHEN ri.ResponseStatus = 'NO_RESPONSE' THEN 'ยังไม่ตอบรับ'
    WHEN ri.Decision = 'PARTICIPATING' THEN 'ตอบรับและเข้าร่วม'
    WHEN ri.Decision = 'NOT_PARTICIPATING' THEN 'ตอบรับแต่ปฏิเสธ'
    WHEN ri.Decision = 'AUTO_DECLINED' THEN 'หมดเวลา'
  END AS "สถานะการเข้าร่วม",
  
  -- ใครเป็นคนดำเนินการ
  ri.RespondedByContactId,
  sc.FirstName || ' ' || sc.LastName AS "ผู้ดำเนินการ"
  
FROM RfqInvitations ri
JOIN Rfqs r ON ri.RfqId = r.Id
JOIN Companies c ON r.CompanyId = c.Id
LEFT JOIN SupplierContacts sc ON ri.RespondedByContactId = sc.Id;

COMMENT ON VIEW vw_supplier_dashboard IS 'Dashboard แสดงทุก RFQ ของ Supplier - ทุก Contact เห็นหมด';

-- =============================================
-- View: หน้า "ดูรายการเสนอราคาของฉัน"
-- Contact เห็นเฉพาะรายการที่ตนกดเข้าร่วม
-- =============================================
CREATE OR REPLACE VIEW vw_my_rfq_list AS
SELECT 
  ri.RespondedByContactId AS ContactId,
  r.RfqNumber AS "เลขที่เอกสาร",
  r.ProjectName AS "ชื่อโครงงาน/งาน",
  u.FirstNameTh || ' ' || u.LastNameTh AS "ผู้ร้องขอ",
  c.NameTh AS "บริษัทผู้ร้องขอ",
  ri.InvitedAt + INTERVAL '1 day' AS "ใส่ข้อมูลเสนอราคาได้ตั้งแต่วันที่",
  r.QuotationDeadline - (ri.InvitedAt + INTERVAL '1 day') AS "ระยะเวลา",
  
  -- Open/Closed
  CASE 
    WHEN r.QuotationDeadline > NOW() THEN 'Open'
    ELSE 'Closed'
  END AS "Open/Closed",
  
  -- สถานะการเข้าร่วม (เฉพาะที่เข้าร่วม)
  'ตอบรับและเข้าร่วม' AS "สถานะการเข้าร่วม",
  
  -- สถานะเสนอราคา
  CASE
    WHEN q.Status = 'SUBMITTED' THEN 'Submitted'
    WHEN q.Id IS NULL THEN 'Not Submitted'
    ELSE q.Status
  END AS "สถานะเสนอราคา"
  
FROM RfqInvitations ri
JOIN Rfqs r ON ri.RfqId = r.Id
JOIN Users u ON r.RequesterId = u.Id
JOIN Companies c ON r.CompanyId = c.Id
LEFT JOIN Quotations q ON ri.RfqId = q.RfqId AND ri.SupplierId = q.SupplierId
WHERE ri.Decision = 'PARTICIPATING';  -- เฉพาะที่กดเข้าร่วม

COMMENT ON VIEW vw_my_rfq_list IS 'รายการ RFQ ที่ Contact กดเข้าร่วม - แต่ละ Contact เห็นเฉพาะของตนเอง';

-- 12.3 Function to Calculate Converted Amount
CREATE OR REPLACE FUNCTION calculate_converted_amount(
 p_amount DECIMAL,
 p_from_currency_id BIGINT,
 p_to_currency_id BIGINT,
 p_rate_date DATE DEFAULT CURRENT_DATE
) RETURNS DECIMAL AS $$
DECLARE
 v_rate DECIMAL(15,6);
 v_converted_amount DECIMAL(18,4);
BEGIN
 -- If same currency, return same amount
 IF p_from_currency_id = p_to_currency_id THEN
 RETURN p_amount;
 END IF;

 -- Get exchange rate
 SELECT Rate INTO v_rate
 FROM ExchangeRates
 WHERE FromCurrencyId = p_from_currency_id
 AND ToCurrencyId = p_to_currency_id
 AND EectiveDate <= p_rate_date
 AND IsActive = TRUE
 ORDER BY EectiveDate DESC
 LIMIT 1;

 -- Calculate converted amount
 v_converted_amount := p_amount * v_rate;

 RETURN v_converted_amount;
END;
$$ LANGUAGE plpgsql;
-- 12.4 Trigger for Auto-updating UpdatedAt
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
 NEW.UpdatedAt = CURRENT_TIMESTAMP;
 RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- Apply trigger to all tables with UpdatedAt column
DO $$
DECLARE
 t record;
BEGIN
 FOR t IN
 SELECT table_name
 FROM information_schema.columns
 WHERE column_name = 'updatedat'
 AND table_schema = 'public'
 LOOP
 EXECUTE format('CREATE TRIGGER update_%I_updated_at
 BEFORE UPDATE ON %I
 FOR EACH ROW
 EXECUTE FUNCTION update_updated_at_column()',
 t.table_name, t.table_name);
 END LOOP;
END $$;

-- =============================================
-- Function: Contact ตอบรับคำเชิญ (เข้าร่วม/ปฏิเสธ)
-- ใช้เมื่อ Contact กดปุ่มเข้าร่วมหรือไม่เข้าร่วมใน popup
-- =============================================
CREATE OR REPLACE FUNCTION contact_respond_invitation(
  p_rfq_id BIGINT,          -- RFQ ID
  p_contact_id BIGINT,      -- Contact ID ที่กด
  p_decision VARCHAR,        -- 'PARTICIPATING' หรือ 'NOT_PARTICIPATING'
  p_reason TEXT DEFAULT NULL -- เหตุผล (ถ้าปฏิเสธ)
) RETURNS BOOLEAN AS $$
DECLARE
  v_supplier_id BIGINT;
  v_invitation_id BIGINT;
  v_current_decision VARCHAR;
  v_deadline TIMESTAMP;
  v_change_count INT;
BEGIN
  -- หา Supplier จาก Contact
  SELECT SupplierId INTO v_supplier_id
  FROM SupplierContacts 
  WHERE Id = p_contact_id AND IsActive = TRUE;
  
  IF v_supplier_id IS NULL THEN
    RETURN FALSE;
  END IF;
  
  -- ตรวจสอบ deadline
  SELECT QuotationDeadline INTO v_deadline
  FROM Rfqs WHERE Id = p_rfq_id;
  
  IF v_deadline < NOW() THEN
    RETURN FALSE; -- หมดเวลาแล้ว
  END IF;
  
  -- หา invitation และสถานะปัจจุบัน
  SELECT Id, Decision, DecisionChangeCount 
  INTO v_invitation_id, v_current_decision, v_change_count
  FROM RfqInvitations 
  WHERE RfqId = p_rfq_id AND SupplierId = v_supplier_id;
  
  -- ตรวจสอบว่ามี Contact อื่นกดเข้าร่วมไปแล้วหรือไม่
  IF v_current_decision = 'PARTICIPATING' AND 
     EXISTS (SELECT 1 FROM RfqInvitations 
             WHERE Id = v_invitation_id 
             AND RespondedByContactId IS NOT NULL 
             AND RespondedByContactId != p_contact_id) THEN
    RETURN FALSE; -- มี Contact อื่นกดเข้าร่วมแล้ว
  END IF;
  
  -- บันทึกประวัติการเปลี่ยนแปลง
  INSERT INTO RfqInvitationHistory (
    InvitationId, DecisionSequence, FromDecision, ToDecision, 
    ChangedByContactId, ChangeReason
  ) VALUES (
    v_invitation_id, v_change_count + 1, v_current_decision, 
    p_decision, p_contact_id, p_reason
  );
  
  -- Update การตอบรับ
  UPDATE RfqInvitations
  SET 
    ResponseStatus = 'RESPONDED',
    RespondedAt = COALESCE(RespondedAt, NOW()),
    Decision = p_decision,
    DecisionReason = p_reason,
    RespondedByContactId = p_contact_id,
    DecisionChangeCount = DecisionChangeCount + 1,
    LastDecisionChangeAt = NOW(),
    UpdatedAt = NOW()
  WHERE Id = v_invitation_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION contact_respond_invitation IS 'Function สำหรับ Contact ตอบรับคำเชิญ (เข้าร่วม/ปฏิเสธ)';

-- =============================================
-- Function: Auto-decline invitations ที่หมดเวลา
-- ควรเรียกใช้ทุกวันผ่าน pg_cron
-- =============================================
CREATE OR REPLACE FUNCTION auto_decline_expired_invitations() 
RETURNS void AS $$
BEGIN
  UPDATE RfqInvitations ri
  SET 
    Decision = 'AUTO_DECLINED',
    AutoDeclinedAt = NOW(),
    UpdatedAt = NOW()
  FROM Rfqs r
  WHERE 
    ri.RfqId = r.Id
    AND ri.Decision = 'PENDING'
    AND ri.ResponseStatus = 'NO_RESPONSE'
    AND r.QuotationDeadline < NOW();
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION auto_decline_expired_invitations IS 'Auto-decline คำเชิญที่หมดเวลา (ควรรันทุกวัน)';

1.14 Initial Data
-- =============================================
-- SECTION 13: INITIAL DATA
-- =============================================
-- Insert Currencies
INSERT INTO Currencies (CurrencyCode, CurrencyName, CurrencySymbol, DecimalPlaces)
VALUES
('THB', 'Thai Baht', '฿', 2),
('USD', 'US Dollar', '$', 2),
('EUR', 'Euro', '€', 2),
('GBP', 'British Pound', '£', 2),
('JPY', 'Japanese Yen', '¥', 0),
('CNY', 'Chinese Yuan', '¥', 2),
('SGD', 'Singapore Dollar', 'S$', 2),
('MYR', 'Malaysian Ringgit', 'RM', 2);
-- Insert Countries
INSERT INTO Countries (CountryCode, CountryNameEn, CountryNameTh,
DefaultCurrencyId, Timezone, PhoneCode) VALUES
('TH', 'Thailand', 'ประเทศไทย', 1, 'Asia/Bangkok', '+66'),
('US', 'United States', 'สหรัฐรั อเมริกริ า', 2, 'America/New_York', '+1'),
('GB', 'United Kingdom', 'สหราชอาณาจักจั ร', 4, 'Europe/London', '+44'),
('SG', 'Singapore', 'สิงสิคโปร์'ร์, 7, 'Asia/Singapore', '+65'),
('MY', 'Malaysia', 'มาเลเซียซี ', 8, 'Asia/Kuala_Lumpur', '+60');
-- Insert Business Types
INSERT INTO BusinessTypes (Id, Code, NameTh, NameEn, SortOrder) VALUES
(1, 'INDIVIDUAL', 'บุคคลธรรมดา', 'Individual', 1),
(2, 'JURISTIC', 'นิติบุคคล', 'Juristic Person', 2);
-- Insert Job Types
INSERT INTO JobTypes (Id, Code, NameTh, NameEn, ForSupplier, ForRfq,
PriceComparisonRule, SortOrder) VALUES
(1, 'BUY', 'ซื้อซื้', 'Buy', FALSE, TRUE, 'MIN', 1),
(2, 'SELL', 'ขาย', 'Sell', FALSE, TRUE, 'MAX', 2),
(3, 'BOTH', 'ทั้งซื้อซื้และขาย', 'Buy and Sell', TRUE, FALSE, NULL, 3);
-- Insert Roles
INSERT INTO Roles (RoleCode, RoleName, RoleNameTh, RoleLevel, Description) VALUES
('SUPER_ADMIN', 'Super Administrator', 'ผู้ดูแดู ลระบบสูงสู สุดสุ ', 0, 'Full system access'),
('ADMIN', 'Administrator', 'ผู้ดูแดู ลระบบ', 1, 'Company administration'),
('REQUESTER', 'Requester', 'ผู้ร้อร้ งขอ', 2, 'Create and manage RFQs'),
('APPROVER', 'Approver', 'ผู้อนุมัติมั ติ', 2, 'Approve RFQs'),
('PURCHASING', 'Purchasing', 'จัดจั ซื้อซื้', 2, 'Manage purchasing process'),
('PURCHASING_APPROVER', 'Purchasing Approver', 'ผู้จัดจั การจัดจั ซื้อซื้', 2, 'Approve supplier
selection'),
('SUPPLIER', 'Supplier', 'ผู้ขาย', 3, 'Submit quotations');
-- Insert Permissions
INSERT INTO Permissions (PermissionCode, PermissionName, PermissionNameTh, Module)
VALUES
('CREATE', 'Create', 'สร้าร้ง', 'RFQ'),
('UPDATE', 'Update', 'แก้ไข', 'RFQ'),
('DELETE', 'Delete', 'ลบ', 'RFQ'),
('READ', 'Read', 'ดูข้ดู อข้ มูล', 'RFQ'),
('CONSIDER', 'Consider', 'ตัดสินสิ ใจ', 'APPROVAL'),
('INVITE', 'Invite Supplier', 'เชิญชิ Supplier', 'SUPPLIER'),
('INSERT', 'Insert', 'เพิ่มพิ่ ข้อข้ มูล', 'GENERAL'),
('PRE_APPROVE', 'Pre Approve Supplier', 'ตรวจสอบข้อข้ มูล Supplier', 'SUPPLIER'),
('FIRST_SELECT_WINNER', 'First Select Winner', 'เลือกผู้ชนะเบื้อบื้งต้น', 'QUOTATION'),
('FINAL_WINNER', 'Final Winner', 'เลือกผู้ชนะสุดสุ ท้าย', 'QUOTATION'),
('APPROVE_SUPPLIER', 'Approve New Supplier', 'อนุมัติมั ติ Supplier ใหม่'ม่, 'SUPPLIER');
-- Insert Incoterms
INSERT INTO Incoterms (IncotermCode, IncotermName, Description) VALUES
('EXW', 'Ex Works', 'Seller makes goods available at their premises'),
('FCA', 'Free Carrier', 'Seller delivers goods to carrier at named place'),
('CPT', 'Carriage Paid To', 'Seller pays for carriage to named destination'),
('CIP', 'Carriage and Insurance Paid To', 'Seller pays for carriage and insurance'),
('DAP', 'Delivered at Place', 'Seller delivers goods to named destination'),
('DPU', 'Delivered at Place Unloaded', 'Seller delivers and unloads at destination'),
('DDP', 'Delivered Duty Paid', 'Seller delivers goods cleared for import'),
('FAS', 'Free Alongside Ship', 'Seller delivers goods alongside ship'),
('FOB', 'Free on Board', 'Seller delivers goods on board vessel'),
('CFR', 'Cost and Freight', 'Seller pays costs and freight to destination port'),
('CIF', 'Cost, Insurance and Freight', 'Seller pays costs, insurance and freight');
-- Create indexes for performance
CREATE INDEX idx_users_status_active ON Users(Status, IsActive) WHERE IsDeleted =
FALSE;
CREATE INDEX idx_rfqs_date_range ON Rfqs(CreatedDate, RequiredQuotationDate);
CREATE INDEX idx_quotations_comparison ON Quotations(RfqId, ConvertedAmount);


🔍 2. Problems Identified and Solutions
2.1 Design Problems Found
Problem Original Design Impact Solution
1. Currency as
VARCHAR(3)
VARCHAR(3) in
multiple tables
No referential integrity,
data inconsistency
Created Currencies
master table with FK
constraints
2. No Master Data
Management
Hard-coded values Dicult maintenance,
no consistency
Created master tables
for all lookups
3. Missing Audit Trail No history tracking Cannot trace changes,
compliance issues
Added UpdatedAt,
UpdatedBy, and history
tables
4. Weak Role
Management
Simple role assignment Cannot handle
complex scenarios
Implemented
UserCompanyRoles
with constraints
5. No Exchange Rate
History
Single rate value Cannot track rate
changes
Added
ExchangeRateHistory
table
6. Decimal Precision
Issues
Mixed decimal places Calculation errors Standardized:
Money(2), Price(4),
Rate(6)
7. No Workflow Tracking Status field only Cannot see approval
flow
Added ApprovalMatrix
and RfqStatusHistory
8. Missing Delegation No backup approvers Process stops when
approver absent
Added Delegations
table
9. No Performance
Optimization
No indexes Slow queries Added strategic
indexes and
materialized views
10. Weak Notification
System
Simple notification Cannot prioritize or
schedule
Implemented queue
with priority levels

📋 สรุปการเปลี่ยนแปลง
ตารางที่ปรับปรุง:
Suppliers - เพิ่ม JobTypeId, DeclineReason
SupplierContacts - ลบ Username, เพิ่ม Email UNIQUE, Authentication fields
RfqInvitations - ปรับ Status/Decision, เพิ่ม RespondedByContactId, Change tracking
Rfqs - เพิ่ม SubmissionDeadline

ตารางใหม่:
RfqInvitationHistory - เก็บประวัติการเปลี่ยนใจ

Functions:
contact_respond_invitation - จัดการการตอบรับคำเชิญ
auto_decline_expired_invitations - Auto decline เมื่อหมดเวลา

Views:
vw_supplier_dashboard - Dashboard ทุก Contact เห็น
vw_my_rfq_list - เฉพาะรายการที่ Contact นั้นกดเข้าร่วม

2.2 Business Logic Problems Solved
Business Rule Implementation
Requester cannot be Approver/Purchasing CHECK constraint in UserCompanyRoles
RFQ Number Format Function generate_rfq_number()
Auto-calculate quotation deadline Based on Subcategory.Duration
Lock exchange rate at RFQ close LockedExchangeRate in Quotations
Soft delete for Users only IsDeleted flag only in Users table
Max 3 approval levels CHECK constraint ApproverLevel BETWEEN 1 AND
3
Supplier multi-category SupplierCategories junction table
Document size limit 30MB Validation at application level + DB constraint
Winner selection by job type PriceComparisonRule in JobTypes
Notification after 2 days no action NotificationRules with DaysAfterNoAction
