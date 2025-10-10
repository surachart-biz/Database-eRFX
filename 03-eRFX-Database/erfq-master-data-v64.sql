-- =============================================
-- E-RFQ SYSTEM COMPLETE MASTER DATA v6.4
-- Database: PostgreSQL 16+
-- Last Updated: 2025-10-07
-- Changes: Compatible with Schema v6.4 (Effect-Based Permissions + RLS)
-- Note: No data changes needed - schema changes are structural only
-- =============================================

-- =============================================
-- SECTION 1: CURRENCIES (สกุลเงิน)
-- =============================================

INSERT INTO "Currencies" ("CurrencyCode", "CurrencyName", "CurrencySymbol", "DecimalPlaces", "IsActive") VALUES
('THB', 'Thai Baht', '฿', 2, TRUE),
('USD', 'US Dollar', '$', 2, TRUE),
('EUR', 'Euro', '€', 2, TRUE),
('GBP', 'British Pound', '£', 2, TRUE),
('JPY', 'Japanese Yen', '¥', 0, TRUE),
('CNY', 'Chinese Yuan', '¥', 2, TRUE),
('SGD', 'Singapore Dollar', 'S$', 2, TRUE),
('MYR', 'Malaysian Ringgit', 'RM', 2, TRUE),
('AUD', 'Australian Dollar', 'A$', 2, TRUE),
('HKD', 'Hong Kong Dollar', 'HK$', 2, TRUE)
ON CONFLICT ("CurrencyCode") DO NOTHING;
-- india , indonisia ,Veitenam
-- =============================================
-- SECTION 2: COUNTRIES (ประเทศ)
-- =============================================

INSERT INTO "Countries" ("CountryCode", "CountryNameEn", "CountryNameTh", "DefaultCurrencyId", "Timezone", "PhoneCode", "IsActive") VALUES
('TH', 'Thailand', 'ประเทศไทย', (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'THB'), 'Asia/Bangkok', '+66', TRUE),
('US', 'United States', 'สหรัฐอเมริกา', (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'USD'), 'America/New_York', '+1', TRUE),
('GB', 'United Kingdom', 'สหราชอาณาจักร', (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'GBP'), 'Europe/London', '+44', TRUE),
('JP', 'Japan', 'ญี่ปุ่น', (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'JPY'), 'Asia/Tokyo', '+81', TRUE),
('CN', 'China', 'จีน', (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'CNY'), 'Asia/Shanghai', '+86', TRUE),
('SG', 'Singapore', 'สิงคโปร์', (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'SGD'), 'Asia/Singapore', '+65', TRUE),
('MY', 'Malaysia', 'มาเลเซีย', (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'MYR'), 'Asia/Kuala_Lumpur', '+60', TRUE),
('AU', 'Australia', 'ออสเตรเลีย', (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'AUD'), 'Australia/Sydney', '+61', TRUE),
('HK', 'Hong Kong', 'ฮ่องกง', (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'HKD'), 'Asia/Hong_Kong', '+852', TRUE),
('VN', 'Vietnam', 'เวียดนาม', (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'USD'), 'Asia/Ho_Chi_Minh', '+84', TRUE)
ON CONFLICT ("CountryCode") DO NOTHING;
-- india , indonisia ,Veitenam
-- =============================================
-- SECTION 3: BUSINESS TYPES (ประเภทธุรกิจ)
-- =============================================

INSERT INTO "BusinessTypes" ("Id", "Code", "NameTh", "NameEn", "SortOrder", "IsActive") VALUES
(1, 'INDIVIDUAL', 'บุคคลธรรมดา', 'Individual', 1, TRUE),
(2, 'JURISTIC', 'นิติบุคคล', 'Juristic Person', 2, TRUE)
ON CONFLICT ("Id") DO NOTHING;

-- =============================================
-- SECTION 4: JOB TYPES (ประเภทงาน) - UPDATED
-- Now includes BUY, SELL, and BOTH options
-- =============================================

INSERT INTO "JobTypes" ("Id", "Code", "NameTh", "NameEn", "ForSupplier", "ForRfq", "PriceComparisonRule", "SortOrder", "IsActive") VALUES
(1, 'BUY', 'ซื้อ', 'Buy', TRUE, TRUE, 'MIN', 1, TRUE),
(2, 'SELL', 'ขาย', 'Sell', TRUE, TRUE, 'MAX', 2, TRUE),
(3, 'BOTH', 'ทั้งซื้อและขาย', 'Both Buy and Sell', TRUE, FALSE, NULL, 3, TRUE)  -- ForRfq=FALSE because RFQ must be either buy or sell
ON CONFLICT ("Id") DO NOTHING;

-- =============================================
-- SECTION 5: ROLES (บทบาท)
-- =============================================

INSERT INTO "Roles" ("Id", "RoleCode", "RoleNameTh", "RoleNameEn", "Description", "IsSystemRole", "IsActive") VALUES
(1, 'SUPER_ADMIN', 'ผู้ดูแลระบบสูงสุด', 'Super Administrator', 'Full system access', TRUE, TRUE),
(2, 'ADMIN', 'ผู้ดูแลระบบ', 'Administrator', 'Manage users and configurations, can be any role', TRUE, TRUE),
(3, 'REQUESTER', 'ผู้ขอซื้อ', 'Requester', 'Create and submit RFQs', FALSE, TRUE),
(4, 'APPROVER', 'ผู้อนุมัติ', 'Approver', 'Approve RFQs (Max 3 levels)', FALSE, TRUE),
(5, 'PURCHASING', 'จัดซื้อ', 'Purchasing', 'Manage suppliers and quotations', FALSE, TRUE),
(6, 'PURCHASING_APPROVER', 'ผู้อนุมัติจัดซื้อ', 'Purchasing Approver', 'Final approval (Max 3 levels)', FALSE, TRUE),
(7, 'SUPPLIER', 'ผู้ขาย', 'Supplier', 'External supplier role', FALSE, TRUE),
(8, 'MANAGING_DIRECTOR', 'ผู้บริหาร', 'Managing Director', 'View dashboards only', FALSE, TRUE)
ON CONFLICT ("Id") DO NOTHING;

-- =============================================
-- SECTION 6: PERMISSIONS (สิทธิ์การใช้งาน) - UPDATED
-- Added Thai names, removed unused permissions
-- =============================================

-- Note: Adding PermissionNameTh field to match new structure
-- If table doesn't have this column, add it first:
-- ALTER TABLE "Permissions" ADD COLUMN "PermissionNameTh" VARCHAR(100);

INSERT INTO "Permissions" ("Id", "PermissionCode", "PermissionName", "PermissionNameTh", "Module", "IsActive") VALUES
-- User Management
(1, 'USER_VIEW', 'View Users', 'ดูข้อมูลผู้ใช้', 'USER', TRUE),
(2, 'USER_CREATE', 'Create Users', 'สร้างผู้ใช้ใหม่', 'USER', TRUE),
(3, 'USER_EDIT', 'Edit Users', 'แก้ไขข้อมูลผู้ใช้', 'USER', TRUE),
(4, 'USER_DELETE', 'Delete Users', 'ลบ/ปิดการใช้งานผู้ใช้', 'USER', TRUE),
(5, 'USER_ROLE_ASSIGN', 'Assign Roles', 'กำหนดบทบาทให้ผู้ใช้', 'USER', TRUE),

