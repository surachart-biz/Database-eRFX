-- =============================================
-- E-RFQ SYSTEM COMPLETE MASTER DATA v6.1
-- Database: PostgreSQL 14+
-- Created: January 2025
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

-- =============================================
-- SECTION 3: BUSINESS TYPES (ประเภทธุรกิจ)
-- =============================================

INSERT INTO "BusinessTypes" ("Id", "Code", "NameTh", "NameEn", "SortOrder", "IsActive") VALUES
(1, 'INDIVIDUAL', 'บุคคลธรรมดา', 'Individual', 1, TRUE),
(2, 'JURISTIC', 'นิติบุคคล', 'Juristic Person', 2, TRUE)
ON CONFLICT ("Id") DO NOTHING;

-- =============================================
-- SECTION 4: JOB TYPES (ประเภทงาน)
-- =============================================

INSERT INTO "JobTypes" ("Id", "Code", "NameTh", "NameEn", "ForSupplier", "ForRfq", "PriceComparisonRule", "SortOrder", "IsActive") VALUES
(1, 'BUY', 'ซื้อ', 'Buy', TRUE, TRUE, 'MIN', 1, TRUE),
(2, 'SELL', 'ขาย', 'Sell', TRUE, TRUE, 'MAX', 2, TRUE)
ON CONFLICT ("Id") DO NOTHING;

-- =============================================
-- SECTION 5: ROLES (บทบาท)
-- =============================================

INSERT INTO "Roles" ("Id", "RoleCode", "RoleNameTh", "RoleNameEn", "Description", "IsSystemRole", "IsActive") VALUES
(1, 'SUPER_ADMIN', 'ผู้ดูแลระบบสูงสุด', 'Super Administrator', 'Full system access', TRUE, TRUE),
(2, 'ADMIN', 'ผู้ดูแลระบบ', 'Administrator', 'Manage users and configurations', TRUE, TRUE),
(3, 'REQUESTER', 'ผู้ขอซื้อ', 'Requester', 'Create and submit RFQs', FALSE, TRUE),
(4, 'APPROVER', 'ผู้อนุมัติ', 'Approver', 'Approve RFQs (Max 3 levels)', FALSE, TRUE),
(5, 'PURCHASING', 'จัดซื้อ', 'Purchasing', 'Manage suppliers and quotations', FALSE, TRUE),
(6, 'PURCHASING_APPROVER', 'ผู้อนุมัติจัดซื้อ', 'Purchasing Approver', 'Final approval (Max 3 levels)', FALSE, TRUE),
(7, 'SUPPLIER', 'ผู้ขาย', 'Supplier', 'External supplier role', FALSE, TRUE),
(8, 'MANAGING_DIRECTOR', 'ผู้บริหาร', 'Managing Director', 'View dashboards and reports', FALSE, TRUE)
ON CONFLICT ("Id") DO NOTHING;

-- =============================================
-- SECTION 6: PERMISSIONS (สิทธิ์การใช้งาน)
-- =============================================

INSERT INTO "Permissions" ("Id", "PermissionCode", "PermissionName", "Module", "Description", "IsActive") VALUES
-- User Management
(1, 'USER_VIEW', 'View Users', 'USER', 'View user list and details', TRUE),
(2, 'USER_CREATE', 'Create Users', 'USER', 'Create new users', TRUE),
(3, 'USER_EDIT', 'Edit Users', 'USER', 'Edit user information', TRUE),
(4, 'USER_DELETE', 'Delete Users', 'USER', 'Delete/deactivate users', TRUE),
(5, 'USER_ROLE_ASSIGN', 'Assign Roles', 'USER', 'Assign roles to users', TRUE),

-- RFQ Management
(10, 'RFQ_VIEW_OWN', 'View Own RFQs', 'RFQ', 'View own created RFQs', TRUE),
(11, 'RFQ_VIEW_DEPT', 'View Department RFQs', 'RFQ', 'View department RFQs', TRUE),
(12, 'RFQ_VIEW_ALL', 'View All RFQs', 'RFQ', 'View all company RFQs', TRUE),
(13, 'RFQ_CREATE', 'Create RFQ', 'RFQ', 'Create new RFQ', TRUE),
(14, 'RFQ_EDIT', 'Edit RFQ', 'RFQ', 'Edit RFQ details', TRUE),
(15, 'RFQ_DELETE', 'Delete RFQ', 'RFQ', 'Delete draft RFQs', TRUE),
(16, 'RFQ_SUBMIT', 'Submit RFQ', 'RFQ', 'Submit RFQ for approval', TRUE),
(17, 'RFQ_APPROVE', 'Approve RFQ', 'RFQ', 'Approve/reject RFQs', TRUE),
(18, 'RFQ_RE_BID', 'Re-bid RFQ', 'RFQ', 'Initiate re-bidding', TRUE),

