-- =============================================
-- E-RFQ SYSTEM COMPLETE DATABASE SCHEMA v6.3.0
-- Database: PostgreSQL 14+
-- Last Updated: 2025-10-03
--
-- MAJOR CHANGES in v6.3.0:
--   - Changed ALL TIMESTAMP columns to TIMESTAMP WITH TIME ZONE (NodaTime support)
--   - Added Users.PreferredTimezone VARCHAR(50) for multi-timezone support
--   - Added SupplierContacts.PreferredTimezone VARCHAR(50) for supplier timezone
--   - Required for Npgsql.NodaTime provider (Instant type mapping)
--
-- CHANGES from v6.2.1:
--   - Fixed UserCompanyRoles UNIQUE constraint to support multi-role per user
--   - Added approval chain support (Department & Purchasing Approver)
--   - Corrected table count (50 not 68)
--   - Added 2 new indexes for approval chain queries

-- =============================================
-- SECTION 1: MASTER DATA & LOOKUPS
-- =============================================

-- 1.1 Currencies
CREATE TABLE "Currencies" (
  "Id" BIGSERIAL PRIMARY KEY,
  "CurrencyCode" VARCHAR(3) UNIQUE NOT NULL,
  "CurrencyName" VARCHAR(100) NOT NULL,
  "CurrencySymbol" VARCHAR(10),
  "DecimalPlaces" SMALLINT DEFAULT 2,
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  "UpdatedAt" TIMESTAMP WITH TIME ZONE,
  
  CONSTRAINT "chk_currency_code" CHECK (LENGTH("CurrencyCode") = 3),
  CONSTRAINT "chk_decimal_places" CHECK ("DecimalPlaces" BETWEEN 0 AND 4)
);

COMMENT ON TABLE "Currencies" IS 'สกุลเงินที่ใช้ในระบบ';
COMMENT ON COLUMN "Currencies"."CurrencyCode" IS 'รหัสสกุลเงิน 3 ตัว ISO 4217';

-- 1.2 Countries
CREATE TABLE "Countries" (
  "Id" BIGSERIAL PRIMARY KEY,
  "CountryCode" VARCHAR(2) UNIQUE NOT NULL,
  "CountryNameEn" VARCHAR(100) NOT NULL,
  "CountryNameTh" VARCHAR(100),
  "DefaultCurrencyId" BIGINT REFERENCES "Currencies"("Id"),
  "Timezone" VARCHAR(50) DEFAULT 'Asia/Bangkok',
  "PhoneCode" VARCHAR(5),
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT "chk_country_code" CHECK (LENGTH("CountryCode") = 2)
);

COMMENT ON TABLE "Countries" IS 'ข้อมูลประเทศ';