-- RFQ Management (removed RFQ_DELETE as system auto-deletes)
(10, 'RFQ_VIEW_OWN', 'View Own RFQs', 'ดู RFQ ของตนเอง', 'RFQ', TRUE),
(11, 'RFQ_VIEW_DEPT', 'View Department RFQs', 'ดู RFQ ของแผนก', 'RFQ', TRUE),
(12, 'RFQ_VIEW_ALL', 'View All RFQs', 'ดู RFQ ทั้งหมด', 'RFQ', TRUE),
(13, 'RFQ_CREATE', 'Create RFQ', 'สร้าง RFQ ใหม่', 'RFQ', TRUE),
(14, 'RFQ_EDIT', 'Edit RFQ', 'แก้ไข RFQ', 'RFQ', TRUE),
-- (15, 'RFQ_DELETE', removed - system auto-deletes draft RFQs)
(16, 'RFQ_SUBMIT', 'Submit RFQ', 'ส่ง RFQ เข้าสู่การอนุมัติ', 'RFQ', TRUE),
(17, 'RFQ_APPROVE', 'Approve RFQ', 'อนุมัติ/ปฏิเสธ RFQ', 'RFQ', TRUE),
(18, 'RFQ_RE_BID', 'Re-bid RFQ', 'ขอเสนอราคาใหม่', 'RFQ', TRUE),
(19, 'RFQ_REVISE', 'Request Revision', 'ขอให้แก้ไข RFQ', 'RFQ', TRUE),

-- Supplier Management (removed SUPPLIER_EVALUATE)
(20, 'SUPPLIER_VIEW', 'View Suppliers', 'ดูข้อมูล Supplier', 'SUPPLIER', TRUE),
(21, 'SUPPLIER_CREATE', 'Create Suppliers', 'ลงทะเบียน Supplier ใหม่', 'SUPPLIER', TRUE),
(22, 'SUPPLIER_EDIT', 'Edit Suppliers', 'แก้ไขข้อมูล Supplier', 'SUPPLIER', TRUE),
(23, 'SUPPLIER_APPROVE', 'Approve Suppliers', 'อนุมัติการลงทะเบียน Supplier', 'SUPPLIER', TRUE),
(24, 'SUPPLIER_INVITE', 'Invite Suppliers', 'เชิญ Supplier เสนอราคา', 'SUPPLIER', TRUE),
-- (25, 'SUPPLIER_EVALUATE', removed - not in requirements)

-- Quotation Management
(30, 'QUOTE_VIEW', 'View Quotations', 'ดูใบเสนอราคา', 'QUOTE', TRUE),
(31, 'QUOTE_COMPARE', 'Compare Quotations', 'เปรียบเทียบใบเสนอราคา', 'QUOTE', TRUE),
(32, 'QUOTE_SELECT_WINNER', 'Select Winner', 'เลือกผู้ชนะการเสนอราคา', 'QUOTE', TRUE),
(33, 'QUOTE_EXPORT', 'Export Quotations', 'ส่งออกข้อมูลใบเสนอราคา', 'QUOTE', TRUE),
(34, 'QUOTE_INPUT_FOR_SUPPLIER', 'Input Quote for Supplier', 'ใส่ราคาแทน Supplier', 'QUOTE', TRUE),  -- Admin can input price for supplier

-- Dashboard (removed Reports)
(40, 'DASHBOARD_VIEW_OWN', 'View Own Dashboard', 'ดู Dashboard ของตนเอง', 'DASHBOARD', TRUE),
(41, 'DASHBOARD_VIEW_DEPT', 'View Department Dashboard', 'ดู Dashboard ของแผนก', 'DASHBOARD', TRUE),
(42, 'DASHBOARD_VIEW_ALL', 'View All Dashboards', 'ดู Dashboard ทั้งหมด', 'DASHBOARD', TRUE),
(43, 'DASHBOARD_EXECUTIVE', 'Executive Dashboard', 'Dashboard ผู้บริหาร', 'DASHBOARD', TRUE),

-- System Configuration
(50, 'CONFIG_VIEW', 'View Configuration', 'ดูการตั้งค่าระบบ', 'CONFIG', TRUE),
(51, 'CONFIG_EDIT', 'Edit Configuration', 'แก้ไขการตั้งค่าระบบ', 'CONFIG', TRUE),
(52, 'MASTER_DATA_MANAGE', 'Manage Master Data', 'จัดการข้อมูลหลัก', 'CONFIG', TRUE),
(53, 'AUDIT_LOG_VIEW', 'View Audit Logs', 'ดู Audit Logs', 'CONFIG', TRUE),
(54, 'CATEGORY_MANAGE', 'Manage Categories', 'จัดการ Category/Subcategory', 'CONFIG', TRUE)  -- Admin can add/edit categories
ON CONFLICT ("Id") DO NOTHING;

-- =============================================
-- SECTION 7: ROLE PERMISSIONS (สิทธิ์ตามบทบาท) - UPDATED
-- =============================================

-- SUPER_ADMIN: Full access
INSERT INTO "RolePermissions" ("RoleId", "PermissionId", "IsActive")
SELECT 1, "Id", TRUE FROM "Permissions";

-- ADMIN: Can do everything including being any role
INSERT INTO "RolePermissions" ("RoleId", "PermissionId", "IsActive")
SELECT 2, "Id", TRUE FROM "Permissions"
ON CONFLICT ("RoleId", "PermissionId") DO NOTHING;

-- REQUESTER: Create and manage own RFQs
INSERT INTO "RolePermissions" ("RoleId", "PermissionId", "IsActive") VALUES
(3, 10, TRUE),  -- View own RFQs
(3, 13, TRUE),  -- Create RFQ
(3, 14, TRUE),  -- Edit RFQ
(3, 16, TRUE),  -- Submit RFQ
(3, 40, TRUE)   -- View own dashboard
ON CONFLICT ("RoleId", "PermissionId") DO NOTHING;

-- APPROVER: Approve RFQs and view department data
INSERT INTO "RolePermissions" ("RoleId", "PermissionId", "IsActive") VALUES
(4, 11, TRUE),  -- View department RFQs
(4, 17, TRUE),  -- Approve RFQ
(4, 19, TRUE),  -- Request revision
(4, 41, TRUE)   -- View department dashboard
ON CONFLICT ("RoleId", "PermissionId") DO NOTHING;

-- PURCHASING: Review & Invite, Select Winners, Q&A (Cannot CRUD Suppliers)
INSERT INTO "RolePermissions" ("RoleId", "PermissionId", "IsActive") VALUES
(5, 10, TRUE), (5, 11, TRUE), (5, 12, TRUE),  -- View RFQs (all levels)
(5, 13, TRUE), (5, 14, TRUE), (5, 16, TRUE),  -- Create RFQ (as Requester for office supplies)
(5, 17, TRUE),  -- Approve/Reject/Decline (for Review & Invite)
(5, 18, TRUE),  -- Re-bid
(5, 19, TRUE),  -- Request revision (Declined)
(5, 20, TRUE),  -- View Suppliers ONLY (no create/edit/delete)
(5, 24, TRUE),  -- Invite Suppliers
(5, 30, TRUE), (5, 31, TRUE), (5, 32, TRUE), (5, 33, TRUE),  -- Quotations
(5, 40, TRUE), (5, 41, TRUE), (5, 42, TRUE)  -- Dashboards
ON CONFLICT ("RoleId", "PermissionId") DO NOTHING;

-- PURCHASING_APPROVER: Final approval (Max 3 levels), Re-Bid decision
INSERT INTO "RolePermissions" ("RoleId", "PermissionId", "IsActive") VALUES
(6, 12, TRUE),  -- View all RFQs
(6, 17, TRUE),  -- Approve/Reject (Final)
(6, 18, TRUE),  -- Re-bid decision
(6, 19, TRUE),  -- Request revision (Declined = send back to Purchasing)
(6, 23, TRUE),  -- Approve suppliers (2nd review)
(6, 30, TRUE), (6, 31, TRUE), (6, 32, TRUE),  -- View/Compare quotations, Select final winner
(6, 42, TRUE),  -- View all dashboards
(6, 43, TRUE)   -- Executive dashboard
ON CONFLICT ("RoleId", "PermissionId") DO NOTHING;