-- Supplier Management
(20, 'SUPPLIER_VIEW', 'View Suppliers', 'SUPPLIER', 'View supplier list', TRUE),
(21, 'SUPPLIER_CREATE', 'Create Suppliers', 'SUPPLIER', 'Register new suppliers', TRUE),
(22, 'SUPPLIER_EDIT', 'Edit Suppliers', 'SUPPLIER', 'Edit supplier information', TRUE),
(23, 'SUPPLIER_APPROVE', 'Approve Suppliers', 'SUPPLIER', 'Approve supplier registration', TRUE),
(24, 'SUPPLIER_INVITE', 'Invite Suppliers', 'SUPPLIER', 'Invite suppliers to RFQ', TRUE),
(25, 'SUPPLIER_EVALUATE', 'Evaluate Suppliers', 'SUPPLIER', 'Evaluate supplier performance', TRUE),

-- Quotation Management
(30, 'QUOTE_VIEW', 'View Quotations', 'QUOTE', 'View quotations', TRUE),
(31, 'QUOTE_COMPARE', 'Compare Quotations', 'QUOTE', 'Compare quotations', TRUE),
(32, 'QUOTE_SELECT_WINNER', 'Select Winner', 'QUOTE', 'Select winning quotation', TRUE),
(33, 'QUOTE_EXPORT', 'Export Quotations', 'QUOTE', 'Export quotation data', TRUE),

-- Reports & Dashboard
(40, 'REPORT_VIEW_OWN', 'View Own Reports', 'REPORT', 'View own reports', TRUE),
(41, 'REPORT_VIEW_DEPT', 'View Department Reports', 'REPORT', 'View department reports', TRUE),
(42, 'REPORT_VIEW_ALL', 'View All Reports', 'REPORT', 'View all reports', TRUE),
(43, 'DASHBOARD_VIEW', 'View Dashboard', 'DASHBOARD', 'View dashboard', TRUE),
(44, 'DASHBOARD_EXECUTIVE', 'Executive Dashboard', 'DASHBOARD', 'View executive dashboard', TRUE),

-- System Configuration
(50, 'CONFIG_VIEW', 'View Configuration', 'CONFIG', 'View system configuration', TRUE),
(51, 'CONFIG_EDIT', 'Edit Configuration', 'CONFIG', 'Edit system configuration', TRUE),
(52, 'MASTER_DATA_MANAGE', 'Manage Master Data', 'CONFIG', 'Manage master data', TRUE),
(53, 'AUDIT_LOG_VIEW', 'View Audit Logs', 'CONFIG', 'View audit logs', TRUE)
ON CONFLICT ("Id") DO NOTHING;

-- =============================================
-- SECTION 7: ROLE PERMISSIONS (สิทธิ์ตามบทบาท)
-- =============================================

-- SUPER_ADMIN: Full access
INSERT INTO "RolePermissions" ("RoleId", "PermissionId", "IsActive")
SELECT 1, "Id", TRUE FROM "Permissions";

-- ADMIN: User management and configuration
INSERT INTO "RolePermissions" ("RoleId", "PermissionId", "IsActive") VALUES
(2, 1, TRUE), (2, 2, TRUE), (2, 3, TRUE), (2, 4, TRUE), (2, 5, TRUE),  -- User management
(2, 10, TRUE), (2, 11, TRUE), (2, 12, TRUE),  -- View RFQs
(2, 20, TRUE), (2, 21, TRUE), (2, 22, TRUE), (2, 23, TRUE),  -- Supplier management
(2, 40, TRUE), (2, 41, TRUE), (2, 42, TRUE), (2, 43, TRUE),  -- Reports
(2, 50, TRUE), (2, 51, TRUE), (2, 52, TRUE), (2, 53, TRUE)  -- Configuration
ON CONFLICT ("RoleId", "PermissionId") DO NOTHING;