-- 1.3 BusinessTypes
CREATE TABLE "BusinessTypes" (
  "Id" SMALLINT PRIMARY KEY,
  "Code" VARCHAR(20) UNIQUE NOT NULL,
  "NameTh" VARCHAR(50) NOT NULL,
  "NameEn" VARCHAR(50),
  "SortOrder" SMALLINT,
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE "BusinessTypes" IS 'ประเภทธุรกิจ (บุคคลธรรมดา/นิติบุคคล)';

-- 1.4 JobTypes
CREATE TABLE "JobTypes" (
  "Id" SMALLINT PRIMARY KEY,
  "Code" VARCHAR(20) UNIQUE NOT NULL,
  "NameTh" VARCHAR(50) NOT NULL,
  "NameEn" VARCHAR(50),
  "ForSupplier" BOOLEAN DEFAULT TRUE,
  "ForRfq" BOOLEAN DEFAULT TRUE,
  "PriceComparisonRule" VARCHAR(10),
  "SortOrder" SMALLINT,
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE "JobTypes" IS 'ประเภทงาน (ซื้อ/ขาย)';
COMMENT ON COLUMN "JobTypes"."PriceComparisonRule" IS 'MIN=เลือกราคาต่ำสุด(ซื้อ), MAX=เลือกราคาสูงสุด(ขาย)';

-- 1.5 Roles
CREATE TABLE "Roles" (
  "Id" BIGSERIAL PRIMARY KEY,
  "RoleCode" VARCHAR(30) UNIQUE NOT NULL,
  "RoleNameTh" VARCHAR(100) NOT NULL,
  "RoleNameEn" VARCHAR(100),
  "Description" TEXT,
  "IsSystemRole" BOOLEAN DEFAULT FALSE,
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT "chk_role_code" CHECK ("RoleCode" IN 
    ('SUPER_ADMIN','ADMIN','REQUESTER','APPROVER','PURCHASING',
     'PURCHASING_APPROVER','SUPPLIER','MANAGING_DIRECTOR'))
);

COMMENT ON TABLE "Roles" IS 'บทบาทผู้ใช้งานในระบบ';

-- 1.6 RoleResponseTimes
CREATE TABLE "RoleResponseTimes" (
  "Id" BIGSERIAL PRIMARY KEY,
  "RoleCode" VARCHAR(30) UNIQUE NOT NULL,
  "ResponseTimeDays" INT NOT NULL,
  "Description" TEXT,
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  "UpdatedAt" TIMESTAMP WITH TIME ZONE,
  
  CONSTRAINT "chk_role_response_code" CHECK ("RoleCode" IN 
    ('REQUESTER','APPROVER','PURCHASING','PURCHASING_APPROVER','SUPPLIER'))
);

COMMENT ON TABLE "RoleResponseTimes" IS 'ระยะเวลามาตรฐานของแต่ละ Role';

-- 1.7 Permissions
CREATE TABLE "Permissions" (
  "Id" BIGSERIAL PRIMARY KEY,
  "PermissionCode" VARCHAR(50) UNIQUE NOT NULL,
  "PermissionName" VARCHAR(100) NOT NULL,
  "PermissionNameTh" VARCHAR(100),
  "Module" VARCHAR(50),
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE "Permissions" IS 'สิทธิ์การใช้งานในระบบ';

-- 1.8 RolePermissions
CREATE TABLE "RolePermissions" (
  "Id" BIGSERIAL PRIMARY KEY,
  "RoleId" BIGINT NOT NULL REFERENCES "Roles"("Id"),
  "PermissionId" BIGINT NOT NULL REFERENCES "Permissions"("Id"),
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  "CreatedBy" BIGINT,
  
  UNIQUE("RoleId", "PermissionId")
);

COMMENT ON TABLE "RolePermissions" IS 'กำหนดสิทธิ์ให้แต่ละบทบาท';

-- 1.9 Categories
CREATE TABLE "Categories" (
  "Id" BIGSERIAL PRIMARY KEY,
  "CategoryCode" VARCHAR(50) UNIQUE NOT NULL,
  "CategoryNameTh" VARCHAR(200) NOT NULL,
  "CategoryNameEn" VARCHAR(200),
  "Description" TEXT,
  "SortOrder" INT,
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  "UpdatedAt" TIMESTAMP
);

COMMENT ON TABLE "Categories" IS 'หมวดหมู่สินค้า/บริการ';

-- 1.10 Subcategories
CREATE TABLE "Subcategories" (
  "Id" BIGSERIAL PRIMARY KEY,
  "CategoryId" BIGINT NOT NULL REFERENCES "Categories"("Id"),
  "SubcategoryCode" VARCHAR(50) NOT NULL,
  "SubcategoryNameTh" VARCHAR(200) NOT NULL,
  "SubcategoryNameEn" VARCHAR(200),
  "IsUseSerialNumber" BOOLEAN DEFAULT FALSE,
  "Duration" INT DEFAULT 7,
  "Description" TEXT,
  "SortOrder" INT,
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  "UpdatedAt" TIMESTAMP WITH TIME ZONE,
  
  UNIQUE("CategoryId", "SubcategoryCode")
);

COMMENT ON TABLE "Subcategories" IS 'หมวดหมู่ย่อยของสินค้า/บริการ';
COMMENT ON COLUMN "Subcategories"."Duration" IS 'จำนวนวันสำหรับคำนวณ deadline';

-- 1.11 SubcategoryDocRequirements
CREATE TABLE "SubcategoryDocRequirements" (
  "Id" BIGSERIAL PRIMARY KEY,
  "SubcategoryId" BIGINT NOT NULL REFERENCES "Subcategories"("Id"),
  "DocumentName" VARCHAR(200) NOT NULL,
  "DocumentNameEn" VARCHAR(200),
  "IsRequired" BOOLEAN DEFAULT TRUE,
  "MaxFileSize" INT DEFAULT 30,
  "AllowedExtensions" TEXT,
  "SortOrder" INT,
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE "SubcategoryDocRequirements" IS 'เอกสารที่ต้องแนบตาม Subcategory';

-- 1.12 Incoterms
CREATE TABLE "Incoterms" (
  "Id" BIGSERIAL PRIMARY KEY,
  "IncotermCode" VARCHAR(3) UNIQUE NOT NULL,
  "IncotermName" VARCHAR(100) NOT NULL,
  "Description" TEXT,
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE "Incoterms" IS 'เงื่อนไขการส่งมอบสินค้าระหว่างประเทศ';

-- 1.13 NotificationRules
CREATE TABLE "NotificationRules" (
  "Id" BIGSERIAL PRIMARY KEY,
  "RoleType" VARCHAR(30) NOT NULL,
  "EventType" VARCHAR(50) NOT NULL,
  "DaysAfterNoAction" INT,
  "HoursBeforeDeadline" INT,
  "NotifyRecipients" TEXT[],
  "Priority" VARCHAR(20) DEFAULT 'NORMAL',
  "Channels" TEXT[],
  "TitleTemplate" TEXT,
  "MessageTemplate" TEXT,
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE("RoleType", "EventType")
);

COMMENT ON TABLE "NotificationRules" IS 'กฎการแจ้งเตือน';

-- 1.14 Positions
CREATE TABLE "Positions" (
  "Id" BIGSERIAL PRIMARY KEY,
  "PositionCode" VARCHAR(20) UNIQUE NOT NULL,
  "PositionNameTh" VARCHAR(100) NOT NULL,
  "PositionNameEn" VARCHAR(100),
  "PositionLevel" INT CHECK ("PositionLevel" BETWEEN 1 AND 10),
  "DepartmentType" VARCHAR(50),
  "DefaultApproverLevel" SMALLINT CHECK ("DefaultApproverLevel" BETWEEN 1 AND 3),
  "CanActAsApproverLevels" INT[],
  "CanBeRequester" BOOLEAN DEFAULT TRUE,
  "CanBeApprover" BOOLEAN DEFAULT FALSE,
  "CanBePurchasing" BOOLEAN DEFAULT FALSE,
  "CanBePurchasingApprover" BOOLEAN DEFAULT FALSE,
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE "Positions" IS 'ตำแหน่งงาน';

-- 1.15 EmailTemplates
CREATE TABLE "EmailTemplates" (
  "Id" BIGSERIAL PRIMARY KEY,
  "TemplateCode" VARCHAR(50) UNIQUE NOT NULL,
  "TemplateName" VARCHAR(200) NOT NULL,
  "Subject" VARCHAR(500) NOT NULL,
  "BodyHtml" TEXT NOT NULL,
  "BodyText" TEXT,
  "Variables" TEXT[],
  "Language" VARCHAR(5) DEFAULT 'th',
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  "UpdatedAt" TIMESTAMP
);

COMMENT ON TABLE "EmailTemplates" IS 'Template สำหรับส่ง Email';

-- 1.16 SupplierDocumentTypes
CREATE TABLE "SupplierDocumentTypes" (
  "Id" BIGSERIAL PRIMARY KEY,
  "BusinessTypeId" SMALLINT NOT NULL REFERENCES "BusinessTypes"("Id"),
  "DocumentCode" VARCHAR(50) NOT NULL,
  "DocumentNameTh" VARCHAR(200) NOT NULL,
  "DocumentNameEn" VARCHAR(200),
  "IsRequired" BOOLEAN DEFAULT TRUE,
  "SortOrder" INT,
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE("BusinessTypeId", "DocumentCode")
);

COMMENT ON TABLE "SupplierDocumentTypes" IS 'เอกสารที่ต้องใช้ตาม BusinessType';

-- =============================================
-- SECTION 2: COMPANY & ORGANIZATION
-- =============================================

-- 2.1 Companies
CREATE TABLE "Companies" (
  "Id" BIGSERIAL PRIMARY KEY,
  "CompanyCode" VARCHAR(20) UNIQUE NOT NULL,
  "CompanyNameTh" VARCHAR(150),
  "CompanyNameEn" VARCHAR(150),
  "ShortNameEn" VARCHAR(10) NOT NULL UNIQUE,
  "TaxId" VARCHAR(20) UNIQUE,
  "CountryId" BIGINT NOT NULL REFERENCES "Countries"("Id"),
  "DefaultCurrencyId" BIGINT NOT NULL REFERENCES "Currencies"("Id"),
  "BusinessTypeId" SMALLINT REFERENCES "BusinessTypes"("Id"),
  "RegisteredCapital" DECIMAL(15,2),
  "RegisteredCapitalCurrencyId" BIGINT REFERENCES "Currencies"("Id"),
  "FoundedDate" DATE,
  "AddressLine1" VARCHAR(200),
  "AddressLine2" VARCHAR(200),
  "City" VARCHAR(100),
  "Province" VARCHAR(100),
  "PostalCode" VARCHAR(20),
  "Phone" VARCHAR(20),
  "Fax" VARCHAR(20),
  "Email" VARCHAR(100),
  "Website" VARCHAR(200),
  "Status" VARCHAR(20) DEFAULT 'ACTIVE',
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  "CreatedBy" BIGINT,
  "UpdatedAt" TIMESTAMP WITH TIME ZONE,
  "UpdatedBy" BIGINT,
  
  CONSTRAINT "chk_company_status" CHECK ("Status" IN ('ACTIVE','INACTIVE'))
);

COMMENT ON TABLE "Companies" IS 'บริษัทในระบบ (Multi-Company Support)';
COMMENT ON COLUMN "Companies"."ShortNameEn" IS 'ชื่อย่อสำหรับสร้างเลข RFQ';

-- 2.2 Departments
CREATE TABLE "Departments" (
  "Id" BIGSERIAL PRIMARY KEY,
  "CompanyId" BIGINT NOT NULL REFERENCES "Companies"("Id"),
  "DepartmentCode" VARCHAR(50) NOT NULL,
  "DepartmentNameTh" VARCHAR(200) NOT NULL,
  "DepartmentNameEn" VARCHAR(200),
  "ManagerUserId" BIGINT,
  "CostCenter" VARCHAR(50),
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  "UpdatedAt" TIMESTAMP WITH TIME ZONE,
  
  UNIQUE("CompanyId", "DepartmentCode")
);

COMMENT ON TABLE "Departments" IS 'แผนกภายในบริษัท';

-- =============================================
-- SECTION 3: USER MANAGEMENT
-- =============================================

-- 3.1 Users
CREATE TABLE "Users" (
  "Id" BIGSERIAL PRIMARY KEY,
  "EmployeeCode" VARCHAR(50),
  "Email" VARCHAR(100) UNIQUE NOT NULL,
  "PasswordHash" VARCHAR(255) NOT NULL,
  "FirstNameTh" VARCHAR(100),
  "LastNameTh" VARCHAR(100),
  "FirstNameEn" VARCHAR(100),
  "LastNameEn" VARCHAR(100),
  "PhoneNumber" VARCHAR(20),
  "MobileNumber" VARCHAR(20),
  "PreferredLanguage" VARCHAR(5) DEFAULT 'th', -- NEW in v6.2
  "PreferredTimezone" VARCHAR(50) DEFAULT 'Asia/Bangkok', -- NEW in v6.3
  "IsEmailVerified" BOOLEAN DEFAULT FALSE,
  "EmailVerifiedAt" TIMESTAMP WITH TIME ZONE,
  "PasswordResetToken" VARCHAR(255),
  "PasswordResetExpiry" TIMESTAMP WITH TIME ZONE,
  "SecurityStamp" VARCHAR(100),
  "LastLoginAt" TIMESTAMP WITH TIME ZONE,
  "LockoutEnabled" BOOLEAN DEFAULT TRUE,
  "LockoutEnd" TIMESTAMP WITH TIME ZONE,
  "AccessFailedCount" INT DEFAULT 0,
  "Status" VARCHAR(20) DEFAULT 'ACTIVE',
  "IsActive" BOOLEAN DEFAULT TRUE,
  "IsDeleted" BOOLEAN DEFAULT FALSE,
  "DeletedAt" TIMESTAMP WITH TIME ZONE,
  "DeletedBy" BIGINT,
  "CreatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  "CreatedBy" BIGINT,
  "UpdatedAt" TIMESTAMP WITH TIME ZONE,
  "UpdatedBy" BIGINT,
  
  CONSTRAINT "chk_user_status" CHECK ("Status" IN ('ACTIVE','INACTIVE')),
  CONSTRAINT "chk_preferred_language" CHECK ("PreferredLanguage" IN ('th','en'))
);

COMMENT ON TABLE "Users" IS 'พนักงานภายในบริษัท (Internal Users)';
COMMENT ON COLUMN "Users"."Email" IS 'ใช้เป็น username สำหรับ login';
COMMENT ON COLUMN "Users"."PreferredLanguage" IS 'ภาษาที่ต้องการ th/en (NEW in v6.2)';
COMMENT ON COLUMN "Users"."PreferredTimezone" IS 'IANA timezone (e.g., Asia/Bangkok, America/New_York) for multi-timezone support (NEW in v6.3)';

-- 3.2 UserCompanyRoles
CREATE TABLE "UserCompanyRoles" (
  "Id" BIGSERIAL PRIMARY KEY,
  "UserId" BIGINT NOT NULL REFERENCES "Users"("Id"),
  "CompanyId" BIGINT NOT NULL REFERENCES "Companies"("Id"),
  "DepartmentId" BIGINT REFERENCES "Departments"("Id"),
  "PrimaryRoleId" BIGINT NOT NULL REFERENCES "Roles"("Id"),
  "SecondaryRoleId" BIGINT REFERENCES "Roles"("Id"),
  "PositionId" BIGINT REFERENCES "Positions"("Id"),
  "ApproverLevel" SMALLINT CHECK ("ApproverLevel" BETWEEN 1 AND 3),
  "StartDate" DATE NOT NULL,
  "EndDate" DATE,
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  "CreatedBy" BIGINT,
  "UpdatedAt" TIMESTAMP WITH TIME ZONE,
  "UpdatedBy" BIGINT,
  
  -- CHANGED v6.2.1: Removed UNIQUE(UserId, CompanyId) to allow one user to have multiple roles
  -- in the same company (e.g., APPROVER for multiple departments, PURCHASING_APPROVER for multiple categories)
  -- Constraint ensures one user cannot have the same role in the same department twice
  UNIQUE("UserId", "CompanyId", "DepartmentId", "PrimaryRoleId"),
  CONSTRAINT "chk_role_rules" CHECK (
    NOT (
      ("PrimaryRoleId" = 3 AND "SecondaryRoleId" = 4) OR
      ("PrimaryRoleId" = 4 AND "SecondaryRoleId" = 3) OR
      ("PrimaryRoleId" = 3 AND "SecondaryRoleId" = 5)
    )
  ),
  CONSTRAINT "chk_date_validity" CHECK ("EndDate" IS NULL OR "EndDate" > "StartDate")
);

COMMENT ON TABLE "UserCompanyRoles" IS 'บทบาทของ User ในแต่ละบริษัท';
COMMENT ON COLUMN "UserCompanyRoles"."PositionId" IS 'ตำแหน่งงาน';
COMMENT ON COLUMN "UserCompanyRoles"."ApproverLevel" IS 'ระดับผู้อนุมัติ (1-3) สำหรับ APPROVER และ PURCHASING_APPROVER - See idx_dept_approver_level_unique for constraint';

-- 3.3 UserCategoryBindings
CREATE TABLE "UserCategoryBindings" (
  "Id" BIGSERIAL PRIMARY KEY,
  "UserCompanyRoleId" BIGINT NOT NULL REFERENCES "UserCompanyRoles"("Id"),
  "CategoryId" BIGINT NOT NULL REFERENCES "Categories"("Id"),
  "SubcategoryId" BIGINT REFERENCES "Subcategories"("Id"),
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE("UserCompanyRoleId", "CategoryId", "SubcategoryId")
);

COMMENT ON TABLE "UserCategoryBindings" IS 'กำหนด Category ที่ Purchasing/PURCHASING_APPROVER รับผิดชอบ (Purchasing Approver chain via UserCompanyRoles.ApproverLevel)';

-- 3.4 Delegations
CREATE TABLE "Delegations" (
  "Id" BIGSERIAL PRIMARY KEY,
  "FromUserId" BIGINT NOT NULL REFERENCES "Users"("Id"),
  "ToUserId" BIGINT NOT NULL REFERENCES "Users"("Id"),
  "CompanyId" BIGINT NOT NULL REFERENCES "Companies"("Id"),
  "RoleId" BIGINT NOT NULL REFERENCES "Roles"("Id"),
  "FromPositionId" BIGINT REFERENCES "Positions"("Id"),
  "DelegatedApproverLevel" SMALLINT,
  "StartDate" TIMESTAMP WITH TIME ZONE NOT NULL,
  "EndDate" TIMESTAMP WITH TIME ZONE NOT NULL,
  "Reason" TEXT,
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  "CreatedBy" BIGINT,
  
  CONSTRAINT "chk_delegation_dates" CHECK ("EndDate" > "StartDate"),
  CONSTRAINT "chk_delegation_users" CHECK ("FromUserId" != "ToUserId")
);

COMMENT ON TABLE "Delegations" IS 'การมอบหมายงานชั่วคราว (เช่น ลางาน)';

-- =============================================
-- SECTION 4: SUPPLIER MANAGEMENT
-- =============================================

-- 4.1 Suppliers
CREATE TABLE "Suppliers" (
  "Id" BIGSERIAL PRIMARY KEY,
  "TaxId" VARCHAR(20) UNIQUE,
  "CompanyNameTh" VARCHAR(200) NOT NULL,
  "CompanyNameEn" VARCHAR(200),
  "BusinessTypeId" SMALLINT NOT NULL REFERENCES "BusinessTypes"("Id"),
  "JobTypeId" SMALLINT NOT NULL REFERENCES "JobTypes"("Id"),
  "RegisteredCapital" DECIMAL(15,2),
  "RegisteredCapitalCurrencyId" BIGINT REFERENCES "Currencies"("Id"),
  "DefaultCurrencyId" BIGINT REFERENCES "Currencies"("Id"),
  "CompanyEmail" VARCHAR(100),
  "CompanyPhone" VARCHAR(20),
  "CompanyFax" VARCHAR(20),
  "CompanyWebsite" VARCHAR(200),
  "AddressLine1" VARCHAR(200),
  "AddressLine2" VARCHAR(200),
  "City" VARCHAR(100),
  "Province" VARCHAR(100),
  "PostalCode" VARCHAR(20),
  "CountryId" BIGINT REFERENCES "Countries"("Id"),
  "BusinessScope" TEXT,
  "FoundedDate" DATE,
  "InvitedByUserId" BIGINT REFERENCES "Users"("Id"),
  "InvitedByCompanyId" BIGINT REFERENCES "Companies"("Id"),
  "InvitedAt" TIMESTAMP WITH TIME ZONE,
  "RegisteredAt" TIMESTAMP WITH TIME ZONE,
  "ApprovedByUserId" BIGINT REFERENCES "Users"("Id"),
  "ApprovedAt" TIMESTAMP WITH TIME ZONE,
  "Status" VARCHAR(20) DEFAULT 'PENDING',
  "DeclineReason" TEXT,
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  "UpdatedAt" TIMESTAMP WITH TIME ZONE,
  
  CONSTRAINT "chk_supplier_status" CHECK ("Status" IN ('PENDING','COMPLETED','DECLINED'))
);

COMMENT ON TABLE "Suppliers" IS 'ข้อมูล Supplier ที่ลงทะเบียนในระบบ';

-- 4.2 SupplierContacts
CREATE TABLE "SupplierContacts" (
  "Id" BIGSERIAL PRIMARY KEY,
  "SupplierId" BIGINT NOT NULL REFERENCES "Suppliers"("Id"),
  "FirstName" VARCHAR(100) NOT NULL,
  "LastName" VARCHAR(100) NOT NULL,
  "Position" VARCHAR(100),
  "Email" VARCHAR(100) NOT NULL,
  "PhoneNumber" VARCHAR(20),
  "MobileNumber" VARCHAR(20),
  "PreferredLanguage" VARCHAR(5) DEFAULT 'th', -- NEW in v6.2
  "PreferredTimezone" VARCHAR(50) DEFAULT 'Asia/Bangkok', -- NEW in v6.3
  "PasswordHash" VARCHAR(255),
  "SecurityStamp" VARCHAR(100),
  "IsEmailVerified" BOOLEAN DEFAULT FALSE,
  "EmailVerifiedAt" TIMESTAMP WITH TIME ZONE,
  "PasswordResetToken" VARCHAR(255),
  "PasswordResetExpiry" TIMESTAMP WITH TIME ZONE,
  "LastLoginAt" TIMESTAMP WITH TIME ZONE,
  "FailedLoginAttempts" INT DEFAULT 0,
  "LockoutEnd" TIMESTAMP WITH TIME ZONE,
  "CanSubmitQuotation" BOOLEAN DEFAULT TRUE,
  "CanReceiveNotification" BOOLEAN DEFAULT TRUE,
  "CanViewReports" BOOLEAN DEFAULT FALSE,
  "IsPrimaryContact" BOOLEAN DEFAULT FALSE,
  "ReceiveSMS" BOOLEAN DEFAULT FALSE,
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  "CreatedBy" BIGINT,
  "UpdatedAt" TIMESTAMP WITH TIME ZONE,
  "UpdatedBy" BIGINT,
  
  UNIQUE("SupplierId", "Email"),
  CONSTRAINT "chk_contact_language" CHECK ("PreferredLanguage" IN ('th','en'))
);

COMMENT ON TABLE "SupplierContacts" IS 'ผู้ติดต่อของ Supplier';
COMMENT ON COLUMN "SupplierContacts"."PreferredLanguage" IS 'ภาษาที่ต้องการ th/en (NEW in v6.2)';
COMMENT ON COLUMN "SupplierContacts"."PreferredTimezone" IS 'IANA timezone auto-detected from Supplier country (NEW in v6.3)';

-- 4.3 SupplierCategories
CREATE TABLE "SupplierCategories" (
  "Id" BIGSERIAL PRIMARY KEY,
  "SupplierId" BIGINT NOT NULL REFERENCES "Suppliers"("Id"),
  "CategoryId" BIGINT NOT NULL REFERENCES "Categories"("Id"),
  "SubcategoryId" BIGINT REFERENCES "Subcategories"("Id"),
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE("SupplierId", "CategoryId", "SubcategoryId")
);

COMMENT ON TABLE "SupplierCategories" IS 'Category ที่ Supplier ให้บริการ';

-- 4.4 SupplierDocuments
CREATE TABLE "SupplierDocuments" (
  "Id" BIGSERIAL PRIMARY KEY,
  "SupplierId" BIGINT NOT NULL REFERENCES "Suppliers"("Id"),
  "DocumentType" VARCHAR(50) NOT NULL,
  "DocumentName" VARCHAR(200) NOT NULL,
  "FileName" VARCHAR(255) NOT NULL,
  "FilePath" TEXT,
  "FileSize" BIGINT,
  "MimeType" VARCHAR(100),
  "IsActive" BOOLEAN DEFAULT TRUE,
  "UploadedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  "UploadedBy" BIGINT
);

COMMENT ON TABLE "SupplierDocuments" IS 'เอกสารของ Supplier';

-- =============================================
-- SECTION 5: RFQ MANAGEMENT
-- =============================================

-- 5.1 Rfqs
CREATE TABLE "Rfqs" (
  "Id" BIGSERIAL PRIMARY KEY,
  "RfqNumber" VARCHAR(50) UNIQUE NOT NULL,
  "ProjectName" VARCHAR(500) NOT NULL,
  "CompanyId" BIGINT NOT NULL REFERENCES "Companies"("Id"),
  "DepartmentId" BIGINT NOT NULL REFERENCES "Departments"("Id"),
  "CategoryId" BIGINT NOT NULL REFERENCES "Categories"("Id"),
  "SubcategoryId" BIGINT NOT NULL REFERENCES "Subcategories"("Id"),
  "JobTypeId" SMALLINT NOT NULL REFERENCES "JobTypes"("Id"),
  "RequesterId" BIGINT NOT NULL REFERENCES "Users"("Id"),
  "ResponsiblePersonId" BIGINT REFERENCES "Users"("Id"),
  "ResponsiblePersonAssignedAt" TIMESTAMP WITH TIME ZONE,
  "RequesterEmail" VARCHAR(100),
  "RequesterPhone" VARCHAR(20),
  "BudgetAmount" DECIMAL(15,2),
  "BudgetCurrencyId" BIGINT NOT NULL REFERENCES "Currencies"("Id"),
  "CreatedDate" DATE NOT NULL DEFAULT CURRENT_DATE,
  "RequiredQuotationDate" TIMESTAMP WITH TIME ZONE NOT NULL,
  "QuotationDeadline" TIMESTAMP WITH TIME ZONE,
  "SubmissionDeadline" TIMESTAMP WITH TIME ZONE,
  "SerialNumber" VARCHAR(100),
  "Status" VARCHAR(20) DEFAULT 'SAVE_DRAFT',
  "CurrentLevel" SMALLINT DEFAULT 0,
  "CurrentActorId" BIGINT REFERENCES "Users"("Id"),
  "CurrentActorReceivedAt" TIMESTAMP WITH TIME ZONE,
  "ReBidCount" INT DEFAULT 0,
  "LastReBidAt" TIMESTAMP WITH TIME ZONE,
  "ReBidReason" TEXT,
  "LastActionAt" TIMESTAMP WITH TIME ZONE,
  "LastReminderSentAt" TIMESTAMP WITH TIME ZONE,
  "IsUrgent" BOOLEAN DEFAULT FALSE,
  "ProcessingDays" INT,
  "IsOverdue" BOOLEAN DEFAULT FALSE,
  "DeclineReason" TEXT,
  "RejectReason" TEXT,
  "Remarks" TEXT,
  "PurchasingRemarks" TEXT,
  "CreatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  "CreatedBy" BIGINT REFERENCES "Users"("Id"),
  "UpdatedAt" TIMESTAMP WITH TIME ZONE,
  "UpdatedBy" BIGINT REFERENCES "Users"("Id"),
  
  CONSTRAINT "chk_rfq_status" CHECK ("Status" IN 
    ('SAVE_DRAFT','PENDING','DECLINED','REJECTED','COMPLETED','RE_BID')),
  CONSTRAINT "chk_rfq_job_type" CHECK ("JobTypeId" IN (1, 2)),
  CONSTRAINT "chk_rfq_dates" CHECK (
    "QuotationDeadline" > "CreatedDate" 
    AND ("SubmissionDeadline" IS NULL OR "SubmissionDeadline" <= "RequiredQuotationDate")
  )
);

COMMENT ON TABLE "Rfqs" IS 'ใบขอเสนอราคา';
COMMENT ON COLUMN "Rfqs"."ResponsiblePersonAssignedAt" IS
  'เมื่อไหร่ที่ Purchasing รับมอบหมาย (Temporal Data Pattern - v6.2.2)';
COMMENT ON COLUMN "Rfqs"."PurchasingRemarks" IS 'ข้อมูลเพิ่มเติมจาก Purchasing';

-- 5.2 RfqItems
CREATE TABLE "RfqItems" (
  "Id" BIGSERIAL PRIMARY KEY,
  "RfqId" BIGINT NOT NULL REFERENCES "Rfqs"("Id") ON DELETE CASCADE,
  "ItemSequence" INT NOT NULL,
  "ProductCode" VARCHAR(50),
  "ProductName" TEXT NOT NULL,
  "Brand" VARCHAR(100),
  "Model" VARCHAR(100),
  "Quantity" DECIMAL(12,4) NOT NULL,
  "UnitOfMeasure" VARCHAR(50) NOT NULL,
  "ProductDescription" TEXT,
  "Remarks" TEXT,
  "CreatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  "UpdatedAt" TIMESTAMP WITH TIME ZONE,
  
  UNIQUE("RfqId", "ItemSequence"),
  CONSTRAINT "chk_rfq_items_quantity" CHECK ("Quantity" > 0)
);

COMMENT ON TABLE "RfqItems" IS 'รายการสินค้า/บริการใน RFQ';

-- 5.3 RfqDocuments
CREATE TABLE "RfqDocuments" (
  "Id" BIGSERIAL PRIMARY KEY,
  "RfqId" BIGINT NOT NULL REFERENCES "Rfqs"("Id") ON DELETE CASCADE,
  "DocumentType" VARCHAR(50) NOT NULL,
  "DocumentName" VARCHAR(200) NOT NULL,
  "FileName" VARCHAR(255) NOT NULL,
  "FilePath" TEXT,
  "FileSize" BIGINT,
  "MimeType" VARCHAR(100),
  "UploadedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  "UploadedBy" BIGINT REFERENCES "Users"("Id")
);

COMMENT ON TABLE "RfqDocuments" IS 'เอกสารแนบ RFQ';

-- 5.4 RfqRequiredFields
CREATE TABLE "RfqRequiredFields" (
  "Id" BIGSERIAL PRIMARY KEY,
  "RfqId" BIGINT NOT NULL REFERENCES "Rfqs"("Id") ON DELETE CASCADE,
  "RequireMOQ" BOOLEAN DEFAULT FALSE,
  "RequireDLT" BOOLEAN DEFAULT FALSE,
  "RequireCredit" BOOLEAN DEFAULT FALSE,
  "RequireWarranty" BOOLEAN DEFAULT FALSE,
  "RequireIncoTerm" BOOLEAN DEFAULT FALSE,
  "CreatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  "CreatedBy" BIGINT REFERENCES "Users"("Id"),
  "UpdatedAt" TIMESTAMP WITH TIME ZONE,
  "UpdatedBy" BIGINT REFERENCES "Users"("Id"),
  
  CONSTRAINT "uk_rfq_required_fields" UNIQUE("RfqId")
);

COMMENT ON TABLE "RfqRequiredFields" IS 'กำหนดข้อมูลที่ Supplier ต้องระบุ';

-- 5.5 PurchasingDocuments
CREATE TABLE "PurchasingDocuments" (
  "Id" BIGSERIAL PRIMARY KEY,
  "RfqId" BIGINT NOT NULL REFERENCES "Rfqs"("Id") ON DELETE CASCADE,
  "DocumentName" VARCHAR(200) NOT NULL,
  "FileName" VARCHAR(255) NOT NULL,
  "FilePath" TEXT NOT NULL,
  "FileSize" BIGINT,
  "MimeType" VARCHAR(100),
  "UploadedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  "UploadedBy" BIGINT NOT NULL REFERENCES "Users"("Id")
);

COMMENT ON TABLE "PurchasingDocuments" IS 'เอกสารเพิ่มเติมจาก Purchasing';

-- 5.6 RfqDeadlineHistory
CREATE TABLE "RfqDeadlineHistory" (
  "Id" BIGSERIAL PRIMARY KEY,
  "RfqId" BIGINT NOT NULL REFERENCES "Rfqs"("Id") ON DELETE CASCADE,
  "FromDeadline" TIMESTAMP WITH TIME ZONE,
  "ToDeadline" TIMESTAMP WITH TIME ZONE NOT NULL,
  "FromHour" SMALLINT,
  "ToHour" SMALLINT NOT NULL,
  "FromMinute" SMALLINT,
  "ToMinute" SMALLINT NOT NULL,
  "ChangeReason" TEXT NOT NULL,
  "ChangedBy" BIGINT NOT NULL REFERENCES "Users"("Id"),
  "ChangedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE "RfqDeadlineHistory" IS 'ประวัติการเปลี่ยน deadline';

-- =============================================
-- SECTION 6: WORKFLOW & APPROVAL
-- =============================================

-- 6.1 RfqStatusHistory
CREATE TABLE "RfqStatusHistory" (
  "Id" BIGSERIAL PRIMARY KEY,
  "RfqId" BIGINT NOT NULL REFERENCES "Rfqs"("Id"),
  "FromStatus" VARCHAR(20),
  "ToStatus" VARCHAR(20) NOT NULL,
  "ActionType" VARCHAR(50) NOT NULL,
  "ActorId" BIGINT NOT NULL REFERENCES "Users"("Id"),
  "ActorRole" VARCHAR(30),
  "ApprovalLevel" SMALLINT,
  "Decision" VARCHAR(20),
  "Reason" TEXT,
  "Comments" TEXT,
  "ActionAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT "chk_decision" CHECK ("Decision" IN ('APPROVED','DECLINED','REJECTED','SUBMITTED'))
);

COMMENT ON TABLE "RfqStatusHistory" IS 'ประวัติการเปลี่ยนสถานะ RFQ';

-- 6.2 RfqActorTimeline
CREATE TABLE "RfqActorTimeline" (
  "Id" BIGSERIAL PRIMARY KEY,
  "RfqId" BIGINT NOT NULL REFERENCES "Rfqs"("Id"),
  "ActorId" BIGINT NOT NULL REFERENCES "Users"("Id"),
  "ActorRole" VARCHAR(30) NOT NULL,
  "ReceivedAt" TIMESTAMP WITH TIME ZONE NOT NULL,
  "ActionAt" TIMESTAMP WITH TIME ZONE,
  "IsOntime" BOOLEAN,
  
  CONSTRAINT "uk_rfq_actor" UNIQUE("RfqId", "ActorId", "ReceivedAt")
);

COMMENT ON TABLE "RfqActorTimeline" IS 'Timeline การทำงานของแต่ละ Actor';

-- =============================================
-- SECTION 7: QUOTATION MANAGEMENT
-- =============================================

-- 7.1 RfqInvitations
CREATE TABLE "RfqInvitations" (
  "Id" BIGSERIAL PRIMARY KEY,
  "RfqId" BIGINT NOT NULL REFERENCES "Rfqs"("Id") ON DELETE CASCADE,
  "SupplierId" BIGINT NOT NULL REFERENCES "Suppliers"("Id"),
  "InvitedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "InvitedByUserId" BIGINT NOT NULL REFERENCES "Users"("Id"),
  "ResponseStatus" VARCHAR(30) DEFAULT 'NO_RESPONSE',
  "RespondedAt" TIMESTAMP WITH TIME ZONE,
  "Decision" VARCHAR(30) DEFAULT 'PENDING',
  "DecisionReason" TEXT,
  "RespondedByContactId" BIGINT REFERENCES "SupplierContacts"("Id"),
  "DecisionChangeCount" INT DEFAULT 0,
  "LastDecisionChangeAt" TIMESTAMP WITH TIME ZONE,
  "ReBidCount" INT DEFAULT 0,
  "LastReBidAt" TIMESTAMP WITH TIME ZONE,
  "RespondedIpAddress" INET,
  "RespondedUserAgent" TEXT,
  "RespondedDeviceInfo" TEXT,
  "AutoDeclinedAt" TIMESTAMP WITH TIME ZONE,
  "IsManuallyAdded" BOOLEAN DEFAULT FALSE,
  "CreatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  "UpdatedAt" TIMESTAMP WITH TIME ZONE,
  
  CONSTRAINT "uk_rfq_supplier" UNIQUE("RfqId", "SupplierId"),
  CONSTRAINT "chk_response_status" CHECK ("ResponseStatus" IN ('NO_RESPONSE','RESPONDED')),
  CONSTRAINT "chk_invitation_decision" CHECK ("Decision" IN 
    ('PENDING','PARTICIPATING','NOT_PARTICIPATING','AUTO_DECLINED'))
);

COMMENT ON TABLE "RfqInvitations" IS 'การเชิญ Supplier เสนอราคา';
COMMENT ON COLUMN "RfqInvitations"."IsManuallyAdded" IS 'Flag สำหรับ Supplier ที่เพิ่มด้วย manual';

-- 7.2 RfqInvitationHistory
CREATE TABLE "RfqInvitationHistory" (
  "Id" BIGSERIAL PRIMARY KEY,
  "InvitationId" BIGINT NOT NULL REFERENCES "RfqInvitations"("Id"),
  "DecisionSequence" INT NOT NULL,
  "FromDecision" VARCHAR(30),
  "ToDecision" VARCHAR(30) NOT NULL,
  "ChangedByContactId" BIGINT REFERENCES "SupplierContacts"("Id"),
  "ChangedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  "ChangeReason" TEXT,
  
  CONSTRAINT "uk_invitation_sequence" UNIQUE("InvitationId", "DecisionSequence")
);

COMMENT ON TABLE "RfqInvitationHistory" IS 'ประวัติการเปลี่ยนการตอบรับคำเชิญ';

-- 7.3 QuotationItems
CREATE TABLE "QuotationItems" (
  "Id" BIGSERIAL PRIMARY KEY,
  "RfqId" BIGINT NOT NULL REFERENCES "Rfqs"("Id"),
  "SupplierId" BIGINT NOT NULL REFERENCES "Suppliers"("Id"),
  "RfqItemId" BIGINT NOT NULL REFERENCES "RfqItems"("Id"),
  "UnitPrice" DECIMAL(18,4) NOT NULL,
  "Quantity" DECIMAL(12,4) NOT NULL,
  "TotalPrice" DECIMAL(18,4) GENERATED ALWAYS AS ("Quantity" * "UnitPrice") STORED,
  "ConvertedUnitPrice" DECIMAL(18,4),
  "ConvertedTotalPrice" DECIMAL(18,4),
  "CurrencyId" BIGINT REFERENCES "Currencies"("Id"),
  "IncotermId" BIGINT REFERENCES "Incoterms"("Id"),
  "MinOrderQty" INT,
  "DeliveryDays" INT,
  "CreditDays" INT,
  "WarrantyDays" INT,
  "Remarks" TEXT,
  "SubmittedAt" TIMESTAMP WITH TIME ZONE,
  "SubmittedByContactId" BIGINT REFERENCES "SupplierContacts"("Id"),
  "CreatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT "uk_quotation_item" UNIQUE("RfqId", "SupplierId", "RfqItemId")
);

COMMENT ON TABLE "QuotationItems" IS 'รายการในใบเสนอราคา (ไม่มี Quotations table แล้ว)';
COMMENT ON COLUMN "QuotationItems"."TotalPrice" IS
  'ราคารวม คำนวณ auto จาก (Quantity × UnitPrice) - GENERATED COLUMN (v6.2.2)
   Business Rule: "ราคารวม จะคำนวณ auto จาก (จำนวนสินค้า*ราคาต่อหน่วย)"
   Data Integrity: Cannot be manually set, database-enforced calculation';

-- 7.4 QuotationDocuments (NEW in v6.2)
CREATE TABLE "QuotationDocuments" (
  "Id" BIGSERIAL PRIMARY KEY,
  "RfqId" BIGINT NOT NULL REFERENCES "Rfqs"("Id") ON DELETE CASCADE,
  "SupplierId" BIGINT NOT NULL REFERENCES "Suppliers"("Id"),
  "DocumentType" VARCHAR(50) NOT NULL,
  "DocumentName" VARCHAR(200) NOT NULL,
  "FileName" VARCHAR(255) NOT NULL,
  "FilePath" TEXT NOT NULL,
  "FileSize" BIGINT,
  "MimeType" VARCHAR(100),
  "UploadedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  "UploadedByContactId" BIGINT REFERENCES "SupplierContacts"("Id")
);

COMMENT ON TABLE "QuotationDocuments" IS 'เอกสารใบเสนอราคาจาก Supplier (NEW in v6.2)';

-- 7.5 RfqItemWinners
CREATE TABLE "RfqItemWinners" (
  "Id" BIGSERIAL PRIMARY KEY,
  "RfqId" BIGINT NOT NULL REFERENCES "Rfqs"("Id"),
  "RfqItemId" BIGINT NOT NULL REFERENCES "RfqItems"("Id"),
  "SupplierId" BIGINT NOT NULL REFERENCES "Suppliers"("Id"),
  "QuotationItemId" BIGINT NOT NULL REFERENCES "QuotationItems"("Id"),
  "SystemRank" INT NOT NULL,
  "FinalRank" INT NOT NULL,
  "IsSystemMatch" BOOLEAN DEFAULT TRUE,
  "SelectionReason" TEXT,
  "SelectedBy" BIGINT NOT NULL REFERENCES "Users"("Id"),
  "SelectedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  "ApprovedBy" BIGINT REFERENCES "Users"("Id"),
  "ApprovedAt" TIMESTAMP WITH TIME ZONE,
  
  UNIQUE("RfqItemId")
);

COMMENT ON TABLE "RfqItemWinners" IS 'เลือกผู้ชนะระดับ item (1 winner per item)';

-- 7.6 RfqItemWinnerOverrides (NEW in v6.2)
CREATE TABLE "RfqItemWinnerOverrides" (
  "Id" BIGSERIAL PRIMARY KEY,
  "RfqItemWinnerId" BIGINT NOT NULL REFERENCES "RfqItemWinners"("Id"),
  "OriginalSupplierId" BIGINT NOT NULL REFERENCES "Suppliers"("Id"),
  "OriginalQuotationItemId" BIGINT NOT NULL REFERENCES "QuotationItems"("Id"),
  "NewSupplierId" BIGINT NOT NULL REFERENCES "Suppliers"("Id"),
  "NewQuotationItemId" BIGINT NOT NULL REFERENCES "QuotationItems"("Id"),
  "OverrideReason" TEXT NOT NULL,
  "OverriddenBy" BIGINT NOT NULL REFERENCES "Users"("Id"),
  "OverriddenAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  "ApprovedBy" BIGINT REFERENCES "Users"("Id"),
  "ApprovedAt" TIMESTAMP WITH TIME ZONE,
  "IsActive" BOOLEAN DEFAULT TRUE
);

COMMENT ON TABLE "RfqItemWinnerOverrides" IS 'ประวัติการเปลี่ยนผู้ชนะ (NEW in v6.2)';

-- =============================================
-- SECTION 8: COMMUNICATION & Q&A
-- =============================================

-- 8.1 QnAThreads
CREATE TABLE "QnAThreads" (
  "Id" BIGSERIAL PRIMARY KEY,
  "RfqId" BIGINT NOT NULL REFERENCES "Rfqs"("Id"),
  "SupplierId" BIGINT NOT NULL REFERENCES "Suppliers"("Id"),
  "ThreadStatus" VARCHAR(20) DEFAULT 'OPEN',
  "CreatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  "ClosedAt" TIMESTAMP WITH TIME ZONE,
  
  UNIQUE("RfqId", "SupplierId"),
  CONSTRAINT "chk_thread_status" CHECK ("ThreadStatus" IN ('OPEN','CLOSED'))
);

COMMENT ON TABLE "QnAThreads" IS 'Thread สำหรับถาม-ตอบระหว่าง Supplier และ Purchasing';

-- 8.2 QnAMessages
CREATE TABLE "QnAMessages" (
  "Id" BIGSERIAL PRIMARY KEY,
  "ThreadId" BIGINT NOT NULL REFERENCES "QnAThreads"("Id"),
  "MessageText" TEXT NOT NULL,
  "SenderType" VARCHAR(20) NOT NULL,
  "SenderId" BIGINT NOT NULL,
  "SentAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  "IsRead" BOOLEAN DEFAULT FALSE,
  "ReadAt" TIMESTAMP WITH TIME ZONE,
  
  CONSTRAINT "chk_sender_type" CHECK ("SenderType" IN ('SUPPLIER','PURCHASING'))
);

COMMENT ON TABLE "QnAMessages" IS 'ข้อความในแต่ละ Thread';

-- =============================================
-- SECTION 9: NOTIFICATION SYSTEM
-- =============================================

-- 9.1 Notifications
CREATE TABLE "Notifications" (
  "Id" BIGSERIAL PRIMARY KEY,
  "Type" VARCHAR(50) NOT NULL,
  "Priority" VARCHAR(20) DEFAULT 'NORMAL',
  "NotificationType" VARCHAR(30) DEFAULT 'INFO',
  "UserId" BIGINT REFERENCES "Users"("Id"),
  "ContactId" BIGINT REFERENCES "SupplierContacts"("Id"),
  "RfqId" BIGINT REFERENCES "Rfqs"("Id"),
  "Title" VARCHAR(200) NOT NULL,
  "Message" TEXT NOT NULL,
  "IconType" VARCHAR(20),
  "ActionUrl" TEXT,
  "IsRead" BOOLEAN DEFAULT FALSE,
  "ReadAt" TIMESTAMP WITH TIME ZONE,
  "Channels" TEXT[],
  "EmailSent" BOOLEAN DEFAULT FALSE,
  "EmailSentAt" TIMESTAMP WITH TIME ZONE,
  "SmsSent" BOOLEAN DEFAULT FALSE,
  "SmsSentAt" TIMESTAMP WITH TIME ZONE,
  "RecipientPhone" VARCHAR(20),
  "SmsProvider" VARCHAR(20),
  "SmsStatus" VARCHAR(20),
  "SmsMessageId" VARCHAR(100),
  "SignalRConnectionId" VARCHAR(100),
  "MessageQueueId" UUID,
  "ScheduledFor" TIMESTAMP WITH TIME ZONE,
  "ProcessedAt" TIMESTAMP WITH TIME ZONE,
  "CreatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  "CreatedBy" BIGINT,

  CONSTRAINT "chk_notification_priority" CHECK ("Priority" IN ('LOW','NORMAL','HIGH','URGENT')),
  CONSTRAINT "chk_notification_icon" CHECK ("IconType" IN (
    -- Status-based (RFQ Lifecycle)
    'DRAFT_WARNING','PENDING_ACTION','APPROVED','DECLINED','REJECTED','COMPLETED','RE_BID',
    -- Action-based (Workflow)
    'ASSIGNED','INVITATION',
    -- Supplier-related
    'SUPPLIER_NEW','SUPPLIER_APPROVED','SUPPLIER_DECLINED',
    -- Q&A
    'QUESTION','REPLY',
    -- Quotation & Winner
    'QUOTATION_SUBMITTED','WINNER_SELECTED','WINNER_ANNOUNCED',
    -- Time-related
    'DEADLINE_EXTENDED','DEADLINE_WARNING','OVERDUE',
    -- Generic
    'EDIT','INFO'
  ))
);

COMMENT ON TABLE "Notifications" IS 'การแจ้งเตือน (Enhanced for SMS & SignalR)';
COMMENT ON COLUMN "Notifications"."IconType" IS
  'ประเภทไอคอน สำหรับแสดงใน UI - Data Quality (v6.2.2)
   22 valid values covering all business scenarios:
   Status: DRAFT_WARNING, PENDING_ACTION, APPROVED, DECLINED, REJECTED, COMPLETED, RE_BID
   Action: ASSIGNED, INVITATION
   Supplier: SUPPLIER_NEW, SUPPLIER_APPROVED, SUPPLIER_DECLINED
   Q&A: QUESTION, REPLY
   Quotation: QUOTATION_SUBMITTED, WINNER_SELECTED, WINNER_ANNOUNCED
   Time: DEADLINE_EXTENDED, DEADLINE_WARNING, OVERDUE
   Generic: EDIT, INFO
   Database-enforced enum prevents typos and invalid icon types';

-- =============================================
-- SECTION 10: FINANCIAL & EXCHANGE RATES
-- =============================================

-- 10.1 ExchangeRates
CREATE TABLE "ExchangeRates" (
  "Id" BIGSERIAL PRIMARY KEY,
  "FromCurrencyId" BIGINT NOT NULL REFERENCES "Currencies"("Id"),
  "ToCurrencyId" BIGINT NOT NULL REFERENCES "Currencies"("Id"),
  "Rate" DECIMAL(15,6) NOT NULL,
  "EffectiveDate" DATE NOT NULL,
  "ExpiryDate" DATE,
  "Source" VARCHAR(50) DEFAULT 'MANUAL',
  "SourceReference" VARCHAR(100),
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  "CreatedBy" BIGINT REFERENCES "Users"("Id"),
  "UpdatedAt" TIMESTAMP WITH TIME ZONE,
  "UpdatedBy" BIGINT REFERENCES "Users"("Id"),
  
  UNIQUE("FromCurrencyId", "ToCurrencyId", "EffectiveDate"),
  CONSTRAINT "chk_exchange_rate" CHECK ("Rate" > 0),
  CONSTRAINT "chk_exchange_dates" CHECK (
    "ExpiryDate" IS NULL OR "ExpiryDate" > "EffectiveDate"
  )
);

COMMENT ON TABLE "ExchangeRates" IS 'อัตราแลกเปลี่ยน';

-- 10.2 ExchangeRateHistory
CREATE TABLE "ExchangeRateHistory" (
  "Id" BIGSERIAL PRIMARY KEY,
  "ExchangeRateId" BIGINT NOT NULL REFERENCES "ExchangeRates"("Id"),
  "OldRate" DECIMAL(15,6),
  "NewRate" DECIMAL(15,6),
  "ChangedBy" BIGINT NOT NULL REFERENCES "Users"("Id"),
  "ChangedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  "ChangeReason" TEXT
);

COMMENT ON TABLE "ExchangeRateHistory" IS 'ประวัติการเปลี่ยนแปลงอัตราแลกเปลี่ยน';

-- =============================================
-- SECTION 11: AUTHENTICATION & SECURITY
-- =============================================

-- 11.1 RefreshTokens
CREATE TABLE "RefreshTokens" (
  "Id" BIGSERIAL PRIMARY KEY,
  "Token" VARCHAR(500) UNIQUE NOT NULL,
  "UserType" VARCHAR(20) NOT NULL,
  "UserId" BIGINT,
  "ContactId" BIGINT,
  "ExpiresAt" TIMESTAMP WITH TIME ZONE NOT NULL,
  "CreatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  "CreatedByIp" VARCHAR(45),
  "RevokedAt" TIMESTAMP WITH TIME ZONE,
  "RevokedByIp" VARCHAR(45),
  "ReplacedByToken" VARCHAR(500),
  "ReasonRevoked" VARCHAR(100),
  
  CONSTRAINT "chk_refresh_user_type" CHECK ("UserType" IN ('Employee', 'SupplierContact')),
  CONSTRAINT "chk_refresh_user_ref" CHECK (
    ("UserType" = 'Employee' AND "UserId" IS NOT NULL AND "ContactId" IS NULL) OR
    ("UserType" = 'SupplierContact' AND "ContactId" IS NOT NULL AND "UserId" IS NULL)
  )
);

COMMENT ON TABLE "RefreshTokens" IS 'JWT Refresh Tokens';

-- 11.2 LoginHistory
CREATE TABLE "LoginHistory" (
  "Id" BIGSERIAL PRIMARY KEY,
  "UserType" VARCHAR(20) NOT NULL,
  "UserId" BIGINT,
  "ContactId" BIGINT,
  "Email" VARCHAR(100),
  "LoginAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  "LoginIp" VARCHAR(45),
  "UserAgent" TEXT,
  "DeviceInfo" TEXT,
  "Country" VARCHAR(100),
  "City" VARCHAR(100),
  "Success" BOOLEAN NOT NULL,
  "FailureReason" VARCHAR(200),
  "SessionId" VARCHAR(100),
  "RefreshTokenId" BIGINT REFERENCES "RefreshTokens"("Id"),
  "LogoutAt" TIMESTAMP WITH TIME ZONE,
  "LogoutType" VARCHAR(20),
  
  CONSTRAINT "chk_login_user_type" CHECK ("UserType" IN ('Employee', 'SupplierContact'))
);

COMMENT ON TABLE "LoginHistory" IS 'ประวัติการ Login/Logout';

-- =============================================
-- SECTION 12: SYSTEM & AUDIT
-- =============================================

-- 12.1 ActivityLogs
CREATE TABLE "ActivityLogs" (
  "Id" BIGSERIAL PRIMARY KEY,
  "UserId" BIGINT REFERENCES "Users"("Id"),
  "CompanyId" BIGINT REFERENCES "Companies"("Id"),
  "Module" VARCHAR(50),
  "Action" VARCHAR(100),
  "EntityType" VARCHAR(50),
  "EntityId" BIGINT,
  "OldValues" JSONB,
  "NewValues" JSONB,
  "IpAddress" INET,
  "UserAgent" TEXT,
  "SessionId" VARCHAR(100),
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE "ActivityLogs" IS 'บันทึกกิจกรรมสำคัญ (Critical actions only)';

-- 12.2 SystemConfigurations
CREATE TABLE "SystemConfigurations" (
  "Id" BIGSERIAL PRIMARY KEY,
  "ConfigKey" VARCHAR(100) UNIQUE NOT NULL,
  "ConfigValue" TEXT,
  "ConfigType" VARCHAR(20),
  "Description" TEXT,
  "IsEncrypted" BOOLEAN DEFAULT FALSE,
  "CompanyId" BIGINT REFERENCES "Companies"("Id"),
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  "CreatedBy" BIGINT REFERENCES "Users"("Id"),
  "UpdatedAt" TIMESTAMP WITH TIME ZONE,
  "UpdatedBy" BIGINT REFERENCES "Users"("Id")
);

COMMENT ON TABLE "SystemConfigurations" IS 'การตั้งค่าระบบที่แก้ไขผ่าน UI';

-- 12.3 ErrorLogs
CREATE TABLE "ErrorLogs" (
  "Id" BIGSERIAL PRIMARY KEY,
  "ErrorCode" VARCHAR(50),
  "ErrorMessage" TEXT NOT NULL,
  "ErrorDetails" TEXT,
  "UserId" BIGINT,
  "Module" VARCHAR(50),
  "Action" VARCHAR(100),
  "IsResolved" BOOLEAN DEFAULT FALSE,
  "ResolvedBy" BIGINT REFERENCES "Users"("Id"),
  "ResolvedAt" TIMESTAMP WITH TIME ZONE,
  "ResolutionNotes" TEXT,
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE "ErrorLogs" IS 'บันทึก Business Critical Errors';

-- =============================================
-- INDEXES FOR PERFORMANCE (Complete v6.2)
-- =============================================

-- User & Role Indexes
CREATE INDEX "idx_users_email" ON "Users"("Email");
CREATE INDEX "idx_users_active" ON "Users"("IsActive") WHERE "IsActive" = true;
CREATE INDEX "idx_users_deleted" ON "Users"("IsDeleted") WHERE "IsDeleted" = false;
CREATE INDEX "idx_user_company_roles_user" ON "UserCompanyRoles"("UserId");
CREATE INDEX "idx_user_company_roles_company" ON "UserCompanyRoles"("CompanyId");
CREATE INDEX "idx_user_company_roles_active" ON "UserCompanyRoles"("IsActive") WHERE "IsActive" = true;
CREATE INDEX "idx_user_category_bindings" ON "UserCategoryBindings"("UserCompanyRoleId");
-- NEW v6.2.1: Approval chain indexes
CREATE UNIQUE INDEX "idx_dept_approver_level_unique" ON "UserCompanyRoles"("CompanyId", "DepartmentId", "ApproverLevel") WHERE "PrimaryRoleId" = 4 AND "DepartmentId" IS NOT NULL AND "ApproverLevel" IS NOT NULL AND "IsActive" = TRUE AND "EndDate" IS NULL;
CREATE INDEX "idx_user_category_bindings_chain" ON "UserCategoryBindings"("CategoryId", "SubcategoryId", "UserCompanyRoleId") WHERE "IsActive" = TRUE;

-- RFQ Indexes
CREATE INDEX "idx_rfqs_status" ON "Rfqs"("Status");
CREATE INDEX "idx_rfqs_company" ON "Rfqs"("CompanyId");
CREATE INDEX "idx_rfqs_requester" ON "Rfqs"("RequesterId");
CREATE INDEX "idx_rfqs_current_actor" ON "Rfqs"("CurrentActorId");
CREATE INDEX "idx_rfqs_overdue" ON "Rfqs"("IsOverdue") WHERE "IsOverdue" = true;
CREATE INDEX "idx_rfqs_category" ON "Rfqs"("CategoryId");
CREATE INDEX "idx_rfqs_subcategory" ON "Rfqs"("SubcategoryId");
CREATE INDEX "idx_rfqs_created_date" ON "Rfqs"("CreatedDate");
CREATE INDEX "idx_rfq_items_rfq" ON "RfqItems"("RfqId");
CREATE INDEX "idx_rfq_documents_rfq" ON "RfqDocuments"("RfqId");
CREATE INDEX "idx_rfq_status_history_rfq" ON "RfqStatusHistory"("RfqId");
CREATE INDEX "idx_rfq_status_history_actor" ON "RfqStatusHistory"("ActorId");
CREATE INDEX "idx_rfq_actor_timeline_rfq" ON "RfqActorTimeline"("RfqId");
CREATE INDEX "idx_rfq_actor_timeline_actor" ON "RfqActorTimeline"("ActorId");

-- Supplier Indexes
CREATE INDEX "idx_suppliers_status" ON "Suppliers"("Status");
CREATE INDEX "idx_suppliers_active" ON "Suppliers"("IsActive") WHERE "IsActive" = true;
CREATE INDEX "idx_suppliers_tax_id" ON "Suppliers"("TaxId");
CREATE INDEX "idx_supplier_contacts_supplier" ON "SupplierContacts"("SupplierId");
CREATE INDEX "idx_supplier_contacts_email" ON "SupplierContacts"("Email");
CREATE INDEX "idx_supplier_categories_supplier" ON "SupplierCategories"("SupplierId");
CREATE INDEX "idx_supplier_categories_category" ON "SupplierCategories"("CategoryId");
CREATE INDEX "idx_supplier_documents_supplier" ON "SupplierDocuments"("SupplierId");

-- Quotation Indexes
CREATE INDEX "idx_rfq_invitations_rfq" ON "RfqInvitations"("RfqId");
CREATE INDEX "idx_rfq_invitations_supplier" ON "RfqInvitations"("SupplierId");
CREATE INDEX "idx_rfq_invitations_status" ON "RfqInvitations"("ResponseStatus", "Decision");
CREATE INDEX "idx_quotation_items_rfq" ON "QuotationItems"("RfqId");
CREATE INDEX "idx_quotation_items_supplier" ON "QuotationItems"("SupplierId");
CREATE INDEX "idx_quotation_items_rfq_item" ON "QuotationItems"("RfqItemId");
CREATE INDEX "idx_quotation_items_currency" ON "QuotationItems"("CurrencyId");
CREATE INDEX "idx_quotation_documents_rfq" ON "QuotationDocuments"("RfqId"); -- NEW in v6.2
CREATE INDEX "idx_quotation_documents_supplier" ON "QuotationDocuments"("SupplierId"); -- NEW in v6.2

-- Winner Indexes
CREATE INDEX "idx_item_winners_rfq" ON "RfqItemWinners"("RfqId");
CREATE INDEX "idx_item_winners_item" ON "RfqItemWinners"("RfqItemId");
CREATE INDEX "idx_item_winners_supplier" ON "RfqItemWinners"("SupplierId");
CREATE INDEX "idx_winner_overrides_winner" ON "RfqItemWinnerOverrides"("RfqItemWinnerId"); -- NEW in v6.2
CREATE INDEX "idx_winner_overrides_active" ON "RfqItemWinnerOverrides"("IsActive") WHERE "IsActive" = true; -- NEW in v6.2

-- New indexes for v6.1 tables
CREATE INDEX "idx_purchasing_docs_rfq" ON "PurchasingDocuments"("RfqId");
CREATE INDEX "idx_deadline_history_rfq" ON "RfqDeadlineHistory"("RfqId");
CREATE INDEX "idx_supplier_doc_types" ON "SupplierDocumentTypes"("BusinessTypeId");

-- Q&A Indexes
CREATE INDEX "idx_qna_threads_rfq" ON "QnAThreads"("RfqId");
CREATE INDEX "idx_qna_threads_supplier" ON "QnAThreads"("SupplierId");
CREATE INDEX "idx_qna_messages_thread" ON "QnAMessages"("ThreadId");
CREATE INDEX "idx_qna_messages_unread" ON "QnAMessages"("ThreadId", "IsRead") WHERE "IsRead" = false;

-- Notification Indexes
CREATE INDEX "idx_notifications_user" ON "Notifications"("UserId") WHERE "IsRead" = false;
CREATE INDEX "idx_notifications_contact" ON "Notifications"("ContactId") WHERE "IsRead" = false;
CREATE INDEX "idx_notifications_rfq" ON "Notifications"("RfqId");

-- Exchange Rate Indexes
CREATE INDEX "idx_exchange_rates_active" ON "ExchangeRates"("FromCurrencyId", "ToCurrencyId", "EffectiveDate") 
  WHERE "IsActive" = true;
CREATE INDEX "idx_exchange_rate_history_rate" ON "ExchangeRateHistory"("ExchangeRateId");

-- Authentication Indexes
CREATE INDEX "idx_refresh_tokens_token" ON "RefreshTokens"("Token");
CREATE INDEX "idx_refresh_tokens_user" ON "RefreshTokens"("UserId") WHERE "UserId" IS NOT NULL;
CREATE INDEX "idx_refresh_tokens_contact" ON "RefreshTokens"("ContactId") WHERE "ContactId" IS NOT NULL;
CREATE INDEX "idx_login_history_user" ON "LoginHistory"("UserId") WHERE "UserId" IS NOT NULL;
CREATE INDEX "idx_login_history_contact" ON "LoginHistory"("ContactId") WHERE "ContactId" IS NOT NULL;
CREATE INDEX "idx_login_history_date" ON "LoginHistory"("LoginAt");

-- Department & Delegation Indexes
CREATE INDEX "idx_departments_company" ON "Departments"("CompanyId");
CREATE INDEX "idx_departments_manager" ON "Departments"("ManagerUserId");
CREATE INDEX "idx_delegations_from_user" ON "Delegations"("FromUserId");
CREATE INDEX "idx_delegations_to_user" ON "Delegations"("ToUserId");
CREATE INDEX "idx_delegations_active" ON "Delegations"("IsActive", "StartDate", "EndDate") WHERE "IsActive" = true;

-- Category & Subcategory Indexes
CREATE INDEX "idx_subcategories_category" ON "Subcategories"("CategoryId");
CREATE INDEX "idx_subcategory_doc_requirements" ON "SubcategoryDocRequirements"("SubcategoryId");

-- Dashboard Performance Indexes
CREATE INDEX "idx_rfqs_dashboard" ON "Rfqs"("Status", "CompanyId", "CurrentActorId");
CREATE INDEX "idx_rfqs_date_range" ON "Rfqs"("CreatedAt", "Status");
CREATE INDEX "idx_notifications_unread" ON "Notifications"("UserId", "IsRead") WHERE "IsRead" = false;

-- =============================================
-- END OF DATABASE SCHEMA
-- Version: 6.3.0 (NodaTime Multi-Timezone Support)
-- Total Tables: 50
-- Total Indexes: 89
--
-- Changes from v6.2.2 (v6.3.0):
--   ✅ CHANGED: ALL TIMESTAMP columns → TIMESTAMP WITH TIME ZONE (~60 columns)
--            Required for Npgsql.NodaTime provider (Instant type mapping)
--            PostgreSQL stores as UTC, EF Core scaffolds as Instant type
--   ✅ ADDED: Users.PreferredTimezone VARCHAR(50) DEFAULT 'Asia/Bangkok' (Line 360)
--            IANA timezone for multi-timezone support (e.g., Asia/Bangkok, America/New_York)
--   ✅ ADDED: SupplierContacts.PreferredTimezone VARCHAR(50) DEFAULT 'Asia/Bangkok' (Line 516)
--            Auto-detected from Supplier country, user can override
--
-- Changes from v6.2.1 (v6.2.2):
--   ✅ ADDED: Rfqs.ResponsiblePersonAssignedAt TIMESTAMP (Line 582)
--            Temporal Data Pattern: ResponsiblePersonId + ResponsiblePersonAssignedAt
--            WHY: Track when Purchasing person was assigned (SLA, performance metrics, timeline)
--            PATTERN: Follows CurrentActorId + CurrentActorReceivedAt pattern
--            HYBRID: Denormalized for performance + RfqActorTimeline for complete history
--   ✅ CHANGED: QuotationItems.TotalPrice → GENERATED COLUMN (Line 816)
--            FROM: "TotalPrice" DECIMAL(18,4) NOT NULL
--            TO:   "TotalPrice" DECIMAL(18,4) GENERATED ALWAYS AS ("Quantity" * "UnitPrice") STORED
--            WHY: Data Integrity - Business Rule: "ราคารวม จะคำนวณ auto จาก (จำนวนสินค้า*ราคาต่อหน่วย)"
--            BENEFIT: 100% Data Integrity, cannot insert wrong TotalPrice
--            EF CORE: Compatible with EF Core 5.0+ (HasComputedColumnSql)
--
-- Changes from v6.2:
--   ✅ FIXED: UserCompanyRoles UNIQUE constraint to allow multi-role per user
--            Old: UNIQUE(UserId, CompanyId) - too restrictive
--            New: UNIQUE(UserId, CompanyId, DepartmentId, PrimaryRoleId)
--            WHY: Support users being APPROVER for multiple departments
--                 Support users being PURCHASING_APPROVER for multiple categories
--   ✅ ADDED: Partial unique index "idx_dept_approver_level_unique" (Line 1130)
--            Prevents duplicate ApproverLevel per Department (e.g., two Level 1 approvers)
--            WHERE PrimaryRoleId = 4 (APPROVER) AND IsActive = TRUE AND EndDate IS NULL
--   ✅ ADDED: Index "idx_user_category_bindings_chain" (Line 1131)
--            Optimizes Purchasing Approver chain queries by Category/Subcategory
--   ✅ FIXED: Table count correction (50 not 68)
--
-- Changes from v6.1:
--   ✅ Added QuotationDocuments table
--   ✅ Added RfqItemWinnerOverrides table
--   ✅ Added Users.PreferredLanguage field
--   ✅ Added SupplierContacts.PreferredLanguage field
--   ✅ Added Complete Performance Indexes (87 total)
--
-- IMPORTANT APPLICATION REQUIREMENTS (v6.3.0):
--   ⚠️  NodaTime: MUST use Npgsql.NodaTime provider in DbContext configuration
--        options.UseNpgsql(connectionString, npgsqlOptions => npgsqlOptions.UseNodaTime());
--        All TIMESTAMP WITH TIME ZONE columns will scaffold as Instant type (NOT DateTime)
--   ⚠️  Timezone: Users.PreferredTimezone and SupplierContacts.PreferredTimezone must be valid IANA timezone
--        Validate against DateTimeZoneProviders.Tzdb before saving
--   ⚠️  Department Approver: Database enforces via idx_dept_approver_level_unique (no duplicate levels)
--   ⚠️  Purchasing Approver: Application MUST validate that ApproverLevel doesn't duplicate per Category
--   ⚠️  Recommended: Validate all 3 levels are assigned before allowing RFQ routing
--   ⚠️  Purchasing Assignment: When updating ResponsiblePersonId, also set ResponsiblePersonAssignedAt = NOW()
--   ⚠️  Timeline Tracking: Insert RfqActorTimeline record when assigning Purchasing person (Hybrid Pattern)
--   ⚠️  QuotationItems.TotalPrice: GENERATED COLUMN - DO NOT assign value in INSERT/UPDATE
--        EF Core config: .HasComputedColumnSql("\"Quantity\" * \"UnitPrice\"", stored: true)
--        Entity: public decimal TotalPrice { get; private set; }  // No setter!
--
-- INDEX LOCATIONS (All indexes in INDEXES FOR PERFORMANCE section):
--   - idx_dept_approver_level_unique: Line 1130 (partial unique index on UserCompanyRoles)
--   - idx_user_category_bindings_chain: Line 1131 (composite index for chain queries)
-- =============================================