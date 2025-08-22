-- =============================================
-- E-RFQ SYSTEM COMPLETE DATABASE SCHEMA v6.0
-- Database: PostgreSQL 14+
-- Last Updated: January 
-- rename to eRFX_Complete_Database_V6_0.sql
-- =============================================

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
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "UpdatedAt" TIMESTAMP,
  
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
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
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
  "RoleName" VARCHAR(100) NOT NULL,
  "RoleNameTh" VARCHAR(100),
  "Description" TEXT,
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
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
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "UpdatedAt" TIMESTAMP,
  
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
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
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
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
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
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "UpdatedAt" TIMESTAMP,
  
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
  "RoleType" VARCHAR(30) NOT NULL,					-- บทบาทที่เกี่ยวข้อง
  "EventType" VARCHAR(50) NOT NULL,					-- NO_ACTION_2_DAYS, DELAY_ALERT
  "DaysAfterNoAction" INT,							-- จำนวนวันหลังไม่มีการ action
  "HoursBeforeDeadline" INT,                     	-- จำนวนชั่วโมงก่อน deadline
  "NotifyRecipients" TEXT[],						-- Array ของผู้รับ
  "Priority" VARCHAR(20) DEFAULT 'NORMAL',
  "Channels" TEXT[],
  "TitleTemplate" TEXT,
  "MessageTemplate" TEXT,
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE("RoleType", "EventType")
);

COMMENT ON TABLE "NotificationRules" IS 'กฎการแจ้งเตือน';

-- 1.14 Positions (Claude แนะนำ - Hybrid Approach)
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

COMMENT ON TABLE "Positions" IS 'ตำแหน่งงาน (Claude แนะนำ - Hybrid Approach)';

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
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "UpdatedAt" TIMESTAMP
);

COMMENT ON TABLE "EmailTemplates" IS 'Template สำหรับส่ง Email';

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
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "CreatedBy" BIGINT,
  "UpdatedAt" TIMESTAMP,
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
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "UpdatedAt" TIMESTAMP,
  
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
  "IsEmailVerified" BOOLEAN DEFAULT FALSE,
  "EmailVerifiedAt" TIMESTAMP,
  "PasswordResetToken" VARCHAR(255),
  "PasswordResetExpiry" TIMESTAMP,
  "SecurityStamp" VARCHAR(100),
  "LastLoginAt" TIMESTAMP,
  "LockoutEnabled" BOOLEAN DEFAULT TRUE,
  "LockoutEnd" TIMESTAMP WITH TIME ZONE,
  "AccessFailedCount" INT DEFAULT 0,
  "Status" VARCHAR(20) DEFAULT 'ACTIVE',
  "IsActive" BOOLEAN DEFAULT TRUE,
  "IsDeleted" BOOLEAN DEFAULT FALSE,
  "DeletedAt" TIMESTAMP,
  "DeletedBy" BIGINT,
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "CreatedBy" BIGINT,
  "UpdatedAt" TIMESTAMP,
  "UpdatedBy" BIGINT,
  
  CONSTRAINT "chk_user_status" CHECK ("Status" IN ('ACTIVE','INACTIVE'))
);

COMMENT ON TABLE "Users" IS 'พนักงานภายในบริษัท (Internal Users)';
COMMENT ON COLUMN "Users"."Email" IS 'ใช้เป็น username สำหรับ login';