-- REQUESTER: Create and manage own RFQs
INSERT INTO "RolePermissions" ("RoleId", "PermissionId", "IsActive") VALUES
(3, 10, TRUE),  -- View own RFQs
(3, 13, TRUE),  -- Create RFQ
(3, 14, TRUE),  -- Edit RFQ
(3, 15, TRUE),  -- Delete draft
(3, 16, TRUE),  -- Submit RFQ
(3, 40, TRUE),  -- View own reports
(3, 43, TRUE)   -- View dashboard
ON CONFLICT ("RoleId", "PermissionId") DO NOTHING;

-- APPROVER: Approve RFQs
INSERT INTO "RolePermissions" ("RoleId", "PermissionId", "IsActive") VALUES
(4, 11, TRUE),  -- View department RFQs
(4, 17, TRUE),  -- Approve RFQ
(4, 41, TRUE),  -- View department reports
(4, 43, TRUE)   -- View dashboard
ON CONFLICT ("RoleId", "PermissionId") DO NOTHING;

-- PURCHASING: Manage suppliers and quotations
INSERT INTO "RolePermissions" ("RoleId", "PermissionId", "IsActive") VALUES
(5, 10, TRUE), (5, 11, TRUE), (5, 12, TRUE),  -- View RFQs
(5, 13, TRUE), (5, 14, TRUE), (5, 16, TRUE),  -- Create RFQ (for office supplies)
(5, 18, TRUE),  -- Re-bid
(5, 20, TRUE), (5, 21, TRUE), (5, 22, TRUE), (5, 24, TRUE), (5, 25, TRUE),  -- Suppliers
(5, 30, TRUE), (5, 31, TRUE), (5, 32, TRUE), (5, 33, TRUE),  -- Quotations
(5, 40, TRUE), (5, 41, TRUE), (5, 43, TRUE)  -- Reports
ON CONFLICT ("RoleId", "PermissionId") DO NOTHING;

-- PURCHASING_APPROVER: Final approval
INSERT INTO "RolePermissions" ("RoleId", "PermissionId", "IsActive") VALUES
(6, 12, TRUE),  -- View all RFQs
(6, 17, TRUE),  -- Approve
(6, 30, TRUE), (6, 31, TRUE),  -- View quotations
(6, 42, TRUE),  -- View all reports
(6, 43, TRUE)   -- View dashboard
ON CONFLICT ("RoleId", "PermissionId") DO NOTHING;

-- MANAGING_DIRECTOR: View only
INSERT INTO "RolePermissions" ("RoleId", "PermissionId", "IsActive") VALUES
(8, 12, TRUE),  -- View all RFQs
(8, 42, TRUE),  -- View all reports
(8, 43, TRUE),  -- View dashboard
(8, 44, TRUE)   -- Executive dashboard
ON CONFLICT ("RoleId", "PermissionId") DO NOTHING;

-- =============================================
-- SECTION 8: ROLE RESPONSE TIMES (SLA)
-- =============================================

INSERT INTO "RoleResponseTimes" ("RoleType", "ResponseTimeDays", "Description", "IsActive") VALUES
('REQUESTER', 1, 'ระยะเวลาที่ REQUESTER ต้องดำเนินการ', TRUE),
('APPROVER', 2, 'ระยะเวลาที่ APPROVER ต้องอนุมัติ', TRUE),
('PURCHASING', 2, 'ระยะเวลาที่ PURCHASING ต้องดำเนินการ', TRUE),
('PURCHASING_APPROVER', 1, 'ระยะเวลาที่ PURCHASING_APPROVER ต้องอนุมัติ', TRUE),
('SUPPLIER', 3, 'ระยะเวลาที่ SUPPLIER ต้องเสนอราคา', TRUE)
ON CONFLICT ("RoleType") DO NOTHING;

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
(10, 'SAFETY', 'ความปลอดภัย', 'Safety', 'Safety equipment and PPE', 10, TRUE)
ON CONFLICT ("Id") DO NOTHING;

-- =============================================
-- SECTION 10: SUBCATEGORIES (หมวดหมู่ย่อย)
-- =============================================

