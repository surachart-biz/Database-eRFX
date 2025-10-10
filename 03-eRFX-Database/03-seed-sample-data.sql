-- =============================================
-- E-RFQ SYSTEM SEED/SAMPLE DATA v6.4
-- Database: PostgreSQL 16+
-- Last Updated: 2025-10-07
-- Purpose: Non-transactional seed data for development and testing
--
-- IMPORTANT: This creates ONLY non-transactional data:
--   ✅ Companies, Departments, Users, Suppliers
--   ❌ RFQs, Quotations, Notifications (transactional - create via UI)
--
-- Run after:
--   1. 00-init-database.sql
--   2. erfq-db-schema-v64.sql
--   3. erfq-master-data-v64.sql
-- =============================================

\echo ''
\echo '=========================================='
\echo 'E-RFX Seed Data Script v6.4'
\echo '=========================================='
\echo ''
\echo 'Creating non-transactional sample data...'
\echo ''

-- =============================================
-- SECTION 1: COMPANIES (2 บริษัท)
-- =============================================

\echo '1. Creating Companies...'

INSERT INTO "Companies" (
  "CompanyCode", "CompanyNameTh", "CompanyNameEn", "ShortNameEn",
  "TaxId", "CountryId", "DefaultCurrencyId", "BusinessTypeId",
  "RegisteredCapital", "RegisteredCapitalCurrencyId", "FoundedDate",
  "AddressLine1", "AddressLine2", "City", "Province", "PostalCode",
  "Phone", "Fax", "Email", "Website", "Status", "IsActive"
) VALUES
-- Company 1: Thai Venture Co., Ltd.
(
  'TVC001',
  'บริษัท ไทยเวนเจอร์ จำกัด',
  'Thai Venture Co., Ltd.',
  'TVC',
  '0105558001234',
  (SELECT "Id" FROM "Countries" WHERE "CountryCode" = 'TH'),
  (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'THB'),
  2, -- JURISTIC
  10000000.00,
  (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'THB'),
  '2010-06-15',
  '123 ถนนสุขุมวิท',
  'แขวงคลองเตย',
  'กรุงเทพมหานคร',
  'กรุงเทพมหานคร',
  '10110',
  '+66-2-123-4567',
  '+66-2-123-4568',
  'info@thaiventure.co.th',
  'https://www.thaiventure.co.th',
  'ACTIVE',
  TRUE
),
-- Company 2: Asia Pacific Trading Ltd.
(
  'APT002',
  'บริษัท เอเชีย แปซิฟิค เทรดดิ้ง จำกัด',
  'Asia Pacific Trading Ltd.',
  'APT',
  '0105558009876',
  (SELECT "Id" FROM "Countries" WHERE "CountryCode" = 'TH'),
  (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'THB'),
  2, -- JURISTIC
  5000000.00,
  (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'THB'),
  '2015-03-20',
  '456 ถนนพระราม 4',
  'แขวงปทุมวัน',
  'กรุงเทพมหานคร',
  'กรุงเทพมหานคร',
  '10330',
  '+66-2-987-6543',
  '+66-2-987-6544',
  'contact@asiapacific.co.th',
  'https://www.asiapacific.co.th',
  'ACTIVE',
  TRUE
)
ON CONFLICT ("CompanyCode") DO NOTHING;

\echo '   ✓ Created 2 companies'
\echo ''

-- =============================================
-- SECTION 2: DEPARTMENTS (หลายแผนก)
-- =============================================

\echo '2. Creating Departments...'

-- Company 1 Departments
INSERT INTO "Departments" (
  "CompanyId", "DepartmentCode", "DepartmentNameTh", "DepartmentNameEn",
  "CostCenter", "IsActive"
) VALUES
-- TVC Departments
(
  (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'TVC001'),
  'IT', 'แผนกเทคโนโลยีสารสนเทศ', 'IT Department', 'CC-IT-001', TRUE
),
(
  (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'TVC001'),
  'HR', 'แผนกทรัพยากรบุคคล', 'Human Resources', 'CC-HR-001', TRUE
),
(
  (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'TVC001'),
  'FIN', 'แผนกการเงิน', 'Finance Department', 'CC-FIN-001', TRUE
),
(
  (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'TVC001'),
  'OPS', 'แผนกปฏิบัติการ', 'Operations', 'CC-OPS-001', TRUE
),
(
  (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'TVC001'),
  'PROC', 'แผนกจัดซื้อ', 'Procurement', 'CC-PROC-001', TRUE
),
-- APT Departments
(
  (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'APT002'),
  'SALES', 'แผนกขาย', 'Sales Department', 'CC-SALES-002', TRUE
),
(
  (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'APT002'),
  'MKT', 'แผนกการตลาด', 'Marketing', 'CC-MKT-002', TRUE
),
(
  (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'APT002'),
  'LOG', 'แผนกโลจิสติกส์', 'Logistics', 'CC-LOG-002', TRUE
),
(
  (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'APT002'),
  'PROC', 'แผนกจัดซื้อ', 'Procurement', 'CC-PROC-002', TRUE
)
ON CONFLICT ("CompanyId", "DepartmentCode") DO NOTHING;

\echo '   ✓ Created 9 departments (5 for TVC, 4 for APT)'
\echo ''

-- =============================================
-- SECTION 3: USERS (15 users ครบ 8 roles)
-- =============================================

\echo '3. Creating Users...'

-- Password: "Password123!" hashed with bcrypt
-- NOTE: Replace with actual password hash in production
INSERT INTO "Users" (
  "EmployeeCode", "Email", "PasswordHash",
  "FirstNameTh", "LastNameTh", "FirstNameEn", "LastNameEn",
  "PhoneNumber", "MobileNumber",
  "PreferredLanguage", "PreferredTimezone",
  "IsEmailVerified", "EmailVerifiedAt",
  "Status", "IsActive"
) VALUES
-- SUPER_ADMIN (1 person)
('SA001', 'superadmin@erfx.system', '$2a$11$LQKvFfZZvZxJxPxH.JzH4uVqhvZxME5lFYqZ0RLz7g8y4Z5PZJHKm',
 'ซุปเปอร์', 'แอดมิน', 'Super', 'Admin',
 '+66-2-000-0001', '+66-81-000-0001',
 'th', 'Asia/Bangkok', TRUE, CURRENT_TIMESTAMP, 'ACTIVE', TRUE),

-- ADMIN (1 person - TVC)
('EMP001', 'admin@thaiventure.co.th', '$2a$11$LQKvFfZZvZxJxPxH.JzH4uVqhvZxME5lFYqZ0RLz7g8y4Z5PZJHKm',
 'สมชาย', 'ใจดี', 'Somchai', 'Jaidee',
 '+66-2-123-4501', '+66-81-234-5001',
 'th', 'Asia/Bangkok', TRUE, CURRENT_TIMESTAMP, 'ACTIVE', TRUE),

-- REQUESTER (3 persons - different departments)
('EMP002', 'requester1@thaiventure.co.th', '$2a$11$LQKvFfZZvZxJxPxH.JzH4uVqhvZxME5lFYqZ0RLz7g8y4Z5PZJHKm',
 'สมหญิง', 'ขยัน', 'Somying', 'Khayan',
 '+66-2-123-4502', '+66-81-234-5002',
 'th', 'Asia/Bangkok', TRUE, CURRENT_TIMESTAMP, 'ACTIVE', TRUE),
('EMP003', 'requester2@thaiventure.co.th', '$2a$11$LQKvFfZZvZxJxPxH.JzH4uVqhvZxME5lFYqZ0RLz7g8y4Z5PZJHKm',
 'สมศักดิ์', 'มั่นคง', 'Somsak', 'Mankong',
 '+66-2-123-4503', '+66-81-234-5003',
 'th', 'Asia/Bangkok', TRUE, CURRENT_TIMESTAMP, 'ACTIVE', TRUE),
('EMP012', 'requester3@asiapacific.co.th', '$2a$11$LQKvFfZZvZxJxPxH.JzH4uVqhvZxME5lFYqZ0RLz7g8y4Z5PZJHKm',
 'นิภา', 'สว่างใจ', 'Nipa', 'Sawangjai',
 '+66-2-987-6501', '+66-82-345-6001',
 'th', 'Asia/Bangkok', TRUE, CURRENT_TIMESTAMP, 'ACTIVE', TRUE),

-- APPROVER (3 persons - 3 levels)
('EMP004', 'approver.l1@thaiventure.co.th', '$2a$11$LQKvFfZZvZxJxPxH.JzH4uVqhvZxME5lFYqZ0RLz7g8y4Z5PZJHKm',
 'วิชัย', 'เก่งการ', 'Wichai', 'Kengkan',
 '+66-2-123-4504', '+66-81-234-5004',
 'th', 'Asia/Bangkok', TRUE, CURRENT_TIMESTAMP, 'ACTIVE', TRUE),