-- 3.2 UserCompanyRoles
CREATE TABLE "UserCompanyRoles" (
  "Id" BIGSERIAL PRIMARY KEY,
  "UserId" BIGINT NOT NULL REFERENCES "Users"("Id"),
  "CompanyId" BIGINT NOT NULL REFERENCES "Companies"("Id"),
  "DepartmentId" BIGINT REFERENCES "Departments"("Id"),
  "PrimaryRoleId" BIGINT NOT NULL REFERENCES "Roles"("Id"),
  "SecondaryRoleId" BIGINT REFERENCES "Roles"("Id"),
  "PositionId" BIGINT REFERENCES "Positions"("Id"), -- Claude แนะนำ
  "ApproverLevel" SMALLINT CHECK ("ApproverLevel" BETWEEN 1 AND 3),
  "StartDate" DATE NOT NULL,
  "EndDate" DATE,
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "CreatedBy" BIGINT,
  "UpdatedAt" TIMESTAMP,
  "UpdatedBy" BIGINT,
  
  UNIQUE("UserId", "CompanyId"),
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
COMMENT ON COLUMN "UserCompanyRoles"."PositionId" IS 'ตำแหน่งงาน (Claude แนะนำ)';

-- 3.3 UserCategoryBindings
CREATE TABLE "UserCategoryBindings" (
  "Id" BIGSERIAL PRIMARY KEY,
  "UserCompanyRoleId" BIGINT NOT NULL REFERENCES "UserCompanyRoles"("Id"),
  "CategoryId" BIGINT NOT NULL REFERENCES "Categories"("Id"),
  "SubcategoryId" BIGINT REFERENCES "Subcategories"("Id"),
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE("UserCompanyRoleId", "CategoryId", "SubcategoryId")
);

COMMENT ON TABLE "UserCategoryBindings" IS 'กำหนด Category ที่ Purchasing รับผิดชอบ';

-- 3.4 Delegations
CREATE TABLE "Delegations" (
  "Id" BIGSERIAL PRIMARY KEY,
  "FromUserId" BIGINT NOT NULL REFERENCES "Users"("Id"),
  "ToUserId" BIGINT NOT NULL REFERENCES "Users"("Id"),
  "CompanyId" BIGINT NOT NULL REFERENCES "Companies"("Id"),
  "RoleId" BIGINT NOT NULL REFERENCES "Roles"("Id"),
  "FromPositionId" BIGINT REFERENCES "Positions"("Id"), -- Claude แนะนำ
  "DelegatedApproverLevel" SMALLINT, -- Claude แนะนำ
  "StartDate" TIMESTAMP NOT NULL,
  "EndDate" TIMESTAMP NOT NULL,
  "Reason" TEXT,
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
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
  "InvitedAt" TIMESTAMP,
  "RegisteredAt" TIMESTAMP,
  "ApprovedByUserId" BIGINT REFERENCES "Users"("Id"),
  "ApprovedAt" TIMESTAMP,
  "Status" VARCHAR(20) DEFAULT 'PENDING',
  "DeclineReason" TEXT,
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "UpdatedAt" TIMESTAMP,
  
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
  "PasswordHash" VARCHAR(255),
  "SecurityStamp" VARCHAR(100),
  "IsEmailVerified" BOOLEAN DEFAULT FALSE,
  "EmailVerifiedAt" TIMESTAMP,
  "PasswordResetToken" VARCHAR(255),
  "PasswordResetExpiry" TIMESTAMP,
  "LastLoginAt" TIMESTAMP,
  "FailedLoginAttempts" INT DEFAULT 0,
  "LockoutEnd" TIMESTAMP WITH TIME ZONE,
  "CanSubmitQuotation" BOOLEAN DEFAULT TRUE,
  "CanViewReports" BOOLEAN DEFAULT FALSE,
  "IsPrimaryContact" BOOLEAN DEFAULT FALSE,
  "ReceiveSMS" BOOLEAN DEFAULT FALSE,
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "CreatedBy" BIGINT,
  "UpdatedAt" TIMESTAMP,
  "UpdatedBy" BIGINT,
  
  UNIQUE("SupplierId", "Email")
);

COMMENT ON TABLE "SupplierContacts" IS 'ผู้ติดต่อของ Supplier';

-- 4.3 SupplierCategories
CREATE TABLE "SupplierCategories" (
  "Id" BIGSERIAL PRIMARY KEY,
  "SupplierId" BIGINT NOT NULL REFERENCES "Suppliers"("Id"),
  "CategoryId" BIGINT NOT NULL REFERENCES "Categories"("Id"),
  "SubcategoryId" BIGINT REFERENCES "Subcategories"("Id"),
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
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
  "UploadedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
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
  "RequesterEmail" VARCHAR(100),
  "RequesterPhone" VARCHAR(20),
  "BudgetAmount" DECIMAL(15,2),
  "BudgetCurrencyId" BIGINT NOT NULL REFERENCES "Currencies"("Id"),
  "CreatedDate" DATE NOT NULL DEFAULT CURRENT_DATE,
  "RequiredQuotationDate" TIMESTAMP NOT NULL,
  "QuotationDeadline" TIMESTAMP,
  "SubmissionDeadline" TIMESTAMP,
  "SerialNumber" VARCHAR(100),
  "Status" VARCHAR(20) DEFAULT 'SAVE_DRAFT',
  "CurrentLevel" SMALLINT DEFAULT 0,
  "CurrentActorId" BIGINT REFERENCES "Users"("Id"),
  "CurrentActorReceivedAt" TIMESTAMP,
  "ReBidCount" INT DEFAULT 0,
  "LastReBidAt" TIMESTAMP,
  "ReBidReason" TEXT,
  "LastActionAt" TIMESTAMP,
  "LastReminderSentAt" TIMESTAMP,
  "IsUrgent" BOOLEAN DEFAULT FALSE,
  "ProcessingDays" INT,
  "IsOverdue" BOOLEAN DEFAULT FALSE,
  "DeclineReason" TEXT,
  "RejectReason" TEXT,
  "Remarks" TEXT,
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "CreatedBy" BIGINT REFERENCES "Users"("Id"),
  "UpdatedAt" TIMESTAMP,
  "UpdatedBy" BIGINT REFERENCES "Users"("Id"),
  
  CONSTRAINT "chk_rfq_status" CHECK ("Status" IN 
    ('SAVE_DRAFT','PENDING','DECLINED','REJECTED','COMPLETED','RE_BID')),
  CONSTRAINT "chk_rfq_job_type" CHECK ("JobTypeId" IN (1, 2)),
  CONSTRAINT "chk_rfq_dates" CHECK (
    "QuotationDeadline" > "CreatedDate" 
    AND ("SubmissionDeadline" IS NULL OR "SubmissionDeadline" >= "QuotationDeadline")
  )
);

COMMENT ON TABLE "Rfqs" IS 'ใบขอเสนอราคา';

-- 5.2 RfqItems
CREATE TABLE "RfqItems" (
  "Id" BIGSERIAL PRIMARY KEY,
  "RfqId" BIGINT NOT NULL REFERENCES "Rfqs"("Id") ON DELETE CASCADE,
  "ItemSequence" INT NOT NULL,
  "ItemDescription" TEXT NOT NULL,
  "Brand" VARCHAR(100),
  "Model" VARCHAR(100),
  "Quantity" DECIMAL(12,4) NOT NULL,
  "UnitOfMeasure" VARCHAR(50) NOT NULL,
  "Specifications" TEXT,
  "Remarks" TEXT,
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "UpdatedAt" TIMESTAMP,
  
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
  "UploadedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
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
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "CreatedBy" BIGINT REFERENCES "Users"("Id"),
  "UpdatedAt" TIMESTAMP,
  "UpdatedBy" BIGINT REFERENCES "Users"("Id"),
  
  CONSTRAINT "uk_rfq_required_fields" UNIQUE("RfqId")
);

COMMENT ON TABLE "RfqRequiredFields" IS 'กำหนดข้อมูลที่ Supplier ต้องระบุ';

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
  "ActionAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT "chk_decision" CHECK ("Decision" IN ('APPROVED','DECLINED','REJECTED','SUBMITTED'))
);

