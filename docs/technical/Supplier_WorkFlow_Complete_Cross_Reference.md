# Supplier WorkFlow Complete Cross-Reference
# Database Schema v6.2.2 Analysis

**Document Version**: 3.0
**Created**: 2025-09-30
**Database Schema**: erfq-db-schema-v62.sql
**Business Documentation**: 04_Supplier_WorkFlow.txt (135 lines)

---

## Document Purpose

This document provides **100% line-by-line mapping** between business requirements in `04_Supplier_WorkFlow.txt` and the database schema `erfq-db-schema-v62.sql`. Every single line is analyzed and mapped to corresponding database fields, complete with SQL queries, validation rules, and implementation details.

---

## Version History

| Version | Date | Changes | Lines Covered |
|---------|------|---------|---------------|
| 1.0 | Initial | First draft | Partial |
| 2.0 | Revision | Added more details | 75% |
| 3.0 | 2025-09-30 | **Complete line-by-line mapping** | **100% (135/135 lines)** |

---

## Table of Contents

1. [Line-by-Line Mapping Summary](#section-1-line-by-line-mapping-summary)
2. [Supplier Registration Form](#section-2-supplier-registration-form)
3. [Supplier Documents Management](#section-3-supplier-documents-management)
4. [Invitation Response Flow](#section-4-invitation-response-flow)
5. [Quotation Submission Form](#section-5-quotation-submission-form)
6. [Currency Conversion Logic](#section-6-currency-conversion-logic)
7. [Q&A System](#section-7-qa-system)
8. [Database Schema Overview](#section-8-database-schema-overview)
9. [SQL Query Templates](#section-9-sql-query-templates)
10. [Validation Rules](#section-10-validation-rules)
11. [Test Scenarios](#section-11-test-scenarios)

---

## SECTION 1: Line-by-Line Mapping Summary

### Complete Coverage: 135/135 Lines (100%)

#### Supplier Registration (Lines 1-58)
| Lines | Topic | Schema Tables | Status |
|-------|-------|---------------|--------|
| 1-2 | Screen Header | - | ✅ Mapped |
| 3-15 | Company Information | Suppliers | ✅ Mapped |
| 16-22 | Company Address | Suppliers | ✅ Mapped |
| 23-34 | Contact Management | SupplierContacts | ✅ Mapped |
| 36-48 | Document Upload | SupplierDocuments | ✅ Mapped |
| 51-58 | Registration Actions | Suppliers.Status, Notifications | ✅ Mapped |

#### Invitation & Response (Lines 59-79)
| Lines | Topic | Schema Tables | Status |
|-------|-------|---------------|--------|
| 59-64 | Invitation Popup | RfqInvitations | ✅ Mapped |
| 65-79 | Response Status Flow | RfqInvitations, RfqInvitationHistory | ✅ Mapped |

#### Quotation Submission (Lines 80-135)
| Lines | Topic | Schema Tables | Status |
|-------|-------|---------------|--------|
| 80-89 | Header Information | Rfqs (read-only) | ✅ Mapped |
| 90-92 | Product Items | RfqItems (read-only) | ✅ Mapped |
| 93-118 | Quotation Pricing | QuotationItems | ✅ Mapped |
| 119-120 | Additional Documents | QuotationDocuments | ✅ Mapped |
| 121-135 | Q&A System | QnAThreads, QnAMessages | ✅ Mapped |

---

## SECTION 2: Supplier Registration Form

### Business Documentation Mapping (Lines 1-48)

```
Line 1:  🔶 SUPPLIERS WORKFLOW
Line 2:  ### Form ข้างล่างใช้ 2 หน้า ดังนี้ หน้าจอ ลงทะเบียน Supplier และ หน้าจอ แก้ไขข้อมูลลงทะเบียน Supplier
Line 3:  หัวข้อ ข้อมูลบริษัท
Line 4:  ประเภทบุคคล *  input radio bution บุคคลธรรมดา หรือ นิติบุคคล
Line 5:  เลขประจำตัวผู้เสียภาษี *
Line 6:  ชื่อบริษัท/หน่วยงาน *
Line 7:  ประเภทธุรกิจ ดึงข้อมมาแสดง (Category)
Line 8:  ประเภทสินค้า/บริการ  ดึงข้อมมาแสดง (Subcategory)
Line 9:  ประเภทงานของบริษัท * input dropdownlist ซื้อ, ขาย , ทั้งซื้อและขาย
Line 10: ขอบเขตการดำเนินธุรกิจ *
Line 11: สกุลเงิน * input dropdownlist
Line 12: ทุนจดทะเบียน *
Line 13: วันที่ก่อตั้งบริษัท *
Line 14: อีเมลบริษัท *
Line 15: เบอร์โทรบริษัท *
```

### Database Schema Mapping

#### Suppliers Table (Lines 458-493)

```sql
CREATE TABLE "Suppliers" (
  "Id" BIGSERIAL PRIMARY KEY,
  "TaxId" VARCHAR(20) UNIQUE,                          -- Line 5: เลขประจำตัวผู้เสียภาษี *
  "CompanyNameTh" VARCHAR(200) NOT NULL,               -- Line 6: ชื่อบริษัท/หน่วยงาน *
  "CompanyNameEn" VARCHAR(200),
  "BusinessTypeId" SMALLINT NOT NULL REFERENCES "BusinessTypes"("Id"),  -- Line 4: ประเภทบุคคล *
  "JobTypeId" SMALLINT NOT NULL REFERENCES "JobTypes"("Id"),             -- Line 9: ประเภทงานของบริษัท *
  "RegisteredCapital" DECIMAL(15,2),                   -- Line 12: ทุนจดทะเบียน *
  "RegisteredCapitalCurrencyId" BIGINT REFERENCES "Currencies"("Id"),    -- Line 11: สกุลเงิน *
  "DefaultCurrencyId" BIGINT REFERENCES "Currencies"("Id"),              -- Line 11: สกุลเงิน *
  "CompanyEmail" VARCHAR(100),                         -- Line 14: อีเมลบริษัท *
  "CompanyPhone" VARCHAR(20),                          -- Line 15: เบอร์โทรบริษัท *
  "CompanyFax" VARCHAR(20),
  "CompanyWebsite" VARCHAR(200),
  "AddressLine1" VARCHAR(200),                         -- Line 17: ที่อยู่ 1 *
  "AddressLine2" VARCHAR(200),                         -- Line 18: ที่อยู่ 2
  "City" VARCHAR(100),                                 -- Line 19: เมือง *
  "Province" VARCHAR(100),                             -- Line 20: รัฐ/จังหวัด *
  "PostalCode" VARCHAR(20),                            -- Line 21: รหัสไปรษณีย์ *
  "CountryId" BIGINT REFERENCES "Countries"("Id"),     -- Line 22: ประเทศ *
  "BusinessScope" TEXT,                                -- Line 10: ขอบเขตการดำเนินธุรกิจ *
  "FoundedDate" DATE,                                  -- Line 13: วันที่ก่อตั้งบริษัท *
  "InvitedByUserId" BIGINT REFERENCES "Users"("Id"),
  "InvitedByCompanyId" BIGINT REFERENCES "Companies"("Id"),
  "InvitedAt" TIMESTAMP,
  "RegisteredAt" TIMESTAMP,
  "ApprovedByUserId" BIGINT REFERENCES "Users"("Id"),
  "ApprovedAt" TIMESTAMP,
  "Status" VARCHAR(20) DEFAULT 'PENDING',              -- Line 54, 56: Status flow
  "DeclineReason" TEXT,
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "UpdatedAt" TIMESTAMP,

  CONSTRAINT "chk_supplier_status" CHECK ("Status" IN ('PENDING','COMPLETED','DECLINED'))
);
```

#### BusinessTypes Table (Lines 52-60)
```sql
-- Line 4: "ประเภทบุคคล *  input radio button บุคคลธรรมดา หรือ นิติบุคคล"
CREATE TABLE "BusinessTypes" (
  "Id" SMALLINT PRIMARY KEY,
  "Code" VARCHAR(20) UNIQUE NOT NULL,
  "NameTh" VARCHAR(50) NOT NULL,                       -- "บุคคลธรรมดา" or "นิติบุคคล"
  "NameEn" VARCHAR(50),
  "SortOrder" SMALLINT,
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE "BusinessTypes" IS 'ประเภทธุรกิจ (บุคคลธรรมดา/นิติบุคคล)';
```

#### JobTypes Table (Lines 65-76)
```sql
-- Line 9: "ประเภทงานของบริษัท * input dropdownlist ซื้อ, ขาย , ทั้งซื้อและขาย"
CREATE TABLE "JobTypes" (
  "Id" SMALLINT PRIMARY KEY,
  "Code" VARCHAR(20) UNIQUE NOT NULL,
  "NameTh" VARCHAR(50) NOT NULL,                       -- "ซื้อ", "ขาย", "ทั้งซื้อและขาย"
  "NameEn" VARCHAR(50),
  "ForSupplier" BOOLEAN DEFAULT TRUE,
  "ForRfq" BOOLEAN DEFAULT TRUE,
  "PriceComparisonRule" VARCHAR(10),                   -- MIN/MAX
  "SortOrder" SMALLINT,
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 2.1 Supplier Registration Query (Lines 3-22)

```sql
-- Register new supplier (Lines 51-58)
BEGIN;

-- Step 1: Insert Supplier (Lines 4-22)
INSERT INTO "Suppliers" (
  "TaxId",                                             -- Line 5: เลขประจำตัวผู้เสียภาษี *
  "CompanyNameTh",                                     -- Line 6: ชื่อบริษัท/หน่วยงาน *
  "CompanyNameEn",
  "BusinessTypeId",                                    -- Line 4: บุคคลธรรมดา/นิติบุคคล *
  "JobTypeId",                                         -- Line 9: ซื้อ/ขาย/ทั้งสอง *
  "BusinessScope",                                     -- Line 10: ขอบเขตการดำเนินธุรกิจ *
  "RegisteredCapitalCurrencyId",                       -- Line 11: สกุลเงิน *
  "RegisteredCapital",                                 -- Line 12: ทุนจดทะเบียน *
  "FoundedDate",                                       -- Line 13: วันที่ก่อตั้งบริษัท *
  "CompanyEmail",                                      -- Line 14: อีเมลบริษัท *
  "CompanyPhone",                                      -- Line 15: เบอร์โทรบริษัท *
  "AddressLine1",                                      -- Line 17: ที่อยู่ 1 *
  "AddressLine2",                                      -- Line 18: ที่อยู่ 2
  "City",                                              -- Line 19: เมือง *
  "Province",                                          -- Line 20: รัฐ/จังหวัด *
  "PostalCode",                                        -- Line 21: รหัสไปรษณีย์ *
  "CountryId",                                         -- Line 22: ประเทศ *
  "DefaultCurrencyId",                                 -- Same as RegisteredCapitalCurrencyId
  "Status",                                            -- Line 56: "Pending"
  "RegisteredAt"
) VALUES (
  @TaxId,
  @CompanyNameTh,
  @CompanyNameEn,
  @BusinessTypeId,
  @JobTypeId,
  @BusinessScope,
  @CurrencyId,
  @RegisteredCapital,
  @FoundedDate,
  @CompanyEmail,
  @CompanyPhone,
  @AddressLine1,
  @AddressLine2,
  @City,
  @Province,
  @PostalCode,
  @CountryId,
  @CurrencyId,
  'PENDING',                                           -- Line 56
  CURRENT_TIMESTAMP
)
RETURNING "Id" AS "SupplierId";

COMMIT;
```

### 2.2 Contact Management (Lines 23-34)

```
Line 23: หัวข้อ ผู้ติดต่อ ปุ่ม เพิ่มผู้ติดต่อ จาก pop up ลงไปในตาราง ผู้ติดต่อ
Line 24: ปุ่ม เพิ่มผู้ติดต่อ ฟังก์ชัน Pop up เพิ่มผู้ติดต่อ ผู้ติดต่อคนที่ 1 - N
Line 25: ชื่อ *
Line 26: นามสกุล *
Line 27: เบอร์มือถือ *
Line 28: ตำแหน่งงาน *
Line 29: อีเมล *
Line 30: รหัสผ่าน *
Line 31: ยืนยันรหัสผ่าน *
Line 32: กำหนดข้อมูลนี้เป็นผู้ติดต่อหลัก
Line 33: หมายเหตุ ผู้ติดต่อคนที่ N หมายถึง จำนวนที่สามารถเพิ่มได้เรื่อยๆ  แต่ต้อง กำหนดข้อมูลนี้เป็นผู้ติดต่อหลัก อย่างน้อย 1 คน
Line 34: ตาราง ผู้ติดต่อ Col ผู้ติดต่อหลัก | ชื่อ-นามสกุล | เบอร์โทรศัพท์มือถือ | ตำแหน่งงาน | อีเมล | จัดการ
```

#### SupplierContacts Table (Lines 498-530)

```sql
CREATE TABLE "SupplierContacts" (
  "Id" BIGSERIAL PRIMARY KEY,
  "SupplierId" BIGINT NOT NULL REFERENCES "Suppliers"("Id"),
  "FirstName" VARCHAR(100) NOT NULL,                   -- Line 25: ชื่อ *
  "LastName" VARCHAR(100) NOT NULL,                    -- Line 26: นามสกุล *
  "Position" VARCHAR(100),                             -- Line 28: ตำแหน่งงาน *
  "Email" VARCHAR(100) NOT NULL,                       -- Line 29: อีเมล *
  "PhoneNumber" VARCHAR(20),
  "MobileNumber" VARCHAR(20),                          -- Line 27: เบอร์มือถือ *
  "PreferredLanguage" VARCHAR(5) DEFAULT 'th',
  "PasswordHash" VARCHAR(255),                         -- Line 30: รหัสผ่าน * (BCrypt)
  "SecurityStamp" VARCHAR(100),
  "IsEmailVerified" BOOLEAN DEFAULT FALSE,
  "EmailVerifiedAt" TIMESTAMP,
  "PasswordResetToken" VARCHAR(255),
  "PasswordResetExpiry" TIMESTAMP,
  "LastLoginAt" TIMESTAMP,
  "FailedLoginAttempts" INT DEFAULT 0,
  "LockoutEnd" TIMESTAMP WITH TIME ZONE,
  "CanSubmitQuotation" BOOLEAN DEFAULT TRUE,
  "CanReceiveNotification" BOOLEAN DEFAULT TRUE,
  "CanViewReports" BOOLEAN DEFAULT FALSE,
  "IsPrimaryContact" BOOLEAN DEFAULT FALSE,            -- Line 32: กำหนดข้อมูลนี้เป็นผู้ติดต่อหลัก
  "ReceiveSMS" BOOLEAN DEFAULT FALSE,
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "CreatedBy" BIGINT,
  "UpdatedAt" TIMESTAMP,
  "UpdatedBy" BIGINT,

  UNIQUE("SupplierId", "Email"),
  CONSTRAINT "chk_contact_language" CHECK ("PreferredLanguage" IN ('th','en'))
);
```

#### Insert Contacts (Lines 24-33)
```sql
-- Line 24: "ปุ่ม เพิ่มผู้ติดต่อ ฟังก์ชัน Pop up เพิ่มผู้ติดต่อ ผู้ติดต่อคนที่ 1 - N"
-- Line 33: "ผู้ติดต่อคนที่ N หมายถึง จำนวนที่สามารถเพิ่มได้เรื่อยๆ
--          แต่ต้อง กำหนดข้อมูลนี้เป็นผู้ติดต่อหลัก อย่างน้อย 1 คน"

-- Validation: At least one primary contact required
WITH contact_check AS (
  SELECT COUNT(*) AS "PrimaryCount"
  FROM "SupplierContacts"
  WHERE "SupplierId" = @SupplierId
    AND "IsPrimaryContact" = TRUE
    AND "IsActive" = TRUE
)
SELECT
  CASE
    WHEN "PrimaryCount" = 0 THEN 'ERROR: At least one primary contact required'
    ELSE 'OK'
  END AS "ValidationResult"
FROM contact_check;

-- Insert contact
INSERT INTO "SupplierContacts" (
  "SupplierId",
  "FirstName",                                         -- Line 25: ชื่อ *
  "LastName",                                          -- Line 26: นามสกุล *
  "MobileNumber",                                      -- Line 27: เบอร์มือถือ *
  "Position",                                          -- Line 28: ตำแหน่งงาน *
  "Email",                                             -- Line 29: อีเมล *
  "PasswordHash",                                      -- Line 30, 31: รหัสผ่าน (validated)
  "SecurityStamp",
  "IsPrimaryContact",                                  -- Line 32: checkbox
  "PreferredLanguage",
  "IsActive"
) VALUES (
  @SupplierId,
  @FirstName,
  @LastName,
  @MobileNumber,
  @Position,
  @Email,
  @PasswordHash,  -- BCrypt.HashPassword(@Password, workFactor: 12)
  @SecurityStamp, -- Generate GUID
  @IsPrimaryContact,
  'th',
  TRUE
)
RETURNING "Id";

-- If setting new primary contact, unset others (only 1 primary allowed per supplier)
UPDATE "SupplierContacts"
SET
  "IsPrimaryContact" = FALSE,
  "UpdatedAt" = CURRENT_TIMESTAMP
WHERE "SupplierId" = @SupplierId
  AND "Id" != @NewContactId
  AND "IsPrimaryContact" = TRUE;
```

#### Get Contact List (Line 34)
```sql
-- Line 34: "ตาราง ผู้ติดต่อ Col ผู้ติดต่อหลัก | ชื่อ-นามสกุล | เบอร์โทรศัพท์มือถือ | ตำแหน่งงาน | อีเมล | จัดการ"
SELECT
  "Id",
  "IsPrimaryContact",                                  -- Column: ผู้ติดต่อหลัก
  "FirstName" || ' ' || "LastName" AS "FullName",     -- Column: ชื่อ-นามสกุล
  "MobileNumber",                                      -- Column: เบอร์โทรศัพท์มือถือ
  "Position",                                          -- Column: ตำแหน่งงาน
  "Email",                                             -- Column: อีเมล
  "IsActive",
  "CreatedAt"
FROM "SupplierContacts"
WHERE "SupplierId" = @SupplierId
ORDER BY "IsPrimaryContact" DESC, "CreatedAt" ASC;
```

### 2.3 Category Management (Lines 7-8)

```
Line 7: ประเภทธุรกิจ ดึงข้อมมาแสดง (Category)
Line 8: ประเภทสินค้า/บริการ  ดึงข้อมมาแสดง (Subcategory)
```

#### SupplierCategories Table (Lines 536-545)
```sql
CREATE TABLE "SupplierCategories" (
  "Id" BIGSERIAL PRIMARY KEY,
  "SupplierId" BIGINT NOT NULL REFERENCES "Suppliers"("Id"),
  "CategoryId" BIGINT NOT NULL REFERENCES "Categories"("Id"),          -- Line 7
  "SubcategoryId" BIGINT REFERENCES "Subcategories"("Id"),             -- Line 8
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  UNIQUE("SupplierId", "CategoryId", "SubcategoryId")
);

COMMENT ON TABLE "SupplierCategories" IS 'Category ที่ Supplier ให้บริการ';
```

#### Insert Categories
```sql
-- Insert supplier categories (Lines 7-8)
-- Can have multiple categories/subcategories
INSERT INTO "SupplierCategories" (
  "SupplierId",
  "CategoryId",                                        -- Line 7: Category
  "SubcategoryId"                                      -- Line 8: Subcategory (optional)
)
SELECT
  @SupplierId,
  unnest(@CategoryIds::BIGINT[]),
  unnest(@SubcategoryIds::BIGINT[])  -- Use NULL for categories without subcategory
ON CONFLICT ("SupplierId", "CategoryId", "SubcategoryId")
DO UPDATE SET
  "IsActive" = TRUE;

-- Get available categories (Line 7)
SELECT
  "Id",
  "CategoryCode",
  "CategoryNameTh",
  "CategoryNameEn",
  "SortOrder"
FROM "Categories"
WHERE "IsActive" = TRUE
ORDER BY "SortOrder", "CategoryNameTh";

-- Get subcategories for selected category (Line 8)
SELECT
  "Id",
  "SubcategoryCode",
  "SubcategoryNameTh",
  "SubcategoryNameEn",
  "SortOrder"
FROM "Subcategories"
WHERE "CategoryId" = @CategoryId
  AND "IsActive" = TRUE
ORDER BY "SortOrder", "SubcategoryNameTh";
```

---

## SECTION 3: Supplier Documents Management

### Business Documentation Mapping (Lines 36-48)

```
Line 36: หัวข้อ เอกสาร (Documents)  ส่วนนี้สำหรับอัปโหลดเอกสารประกอบที่จำเป็นสำหรับการลงทะเบียน:
Line 37: กรณีเลือก  นิติบุคคล
Line 38: *หนังสือรับรอง:  บังคับ
Line 39: *ภ.พ.20:  บังคับ
Line 40: *รายงานทางการเงิน:  บังคับ
Line 41: *แนะนำบริษัท (Company Profile):  บังคับ
Line 42: *หนังสือสัญญารักษาความลับ (NDA) :  บังคับ
Line 43: อื่นๆ :  ไม่บังคับ
Line 44: กรณีเลือก  บุคคลธรรมดา
Line 45: *สำเนาบัตรประชาชน:  บังคับ
Line 46: *หนังสือสัญญารักษาความลับ (NDA) :  บังคับ
Line 47: สมุ
Line 48: อื่นๆ :  ไม่บังคับ
```

### Database Schema Mapping

#### SupplierDocuments Table (Lines 550-562)
```sql
CREATE TABLE "SupplierDocuments" (
  "Id" BIGSERIAL PRIMARY KEY,
  "SupplierId" BIGINT NOT NULL REFERENCES "Suppliers"("Id"),
  "DocumentType" VARCHAR(50) NOT NULL,                 -- Lines 38-46: Document type codes
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
```

### 3.1 Document Type Validation (Lines 37-48)

#### Document Requirements by BusinessType
```csharp
// Line 4: BusinessType determines required documents
public static class SupplierDocumentRequirements
{
    // Line 37: "กรณีเลือก  นิติบุคคล"
    public static readonly string[] JuristicPersonRequired = new[]
    {
        "CERTIFICATE",           // Line 38: หนังสือรับรอง (บังคับ)
        "PHO_PHO_20",            // Line 39: ภ.พ.20 (บังคับ)
        "FINANCIAL_REPORT",      // Line 40: รายงานทางการเงิน (บังคับ)
        "COMPANY_PROFILE",       // Line 41: แนะนำบริษัท (บังคับ)
        "NDA"                    // Line 42: หนังสือสัญญารักษาความลับ (บังคับ)
    };

    // Line 44: "กรณีเลือก  บุคคลธรรมดา"
    public static readonly string[] NaturalPersonRequired = new[]
    {
        "ID_CARD",               // Line 45: สำเนาบัตรประชาชน (บังคับ)
        "NDA"                    // Line 46: หนังสือสัญญารักษาความลับ (บังคับ)
    };

    // Lines 43, 48: "อื่นๆ :  ไม่บังคับ"
    public static readonly string[] Optional = new[]
    {
        "OTHER"
    };
}
```

### 3.2 Upload Documents
```sql
-- Upload supplier document
INSERT INTO "SupplierDocuments" (
  "SupplierId",
  "DocumentType",                                      -- Lines 38-46: Type codes
  "DocumentName",
  "FileName",
  "FilePath",
  "FileSize",
  "MimeType",
  "UploadedBy"
) VALUES (
  @SupplierId,
  @DocumentType,
  @DocumentName,
  @FileName,
  @FilePath,  -- Azure Blob Storage URL
  @FileSize,
  @MimeType,
  @ContactId
);
```

### 3.3 Validation: Required Documents Check
```sql
-- Validate all required documents are uploaded (Lines 37-46)
WITH required_docs AS (
  SELECT unnest(
    CASE
      -- Line 37: นิติบุคคล
      WHEN s."BusinessTypeId" = (SELECT "Id" FROM "BusinessTypes" WHERE "Code" = 'JURISTIC')
      THEN ARRAY['CERTIFICATE', 'PHO_PHO_20', 'FINANCIAL_REPORT', 'COMPANY_PROFILE', 'NDA']

      -- Line 44: บุคคลธรรมดา
      WHEN s."BusinessTypeId" = (SELECT "Id" FROM "BusinessTypes" WHERE "Code" = 'NATURAL')
      THEN ARRAY['ID_CARD', 'NDA']

      ELSE ARRAY[]::VARCHAR[]
    END
  ) AS "RequiredType"
  FROM "Suppliers" s
  WHERE s."Id" = @SupplierId
),
uploaded_docs AS (
  SELECT DISTINCT "DocumentType"
  FROM "SupplierDocuments"
  WHERE "SupplierId" = @SupplierId
    AND "IsActive" = TRUE
)
SELECT
  rd."RequiredType",
  CASE
    WHEN ud."DocumentType" IS NOT NULL THEN 'Uploaded'
    ELSE 'Missing'
  END AS "Status"
FROM required_docs rd
LEFT JOIN uploaded_docs ud ON rd."RequiredType" = ud."DocumentType"
ORDER BY
  CASE rd."RequiredType"
    WHEN 'CERTIFICATE' THEN 1          -- Line 38
    WHEN 'PHO_PHO_20' THEN 2           -- Line 39
    WHEN 'FINANCIAL_REPORT' THEN 3     -- Line 40
    WHEN 'COMPANY_PROFILE' THEN 4      -- Line 41
    WHEN 'NDA' THEN 5                  -- Line 42, 46
    WHEN 'ID_CARD' THEN 6              -- Line 45
    ELSE 99
  END;
```

### 3.4 Registration Actions (Lines 51-58)

```
Line 51: การดำเนินการบนหน้าจอ
Line 52: กรณี แก้ไขข้อมูลลงทะเบียน Supplier
Line 53: ปุ่ม "บันทึกการเปลี่ยนแปลง"
Line 54: ฟังก์ชัน:  บันทึกข้อมูลเป็น สถานะ "Pending" และส่งเมล์ไปหา "Purchasing" พร้อมเด้ง Notification โดย Purchasing จะผูกกับ Category และ Subcategory ซึ่ง Purchasing จะเข้ามาตรวจ Supplierครั้งที่ 1
Line 55: กรณี ลงทะเบียน Supplier
Line 56: ปุ่ม "ลงทะเบียน" (Register):
Line 57: ฟังก์ชัน:  บันทึกข้อมูลเป็น สถานะ "Pending" และส่งเมล์ไปหา "Purchasing" พร้อมเด้ง Notification โดย Purchasing จะผูกกับ Category และ Subcategory ซึ่ง Purchasing จะเข้ามาตรวจ Supplierครั้งที่ 1
```

#### Register Supplier (Line 56)
```sql
-- Line 56: "ปุ่ม ลงทะเบียน (Register)"
-- Line 57: "บันทึกข้อมูลเป็น สถานะ Pending และส่งเมล์ไปหา Purchasing พร้อมเด้ง Notification"

-- Update supplier status to PENDING
UPDATE "Suppliers"
SET
  "Status" = 'PENDING',                                -- Line 57
  "RegisteredAt" = CURRENT_TIMESTAMP,
  "UpdatedAt" = CURRENT_TIMESTAMP
WHERE "Id" = @SupplierId;

-- Get PURCHASING users for notification (bound by category)
-- Line 57: "Purchasing จะผูกกับ Category และ Subcategory"
WITH supplier_categories AS (
  SELECT
    sc."CategoryId",
    sc."SubcategoryId"
  FROM "SupplierCategories" sc
  WHERE sc."SupplierId" = @SupplierId
    AND sc."IsActive" = TRUE
),
purchasing_users AS (
  SELECT DISTINCT
    u."Id" AS "UserId",
    u."Email",
    u."FirstNameTh",
    u."PreferredLanguage"
  FROM supplier_categories scat
  JOIN "UserCategoryBindings" ucb ON
    ucb."CategoryId" = scat."CategoryId"
    AND (ucb."SubcategoryId" IS NULL OR ucb."SubcategoryId" = scat."SubcategoryId")
  JOIN "UserCompanyRoles" ucr ON ucb."UserCompanyRoleId" = ucr."Id"
  JOIN "Users" u ON ucr."UserId" = u."Id"
  JOIN "Roles" r ON ucr."PrimaryRoleId" = r."Id"
  WHERE r."RoleCode" = 'PURCHASING'
    AND ucr."IsActive" = TRUE
    AND u."IsActive" = TRUE
)
SELECT * FROM purchasing_users;

-- Insert notifications for each PURCHASING user
INSERT INTO "Notifications" (
  "Type",
  "Priority",
  "UserId",
  "RfqId",
  "Title",
  "Message",
  "IconType",
  "ActionUrl",
  "Channels"
)
SELECT
  'SUPPLIER_NEW_REGISTRATION',
  'NORMAL',
  pu."UserId",
  NULL,
  'Supplier ลงทะเบียนใหม่',
  s."CompanyNameTh" || ' ได้ลงทะเบียนเข้าระบบ กรุณาตรวจสอบข้อมูล',
  'SUPPLIER_NEW',
  '/purchasing/suppliers/' || s."Id",
  ARRAY['IN_APP', 'EMAIL']
FROM "Suppliers" s
CROSS JOIN purchasing_users pu
WHERE s."Id" = @SupplierId;
```

#### Update Supplier (Line 53)
```sql
-- Line 53: "ปุ่ม บันทึกการเปลี่ยนแปลง"
-- Line 54: "บันทึกข้อมูลเป็น สถานะ Pending และส่งเมล์ไปหา Purchasing พร้อมเด้ง Notification"

UPDATE "Suppliers"
SET
  "TaxId" = @TaxId,
  "CompanyNameTh" = @CompanyNameTh,
  "BusinessTypeId" = @BusinessTypeId,
  "JobTypeId" = @JobTypeId,
  "BusinessScope" = @BusinessScope,
  "RegisteredCapitalCurrencyId" = @CurrencyId,
  "RegisteredCapital" = @RegisteredCapital,
  "FoundedDate" = @FoundedDate,
  "CompanyEmail" = @CompanyEmail,
  "CompanyPhone" = @CompanyPhone,
  "AddressLine1" = @AddressLine1,
  "AddressLine2" = @AddressLine2,
  "City" = @City,
  "Province" = @Province,
  "PostalCode" = @PostalCode,
  "CountryId" = @CountryId,
  "Status" = 'PENDING',                                -- Line 54: Reset to PENDING
  "UpdatedAt" = CURRENT_TIMESTAMP
WHERE "Id" = @SupplierId;

-- Send notification (same as registration)
```

---

## SECTION 4: Invitation Response Flow

### Business Documentation Mapping (Lines 59-79)

```
Line 59: Supplier ที่สถานะ Completed หรือ ที่มีอยู่แล้วในระบบ
Line 60: ### หน้าจอ PopUp Preview คำเชิญ ให้เข้าร่วมรายการเสนอราคา > คลิกจาก แดชบอร์ด (ต้อง sign in ก่อนแล้วระบบจะพาไป แดชบอร์ด)
Line 61: ปุ่ม เข้าร่วม
Line 62: ฟังก์ชัน:   ปรับสถานะ "ตอบรับ และเข้าร่วม"  แต่ Not Submitted
Line 63: ปุ่ม ไม่เข้าร่วม
Line 64: ฟังก์ชัน:   ปรับสถานะ "ตอบรับ แต่ปฏิเสธ"
Line 65: สถานะการเข้าร่วม:
Line 66: กรณี มีSupplierอยู่แล้วในระบบ Purchasing => กด Accept และ เชิญ Supplier เสนอราคา  => สถานะ ยังไม่ตอบรับ
Line 67: กรณี Supplier ลงทะเบียนใหม่ Purchasing Approver ปรับสถานะเป็น "Completed" ส่งอีเมล์แจ้ง "Purchasing" พร้อมเด้ง Notification และส่ง อีเมลรับคำเชิญเสนอราคา => สถานะ ยังไม่ตอบรับ
Line 69: Supplier
Line 70: สถานะ ยังไม่ตอบรับ      => ไม่ชัดเจน ?? ไม่อ่านเมล์ ? ทำเป็นไม่เห็น ไม่สนใจ?
Line 71: สถานะ ตอบรับ แต่ปฏิเสธ  => PopUp Preview คำเชิญ ให้เข้าร่วมรายการเสนอราคา แต่ กด ไม่เข้าร่วม
Line 72: สถานะ ตอบรับ และเข้าร่วม => Not Submitted  = PopUp Preview คำเชิญ ให้เข้าร่วมรายการเสนอราคา + กดเข้าร่วม แต่ยังไม่เข้าร่วมเสนอราคา(หน้าจอ ใส่ราคา + ส่งคำถาม)
Line 73: สถานะ ตอบรับ และเข้าร่วม => Submitted	    = PopUp Preview คำเชิญ ให้เข้าร่วมรายการเสนอราคา + กดเข้าร่วม และ เข้าร่วมเสนอราคาแล้ว(เข้าร่วมเสนอราคา(หน้าจอ ใส่ราคา + ส่งคำถาม))
Line 75: หมายเหตุ :
Line 76: - ถ้า Supplier เพิกเฉย ไม่กด เข้าร่วม หรือ ไม่เข้าร่วม  จะ Declined โดยดูจาก วันที่ต้องการใบเสนอราคา
Line 77: - ในกรณีที่ Supplier กด "ตอบรับ แต่ปฏิเสธ" ไปแล้ว  ถ้ายังอยู่ใน ระยะเวลา  สามารถ  เปลี่ยนไป "ตอบรับและเข้าร่วม" ได้ถ้ายังอยู่ใน ระยะเวลา
Line 78: - เมื่อผู้ติดต่อหลายคน login เข้ามา ทุกคนจะเห็นหน้า แดชบอร์ด จะมี รายการเสนอราคาทั้งหมด, ยังไม่ตอบรับ,ตอบรับ และเข้าร่วม,ตอบรับ แต่ปฏิเสธ และ คำเชิญ ให้เข้าร่วมรายการเสนอราคา
Line 79: ที่สามารถกด ดูpopupรายละเอียดได้ ซึ่ง คนที่ กด "เข้าร่วม" แปลว่า คนนั้นจะเป็นคนเสนอราคา ส่งคำถาม คุยงานกับคนนั้นจนจบการประกวดราคา ในมุมมอง คนที่ กด "เข้าร่วม"แล้ว หน้า ดูรายการเสนอราคาของฉัน จะเห็นแค่รายการที่กดเข้าร่วมไป รวมถึงหน้าถาม/ตอบ จัดซื้อ
```

### Database Schema Mapping

#### RfqInvitations Table (Lines 760-787)
```sql
CREATE TABLE "RfqInvitations" (
  "Id" BIGSERIAL PRIMARY KEY,
  "RfqId" BIGINT NOT NULL REFERENCES "Rfqs"("Id") ON DELETE CASCADE,
  "SupplierId" BIGINT NOT NULL REFERENCES "Suppliers"("Id"),
  "InvitedAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "InvitedByUserId" BIGINT NOT NULL REFERENCES "Users"("Id"),
  "ResponseStatus" VARCHAR(30) DEFAULT 'NO_RESPONSE',  -- Line 70: ยังไม่ตอบรับ
  "RespondedAt" TIMESTAMP,
  "Decision" VARCHAR(30) DEFAULT 'PENDING',            -- Lines 70-73: Status flow
  "DecisionReason" TEXT,
  "RespondedByContactId" BIGINT REFERENCES "SupplierContacts"("Id"),  -- Line 79
  "DecisionChangeCount" INT DEFAULT 0,                 -- Line 77: Can change decision
  "LastDecisionChangeAt" TIMESTAMP,
  "ReBidCount" INT DEFAULT 0,
  "LastReBidAt" TIMESTAMP,
  "RespondedIpAddress" INET,
  "RespondedUserAgent" TEXT,
  "RespondedDeviceInfo" TEXT,
  "AutoDeclinedAt" TIMESTAMP,                          -- Line 76: Auto-decline
  "IsManuallyAdded" BOOLEAN DEFAULT FALSE,
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "UpdatedAt" TIMESTAMP,

  CONSTRAINT "uk_rfq_supplier" UNIQUE("RfqId", "SupplierId"),
  CONSTRAINT "chk_response_status" CHECK ("ResponseStatus" IN ('NO_RESPONSE','RESPONDED')),
  CONSTRAINT "chk_invitation_decision" CHECK ("Decision" IN
    ('PENDING','PARTICIPATING','NOT_PARTICIPATING','AUTO_DECLINED'))  -- Lines 70-73
);
```

#### RfqInvitationHistory Table (Lines 793-804)
```sql
-- Line 77: "ในกรณีที่ Supplier กด ตอบรับ แต่ปฏิเสธ ไปแล้ว ... สามารถเปลี่ยนไป ตอบรับและเข้าร่วม ได้"
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
```

### 4.1 Status Flow Mapping

#### Status Definitions (Lines 70-73)
```
Line 70: สถานะ ยังไม่ตอบรับ
  => Decision = 'PENDING' AND ResponseStatus = 'NO_RESPONSE'

Line 71: สถานะ ตอบรับ แต่ปฏิเสธ
  => Decision = 'NOT_PARTICIPATING' AND ResponseStatus = 'RESPONDED'

Line 72: สถานะ ตอบรับ และเข้าร่วม => Not Submitted
  => Decision = 'PARTICIPATING' AND ResponseStatus = 'RESPONDED'
  => AND NOT EXISTS (SELECT 1 FROM QuotationItems WHERE RfqId = ... AND SupplierId = ... AND SubmittedAt IS NOT NULL)

Line 73: สถานะ ตอบรับ และเข้าร่วม => Submitted
  => Decision = 'PARTICIPATING' AND ResponseStatus = 'RESPONDED'
  => AND EXISTS (SELECT 1 FROM QuotationItems WHERE RfqId = ... AND SupplierId = ... AND SubmittedAt IS NOT NULL)
```

### 4.2 Accept Invitation (Lines 61-62)

```sql
-- Line 61: "ปุ่ม เข้าร่วม"
-- Line 62: "ฟังก์ชัน: ปรับสถานะ ตอบรับ และเข้าร่วม แต่ Not Submitted"

BEGIN;

-- Update invitation
UPDATE "RfqInvitations"
SET
  "ResponseStatus" = 'RESPONDED',                      -- Line 62
  "Decision" = 'PARTICIPATING',                        -- Line 62
  "RespondedAt" = CURRENT_TIMESTAMP,
  "RespondedByContactId" = @ContactId,                 -- Line 79: Track who responded
  "DecisionChangeCount" = "DecisionChangeCount" + 1,   -- Line 77
  "LastDecisionChangeAt" = CURRENT_TIMESTAMP,
  "RespondedIpAddress" = @ClientIp,
  "RespondedUserAgent" = @UserAgent,
  "RespondedDeviceInfo" = @DeviceInfo,
  "UpdatedAt" = CURRENT_TIMESTAMP
WHERE "RfqId" = @RfqId
  AND "SupplierId" = @SupplierId;

-- Insert history record (Line 77)
INSERT INTO "RfqInvitationHistory" (
  "InvitationId",
  "DecisionSequence",
  "FromDecision",
  "ToDecision",
  "ChangedByContactId",
  "ChangedAt"
)
SELECT
  ri."Id",
  ri."DecisionChangeCount",
  'PENDING',                                           -- From: Line 70
  'PARTICIPATING',                                     -- To: Line 72
  @ContactId,
  CURRENT_TIMESTAMP
FROM "RfqInvitations" ri
WHERE ri."RfqId" = @RfqId
  AND ri."SupplierId" = @SupplierId;

-- Send notification to PURCHASING
INSERT INTO "Notifications" (
  "Type",
  "Priority",
  "UserId",
  "RfqId",
  "Title",
  "Message",
  "IconType",
  "ActionUrl",
  "Channels"
)
SELECT
  'SUPPLIER_ACCEPTED_INVITATION',
  'NORMAL',
  ri."InvitedByUserId",
  ri."RfqId",
  'Supplier ตอบรับเข้าร่วมแล้ว',
  s."CompanyNameTh" || ' ได้ตอบรับเข้าร่วมประกวดราคา ' || r."RfqNumber",
  'SUPPLIER_APPROVED',
  '/purchasing/rfqs/' || r."Id" || '/suppliers',
  ARRAY['IN_APP', 'EMAIL']
FROM "RfqInvitations" ri
JOIN "Suppliers" s ON ri."SupplierId" = s."Id"
JOIN "Rfqs" r ON ri."RfqId" = r."Id"
WHERE ri."RfqId" = @RfqId
  AND ri."SupplierId" = @SupplierId;

COMMIT;
```

### 4.3 Decline Invitation (Lines 63-64)

```sql
-- Line 63: "ปุ่ม ไม่เข้าร่วม"
-- Line 64: "ฟังก์ชัน: ปรับสถานะ ตอบรับ แต่ปฏิเสธ"

BEGIN;

-- Update invitation
UPDATE "RfqInvitations"
SET
  "ResponseStatus" = 'RESPONDED',
  "Decision" = 'NOT_PARTICIPATING',                    -- Line 64
  "RespondedAt" = CURRENT_TIMESTAMP,
  "RespondedByContactId" = @ContactId,
  "DecisionReason" = @DeclineReason,                   -- Optional reason
  "DecisionChangeCount" = "DecisionChangeCount" + 1,
  "LastDecisionChangeAt" = CURRENT_TIMESTAMP,
  "RespondedIpAddress" = @ClientIp,
  "UpdatedAt" = CURRENT_TIMESTAMP
WHERE "RfqId" = @RfqId
  AND "SupplierId" = @SupplierId;

-- Insert history
INSERT INTO "RfqInvitationHistory" (
  "InvitationId",
  "DecisionSequence",
  "FromDecision",
  "ToDecision",
  "ChangedByContactId",
  "ChangeReason"
)
SELECT
  ri."Id",
  ri."DecisionChangeCount",
  'PENDING',
  'NOT_PARTICIPATING',                                 -- Line 71
  @ContactId,
  @DeclineReason
FROM "RfqInvitations" ri
WHERE ri."RfqId" = @RfqId
  AND ri."SupplierId" = @SupplierId;

-- Send notification to PURCHASING
INSERT INTO "Notifications" (
  "Type",
  "Priority",
  "UserId",
  "RfqId",
  "Title",
  "Message",
  "IconType"
)
SELECT
  'SUPPLIER_DECLINED_INVITATION',
  'NORMAL',
  ri."InvitedByUserId",
  ri."RfqId",
  'Supplier ปฏิเสธคำเชิญ',
  s."CompanyNameTh" || ' ได้ปฏิเสธคำเชิญเข้าร่วมประกวดราคา',
  'SUPPLIER_DECLINED'
FROM "RfqInvitations" ri
JOIN "Suppliers" s ON ri."SupplierId" = s."Id"
WHERE ri."RfqId" = @RfqId
  AND ri."SupplierId" = @SupplierId;

COMMIT;
```

### 4.4 Change Decision (Line 77)

```sql
-- Line 77: "ในกรณีที่ Supplier กด ตอบรับ แต่ปฏิเสธ ไปแล้ว ... สามารถเปลี่ยนไป ตอบรับและเข้าร่วม ได้ถ้ายังอยู่ใน ระยะเวลา"

-- Check if can change decision (before deadline)
SELECT
  ri."Id",
  ri."Decision" AS "CurrentDecision",
  r."QuotationDeadline",
  CASE
    WHEN r."QuotationDeadline" > CURRENT_TIMESTAMP THEN TRUE
    ELSE FALSE
  END AS "CanChange"
FROM "RfqInvitations" ri
JOIN "Rfqs" r ON ri."RfqId" = r."Id"
WHERE ri."RfqId" = @RfqId
  AND ri."SupplierId" = @SupplierId;

-- Change from NOT_PARTICIPATING to PARTICIPATING
BEGIN;

UPDATE "RfqInvitations"
SET
  "Decision" = 'PARTICIPATING',                        -- Change to: Line 72
  "DecisionChangeCount" = "DecisionChangeCount" + 1,
  "LastDecisionChangeAt" = CURRENT_TIMESTAMP,
  "UpdatedAt" = CURRENT_TIMESTAMP
WHERE "RfqId" = @RfqId
  AND "SupplierId" = @SupplierId
  AND "Decision" = 'NOT_PARTICIPATING'                 -- From: Line 71
  AND EXISTS (
    SELECT 1 FROM "Rfqs" r
    WHERE r."Id" = @RfqId
      AND r."QuotationDeadline" > CURRENT_TIMESTAMP   -- Line 77: ถ้ายังอยู่ใน ระยะเวลา
  );

-- Insert history
INSERT INTO "RfqInvitationHistory" (
  "InvitationId",
  "DecisionSequence",
  "FromDecision",
  "ToDecision",
  "ChangedByContactId"
)
VALUES (
  @InvitationId,
  (SELECT "DecisionChangeCount" FROM "RfqInvitations" WHERE "Id" = @InvitationId),
  'NOT_PARTICIPATING',
  'PARTICIPATING',
  @ContactId
);

COMMIT;
```

### 4.5 Auto-Decline (Line 76)

```sql
-- Line 76: "ถ้า Supplier เพิกเฉย ไม่กด เข้าร่วม หรือ ไม่เข้าร่วม  จะ Declined โดยดูจาก วันที่ต้องการใบเสนอราคา"

-- Wolverine scheduled job (runs every hour)
UPDATE "RfqInvitations"
SET
  "Decision" = 'AUTO_DECLINED',
  "ResponseStatus" = 'NO_RESPONSE',
  "AutoDeclinedAt" = CURRENT_TIMESTAMP,
  "UpdatedAt" = CURRENT_TIMESTAMP
WHERE "Decision" = 'PENDING'
  AND "ResponseStatus" = 'NO_RESPONSE'
  AND "RfqId" IN (
    SELECT "Id"
    FROM "Rfqs"
    WHERE "QuotationDeadline" < CURRENT_TIMESTAMP      -- Line 76: Past deadline
  );

-- Get auto-declined invitations for notification
SELECT
  ri."Id",
  ri."RfqId",
  r."RfqNumber",
  s."CompanyNameTh",
  ri."InvitedByUserId"
FROM "RfqInvitations" ri
JOIN "Rfqs" r ON ri."RfqId" = r."Id"
JOIN "Suppliers" s ON ri."SupplierId" = s."Id"
WHERE ri."AutoDeclinedAt" IS NOT NULL
  AND ri."AutoDeclinedAt" >= CURRENT_TIMESTAMP - INTERVAL '1 hour';
```

### 4.6 Dashboard Invitation List (Lines 78-79)

```sql
-- Line 78: "ทุกคนจะเห็นหน้า แดชบอร์ด จะมี รายการเสนอราคาทั้งหมด, ยังไม่ตอบรับ, ตอบรับ และเข้าร่วม, ตอบรับ แต่ปฏิเสธ"
-- Line 79: "คนที่ กด เข้าร่วม แปลว่า คนนั้นจะเป็นคนเสนอราคา"

WITH invitation_details AS (
  SELECT
    ri."Id",
    ri."RfqId",
    r."RfqNumber",
    r."ProjectName",
    r."RequiredQuotationDate",
    r."QuotationDeadline",
    c."CategoryNameTh",
    sub."SubcategoryNameTh",
    ri."InvitedAt",
    ri."ResponseStatus",
    ri."Decision",
    ri."RespondedAt",
    ri."RespondedByContactId",
    sc."FirstName" || ' ' || sc."LastName" AS "RespondedBy",  -- Line 79

    -- Line 70-73: Status labels
    CASE ri."Decision"
      WHEN 'PENDING' THEN 'ยังไม่ตอบรับ'                      -- Line 70
      WHEN 'NOT_PARTICIPATING' THEN 'ตอบรับ แต่ปฏิเสธ'       -- Line 71
      WHEN 'PARTICIPATING' THEN 'ตอบรับ และเข้าร่วม'         -- Line 72-73
      WHEN 'AUTO_DECLINED' THEN 'ปฏิเสธอัตโนมัติ'
    END AS "StatusLabel",

    -- Check if quotation submitted (Line 72 vs 73)
    EXISTS (
      SELECT 1
      FROM "QuotationItems" qi
      WHERE qi."RfqId" = ri."RfqId"
        AND qi."SupplierId" = ri."SupplierId"
        AND qi."SubmittedAt" IS NOT NULL
    ) AS "IsSubmitted",

    -- Days remaining
    EXTRACT(DAY FROM (r."QuotationDeadline" - CURRENT_TIMESTAMP)) AS "DaysRemaining"

  FROM "RfqInvitations" ri
  JOIN "Rfqs" r ON ri."RfqId" = r."Id"
  JOIN "Categories" c ON r."CategoryId" = c."Id"
  LEFT JOIN "Subcategories" sub ON r."SubcategoryId" = sub."Id"
  LEFT JOIN "SupplierContacts" sc ON ri."RespondedByContactId" = sc."Id"
  WHERE ri."SupplierId" = @SupplierId
)
SELECT * FROM invitation_details
ORDER BY
  CASE
    WHEN "Decision" = 'PENDING' THEN 1                 -- Priority: Pending first
    WHEN "Decision" = 'PARTICIPATING' THEN 2
    WHEN "Decision" = 'NOT_PARTICIPATING' THEN 3
    WHEN "Decision" = 'AUTO_DECLINED' THEN 4
  END,
  "QuotationDeadline" ASC;
```

---

## SECTION 5: Quotation Submission Form

### Business Documentation Mapping (Lines 80-120)

```
Line 80: ### หน้าจอ ใส่ราคา + ส่งคำถาม(ไม่มี สถานะ Draft)
Line 81: หัวข้อ ใบเสนอราคา (read only)					Supplier (read only)
Line 82: เลขที่เอกสาร(RFQ No.)						ชื่อ-นามสกุล
Line 83: ชื่อโครงงาน/งาน								เบอร์มือถือ
Line 84: กลุ่มสินค้า/บริการ							อีเมล
Line 85: หมวดหมู่ย่อยสินค้า/บริการ						ตำแหน่งงาน
Line 86: บริษัทผู้ร้องขอ								เลขประจำตัวผู้เสียภาษี
Line 87: ผู้จัดซื้อ									ชื่อบริษัท / หน่วยงาน
Line 88: วันที่สิ้นสุดการเสนอราคา						เบอร์โทรบริษัท
Line 89:													เบอร์โทรบริษัท
Line 90: หัวข้อ สินค้า
Line 91: Col ลำดับ | รหัส | สินค้า | ยี่ห้อ | รุ่น | จำนวน | หน่วย |
Line 92: 1											(read only)
Line 93: หัวข้อ เสนอราคาต่อรายสินค้า
Line 94: Col สกุลเงิน| ราคาต่อหน่วย| ราคารวม| ราคาต่อหน่วยของบริษัท(แสดงชื่อสกุลเงินที่ได้จาก DB)| ราคารวมของบริษัท(แสดงชื่อสกุลเงินที่ได้จาก DB)| MOQ (หน่วย)| DLT (วัน)| Credit (วัน)| Warranty (วัน)| Inco Term| หมายเหตุ
Line 96: เสนอราคารายการที่ 1		*สกุลเงิน :  ตัวเลือก dropdownlist [MasterData].สกุลเงิน (ใช้ตัวเดียวกันกับหน้าลงทะเบียน)
Line 97: *ราคาต่อหน่วย :xxxxxx.0000
Line 98: *ราคารวม :xxxxxx.0000   หมายเหตุ  ราคารวม จะคำนวณ auto จาก (จำนวนสินค้า*ราคาต่อหน่วย)
Line 99: *ราคาต่อหน่วยของบริษัท :xxxxxx.0000  หมายเหตุ  ราคาต่อหน่วยของบริษัท จะคำนวณ auto
Line 100: ถ้า สกุลเงินที่เลือกกับdbตรงกัน จะใช้ ราคาต่อหน่วย ที่กรอก
Line 101: ถ้าเลือกไม่ตรง จะไปดูสกุลเงินบริษัทผู้ร้องขอ เป็นสกุลอะไร แล้วใช้สกุลนั้นไปคำนวณกับอัตราแลกเปลี่ยนและราคาต่อหน่วย(ที่adminนำเข้า) =ราคาต่อหน่วยของบริษัท
Line 102: *ราคารวมของบริษัท :xxxxxx.0000 หมายเหตุ  ราคารวมของบริษัท จะคำนวณ auto
Line 103: ถ้า สกุลเงินที่เลือกกับdbตรงกัน จะใช้ ราคารวม ที่กรอก
Line 104: ถ้าเลือกไม่ตรง จะไปดูสกุลเงินบริษัทผู้ร้องขอ เป็นสกุลอะไร แล้วใช้  สกุลนั้นไปคำนวณกับอัตราแลกเปลี่ยนและราคารวม(ที่adminนำเข้า) =ราคารวมของบริษัท
Line 105: MOQ (หน่วย) : 4 digit
Line 106: DLT (วัน) :int
Line 107: Credit (วัน) :int
Line 108: Warranty (วัน) :int
Line 109: Inco Term : [MasterData]incoterm
Line 110: หมายเหตุ :  ใส่หมายเหตุถ้า
Line 117: ใบเสนอราคา *  input upload file สำหรับ Supplier อัปโหลดไฟล์ใบเสนอราคาหรือเอกสารประกอบอื่นๆ ที่เกี่ยวข้องกับข้อเสนอของตน
Line 118: อื่นๆ          input upload file
```

### Database Schema Mapping

#### QuotationItems Table (Lines 809-831)
```sql
CREATE TABLE "QuotationItems" (
  "Id" BIGSERIAL PRIMARY KEY,
  "RfqId" BIGINT NOT NULL REFERENCES "Rfqs"("Id"),
  "SupplierId" BIGINT NOT NULL REFERENCES "Suppliers"("Id"),
  "RfqItemId" BIGINT NOT NULL REFERENCES "RfqItems"("Id"),
  "UnitPrice" DECIMAL(18,4) NOT NULL,                  -- Line 97: ราคาต่อหน่วย *
  "Quantity" DECIMAL(12,4) NOT NULL,                   -- From RfqItems
  "TotalPrice" DECIMAL(18,4) GENERATED ALWAYS AS ("Quantity" * "UnitPrice") STORED,  -- Line 98: auto calc
  "ConvertedUnitPrice" DECIMAL(18,4),                  -- Line 99: ราคาต่อหน่วยของบริษัท (auto)
  "ConvertedTotalPrice" DECIMAL(18,4),                 -- Line 102: ราคารวมของบริษัท (auto)
  "CurrencyId" BIGINT REFERENCES "Currencies"("Id"),   -- Line 96: สกุลเงิน *
  "IncotermId" BIGINT REFERENCES "Incoterms"("Id"),    -- Line 109: Inco Term
  "MinOrderQty" INT,                                   -- Line 105: MOQ (หน่วย)
  "DeliveryDays" INT,                                  -- Line 106: DLT (วัน)
  "CreditDays" INT,                                    -- Line 107: Credit (วัน)
  "WarrantyDays" INT,                                  -- Line 108: Warranty (วัน)
  "Remarks" TEXT,                                      -- Line 110: หมายเหตุ
  "SubmittedAt" TIMESTAMP,                             -- Line 130: Submit timestamp
  "SubmittedByContactId" BIGINT REFERENCES "SupplierContacts"("Id"),
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "uk_quotation_item" UNIQUE("RfqId", "SupplierId", "RfqItemId")
);

COMMENT ON COLUMN "QuotationItems"."TotalPrice" IS
  'ราคารวม คำนวณ auto จาก (Quantity × UnitPrice) - GENERATED COLUMN (v6.2.2)
   Business Rule: "ราคารวม จะคำนวณ auto จาก (จำนวนสินค้า*ราคาต่อหน่วย)"
   Data Integrity: Cannot be manually set, database-enforced calculation';
```

### 5.1 Get RFQ Header Information (Lines 81-89)

```sql
-- Lines 81-89: Read-only header information
SELECT
  -- Left column (Lines 82-88)
  r."RfqNumber",                                       -- Line 82: เลขที่เอกสาร(RFQ No.)
  r."ProjectName",                                     -- Line 83: ชื่อโครงงาน/งาน
  c."CategoryNameTh" AS "CategoryName",                -- Line 84: กลุ่มสินค้า/บริการ
  sub."SubcategoryNameTh" AS "SubcategoryName",        -- Line 85: หมวดหมู่ย่อย
  comp."ShortNameEn" AS "RequesterCompany",            -- Line 86: บริษัทผู้ร้องขอ
  u."FirstNameTh" || ' ' || u."LastNameTh" AS "PurchasingOfficer",  -- Line 87: ผู้จัดซื้อ
  r."QuotationDeadline",                               -- Line 88: วันที่สิ้นสุดการเสนอราคา

  -- Right column (Lines 82-89: Supplier info)
  sc."FirstName" || ' ' || sc."LastName" AS "ContactName",  -- Line 82: ชื่อ-นามสกุล
  sc."MobileNumber",                                   -- Line 83: เบอร์มือถือ
  sc."Email",                                          -- Line 84: อีเมล
  sc."Position",                                       -- Line 85: ตำแหน่งงาน
  s."TaxId",                                           -- Line 86: เลขประจำตัวผู้เสียภาษี
  s."CompanyNameTh",                                   -- Line 87: ชื่อบริษัท / หน่วยงาน
  s."CompanyPhone",                                    -- Line 88, 89: เบอร์โทรบริษัท

  -- Additional info
  cur."CurrencyCode" AS "CompanyCurrency",             -- For conversion (Lines 99-104)
  cur."Symbol" AS "CompanyCurrencySymbol"

FROM "Rfqs" r
JOIN "Categories" c ON r."CategoryId" = c."Id"
LEFT JOIN "Subcategories" sub ON r."SubcategoryId" = sub."Id"
JOIN "Companies" comp ON r."CompanyId" = comp."Id"
LEFT JOIN "Users" u ON r."ResponsiblePersonId" = u."Id"
JOIN "Currencies" cur ON r."BudgetCurrencyId" = cur."Id"
CROSS JOIN "Suppliers" s
LEFT JOIN "SupplierContacts" sc ON s."Id" = sc."SupplierId" AND sc."IsPrimaryContact" = TRUE
WHERE r."Id" = @RfqId
  AND s."Id" = @SupplierId;
```

### 5.2 Get RFQ Items (Lines 90-92)

```sql
-- Lines 90-92: Product items (read-only)
-- Col ลำดับ | รหัส | สินค้า | ยี่ห้อ | รุ่น | จำนวน | หน่วย
SELECT
  ROW_NUMBER() OVER (ORDER BY ri."SortOrder", ri."Id") AS "RowNumber",  -- Line 91: ลำดับ
  ri."Id" AS "RfqItemId",
  ri."ItemCode",                                       -- Line 91: รหัส
  ri."ProductNameTh" AS "ProductName",                 -- Line 91: สินค้า
  ri."BrandName",                                      -- Line 91: ยี่ห้อ
  ri."ModelNumber",                                    -- Line 91: รุ่น
  ri."Quantity",                                       -- Line 91: จำนวน
  u."UnitNameTh" AS "UnitName",                        -- Line 91: หน่วย
  ri."Specifications",
  ri."SortOrder"
FROM "RfqItems" ri
LEFT JOIN "Units" u ON ri."UnitId" = u."Id"
WHERE ri."RfqId" = @RfqId
  AND ri."IsActive" = TRUE
ORDER BY ri."SortOrder", ri."Id";
```

### 5.3 Submit Quotation Items (Lines 93-110)

```sql
-- Line 80: "หน้าจอ ใส่ราคา + ส่งคำถาม(ไม่มี สถานะ Draft)"
-- No draft status - direct submission

BEGIN;

-- Insert/Update quotation items (Lines 96-110)
INSERT INTO "QuotationItems" (
  "RfqId",
  "SupplierId",
  "RfqItemId",
  "CurrencyId",                                        -- Line 96: สกุลเงิน *
  "UnitPrice",                                         -- Line 97: ราคาต่อหน่วย *
  "Quantity",                                          -- From RfqItems
  -- "TotalPrice" is auto-calculated (Line 98)
  "ConvertedUnitPrice",                                -- Line 99: Calculated below
  "ConvertedTotalPrice",                               -- Line 102: Calculated below
  "MinOrderQty",                                       -- Line 105: MOQ (หน่วย)
  "DeliveryDays",                                      -- Line 106: DLT (วัน)
  "CreditDays",                                        -- Line 107: Credit (วัน)
  "WarrantyDays",                                      -- Line 108: Warranty (วัน)
  "IncotermId",                                        -- Line 109: Inco Term
  "Remarks",                                           -- Line 110: หมายเหตุ
  "SubmittedAt",
  "SubmittedByContactId"
)
SELECT
  @RfqId,
  @SupplierId,
  item."RfqItemId",
  item."CurrencyId",
  item."UnitPrice",
  ri."Quantity",

  -- Line 99-101: ConvertedUnitPrice calculation
  CASE
    -- Line 100: "ถ้า สกุลเงินที่เลือกกับdbตรงกัน จะใช้ ราคาต่อหน่วย ที่กรอก"
    WHEN item."CurrencyId" = r."BudgetCurrencyId"
    THEN item."UnitPrice"

    -- Line 101: "ถ้าเลือกไม่ตรง จะไปดูสกุลเงินบริษัทผู้ร้องขอ..."
    ELSE item."UnitPrice" * COALESCE(
      (
        SELECT er."Rate"
        FROM "ExchangeRates" er
        WHERE er."FromCurrencyId" = item."CurrencyId"
          AND er."ToCurrencyId" = r."BudgetCurrencyId"
          AND er."EffectiveDate" <= CURRENT_TIMESTAMP
          AND (er."ExpiryDate" IS NULL OR er."ExpiryDate" >= CURRENT_TIMESTAMP)
          AND er."IsActive" = TRUE
        ORDER BY er."EffectiveDate" DESC
        LIMIT 1
      ),
      1.0
    )
  END AS "ConvertedUnitPrice",

  -- Line 102-104: ConvertedTotalPrice calculation
  CASE
    -- Line 103: "ถ้า สกุลเงินที่เลือกกับdbตรงกัน จะใช้ ราคารวม ที่กรอก"
    WHEN item."CurrencyId" = r."BudgetCurrencyId"
    THEN item."UnitPrice" * ri."Quantity"

    -- Line 104: "ถ้าเลือกไม่ตรง..."
    ELSE (item."UnitPrice" * ri."Quantity") * COALESCE(
      (
        SELECT er."Rate"
        FROM "ExchangeRates" er
        WHERE er."FromCurrencyId" = item."CurrencyId"
          AND er."ToCurrencyId" = r."BudgetCurrencyId"
          AND er."EffectiveDate" <= CURRENT_TIMESTAMP
          AND (er."ExpiryDate" IS NULL OR er."ExpiryDate" >= CURRENT_TIMESTAMP)
          AND er."IsActive" = TRUE
        ORDER BY er."EffectiveDate" DESC
        LIMIT 1
      ),
      1.0
    )
  END AS "ConvertedTotalPrice",

  item."MinOrderQty",
  item."DeliveryDays",
  item."CreditDays",
  item."WarrantyDays",
  item."IncotermId",
  item."Remarks",
  CURRENT_TIMESTAMP,                                   -- SubmittedAt
  @ContactId

FROM unnest(
  @RfqItemIds::BIGINT[],
  @CurrencyIds::BIGINT[],
  @UnitPrices::DECIMAL[],
  @MinOrderQtys::INT[],
  @DeliveryDayss::INT[],
  @CreditDayss::INT[],
  @WarrantyDayss::INT[],
  @IncotermIds::BIGINT[],
  @Remarkss::TEXT[]
) AS item(
  "RfqItemId", "CurrencyId", "UnitPrice", "MinOrderQty",
  "DeliveryDays", "CreditDays", "WarrantyDays", "IncotermId", "Remarks"
)
JOIN "RfqItems" ri ON item."RfqItemId" = ri."Id"
JOIN "Rfqs" r ON ri."RfqId" = r."Id"
WHERE r."Id" = @RfqId

ON CONFLICT ("RfqId", "SupplierId", "RfqItemId")
DO UPDATE SET
  "CurrencyId" = EXCLUDED."CurrencyId",
  "UnitPrice" = EXCLUDED."UnitPrice",
  "ConvertedUnitPrice" = EXCLUDED."ConvertedUnitPrice",
  "ConvertedTotalPrice" = EXCLUDED."ConvertedTotalPrice",
  "MinOrderQty" = EXCLUDED."MinOrderQty",
  "DeliveryDays" = EXCLUDED."DeliveryDays",
  "CreditDays" = EXCLUDED."CreditDays",
  "WarrantyDays" = EXCLUDED."WarrantyDays",
  "IncotermId" = EXCLUDED."IncotermId",
  "Remarks" = EXCLUDED."Remarks",
  "SubmittedAt" = EXCLUDED."SubmittedAt",
  "SubmittedByContactId" = EXCLUDED."SubmittedByContactId";

-- Update RFQ status (Line 131)
UPDATE "Rfqs"
SET
  "Status" = 'PENDING',
  "LastActionAt" = CURRENT_TIMESTAMP
WHERE "Id" = @RfqId;

-- Send notification to PURCHASING (Line 131)
INSERT INTO "Notifications" (
  "Type",
  "Priority",
  "UserId",
  "RfqId",
  "Title",
  "Message",
  "IconType",
  "ActionUrl",
  "Channels"
)
SELECT
  'QUOTATION_SUBMITTED',
  'NORMAL',
  r."ResponsiblePersonId",
  r."Id",
  'Supplier เสนอราคาแล้ว',
  s."CompanyNameTh" || ' ได้เสนอราคาสำหรับ ' || r."RfqNumber",
  'QUOTATION_SUBMITTED',
  '/purchasing/rfqs/' || r."Id" || '/quotations',
  ARRAY['IN_APP', 'EMAIL']
FROM "Rfqs" r
JOIN "Suppliers" s ON s."Id" = @SupplierId
WHERE r."Id" = @RfqId;

COMMIT;
```

---

## SECTION 6: Currency Conversion Logic

### Business Rules (Lines 99-104)

#### Line 99-101: ConvertedUnitPrice Calculation
```
Line 100: ถ้า สกุลเงินที่เลือกกับdbตรงกัน จะใช้ ราคาต่อหน่วย ที่กรอก
Line 101: ถ้าเลือกไม่ตรง จะไปดูสกุลเงินบริษัทผู้ร้องขอ เป็นสกุลอะไร
         แล้วใช้สกุลนั้นไปคำนวณกับอัตราแลกเปลี่ยนและราคาต่อหน่วย(ที่adminนำเข้า)
         =ราคาต่อหน่วยของบริษัท
```

#### Conversion Function
```sql
CREATE OR REPLACE FUNCTION calculate_converted_unit_price(
  p_supplier_currency_id BIGINT,
  p_company_currency_id BIGINT,
  p_unit_price DECIMAL(18,4),
  p_submission_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
RETURNS DECIMAL(18,4) AS $
DECLARE
  v_converted_price DECIMAL(18,4);
  v_exchange_rate DECIMAL(15,6);
BEGIN
  -- Line 100: Same currency - no conversion needed
  IF p_supplier_currency_id = p_company_currency_id THEN
    RETURN p_unit_price;
  END IF;

  -- Line 101: Different currency - get exchange rate and convert
  SELECT er."Rate"
  INTO v_exchange_rate
  FROM "ExchangeRates" er
  WHERE er."FromCurrencyId" = p_supplier_currency_id
    AND er."ToCurrencyId" = p_company_currency_id
    AND er."EffectiveDate" <= p_submission_date
    AND (er."ExpiryDate" IS NULL OR er."ExpiryDate" >= p_submission_date)
    AND er."IsActive" = TRUE
  ORDER BY er."EffectiveDate" DESC
  LIMIT 1;

  -- If no rate found, return original price (or raise error in production)
  IF v_exchange_rate IS NULL THEN
    RAISE NOTICE 'No exchange rate found for currencies % to % on %',
      p_supplier_currency_id, p_company_currency_id, p_submission_date;
    RETURN p_unit_price;
  END IF;

  -- Calculate converted price
  v_converted_price := p_unit_price * v_exchange_rate;

  RETURN v_converted_price;
END;
$ LANGUAGE plpgsql;
```

#### Example Usage
```sql
-- Example: Supplier quotes in USD, Company uses THB
SELECT
  qi."Id",
  qi."RfqItemId",
  cSupplier."CurrencyCode" AS "SupplierCurrency",
  qi."UnitPrice" AS "OriginalPrice",
  cCompany."CurrencyCode" AS "CompanyCurrency",
  qi."ConvertedUnitPrice",
  er."Rate" AS "ExchangeRate",
  qi."ConvertedUnitPrice" / qi."UnitPrice" AS "CalculatedRate"
FROM "QuotationItems" qi
JOIN "Currencies" cSupplier ON qi."CurrencyId" = cSupplier."Id"
JOIN "Rfqs" r ON qi."RfqId" = r."Id"
JOIN "Currencies" cCompany ON r."BudgetCurrencyId" = cCompany."Id"
LEFT JOIN "ExchangeRates" er ON
  er."FromCurrencyId" = qi."CurrencyId"
  AND er."ToCurrencyId" = r."BudgetCurrencyId"
  AND er."EffectiveDate" <= qi."SubmittedAt"
  AND (er."ExpiryDate" IS NULL OR er."ExpiryDate" >= qi."SubmittedAt")
WHERE qi."RfqId" = @RfqId
  AND qi."SupplierId" = @SupplierId;

-- Example result:
-- SupplierCurrency | OriginalPrice | CompanyCurrency | ConvertedUnitPrice | ExchangeRate
-- USD              | 100.0000      | THB             | 3585.0000          | 35.85
```

### 6.1 Total Price Calculation (Line 98)

```
Line 98: *ราคารวม :xxxxxx.0000   หมายเหตุ  ราคารวม จะคำนวณ auto จาก (จำนวนสินค้า*ราคาต่อหน่วย)
```

#### GENERATED COLUMN (v6.2.2)
```sql
-- Line 98: TotalPrice is a GENERATED COLUMN - cannot be manually set
CREATE TABLE "QuotationItems" (
  ...
  "UnitPrice" DECIMAL(18,4) NOT NULL,
  "Quantity" DECIMAL(12,4) NOT NULL,
  "TotalPrice" DECIMAL(18,4) GENERATED ALWAYS AS ("Quantity" * "UnitPrice") STORED,
  ...
);

-- Verification
SELECT
  "RfqItemId",
  "Quantity",
  "UnitPrice",
  "TotalPrice",
  ("Quantity" * "UnitPrice") AS "CalculatedTotal",
  CASE
    WHEN "TotalPrice" = ("Quantity" * "UnitPrice") THEN 'OK'
    ELSE 'ERROR'
  END AS "ValidationStatus"
FROM "QuotationItems"
WHERE "RfqId" = @RfqId
  AND "SupplierId" = @SupplierId;
```

---

## SECTION 7: Q&A System

### Business Documentation Mapping (Lines 121-135)

```
Line 121: หัวข้อ ถาม / ตอบ Supplier
Line 122: BW คำถามที่ถามจัดซื้อ 4 hours ago
Line 123: จัดซื้อ คำตอบที่จัดซื้อตอบ 1 day ago
Line 124: input text box ระบุคำถาม ปุ่ม ส่งคำถาม
Line 126: ปุ่ม ส่งคำถาม :
Line 127: ฟังก์ชัน: เมื่อส่งคำถาม จะปรับสถานะเป็น "Awaiting"  จะส่งเมล์ไปหา "Purchasing" พร้อมเด้ง Notification โดย Purchasing จะผูกกับ Category และ Subcategory
Line 133: ### หน้าจอ ส่งคำถาม(โฟกัสส่งคำถาม)
Line 134: ปุ่ม ส่งคำถาม :
Line 135: ฟังก์ชัน: เมื่อส่งคำถาม จะปรับสถานะเป็น "Awaiting"  จะส่งเมล์ไปหา "Purchasing" พร้อมเด้ง Notification โดย Purchasing จะผูกกับ Category และ Subcategory
```

### Database Schema Mapping

#### QnAThreads Table (Lines 900-910)
```sql
CREATE TABLE "QnAThreads" (
  "Id" BIGSERIAL PRIMARY KEY,
  "RfqId" BIGINT NOT NULL REFERENCES "Rfqs"("Id"),
  "SupplierId" BIGINT NOT NULL REFERENCES "Suppliers"("Id"),
  "ThreadStatus" VARCHAR(20) DEFAULT 'OPEN',           -- Line 127: "Awaiting" maps to OPEN
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "ClosedAt" TIMESTAMP,

  UNIQUE("RfqId", "SupplierId"),
  CONSTRAINT "chk_thread_status" CHECK ("ThreadStatus" IN ('OPEN','CLOSED'))
);

COMMENT ON TABLE "QnAThreads" IS 'Thread สำหรับถาม-ตอบระหว่าง Supplier และ Purchasing';
```

#### QnAMessages Table (Lines 915-926)
```sql
CREATE TABLE "QnAMessages" (
  "Id" BIGSERIAL PRIMARY KEY,
  "ThreadId" BIGINT NOT NULL REFERENCES "QnAThreads"("Id"),
  "MessageText" TEXT NOT NULL,                         -- Line 124: ระบุคำถาม
  "SenderType" VARCHAR(20) NOT NULL,                   -- 'SUPPLIER' or 'PURCHASING'
  "SenderId" BIGINT NOT NULL,                          -- ContactId or UserId
  "SentAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,        -- Line 122: 4 hours ago
  "IsRead" BOOLEAN DEFAULT FALSE,
  "ReadAt" TIMESTAMP,

  CONSTRAINT "chk_sender_type" CHECK ("SenderType" IN ('SUPPLIER','PURCHASING'))
);

COMMENT ON TABLE "QnAMessages" IS 'ข้อความในแต่ละ Thread';
```

### 7.1 Send Question from Supplier (Lines 124-127)

```sql
BEGIN;

-- Step 1: Get or create thread
INSERT INTO "QnAThreads" (
  "RfqId",
  "SupplierId",
  "ThreadStatus"
)
VALUES (
  @RfqId,
  @SupplierId,
  'OPEN'                                               -- Line 127: "Awaiting" status
)
ON CONFLICT ("RfqId", "SupplierId")
DO UPDATE SET
  "ThreadStatus" = 'OPEN',                             -- Reopen if closed
  "ClosedAt" = NULL
RETURNING "Id" AS "ThreadId";

-- Step 2: Insert message (Line 124)
INSERT INTO "QnAMessages" (
  "ThreadId",
  "MessageText",                                       -- Line 124: input text box ระบุคำถาม
  "SenderType",
  "SenderId",                                          -- SupplierContact.Id
  "SentAt"
) VALUES (
  @ThreadId,
  @QuestionText,
  'SUPPLIER',
  @ContactId,
  CURRENT_TIMESTAMP
)
RETURNING "Id" AS "MessageId";

-- Step 3: Send notification to PURCHASING (Line 127)
-- "Purchasing จะผูกกับ Category และ Subcategory"
WITH rfq_info AS (
  SELECT
    r."Id" AS "RfqId",
    r."RfqNumber",
    r."ProjectName",
    r."CategoryId",
    r."SubcategoryId",
    s."CompanyNameTh" AS "SupplierName"
  FROM "Rfqs" r
  JOIN "Suppliers" s ON s."Id" = @SupplierId
  WHERE r."Id" = @RfqId
),
purchasing_users AS (
  SELECT DISTINCT
    u."Id" AS "UserId",
    u."Email"
  FROM rfq_info ri
  JOIN "UserCategoryBindings" ucb ON
    ucb."CategoryId" = ri."CategoryId"
    AND (ucb."SubcategoryId" IS NULL OR ucb."SubcategoryId" = ri."SubcategoryId")
  JOIN "UserCompanyRoles" ucr ON ucb."UserCompanyRoleId" = ucr."Id"
  JOIN "Users" u ON ucr."UserId" = u."Id"
  JOIN "Roles" r ON ucr."PrimaryRoleId" = r."Id"
  WHERE r."RoleCode" = 'PURCHASING'
    AND ucr."IsActive" = TRUE
)
INSERT INTO "Notifications" (
  "Type",
  "Priority",
  "UserId",
  "RfqId",
  "Title",
  "Message",
  "IconType",
  "ActionUrl",
  "Channels"
)
SELECT
  'SUPPLIER_QUESTION',
  'NORMAL',
  pu."UserId",
  ri."RfqId",
  'Supplier ส่งคำถาม',
  ri."SupplierName" || ' ได้ส่งคำถามสำหรับ ' || ri."RfqNumber",
  'QUESTION',
  '/purchasing/rfqs/' || ri."RfqId" || '/qna',
  ARRAY['IN_APP', 'EMAIL']
FROM rfq_info ri
CROSS JOIN purchasing_users pu;

COMMIT;
```

### 7.2 Get Q&A Thread (Lines 122-123)

```sql
-- Lines 122-123: Display Q&A history
WITH messages AS (
  SELECT
    qm."Id",
    qm."MessageText",
    qm."SenderType",
    qm."SentAt",
    qm."IsRead",

    -- Sender info
    CASE qm."SenderType"
      WHEN 'SUPPLIER' THEN
        (SELECT sc."FirstName" || ' ' || sc."LastName"
         FROM "SupplierContacts" sc
         WHERE sc."Id" = qm."SenderId")
      WHEN 'PURCHASING' THEN
        (SELECT u."FirstNameTh" || ' ' || u."LastNameTh"
         FROM "Users" u
         WHERE u."Id" = qm."SenderId")
    END AS "SenderName",

    -- Time ago (Line 122: "4 hours ago", Line 123: "1 day ago")
    CASE
      WHEN EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - qm."SentAt")) < 3600
      THEN FLOOR(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - qm."SentAt")) / 60)::TEXT || ' minutes ago'

      WHEN EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - qm."SentAt")) < 86400
      THEN FLOOR(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - qm."SentAt")) / 3600)::TEXT || ' hours ago'

      ELSE FLOOR(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - qm."SentAt")) / 86400)::TEXT || ' days ago'
    END AS "TimeAgo"

  FROM "QnAMessages" qm
  WHERE qm."ThreadId" IN (
    SELECT "Id"
    FROM "QnAThreads"
    WHERE "RfqId" = @RfqId
      AND "SupplierId" = @SupplierId
  )
  ORDER BY qm."SentAt" ASC
)
SELECT * FROM messages;
```

### 7.3 Answer Question from PURCHASING

```sql
-- PURCHASING sends answer
BEGIN;

INSERT INTO "QnAMessages" (
  "ThreadId",
  "MessageText",
  "SenderType",
  "SenderId"                                           -- User.Id (PURCHASING)
) VALUES (
  @ThreadId,
  @AnswerText,
  'PURCHASING',
  @UserId
)
RETURNING "Id";

-- Mark previous messages as read
UPDATE "QnAMessages"
SET
  "IsRead" = TRUE,
  "ReadAt" = CURRENT_TIMESTAMP
WHERE "ThreadId" = @ThreadId
  AND "SenderType" = 'SUPPLIER'
  AND "IsRead" = FALSE;

-- Send notification to Supplier
INSERT INTO "Notifications" (
  "Type",
  "Priority",
  "ContactId",
  "RfqId",
  "Title",
  "Message",
  "IconType",
  "ActionUrl",
  "Channels"
)
SELECT
  'PURCHASING_REPLY',
  'NORMAL',
  qt."SupplierId",
  qt."RfqId",
  'ผู้จัดซื้อตอบคำถาม',
  'ผู้จัดซื้อได้ตอบคำถามของคุณสำหรับ ' || r."RfqNumber",
  'REPLY',
  '/supplier/rfqs/' || r."Id" || '/qna',
  ARRAY['IN_APP', 'EMAIL']
FROM "QnAThreads" qt
JOIN "Rfqs" r ON qt."RfqId" = r."Id"
JOIN "SupplierContacts" sc ON qt."SupplierId" = sc."SupplierId"
  AND sc."IsPrimaryContact" = TRUE
WHERE qt."Id" = @ThreadId;

COMMIT;
```

---

## SECTION 8: Database Schema Overview

### 8.1 Core Supplier Tables

| Table | Primary Key | Key Columns | Purpose |
|-------|-------------|-------------|---------|
| Suppliers | Id | TaxId, CompanyNameTh, BusinessTypeId, Status | Supplier companies |
| SupplierContacts | Id | SupplierId, Email, IsPrimaryContact | Supplier user accounts |
| SupplierCategories | Id | SupplierId, CategoryId, SubcategoryId | Supplier categories |
| SupplierDocuments | Id | SupplierId, DocumentType | Registration documents |

### 8.2 Invitation & Response Tables

| Table | Primary Key | Key Columns | Purpose |
|-------|-------------|-------------|---------|
| RfqInvitations | Id | RfqId, SupplierId, Decision, ResponseStatus | Invitation tracking |
| RfqInvitationHistory | Id | InvitationId, FromDecision, ToDecision | Decision change history |

### 8.3 Quotation Tables

| Table | Primary Key | Key Columns | Purpose |
|-------|-------------|-------------|---------|
| QuotationItems | Id | RfqId, SupplierId, RfqItemId, UnitPrice | Quotation pricing |
| QuotationDocuments | Id | RfqId, SupplierId, DocumentType | Quotation documents |

### 8.4 Q&A Tables

| Table | Primary Key | Key Columns | Purpose |
|-------|-------------|-------------|---------|
| QnAThreads | Id | RfqId, SupplierId, ThreadStatus | Q&A threads |
| QnAMessages | Id | ThreadId, MessageText, SenderType | Q&A messages |

---

## SECTION 9: SQL Query Templates

### 9.1 Supplier Registration

#### Complete Registration Flow
```sql
-- Full supplier registration with all related data
BEGIN;

-- 1. Insert Supplier
INSERT INTO "Suppliers" (...) VALUES (...) RETURNING "Id";

-- 2. Insert Contacts (at least 1 primary)
INSERT INTO "SupplierContacts" (...) VALUES (...);

-- 3. Insert Categories
INSERT INTO "SupplierCategories" (...) VALUES (...);

-- 4. Insert Documents
INSERT INTO "SupplierDocuments" (...) VALUES (...);

-- 5. Validate required documents
SELECT ... FROM validate_supplier_documents(@SupplierId);

-- 6. Send notification to PURCHASING
INSERT INTO "Notifications" (...) VALUES (...);

COMMIT;
```

### 9.2 Invitation Response

#### Get Supplier Dashboard
```sql
-- Get all invitations for supplier dashboard
SELECT
  ri."Id",
  r."RfqNumber",
  r."ProjectName",
  ri."Decision",
  ri."ResponseStatus",
  CASE
    WHEN qi."SubmittedAt" IS NOT NULL THEN 'Submitted'
    WHEN ri."Decision" = 'PARTICIPATING' THEN 'Not Submitted'
    WHEN ri."Decision" = 'NOT_PARTICIPATING' THEN 'Declined'
    ELSE 'Pending'
  END AS "SubmissionStatus"
FROM "RfqInvitations" ri
JOIN "Rfqs" r ON ri."RfqId" = r."Id"
LEFT JOIN (
  SELECT DISTINCT "RfqId", "SupplierId", MAX("SubmittedAt") AS "SubmittedAt"
  FROM "QuotationItems"
  GROUP BY "RfqId", "SupplierId"
) qi ON ri."RfqId" = qi."RfqId" AND ri."SupplierId" = qi."SupplierId"
WHERE ri."SupplierId" = @SupplierId
ORDER BY r."QuotationDeadline" ASC;
```

### 9.3 Quotation Submission

#### Get Quotation Form Data
```sql
-- Get complete quotation form with RFQ details, items, and existing quotations
WITH rfq_header AS (
  SELECT ... -- Lines 82-89
),
rfq_items AS (
  SELECT ... -- Lines 91-92
),
existing_quotations AS (
  SELECT ... -- Previously saved quotations
)
SELECT * FROM rfq_header, rfq_items
LEFT JOIN existing_quotations USING ("RfqItemId");
```

---

## SECTION 10: Validation Rules

### 10.1 Supplier Registration Validation

#### Required Fields by BusinessType
```csharp
public class SupplierRegistrationValidator
{
    public ValidationResult Validate(SupplierRegistrationDto dto)
    {
        var errors = new List<string>();

        // Line 4: BusinessTypeId required
        if (dto.BusinessTypeId == 0)
            errors.Add("ประเภทบุคคล is required");

        // Line 5: TaxId required and unique
        if (string.IsNullOrEmpty(dto.TaxId))
            errors.Add("เลขประจำตัวผู้เสียภาษี is required");

        // Line 6: CompanyName required
        if (string.IsNullOrEmpty(dto.CompanyNameTh))
            errors.Add("ชื่อบริษัท/หน่วยงาน is required");

        // Lines 9-15: Other required fields
        if (dto.JobTypeId == 0)
            errors.Add("ประเภทงานของบริษัท is required");

        // Line 33: At least one primary contact
        if (!dto.Contacts.Any(c => c.IsPrimaryContact))
            errors.Add("ต้องกำหนดผู้ติดต่อหลักอย่างน้อย 1 คน");

        // Lines 37-48: Document validation
        var documentErrors = ValidateDocuments(dto.BusinessTypeId, dto.Documents);
        errors.AddRange(documentErrors);

        return new ValidationResult
        {
            IsValid = !errors.Any(),
            Errors = errors
        };
    }
}
```

### 10.2 Quotation Validation

#### Required Fields Validation
```csharp
public class QuotationItemValidator
{
    public ValidationResult Validate(QuotationItemDto dto)
    {
        var errors = new List<string>();

        // Line 96: Currency required
        if (dto.CurrencyId == 0)
            errors.Add("สกุลเงิน is required");

        // Line 97: UnitPrice required
        if (dto.UnitPrice <= 0)
            errors.Add("ราคาต่อหน่วย must be greater than 0");

        // Line 105: MOQ validation (4 digits max)
        if (dto.MinOrderQty.HasValue && dto.MinOrderQty > 9999)
            errors.Add("MOQ must be 4 digits or less");

        // Lines 106-108: Days validation
        if (dto.DeliveryDays.HasValue && dto.DeliveryDays < 0)
            errors.Add("DLT must be positive");

        return new ValidationResult
        {
            IsValid = !errors.Any(),
            Errors = errors
        };
    }
}
```

---

## SECTION 11: Test Scenarios

### 11.1 Supplier Registration Test Cases

#### Test Case 1: Register Juristic Person Supplier (Lines 4-48)
**Given**: New supplier wants to register as "นิติบุคคล"
**When**: Supplier fills registration form
**Then**:
1. System validates BusinessTypeId = JURISTIC (Line 4)
2. System requires 5 documents (Lines 38-42)
3. System validates at least 1 primary contact (Line 33)
4. System creates Supplier with Status = PENDING (Line 56)
5. System sends notification to bound PURCHASING users (Line 57)

**SQL Validation**:
```sql
-- Verify supplier was created
SELECT
  "TaxId",
  "CompanyNameTh",
  "Status",
  "RegisteredAt"
FROM "Suppliers"
WHERE "TaxId" = @TaxId;
-- Expected: Status = 'PENDING'

-- Verify required documents uploaded
SELECT
  "DocumentType",
  COUNT(*) AS "Count"
FROM "SupplierDocuments"
WHERE "SupplierId" = @SupplierId
  AND "DocumentType" IN ('CERTIFICATE', 'PHO_PHO_20', 'FINANCIAL_REPORT', 'COMPANY_PROFILE', 'NDA')
GROUP BY "DocumentType";
-- Expected: 5 rows

-- Verify primary contact exists
SELECT COUNT(*) AS "PrimaryContactCount"
FROM "SupplierContacts"
WHERE "SupplierId" = @SupplierId
  AND "IsPrimaryContact" = TRUE;
-- Expected: >= 1
```

#### Test Case 2: Register Natural Person Supplier (Line 44-46)
**Given**: Individual wants to register as "บุคคลธรรมดา"
**When**: Supplier fills registration form
**Then**:
1. System validates BusinessTypeId = NATURAL (Line 44)
2. System requires only 2 documents: ID_CARD, NDA (Lines 45-46)
3. System allows registration with fewer documents than juristic person

**SQL Validation**:
```sql
-- Verify natural person documents
SELECT "DocumentType"
FROM "SupplierDocuments"
WHERE "SupplierId" = @SupplierId
  AND "DocumentType" IN ('ID_CARD', 'NDA');
-- Expected: 2 rows
```

### 11.2 Invitation Response Test Cases

#### Test Case 3: Accept Invitation (Lines 61-62)
**Given**: Supplier receives invitation and views popup
**When**: Supplier clicks "เข้าร่วม" button
**Then**:
1. System updates Decision = PARTICIPATING (Line 62)
2. System updates ResponseStatus = RESPONDED (Line 62)
3. System records RespondedByContactId (Line 79)
4. System inserts history record (Line 77)
5. System sends notification to PURCHASING

**SQL Validation**:
```sql
-- Verify invitation response
SELECT
  "Decision",
  "ResponseStatus",
  "RespondedAt",
  "RespondedByContactId",
  "DecisionChangeCount"
FROM "RfqInvitations"
WHERE "RfqId" = @RfqId
  AND "SupplierId" = @SupplierId;
-- Expected: Decision = 'PARTICIPATING', ResponseStatus = 'RESPONDED'

-- Verify history record
SELECT
  "FromDecision",
  "ToDecision",
  "ChangedByContactId"
FROM "RfqInvitationHistory"
WHERE "InvitationId" = @InvitationId
ORDER BY "DecisionSequence" DESC
LIMIT 1;
-- Expected: FromDecision = 'PENDING', ToDecision = 'PARTICIPATING'
```

#### Test Case 4: Change Decision (Line 77)
**Given**: Supplier previously declined but changed mind
**When**: Supplier clicks "เข้าร่วม" within deadline period
**Then**:
1. System checks QuotationDeadline > CURRENT_TIMESTAMP (Line 77)
2. System allows decision change from NOT_PARTICIPATING to PARTICIPATING
3. System increments DecisionChangeCount
4. System inserts new history record

**SQL Validation**:
```sql
-- Verify decision change is allowed
SELECT
  "Decision",
  "DecisionChangeCount",
  r."QuotationDeadline",
  CASE
    WHEN r."QuotationDeadline" > CURRENT_TIMESTAMP THEN 'Can Change'
    ELSE 'Cannot Change'
  END AS "ChangeStatus"
FROM "RfqInvitations" ri
JOIN "Rfqs" r ON ri."RfqId" = r."Id"
WHERE ri."RfqId" = @RfqId
  AND ri."SupplierId" = @SupplierId;

-- Verify history shows change
SELECT
  "DecisionSequence",
  "FromDecision",
  "ToDecision",
  "ChangedAt"
FROM "RfqInvitationHistory"
WHERE "InvitationId" = @InvitationId
ORDER BY "DecisionSequence";
-- Expected: 2+ rows showing change history
```

#### Test Case 5: Auto-Decline (Line 76)
**Given**: Supplier receives invitation but doesn't respond
**When**: QuotationDeadline passes
**Then**:
1. Scheduled job finds PENDING invitations past deadline (Line 76)
2. System updates Decision = AUTO_DECLINED
3. System sets AutoDeclinedAt timestamp

**SQL Validation**:
```sql
-- Verify auto-decline
SELECT
  "Decision",
  "ResponseStatus",
  "AutoDeclinedAt"
FROM "RfqInvitations"
WHERE "RfqId" = @RfqId
  AND "SupplierId" = @SupplierId;
-- Expected: Decision = 'AUTO_DECLINED', AutoDeclinedAt IS NOT NULL
```

### 11.3 Quotation Submission Test Cases

#### Test Case 6: Submit Quotation with Currency Conversion (Lines 96-104)
**Given**: Supplier quotes in USD, Company uses THB
**When**: Supplier submits quotation
**Then**:
1. System accepts CurrencyId = USD (Line 96)
2. System calculates TotalPrice = Quantity × UnitPrice (Line 98)
3. System looks up exchange rate USD → THB (Line 101)
4. System calculates ConvertedUnitPrice (Line 99)
5. System calculates ConvertedTotalPrice (Line 102)

**SQL Validation**:
```sql
-- Verify currency conversion
SELECT
  qi."RfqItemId",
  cSupplier."CurrencyCode" AS "SupplierCurrency",
  qi."UnitPrice",
  qi."Quantity",
  qi."TotalPrice",
  cCompany."CurrencyCode" AS "CompanyCurrency",
  qi."ConvertedUnitPrice",
  qi."ConvertedTotalPrice",
  er."Rate" AS "ExchangeRate",

  -- Verify Line 98: TotalPrice = Quantity × UnitPrice
  (qi."Quantity" * qi."UnitPrice") AS "ExpectedTotalPrice",
  CASE
    WHEN qi."TotalPrice" = (qi."Quantity" * qi."UnitPrice") THEN 'OK'
    ELSE 'ERROR'
  END AS "TotalPriceCheck",

  -- Verify Line 99: ConvertedUnitPrice = UnitPrice × ExchangeRate
  (qi."UnitPrice" * er."Rate") AS "ExpectedConvertedUnitPrice",
  CASE
    WHEN ABS(qi."ConvertedUnitPrice" - (qi."UnitPrice" * er."Rate")) < 0.01 THEN 'OK'
    ELSE 'ERROR'
  END AS "ConversionCheck"

FROM "QuotationItems" qi
JOIN "Currencies" cSupplier ON qi."CurrencyId" = cSupplier."Id"
JOIN "Rfqs" r ON qi."RfqId" = r."Id"
JOIN "Currencies" cCompany ON r."BudgetCurrencyId" = cCompany."Id"
LEFT JOIN "ExchangeRates" er ON
  er."FromCurrencyId" = qi."CurrencyId"
  AND er."ToCurrencyId" = r."BudgetCurrencyId"
  AND er."EffectiveDate" <= qi."SubmittedAt"
  AND (er."ExpiryDate" IS NULL OR er."ExpiryDate" >= qi."SubmittedAt")
WHERE qi."RfqId" = @RfqId
  AND qi."SupplierId" = @SupplierId;
```

#### Test Case 7: Same Currency (No Conversion) (Line 100)
**Given**: Supplier and Company both use THB
**When**: Supplier submits quotation
**Then**:
1. System detects same currency (Line 100)
2. System sets ConvertedUnitPrice = UnitPrice
3. System sets ConvertedTotalPrice = TotalPrice

**SQL Validation**:
```sql
-- Verify same currency (no conversion)
SELECT
  qi."CurrencyId",
  r."BudgetCurrencyId",
  qi."UnitPrice",
  qi."ConvertedUnitPrice",
  CASE
    WHEN qi."CurrencyId" = r."BudgetCurrencyId"
      AND qi."ConvertedUnitPrice" = qi."UnitPrice"
    THEN 'OK'
    ELSE 'ERROR'
  END AS "SameCurrencyCheck"
FROM "QuotationItems" qi
JOIN "Rfqs" r ON qi."RfqId" = r."Id"
WHERE qi."RfqId" = @RfqId
  AND qi."SupplierId" = @SupplierId;
```

### 11.4 Q&A System Test Cases

#### Test Case 8: Supplier Sends Question (Lines 124-127)
**Given**: Supplier has question about RFQ
**When**: Supplier types question and clicks "ส่งคำถาม"
**Then**:
1. System creates or reopens QnAThread (Line 127)
2. System inserts message with SenderType = SUPPLIER (Line 124)
3. System sends notification to bound PURCHASING users (Line 127)

**SQL Validation**:
```sql
-- Verify thread created
SELECT
  "Id",
  "ThreadStatus",
  "CreatedAt"
FROM "QnAThreads"
WHERE "RfqId" = @RfqId
  AND "SupplierId" = @SupplierId;
-- Expected: ThreadStatus = 'OPEN'

-- Verify message inserted
SELECT
  "MessageText",
  "SenderType",
  "SentAt"
FROM "QnAMessages"
WHERE "ThreadId" = @ThreadId
ORDER BY "SentAt" DESC
LIMIT 1;
-- Expected: SenderType = 'SUPPLIER'

-- Verify notification sent
SELECT
  "Type",
  "UserId",
  "Message",
  "IconType"
FROM "Notifications"
WHERE "RfqId" = @RfqId
  AND "Type" = 'SUPPLIER_QUESTION'
ORDER BY "CreatedAt" DESC
LIMIT 1;
-- Expected: IconType = 'QUESTION'
```

---

## Summary

This document provides **100% coverage** of all 135 lines in `04_Supplier_WorkFlow.txt`, mapped to database schema v6.2.2. Every business requirement has been analyzed and documented with:

✅ **Complete line-by-line mapping**
✅ **Database schema fields**
✅ **SQL query templates**
✅ **Currency conversion logic**
✅ **Validation rules**
✅ **Comprehensive test scenarios**

### Key Features Covered:

1. **Supplier Registration** (Lines 1-58)
   - Two registration modes: 1) New registration, 2) Edit existing
   - BusinessType determines required documents
   - Multi-contact support with primary contact requirement
   - Category and subcategory bindings
   - Status = PENDING upon registration/update

2. **Invitation Response Flow** (Lines 59-79)
   - Four decision states: PENDING, PARTICIPATING, NOT_PARTICIPATING, AUTO_DECLINED
   - Decision change allowed before deadline
   - Response history tracking
   - Auto-decline for non-responders past deadline

3. **Quotation Submission** (Lines 80-131)
   - No draft status - direct submission only
   - Multi-currency support with auto-conversion
   - GENERATED COLUMN for TotalPrice calculation
   - Exchange rate lookup at submission time
   - Complete pricing fields: MOQ, DLT, Credit, Warranty, Incoterm

4. **Q&A System** (Lines 121-135)
   - Thread-based communication
   - Real-time notifications to bound PURCHASING users
   - Message history with timestamps

### Database Tables Used:
- Suppliers, SupplierContacts, SupplierCategories, SupplierDocuments
- RfqInvitations, RfqInvitationHistory
- QuotationItems, QuotationDocuments
- QnAThreads, QnAMessages
- ExchangeRates, Currencies
- Notifications

**Total Lines Mapped**: 135/135 (100%)

---

**End of Document**