('EMP005', 'approver.l2@thaiventure.co.th', '$2a$11$LQKvFfZZvZxJxPxH.JzH4uVqhvZxME5lFYqZ0RLz7g8y4Z5PZJHKm',
 'ประสิทธิ์', 'วิจารณ์', 'Prasit', 'Wicharn',
 '+66-2-123-4505', '+66-81-234-5005',
 'en', 'Asia/Bangkok', TRUE, CURRENT_TIMESTAMP, 'ACTIVE', TRUE),
('EMP006', 'approver.l3@thaiventure.co.th', '$2a$11$LQKvFfZZvZxJxPxH.JzH4uVqhvZxME5lFYqZ0RLz7g8y4Z5PZJHKm',
 'สุรศักดิ์', 'บริหาร', 'Surasak', 'Borihan',
 '+66-2-123-4506', '+66-81-234-5006',
 'th', 'Asia/Bangkok', TRUE, CURRENT_TIMESTAMP, 'ACTIVE', TRUE),

-- PURCHASING (3 persons - different categories)
('EMP007', 'purchasing1@thaiventure.co.th', '$2a$11$LQKvFfZZvZxJxPxH.JzH4uVqhvZxME5lFYqZ0RLz7g8y4Z5PZJHKm',
 'พัชรา', 'จัดซื้อ', 'Patchara', 'Jadsue',
 '+66-2-123-4507', '+66-81-234-5007',
 'th', 'Asia/Bangkok', TRUE, CURRENT_TIMESTAMP, 'ACTIVE', TRUE),
('EMP008', 'purchasing2@thaiventure.co.th', '$2a$11$LQKvFfZZvZxJxPxH.JzH4uVqhvZxME5lFYqZ0RLz7g8y4Z5PZJHKm',
 'ธนพล', 'เจรจา', 'Thanapol', 'Charocha',
 '+66-2-123-4508', '+66-81-234-5008',
 'th', 'Asia/Bangkok', TRUE, CURRENT_TIMESTAMP, 'ACTIVE', TRUE),
('EMP013', 'purchasing3@asiapacific.co.th', '$2a$11$LQKvFfZZvZxJxPxH.JzH4uVqhvZxME5lFYqZ0RLz7g8y4Z5PZJHKm',
 'กมล', 'จัดการ', 'Kamol', 'Jadkan',
 '+66-2-987-6502', '+66-82-345-6002',
 'th', 'Asia/Bangkok', TRUE, CURRENT_TIMESTAMP, 'ACTIVE', TRUE),

-- PURCHASING_APPROVER (2 persons - 2 levels)
('EMP009', 'purch.approver.l1@thaiventure.co.th', '$2a$11$LQKvFfZZvZxJxPxH.JzH4uVqhvZxME5lFYqZ0RLz7g8y4Z5PZJHKm',
 'สมบูรณ์', 'อนุมัติ', 'Somboon', 'Anumat',
 '+66-2-123-4509', '+66-81-234-5009',
 'th', 'Asia/Bangkok', TRUE, CURRENT_TIMESTAMP, 'ACTIVE', TRUE),
('EMP010', 'purch.approver.l2@thaiventure.co.th', '$2a$11$LQKvFfZZvZxJxPxH.JzH4uVqhvZxME5lFYqZ0RLz7g8y4Z5PZJHKm',
 'วิโรจน์', 'ตัดสินใจ', 'Wiroj', 'Tadsinjai',
 '+66-2-123-4510', '+66-81-234-5010',
 'en', 'Asia/Bangkok', TRUE, CURRENT_TIMESTAMP, 'ACTIVE', TRUE),

-- MANAGING_DIRECTOR (1 person)
('EMP011', 'md@thaiventure.co.th', '$2a$11$LQKvFfZZvZxJxPxH.JzH4uVqhvZxME5lFYqZ0RLz7g8y4Z5PZJHKm',
 'ชัยวัฒน์', 'ผู้นำ', 'Chaiwat', 'Phunnam',
 '+66-2-123-4511', '+66-81-234-5011',
 'th', 'Asia/Bangkok', TRUE, CURRENT_TIMESTAMP, 'ACTIVE', TRUE),

-- APT Admin
('EMP014', 'admin@asiapacific.co.th', '$2a$11$LQKvFfZZvZxJxPxH.JzH4uVqhvZxME5lFYqZ0RLz7g8y4Z5PZJHKm',
 'สุชาติ', 'ดูแล', 'Suchat', 'Doolae',
 '+66-2-987-6503', '+66-82-345-6003',
 'th', 'Asia/Bangkok', TRUE, CURRENT_TIMESTAMP, 'ACTIVE', TRUE)

ON CONFLICT ("Email") DO NOTHING;

\echo '   ✓ Created 15 users'
\echo ''

-- =============================================
-- SECTION 4: USER COMPANY ROLES
-- =============================================

\echo '4. Creating User Company Roles...'

INSERT INTO "UserCompanyRoles" (
  "UserId", "CompanyId", "DepartmentId", "PrimaryRoleId", "SecondaryRoleId",
  "PositionId", "ApproverLevel", "StartDate", "IsActive"
) VALUES
-- SUPER_ADMIN (cross-company, no department)
(
  (SELECT "Id" FROM "Users" WHERE "Email" = 'superadmin@erfx.system'),
  (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'TVC001'),
  NULL,
  (SELECT "Id" FROM "Roles" WHERE "RoleCode" = 'SUPER_ADMIN'),
  NULL,
  (SELECT "Id" FROM "Positions" WHERE "PositionCode" = 'CEO'),
  NULL,
  '2024-01-01',
  TRUE
),

-- TVC ADMIN
(
  (SELECT "Id" FROM "Users" WHERE "Email" = 'admin@thaiventure.co.th'),
  (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'TVC001'),
  (SELECT "Id" FROM "Departments" WHERE "CompanyId" = (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'TVC001') AND "DepartmentCode" = 'IT'),
  (SELECT "Id" FROM "Roles" WHERE "RoleCode" = 'ADMIN'),
  NULL,
  (SELECT "Id" FROM "Positions" WHERE "PositionCode" = 'DEPT_HEAD'),
  NULL,
  '2024-01-01',
  TRUE
),

-- REQUESTER 1 (IT Dept)
(
  (SELECT "Id" FROM "Users" WHERE "Email" = 'requester1@thaiventure.co.th'),
  (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'TVC001'),
  (SELECT "Id" FROM "Departments" WHERE "CompanyId" = (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'TVC001') AND "DepartmentCode" = 'IT'),
  (SELECT "Id" FROM "Roles" WHERE "RoleCode" = 'REQUESTER'),
  NULL,
  (SELECT "Id" FROM "Positions" WHERE "PositionCode" = 'STAFF'),
  NULL,
  '2024-01-01',
  TRUE
),

-- REQUESTER 2 (HR Dept)
(
  (SELECT "Id" FROM "Users" WHERE "Email" = 'requester2@thaiventure.co.th'),
  (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'TVC001'),
  (SELECT "Id" FROM "Departments" WHERE "CompanyId" = (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'TVC001') AND "DepartmentCode" = 'HR'),
  (SELECT "Id" FROM "Roles" WHERE "RoleCode" = 'REQUESTER'),
  NULL,
  (SELECT "Id" FROM "Positions" WHERE "PositionCode" = 'SR_OFFICER'),
  NULL,
  '2024-01-01',
  TRUE
),

-- REQUESTER 3 (APT - Sales Dept)
(
  (SELECT "Id" FROM "Users" WHERE "Email" = 'requester3@asiapacific.co.th'),
  (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'APT002'),
  (SELECT "Id" FROM "Departments" WHERE "CompanyId" = (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'APT002') AND "DepartmentCode" = 'SALES'),
  (SELECT "Id" FROM "Roles" WHERE "RoleCode" = 'REQUESTER'),
  NULL,
  (SELECT "Id" FROM "Positions" WHERE "PositionCode" = 'STAFF'),
  NULL,
  '2024-01-01',
  TRUE
),

-- APPROVER Level 1 (IT Dept)
(
  (SELECT "Id" FROM "Users" WHERE "Email" = 'approver.l1@thaiventure.co.th'),
  (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'TVC001'),
  (SELECT "Id" FROM "Departments" WHERE "CompanyId" = (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'TVC001') AND "DepartmentCode" = 'IT'),
  (SELECT "Id" FROM "Roles" WHERE "RoleCode" = 'APPROVER'),
  NULL,
  (SELECT "Id" FROM "Positions" WHERE "PositionCode" = 'SUPERVISOR'),
  1, -- Level 1
  '2024-01-01',
  TRUE
),