-- MANAGING_DIRECTOR: View dashboards only
INSERT INTO "RolePermissions" ("RoleId", "PermissionId", "IsActive") VALUES
(8, 12, TRUE),  -- View all RFQs
(8, 42, TRUE),  -- View all dashboards
(8, 43, TRUE)   -- Executive dashboard
ON CONFLICT ("RoleId", "PermissionId") DO NOTHING;

-- =============================================
-- SECTION 8: ROLE RESPONSE TIMES (SLA)
-- =============================================

INSERT INTO "RoleResponseTimes" ("RoleCode", "ResponseTimeDays", "Description", "IsActive") VALUES
('REQUESTER', 1, 'ระยะเวลาที่ REQUESTER ต้องดำเนินการ', TRUE),
('APPROVER', 2, 'ระยะเวลาที่ APPROVER ต้องอนุมัติ', TRUE),
('PURCHASING', 2, 'ระยะเวลาที่ PURCHASING ต้องดำเนินการ', TRUE),
('PURCHASING_APPROVER', 1, 'ระยะเวลาที่ PURCHASING_APPROVER ต้องอนุมัติ', TRUE),
('SUPPLIER', 3, 'ระยะเวลาที่ SUPPLIER ต้องเสนอราคา', TRUE)
ON CONFLICT ("RoleCode") DO NOTHING;

-- =============================================
-- SECTION 9: CATEGORIES (หมวดหมู่สินค้า)
-- =============================================

INSERT INTO "Categories" ("Id", "CategoryCode", "CategoryNameTh", "CategoryNameEn", "Description", "SortOrder", "IsActive") VALUES
(1, 'IT', 'เทคโนโลยีสารสนเทศ', 'Information Technology', 'IT equipment and services', 1, TRUE),
(2, 'OFFICE', 'อุปกรณ์สำนักงาน', 'Office Supplies', 'Office equipment and stationery', 2, TRUE),
(3, 'MRO', 'ซ่อมบำรุง', 'Maintenance & Repair', 'Maintenance, repair and operations', 3, TRUE),
(4, 'RAW_MAT', 'วัตถุดิบ', 'Raw Materials', 'Raw materials for production', 4, TRUE),
(5, 'PACKAGING', 'บรรจุภัณฑ์', 'Packaging', 'Packaging materials', 5, TRUE),
(6, 'MARKETING', 'การตลาด', 'Marketing', 'Marketing and promotional materials', 6, TRUE),
(7, 'SERVICES', 'บริการ', 'Services', 'Various services', 7, TRUE),
(8, 'CONSTRUCTION', 'ก่อสร้าง', 'Construction', 'Construction materials and services', 8, TRUE),
(9, 'TRANSPORT', 'ขนส่ง', 'Transportation', 'Transportation and logistics', 9, TRUE),
(10, 'SAFETY', 'ความปลอดภัย', 'Safety', 'Safety equipment and PPE', 10, TRUE),
(11, 'UNIFORM', 'ชุดยูนิฟอร์ม', 'Uniforms', 'Employee uniforms and workwear', 11, TRUE),
(12, 'ELECTRICAL', 'ระบบไฟฟ้า', 'Electrical Systems', 'Electrical equipment and systems', 12, TRUE)
ON CONFLICT ("Id") DO NOTHING;

-- =============================================
-- SECTION 10: SUBCATEGORIES (หมวดหมู่ย่อย) - UPDATED
-- Added IsUseSerialNumber field
-- =============================================

-- IT Subcategories
INSERT INTO "Subcategories" ("CategoryId", "SubcategoryCode", "SubcategoryNameTh", "SubcategoryNameEn", "IsUseSerialNumber", "Duration", "Description", "SortOrder", "IsActive") VALUES
(1, 'IT-HW-COM', 'คอมพิวเตอร์', 'Computers', TRUE, 7, 'Desktop and laptop computers', 1, TRUE),
(1, 'IT-HW-MON', 'จอภาพ', 'Monitors', TRUE, 5, 'Computer monitors and displays', 2, TRUE),
(1, 'IT-HW-PRT', 'เครื่องพิมพ์', 'Printers', TRUE, 5, 'Printers and scanners', 3, TRUE),
(1, 'IT-HW-NET', 'อุปกรณ์เครือข่าย', 'Network Equipment', TRUE, 7, 'Routers, switches, network devices', 4, TRUE),
(1, 'IT-SW-LIC', 'ซอฟต์แวร์ลิขสิทธิ์', 'Software Licenses', FALSE, 10, 'Software and licenses', 5, TRUE),
(1, 'IT-SVC-MA', 'บริการดูแลระบบ', 'IT Maintenance', FALSE, 14, 'IT maintenance services', 6, TRUE);

-- Office Supplies Subcategories
INSERT INTO "Subcategories" ("CategoryId", "SubcategoryCode", "SubcategoryNameTh", "SubcategoryNameEn", "IsUseSerialNumber", "Duration", "Description", "SortOrder", "IsActive") VALUES
(2, 'OFF-STAT', 'เครื่องเขียน', 'Stationery', FALSE, 3, 'Pens, papers, office stationery', 1, TRUE),
(2, 'OFF-PAPER', 'กระดาษ', 'Paper Products', FALSE, 3, 'All types of paper products', 2, TRUE),
(2, 'OFF-FURN', 'เฟอร์นิเจอร์', 'Office Furniture', TRUE, 14, 'Desks, chairs, cabinets', 3, TRUE),
(2, 'OFF-PANTRY', 'ของใช้ห้องครัว', 'Pantry Supplies', FALSE, 3, 'Kitchen and pantry supplies', 4, TRUE);

-- MRO Subcategories
INSERT INTO "Subcategories" ("CategoryId", "SubcategoryCode", "SubcategoryNameTh", "SubcategoryNameEn", "IsUseSerialNumber", "Duration", "Description", "SortOrder", "IsActive") VALUES
(3, 'MRO-ELEC', 'อุปกรณ์ไฟฟ้า', 'Electrical Equipment', TRUE, 7, 'Electrical tools and equipment', 1, TRUE),
(3, 'MRO-PLUMB', 'อุปกรณ์ประปา', 'Plumbing Equipment', FALSE, 7, 'Plumbing tools and materials', 2, TRUE),
(3, 'MRO-TOOLS', 'เครื่องมือ', 'Tools', TRUE, 5, 'Hand tools and power tools', 3, TRUE),
(3, 'MRO-SPARE', 'อะไหล่', 'Spare Parts', TRUE, 10, 'Spare parts for machinery', 4, TRUE);

-- Services Subcategories
INSERT INTO "Subcategories" ("CategoryId", "SubcategoryCode", "SubcategoryNameTh", "SubcategoryNameEn", "IsUseSerialNumber", "Duration", "Description", "SortOrder", "IsActive") VALUES
(7, 'SVC-CLEAN', 'บริการทำความสะอาด', 'Cleaning Services', FALSE, 7, 'Office cleaning services', 1, TRUE),
(7, 'SVC-SECURITY', 'บริการรักษาความปลอดภัย', 'Security Services', FALSE, 14, 'Security guard services', 2, TRUE),
(7, 'SVC-CONSULT', 'บริการที่ปรึกษา', 'Consulting Services', FALSE, 21, 'Business consulting services', 3, TRUE),
(7, 'SVC-TRAINING', 'บริการฝึกอบรม', 'Training Services', FALSE, 14, 'Employee training services', 4, TRUE);

