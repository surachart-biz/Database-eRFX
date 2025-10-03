# Supplier WorkFlow Complete Cross-Reference - Part 2
# Invitation Response & Quotation Submission

**Document Version**: 3.0
**Created**: 2025-09-30
**Database Schema**: erfq-db-schema-v62.sql
**Business Documentation**: 04_Supplier_WorkFlow.txt (Lines 59-135)
**Part**: 2 of 3

---

## Document Purpose

This document (Part 2) covers **Invitation Response Flow, Quotation Submission, Currency Conversion, and Q&A System** including:
- Complete line-by-line mapping (Lines 59-135)
- Invitation status flows and decision changes
- Quotation pricing with multi-currency support
- Q&A thread-based communication

**Other Parts**:
- Part 1: Supplier Registration & Documents Management
- Part 3: Database Schema, SQL Templates, Validation & Tests

---

## Table of Contents (Part 2)

4. [Invitation Response Flow](#section-4-invitation-response-flow)
5. [Quotation Submission Form](#section-5-quotation-submission-form)
6. [Currency Conversion Logic](#section-6-currency-conversion-logic)
7. [Q&A System](#section-7-qa-system)

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
    WHEN 'AUTO_DECLINED' THEN 4
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
RETURNS DECIMAL(18,4) AS $$
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
$$ LANGUAGE plpgsql;
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

**End of Part 2**

See Part 1 for Supplier Registration & Documents Management.
See Part 3 for Database Schema Overview, SQL Query Templates, Validation Rules, and Test Scenarios.