-- APPROVER Level 2 (IT Dept)
(
  (SELECT "Id" FROM "Users" WHERE "Email" = 'approver.l2@thaiventure.co.th'),
  (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'TVC001'),
  (SELECT "Id" FROM "Departments" WHERE "CompanyId" = (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'TVC001') AND "DepartmentCode" = 'IT'),
  (SELECT "Id" FROM "Roles" WHERE "RoleCode" = 'APPROVER'),
  NULL,
  (SELECT "Id" FROM "Positions" WHERE "PositionCode" = 'DEPT_HEAD'),
  2, -- Level 2
  '2024-01-01',
  TRUE
),

-- APPROVER Level 3 (Cross-department - FIN)
(
  (SELECT "Id" FROM "Users" WHERE "Email" = 'approver.l3@thaiventure.co.th'),
  (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'TVC001'),
  (SELECT "Id" FROM "Departments" WHERE "CompanyId" = (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'TVC001') AND "DepartmentCode" = 'FIN'),
  (SELECT "Id" FROM "Roles" WHERE "RoleCode" = 'APPROVER'),
  NULL,
  (SELECT "Id" FROM "Positions" WHERE "PositionCode" = 'DIRECTOR'),
  3, -- Level 3
  '2024-01-01',
  TRUE
),

-- PURCHASING 1 (PROC Dept - IT Category)
(
  (SELECT "Id" FROM "Users" WHERE "Email" = 'purchasing1@thaiventure.co.th'),
  (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'TVC001'),
  (SELECT "Id" FROM "Departments" WHERE "CompanyId" = (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'TVC001') AND "DepartmentCode" = 'PROC'),
  (SELECT "Id" FROM "Roles" WHERE "RoleCode" = 'PURCHASING'),
  NULL,
  (SELECT "Id" FROM "Positions" WHERE "PositionCode" = 'SR_OFFICER'),
  NULL,
  '2024-01-01',
  TRUE
),

-- PURCHASING 2 (PROC Dept - OFFICE Category)
(
  (SELECT "Id" FROM "Users" WHERE "Email" = 'purchasing2@thaiventure.co.th'),
  (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'TVC001'),
  (SELECT "Id" FROM "Departments" WHERE "CompanyId" = (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'TVC001') AND "DepartmentCode" = 'PROC'),
  (SELECT "Id" FROM "Roles" WHERE "RoleCode" = 'PURCHASING'),
  NULL,
  (SELECT "Id" FROM "Positions" WHERE "PositionCode" = 'OFFICER'),
  NULL,
  '2024-01-01',
  TRUE
),

-- PURCHASING 3 (APT - PROC Dept)
(
  (SELECT "Id" FROM "Users" WHERE "Email" = 'purchasing3@asiapacific.co.th'),
  (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'APT002'),
  (SELECT "Id" FROM "Departments" WHERE "CompanyId" = (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'APT002') AND "DepartmentCode" = 'PROC'),
  (SELECT "Id" FROM "Roles" WHERE "RoleCode" = 'PURCHASING'),
  NULL,
  (SELECT "Id" FROM "Positions" WHERE "PositionCode" = 'SR_OFFICER'),
  NULL,
  '2024-01-01',
  TRUE
),

-- PURCHASING_APPROVER Level 1 (PROC Dept)
(
  (SELECT "Id" FROM "Users" WHERE "Email" = 'purch.approver.l1@thaiventure.co.th'),
  (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'TVC001'),
  (SELECT "Id" FROM "Departments" WHERE "CompanyId" = (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'TVC001') AND "DepartmentCode" = 'PROC'),
  (SELECT "Id" FROM "Roles" WHERE "RoleCode" = 'PURCHASING_APPROVER'),
  NULL,
  (SELECT "Id" FROM "Positions" WHERE "PositionCode" = 'DEPT_HEAD'),
  1, -- Level 1
  '2024-01-01',
  TRUE
),

-- PURCHASING_APPROVER Level 2 (FIN Dept)
(
  (SELECT "Id" FROM "Users" WHERE "Email" = 'purch.approver.l2@thaiventure.co.th'),
  (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'TVC001'),
  (SELECT "Id" FROM "Departments" WHERE "CompanyId" = (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'TVC001') AND "DepartmentCode" = 'FIN'),
  (SELECT "Id" FROM "Roles" WHERE "RoleCode" = 'PURCHASING_APPROVER'),
  NULL,
  (SELECT "Id" FROM "Positions" WHERE "PositionCode" = 'DIRECTOR'),
  2, -- Level 2
  '2024-01-01',
  TRUE
),

-- MANAGING_DIRECTOR (No department - company-wide)
(
  (SELECT "Id" FROM "Users" WHERE "Email" = 'md@thaiventure.co.th'),
  (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'TVC001'),
  NULL,
  (SELECT "Id" FROM "Roles" WHERE "RoleCode" = 'MANAGING_DIRECTOR'),
  NULL,
  (SELECT "Id" FROM "Positions" WHERE "PositionCode" = 'MD'),
  NULL,
  '2024-01-01',
  TRUE
),

-- APT ADMIN
(
  (SELECT "Id" FROM "Users" WHERE "Email" = 'admin@asiapacific.co.th'),
  (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'APT002'),
  (SELECT "Id" FROM "Departments" WHERE "CompanyId" = (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'APT002') AND "DepartmentCode" = 'PROC'),
  (SELECT "Id" FROM "Roles" WHERE "RoleCode" = 'ADMIN'),
  NULL,
  (SELECT "Id" FROM "Positions" WHERE "PositionCode" = 'MANAGER'),
  NULL,
  '2024-01-01',
  TRUE
)
ON CONFLICT ("UserId", "CompanyId", "DepartmentId", "PrimaryRoleId") DO NOTHING;

\echo '   ✓ Created 15 user company roles'
\echo ''

-- =============================================
-- SECTION 5: USER CATEGORY BINDINGS
-- (สำหรับ PURCHASING และ PURCHASING_APPROVER เท่านั้น)
-- =============================================

\echo '5. Creating User Category Bindings...'

-- PURCHASING 1 -> IT Category
INSERT INTO "UserCategoryBindings" ("UserCompanyRoleId", "CategoryId", "SubcategoryId", "IsActive") VALUES
(
  (SELECT ucr."Id" FROM "UserCompanyRoles" ucr
   JOIN "Users" u ON ucr."UserId" = u."Id"
   WHERE u."Email" = 'purchasing1@thaiventure.co.th'),
  (SELECT "Id" FROM "Categories" WHERE "CategoryCode" = 'IT'),
  NULL,
  TRUE
);

-- PURCHASING 2 -> OFFICE + MRO Categories
INSERT INTO "UserCategoryBindings" ("UserCompanyRoleId", "CategoryId", "SubcategoryId", "IsActive") VALUES
(
  (SELECT ucr."Id" FROM "UserCompanyRoles" ucr
   JOIN "Users" u ON ucr."UserId" = u."Id"
   WHERE u."Email" = 'purchasing2@thaiventure.co.th'),
  (SELECT "Id" FROM "Categories" WHERE "CategoryCode" = 'OFFICE'),
  NULL,
  TRUE
),
(
  (SELECT ucr."Id" FROM "UserCompanyRoles" ucr
   JOIN "Users" u ON ucr."UserId" = u."Id"
   WHERE u."Email" = 'purchasing2@thaiventure.co.th'),
  (SELECT "Id" FROM "Categories" WHERE "CategoryCode" = 'MRO'),
  NULL,
  TRUE
);

-- PURCHASING 3 (APT) -> SERVICES + UNIFORM
INSERT INTO "UserCategoryBindings" ("UserCompanyRoleId", "CategoryId", "SubcategoryId", "IsActive") VALUES
(
  (SELECT ucr."Id" FROM "UserCompanyRoles" ucr
   JOIN "Users" u ON ucr."UserId" = u."Id"
   WHERE u."Email" = 'purchasing3@asiapacific.co.th'),
  (SELECT "Id" FROM "Categories" WHERE "CategoryCode" = 'SERVICES'),
  NULL,
  TRUE
),
(
  (SELECT ucr."Id" FROM "UserCompanyRoles" ucr
   JOIN "Users" u ON ucr."UserId" = u."Id"
   WHERE u."Email" = 'purchasing3@asiapacific.co.th'),
  (SELECT "Id" FROM "Categories" WHERE "CategoryCode" = 'UNIFORM'),
  NULL,
  TRUE
);