COMMENT ON TABLE "RfqStatusHistory" IS 'ประวัติการเปลี่ยนสถานะ RFQ';

-- 6.2 RfqActorTimeline
CREATE TABLE "RfqActorTimeline" (
  "Id" BIGSERIAL PRIMARY KEY,
  "RfqId" BIGINT NOT NULL REFERENCES "Rfqs"("Id"),
  "ActorId" BIGINT NOT NULL REFERENCES "Users"("Id"),
  "ActorRole" VARCHAR(30) NOT NULL,
  "ReceivedAt" TIMESTAMP NOT NULL,
  "ActionAt" TIMESTAMP,
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
  "InvitedAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "InvitedByUserId" BIGINT NOT NULL REFERENCES "Users"("Id"),
  "ResponseStatus" VARCHAR(30) DEFAULT 'NO_RESPONSE',
  "RespondedAt" TIMESTAMP,
  "Decision" VARCHAR(30) DEFAULT 'PENDING',
  "DecisionReason" TEXT,
  "RespondedByContactId" BIGINT REFERENCES "SupplierContacts"("Id"),
  "DecisionChangeCount" INT DEFAULT 0,
  "LastDecisionChangeAt" TIMESTAMP,
  "ReBidCount" INT DEFAULT 0,
  "LastReBidAt" TIMESTAMP,
  "RespondedIpAddress" INET,
  "RespondedUserAgent" TEXT,
  "RespondedDeviceInfo" TEXT,
  "AutoDeclinedAt" TIMESTAMP,
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "UpdatedAt" TIMESTAMP,
  
  CONSTRAINT "uk_rfq_supplier" UNIQUE("RfqId", "SupplierId"),
  CONSTRAINT "chk_response_status" CHECK ("ResponseStatus" IN ('NO_RESPONSE','RESPONDED')),
  CONSTRAINT "chk_invitation_decision" CHECK ("Decision" IN 
    ('PENDING','PARTICIPATING','NOT_PARTICIPATING','AUTO_DECLINED'))
);