-- IT Subcategories
INSERT INTO "Subcategories" ("CategoryId", "SubcategoryCode", "SubcategoryNameTh", "SubcategoryNameEn", "RequireSpecification", "RequireBrand", "RequireModel", "Duration", "SortOrder", "IsActive") VALUES
(1, 'IT-HW-COM', 'คอมพิวเตอร์', 'Computers', TRUE, TRUE, TRUE, 7, 1, TRUE),
(1, 'IT-HW-MON', 'จอภาพ', 'Monitors', TRUE, TRUE, TRUE, 5, 2, TRUE),
(1, 'IT-HW-PRT', 'เครื่องพิมพ์', 'Printers', TRUE, TRUE, TRUE, 5, 3, TRUE),
(1, 'IT-HW-NET', 'อุปกรณ์เครือข่าย', 'Network Equipment', TRUE, TRUE, TRUE, 7, 4, TRUE),
(1, 'IT-SW-LIC', 'ซอฟต์แวร์ลิขสิทธิ์', 'Software Licenses', TRUE, FALSE, FALSE, 10, 5, TRUE),
(1, 'IT-SVC-MA', 'บริการดูแลระบบ', 'IT Maintenance', FALSE, FALSE, FALSE, 14, 6, TRUE);

-- Office Supplies Subcategories
INSERT INTO "Subcategories" ("CategoryId", "SubcategoryCode", "SubcategoryNameTh", "SubcategoryNameEn", "RequireSpecification", "RequireBrand", "RequireModel", "Duration", "SortOrder", "IsActive") VALUES
(2, 'OFF-STAT', 'เครื่องเขียน', 'Stationery', FALSE, FALSE, FALSE, 3, 1, TRUE),
(2, 'OFF-PAPER', 'กระดาษ', 'Paper Products', FALSE, TRUE, FALSE, 3, 2, TRUE),
(2, 'OFF-FURN', 'เฟอร์นิเจอร์', 'Office Furniture', TRUE, TRUE, TRUE, 14, 3, TRUE),
(2, 'OFF-PANTRY', 'ของใช้ห้องครัว', 'Pantry Supplies', FALSE, FALSE, FALSE, 3, 4, TRUE);

-- MRO Subcategories
INSERT INTO "Subcategories" ("CategoryId", "SubcategoryCode", "SubcategoryNameTh", "SubcategoryNameEn", "RequireSpecification", "RequireBrand", "RequireModel", "Duration", "SortOrder", "IsActive") VALUES
(3, 'MRO-ELEC', 'อุปกรณ์ไฟฟ้า', 'Electrical Equipment', TRUE, TRUE, FALSE, 7, 1, TRUE),
(3, 'MRO-PLUMB', 'อุปกรณ์ประปา', 'Plumbing Equipment', TRUE, TRUE, FALSE, 7, 2, TRUE),
(3, 'MRO-TOOLS', 'เครื่องมือ', 'Tools', TRUE, TRUE, TRUE, 5, 3, TRUE),
(3, 'MRO-SPARE', 'อะไหล่', 'Spare Parts', TRUE, TRUE, TRUE, 10, 4, TRUE);

-- Services Subcategories
INSERT INTO "Subcategories" ("CategoryId", "SubcategoryCode", "SubcategoryNameTh", "SubcategoryNameEn", "RequireSpecification", "RequireBrand", "RequireModel", "Duration", "SortOrder", "IsActive") VALUES
(7, 'SVC-CLEAN', 'บริการทำความสะอาด', 'Cleaning Services', TRUE, FALSE, FALSE, 7, 1, TRUE),
(7, 'SVC-SECURITY', 'บริการรักษาความปลอดภัย', 'Security Services', TRUE, FALSE, FALSE, 14, 2, TRUE),
(7, 'SVC-CONSULT', 'บริการที่ปรึกษา', 'Consulting Services', TRUE, FALSE, FALSE, 21, 3, TRUE),
(7, 'SVC-TRAINING', 'บริการฝึกอบรม', 'Training Services', TRUE, FALSE, FALSE, 14, 4, TRUE)
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
-- SECTION 13: NOTIFICATION RULES
-- =============================================