-- Uniform Subcategories
INSERT INTO "Subcategories" ("CategoryId", "SubcategoryCode", "SubcategoryNameTh", "SubcategoryNameEn", "IsUseSerialNumber", "Duration", "Description", "SortOrder", "IsActive") VALUES
(11, 'UNI-SHIRT', 'เสื้อยูนิฟอร์ม', 'Uniform Shirts', FALSE, 14, 'Company uniform shirts', 1, TRUE),
(11, 'UNI-SUIT', 'ชุดสูท', 'Business Suits', FALSE, 21, 'Business suits for executives', 2, TRUE),
(11, 'UNI-SAFETY', 'ชุดเซฟตี้', 'Safety Uniforms', FALSE, 14, 'Safety wear and PPE uniforms', 3, TRUE);

-- Electrical Subcategories  
INSERT INTO "Subcategories" ("CategoryId", "SubcategoryCode", "SubcategoryNameTh", "SubcategoryNameEn", "IsUseSerialNumber", "Duration", "Description", "SortOrder", "IsActive") VALUES
(12, 'ELEC-LIGHT', 'ระบบไฟแสงสว่าง', 'Lighting Systems', FALSE, 14, 'Office lighting systems', 1, TRUE),
(12, 'ELEC-POWER', 'ระบบไฟฟ้ากำลัง', 'Power Systems', TRUE, 21, 'Electrical power systems', 2, TRUE),
(12, 'ELEC-BACKUP', 'ระบบสำรองไฟ', 'Backup Power Systems', TRUE, 21, 'UPS and generator systems', 3, TRUE)
ON CONFLICT ("CategoryId", "SubcategoryCode") DO NOTHING;

-- =============================================
-- SECTION 11: SUBCATEGORY DOCUMENT REQUIREMENTS
-- =============================================

-- IT Hardware Requirements
INSERT INTO "SubcategoryDocRequirements" ("SubcategoryId", "DocumentName", "DocumentNameEn", "IsRequired", "MaxFileSize", "AllowedExtensions", "SortOrder", "IsActive") VALUES
((SELECT "Id" FROM "Subcategories" WHERE "SubcategoryCode" = 'IT-HW-COM'), 'สเปคสินค้า', 'Product Specification', TRUE, 30, 'pdf,doc,docx', 1, TRUE),
((SELECT "Id" FROM "Subcategories" WHERE "SubcategoryCode" = 'IT-HW-COM'), 'ใบเสนอราคา', 'Quotation', TRUE, 30, 'pdf,xlsx,xls', 2, TRUE),
((SELECT "Id" FROM "Subcategories" WHERE "SubcategoryCode" = 'IT-HW-COM'), 'รับประกันสินค้า', 'Warranty Certificate', FALSE, 30, 'pdf', 3, TRUE);

-- Services Requirements
INSERT INTO "SubcategoryDocRequirements" ("SubcategoryId", "DocumentName", "DocumentNameEn", "IsRequired", "MaxFileSize", "AllowedExtensions", "SortOrder", "IsActive") VALUES
((SELECT "Id" FROM "Subcategories" WHERE "SubcategoryCode" = 'SVC-CONSULT'), 'ข้อเสนอโครงการ', 'Project Proposal', TRUE, 30, 'pdf,doc,docx', 1, TRUE),
((SELECT "Id" FROM "Subcategories" WHERE "SubcategoryCode" = 'SVC-CONSULT'), 'Profile บริษัท', 'Company Profile', TRUE, 30, 'pdf', 2, TRUE),
((SELECT "Id" FROM "Subcategories" WHERE "SubcategoryCode" = 'SVC-CONSULT'), 'ผลงานที่ผ่านมา', 'Past Projects', FALSE, 30, 'pdf', 3, TRUE)
ON CONFLICT DO NOTHING;

-- =============================================
-- SECTION 12: INCOTERMS
-- =============================================

INSERT INTO "Incoterms" ("IncotermCode", "IncotermName", "Description", "IsActive") VALUES
('EXW', 'Ex Works', 'ผู้ซื้อรับสินค้าที่โรงงานผู้ขาย', TRUE),
('FCA', 'Free Carrier', 'ผู้ขายส่งมอบสินค้าให้ผู้ขนส่งที่ผู้ซื้อกำหนด', TRUE),
('FAS', 'Free Alongside Ship', 'ผู้ขายส่งมอบสินค้าข้างเรือที่ท่าเรือต้นทาง', TRUE),
('FOB', 'Free On Board', 'ผู้ขายส่งมอบสินค้าบนเรือที่ท่าเรือต้นทาง', TRUE),
('CFR', 'Cost and Freight', 'ผู้ขายจ่ายค่าขนส่งถึงท่าเรือปลายทาง', TRUE),
('CIF', 'Cost Insurance and Freight', 'ผู้ขายจ่ายค่าขนส่งและประกันถึงท่าเรือปลายทาง', TRUE),
('CPT', 'Carriage Paid To', 'ผู้ขายจ่ายค่าขนส่งถึงจุดหมายที่กำหนด', TRUE),
('CIP', 'Carriage and Insurance Paid To', 'ผู้ขายจ่ายค่าขนส่งและประกันถึงจุดหมาย', TRUE),
('DAP', 'Delivered At Place', 'ผู้ขายส่งมอบสินค้าถึงสถานที่ปลายทาง', TRUE),
('DPU', 'Delivered At Place Unloaded', 'ผู้ขายส่งมอบและขนถ่ายสินค้า ณ สถานที่ปลายทาง', TRUE),
('DDP', 'Delivered Duty Paid', 'ผู้ขายส่งมอบสินค้าพร้อมเสียภาษีแล้ว', TRUE)
ON CONFLICT ("IncotermCode") DO NOTHING;

-- =============================================
-- SECTION 13: NOTIFICATION RULES - UPDATED
-- Based on actual notification examples from requirements
-- =============================================