-- PURCHASING_APPROVER 1 -> ALL IT Categories
INSERT INTO "UserCategoryBindings" ("UserCompanyRoleId", "CategoryId", "SubcategoryId", "IsActive") VALUES
(
  (SELECT ucr."Id" FROM "UserCompanyRoles" ucr
   JOIN "Users" u ON ucr."UserId" = u."Id"
   WHERE u."Email" = 'purch.approver.l1@thaiventure.co.th'),
  (SELECT "Id" FROM "Categories" WHERE "CategoryCode" = 'IT'),
  NULL,
  TRUE
);

-- PURCHASING_APPROVER 2 -> ALL Categories (Cross-category approver)
INSERT INTO "UserCategoryBindings" ("UserCompanyRoleId", "CategoryId", "SubcategoryId", "IsActive")
SELECT
  (SELECT ucr."Id" FROM "UserCompanyRoles" ucr
   JOIN "Users" u ON ucr."UserId" = u."Id"
   WHERE u."Email" = 'purch.approver.l2@thaiventure.co.th'),
  c."Id",
  NULL,
  TRUE
FROM "Categories" c
WHERE c."IsActive" = TRUE
ON CONFLICT ("UserCompanyRoleId", "CategoryId", "SubcategoryId") DO NOTHING;

\echo '   ✓ Created category bindings for PURCHASING and PURCHASING_APPROVER users'
\echo ''

-- =============================================
-- SECTION 6: USER PERMISSIONS (Effect-Based Examples)
-- =============================================

\echo '6. Creating Effect-Based User Permissions (examples)...'

-- Example 1: DENY specific permission to a REQUESTER
INSERT INTO "UserPermissions" (
  "UserId", "CompanyId", "PermissionId", "Effect",
  "GrantedBy", "Reason", "IsActive"
) VALUES
(
  (SELECT "Id" FROM "Users" WHERE "Email" = 'requester1@thaiventure.co.th'),
  (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'TVC001'),
  (SELECT "Id" FROM "Permissions" WHERE "PermissionCode" = 'RFQ_SUBMIT'),
  'DENY',
  (SELECT "Id" FROM "Users" WHERE "Email" = 'admin@thaiventure.co.th'),
  'Under probation - cannot submit RFQs until training completed',
  TRUE
);

-- Example 2: ALLOW extra permission to a REQUESTER
INSERT INTO "UserPermissions" (
  "UserId", "CompanyId", "PermissionId", "Effect",
  "GrantedBy", "Reason", "IsActive"
) VALUES
(
  (SELECT "Id" FROM "Users" WHERE "Email" = 'requester2@thaiventure.co.th'),
  (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'TVC001'),
  (SELECT "Id" FROM "Permissions" WHERE "PermissionCode" = 'RFQ_VIEW_DEPT'),
  'ALLOW',
  (SELECT "Id" FROM "Users" WHERE "Email" = 'admin@thaiventure.co.th'),
  'Temporary department coordinator role - needs to view all dept RFQs',
  TRUE
)
ON CONFLICT ("UserId", "CompanyId", "PermissionId") DO NOTHING;

\echo '   ✓ Created 2 example user permissions (1 DENY, 1 ALLOW)'
\echo ''

-- =============================================
-- SECTION 7: SUPPLIERS (10 suppliers)
-- =============================================

\echo '7. Creating Suppliers...'

INSERT INTO "Suppliers" (
  "TaxId", "CompanyNameTh", "CompanyNameEn",
  "BusinessTypeId", "JobTypeId",
  "RegisteredCapital", "RegisteredCapitalCurrencyId", "DefaultCurrencyId",
  "CompanyEmail", "CompanyPhone", "CompanyWebsite",
  "AddressLine1", "AddressLine2", "City", "Province", "PostalCode", "CountryId",
  "BusinessScope", "FoundedDate",
  "InvitedByUserId", "InvitedByCompanyId", "InvitedAt",
  "RegisteredAt", "ApprovedByUserId", "ApprovedAt",
  "Status", "IsActive"
) VALUES
-- Supplier 1: IT Hardware (COMPLETED)
(
  '0105559001111',
  'บริษัท เทคโนโลยีคอมพิวเตอร์ จำกัด',
  'Tech Computer Co., Ltd.',
  2, -- JURISTIC
  1, -- BUY
  3000000.00,
  (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'THB'),
  (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'THB'),
  'sales@techcomputer.co.th',
  '+66-2-111-2222',
  'https://www.techcomputer.co.th',
  '100 ถนนพระราม 9',
  'แขวงห้วยขวาง',
  'กรุงเทพมหานคร',
  'กรุงเทพมหานคร',
  '10310',
  (SELECT "Id" FROM "Countries" WHERE "CountryCode" = 'TH'),
  'จำหน่ายคอมพิวเตอร์และอุปกรณ์ IT',
  '2015-05-10',
  (SELECT "Id" FROM "Users" WHERE "Email" = 'purchasing1@thaiventure.co.th'),
  (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'TVC001'),
  '2024-01-15 10:00:00+07',
  '2024-01-15 14:30:00+07',
  (SELECT "Id" FROM "Users" WHERE "Email" = 'purch.approver.l1@thaiventure.co.th'),
  '2024-01-16 09:00:00+07',
  'COMPLETED',
  TRUE
),

-- Supplier 2: Office Supplies (COMPLETED)
(
  '0105559002222',
  'บริษัท สำนักงานภัณฑ์ไทย จำกัด',
  'Thai Office Supply Co., Ltd.',
  2, -- JURISTIC
  1, -- BUY
  2000000.00,
  (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'THB'),
  (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'THB'),
  'info@thaiofficebsupply.com',
  '+66-2-222-3333',
  'https://www.thaiofficesupply.com',
  '200 ถนนลาดพร้าว',
  'แขวงจอมพล',
  'กรุงเทพมหานคร',
  'กรุงเทพมหานคร',
  '10900',
  (SELECT "Id" FROM "Countries" WHERE "CountryCode" = 'TH'),
  'จำหน่ายอุปกรณ์สำนักงานครบวงจร',
  '2012-03-20',
  (SELECT "Id" FROM "Users" WHERE "Email" = 'purchasing2@thaiventure.co.th'),
  (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'TVC001'),
  '2024-01-20 11:00:00+07',
  '2024-01-20 16:00:00+07',
  (SELECT "Id" FROM "Users" WHERE "Email" = 'purch.approver.l1@thaiventure.co.th'),
  '2024-01-21 10:00:00+07',
  'COMPLETED',
  TRUE
),

-- Supplier 3: IT Services (PENDING - waiting approval)
(
  '0105559003333',
  'บริษัท ไอทีซอลูชั่น จำกัด',
  'IT Solution Co., Ltd.',
  2, -- JURISTIC
  1, -- BUY
  5000000.00,
  (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'THB'),
  (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'THB'),
  'contact@itsolution.co.th',
  '+66-2-333-4444',
  'https://www.itsolution.co.th',
  '300 ถนนสาธร',
  'แขวงสาธร',
  'กรุงเทพมหานคร',
  'กรุงเทพมหานคร',
  '10120',
  (SELECT "Id" FROM "Countries" WHERE "CountryCode" = 'TH'),
  'บริการดูแลระบบ IT และ Cloud Services',
  '2018-08-15',
  (SELECT "Id" FROM "Users" WHERE "Email" = 'purchasing1@thaiventure.co.th'),
  (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'TVC001'),
  '2024-02-01 09:00:00+07',
  '2024-02-01 15:00:00+07',
  NULL,
  NULL,
  'PENDING',
  TRUE
),

-- Supplier 4: Cleaning Services (COMPLETED)
(
  '0105559004444',
  'บริษัท สะอาดทุกวัน จำกัด',
  'Clean Everyday Co., Ltd.',
  2, -- JURISTIC
  1, -- BUY
  1000000.00,
  (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'THB'),
  (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'THB'),
  'service@cleaneveryday.co.th',
  '+66-2-444-5555',
  'https://www.cleaneveryday.co.th',
  '400 ถนนเพชรบุรี',
  'แขวงมักกะสัน',
  'กรุงเทพมหานคร',
  'กรุงเทพมหานคร',
  '10400',
  (SELECT "Id" FROM "Countries" WHERE "CountryCode" = 'TH'),
  'บริการทำความสะอาดสำนักงาน',
  '2010-11-05',
  (SELECT "Id" FROM "Users" WHERE "Email" = 'purchasing3@asiapacific.co.th'),
  (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'APT002'),
  '2024-01-25 10:30:00+07',
  '2024-01-25 14:00:00+07',
  (SELECT "Id" FROM "Users" WHERE "Email" = 'admin@asiapacific.co.th'),
  '2024-01-26 09:00:00+07',
  'COMPLETED',
  TRUE
),