-- REQUESTER Notifications
INSERT INTO "NotificationRules" ("RoleType", "EventType", "DaysAfterNoAction", "HoursBeforeDeadline", "NotifyRecipients", "Priority", "Channels", "TitleTemplate", "MessageTemplate", "IsActive") VALUES
('REQUESTER', 'RFQ_DRAFT_REMINDER', 3, NULL, '{SELF}', 'NORMAL', '{EMAIL,WEB}', 'แจ้งเตือน: RFQ ฉบับร่างรอการส่ง', 'คุณมี RFQ เลขที่ {{RfqNumber}} ที่ยังไม่ได้ส่งเข้าสู่กระบวนการอนุมัติ', TRUE),
('REQUESTER', 'RFQ_APPROVED', NULL, NULL, '{SELF}', 'NORMAL', '{EMAIL,WEB}', 'RFQ ได้รับการอนุมัติ', 'RFQ เลขที่ {{RfqNumber}} ได้รับการอนุมัติแล้ว', TRUE),
('REQUESTER', 'RFQ_REJECTED', NULL, NULL, '{SELF}', 'HIGH', '{EMAIL,WEB}', 'RFQ ถูกปฏิเสธ', 'RFQ เลขที่ {{RfqNumber}} ถูกปฏิเสธ เหตุผล: {{Reason}}', TRUE),
('REQUESTER', 'RFQ_COMPLETED', NULL, NULL, '{SELF}', 'NORMAL', '{EMAIL,WEB}', 'RFQ ดำเนินการเสร็จสิ้น', 'RFQ เลขที่ {{RfqNumber}} ดำเนินการเสร็จสิ้นแล้ว', TRUE);

-- APPROVER Notifications
INSERT INTO "NotificationRules" ("RoleType", "EventType", "DaysAfterNoAction", "HoursBeforeDeadline", "NotifyRecipients", "Priority", "Channels", "TitleTemplate", "MessageTemplate", "IsActive") VALUES
('APPROVER', 'RFQ_PENDING_APPROVAL', NULL, NULL, '{SELF}', 'HIGH', '{EMAIL,WEB}', 'รออนุมัติ: RFQ ใหม่', 'มี RFQ เลขที่ {{RfqNumber}} รอการอนุมัติจากคุณ', TRUE),
('APPROVER', 'RFQ_APPROVAL_REMINDER', 1, NULL, '{SELF,SUPERVISOR}', 'HIGH', '{EMAIL,WEB}', 'เตือน: RFQ รออนุมัติเกิน 1 วัน', 'RFQ เลขที่ {{RfqNumber}} รอการอนุมัติเกิน 1 วันแล้ว', TRUE),
('APPROVER', 'RFQ_DEADLINE_WARNING', NULL, 24, '{SELF,REQUESTER}', 'URGENT', '{EMAIL,WEB,SMS}', 'ด่วน: RFQ ใกล้ครบกำหนด', 'RFQ เลขที่ {{RfqNumber}} จะครบกำหนดใน 24 ชั่วโมง', TRUE);

-- PURCHASING Notifications
INSERT INTO "NotificationRules" ("RoleType", "EventType", "DaysAfterNoAction", "HoursBeforeDeadline", "NotifyRecipients", "Priority", "Channels", "TitleTemplate", "MessageTemplate", "IsActive") VALUES
('PURCHASING', 'RFQ_READY_FOR_INVITE', NULL, NULL, '{SELF}', 'NORMAL', '{EMAIL,WEB}', 'RFQ พร้อมเชิญ Supplier', 'RFQ เลขที่ {{RfqNumber}} พร้อมสำหรับการเชิญ Supplier', TRUE),
('PURCHASING', 'SUPPLIER_QNA', NULL, NULL, '{SELF}', 'HIGH', '{EMAIL,WEB}', 'มีคำถามจาก Supplier', 'Supplier {{SupplierName}} มีคำถามเกี่ยวกับ RFQ {{RfqNumber}}', TRUE),
('PURCHASING', 'QUOTATION_RECEIVED', NULL, NULL, '{SELF}', 'NORMAL', '{EMAIL,WEB}', 'ได้รับใบเสนอราคาใหม่', 'ได้รับใบเสนอราคาจาก {{SupplierName}} สำหรับ RFQ {{RfqNumber}}', TRUE),
('PURCHASING', 'SUBMISSION_DEADLINE_REACHED', NULL, 0, '{SELF,REQUESTER}', 'HIGH', '{EMAIL,WEB}', 'ครบกำหนดรับใบเสนอราคา', 'RFQ {{RfqNumber}} ครบกำหนดรับใบเสนอราคาแล้ว', TRUE);