-- REQUESTER Notifications
INSERT INTO "NotificationRules" ("RoleType", "EventType", "DaysAfterNoAction", "HoursBeforeDeadline", "NotifyRecipients", "Priority", "Channels", "TitleTemplate", "MessageTemplate", "IsActive") VALUES
('REQUESTER', 'DRAFT_EXPIRY_WARNING', NULL, 3, '{SELF}', 'HIGH', '{WEB}', 'แจ้งเตือน: ใบขอราคาใกล้หมดอายุ', 'ใบขอราคาของคุณ ที่บันทึกแบบร่างไว้ ใกล้จะหมดอายุแล้ว กรุณาตรวจสอบใบขอราคา ที่เมนู ดูใบขอราคา', TRUE),
('REQUESTER', 'APPROVED_BY_APPROVER', NULL, NULL, '{SELF}', 'NORMAL', '{WEB}', 'อนุมัติแล้ว', '{{RfqNumber}} {{ProjectName}} ผู้อนุมัติ ได้ทำการอนุมัติแล้ว ผู้จัดซื้อ กำลังดำเนินการอยู่', TRUE),
('REQUESTER', 'REVISION_REQUEST_APPROVER', NULL, NULL, '{SELF}', 'HIGH', '{WEB}', 'ขอแก้ไข', '{{RfqNumber}} {{ProjectName}} ผู้อนุมัติ ต้องการให้แก้ไขข้อมูล อีกครั้ง', TRUE),
('REQUESTER', 'REJECTED_BY_APPROVER', NULL, NULL, '{SELF}', 'HIGH', '{WEB}', 'ปฏิเสธ', '{{RfqNumber}} {{ProjectName}} ผู้อนุมัติ ได้ปฏิเสธ', TRUE),
('REQUESTER', 'APPROVED_BY_PURCHASING', NULL, NULL, '{SELF}', 'NORMAL', '{WEB}', 'ผู้จัดซื้ออนุมัติแล้ว', '{{RfqNumber}} {{ProjectName}} ผู้จัดซื้อ ได้อนุมัติแล้ว กำลังเชิญ Supplier เสนอราคาอยู่', TRUE),
('REQUESTER', 'REVISION_REQUEST_PURCHASING', NULL, NULL, '{SELF}', 'HIGH', '{WEB}', 'ผู้จัดซื้อขอแก้ไข', '{{RfqNumber}} {{ProjectName}} ผู้จัดซื้อ ต้องการให้แก้ไขข้อมูล อีกครั้ง', TRUE),
('REQUESTER', 'REJECTED_BY_PURCHASING', NULL, NULL, '{SELF}', 'HIGH', '{WEB}', 'ผู้จัดซื้อปฏิเสธ', '{{RfqNumber}} {{ProjectName}} ผู้จัดซื้อ ได้ปฏิเสธ', TRUE),
('REQUESTER', 'COMPLETED', NULL, NULL, '{SELF}', 'NORMAL', '{WEB}', 'เสร็จสิ้น', '{{RfqNumber}} {{ProjectName}} ผู้จัดการจัดซื้อ ได้ทำการอนุมัติ และได้เลือก Supplier แล้ว', TRUE),
('REQUESTER', 'REVISION_REQUEST_PURCHASING_APPROVER', NULL, NULL, '{SELF}', 'HIGH', '{WEB}', 'ผู้จัดการจัดซื้อขอแก้ไข', '{{RfqNumber}} {{ProjectName}} ผู้จัดการจัดซื้อ ต้องการให้แก้ไขข้อมูล อีกครั้ง', TRUE),
('REQUESTER', 'REJECTED_BY_PURCHASING_APPROVER', NULL, NULL, '{SELF}', 'HIGH', '{WEB}', 'ผู้จัดการจัดซื้อปฏิเสธ', '{{RfqNumber}} {{ProjectName}} ผู้จัดการจัดซื้อ ได้ปฏิเสธ', TRUE);

-- APPROVER Notifications
INSERT INTO "NotificationRules" ("RoleType", "EventType", "DaysAfterNoAction", "HoursBeforeDeadline", "NotifyRecipients", "Priority", "Channels", "TitleTemplate", "MessageTemplate", "IsActive") VALUES
('APPROVER', 'NEW_RFQ_APPROVAL', NULL, NULL, '{SELF}', 'HIGH', '{WEB}', 'รออนุมัติ', '{{RfqNumber}} {{ProjectName}} ผู้ร้องขอ ได้ส่งใบขอราคาให้คุณตรวจอนุมัติ', TRUE),
('APPROVER', 'RFQ_REVISED_BY_REQUESTER', NULL, NULL, '{SELF}', 'HIGH', '{WEB}', 'แก้ไขแล้ว', '{{RfqNumber}} {{ProjectName}} ผู้ร้องขอ ได้แก้ไขข้อมูลแล้ว อย่าลืมกดอนุมัติส่งไปยัง ผู้จัดซื้อ', TRUE),
('APPROVER', 'RFQ_COMPLETED', NULL, NULL, '{SELF}', 'NORMAL', '{WEB}', 'เสร็จสิ้น', '{{RfqNumber}} {{ProjectName}} ผู้จัดการจัดซื้อ ได้ทำการอนุมัติ และได้เลือก Supplier แล้ว', TRUE),
('APPROVER', 'PURCHASING_APPROVER_REQUEST_REVISION', NULL, NULL, '{SELF}', 'NORMAL', '{WEB}', 'ขอแก้ไข', '{{RfqNumber}} {{ProjectName}} ผู้จัดการจัดซื้อ ต้องการให้ ผู้ร้องขอ แก้ไขข้อมูล อีกครั้ง', TRUE),
('APPROVER', 'PURCHASING_APPROVER_REJECTED', NULL, NULL, '{SELF}', 'NORMAL', '{WEB}', 'ปฏิเสธ', '{{RfqNumber}} {{ProjectName}} ผู้จัดการจัดซื้อ ได้ปฏิเสธ ผู้ร้องขอ', TRUE),
('APPROVER', 'DEADLINE_WARNING_1DAY', NULL, 24, '{SELF}', 'HIGH', '{WEB}', 'เตือนใกล้ครบกำหนด', '{{RfqNumber}} {{ProjectName}} เหลืออีก 1 วัน จะครบกำหนด...', TRUE),
('APPROVER', 'DEADLINE_EXCEEDED', 1, NULL, '{SELF,SUPERVISOR}', 'URGENT', '{WEB,EMAIL}', 'เกินกำหนด', '{{RfqNumber}} {{ProjectName}} เกินกำหนดแล้ว ...', TRUE);

-- PURCHASING Notifications
INSERT INTO "NotificationRules" ("RoleType", "EventType", "DaysAfterNoAction", "HoursBeforeDeadline", "NotifyRecipients", "Priority", "Channels", "TitleTemplate", "MessageTemplate", "IsActive") VALUES
('PURCHASING', 'PURCHASING_APPROVER_APPROVED', NULL, NULL, '{SELF}', 'NORMAL', '{WEB}', 'อนุมัติแล้ว', '{{RfqNumber}} {{ProjectName}} ผู้จัดการจัดซื้อ ได้อนุมัติเรียบร้อยแล้ว', TRUE),
('PURCHASING', 'PURCHASING_APPROVER_REJECTED', NULL, NULL, '{SELF}', 'HIGH', '{WEB}', 'ปฏิเสธ', '{{RfqNumber}} {{ProjectName}} ผู้จัดการจัดซื้อ ปฏิเสธ', TRUE),
('PURCHASING', 'PURCHASING_APPROVER_REQUEST_REVISION', NULL, NULL, '{SELF}', 'HIGH', '{WEB}', 'ขอแก้ไข', '{{RfqNumber}} {{ProjectName}} ผู้จัดการจัดซื้อ ต้องการให้แก้ไข อีกครั้ง', TRUE),
('PURCHASING', 'SUPPLIER_REGISTERED_APPROVED', NULL, NULL, '{SELF}', 'NORMAL', '{WEB}', 'Supplier อนุมัติแล้ว', 'บริษัท {{SupplierName}} ผู้จัดการจัดซื้อ ได้อนุมัติการลงทะเบียน Supplier ใหม่ เรียบร้อยแล้ว', TRUE),
('PURCHASING', 'SUPPLIER_REGISTERED_REVISION', NULL, NULL, '{SELF}', 'HIGH', '{WEB}', 'แก้ไขข้อมูล Supplier', 'บริษัท {{SupplierName}} ผู้จัดการจัดซื้อ ต้องการให้แก้ไขข้อมูลการลงทะเบียน supplier อีกครั้ง', TRUE),
('PURCHASING', 'SUPPLIER_QNA', NULL, NULL, '{SELF}', 'HIGH', '{WEB}', 'มีคำถามจาก Supplier', 'มีคำถามจาก {{SupplierName}} ให้คุณตอบกลับ', TRUE),
('PURCHASING', 'DEADLINE_WARNING_1DAY', NULL, 24, '{SELF}', 'HIGH', '{WEB}', 'ใกล้ครบกำหนด', '{{RfqNumber}} {{ProjectName}} เหลืออีก 1 วัน จะครบกำหนด...', TRUE),
('PURCHASING', 'DEADLINE_EXCEEDED', 1, NULL, '{SELF,REQUESTER}', 'URGENT', '{WEB,EMAIL}', 'เกินกำหนด', '{{RfqNumber}} {{ProjectName}} เกินกำหนดแล้ว ...', TRUE);