-- Supplier 5: Uniforms (COMPLETED)
(
  '0105559005555',
  'บริษัท ยูนิฟอร์มดีไซน์ จำกัด',
  'Uniform Design Co., Ltd.',
  2, -- JURISTIC
  1, -- BUY
  1500000.00,
  (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'THB'),
  (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'THB'),
  'sales@uniformdesign.co.th',
  '+66-2-555-6666',
  'https://www.uniformdesign.co.th',
  '500 ถนนประชาอุทิศ',
  'แขวงทุ่งครุ',
  'กรุงเทพมหานคร',
  'กรุงเทพมหานคร',
  '10140',
  (SELECT "Id" FROM "Countries" WHERE "CountryCode" = 'TH'),
  'ออกแบบและผลิตชุดยูนิฟอร์ม',
  '2013-07-20',
  (SELECT "Id" FROM "Users" WHERE "Email" = 'purchasing3@asiapacific.co.th'),
  (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'APT002'),
  '2024-02-05 11:00:00+07',
  '2024-02-05 16:30:00+07',
  (SELECT "Id" FROM "Users" WHERE "Email" = 'admin@asiapacific.co.th'),
  '2024-02-06 10:00:00+07',
  'COMPLETED',
  TRUE
),

-- Supplier 6: MRO (COMPLETED)
(
  '0105559006666',
  'บริษัท เครื่องมือช่าง จำกัด',
  'Tools & Equipment Co., Ltd.',
  2, -- JURISTIC
  1, -- BUY
  4000000.00,
  (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'THB'),
  (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'THB'),
  'sales@toolsequipment.co.th',
  '+66-2-666-7777',
  'https://www.toolsequipment.co.th',
  '600 ถนนรามคำแหง',
  'แขวงหัวหมาก',
  'กรุงเทพมหานคร',
  'กรุงเทพมหานคร',
  '10240',
  (SELECT "Id" FROM "Countries" WHERE "CountryCode" = 'TH'),
  'จำหน่ายเครื่องมือช่างและอุปกรณ์ซ่อมบำรุง',
  '2011-09-10',
  (SELECT "Id" FROM "Users" WHERE "Email" = 'purchasing2@thaiventure.co.th'),
  (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'TVC001'),
  '2024-01-28 09:30:00+07',
  '2024-01-28 14:00:00+07',
  (SELECT "Id" FROM "Users" WHERE "Email" = 'purch.approver.l1@thaiventure.co.th'),
  '2024-01-29 09:00:00+07',
  'COMPLETED',
  TRUE
),

-- Supplier 7: Individual Supplier (COMPLETED)
(
  '1234567890123',
  'ร้านคอมพิวเตอร์สมชาย',
  'Somchai Computer Shop',
  1, -- INDIVIDUAL
  1, -- BUY
  NULL,
  NULL,
  (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'THB'),
  'somchai.computer@gmail.com',
  '+66-81-777-8888',
  NULL,
  '700 ถนนพหลโยธิน',
  'แขวงจตุจักร',
  'กรุงเทพมหานคร',
  'กรุงเทพมหานคร',
  '10900',
  (SELECT "Id" FROM "Countries" WHERE "CountryCode" = 'TH'),
  'ขายคอมพิวเตอร์มือสอง',
  NULL,
  (SELECT "Id" FROM "Users" WHERE "Email" = 'purchasing1@thaiventure.co.th'),
  (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'TVC001'),
  '2024-02-10 10:00:00+07',
  '2024-02-10 15:00:00+07',
  (SELECT "Id" FROM "Users" WHERE "Email" = 'purch.approver.l1@thaiventure.co.th'),
  '2024-02-11 09:30:00+07',
  'COMPLETED',
  TRUE
),

-- Supplier 8: Singapore Supplier (COMPLETED)
(
  'SG123456789',
  'Singapore Tech Pte Ltd',
  'Singapore Tech Pte Ltd',
  2, -- JURISTIC
  1, -- BUY
  500000.00,
  (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'SGD'),
  (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'SGD'),
  'sales@sgtech.com.sg',
  '+65-6888-9999',
  'https://www.sgtech.com.sg',
  '100 Orchard Road',
  '#10-01',
  'Singapore',
  'Singapore',
  '238840',
  (SELECT "Id" FROM "Countries" WHERE "CountryCode" = 'SG'),
  'IT Hardware and Software Solutions',
  '2016-04-15',
  (SELECT "Id" FROM "Users" WHERE "Email" = 'purchasing1@thaiventure.co.th'),
  (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'TVC001'),
  '2024-02-15 09:00:00+07',
  '2024-02-15 16:00:00+07',
  (SELECT "Id" FROM "Users" WHERE "Email" = 'purch.approver.l2@thaiventure.co.th'),
  '2024-02-16 10:00:00+07',
  'COMPLETED',
  TRUE
),

-- Supplier 9: Electrical Systems (PENDING)
(
  '0105559009999',
  'บริษัท ระบบไฟฟ้า จำกัด',
  'Electrical Systems Co., Ltd.',
  2, -- JURISTIC
  1, -- BUY
  8000000.00,
  (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'THB'),
  (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'THB'),
  'info@electricalsystems.co.th',
  '+66-2-999-0000',
  'https://www.electricalsystems.co.th',
  '900 ถนนวิภาวดีรังสิต',
  'แขวงจตุจักร',
  'กรุงเทพมหานคร',
  'กรุงเทพมหานคร',
  '10900',
  (SELECT "Id" FROM "Countries" WHERE "CountryCode" = 'TH'),
  'ติดตั้งและซ่อมบำรุงระบบไฟฟ้า',
  '2014-12-01',
  (SELECT "Id" FROM "Users" WHERE "Email" = 'purchasing2@thaiventure.co.th'),
  (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'TVC001'),
  '2024-02-20 11:00:00+07',
  '2024-02-20 17:00:00+07',
  NULL,
  NULL,
  'PENDING',
  TRUE
),

-- Supplier 10: Training Services (DECLINED)
(
  '0105559010000',
  'บริษัท อบรมพัฒนา จำกัด',
  'Training Development Co., Ltd.',
  2, -- JURISTIC
  1, -- BUY
  2500000.00,
  (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'THB'),
  (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'THB'),
  'training@traindev.co.th',
  '+66-2-000-1111',
  'https://www.traindev.co.th',
  '1000 ถนนศรีนครินทร์',
  'แขวงหนองบอน',
  'กรุงเทพมหานคร',
  'กรุงเทพมหานคร',
  '10250',
  (SELECT "Id" FROM "Countries" WHERE "CountryCode" = 'TH'),
  'บริการฝึกอบรมและพัฒนาบุคลากร',
  '2017-06-10',
  (SELECT "Id" FROM "Users" WHERE "Email" = 'purchasing3@asiapacific.co.th'),
  (SELECT "Id" FROM "Companies" WHERE "CompanyCode" = 'APT002'),
  '2024-02-22 10:00:00+07',
  '2024-02-22 15:30:00+07',
  NULL,
  NULL,
  'DECLINED',
  FALSE
)
ON CONFLICT ("TaxId") DO NOTHING;

\echo '   ✓ Created 10 suppliers (7 COMPLETED, 2 PENDING, 1 DECLINED)'
\echo ''

-- =============================================
-- SECTION 8: SUPPLIER CONTACTS
-- =============================================

\echo '8. Creating Supplier Contacts...'