-- SUPPLIER Notifications
INSERT INTO "NotificationRules" ("RoleType", "EventType", "DaysAfterNoAction", "HoursBeforeDeadline", "NotifyRecipients", "Priority", "Channels", "TitleTemplate", "MessageTemplate", "IsActive") VALUES
('SUPPLIER', 'RFQ_INVITATION', NULL, NULL, '{SELF}', 'HIGH', '{EMAIL,SMS}', 'คำเชิญเสนอราคา', 'คุณได้รับเชิญให้เสนอราคา RFQ {{RfqNumber}}', TRUE),
('SUPPLIER', 'RFQ_DEADLINE_REMINDER', NULL, 48, '{SELF}', 'HIGH', '{EMAIL,SMS}', 'เตือน: ใกล้หมดเวลาเสนอราคา', 'RFQ {{RfqNumber}} จะปิดรับใบเสนอราคาใน 48 ชั่วโมง', TRUE),
('SUPPLIER', 'QNA_RESPONSE', NULL, NULL, '{SELF}', 'NORMAL', '{EMAIL}', 'มีการตอบคำถามของคุณ', 'คำถามของคุณเกี่ยวกับ RFQ {{RfqNumber}} ได้รับการตอบแล้ว', TRUE),
('SUPPLIER', 'WINNER_ANNOUNCEMENT', NULL, NULL, '{SELF}', 'HIGH', '{EMAIL,SMS}', 'ประกาศผู้ชนะการเสนอราคา', 'ผลการพิจารณา RFQ {{RfqNumber}}', TRUE)
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
-- SECTION 15: EMAIL TEMPLATES
-- =============================================

INSERT INTO "EmailTemplates" ("TemplateCode", "TemplateName", "Subject", "BodyHtml", "BodyText", "Variables", "Language", "IsActive") VALUES
-- Thai Templates
('RFQ_SUBMIT_TH', 'RFQ Submission (Thai)', 'แจ้งส่ง RFQ เลขที่ {{RfqNumber}}', 
'<p>เรียน {{RecipientName}}</p>
<p>มี RFQ ใหม่รอการพิจารณา:</p>
<ul>
<li>เลขที่: {{RfqNumber}}</li>
<li>โครงการ: {{ProjectName}}</li>
<li>ผู้ขอ: {{RequesterName}}</li>
<li>วันที่ต้องการ: {{RequiredDate}}</li>
</ul>
<p>กรุณาเข้าสู่ระบบเพื่อพิจารณา</p>', 
'เรียน {{RecipientName}}\nมี RFQ ใหม่รอการพิจารณา\nเลขที่: {{RfqNumber}}\nโครงการ: {{ProjectName}}',
'{RecipientName,RfqNumber,ProjectName,RequesterName,RequiredDate}', 'th', TRUE),

('SUPPLIER_INVITE_TH', 'Supplier Invitation (Thai)', 'เชิญเสนอราคา RFQ {{RfqNumber}}',
'<p>เรียน {{SupplierName}}</p>
<p>บริษัทขอเชิญท่านเสนอราคาสำหรับ:</p>
<ul>
<li>RFQ เลขที่: {{RfqNumber}}</li>
<li>โครงการ: {{ProjectName}}</li>
<li>ประเภท: {{CategoryName}}</li>
<li>กำหนดส่ง: {{SubmissionDeadline}}</li>
</ul>
<p><a href="{{LoginLink}}">คลิกที่นี่เพื่อเข้าสู่ระบบ</a></p>',
'เรียน {{SupplierName}}\nเชิญเสนอราคา RFQ {{RfqNumber}}\nกำหนดส่ง: {{SubmissionDeadline}}',
'{SupplierName,RfqNumber,ProjectName,CategoryName,SubmissionDeadline,LoginLink}', 'th', TRUE),

-- English Templates
('RFQ_SUBMIT_EN', 'RFQ Submission (English)', 'New RFQ {{RfqNumber}} for Review',
'<p>Dear {{RecipientName}},</p>
<p>A new RFQ requires your attention:</p>
<ul>
<li>Number: {{RfqNumber}}</li>
<li>Project: {{ProjectName}}</li>
<li>Requester: {{RequesterName}}</li>
<li>Required Date: {{RequiredDate}}</li>
</ul>
<p>Please login to review.</p>',
'Dear {{RecipientName}}\nNew RFQ for review\nNumber: {{RfqNumber}}\nProject: {{ProjectName}}',
'{RecipientName,RfqNumber,ProjectName,RequesterName,RequiredDate}', 'en', TRUE),