-- SUPPLIER Notifications  
INSERT INTO "NotificationRules" ("RoleType", "EventType", "DaysAfterNoAction", "HoursBeforeDeadline", "NotifyRecipients", "Priority", "Channels", "TitleTemplate", "MessageTemplate", "IsActive") VALUES
('SUPPLIER', 'RFQ_INVITATION', NULL, NULL, '{SELF}', 'HIGH', '{EMAIL,SMS}', 'เชิญเสนอราคา', '{{RfqNumber}} {{ProjectName}} เชิญคุณ ร่วมเสนอราคา', TRUE),
('SUPPLIER', 'RFQ_INVITATION_REMINDER', 2, NULL, '{SELF}', 'HIGH', '{EMAIL}', 'เตือนเชิญเสนอราคา', '{{RfqNumber}} {{ProjectName}} เชิญคุณ ร่วมเสนอราคา ขณะนี้ ผ่านมาแล้ว 2 วัน', TRUE),
('SUPPLIER', 'SUBMISSION_DEADLINE_1DAY', NULL, 24, '{SELF}', 'HIGH', '{EMAIL,SMS}', 'ใกล้หมดเวลา', '{{RfqNumber}} {{ProjectName}} เหลืออีก 1 วัน จะหมดเวลาเสนอราคา', TRUE),
('SUPPLIER', 'SUBMISSION_DEADLINE_REACHED', NULL, 0, '{SELF}', 'URGENT', '{EMAIL}', 'หมดเวลาเสนอราคา', '{{RfqNumber}} {{ProjectName}} ขณะนี้ หมดเวลา เสนอราคาแล้ว', TRUE),
('SUPPLIER', 'QNA_RESPONSE', NULL, NULL, '{SELF}', 'NORMAL', '{EMAIL}', 'มีการตอบคำถาม', 'มีการตอบคำถามของคุณ คำถามของคุณเกี่ยวกับ {{ProjectName}} ได้รับการตอบแล้ว', TRUE);

-- PURCHASING_APPROVER Notifications
INSERT INTO "NotificationRules" ("RoleType", "EventType", "DaysAfterNoAction", "HoursBeforeDeadline", "NotifyRecipients", "Priority", "Channels", "TitleTemplate", "MessageTemplate", "IsActive") VALUES
('PURCHASING_APPROVER', 'WINNER_SELECTION_REQUEST', NULL, NULL, '{SELF}', 'HIGH', '{WEB}', 'รออนุมัติผู้ชนะ', '{{RfqNumber}} {{ProjectName}} จัดซื้อ ได้ส่งให้คุณอนุมัติเลือกผู้ชนะ', TRUE),
('PURCHASING_APPROVER', 'SUPPLIER_APPROVAL_REQUEST', NULL, NULL, '{SELF}', 'NORMAL', '{WEB}', 'รออนุมัติ Supplier', 'บริษัท {{SupplierName}} จัดซื้อ ได้ส่งให้คุณอนุมัติ', TRUE),
('PURCHASING_APPROVER', 'DEADLINE_WARNING_1DAY', NULL, 24, '{SELF}', 'HIGH', '{WEB}', 'ใกล้ครบกำหนด', '{{RfqNumber}} {{ProjectName}} เหลืออีก 1 วัน จะครบกำหนด...', TRUE),
('PURCHASING_APPROVER', 'DEADLINE_EXCEEDED', 1, NULL, '{SELF,SUPERVISOR}', 'URGENT', '{WEB,EMAIL}', 'เกินกำหนด', '{{RfqNumber}} {{ProjectName}} เกินกำหนดแล้ว ...', TRUE)
ON CONFLICT ("RoleType", "EventType") DO NOTHING;

-- =============================================
-- SECTION 14: POSITIONS (ตำแหน่งงาน)
-- =============================================

INSERT INTO "Positions" ("PositionCode", "PositionNameTh", "PositionNameEn", "PositionLevel", "DepartmentType", "DefaultApproverLevel", "CanActAsApproverLevels", "CanBeRequester", "CanBeApprover", "CanBePurchasing", "CanBePurchasingApprover", "IsActive") VALUES
-- Executive Level
('CEO', 'ประธานเจ้าหน้าที่บริหาร', 'Chief Executive Officer', 10, 'EXECUTIVE', 3, '{3}', FALSE, TRUE, FALSE, TRUE, TRUE),
('COO', 'ประธานเจ้าหน้าที่ปฏิบัติการ', 'Chief Operating Officer', 9, 'EXECUTIVE', 3, '{3}', FALSE, TRUE, FALSE, TRUE, TRUE),
('CFO', 'ประธานเจ้าหน้าที่การเงิน', 'Chief Financial Officer', 9, 'FINANCE', 3, '{3}', FALSE, TRUE, FALSE, TRUE, TRUE),

-- Management Level
('VP', 'รองประธาน', 'Vice President', 8, NULL, 3, '{2,3}', TRUE, TRUE, FALSE, TRUE, TRUE),
('AVP', 'ผู้ช่วยรองประธาน', 'Assistant Vice President', 7, NULL, 2, '{2,3}', TRUE, TRUE, FALSE, TRUE, TRUE),
('DIR', 'ผู้อำนวยการ', 'Director', 7, NULL, 2, '{2,3}', TRUE, TRUE, FALSE, TRUE, TRUE),
('SDIR', 'ผู้อำนวยการอาวุโส', 'Senior Director', 8, NULL, 3, '{2,3}', TRUE, TRUE, FALSE, TRUE, TRUE),

-- Department Heads
('DH', 'หัวหน้าแผนก', 'Department Head', 6, NULL, 2, '{1,2}', TRUE, TRUE, TRUE, TRUE, TRUE),
('SM', 'ผู้จัดการอาวุโส', 'Senior Manager', 6, NULL, 2, '{1,2}', TRUE, TRUE, TRUE, TRUE, TRUE),
('MGR', 'ผู้จัดการ', 'Manager', 5, NULL, 1, '{1,2}', TRUE, TRUE, TRUE, FALSE, TRUE),
('AM', 'ผู้ช่วยผู้จัดการ', 'Assistant Manager', 4, NULL, 1, '{1}', TRUE, TRUE, TRUE, FALSE, TRUE),

-- Supervisor Level
('SPV', 'หัวหน้างาน', 'Supervisor', 3, NULL, 1, '{1}', TRUE, TRUE, TRUE, FALSE, TRUE),
('TL', 'หัวหน้าทีม', 'Team Leader', 3, NULL, 1, '{1}', TRUE, TRUE, TRUE, FALSE, TRUE),

-- Officer Level
('SO', 'เจ้าหน้าที่อาวุโส', 'Senior Officer', 2, NULL, NULL, NULL, TRUE, FALSE, TRUE, FALSE, TRUE),
('OFF', 'เจ้าหน้าที่', 'Officer', 1, NULL, NULL, NULL, TRUE, FALSE, TRUE, FALSE, TRUE),
('JO', 'เจ้าหน้าที่ฝึกหัด', 'Junior Officer', 1, NULL, NULL, NULL, TRUE, FALSE, FALSE, FALSE, TRUE),

-- Purchasing Specific
('PM', 'ผู้จัดการจัดซื้อ', 'Purchasing Manager', 5, 'PURCHASING', 1, '{1}', TRUE, TRUE, TRUE, TRUE, TRUE),
('PO', 'เจ้าหน้าที่จัดซื้อ', 'Purchasing Officer', 2, 'PURCHASING', NULL, NULL, TRUE, FALSE, TRUE, FALSE, TRUE),
('SPO', 'เจ้าหน้าที่จัดซื้ออาวุโส', 'Senior Purchasing Officer', 3, 'PURCHASING', NULL, NULL, TRUE, FALSE, TRUE, FALSE, TRUE)
ON CONFLICT ("PositionCode") DO NOTHING;