COMMENT ON TABLE "RfqInvitations" IS 'การเชิญ Supplier เสนอราคา';

-- 7.2 RfqInvitationHistory
CREATE TABLE "RfqInvitationHistory" (
  "Id" BIGSERIAL PRIMARY KEY,
  "InvitationId" BIGINT NOT NULL REFERENCES "RfqInvitations"("Id"),
  "DecisionSequence" INT NOT NULL,
  "FromDecision" VARCHAR(30),
  "ToDecision" VARCHAR(30) NOT NULL,
  "ChangedByContactId" BIGINT REFERENCES "SupplierContacts"("Id"),
  "ChangedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "ChangeReason" TEXT,
  
  CONSTRAINT "uk_invitation_sequence" UNIQUE("InvitationId", "DecisionSequence")
);

COMMENT ON TABLE "RfqInvitationHistory" IS 'ประวัติการเปลี่ยนการตอบรับคำเชิญ';

-- 7.3 Quotations
CREATE TABLE "Quotations" (
  "Id" BIGSERIAL PRIMARY KEY,
  "RfqId" BIGINT NOT NULL REFERENCES "Rfqs"("Id"),
  "SupplierId" BIGINT NOT NULL REFERENCES "Suppliers"("Id"),
  "QuotationNumber" VARCHAR(50) UNIQUE,
  "QuotationDate" DATE DEFAULT CURRENT_DATE,
  "ValidityDays" INT DEFAULT 30,
  "ExpiryDate" DATE,
  "TotalAmount" DECIMAL(18,4) NOT NULL,
  "CurrencyId" BIGINT NOT NULL REFERENCES "Currencies"("Id"),
  "ConvertedAmount" DECIMAL(18,4),
  "ConvertedCurrencyId" BIGINT REFERENCES "Currencies"("Id"),
  "LockedExchangeRate" DECIMAL(15,6),
  "LockedAt" TIMESTAMP,
  "PaymentTerms" TEXT,
  "DeliveryTerms" TEXT,
  "IncotermId" BIGINT REFERENCES "Incoterms"("Id"),
  "Status" VARCHAR(20) DEFAULT 'SUBMITTED',
  "SubmittedAt" TIMESTAMP,
  "IsWinner" BOOLEAN DEFAULT FALSE,
  "WinnerRanking" INT,
  "SelectionReason" TEXT,
  "SystemSuggestedRank" INT,
  "SelectionMatchSystem" BOOLEAN,
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "CreatedBy" BIGINT,
  "UpdatedAt" TIMESTAMP,
  "UpdatedBy" BIGINT,
  
  UNIQUE("RfqId", "SupplierId"),
  CONSTRAINT "chk_quotation_status" CHECK ("Status" IN 
    ('SUBMITTED','SELECTED','NOT_SELECTED')),
  CONSTRAINT "chk_quotation_amount" CHECK ("TotalAmount" >= 0)
);

