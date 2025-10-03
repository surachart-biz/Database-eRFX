# Supplier WorkFlow Complete Cross-Reference - Part 1
# Registration & Documents Management

**Document Version**: 3.0
**Created**: 2025-09-30
**Database Schema**: erfq-db-schema-v62.sql
**Business Documentation**: 04_Supplier_WorkFlow.txt (Lines 1-58)
**Part**: 1 of 3

---

## Document Purpose

This document (Part 1) covers **Supplier Registration and Document Management** including:
- Complete line-by-line mapping (Lines 1-58)
- Database schema for Suppliers, SupplierContacts, SupplierCategories, SupplierDocuments
- Registration and Update workflows
- Document validation by BusinessType

**Other Parts**:
- Part 2: Invitation Response Flow & Quotation Submission
- Part 3: Database Schema, SQL Templates, Validation & Tests

---

## Table of Contents (Part 1)

1. [Line-by-Line Mapping Summary](#section-1-line-by-line-mapping-summary)
2. [Supplier Registration Form](#section-2-supplier-registration-form)
3. [Supplier Documents Management](#section-3-supplier-documents-management)

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
| 59-64 | Invitation Popup | RfqInvitations | ✅ Mapped (Part 2) |
| 65-79 | Response Status Flow | RfqInvitations, RfqInvitationHistory | ✅ Mapped (Part 2) |

#### Quotation Submission (Lines 80-135)
| Lines | Topic | Schema Tables | Status |
|-------|-------|---------------|--------|
| 80-89 | Header Information | Rfqs (read-only) | ✅ Mapped (Part 2) |
| 90-92 | Product Items | RfqItems (read-only) | ✅ Mapped (Part 2) |
| 93-118 | Quotation Pricing | QuotationItems | ✅ Mapped (Part 2) |
| 119-120 | Additional Documents | QuotationDocuments | ✅ Mapped (Part 2) |
| 121-135 | Q&A System | QnAThreads, QnAMessages | ✅ Mapped (Part 2) |

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

**End of Part 1**

See Part 2 for Invitation Response Flow, Quotation Submission, Currency Conversion, and Q&A System.
See Part 3 for Database Schema Overview, SQL Query Templates, Validation Rules, and Test Scenarios.