-- =============================================
-- SECTION 15: EMAIL TEMPLATES - Based on actual workflow
-- =============================================

INSERT INTO "EmailTemplates" ("TemplateCode", "TemplateName", "Subject", "BodyHtml", "BodyText", "Variables", "Language", "IsActive") VALUES
-- Requester Templates (เคส 1-9 จาก PDF)
('APPROVER_APPROVED', 'Approver Approved', '{{RfqNumber}} {{ProjectName}} ผู้อนุมัติ ได้ทำการอนุมัติแล้ว ผู้จัดซื้อ กำลังดำเนินการอยู่ - eRFx',
'<p>{{RfqNumber}} {{ProjectName}}</p>
<p>ผู้อนุมัติ ได้ทำการอนุมัติแล้ว ผู้จัดซื้อ กำลังดำเนินการอยู่</p>
<p><a href="{{LoginLink}}">ดูใบขอราคา</a></p>',
'{{RfqNumber}} ผู้อนุมัติได้อนุมัติแล้ว',
'{RfqNumber,ProjectName,LoginLink}', 'th', TRUE),

('APPROVER_DECLINED', 'Approver Request Revision', '{{RfqNumber}} {{ProjectName}} ผู้อนุมัติ ต้องการให้แก้ไขข้อมูล อีกครั้ง - eRFx',
'<p>{{RfqNumber}} {{ProjectName}}</p>
<p>ผู้อนุมัติ ต้องการให้แก้ไขข้อมูล อีกครั้ง</p>
<p>เหตุผล: {{Reason}}</p>
<p><a href="{{LoginLink}}">ดูใบขอราคา</a></p>',
'{{RfqNumber}} ผู้อนุมัติขอให้แก้ไข',
'{RfqNumber,ProjectName,Reason,LoginLink}', 'th', TRUE),

('APPROVER_REJECTED', 'Approver Rejected', '{{RfqNumber}} {{ProjectName}} ผู้อนุมัติ ได้ปฏิเสธ - eRFx',
'<p>{{RfqNumber}} {{ProjectName}}</p>
<p>ผู้อนุมัติ ได้ปฏิเสธ</p>
<p>เหตุผล: {{Reason}}</p>
<p><a href="{{LoginLink}}">ดูใบขอราคา</a></p>',
'{{RfqNumber}} ผู้อนุมัติปฏิเสธ',
'{RfqNumber,ProjectName,Reason,LoginLink}', 'th', TRUE),

('PURCHASING_APPROVED', 'Purchasing Approved', '{{RfqNumber}} {{ProjectName}} ผู้จัดซื้อ ได้อนุมัติแล้ว กำลังเชิญ Supplier เสนอราคาอยู่ - eRFx',
'<p>{{RfqNumber}} {{ProjectName}}</p>
<p>ผู้จัดซื้อ ได้อนุมัติแล้ว กำลังเชิญ Supplier เสนอราคาอยู่</p>
<p><a href="{{LoginLink}}">ดูใบขอราคา</a></p>',
'{{RfqNumber}} ผู้จัดซื้ออนุมัติแล้ว',
'{RfqNumber,ProjectName,LoginLink}', 'th', TRUE),

('PURCHASING_DECLINED', 'Purchasing Request Revision', '{{RfqNumber}} {{ProjectName}} ผู้จัดซื้อ ต้องการให้แก้ไขข้อมูล อีกครั้ง - eRFx',
'<p>{{RfqNumber}} {{ProjectName}}</p>
<p>ผู้จัดซื้อ ต้องการให้แก้ไขข้อมูล อีกครั้ง</p>
<p>เหตุผล: {{Reason}}</p>
<p><a href="{{LoginLink}}">ดูใบขอราคา</a></p>',
'{{RfqNumber}} ผู้จัดซื้อขอให้แก้ไข',
'{RfqNumber,ProjectName,Reason,LoginLink}', 'th', TRUE),

('PURCHASING_REJECTED', 'Purchasing Rejected', '{{RfqNumber}} {{ProjectName}} ผู้จัดซื้อ ได้ปฏิเสธ - eRFx',
'<p>{{RfqNumber}} {{ProjectName}}</p>
<p>ผู้จัดซื้อ ได้ปฏิเสธ</p>
<p>เหตุผล: {{Reason}}</p>
<p><a href="{{LoginLink}}">ดูใบขอราคา</a></p>',
'{{RfqNumber}} ผู้จัดซื้อปฏิเสธ',
'{RfqNumber,ProjectName,Reason,LoginLink}', 'th', TRUE),

('PURCHASING_APPROVER_COMPLETED', 'Final Approval Completed', '{{RfqNumber}} {{ProjectName}} ผู้จัดการจัดซื้อ ได้ทำการอนุมัติ และได้เลือก Supplier แล้ว - eRFx',
'<p>{{RfqNumber}} {{ProjectName}}</p>
<p>ผู้จัดการจัดซื้อ ได้ทำการอนุมัติ และได้เลือก Supplier แล้ว</p>
<p>ผู้ชนะ: {{WinnerName}}</p>
<p><a href="{{LoginLink}}">ดูใบขอราคา</a></p>',
'{{RfqNumber}} เลือกผู้ชนะแล้ว',
'{RfqNumber,ProjectName,WinnerName,LoginLink}', 'th', TRUE),

('PURCHASING_APPROVER_DECLINED', 'Purchasing Approver Request Revision', '{{RfqNumber}} {{ProjectName}} ผู้จัดการจัดซื้อ ต้องการให้แก้ไขข้อมูล อีกครั้ง - eRFx',
'<p>{{RfqNumber}} {{ProjectName}}</p>
<p>ผู้จัดการจัดซื้อ ต้องการให้แก้ไขข้อมูล อีกครั้ง</p>
<p>เหตุผล: {{Reason}}</p>
<p><a href="{{LoginLink}}">ดูใบขอราคา</a></p>',
'{{RfqNumber}} ผู้จัดการจัดซื้อขอให้แก้ไข',
'{RfqNumber,ProjectName,Reason,LoginLink}', 'th', TRUE),

('PURCHASING_APPROVER_REJECTED', 'Purchasing Approver Rejected', '{{RfqNumber}} {{ProjectName}} ผู้จัดการจัดซื้อ ได้ปฏิเสธ - eRFx',
'<p>{{RfqNumber}} {{ProjectName}}</p>
<p>ผู้จัดการจัดซื้อ ได้ปฏิเสธ</p>
<p>เหตุผล: {{Reason}}</p>
<p><a href="{{LoginLink}}">ดูใบขอราคา</a></p>',
'{{RfqNumber}} ผู้จัดการจัดซื้อปฏิเสธ',
'{RfqNumber,ProjectName,Reason,LoginLink}', 'th', TRUE),

-- Supplier Templates (New Registration and Invitation)
('SUPPLIER_REGISTER_INVITE', 'เชิญลงทะเบียน Supplier', 'เชิญลงทะเบียน Supplier ใหม่ - eRFx',
'<p>เรียน คุณ {{ContactName}}</p>
<p>บริษัท ธีร์ โฮลดิง จำกัด</p>
<p>ขอเชิญท่าน ลงทะเบียนเป็น Supplier</p>
<ul>
<li>ชื่อบริษัท: {{CompanyName}}</li>
<li>อีเมล: {{Email}}</li>
<li>เบอร์โทร: {{Phone}}</li>
</ul>
<p>กรุณาลงทะเบียนการเข้าร่วมเสนอราคา กรุณาตำเนินการเพิ่มข้อมูล Supplier เพื่อเข้าร่วมเสนอราคา</p>
<p><a href="{{RegisterLink}}">ลงทะเบียน</a></p>',
'เชิญลงทะเบียน Supplier ใหม่',
'{ContactName,CompanyName,Email,Phone,RegisterLink}', 'th', TRUE),