-- Supplier 1: Tech Computer (2 contacts)
INSERT INTO "SupplierContacts" (
  "SupplierId", "FirstName", "LastName", "Position",
  "Email", "PhoneNumber", "MobileNumber",
  "PreferredLanguage", "PreferredTimezone",
  "PasswordHash", "IsEmailVerified", "EmailVerifiedAt",
  "CanSubmitQuotation", "CanReceiveNotification", "IsPrimaryContact", "IsActive"
) VALUES
(
  (SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559001111'),
  'สมหมาย', 'ขายดี', 'Sales Manager',
  'sommai@techcomputer.co.th', '+66-2-111-2223', '+66-81-111-2222',
  'th', 'Asia/Bangkok',
  '$2a$11$LQKvFfZZvZxJxPxH.JzH4uVqhvZxME5lFYqZ0RLz7g8y4Z5PZJHKm',
  TRUE, '2024-01-15 14:30:00+07',
  TRUE, TRUE, TRUE, TRUE
),
(
  (SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559001111'),
  'วิชัย', 'ช่วยขาย', 'Sales Executive',
  'wichai@techcomputer.co.th', '+66-2-111-2224', '+66-82-111-3333',
  'th', 'Asia/Bangkok',
  '$2a$11$LQKvFfZZvZxJxPxH.JzH4uVqhvZxME5lFYqZ0RLz7g8y4Z5PZJHKm',
  TRUE, '2024-01-15 14:30:00+07',
  TRUE, TRUE, FALSE, TRUE
);

-- Supplier 2: Thai Office Supply (1 contact)
INSERT INTO "SupplierContacts" (
  "SupplierId", "FirstName", "LastName", "Position",
  "Email", "PhoneNumber", "MobileNumber",
  "PreferredLanguage", "PreferredTimezone",
  "PasswordHash", "IsEmailVerified", "EmailVerifiedAt",
  "CanSubmitQuotation", "CanReceiveNotification", "IsPrimaryContact", "IsActive"
) VALUES
(
  (SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559002222'),
  'สมศรี', 'จัดส่ง', 'Account Manager',
  'somsri@thaiofficesupply.com', '+66-2-222-3334', '+66-81-222-4444',
  'th', 'Asia/Bangkok',
  '$2a$11$LQKvFfZZvZxJxPxH.JzH4uVqhvZxME5lFYqZ0RLz7g8y4Z5PZJHKm',
  TRUE, '2024-01-20 16:00:00+07',
  TRUE, TRUE, TRUE, TRUE
);

-- Supplier 3: IT Solution (1 contact - PENDING)
INSERT INTO "SupplierContacts" (
  "SupplierId", "FirstName", "LastName", "Position",
  "Email", "PhoneNumber", "MobileNumber",
  "PreferredLanguage", "PreferredTimezone",
  "PasswordHash", "IsEmailVerified", "EmailVerifiedAt",
  "CanSubmitQuotation", "CanReceiveNotification", "IsPrimaryContact", "IsActive"
) VALUES
(
  (SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559003333'),
  'ธนพล', 'เทคโน', 'Director',
  'thanapol@itsolution.co.th', '+66-2-333-4445', '+66-81-333-5555',
  'th', 'Asia/Bangkok',
  '$2a$11$LQKvFfZZvZxJxPxH.JzH4uVqhvZxME5lFYqZ0RLz7g8y4Z5PZJHKm',
  TRUE, '2024-02-01 15:00:00+07',
  TRUE, TRUE, TRUE, TRUE
);

-- Supplier 4: Clean Everyday (1 contact)
INSERT INTO "SupplierContacts" (
  "SupplierId", "FirstName", "LastName", "Position",
  "Email", "PhoneNumber", "MobileNumber",
  "PreferredLanguage", "PreferredTimezone",
  "PasswordHash", "IsEmailVerified", "EmailVerifiedAt",
  "CanSubmitQuotation", "CanReceiveNotification", "IsPrimaryContact", "IsActive"
) VALUES
(
  (SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559004444'),
  'มานี', 'ทำงาน', 'Operations Manager',
  'manee@cleaneveryday.co.th', '+66-2-444-5556', '+66-81-444-6666',
  'th', 'Asia/Bangkok',
  '$2a$11$LQKvFfZZvZxJxPxH.JzH4uVqhvZxME5lFYqZ0RLz7g8y4Z5PZJHKm',
  TRUE, '2024-01-25 14:00:00+07',
  TRUE, TRUE, TRUE, TRUE
);

-- Supplier 5: Uniform Design (1 contact)
INSERT INTO "SupplierContacts" (
  "SupplierId", "FirstName", "LastName", "Position",
  "Email", "PhoneNumber", "MobileNumber",
  "PreferredLanguage", "PreferredTimezone",
  "PasswordHash", "IsEmailVerified", "EmailVerifiedAt",
  "CanSubmitQuotation", "CanReceiveNotification", "IsPrimaryContact", "IsActive"
) VALUES
(
  (SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559005555'),
  'สุดา', 'ออกแบบ', 'Creative Director',
  'suda@uniformdesign.co.th', '+66-2-555-6667', '+66-81-555-7777',
  'th', 'Asia/Bangkok',
  '$2a$11$LQKvFfZZvZxJxPxH.JzH4uVqhvZxME5lFYqZ0RLz7g8y4Z5PZJHKm',
  TRUE, '2024-02-05 16:30:00+07',
  TRUE, TRUE, TRUE, TRUE
);

-- Supplier 6: Tools & Equipment (1 contact)
INSERT INTO "SupplierContacts" (
  "SupplierId", "FirstName", "LastName", "Position",
  "Email", "PhoneNumber", "MobileNumber",
  "PreferredLanguage", "PreferredTimezone",
  "PasswordHash", "IsEmailVerified", "EmailVerifiedAt",
  "CanSubmitQuotation", "CanReceiveNotification", "IsPrimaryContact", "IsActive"
) VALUES
(
  (SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559006666'),
  'ประยุทธ', 'ช่างเหล็ก', 'Sales Manager',
  'prayuth@toolsequipment.co.th', '+66-2-666-7778', '+66-81-666-8888',
  'th', 'Asia/Bangkok',
  '$2a$11$LQKvFfZZvZxJxPxH.JzH4uVqhvZxME5lFYqZ0RLz7g8y4Z5PZJHKm',
  TRUE, '2024-01-28 14:00:00+07',
  TRUE, TRUE, TRUE, TRUE
);

-- Supplier 7: Individual (1 contact - owner)
INSERT INTO "SupplierContacts" (
  "SupplierId", "FirstName", "LastName", "Position",
  "Email", "PhoneNumber", "MobileNumber",
  "PreferredLanguage", "PreferredTimezone",
  "PasswordHash", "IsEmailVerified", "EmailVerifiedAt",
  "CanSubmitQuotation", "CanReceiveNotification", "IsPrimaryContact", "IsActive"
) VALUES
(
  (SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '1234567890123'),
  'สมชาย', 'รักคอม', 'Owner',
  'somchai.computer@gmail.com', '+66-81-777-8888', '+66-81-777-8888',
  'th', 'Asia/Bangkok',
  '$2a$11$LQKvFfZZvZxJxPxH.JzH4uVqhvZxME5lFYqZ0RLz7g8y4Z5PZJHKm',
  TRUE, '2024-02-10 15:00:00+07',
  TRUE, TRUE, TRUE, TRUE
);

-- Supplier 8: Singapore Tech (1 contact)
INSERT INTO "SupplierContacts" (
  "SupplierId", "FirstName", "LastName", "Position",
  "Email", "PhoneNumber", "MobileNumber",
  "PreferredLanguage", "PreferredTimezone",
  "PasswordHash", "IsEmailVerified", "EmailVerifiedAt",
  "CanSubmitQuotation", "CanReceiveNotification", "IsPrimaryContact", "IsActive"
) VALUES
(
  (SELECT "Id" FROM "Suppliers" WHERE "TaxId" = 'SG123456789'),
  'John', 'Tan', 'Regional Sales Director',
  'john.tan@sgtech.com.sg', '+65-6888-9990', '+65-9123-4567',
  'en', 'Asia/Singapore',
  '$2a$11$LQKvFfZZvZxJxPxH.JzH4uVqhvZxME5lFYqZ0RLz7g8y4Z5PZJHKm',
  TRUE, '2024-02-15 16:00:00+07',
  TRUE, TRUE, TRUE, TRUE
);

-- Supplier 9: Electrical Systems (1 contact - PENDING)
INSERT INTO "SupplierContacts" (
  "SupplierId", "FirstName", "LastName", "Position",
  "Email", "PhoneNumber", "MobileNumber",
  "PreferredLanguage", "PreferredTimezone",
  "PasswordHash", "IsEmailVerified", "EmailVerifiedAt",
  "CanSubmitQuotation", "CanReceiveNotification", "IsPrimaryContact", "IsActive"
) VALUES
(
  (SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559009999'),
  'วิศวกร', 'ไฟฟ้า', 'Technical Manager',
  'wisakorn@electricalsystems.co.th', '+66-2-999-0001', '+66-81-999-1111',
  'th', 'Asia/Bangkok',
  '$2a$11$LQKvFfZZvZxJxPxH.JzH4uVqhvZxME5lFYqZ0RLz7g8y4Z5PZJHKm',
  TRUE, '2024-02-20 17:00:00+07',
  TRUE, TRUE, TRUE, TRUE
);

-- Supplier 10: Training Development (1 contact - DECLINED)
INSERT INTO "SupplierContacts" (
  "SupplierId", "FirstName", "LastName", "Position",
  "Email", "PhoneNumber", "MobileNumber",
  "PreferredLanguage", "PreferredTimezone",
  "PasswordHash", "IsEmailVerified", "EmailVerifiedAt",
  "CanSubmitQuotation", "CanReceiveNotification", "IsPrimaryContact", "IsActive"
) VALUES
(
  (SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559010000'),
  'อรุณ', 'สอนดี', 'Training Director',
  'arun@traindev.co.th', '+66-2-000-1112', '+66-81-000-2222',
  'th', 'Asia/Bangkok',
  '$2a$11$LQKvFfZZvZxJxPxH.JzH4uVqhvZxME5lFYqZ0RLz7g8y4Z5PZJHKm',
  TRUE, '2024-02-22 15:30:00+07',
  TRUE, TRUE, TRUE, FALSE
)
ON CONFLICT ("SupplierId", "Email") DO NOTHING;

\echo '   ✓ Created 12 supplier contacts (1-2 contacts per supplier)'
\echo ''

-- =============================================
-- SECTION 9: SUPPLIER CATEGORIES
-- =============================================

\echo '9. Creating Supplier Categories...'

-- Supplier 1: IT Hardware -> IT Category (all subcategories)
INSERT INTO "SupplierCategories" ("SupplierId", "CategoryId", "SubcategoryId", "IsActive") VALUES
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559001111'),
 (SELECT "Id" FROM "Categories" WHERE "CategoryCode" = 'IT'),
 (SELECT "Id" FROM "Subcategories" WHERE "SubcategoryCode" = 'IT-HW-COM'), TRUE),
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559001111'),
 (SELECT "Id" FROM "Categories" WHERE "CategoryCode" = 'IT'),
 (SELECT "Id" FROM "Subcategories" WHERE "SubcategoryCode" = 'IT-HW-MON'), TRUE),
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559001111'),
 (SELECT "Id" FROM "Categories" WHERE "CategoryCode" = 'IT'),
 (SELECT "Id" FROM "Subcategories" WHERE "SubcategoryCode" = 'IT-HW-PRT'), TRUE),
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559001111'),
 (SELECT "Id" FROM "Categories" WHERE "CategoryCode" = 'IT'),
 (SELECT "Id" FROM "Subcategories" WHERE "SubcategoryCode" = 'IT-HW-NET'), TRUE);

-- Supplier 2: Office Supplies -> OFFICE Category (all subcategories)
INSERT INTO "SupplierCategories" ("SupplierId", "CategoryId", "SubcategoryId", "IsActive") VALUES
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559002222'),
 (SELECT "Id" FROM "Categories" WHERE "CategoryCode" = 'OFFICE'),
 (SELECT "Id" FROM "Subcategories" WHERE "SubcategoryCode" = 'OFF-STAT'), TRUE),
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559002222'),
 (SELECT "Id" FROM "Categories" WHERE "CategoryCode" = 'OFFICE'),
 (SELECT "Id" FROM "Subcategories" WHERE "SubcategoryCode" = 'OFF-PAPER'), TRUE),
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559002222'),
 (SELECT "Id" FROM "Categories" WHERE "CategoryCode" = 'OFFICE'),
 (SELECT "Id" FROM "Subcategories" WHERE "SubcategoryCode" = 'OFF-FURN'), TRUE),
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559002222'),
 (SELECT "Id" FROM "Categories" WHERE "CategoryCode" = 'OFFICE'),
 (SELECT "Id" FROM "Subcategories" WHERE "SubcategoryCode" = 'OFF-PANTRY'), TRUE);

-- Supplier 3: IT Services -> IT Category (service subcategories)
INSERT INTO "SupplierCategories" ("SupplierId", "CategoryId", "SubcategoryId", "IsActive") VALUES
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559003333'),
 (SELECT "Id" FROM "Categories" WHERE "CategoryCode" = 'IT'),
 (SELECT "Id" FROM "Subcategories" WHERE "SubcategoryCode" = 'IT-SW-LIC'), TRUE),
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559003333'),
 (SELECT "Id" FROM "Categories" WHERE "CategoryCode" = 'IT'),
 (SELECT "Id" FROM "Subcategories" WHERE "SubcategoryCode" = 'IT-SVC-MA'), TRUE);