('SUPPLIER_INVITE_EN', 'Supplier Invitation (English)', 'Invitation to Quote - RFQ {{RfqNumber}}',
'<p>Dear {{SupplierName}},</p>
<p>You are invited to submit a quotation for:</p>
<ul>
<li>RFQ Number: {{RfqNumber}}</li>
<li>Project: {{ProjectName}}</li>
<li>Category: {{CategoryName}}</li>
<li>Deadline: {{SubmissionDeadline}}</li>
</ul>
<p><a href="{{LoginLink}}">Click here to login</a></p>',
'Dear {{SupplierName}}\nQuotation invitation for RFQ {{RfqNumber}}\nDeadline: {{SubmissionDeadline}}',
'{SupplierName,RfqNumber,ProjectName,CategoryName,SubmissionDeadline,LoginLink}', 'en', TRUE)
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
-- SECTION 18: DEMO COMPANY DATA (Optional)
-- =============================================

-- Demo Company
INSERT INTO "Companies" (
  "CompanyCode", "CompanyNameTh", "CompanyNameEn", "ShortNameEn",
  "TaxId", "CountryId", "DefaultCurrencyId", "BusinessTypeId",
  "RegisteredCapital", "RegisteredCapitalCurrencyId",
  "AddressLine1", "City", "Province", "PostalCode",
  "Phone", "Email", "Website", "Status", "IsActive"
) VALUES (
  'DEMO001', 'บริษัท ตัวอย่าง จำกัด', 'Demo Company Limited', 'DEMO',
  '0105500000001', 
  (SELECT "Id" FROM "Countries" WHERE "CountryCode" = 'TH'),
  (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'THB'),
  2, -- Juristic Person
  10000000.00,
  (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'THB'),
  '123 Demo Tower, Sukhumvit Road', 'Bangkok', 'Bangkok', '10110',
  '02-123-4567', 'info@democompany.co.th', 'www.democompany.co.th',
  'ACTIVE', TRUE
) ON CONFLICT ("CompanyCode") DO NOTHING;

-- Demo Departments
INSERT INTO "Departments" ("CompanyId", "DepartmentCode", "DepartmentNameTh", "DepartmentNameEn", "CostCenter", "IsActive")
SELECT 
  c."Id", dept."DepartmentCode", dept."DepartmentNameTh", dept."DepartmentNameEn", dept."CostCenter", TRUE
FROM "Companies" c,
(VALUES
  ('IT', 'เทคโนโลยีสารสนเทศ', 'Information Technology', 'CC-IT'),
  ('HR', 'ทรัพยากรบุคคล', 'Human Resources', 'CC-HR'),
  ('FIN', 'การเงิน', 'Finance', 'CC-FIN'),
  ('PUR', 'จัดซื้อ', 'Purchasing', 'CC-PUR'),
  ('MKT', 'การตลาด', 'Marketing', 'CC-MKT'),
  ('PROD', 'ผลิต', 'Production', 'CC-PROD'),
  ('ADMIN', 'ธุรการ', 'Administration', 'CC-ADMIN')
) AS dept("DepartmentCode", "DepartmentNameTh", "DepartmentNameEn", "CostCenter")
WHERE c."CompanyCode" = 'DEMO001'
ON CONFLICT ("CompanyId", "DepartmentCode") DO NOTHING;

-- =============================================
-- END OF MASTER DATA
-- =============================================

-- Summary Report
DO $$
BEGIN
  RAISE NOTICE '=========================================';
  RAISE NOTICE 'Master Data Loading Complete';
  RAISE NOTICE '=========================================';
  RAISE NOTICE 'Currencies: 10 records';
  RAISE NOTICE 'Countries: 10 records';
  RAISE NOTICE 'Business Types: 2 records';
  RAISE NOTICE 'Job Types: 2 records';
  RAISE NOTICE 'Roles: 8 records';
  RAISE NOTICE 'Permissions: 53 records';
  RAISE NOTICE 'Categories: 10 records';
  RAISE NOTICE 'Subcategories: 20+ records';
  RAISE NOTICE 'Incoterms: 11 records';
  RAISE NOTICE 'Positions: 20 records';
  RAISE NOTICE 'Email Templates: 4+ records';
  RAISE NOTICE 'Notification Rules: 16+ records';
  RAISE NOTICE 'Exchange Rates: 6 records';
  RAISE NOTICE '=========================================';
END $$;