('SUPPLIER_RFQ_INVITATION', 'เชิญเสนอราคา', '{{RfqNumber}} {{ProjectName}} เชิญคุณ ร่วมเสนอราคา - eRFx',
'<p>เรียน {{SupplierName}}</p>
<p>บริษัท {{RequesterCompany}}</p>
<p>ขอเชิญท่าน เข้าร่วมเสนอราคา</p>
<ul>
<li>เลขที่เอกสาร: {{RfqNumber}}</li>
<li>โครงการ: {{ProjectName}}</li>
<li>หมวดหมู่: {{CategoryName}} / {{SubcategoryName}}</li>
<li>กำหนดส่ง: {{SubmissionDeadline}}</li>
</ul>
<p>กรุณาลงทะเบียนการเข้าร่วมเสนอราคา กรุณาตำเนินการอย่างใดอย่างหนึ่ง</p>
<p>- กรุณาตอบรับเข้าร่วมการเสนอราคา<br>- กรุณาปฏิเสธการเข้าร่วม</p>
<p><a href="{{LoginLink}}">เข้าสู่ระบบ</a></p>',
'เชิญเสนอราคา {{RfqNumber}}',
'{SupplierName,RequesterCompany,RfqNumber,ProjectName,CategoryName,SubcategoryName,SubmissionDeadline,LoginLink}', 'th', TRUE),

-- Notification Templates for various events
('RFQ_SUBMISSION_DEADLINE_CHANGED', 'เปลี่ยนวันสิ้นสุดการเสนอราคา', '{{RfqNumber}} เปลี่ยนวันสิ้นสุดการเสนอราคา',
'<p>{{RfqNumber}} {{ProjectName}}</p>
<p>มีการเปลี่ยนแปลงวันสิ้นสุดการเสนอราคา</p>
<p>จาก: {{OldDate}}</p>
<p>เป็น: {{NewDate}}</p>
<p>เหตุผล: {{Reason}}</p>',
'เปลี่ยนวันสิ้นสุดการเสนอราคา {{RfqNumber}}',
'{RfqNumber,ProjectName,OldDate,NewDate,Reason}', 'th', TRUE),

('SUPPLIER_QNA_RESPONSE', 'ตอบคำถาม Supplier', 'มีการตอบคำถามของคุณ {{RfqNumber}}',
'<p>คำถามของคุณเกี่ยวกับ {{ProjectName}} ได้รับการตอบแล้ว</p>
<p>คำถาม: {{Question}}</p>
<p>คำตอบ: {{Answer}}</p>
<p><a href="{{LoginLink}}">ดูรายละเอียด</a></p>',
'ตอบคำถามของคุณแล้ว {{RfqNumber}}',
'{RfqNumber,ProjectName,Question,Answer,LoginLink}', 'th', TRUE)
ON CONFLICT ("TemplateCode") DO NOTHING;

-- =============================================
-- SECTION 16: SUPPLIER DOCUMENT TYPES
-- =============================================

-- Documents for Juristic Person (นิติบุคคล)
INSERT INTO "SupplierDocumentTypes" ("BusinessTypeId", "DocumentCode", "DocumentNameTh", "DocumentNameEn", "IsRequired", "SortOrder", "IsActive") VALUES
(2, 'CERT_REG', 'หนังสือรับรองบริษัท', 'Company Registration Certificate', TRUE, 1, TRUE),
(2, 'VAT_REG', 'ภ.พ.20', 'VAT Registration (Por Por 20)', TRUE, 2, TRUE),
(2, 'FINANCE_STMT', 'งบการเงิน', 'Financial Statements', TRUE, 3, TRUE),
(2, 'COMPANY_PROFILE', 'Company Profile', 'Company Profile', TRUE, 4, TRUE),
(2, 'NDA', 'ข้อตกลงรักษาความลับ', 'Non-Disclosure Agreement', TRUE, 5, TRUE),
(2, 'BANK_CERT', 'หนังสือรับรองบัญชีธนาคาร', 'Bank Account Certificate', FALSE, 6, TRUE),
(2, 'ISO_CERT', 'ใบรับรอง ISO', 'ISO Certificates', FALSE, 7, TRUE),
(2, 'LICENSE', 'ใบอนุญาตประกอบกิจการ', 'Business License', FALSE, 8, TRUE);

-- Documents for Individual (บุคคลธรรมดา)
INSERT INTO "SupplierDocumentTypes" ("BusinessTypeId", "DocumentCode", "DocumentNameTh", "DocumentNameEn", "IsRequired", "SortOrder", "IsActive") VALUES
(1, 'ID_CARD', 'สำเนาบัตรประชาชน', 'ID Card Copy', TRUE, 1, TRUE),
(1, 'NDA', 'ข้อตกลงรักษาความลับ', 'Non-Disclosure Agreement', TRUE, 2, TRUE),
(1, 'HOUSE_REG', 'สำเนาทะเบียนบ้าน', 'House Registration Copy', FALSE, 3, TRUE),
(1, 'BANK_BOOK', 'สำเนาสมุดบัญชีธนาคาร', 'Bank Book Copy', FALSE, 4, TRUE),
(1, 'TAX_CARD', 'บัตรประจำตัวผู้เสียภาษี', 'Tax Card', FALSE, 5, TRUE)
ON CONFLICT ("BusinessTypeId", "DocumentCode") DO NOTHING;

-- =============================================
-- SECTION 17: INITIAL EXCHANGE RATES
-- =============================================

-- Current exchange rates (as of January 2025) - Base currency THB
INSERT INTO "ExchangeRates" ("FromCurrencyId", "ToCurrencyId", "Rate", "EffectiveDate", "Source", "IsActive") VALUES
-- USD to THB
((SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'USD'), 
 (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'THB'), 
 34.50, CURRENT_DATE, 'MANUAL', TRUE),

-- EUR to THB
((SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'EUR'), 
 (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'THB'), 
 36.20, CURRENT_DATE, 'MANUAL', TRUE),

-- GBP to THB
((SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'GBP'), 
 (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'THB'), 
 42.80, CURRENT_DATE, 'MANUAL', TRUE),

-- JPY to THB
((SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'JPY'), 
 (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'THB'), 
 0.22, CURRENT_DATE, 'MANUAL', TRUE),

-- CNY to THB
((SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'CNY'), 
 (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'THB'), 
 4.73, CURRENT_DATE, 'MANUAL', TRUE),

-- SGD to THB
((SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'SGD'), 
 (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'THB'), 
 25.40, CURRENT_DATE, 'MANUAL', TRUE)
ON CONFLICT ("FromCurrencyId", "ToCurrencyId", "EffectiveDate") DO NOTHING;
-- =============================================
-- END OF MASTER DATA v6.2
-- =============================================

-- Summary Report
DO $$
BEGIN
  RAISE NOTICE '=========================================';
  RAISE NOTICE 'Master Data v6.2 Loading Complete';
  RAISE NOTICE '=========================================';
  RAISE NOTICE 'Total Records:';
  RAISE NOTICE 'Currencies: 10';
  RAISE NOTICE 'Countries: 10';
  RAISE NOTICE 'Business Types: 2';
  RAISE NOTICE 'Job Types: 3 (BUY, SELL, BOTH)';
  RAISE NOTICE 'Roles: 8';
  RAISE NOTICE 'Permissions: 54';
  RAISE NOTICE 'Categories: 12';
  RAISE NOTICE 'Subcategories: 25+';
  RAISE NOTICE 'Notification Rules: 40+';
  RAISE NOTICE '=========================================';
END $$;