-- Supplier 4: Cleaning Services -> SERVICES Category
INSERT INTO "SupplierCategories" ("SupplierId", "CategoryId", "SubcategoryId", "IsActive") VALUES
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559004444'),
 (SELECT "Id" FROM "Categories" WHERE "CategoryCode" = 'SERVICES'),
 (SELECT "Id" FROM "Subcategories" WHERE "SubcategoryCode" = 'SVC-CLEAN'), TRUE);

-- Supplier 5: Uniforms -> UNIFORM Category
INSERT INTO "SupplierCategories" ("SupplierId", "CategoryId", "SubcategoryId", "IsActive") VALUES
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559005555'),
 (SELECT "Id" FROM "Categories" WHERE "CategoryCode" = 'UNIFORM'),
 (SELECT "Id" FROM "Subcategories" WHERE "SubcategoryCode" = 'UNI-SHIRT'), TRUE),
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559005555'),
 (SELECT "Id" FROM "Categories" WHERE "CategoryCode" = 'UNIFORM'),
 (SELECT "Id" FROM "Subcategories" WHERE "SubcategoryCode" = 'UNI-SUIT'), TRUE),
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559005555'),
 (SELECT "Id" FROM "Categories" WHERE "CategoryCode" = 'UNIFORM'),
 (SELECT "Id" FROM "Subcategories" WHERE "SubcategoryCode" = 'UNI-SAFETY'), TRUE);

-- Supplier 6: Tools & Equipment -> MRO Category
INSERT INTO "SupplierCategories" ("SupplierId", "CategoryId", "SubcategoryId", "IsActive") VALUES
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559006666'),
 (SELECT "Id" FROM "Categories" WHERE "CategoryCode" = 'MRO'),
 (SELECT "Id" FROM "Subcategories" WHERE "SubcategoryCode" = 'MRO-ELEC'), TRUE),
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559006666'),
 (SELECT "Id" FROM "Categories" WHERE "CategoryCode" = 'MRO'),
 (SELECT "Id" FROM "Subcategories" WHERE "SubcategoryCode" = 'MRO-TOOLS'), TRUE),
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559006666'),
 (SELECT "Id" FROM "Categories" WHERE "CategoryCode" = 'MRO'),
 (SELECT "Id" FROM "Subcategories" WHERE "SubcategoryCode" = 'MRO-SPARE'), TRUE);

-- Supplier 7: Individual (IT hardware only)
INSERT INTO "SupplierCategories" ("SupplierId", "CategoryId", "SubcategoryId", "IsActive") VALUES
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '1234567890123'),
 (SELECT "Id" FROM "Categories" WHERE "CategoryCode" = 'IT'),
 (SELECT "Id" FROM "Subcategories" WHERE "SubcategoryCode" = 'IT-HW-COM'), TRUE);

-- Supplier 8: Singapore Tech -> IT (full IT categories)
INSERT INTO "SupplierCategories" ("SupplierId", "CategoryId", "SubcategoryId", "IsActive") VALUES
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = 'SG123456789'),
 (SELECT "Id" FROM "Categories" WHERE "CategoryCode" = 'IT'),
 (SELECT "Id" FROM "Subcategories" WHERE "SubcategoryCode" = 'IT-HW-COM'), TRUE),
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = 'SG123456789'),
 (SELECT "Id" FROM "Categories" WHERE "CategoryCode" = 'IT'),
 (SELECT "Id" FROM "Subcategories" WHERE "SubcategoryCode" = 'IT-HW-NET'), TRUE),
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = 'SG123456789'),
 (SELECT "Id" FROM "Categories" WHERE "CategoryCode" = 'IT'),
 (SELECT "Id" FROM "Subcategories" WHERE "SubcategoryCode" = 'IT-SW-LIC'), TRUE);

-- Supplier 9: Electrical Systems -> ELECTRICAL Category
INSERT INTO "SupplierCategories" ("SupplierId", "CategoryId", "SubcategoryId", "IsActive") VALUES
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559009999'),
 (SELECT "Id" FROM "Categories" WHERE "CategoryCode" = 'ELECTRICAL'),
 (SELECT "Id" FROM "Subcategories" WHERE "SubcategoryCode" = 'ELEC-LIGHT'), TRUE),
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559009999'),
 (SELECT "Id" FROM "Categories" WHERE "CategoryCode" = 'ELECTRICAL'),
 (SELECT "Id" FROM "Subcategories" WHERE "SubcategoryCode" = 'ELEC-POWER'), TRUE),
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559009999'),
 (SELECT "Id" FROM "Categories" WHERE "CategoryCode" = 'ELECTRICAL'),
 (SELECT "Id" FROM "Subcategories" WHERE "SubcategoryCode" = 'ELEC-BACKUP'), TRUE);

