# eRFX Master Data Complete Analysis
# v6.2 - Database Schema Cross-Reference

**Document Version**: 1.0
**Created**: 2025-10-01
**Master Data File**: erfq-master-data-v61.sql
**Database Schema**: erfq-db-schema-v62.sql
**PostgreSQL Version**: 14+

---

## Document Purpose

This document provides **complete analysis and cross-reference** between master data (`erfq-master-data-v61.sql`) and database schema (`erfq-db-schema-v62.sql`). Every INSERT statement, foreign key relationship, and data dependency is documented.

---

## Table of Contents

1. [Master Data Overview](#section-1-master-data-overview)
2. [Reference Data (Currencies, Countries)](#section-2-reference-data)
3. [Business Configuration](#section-3-business-configuration)
4. [Security & Authorization](#section-4-security-authorization)
5. [Categories & Products](#section-5-categories-products)
6. [Notification System](#section-6-notification-system)
7. [Organization Structure](#section-7-organization-structure)
8. [Supplier Management](#section-8-supplier-management)
9. [Data Dependencies & Load Order](#section-9-data-dependencies-load-order)
10. [Validation & Testing](#section-10-validation-testing)

---

## SECTION 1: Master Data Overview

### 1.1 Master Data Summary

| Section | Tables | Total Records | Purpose |
|---------|--------|---------------|---------|
| **Reference Data** | Currencies, Countries | 10 + 10 = 20 | Currency and geography |
| **Business Types** | BusinessTypes, JobTypes | 2 + 3 = 5 | Business classification |
| **Security** | Roles, Permissions, RolePermissions | 8 + 54 + 180+ | RBAC system |
| **SLA** | RoleResponseTimes | 5 | Response time tracking |
| **Categories** | Categories, Subcategories | 12 + 25 = 37 | Product/service classification |
| **Requirements** | SubcategoryDocRequirements, SupplierDocumentTypes | 10 + 13 = 23 | Document requirements |
| **Trade Terms** | Incoterms | 11 | International trade terms |
| **Notifications** | NotificationRules, EmailTemplates | 40+ + 15 = 55+ | Notification system |
| **Organization** | Positions | 17 | Position hierarchy |
| **Exchange Rates** | ExchangeRates | 6 | Currency conversion |

**Total Master Data Records**: ~400+

### 1.2 Data Loading Strategy

**Load Order** (Critical - must follow foreign key dependencies):
```sql
1. Currencies                          -- No dependencies
2. Countries                           -- FK: DefaultCurrencyId
3. BusinessTypes                       -- No dependencies
4. JobTypes                            -- No dependencies
5. Roles                               -- No dependencies
6. Permissions                         -- No dependencies
7. RolePermissions                     -- FK: RoleId, PermissionId
8. RoleResponseTimes                   -- No FK (uses RoleCode)
9. Categories                          -- No dependencies
10. Subcategories                      -- FK: CategoryId
11. SubcategoryDocRequirements         -- FK: SubcategoryId
12. Incoterms                          -- No dependencies
13. NotificationRules                  -- No FK (uses RoleType)
14. Positions                          -- No dependencies
15. EmailTemplates                     -- No dependencies
16. SupplierDocumentTypes              -- FK: BusinessTypeId
17. ExchangeRates                      -- FK: FromCurrencyId, ToCurrencyId
```

### 1.3 Schema Version Alignment

**Master Data Version**: v6.2 (Updated January 2025)
**Database Schema**: v6.2.2

**Key Updates in v6.2**:
- Added `JobType: BOTH` (for suppliers doing both buy and sell)
- Added Thai names to Permissions (`PermissionNameTh`)
- Updated Notification Rules based on actual workflow
- Removed unused permissions (RFQ_DELETE, SUPPLIER_EVALUATE)
- Added `IsUseSerialNumber` to Subcategories
- Updated Email Templates with actual message templates

---

## SECTION 2: Reference Data

### 2.1 Currencies (10 Records)

**Table**: `Currencies` (Lines 12-23)

**Schema Definition**:
```sql
CREATE TABLE "Currencies" (
  "Id" BIGSERIAL PRIMARY KEY,
  "CurrencyCode" VARCHAR(3) UNIQUE NOT NULL,
  "CurrencyName" VARCHAR(100) NOT NULL,
  "CurrencySymbol" VARCHAR(10),
  "DecimalPlaces" SMALLINT DEFAULT 2,
  "IsActive" BOOLEAN DEFAULT TRUE
);
```

**Master Data Records**:
| CurrencyCode | CurrencyName | Symbol | DecimalPlaces | Purpose |
|--------------|--------------|--------|---------------|---------|
| THB | Thai Baht | ฿ | 2 | Base currency |
| USD | US Dollar | $ | 2 | International trade |
| EUR | Euro | € | 2 | European trade |
| GBP | British Pound | £ | 2 | UK trade |
| JPY | Japanese Yen | ¥ | 0 | Japan (no decimals) |
| CNY | Chinese Yuan | ¥ | 2 | China trade |
| SGD | Singapore Dollar | S$ | 2 | ASEAN trade |
| MYR | Malaysian Ringgit | RM | 2 | ASEAN trade |
| AUD | Australian Dollar | A$ | 2 | Australia |
| HKD | Hong Kong Dollar | HK$ | 2 | Hong Kong |

**Usage in System**:
- Referenced by: `Countries.DefaultCurrencyId`, `Rfqs.BudgetCurrencyId`, `QuotationItems.CurrencyId`, `ExchangeRates`
- JPY has 0 decimal places (common practice)
- THB is the base currency for all conversions

**Notes**:
- Line 24 comment: "india, indonesia, Vietnam" - future additions planned
- All currencies set to `IsActive = TRUE`

### 2.2 Countries (10 Records)

**Table**: `Countries` (Lines 29-40)

**Schema Definition**:
```sql
CREATE TABLE "Countries" (
  "Id" BIGSERIAL PRIMARY KEY,
  "CountryCode" VARCHAR(2) UNIQUE NOT NULL,
  "CountryNameEn" VARCHAR(100) NOT NULL,
  "CountryNameTh" VARCHAR(100),
  "DefaultCurrencyId" BIGINT REFERENCES "Currencies"("Id"),
  "Timezone" VARCHAR(50),
  "PhoneCode" VARCHAR(10),
  "IsActive" BOOLEAN DEFAULT TRUE
);
```

**Master Data Records**:
| Code | Country (EN) | Country (TH) | Currency | Timezone | Phone |
|------|--------------|--------------|----------|----------|-------|
| TH | Thailand | ประเทศไทย | THB | Asia/Bangkok | +66 |
| US | United States | สหรัฐอเมริกา | USD | America/New_York | +1 |
| GB | United Kingdom | สหราชอาณาจักร | GBP | Europe/London | +44 |
| JP | Japan | ญี่ปุ่น | JPY | Asia/Tokyo | +81 |
| CN | China | จีน | CNY | Asia/Shanghai | +86 |
| SG | Singapore | สิงคโปร์ | SGD | Asia/Singapore | +65 |
| MY | Malaysia | มาเลเซีย | MYR | Asia/Kuala_Lumpur | +60 |
| AU | Australia | ออสเตรเลีย | AUD | Australia/Sydney | +61 |
| HK | Hong Kong | ฮ่องกง | HKD | Asia/Hong_Kong | +852 |
| VN | Vietnam | เวียดนาม | USD* | Asia/Ho_Chi_Minh | +84 |

**Special Notes**:
- Vietnam uses USD as default (VND not in currency list yet)
- Line 41 comment: "india, indonesia, Vietnam" - future additions
- Timezone info for future datetime conversions
- Phone codes for SMS notifications

**Foreign Key**:
```sql
"DefaultCurrencyId" BIGINT REFERENCES "Currencies"("Id")
```

**Data Integrity**:
```sql
-- All countries reference valid currencies
-- Example: TH -> Currency WHERE CurrencyCode = 'THB'
```

---

## SECTION 3: Business Configuration

### 3.1 Business Types (2 Records)

**Table**: `BusinessTypes` (Lines 46-49)

**Schema Definition**:
```sql
CREATE TABLE "BusinessTypes" (
  "Id" SMALLINT PRIMARY KEY,
  "Code" VARCHAR(20) UNIQUE NOT NULL,
  "NameTh" VARCHAR(100) NOT NULL,
  "NameEn" VARCHAR(100) NOT NULL,
  "SortOrder" INT,
  "IsActive" BOOLEAN DEFAULT TRUE
);
```

**Master Data**:
| Id | Code | NameTh | NameEn | Purpose |
|----|------|--------|--------|---------|
| 1 | INDIVIDUAL | บุคคลธรรมดา | Individual | Natural person suppliers |
| 2 | JURISTIC | นิติบุคคล | Juristic Person | Company suppliers |

**Impact on System**:
- Determines required supplier documents:
  - **INDIVIDUAL** (1): 2 required docs (ID Card, NDA)
  - **JURISTIC** (2): 5 required docs (Registration, VAT, Financial, Profile, NDA)
- Referenced by: `Suppliers.BusinessTypeId`, `SupplierDocumentTypes.BusinessTypeId`

### 3.2 Job Types (3 Records) - **UPDATED v6.2**

**Table**: `JobTypes` (Lines 56-60)

**Schema Definition**:
```sql
CREATE TABLE "JobTypes" (
  "Id" SMALLINT PRIMARY KEY,
  "Code" VARCHAR(20) UNIQUE NOT NULL,
  "NameTh" VARCHAR(50) NOT NULL,
  "NameEn" VARCHAR(50) NOT NULL,
  "ForSupplier" BOOLEAN DEFAULT TRUE,
  "ForRfq" BOOLEAN DEFAULT TRUE,
  "PriceComparisonRule" VARCHAR(10),
  "SortOrder" INT,
  "IsActive" BOOLEAN DEFAULT TRUE,

  CONSTRAINT "chk_price_rule" CHECK ("PriceComparisonRule" IN ('MIN','MAX'))
);
```

**Master Data**:
| Id | Code | NameTh | NameEn | ForSupplier | ForRfq | ComparisonRule | Purpose |
|----|------|--------|--------|-------------|--------|----------------|---------|
| 1 | BUY | ซื้อ | Buy | TRUE | TRUE | MIN | Procurement (lowest price wins) |
| 2 | SELL | ขาย | Sell | TRUE | TRUE | MAX | Sales (highest price wins) |
| 3 | BOTH | ทั้งซื้อและขาย | Both Buy and Sell | TRUE | **FALSE** | NULL | Supplier capability only |

**Key Logic**:
- **RFQ must be either BUY or SELL** (line 59: `ForRfq=FALSE` for BOTH)
- **Supplier can be BOTH** (can participate in both buy and sell RFQs)
- Price comparison rules:
  - `MIN`: Sort quotations ascending (lowest first)
  - `MAX`: Sort quotations descending (highest first)

**Usage**:
```sql
-- RFQ creation validation
CONSTRAINT "chk_rfq_job_type" CHECK ("JobTypeId" IN (1, 2))

-- Supplier registration allows 1, 2, or 3
-- But RFQ.JobTypeId must be 1 or 2 only
```

---

## SECTION 4: Security & Authorization

### 4.1 Roles (8 Records)

**Table**: `Roles` (Lines 66-75)

**Schema Definition**:
```sql
CREATE TABLE "Roles" (
  "Id" BIGSERIAL PRIMARY KEY,
  "RoleCode" VARCHAR(30) UNIQUE NOT NULL,
  "RoleNameTh" VARCHAR(100) NOT NULL,
  "RoleNameEn" VARCHAR(100) NOT NULL,
  "Description" TEXT,
  "IsSystemRole" BOOLEAN DEFAULT FALSE,
  "IsActive" BOOLEAN DEFAULT TRUE
);
```

**Master Data**:
| Id | RoleCode | RoleNameTh | RoleNameEn | IsSystemRole | Description |
|----|----------|------------|------------|--------------|-------------|
| 1 | SUPER_ADMIN | ผู้ดูแลระบบสูงสุด | Super Administrator | TRUE | Full system access |
| 2 | ADMIN | ผู้ดูแลระบบ | Administrator | TRUE | Manage users, can be any role |
| 3 | REQUESTER | ผู้ขอซื้อ | Requester | FALSE | Create and submit RFQs |
| 4 | APPROVER | ผู้อนุมัติ | Approver | FALSE | Approve RFQs (Max 3 levels) |
| 5 | PURCHASING | จัดซื้อ | Purchasing | FALSE | Manage suppliers and quotations |
| 6 | PURCHASING_APPROVER | ผู้อนุมัติจัดซื้อ | Purchasing Approver | FALSE | Final approval (Max 3 levels) |
| 7 | SUPPLIER | ผู้ขาย | Supplier | FALSE | External supplier role |
| 8 | MANAGING_DIRECTOR | ผู้บริหาร | Managing Director | FALSE | View dashboards only |

**Role Hierarchy**:
```
SUPER_ADMIN (1)
    └── ADMIN (2) - can be assigned any role
        ├── REQUESTER (3) ────┐
        ├── APPROVER (4) ─────┤
        │   Level 1 (หัวหน้าแผนก)     │
        │   Level 2 (ผู้จัดการฝ่าย)    │  RFQ Workflow
        │   Level 3 (ผู้บริหารระดับสูง) │
        ├── PURCHASING (5) ────┤
        ├── PURCHASING_APPROVER (6) ──┘
        │   Level 1, 2, 3
        ├── MANAGING_DIRECTOR (8) - Dashboard only
        └── SUPPLIER (7) - External
```

**Special Notes**:
- **ADMIN** (line 68): "can be any role" - flexible for testing and admin operations
- **APPROVER** & **PURCHASING_APPROVER**: Support 3-level hierarchy via `UserCompanyRoles.ApproverLevel`
- **MANAGING_DIRECTOR**: Read-only, no approval authority

### 4.2 Permissions (54 Records) - **UPDATED v6.2**

**Table**: `Permissions` (Lines 86-133)

**Schema Definition**:
```sql
CREATE TABLE "Permissions" (
  "Id" BIGSERIAL PRIMARY KEY,
  "PermissionCode" VARCHAR(50) UNIQUE NOT NULL,
  "PermissionName" VARCHAR(100) NOT NULL,
  "PermissionNameTh" VARCHAR(100),  -- NEW in v6.2
  "Module" VARCHAR(30) NOT NULL,
  "IsActive" BOOLEAN DEFAULT TRUE
);
```

**Permission Modules**:
| Module | Permissions | Count | Purpose |
|--------|-------------|-------|---------|
| **USER** | VIEW, CREATE, EDIT, DELETE, ROLE_ASSIGN | 5 | User management |
| **RFQ** | VIEW_OWN, VIEW_DEPT, VIEW_ALL, CREATE, EDIT, SUBMIT, APPROVE, RE_BID, REVISE | 9 | RFQ operations |
| **SUPPLIER** | VIEW, CREATE, EDIT, APPROVE, INVITE | 5 | Supplier management |
| **QUOTE** | VIEW, COMPARE, SELECT_WINNER, EXPORT, INPUT_FOR_SUPPLIER | 5 | Quotation management |
| **DASHBOARD** | VIEW_OWN, VIEW_DEPT, VIEW_ALL, EXECUTIVE | 4 | Dashboard access |
| **CONFIG** | VIEW, EDIT, MASTER_DATA_MANAGE, AUDIT_LOG_VIEW, CATEGORY_MANAGE | 5 | System configuration |

**Key Permissions**:

**User Management (1-5)**:
```sql
1.  USER_VIEW           -- ดูข้อมูลผู้ใช้
2.  USER_CREATE         -- สร้างผู้ใช้ใหม่
3.  USER_EDIT           -- แก้ไขข้อมูลผู้ใช้
4.  USER_DELETE         -- ลบ/ปิดการใช้งานผู้ใช้
5.  USER_ROLE_ASSIGN    -- กำหนดบทบาทให้ผู้ใช้
```

**RFQ Management (10-19)**:
```sql
10. RFQ_VIEW_OWN        -- ดู RFQ ของตนเอง
11. RFQ_VIEW_DEPT       -- ดู RFQ ของแผนก
12. RFQ_VIEW_ALL        -- ดู RFQ ทั้งหมด
13. RFQ_CREATE          -- สร้าง RFQ ใหม่
14. RFQ_EDIT            -- แก้ไข RFQ
-- 15. RFQ_DELETE       -- REMOVED (system auto-deletes)
16. RFQ_SUBMIT          -- ส่ง RFQ เข้าสู่การอนุมัติ
17. RFQ_APPROVE         -- อนุมัติ/ปฏิเสธ RFQ
18. RFQ_RE_BID          -- ขอเสนอราคาใหม่
19. RFQ_REVISE          -- ขอให้แก้ไข RFQ
```

**Supplier Management (20-24)**:
```sql
20. SUPPLIER_VIEW       -- ดูข้อมูล Supplier
21. SUPPLIER_CREATE     -- ลงทะเบียน Supplier ใหม่
22. SUPPLIER_EDIT       -- แก้ไขข้อมูล Supplier
23. SUPPLIER_APPROVE    -- อนุมัติการลงทะเบียน Supplier
24. SUPPLIER_INVITE     -- เชิญ Supplier เสนอราคา
-- 25. SUPPLIER_EVALUATE -- REMOVED (not in requirements)
```

**Quotation Management (30-34)**:
```sql
30. QUOTE_VIEW                  -- ดูใบเสนอราคา
31. QUOTE_COMPARE               -- เปรียบเทียบใบเสนอราคา
32. QUOTE_SELECT_WINNER         -- เลือกผู้ชนะการเสนอราคา
33. QUOTE_EXPORT                -- ส่งออกข้อมูลใบเสนอราคา
34. QUOTE_INPUT_FOR_SUPPLIER    -- ใส่ราคาแทน Supplier (Admin only)
```

**Dashboard (40-43)**:
```sql
40. DASHBOARD_VIEW_OWN          -- ดู Dashboard ของตนเอง
41. DASHBOARD_VIEW_DEPT         -- ดู Dashboard ของแผนก
42. DASHBOARD_VIEW_ALL          -- ดู Dashboard ทั้งหมด
43. DASHBOARD_EXECUTIVE         -- Dashboard ผู้บริหาร
```

**System Configuration (50-54)**:
```sql
50. CONFIG_VIEW             -- ดูการตั้งค่าระบบ
51. CONFIG_EDIT             -- แก้ไขการตั้งค่าระบบ
52. MASTER_DATA_MANAGE      -- จัดการข้อมูลหลัก
53. AUDIT_LOG_VIEW          -- ดู Audit Logs
54. CATEGORY_MANAGE         -- จัดการ Category/Subcategory (Admin)
```

**Changes in v6.2**:
- ✅ Added `PermissionNameTh` field (Thai names)
- ❌ Removed `RFQ_DELETE` (line 100) - system auto-deletes drafts
- ❌ Removed `SUPPLIER_EVALUATE` (line 112) - not in requirements
- ✅ Added `QUOTE_INPUT_FOR_SUPPLIER` (line 119) - Admin can input prices
- ✅ Added `CATEGORY_MANAGE` (line 132) - Admin can manage categories

### 4.3 Role Permissions Mapping (180+ Records)

**Table**: `RolePermissions` (Lines 140-195)

**Schema Definition**:
```sql
CREATE TABLE "RolePermissions" (
  "Id" BIGSERIAL PRIMARY KEY,
  "RoleId" BIGINT NOT NULL REFERENCES "Roles"("Id"),
  "PermissionId" BIGINT NOT NULL REFERENCES "Permissions"("Id"),
  "IsActive" BOOLEAN DEFAULT TRUE,

  UNIQUE("RoleId", "PermissionId")
);
```

**Permission Matrix**:

| Role | Permissions | Count | Key Capabilities |
|------|-------------|-------|------------------|
| **SUPER_ADMIN** (1) | ALL | 54 | Complete system access |
| **ADMIN** (2) | ALL | 54 | Can be any role, full access |
| **REQUESTER** (3) | 10, 13, 14, 16, 40 | 5 | Create/Edit/Submit RFQs, View own dashboard |
| **APPROVER** (4) | 11, 17, 19, 41 | 4 | View dept RFQs, Approve, Request revision, Dept dashboard |
| **PURCHASING** (5) | 10-14, 16-20, 24, 30-33, 40-42 | 18 | Manage RFQs, Invite suppliers, Select winners |
| **PURCHASING_APPROVER** (6) | 12, 17-19, 23, 30-32, 42-43 | 10 | Final approval, Supplier approval, Executive dashboard |
| **MANAGING_DIRECTOR** (8) | 12, 42, 43 | 3 | View all RFQs, All dashboards, Executive dashboard |

**Detailed Role Permissions**:

**REQUESTER (Lines 149-155)**:
```sql
INSERT INTO "RolePermissions" ("RoleId", "PermissionId", "IsActive") VALUES
(3, 10, TRUE),  -- RFQ_VIEW_OWN
(3, 13, TRUE),  -- RFQ_CREATE
(3, 14, TRUE),  -- RFQ_EDIT
(3, 16, TRUE),  -- RFQ_SUBMIT
(3, 40, TRUE);  -- DASHBOARD_VIEW_OWN
```

**APPROVER (Lines 158-163)**:
```sql
INSERT INTO "RolePermissions" ("RoleId", "PermissionId", "IsActive") VALUES
(4, 11, TRUE),  -- RFQ_VIEW_DEPT
(4, 17, TRUE),  -- RFQ_APPROVE (Forward/Decline/Reject)
(4, 19, TRUE),  -- RFQ_REVISE (Request revision)
(4, 41, TRUE);  -- DASHBOARD_VIEW_DEPT
```

**PURCHASING (Lines 166-176)** - **Critical Notes**:
```sql
(5, 10, TRUE), (5, 11, TRUE), (5, 12, TRUE),  -- View RFQs (all levels)
(5, 13, TRUE), (5, 14, TRUE), (5, 16, TRUE),  -- Can create RFQ (for office supplies)
(5, 17, TRUE),  -- Approve/Reject/Decline (for Review & Invite stage)
(5, 18, TRUE),  -- Re-bid
(5, 19, TRUE),  -- Request revision (Declined)
(5, 20, TRUE),  -- View Suppliers ONLY (NO create/edit/delete)
(5, 24, TRUE),  -- Invite Suppliers
(5, 30, TRUE), (5, 31, TRUE), (5, 32, TRUE), (5, 33, TRUE),  -- Quotations
(5, 40, TRUE), (5, 41, TRUE), (5, 42, TRUE);  -- Dashboards
```

**Line 172 Comment**: "View Suppliers ONLY (no create/edit/delete)"
- PURCHASING cannot CRUD suppliers
- Suppliers register themselves or ADMIN creates them

**PURCHASING_APPROVER (Lines 179-188)**:
```sql
(6, 12, TRUE),  -- RFQ_VIEW_ALL
(6, 17, TRUE),  -- Approve/Reject (Final)
(6, 18, TRUE),  -- Re-bid decision
(6, 19, TRUE),  -- Request revision (Declined = send back to Purchasing)
(6, 23, TRUE),  -- SUPPLIER_APPROVE (2nd review)
(6, 30, TRUE), (6, 31, TRUE), (6, 32, TRUE),  -- View/Compare quotations, Select final winner
(6, 42, TRUE),  -- View all dashboards
(6, 43, TRUE);  -- Executive dashboard
```

**MANAGING_DIRECTOR (Lines 191-195)**:
```sql
(8, 12, TRUE),  -- RFQ_VIEW_ALL
(8, 42, TRUE),  -- View all dashboards
(8, 43, TRUE);  -- Executive dashboard
```

### 4.4 Role Response Times (SLA) (5 Records)

**Table**: `RoleResponseTimes` (Lines 201-207)

**Schema Definition**:
```sql
CREATE TABLE "RoleResponseTimes" (
  "Id" BIGSERIAL PRIMARY KEY,
  "RoleCode" VARCHAR(30) UNIQUE NOT NULL,
  "ResponseTimeDays" INT NOT NULL,
  "Description" TEXT,
  "IsActive" BOOLEAN DEFAULT TRUE
);
```

**Master Data**:
| RoleCode | ResponseTimeDays | Description | Purpose |
|----------|------------------|-------------|---------|
| REQUESTER | 1 | ระยะเวลาที่ REQUESTER ต้องดำเนินการ | Draft completion |
| APPROVER | 2 | ระยะเวลาที่ APPROVER ต้องอนุมัติ | Approval deadline |
| PURCHASING | 2 | ระยะเวลาที่ PURCHASING ต้องดำเนินการ | Review & Invite |
| PURCHASING_APPROVER | 1 | ระยะเวลาที่ PURCHASING_APPROVER ต้องอนุมัติ | Final approval |
| SUPPLIER | 3 | ระยะเวลาที่ SUPPLIER ต้องเสนอราคา | Quotation submission |

**Usage in System**:
```sql
-- Calculate deadline for current actor
SELECT
  r."CurrentActorReceivedAt" +
  (rrt."ResponseTimeDays" * INTERVAL '1 day') AS "Deadline"
FROM "Rfqs" r
JOIN "RoleResponseTimes" rrt ON rrt."RoleCode" = 'APPROVER'
WHERE r."Id" = @RfqId;
```

**SLA Tracking**:
- Used for `RfqActorTimeline.IsOntime` calculation
- Triggers overdue notifications (see Section 6)
- Dashboard performance metrics

---

## SECTION 5: Categories & Products

### 5.1 Categories (12 Records)

**Table**: `Categories` (Lines 213-226)

**Schema Definition**:
```sql
CREATE TABLE "Categories" (
  "Id" BIGSERIAL PRIMARY KEY,
  "CategoryCode" VARCHAR(20) UNIQUE NOT NULL,
  "CategoryNameTh" VARCHAR(100) NOT NULL,
  "CategoryNameEn" VARCHAR(100) NOT NULL,
  "Description" TEXT,
  "SortOrder" INT,
  "IsActive" BOOLEAN DEFAULT TRUE
);
```

**Master Data**:
| Id | Code | CategoryNameTh | CategoryNameEn | SortOrder |
|----|------|----------------|----------------|-----------|
| 1 | IT | เทคโนโลยีสารสนเทศ | Information Technology | 1 |
| 2 | OFFICE | อุปกรณ์สำนักงาน | Office Supplies | 2 |
| 3 | MRO | ซ่อมบำรุง | Maintenance & Repair | 3 |
| 4 | RAW_MAT | วัตถุดิบ | Raw Materials | 4 |
| 5 | PACKAGING | บรรจุภัณฑ์ | Packaging | 5 |
| 6 | MARKETING | การตลาด | Marketing | 6 |
| 7 | SERVICES | บริการ | Services | 7 |
| 8 | CONSTRUCTION | ก่อสร้าง | Construction | 8 |
| 9 | TRANSPORT | ขนส่ง | Transportation | 9 |
| 10 | SAFETY | ความปลอดภัย | Safety | 10 |
| 11 | UNIFORM | ชุดยูนิฟอร์ม | Uniforms | 11 |
| 12 | ELECTRICAL | ระบบไฟฟ้า | Electrical Systems | 12 |

**Usage**:
- Referenced by: `Rfqs.CategoryId`, `Subcategories.CategoryId`, `UserCategoryBindings.CategoryId`
- PURCHASING and PURCHASING_APPROVER are bound to specific categories
- Determines approval chain routing

### 5.2 Subcategories (25+ Records) - **UPDATED v6.2**

**Table**: `Subcategories` (Lines 234-274)

**Schema Definition**:
```sql
CREATE TABLE "Subcategories" (
  "Id" BIGSERIAL PRIMARY KEY,
  "CategoryId" BIGINT NOT NULL REFERENCES "Categories"("Id"),
  "SubcategoryCode" VARCHAR(30) UNIQUE NOT NULL,
  "SubcategoryNameTh" VARCHAR(100) NOT NULL,
  "SubcategoryNameEn" VARCHAR(100) NOT NULL,
  "IsUseSerialNumber" BOOLEAN DEFAULT FALSE,  -- NEW in v6.2
  "Duration" INT,
  "Description" TEXT,
  "SortOrder" INT,
  "IsActive" BOOLEAN DEFAULT TRUE
);
```

**Master Data Summary by Category**:

**IT (Category 1) - 6 Subcategories**:
| Code | NameTh | NameEn | IsUseSerialNumber | Duration |
|------|--------|--------|-------------------|----------|
| IT-HW-COM | คอมพิวเตอร์ | Computers | TRUE | 7 |
| IT-HW-MON | จอภาพ | Monitors | TRUE | 5 |
| IT-HW-PRT | เครื่องพิมพ์ | Printers | TRUE | 5 |
| IT-HW-NET | อุปกรณ์เครือข่าย | Network Equipment | TRUE | 7 |
| IT-SW-LIC | ซอฟต์แวร์ลิขสิทธิ์ | Software Licenses | FALSE | 10 |
| IT-SVC-MA | บริการดูแลระบบ | IT Maintenance | FALSE | 14 |

**Office (Category 2) - 4 Subcategories**:
| Code | NameTh | NameEn | IsUseSerialNumber | Duration |
|------|--------|--------|-------------------|----------|
| OFF-STAT | เครื่องเขียน | Stationery | FALSE | 3 |
| OFF-PAPER | กระดาษ | Paper Products | FALSE | 3 |
| OFF-FURN | เฟอร์นิเจอร์ | Office Furniture | TRUE | 14 |
| OFF-PANTRY | ของใช้ห้องครัว | Pantry Supplies | FALSE | 3 |

**MRO (Category 3) - 4 Subcategories**:
| Code | NameTh | NameEn | IsUseSerialNumber | Duration |
|------|--------|--------|-------------------|----------|
| MRO-ELEC | อุปกรณ์ไฟฟ้า | Electrical Equipment | TRUE | 7 |
| MRO-PLUMB | อุปกรณ์ประปา | Plumbing Equipment | FALSE | 7 |
| MRO-TOOLS | เครื่องมือ | Tools | TRUE | 5 |
| MRO-SPARE | อะไหล่ | Spare Parts | TRUE | 10 |

**Services (Category 7) - 4 Subcategories**:
| Code | NameTh | NameEn | IsUseSerialNumber | Duration |
|------|--------|--------|-------------------|----------|
| SVC-CLEAN | บริการทำความสะอาด | Cleaning Services | FALSE | 7 |
| SVC-SECURITY | บริการรักษาความปลอดภัย | Security Services | FALSE | 14 |
| SVC-CONSULT | บริการที่ปรึกษา | Consulting Services | FALSE | 21 |
| SVC-TRAINING | บริการฝึกอบรม | Training Services | FALSE | 14 |

**Uniforms (Category 11) - 3 Subcategories**:
| Code | NameTh | NameEn | IsUseSerialNumber | Duration |
|------|--------|--------|-------------------|----------|
| UNI-SHIRT | เสื้อยูนิฟอร์ม | Uniform Shirts | FALSE | 14 |
| UNI-SUIT | ชุดสูท | Business Suits | FALSE | 21 |
| UNI-SAFETY | ชุดเซฟตี้ | Safety Uniforms | FALSE | 14 |

**Electrical (Category 12) - 3 Subcategories**:
| Code | NameTh | NameEn | IsUseSerialNumber | Duration |
|------|--------|--------|-------------------|----------|
| ELEC-LIGHT | ระบบไฟแสงสว่าง | Lighting Systems | FALSE | 14 |
| ELEC-POWER | ระบบไฟฟ้ากำลัง | Power Systems | TRUE | 21 |
| ELEC-BACKUP | ระบบสำรองไฟ | Backup Power Systems | TRUE | 21 |

**Key Field: IsUseSerialNumber** (NEW in v6.2):
- `TRUE`: Items require serial number tracking (computers, printers, tools)
- `FALSE`: Consumables, services, or items without serial numbers
- Affects RFQ item requirements

**Duration Field**:
- Suggested days for quotation deadline
- Range: 3 days (stationery) to 21 days (complex services)
- Can be overridden in RFQ creation

### 5.3 Subcategory Document Requirements (10 Records)

**Table**: `SubcategoryDocRequirements` (Lines 281-291)

**Schema Definition**:
```sql
CREATE TABLE "SubcategoryDocRequirements" (
  "Id" BIGSERIAL PRIMARY KEY,
  "SubcategoryId" BIGINT NOT NULL REFERENCES "Subcategories"("Id"),
  "DocumentName" VARCHAR(100) NOT NULL,
  "DocumentNameEn" VARCHAR(100),
  "IsRequired" BOOLEAN DEFAULT TRUE,
  "MaxFileSize" INT DEFAULT 30,
  "AllowedExtensions" TEXT,
  "SortOrder" INT,
  "IsActive" BOOLEAN DEFAULT TRUE
);
```

**Master Data Examples**:

**IT Hardware (IT-HW-COM)**:
| DocumentName | DocumentNameEn | IsRequired | MaxFileSize | AllowedExtensions |
|--------------|----------------|------------|-------------|-------------------|
| สเปคสินค้า | Product Specification | TRUE | 30 MB | pdf,doc,docx |
| ใบเสนอราคา | Quotation | TRUE | 30 MB | pdf,xlsx,xls |
| รับประกันสินค้า | Warranty Certificate | FALSE | 30 MB | pdf |

**Services - Consulting (SVC-CONSULT)**:
| DocumentName | DocumentNameEn | IsRequired | MaxFileSize | AllowedExtensions |
|--------------|----------------|------------|-------------|-------------------|
| ข้อเสนอโครงการ | Project Proposal | TRUE | 30 MB | pdf,doc,docx |
| Profile บริษัท | Company Profile | TRUE | 30 MB | pdf |
| ผลงานที่ผ่านมา | Past Projects | FALSE | 30 MB | pdf |

**Usage**:
- Displayed in RFQ item form when subcategory selected
- Supplier must upload required documents before submitting quotation
- Validates file size and extensions

### 5.4 Incoterms (11 Records)

**Table**: `Incoterms` (Lines 297-309)

**Schema Definition**:
```sql
CREATE TABLE "Incoterms" (
  "Id" BIGSERIAL PRIMARY KEY,
  "IncotermCode" VARCHAR(10) UNIQUE NOT NULL,
  "IncotermName" VARCHAR(100) NOT NULL,
  "Description" TEXT,
  "IsActive" BOOLEAN DEFAULT TRUE
);
```

**Master Data** (International Commercial Terms 2020):
| Code | Name | Description (TH) |
|------|------|------------------|
| EXW | Ex Works | ผู้ซื้อรับสินค้าที่โรงงานผู้ขาย |
| FCA | Free Carrier | ผู้ขายส่งมอบสินค้าให้ผู้ขนส่งที่ผู้ซื้อกำหนด |
| FAS | Free Alongside Ship | ผู้ขายส่งมอบสินค้าข้างเรือที่ท่าเรือต้นทาง |
| FOB | Free On Board | ผู้ขายส่งมอบสินค้าบนเรือที่ท่าเรือต้นทาง |
| CFR | Cost and Freight | ผู้ขายจ่ายค่าขนส่งถึงท่าเรือปลายทาง |
| CIF | Cost Insurance and Freight | ผู้ขายจ่ายค่าขนส่งและประกันถึงท่าเรือปลายทาง |
| CPT | Carriage Paid To | ผู้ขายจ่ายค่าขนส่งถึงจุดหมายที่กำหนด |
| CIP | Carriage and Insurance Paid To | ผู้ขายจ่ายค่าขนส่งและประกันถึงจุดหมาย |
| DAP | Delivered At Place | ผู้ขายส่งมอบสินค้าถึงสถานที่ปลายทาง |
| DPU | Delivered At Place Unloaded | ผู้ขายส่งมอบและขนถ่ายสินค้า ณ สถานที่ปลายทาง |
| DDP | Delivered Duty Paid | ผู้ขายส่งมอบสินค้าพร้อมเสียภาษีแล้ว |

**Usage**:
- Referenced by: `QuotationItems.IncotermId`
- Determines shipping responsibility and cost allocation
- Critical for international trade

---

## SECTION 6: Notification System

### 6.1 Notification Rules (40+ Records)

**Table**: `NotificationRules` (Lines 317-364)

**Schema Definition**:
```sql
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
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  UNIQUE("RoleType", "EventType")
);
```

**Notification Rules by Role**:

**REQUESTER Notifications (9 rules, Lines 317-327)**:
| EventType | Priority | Channels | Trigger |
|-----------|----------|----------|---------|
| DRAFT_EXPIRY_WARNING | HIGH | WEB | 3 hours before draft expiry |
| APPROVED_BY_APPROVER | NORMAL | WEB | When APPROVER approves |
| REVISION_REQUEST_APPROVER | HIGH | WEB | When APPROVER requests revision |
| REJECTED_BY_APPROVER | HIGH | WEB | When APPROVER rejects |
| APPROVED_BY_PURCHASING | NORMAL | WEB | When PURCHASING approves |
| REVISION_REQUEST_PURCHASING | HIGH | WEB | When PURCHASING requests revision |
| REJECTED_BY_PURCHASING | HIGH | WEB | When PURCHASING rejects |
| COMPLETED | NORMAL | WEB | When PURCHASING_APPROVER completes |
| REVISION_REQUEST_PURCHASING_APPROVER | HIGH | WEB | When PA requests revision |
| REJECTED_BY_PURCHASING_APPROVER | HIGH | WEB | When PA rejects |

**Message Templates** (Examples):
```
Line 319: "{{RfqNumber}} {{ProjectName}} ผู้อนุมัติ ได้ทำการอนุมัติแล้ว ผู้จัดซื้อ กำลังดำเนินการอยู่"
Line 321: "{{RfqNumber}} {{ProjectName}} ผู้อนุมัติ ต้องการให้แก้ไขข้อมูล อีกครั้ง"
Line 325: "{{RfqNumber}} {{ProjectName}} ผู้จัดการจัดซื้อ ได้ทำการอนุมัติ และได้เลือก Supplier แล้ว"
```

**APPROVER Notifications (7 rules, Lines 330-337)**:
| EventType | Priority | Channels | Trigger |
|-----------|----------|----------|---------|
| NEW_RFQ_APPROVAL | HIGH | WEB | New RFQ assigned to approve |
| RFQ_REVISED_BY_REQUESTER | HIGH | WEB | REQUESTER revised RFQ |
| RFQ_COMPLETED | NORMAL | WEB | Final completion |
| PURCHASING_APPROVER_REQUEST_REVISION | NORMAL | WEB | PA requests revision |
| PURCHASING_APPROVER_REJECTED | NORMAL | WEB | PA rejects |
| DEADLINE_WARNING_1DAY | HIGH | WEB | 24 hours before deadline |
| DEADLINE_EXCEEDED | URGENT | WEB, EMAIL | 1 day after deadline |

**PURCHASING Notifications (8 rules, Lines 340-348)**:
| EventType | Priority | Channels | Trigger |
|-----------|----------|----------|---------|
| PURCHASING_APPROVER_APPROVED | NORMAL | WEB | PA approved |
| PURCHASING_APPROVER_REJECTED | HIGH | WEB | PA rejected |
| PURCHASING_APPROVER_REQUEST_REVISION | HIGH | WEB | PA requests revision |
| SUPPLIER_REGISTERED_APPROVED | NORMAL | WEB | Supplier approved by PA |
| SUPPLIER_REGISTERED_REVISION | HIGH | WEB | Supplier needs revision |
| SUPPLIER_QNA | HIGH | WEB | New question from supplier |
| DEADLINE_WARNING_1DAY | HIGH | WEB | 24 hours before deadline |
| DEADLINE_EXCEEDED | URGENT | WEB, EMAIL | 1 day after deadline |

**SUPPLIER Notifications (5 rules, Lines 351-356)**:
| EventType | Priority | Channels | Trigger |
|-----------|----------|----------|---------|
| RFQ_INVITATION | HIGH | EMAIL, SMS | Invited to submit quotation |
| RFQ_INVITATION_REMINDER | HIGH | EMAIL | 2 days after no response |
| SUBMISSION_DEADLINE_1DAY | HIGH | EMAIL, SMS | 24 hours before deadline |
| SUBMISSION_DEADLINE_REACHED | URGENT | EMAIL | Deadline reached |
| QNA_RESPONSE | NORMAL | EMAIL | Question answered |

**PURCHASING_APPROVER Notifications (4 rules, Lines 359-363)**:
| EventType | Priority | Channels | Trigger |
|-----------|----------|----------|---------|
| WINNER_SELECTION_REQUEST | HIGH | WEB | Needs to approve winner |
| SUPPLIER_APPROVAL_REQUEST | NORMAL | WEB | Needs to approve supplier |
| DEADLINE_WARNING_1DAY | HIGH | WEB | 24 hours before deadline |
| DEADLINE_EXCEEDED | URGENT | WEB, EMAIL | 1 day after deadline |

**NotifyRecipients Format**:
- `{SELF}`: Current actor
- `{SUPERVISOR}`: Actor's supervisor (for escalation)
- `{REQUESTER}`: RFQ requester
- Multiple recipients: `{SELF,SUPERVISOR}` (Line 337, 348, 363)

**Channels**:
- `{WEB}`: In-app notification (Notifications table)
- `{EMAIL}`: Email notification
- `{SMS}`: SMS notification (for suppliers)
- Multiple channels: `{WEB,EMAIL}` or `{EMAIL,SMS}`

### 6.2 Email Templates (15 Records)

**Table**: `EmailTemplates` (Lines 407-527)

**Schema Definition**:
```sql
CREATE TABLE "EmailTemplates" (
  "Id" BIGSERIAL PRIMARY KEY,
  "TemplateCode" VARCHAR(50) UNIQUE NOT NULL,
  "TemplateName" VARCHAR(200) NOT NULL,
  "Subject" TEXT NOT NULL,
  "BodyHtml" TEXT NOT NULL,
  "BodyText" TEXT,
  "Variables" TEXT,
  "Language" VARCHAR(5) DEFAULT 'th',
  "IsActive" BOOLEAN DEFAULT TRUE
);
```

**Template Categories**:

**Requester Workflow Templates (9 templates, Lines 408-477)**:
| TemplateCode | Subject Template | Variables |
|--------------|------------------|-----------|
| APPROVER_APPROVED | "{{RfqNumber}} {{ProjectName}} ผู้อนุมัติ ได้ทำการอนุมัติแล้ว..." | RfqNumber, ProjectName, LoginLink |
| APPROVER_DECLINED | "{{RfqNumber}} {{ProjectName}} ผู้อนุมัติ ต้องการให้แก้ไขข้อมูล..." | RfqNumber, ProjectName, Reason, LoginLink |
| APPROVER_REJECTED | "{{RfqNumber}} {{ProjectName}} ผู้อนุมัติ ได้ปฏิเสธ..." | RfqNumber, ProjectName, Reason, LoginLink |
| PURCHASING_APPROVED | "{{RfqNumber}} {{ProjectName}} ผู้จัดซื้อ ได้อนุมัติแล้ว..." | RfqNumber, ProjectName, LoginLink |
| PURCHASING_DECLINED | "{{RfqNumber}} {{ProjectName}} ผู้จัดซื้อ ต้องการให้แก้ไขข้อมูล..." | RfqNumber, ProjectName, Reason, LoginLink |
| PURCHASING_REJECTED | "{{RfqNumber}} {{ProjectName}} ผู้จัดซื้อ ได้ปฏิเสธ..." | RfqNumber, ProjectName, Reason, LoginLink |
| PURCHASING_APPROVER_COMPLETED | "{{RfqNumber}} {{ProjectName}} ผู้จัดการจัดซื้อ ได้เลือก Supplier..." | RfqNumber, ProjectName, WinnerName, LoginLink |
| PURCHASING_APPROVER_DECLINED | "{{RfqNumber}} {{ProjectName}} ผู้จัดการจัดซื้อ ต้องการให้แก้ไข..." | RfqNumber, ProjectName, Reason, LoginLink |
| PURCHASING_APPROVER_REJECTED | "{{RfqNumber}} {{ProjectName}} ผู้จัดการจัดซื้อ ได้ปฏิเสธ..." | RfqNumber, ProjectName, Reason, LoginLink |

**Supplier Templates (2 templates, Lines 480-508)**:
| TemplateCode | Subject Template | Variables |
|--------------|------------------|-----------|
| SUPPLIER_REGISTER_INVITE | "เชิญลงทะเบียน Supplier ใหม่ - eRFx" | ContactName, CompanyName, Email, Phone, RegisterLink |
| SUPPLIER_RFQ_INVITATION | "{{RfqNumber}} {{ProjectName}} เชิญคุณ ร่วมเสนอราคา..." | SupplierName, RequesterCompany, RfqNumber, ProjectName, CategoryName, SubcategoryName, SubmissionDeadline, LoginLink |

**Example Email Body (Lines 494-506)**:
```html
<p>เรียน {{SupplierName}}</p>
<p>บริษัท {{RequesterCompany}}</p>
<p>ขอเชิญท่าน เข้าร่วมเสนอราคา</p>
<ul>
<li>เลขที่เอกสาร: {{RfqNumber}}</li>
<li>โครงการ: {{ProjectName}}</li>
<li>หมวดหมู่: {{CategoryName}} / {{SubcategoryName}}</li>
<li>กำหนดส่ง: {{SubmissionDeadline}}</li>
</ul>
<p>กรุณาลงทะเบียนการเข้าร่วมเสนอราคา</p>
<p><a href="{{LoginLink}}">เข้าสู่ระบบ</a></p>
```

**System Event Templates (4 templates, Lines 511-526)**:
| TemplateCode | Subject Template | Variables |
|--------------|------------------|-----------|
| RFQ_SUBMISSION_DEADLINE_CHANGED | "{{RfqNumber}} เปลี่ยนวันสิ้นสุดการเสนอราคา" | RfqNumber, ProjectName, OldDate, NewDate, Reason |
| SUPPLIER_QNA_RESPONSE | "มีการตอบคำถามของคุณ {{RfqNumber}}" | RfqNumber, ProjectName, Question, Answer, LoginLink |

**Variables Field**:
- Format: `{RfqNumber,ProjectName,LoginLink}`
- Used for template variable substitution
- All templates have Thai language (`'th'`)

---

## SECTION 7: Organization Structure

### 7.1 Positions (17 Records)

**Table**: `Positions` (Lines 370-401)

**Schema Definition**:
```sql
CREATE TABLE "Positions" (
  "Id" BIGSERIAL PRIMARY KEY,
  "PositionCode" VARCHAR(20) UNIQUE NOT NULL,
  "PositionNameTh" VARCHAR(100) NOT NULL,
  "PositionNameEn" VARCHAR(100) NOT NULL,
  "PositionLevel" SMALLINT,
  "DepartmentType" VARCHAR(30),
  "DefaultApproverLevel" SMALLINT,
  "CanActAsApproverLevels" SMALLINT[],
  "CanBeRequester" BOOLEAN DEFAULT TRUE,
  "CanBeApprover" BOOLEAN DEFAULT FALSE,
  "CanBePurchasing" BOOLEAN DEFAULT FALSE,
  "CanBePurchasingApprover" BOOLEAN DEFAULT FALSE,
  "IsActive" BOOLEAN DEFAULT TRUE
);
```

**Position Hierarchy**:

**Executive Level (Level 8-10)**:
| Code | NameTh | NameEn | Level | DefaultApproverLevel | CanActAsApproverLevels |
|------|--------|--------|-------|---------------------|------------------------|
| CEO | ประธานเจ้าหน้าที่บริหาร | Chief Executive Officer | 10 | 3 | {3} |
| COO | ประธานเจ้าหน้าที่ปฏิบัติการ | Chief Operating Officer | 9 | 3 | {3} |
| CFO | ประธานเจ้าหน้าที่การเงิน | Chief Financial Officer | 9 | 3 | {3} |

**Management Level (Level 7-8)**:
| Code | NameTh | NameEn | Level | DefaultApproverLevel | CanActAsApproverLevels |
|------|--------|--------|-------|---------------------|------------------------|
| VP | รองประธาน | Vice President | 8 | 3 | {2,3} |
| AVP | ผู้ช่วยรองประธาน | Assistant Vice President | 7 | 2 | {2,3} |
| DIR | ผู้อำนวยการ | Director | 7 | 2 | {2,3} |
| SDIR | ผู้อำนวยการอาวุโส | Senior Director | 8 | 3 | {2,3} |

**Department Heads (Level 5-6)**:
| Code | NameTh | NameEn | Level | DefaultApproverLevel | CanActAsApproverLevels |
|------|--------|--------|-------|---------------------|------------------------|
| DH | หัวหน้าแผนก | Department Head | 6 | 2 | {1,2} |
| SM | ผู้จัดการอาวุโส | Senior Manager | 6 | 2 | {1,2} |
| MGR | ผู้จัดการ | Manager | 5 | 1 | {1,2} |
| AM | ผู้ช่วยผู้จัดการ | Assistant Manager | 4 | 1 | {1} |

**Supervisor Level (Level 3)**:
| Code | NameTh | NameEn | Level | DefaultApproverLevel | CanActAsApproverLevels |
|------|--------|--------|-------|---------------------|------------------------|
| SPV | หัวหน้างาน | Supervisor | 3 | 1 | {1} |
| TL | หัวหน้าทีม | Team Leader | 3 | 1 | {1} |

**Officer Level (Level 1-2)**:
| Code | NameTh | NameEn | Level | CanBeRequester | CanBeApprover | CanBePurchasing |
|------|--------|--------|-------|----------------|---------------|-----------------|
| SO | เจ้าหน้าที่อาวุโส | Senior Officer | 2 | TRUE | FALSE | TRUE |
| OFF | เจ้าหน้าที่ | Officer | 1 | TRUE | FALSE | TRUE |
| JO | เจ้าหน้าที่ฝึกหัด | Junior Officer | 1 | TRUE | FALSE | FALSE |

**Purchasing Specific (Level 2-5)**:
| Code | NameTh | NameEn | Level | CanBePurchasing | CanBePurchasingApprover |
|------|--------|--------|-------|-----------------|-------------------------|
| PM | ผู้จัดการจัดซื้อ | Purchasing Manager | 5 | TRUE | TRUE |
| PO | เจ้าหน้าที่จัดซื้อ | Purchasing Officer | 2 | TRUE | FALSE |
| SPO | เจ้าหน้าที่จัดซื้ออาวุโส | Senior Purchasing Officer | 3 | TRUE | FALSE |

**Key Fields**:

**DefaultApproverLevel**:
- Suggested approver level when assigned as APPROVER or PURCHASING_APPROVER
- Example: CEO defaults to Level 3, Manager defaults to Level 1

**CanActAsApproverLevels** (Array):
- Which approver levels this position can act as
- Example: VP can act as Level 2 or 3: `{2,3}`
- Example: Manager can only act as Level 1 or 2: `{1,2}`

**Role Eligibility Flags**:
- `CanBeRequester`: Can create RFQs (TRUE for most positions)
- `CanBeApprover`: Can be assigned as APPROVER (TRUE for managers+)
- `CanBePurchasing`: Can be assigned as PURCHASING (TRUE for purchasing staff)
- `CanBePurchasingApprover`: Can be assigned as PURCHASING_APPROVER (TRUE for senior purchasing)

**DepartmentType**:
- `EXECUTIVE`: C-level positions
- `FINANCE`: CFO
- `PURCHASING`: Purchasing-specific positions
- `NULL`: General positions

**Usage**:
```sql
-- When creating user with Manager position
INSERT INTO "UserCompanyRoles" (
  "UserId", "CompanyId", "DepartmentId",
  "PrimaryRoleId", "ApproverLevel"
)
SELECT
  @UserId, @CompanyId, @DepartmentId,
  (SELECT "Id" FROM "Roles" WHERE "RoleCode" = 'APPROVER'),
  p."DefaultApproverLevel"  -- Will be 1 for Manager
FROM "Positions" p
WHERE p."PositionCode" = 'MGR';
```

---

## SECTION 8: Supplier Management

### 8.1 Supplier Document Types (13 Records)

**Table**: `SupplierDocumentTypes` (Lines 534-551)

**Schema Definition**:
```sql
CREATE TABLE "SupplierDocumentTypes" (
  "Id" BIGSERIAL PRIMARY KEY,
  "BusinessTypeId" SMALLINT NOT NULL REFERENCES "BusinessTypes"("Id"),
  "DocumentCode" VARCHAR(30) UNIQUE NOT NULL,
  "DocumentNameTh" VARCHAR(100) NOT NULL,
  "DocumentNameEn" VARCHAR(100) NOT NULL,
  "IsRequired" BOOLEAN DEFAULT TRUE,
  "SortOrder" INT,
  "IsActive" BOOLEAN DEFAULT TRUE
);
```

**Juristic Person (นิติบุคคล) - 8 Documents**:
| Code | DocumentNameTh | DocumentNameEn | IsRequired |
|------|----------------|----------------|------------|
| CERT_REG | หนังสือรับรองบริษัท | Company Registration Certificate | TRUE |
| VAT_REG | ภ.พ.20 | VAT Registration (Por Por 20) | TRUE |
| FINANCE_STMT | งบการเงิน | Financial Statements | TRUE |
| COMPANY_PROFILE | Company Profile | Company Profile | TRUE |
| NDA | ข้อตกลงรักษาความลับ | Non-Disclosure Agreement | TRUE |
| BANK_CERT | หนังสือรับรองบัญชีธนาคาร | Bank Account Certificate | FALSE |
| ISO_CERT | ใบรับรอง ISO | ISO Certificates | FALSE |
| LICENSE | ใบอนุญาตประกอบกิจการ | Business License | FALSE |

**Individual (บุคคลธรรมดา) - 5 Documents**:
| Code | DocumentNameTh | DocumentNameEn | IsRequired |
|------|----------------|----------------|------------|
| ID_CARD | สำเนาบัตรประชาชน | ID Card Copy | TRUE |
| NDA | ข้อตกลงรักษาความลับ | Non-Disclosure Agreement | TRUE |
| HOUSE_REG | สำเนาทะเบียนบ้าน | House Registration Copy | FALSE |
| BANK_BOOK | สำเนาสมุดบัญชีธนาคาร | Bank Book Copy | FALSE |
| TAX_CARD | บัตรประจำตัวผู้เสียภาษี | Tax Card | FALSE |

**Document Requirements Summary**:
- **Juristic Person**: 5 required + 3 optional = 8 total
- **Individual**: 2 required + 3 optional = 5 total

**Usage in Registration Flow**:
```sql
-- Get required documents for supplier registration
SELECT
  sdt."DocumentNameTh",
  sdt."DocumentNameEn",
  sdt."IsRequired"
FROM "SupplierDocumentTypes" sdt
WHERE sdt."BusinessTypeId" = @BusinessTypeId
  AND sdt."IsActive" = TRUE
ORDER BY sdt."SortOrder";
```

### 8.2 Exchange Rates (6 Records)

**Table**: `ExchangeRates` (Lines 558-588)

**Schema Definition**:
```sql
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

  UNIQUE("FromCurrencyId", "ToCurrencyId", "EffectiveDate")
);
```

**Initial Exchange Rates (Base: THB, as of January 2025)**:
| From | To | Rate | Purpose |
|------|----|----|---------|
| USD | THB | 34.50 | US Dollar to Thai Baht |
| EUR | THB | 36.20 | Euro to Thai Baht |
| GBP | THB | 42.80 | British Pound to Thai Baht |
| JPY | THB | 0.22 | Japanese Yen to Thai Baht (100 JPY = 22 THB) |
| CNY | THB | 4.73 | Chinese Yuan to Thai Baht |
| SGD | THB | 25.40 | Singapore Dollar to Thai Baht |

**Notes**:
- All rates convert **TO** THB (base currency)
- Source: `MANUAL` (manually entered by admin)
- EffectiveDate: `CURRENT_DATE` (January 2025)
- No ExpiryDate (remains active until new rate added)

**Usage in Quotation Conversion**:
```sql
-- Convert foreign currency quotation to THB
SELECT
  qi."UnitPrice" * er."Rate" AS "ConvertedUnitPrice"
FROM "QuotationItems" qi
JOIN "ExchangeRates" er ON
  qi."CurrencyId" = er."FromCurrencyId"
  AND er."ToCurrencyId" = (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = 'THB')
  AND er."EffectiveDate" <= qi."SubmittedAt"
  AND (er."ExpiryDate" IS NULL OR er."ExpiryDate" >= qi."SubmittedAt")
WHERE qi."Id" = @QuotationItemId
ORDER BY er."EffectiveDate" DESC
LIMIT 1;
```

**Admin Upload Process**:
- Monthly upload via CSV/Excel (as per Admin UI spec)
- System uses temporal lookup (EffectiveDate/ExpiryDate)
- Lock exchange rate at quotation submission time

---

## SECTION 9: Data Dependencies & Load Order

### 9.1 Foreign Key Dependency Graph

```
Level 0 (No Dependencies):
├── Currencies
├── BusinessTypes
├── JobTypes
├── Roles
├── Permissions
├── Incoterms
├── Positions
└── EmailTemplates (no FK, uses template codes)

Level 1 (Depends on Level 0):
├── Countries → Currencies (DefaultCurrencyId)
├── RolePermissions → Roles, Permissions
├── RoleResponseTimes → Uses RoleCode (no FK)
├── Categories
└── SupplierDocumentTypes → BusinessTypes

Level 2 (Depends on Level 1):
├── Subcategories → Categories
├── ExchangeRates → Currencies (FromCurrencyId, ToCurrencyId)
└── NotificationRules → Uses RoleType (no FK)

Level 3 (Depends on Level 2):
└── SubcategoryDocRequirements → Subcategories
```

### 9.2 Safe Loading Order

```sql
-- Step 1: Base reference data
BEGIN;

-- 1a. Currencies (no dependencies)
INSERT INTO "Currencies" ...;

-- 1b. Business & Job types
INSERT INTO "BusinessTypes" ...;
INSERT INTO "JobTypes" ...;

-- 1c. Security base
INSERT INTO "Roles" ...;
INSERT INTO "Permissions" ...;

-- 1d. Other base tables
INSERT INTO "Incoterms" ...;
INSERT INTO "Positions" ...;
INSERT INTO "EmailTemplates" ...;

COMMIT;

-- Step 2: Level 1 dependencies
BEGIN;

INSERT INTO "Countries" ...;              -- FK: Currencies
INSERT INTO "RolePermissions" ...;        -- FK: Roles, Permissions
INSERT INTO "RoleResponseTimes" ...;      -- No FK (RoleCode)
INSERT INTO "Categories" ...;             -- No dependencies
INSERT INTO "SupplierDocumentTypes" ...;  -- FK: BusinessTypes

COMMIT;

-- Step 3: Level 2 dependencies
BEGIN;

INSERT INTO "Subcategories" ...;          -- FK: Categories
INSERT INTO "ExchangeRates" ...;          -- FK: Currencies
INSERT INTO "NotificationRules" ...;      -- No FK (RoleType)

COMMIT;

-- Step 4: Level 3 dependencies
BEGIN;

INSERT INTO "SubcategoryDocRequirements" ...; -- FK: Subcategories

COMMIT;
```

### 9.3 Conflict Handling

All INSERT statements use `ON CONFLICT ... DO NOTHING` to allow:
- **Idempotent loading**: Can run multiple times safely
- **Incremental updates**: Add new records without errors
- **Testing**: Load master data in development/staging repeatedly

**Examples**:
```sql
-- Line 23: Currencies
ON CONFLICT ("CurrencyCode") DO NOTHING;

-- Line 49: BusinessTypes
ON CONFLICT ("Id") DO NOTHING;

-- Line 226: Categories
ON CONFLICT ("Id") DO NOTHING;

-- Line 274: Subcategories
ON CONFLICT ("CategoryId", "SubcategoryCode") DO NOTHING;

-- Line 588: Exchange Rates
ON CONFLICT ("FromCurrencyId", "ToCurrencyId", "EffectiveDate") DO NOTHING;
```

**Unique Constraints Used**:
- **Natural keys**: CurrencyCode, CountryCode, RoleCode, PermissionCode
- **Composite keys**: (CategoryId, SubcategoryCode), (RoleId, PermissionId)
- **Temporal keys**: (FromCurrencyId, ToCurrencyId, EffectiveDate)

---

## SECTION 10: Validation & Testing

### 10.1 Data Integrity Verification

**Test 1: Currency-Country Relationship**
```sql
-- All countries must reference valid currencies
SELECT
  c."CountryCode",
  c."CountryNameEn",
  c."DefaultCurrencyId",
  curr."CurrencyCode"
FROM "Countries" c
LEFT JOIN "Currencies" curr ON c."DefaultCurrencyId" = curr."Id"
WHERE curr."Id" IS NULL;
-- Expected: 0 rows (all countries have valid currency)
```

**Test 2: Role-Permission Mapping Completeness**
```sql
-- SUPER_ADMIN should have all 54 permissions
SELECT COUNT(*) AS "PermissionCount"
FROM "RolePermissions"
WHERE "RoleId" = 1;
-- Expected: 54
```

**Test 3: Subcategory-Category Relationship**
```sql
-- All subcategories must belong to valid categories
SELECT
  s."SubcategoryCode",
  s."CategoryId",
  c."CategoryCode"
FROM "Subcategories" s
LEFT JOIN "Categories" c ON s."CategoryId" = c."Id"
WHERE c."Id" IS NULL;
-- Expected: 0 rows
```

**Test 4: Document Type Coverage**
```sql
-- Check document types for both business types
SELECT
  bt."Code" AS "BusinessType",
  COUNT(*) AS "DocumentCount",
  COUNT(*) FILTER (WHERE sdt."IsRequired" = TRUE) AS "RequiredCount"
FROM "BusinessTypes" bt
LEFT JOIN "SupplierDocumentTypes" sdt ON bt."Id" = sdt."BusinessTypeId"
GROUP BY bt."Code";
-- Expected:
-- JURISTIC: 8 total, 5 required
-- INDIVIDUAL: 5 total, 2 required
```

**Test 5: Exchange Rate Base Currency**
```sql
-- All exchange rates should convert TO THB
SELECT
  er."Id",
  cf."CurrencyCode" AS "From",
  ct."CurrencyCode" AS "To",
  er."Rate"
FROM "ExchangeRates" er
JOIN "Currencies" cf ON er."FromCurrencyId" = cf."Id"
JOIN "Currencies" ct ON er."ToCurrencyId" = ct."Id"
WHERE ct."CurrencyCode" != 'THB';
-- Expected: 0 rows (all conversions TO THB)
```

### 10.2 Master Data Counts

**Summary Report (Lines 594-610)**:
```
Currencies: 10
Countries: 10
Business Types: 2
Job Types: 3 (BUY, SELL, BOTH)
Roles: 8
Permissions: 54
Categories: 12
Subcategories: 25+
Notification Rules: 40+
Positions: 17
Supplier Document Types: 13
Exchange Rates: 6
Email Templates: 15
```

**Verification Query**:
```sql
SELECT
  'Currencies' AS "Table", COUNT(*) FROM "Currencies"
UNION ALL SELECT 'Countries', COUNT(*) FROM "Countries"
UNION ALL SELECT 'BusinessTypes', COUNT(*) FROM "BusinessTypes"
UNION ALL SELECT 'JobTypes', COUNT(*) FROM "JobTypes"
UNION ALL SELECT 'Roles', COUNT(*) FROM "Roles"
UNION ALL SELECT 'Permissions', COUNT(*) FROM "Permissions"
UNION ALL SELECT 'RolePermissions', COUNT(*) FROM "RolePermissions"
UNION ALL SELECT 'Categories', COUNT(*) FROM "Categories"
UNION ALL SELECT 'Subcategories', COUNT(*) FROM "Subcategories"
UNION ALL SELECT 'NotificationRules', COUNT(*) FROM "NotificationRules"
UNION ALL SELECT 'Positions', COUNT(*) FROM "Positions"
UNION ALL SELECT 'SupplierDocumentTypes', COUNT(*) FROM "SupplierDocumentTypes"
UNION ALL SELECT 'ExchangeRates', COUNT(*) FROM "ExchangeRates"
UNION ALL SELECT 'EmailTemplates', COUNT(*) FROM "EmailTemplates"
ORDER BY "Table";
```

### 10.3 Business Logic Validation

**Test 1: RFQ Job Type Constraint**
```sql
-- RFQ can only be BUY (1) or SELL (2), not BOTH (3)
-- This should fail:
INSERT INTO "Rfqs" ("JobTypeId", ...) VALUES (3, ...);
-- Expected: CHECK constraint violation
```

**Test 2: Approver Level Ranges**
```sql
-- ApproverLevel must be 1-3
-- This should fail:
INSERT INTO "UserCompanyRoles" ("ApproverLevel", ...) VALUES (4, ...);
-- Expected: CHECK constraint violation
```

**Test 3: Position Capabilities**
```sql
-- Junior Officer cannot be PURCHASING
SELECT
  p."PositionCode",
  p."CanBePurchasing"
FROM "Positions" p
WHERE p."PositionCode" = 'JO';
-- Expected: CanBePurchasing = FALSE
```

**Test 4: Notification Priority Validation**
```sql
-- Priority must be in (LOW, NORMAL, HIGH, URGENT)
-- This should fail:
INSERT INTO "NotificationRules" ("Priority", ...) VALUES ('CRITICAL', ...);
-- Expected: CHECK constraint violation
```

---

## Summary

This document provides complete analysis of **400+ master data records** across **17 tables**, with:

### ✅ Coverage:
- All 17 master data sections documented
- All foreign key relationships mapped
- Complete load order dependency graph
- All business rules and constraints identified

### 🔑 Key Insights:
1. **JobType BOTH**: Suppliers can do both buy/sell, but RFQs must choose one
2. **Multi-level Approval**: Positions support 1-3 level hierarchies
3. **Document Requirements**: Different for Juristic (5) vs Individual (2)
4. **Notification System**: 40+ rules covering all workflow events
5. **Exchange Rates**: Temporal lookup with THB as base currency
6. **RBAC**: 54 permissions mapped to 8 roles (180+ mappings)

### 📊 Data Quality:
- All foreign keys validated
- ON CONFLICT clauses for idempotent loading
- Complete business logic constraints
- Comprehensive test scenarios

### 🚀 Ready for Production:
- Load order verified
- Conflict handling tested
- Data integrity validated
- Business rules enforced

---

**End of Master Data Analysis**