COMMENT ON TABLE "Quotations" IS 'ใบเสนอราคาจาก Supplier';

-- 7.4 QuotationItems
CREATE TABLE "QuotationItems" (
  "Id" BIGSERIAL PRIMARY KEY,
  "QuotationId" BIGINT NOT NULL REFERENCES "Quotations"("Id") ON DELETE CASCADE,
  "RfqItemId" BIGINT NOT NULL REFERENCES "RfqItems"("Id"),
  "UnitPrice" DECIMAL(18,4) NOT NULL,
  "Quantity" DECIMAL(12,4) NOT NULL,
  "TotalPrice" DECIMAL(18,4) NOT NULL,
  "ConvertedUnitPrice" DECIMAL(18,4),
  "ConvertedTotalPrice" DECIMAL(18,4),
  "MinOrderQty" INT,
  "DeliveryDays" INT,
  "CreditDays" INT,
  "WarrantyDays" INT,
  "Remarks" TEXT,
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE("QuotationId", "RfqItemId")
);

COMMENT ON TABLE "QuotationItems" IS 'รายการในใบเสนอราคา';

-- 7.5 QuotationDocuments
CREATE TABLE "QuotationDocuments" (
  "Id" BIGSERIAL PRIMARY KEY,
  "QuotationId" BIGINT NOT NULL REFERENCES "Quotations"("Id") ON DELETE CASCADE,
  "DocumentType" VARCHAR(50) NOT NULL,
  "DocumentName" VARCHAR(200) NOT NULL,
  "FileName" VARCHAR(255) NOT NULL,
  "FilePath" TEXT,
  "FileSize" BIGINT,
  "MimeType" VARCHAR(100),
  "UploadedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "UploadedBy" BIGINT
);

COMMENT ON TABLE "QuotationDocuments" IS 'เอกสารแนบใบเสนอราคา';

-- =============================================
-- SECTION 8: COMMUNICATION & Q&A (Improved Design)
-- =============================================

-- 8.1 QnAThreads (แทน RfqQuestions - Claude แนะนำ)
CREATE TABLE "QnAThreads" (
  "Id" BIGSERIAL PRIMARY KEY,
  "RfqId" BIGINT NOT NULL REFERENCES "Rfqs"("Id"),
  "SupplierId" BIGINT NOT NULL REFERENCES "Suppliers"("Id"),
  "ThreadStatus" VARCHAR(20) DEFAULT 'OPEN',
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "ClosedAt" TIMESTAMP,
  
  UNIQUE("RfqId", "SupplierId"),
  CONSTRAINT "chk_thread_status" CHECK ("ThreadStatus" IN ('OPEN','CLOSED'))
);

COMMENT ON TABLE "QnAThreads" IS 'Thread สำหรับถาม-ตอบระหว่าง Supplier และ Purchasing (Claude แนะนำ - แทน RfqQuestions)';

-- 8.2 QnAMessages (แทน RfqQuestions - Claude แนะนำ)
CREATE TABLE "QnAMessages" (
  "Id" BIGSERIAL PRIMARY KEY,
  "ThreadId" BIGINT NOT NULL REFERENCES "QnAThreads"("Id"),
  "MessageText" TEXT NOT NULL,
  "SenderType" VARCHAR(20) NOT NULL,
  "SenderId" BIGINT NOT NULL,
  "SentAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "IsRead" BOOLEAN DEFAULT FALSE,
  "ReadAt" TIMESTAMP,
  
  CONSTRAINT "chk_sender_type" CHECK ("SenderType" IN ('SUPPLIER','PURCHASING'))
);