-- Supplier 10: Training Services -> SERVICES Category
INSERT INTO "SupplierCategories" ("SupplierId", "CategoryId", "SubcategoryId", "IsActive") VALUES
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559010000'),
 (SELECT "Id" FROM "Categories" WHERE "CategoryCode" = 'SERVICES'),
 (SELECT "Id" FROM "Subcategories" WHERE "SubcategoryCode" = 'SVC-TRAINING'), TRUE)
ON CONFLICT ("SupplierId", "CategoryId", "SubcategoryId") DO NOTHING;

\echo '   ✓ Created 30+ supplier category mappings'
\echo ''

-- =============================================
-- SECTION 10: SUPPLIER DOCUMENTS
-- =============================================

\echo '10. Creating Supplier Documents (samples)...'

-- Supplier 1: Tech Computer (JURISTIC - 5 documents)
INSERT INTO "SupplierDocuments" (
  "SupplierId", "DocumentType", "DocumentName", "FileName",
  "FilePath", "FileSize", "MimeType", "IsActive"
) VALUES
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559001111'),
 'COMPANY_REGISTRATION', 'ใบทะเบียนบริษัท', 'tech-computer-registration.pdf',
 '/suppliers/tech-computer/tech-computer-registration.pdf', 245678, 'application/pdf', TRUE),
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559001111'),
 'TAX_CERTIFICATE', 'ใบทะเบียนภาษี', 'tech-computer-tax-cert.pdf',
 '/suppliers/tech-computer/tech-computer-tax-cert.pdf', 128934, 'application/pdf', TRUE),
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559001111'),
 'VAT_REGISTRATION', 'ทะเบียนภาษีมูลค่าเพิ่ม', 'tech-computer-vat.pdf',
 '/suppliers/tech-computer/tech-computer-vat.pdf', 156789, 'application/pdf', TRUE),
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559001111'),
 'BANK_STATEMENT', 'Statement บัญชีธนาคาร', 'tech-computer-bank-statement.pdf',
 '/suppliers/tech-computer/tech-computer-bank-statement.pdf', 289456, 'application/pdf', TRUE),
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559001111'),
 'COMPANY_PROFILE', 'Profile บริษัท', 'tech-computer-profile.pdf',
 '/suppliers/tech-computer/tech-computer-profile.pdf', 1245678, 'application/pdf', TRUE);

-- Supplier 2: Thai Office Supply (JURISTIC - 5 documents)
INSERT INTO "SupplierDocuments" (
  "SupplierId", "DocumentType", "DocumentName", "FileName",
  "FilePath", "FileSize", "MimeType", "IsActive"
) VALUES
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559002222'),
 'COMPANY_REGISTRATION', 'ใบทะเบียนบริษัท', 'thai-office-registration.pdf',
 '/suppliers/thai-office/thai-office-registration.pdf', 198765, 'application/pdf', TRUE),
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559002222'),
 'TAX_CERTIFICATE', 'ใบทะเบียนภาษี', 'thai-office-tax-cert.pdf',
 '/suppliers/thai-office/thai-office-tax-cert.pdf', 112345, 'application/pdf', TRUE),
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559002222'),
 'VAT_REGISTRATION', 'ทะเบียนภาษีมูลค่าเพิ่ม', 'thai-office-vat.pdf',
 '/suppliers/thai-office/thai-office-vat.pdf', 145678, 'application/pdf', TRUE),
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559002222'),
 'BANK_STATEMENT', 'Statement บัญชีธนาคาร', 'thai-office-bank-statement.pdf',
 '/suppliers/thai-office/thai-office-bank-statement.pdf', 267890, 'application/pdf', TRUE),
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '0105559002222'),
 'COMPANY_PROFILE', 'Profile บริษัท', 'thai-office-profile.pdf',
 '/suppliers/thai-office/thai-office-profile.pdf', 989012, 'application/pdf', TRUE);

-- Supplier 7: Individual (2 documents only)
INSERT INTO "SupplierDocuments" (
  "SupplierId", "DocumentType", "DocumentName", "FileName",
  "FilePath", "FileSize", "MimeType", "IsActive"
) VALUES
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '1234567890123'),
 'ID_CARD', 'บัตรประชาชน', 'somchai-id-card.pdf',
 '/suppliers/somchai-computer/somchai-id-card.pdf', 89012, 'application/pdf', TRUE),
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = '1234567890123'),
 'BANK_STATEMENT', 'Statement บัญชีธนาคาร', 'somchai-bank-statement.pdf',
 '/suppliers/somchai-computer/somchai-bank-statement.pdf', 178900, 'application/pdf', TRUE);

-- Supplier 8: Singapore Tech (JURISTIC - 5 documents)
INSERT INTO "SupplierDocuments" (
  "SupplierId", "DocumentType", "DocumentName", "FileName",
  "FilePath", "FileSize", "MimeType", "IsActive"
) VALUES
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = 'SG123456789'),
 'COMPANY_REGISTRATION', 'Company Registration (Singapore)', 'sg-tech-registration.pdf',
 '/suppliers/sg-tech/sg-tech-registration.pdf', 312456, 'application/pdf', TRUE),
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = 'SG123456789'),
 'TAX_CERTIFICATE', 'Tax Certificate (Singapore)', 'sg-tech-tax-cert.pdf',
 '/suppliers/sg-tech/sg-tech-tax-cert.pdf', 145789, 'application/pdf', TRUE),
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = 'SG123456789'),
 'GST_REGISTRATION', 'GST Registration', 'sg-tech-gst.pdf',
 '/suppliers/sg-tech/sg-tech-gst.pdf', 178234, 'application/pdf', TRUE),
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = 'SG123456789'),
 'BANK_STATEMENT', 'Bank Statement', 'sg-tech-bank-statement.pdf',
 '/suppliers/sg-tech/sg-tech-bank-statement.pdf', 298765, 'application/pdf', TRUE),
((SELECT "Id" FROM "Suppliers" WHERE "TaxId" = 'SG123456789'),
 'COMPANY_PROFILE', 'Company Profile', 'sg-tech-profile.pdf',
 '/suppliers/sg-tech/sg-tech-profile.pdf', 1567890, 'application/pdf', TRUE);

\echo '   ✓ Created 17 supplier documents (samples for 4 suppliers)'
\echo ''

-- =============================================
-- FINAL SUMMARY
-- =============================================

\echo ''
\echo '=========================================='
\echo 'SEED DATA CREATION SUMMARY'
\echo '=========================================='
\echo ''

SELECT
    '✅ Companies' as component,
    COUNT(*) as count
FROM "Companies"
UNION ALL
SELECT
    '✅ Departments',
    COUNT(*)
FROM "Departments"
UNION ALL
SELECT
    '✅ Users',
    COUNT(*)
FROM "Users"
UNION ALL
SELECT
    '✅ UserCompanyRoles',
    COUNT(*)
FROM "UserCompanyRoles"
UNION ALL
SELECT
    '✅ UserCategoryBindings',
    COUNT(*)
FROM "UserCategoryBindings"
UNION ALL
SELECT
    '✅ UserPermissions',
    COUNT(*)
FROM "UserPermissions"
UNION ALL
SELECT
    '✅ Suppliers',
    COUNT(*)
FROM "Suppliers"
UNION ALL
SELECT
    '✅ SupplierContacts',
    COUNT(*)
FROM "SupplierContacts"
UNION ALL
SELECT
    '✅ SupplierCategories',
    COUNT(*)
FROM "SupplierCategories"
UNION ALL
SELECT
    '✅ SupplierDocuments',
    COUNT(*)
FROM "SupplierDocuments";

\echo ''
\echo '=========================================='
\echo 'Seed Data Creation Complete!'
\echo '=========================================='
\echo ''
\echo 'Next Steps:'
\echo '1. Start application and test login with sample users'
\echo '2. Verify RLS policies work correctly (multi-tenant)'
\echo '3. Create transactional data (RFQs, Quotations) via UI'
\echo '4. Test approval workflows with different user roles'
\echo ''
\echo 'Sample Login Credentials:'
\echo '  SUPER_ADMIN: superadmin@erfx.system'
\echo '  ADMIN (TVC): admin@thaiventure.co.th'
\echo '  REQUESTER: requester1@thaiventure.co.th'
\echo '  PURCHASING: purchasing1@thaiventure.co.th'
\echo '  Password: Password123! (for all users)'
\echo ''