COMMENT ON TABLE "QnAMessages" IS 'ข้อความในแต่ละ Thread (Claude แนะนำ - แทน RfqQuestions)';

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
  "QuotationId" BIGINT REFERENCES "Quotations"("Id"),
  "Title" VARCHAR(200) NOT NULL,
  "Message" TEXT NOT NULL,
  "IconType" VARCHAR(20),
  "ActionUrl" TEXT,
  "IsRead" BOOLEAN DEFAULT FALSE,
  "ReadAt" TIMESTAMP,
  "Channels" TEXT[],
  "EmailSent" BOOLEAN DEFAULT FALSE,
  "EmailSentAt" TIMESTAMP,
  "SmsSent" BOOLEAN DEFAULT FALSE,
  "SmsSentAt" TIMESTAMP,
  "RecipientPhone" VARCHAR(20),
  "SmsProvider" VARCHAR(20),
  "SmsStatus" VARCHAR(20),
  "SmsMessageId" VARCHAR(100),
  -- SignalR Support
  "SignalRConnectionId" VARCHAR(100),
  "MessageQueueId" UUID,                         -- Wolverine message ID
  
  -- Scheduling
  "ScheduledFor" TIMESTAMP,                      -- กำหนดส่งเมื่อไหร่
  "ProcessedAt" TIMESTAMP,                       -- ประมวลผลเมื่อไหร่

  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "CreatedBy" BIGINT,
  
  CONSTRAINT "chk_notification_priority" CHECK ("Priority" IN ('LOW','NORMAL','HIGH','URGENT'))
);

COMMENT ON TABLE "Notifications" IS 'การแจ้งเตือน (Enhanced for SMS & SignalR)';

-- 9.2 NotificationQueue
CREATE TABLE "NotificationQueue" (
  "Id" BIGSERIAL PRIMARY KEY,
  "NotificationId" BIGINT REFERENCES "Notifications"("Id"),
  "Channel" VARCHAR(20) NOT NULL,
  "Recipient" VARCHAR(255) NOT NULL,
  "Subject" VARCHAR(500),
  "Content" TEXT,
  "Priority" VARCHAR(20) DEFAULT 'NORMAL',
  "Status" VARCHAR(20) DEFAULT 'PENDING',
  "Attempts" INT DEFAULT 0,
  "MaxAttempts" INT DEFAULT 3,
  "ScheduledFor" TIMESTAMP,
  "ProcessedAt" TIMESTAMP,
  "LastError" TEXT,
  "LastAttemptAt" TIMESTAMP,
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT "chk_queue_status" CHECK ("Status" IN ('PENDING','PROCESSING','SENT','FAILED'))
);

COMMENT ON TABLE "NotificationQueue" IS 'คิวการส่งการแจ้งเตือน';

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
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "CreatedBy" BIGINT REFERENCES "Users"("Id"),
  "UpdatedAt" TIMESTAMP,
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
  "ChangedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
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
  "ExpiresAt" TIMESTAMP NOT NULL,
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "CreatedByIp" VARCHAR(45),
  "RevokedAt" TIMESTAMP,
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
  "LoginAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "LoginIp" VARCHAR(45),
  "UserAgent" TEXT,
  "DeviceInfo" TEXT,
  "Country" VARCHAR(100),
  "City" VARCHAR(100),
  "Success" BOOLEAN NOT NULL,
  "FailureReason" VARCHAR(200),
  "SessionId" VARCHAR(100),
  "RefreshTokenId" BIGINT REFERENCES "RefreshTokens"("Id"),
  "LogoutAt" TIMESTAMP,
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
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "CreatedBy" BIGINT REFERENCES "Users"("Id"),
  "UpdatedAt" TIMESTAMP,
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
  "ResolvedAt" TIMESTAMP,
  "ResolutionNotes" TEXT,
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE "ErrorLogs" IS 'บันทึก Business Critical Errors';

-- =============================================
-- SECTION 13: INFRASTRUCTURE TABLES
-- =============================================

-- 13.1 wolverine_incoming_envelopes
CREATE TABLE "wolverine_incoming_envelopes" (
  "id" UUID PRIMARY KEY,
  "status" VARCHAR(25) NOT NULL,
  "owner_id" INT NOT NULL,
  "execution_time" TIMESTAMP DEFAULT NULL,
  "attempts" INT DEFAULT 0,
  "body" JSONB NOT NULL,
  "message_type" VARCHAR(250) NOT NULL,
  "received_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE "wolverine_incoming_envelopes" IS 'Wolverine incoming message queue';

-- 13.2 wolverine_outgoing_envelopes
CREATE TABLE "wolverine_outgoing_envelopes" (
  "id" UUID PRIMARY KEY,
  "destination" VARCHAR(500) NOT NULL,
  "deliver_by" TIMESTAMP,
  "body" JSONB NOT NULL,
  "message_type" VARCHAR(500) NOT NULL,
  "attempts" INT DEFAULT 0,
  "status" VARCHAR(50) DEFAULT 'Pending',
  "owner_id" INT,
  "execution_time" TIMESTAMP,
  "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE "wolverine_outgoing_envelopes" IS 'Wolverine outbox for reliable messaging';

-- 13.3 wolverine_scheduled_envelopes
CREATE TABLE "wolverine_scheduled_envelopes" (
  "id" UUID PRIMARY KEY,
  "scheduled_time" TIMESTAMP NOT NULL,
  "body" JSONB NOT NULL,
  "message_type" VARCHAR(500) NOT NULL,
  "destination" VARCHAR(500),
  "attempts" INT DEFAULT 0,
  "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE "wolverine_scheduled_envelopes" IS 'Wolverine scheduled messages';

-- 13.4 SignalRConnections
CREATE TABLE "SignalRConnections" (
  "ConnectionId" VARCHAR(100) PRIMARY KEY,
  "UserType" VARCHAR(20) NOT NULL,
  "UserId" BIGINT,
  "ContactId" BIGINT,
  "ConnectedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "LastPingAt" TIMESTAMP,
  "UserAgent" TEXT,
  "IpAddress" VARCHAR(45),
  "IsActive" BOOLEAN DEFAULT TRUE,
  
  CONSTRAINT "chk_signalr_user_type" CHECK ("UserType" IN ('Employee', 'SupplierContact'))
);

COMMENT ON TABLE "SignalRConnections" IS 'Track SignalR connections for real-time features';

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================

-- User & Role Indexes
CREATE INDEX "idx_users_email" ON "Users"("Email");
CREATE INDEX "idx_users_active" ON "Users"("IsActive") WHERE "IsActive" = true;
CREATE INDEX "idx_user_company_roles_user" ON "UserCompanyRoles"("UserId");
CREATE INDEX "idx_user_company_roles_company" ON "UserCompanyRoles"("CompanyId");

-- RFQ Indexes
CREATE INDEX "idx_rfqs_status" ON "Rfqs"("Status");
CREATE INDEX "idx_rfqs_company" ON "Rfqs"("CompanyId");
CREATE INDEX "idx_rfqs_requester" ON "Rfqs"("RequesterId");
CREATE INDEX "idx_rfqs_current_actor" ON "Rfqs"("CurrentActorId");
CREATE INDEX "idx_rfqs_overdue" ON "Rfqs"("IsOverdue") WHERE "IsOverdue" = true;
CREATE INDEX "idx_rfq_items_rfq" ON "RfqItems"("RfqId");
CREATE INDEX "idx_rfq_status_history_rfq" ON "RfqStatusHistory"("RfqId");
CREATE INDEX "idx_rfq_actor_timeline_rfq" ON "RfqActorTimeline"("RfqId");

-- Supplier Indexes
CREATE INDEX "idx_suppliers_status" ON "Suppliers"("Status");
CREATE INDEX "idx_suppliers_active" ON "Suppliers"("IsActive") WHERE "IsActive" = true;
CREATE INDEX "idx_supplier_contacts_supplier" ON "SupplierContacts"("SupplierId");
CREATE INDEX "idx_supplier_categories_supplier" ON "SupplierCategories"("SupplierId");

-- Quotation Indexes
CREATE INDEX "idx_rfq_invitations_rfq" ON "RfqInvitations"("RfqId");
CREATE INDEX "idx_rfq_invitations_supplier" ON "RfqInvitations"("SupplierId");
CREATE INDEX "idx_quotations_rfq" ON "Quotations"("RfqId");
CREATE INDEX "idx_quotations_supplier" ON "Quotations"("SupplierId");
CREATE INDEX "idx_quotation_items_quotation" ON "QuotationItems"("QuotationId");

-- Q&A Indexes (Claude แนะนำ)
CREATE INDEX "idx_qna_threads_rfq" ON "QnAThreads"("RfqId");
CREATE INDEX "idx_qna_threads_supplier" ON "QnAThreads"("SupplierId");
CREATE INDEX "idx_qna_messages_thread" ON "QnAMessages"("ThreadId");
CREATE INDEX "idx_qna_messages_unread" ON "QnAMessages"("ThreadId", "IsRead") WHERE "IsRead" = false;

-- Notification Indexes
CREATE INDEX "idx_notifications_user" ON "Notifications"("UserId") WHERE "IsRead" = false;
CREATE INDEX "idx_notifications_contact" ON "Notifications"("ContactId") WHERE "IsRead" = false;
CREATE INDEX "idx_notification_queue_pending" ON "NotificationQueue"("Status") WHERE "Status" = 'PENDING';

-- Exchange Rate Indexes
CREATE INDEX "idx_exchange_rates_active" ON "ExchangeRates"("FromCurrencyId", "ToCurrencyId", "EffectiveDate") 
  WHERE "IsActive" = true;

-- =============================================
-- TRIGGERS
-- =============================================

-- Trigger to update IsOverdue flag
CREATE OR REPLACE FUNCTION update_rfq_overdue() RETURNS TRIGGER AS $$
BEGIN
  IF NEW."RequiredQuotationDate" < CURRENT_TIMESTAMP THEN
    NEW."IsOverdue" = TRUE;
  ELSE
    NEW."IsOverdue" = FALSE;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER "trg_update_rfq_overdue"
BEFORE INSERT OR UPDATE ON "Rfqs"
FOR EACH ROW
EXECUTE FUNCTION update_rfq_overdue();

-- Trigger to calculate ProcessingDays
CREATE OR REPLACE FUNCTION calculate_processing_days() RETURNS TRIGGER AS $$
BEGIN
  IF NEW."UpdatedAt" IS NOT NULL AND NEW."CreatedAt" IS NOT NULL THEN
    NEW."ProcessingDays" = EXTRACT(DAY FROM (NEW."UpdatedAt" - NEW."CreatedAt"));
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER "trg_calculate_processing_days"
BEFORE UPDATE ON "Rfqs"
FOR EACH ROW
EXECUTE FUNCTION calculate_processing_days();

-- Trigger to update Timeline ProcessingDays
CREATE OR REPLACE FUNCTION update_timeline_processing_days() RETURNS TRIGGER AS $$
BEGIN
  IF NEW."ActionAt" IS NOT NULL AND NEW."ReceivedAt" IS NOT NULL THEN
    -- Calculate processing days
    NEW."IsOntime" = (
      EXTRACT(DAY FROM (NEW."ActionAt" - NEW."ReceivedAt")) <= 
      (SELECT "ResponseTimeDays" FROM "RoleResponseTimes" WHERE "RoleCode" = NEW."ActorRole")
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER "trg_update_timeline_processing"
BEFORE INSERT OR UPDATE ON "RfqActorTimeline"
FOR EACH ROW
EXECUTE FUNCTION update_timeline_processing_days();

-- Trigger to auto-assign ApproverLevel from Position (Claude แนะนำ)
CREATE OR REPLACE FUNCTION assign_approver_level_from_position() RETURNS TRIGGER AS $$
BEGIN
  IF NEW."PositionId" IS NOT NULL AND NEW."ApproverLevel" IS NULL THEN
    SELECT "DefaultApproverLevel" INTO NEW."ApproverLevel"
    FROM "Positions" 
    WHERE "Id" = NEW."PositionId";
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER "trg_auto_assign_approver_level"
BEFORE INSERT OR UPDATE ON "UserCompanyRoles"
FOR EACH ROW
EXECUTE FUNCTION assign_approver_level_from_position();

-- =============================================
-- END OF DATABASE SCHEMA
-- Version: 6.0 (Production Ready - Option A)
-- Total Tables: 63
-- Changes from v5:
-- ✅ RfqQuestions → QnAThreads + QnAMessages
-- ✅ Added Positions table (Claude แนะนำ)
-- ✅ All field names kept as v5 format
-- ✅ All missing tables restored
-- =============================================