# Dashboard RealTime & RFQ WorkFlow DETAILED Cross-Reference
# Database Schema v6.2.2 Complete Analysis (CORRECTED)

**Document Version**: 4.0 (DETAILED)
**Created**: 2025-10-01
**Database Schema**: erfq-db-schema-v62.sql
**Business Documentation**:
- 06_Dashboard_RealTime.txt (84 lines)
- 00_1RFQ_WorkFlow.txt (33 lines)

---

## ⚠️ CRITICAL CORRECTIONS FROM PREVIOUS VERSION

### Schema Differences Identified:

1. **❌ RfqApprovalHistory table DOES NOT EXIST**
   - Previous documentation incorrectly referenced this table
   - **✅ CORRECT tables**: `RfqStatusHistory` + `RfqActorTimeline`

2. **RfqStatusHistory** (Lines 721-736):
   ```sql
   CREATE TABLE "RfqStatusHistory" (
     "ActorRole" VARCHAR(30),
     "ApprovalLevel" SMALLINT,
     "Decision" VARCHAR(20),
     -- CHECK constraint: APPROVED, DECLINED, REJECTED, SUBMITTED
   );
   ```

3. **RfqActorTimeline** (Lines 741-751):
   ```sql
   CREATE TABLE "RfqActorTimeline" (
     "ActorId" BIGINT,
     "ActorRole" VARCHAR(30),
     "ReceivedAt" TIMESTAMP,
     "ActionAt" TIMESTAMP,
     "IsOntime" BOOLEAN
   );
   ```

---

## Table of Contents

1. [Complete Schema Mapping](#section-1-complete-schema-mapping)
2. [RFQ Multi-Level Approval WorkFlow](#section-2-rfq-multi-level-approval-workflow)
3. [Dashboard: Requester (RealTime)](#section-3-dashboard-requester-realtime)
4. [Dashboard: Approver (RealTime)](#section-4-dashboard-approver-realtime)
5. [Dashboard: Purchasing (RealTime)](#section-5-dashboard-purchasing-realtime)
6. [Dashboard: Supplier (RealTime)](#section-6-dashboard-supplier-realtime)
7. [Dashboard: Purchasing Approver (RealTime)](#section-7-dashboard-purchasing-approver-realtime)
8. [Real-Time Queries & Caching](#section-8-real-time-queries-caching)
9. [SignalR Integration](#section-9-signalr-integration)
10. [Complete Test Scenarios](#section-10-complete-test-scenarios)

---

## SECTION 1: Complete Schema Mapping

### 1.1 Core Tables for Dashboards & Workflow

| Table Name | Lines | Purpose | Key Columns |
|------------|-------|---------|-------------|
| **Rfqs** | 571-620 | Main RFQ data | Status, CurrentLevel, CurrentActorId, CurrentActorReceivedAt |
| **UserCompanyRoles** | 382-411 | User roles | ApproverLevel (1-3), PrimaryRoleId, DepartmentId |
| **RfqStatusHistory** | 721-736 | Status changes | ActorRole, ApprovalLevel, Decision, FromStatus, ToStatus |
| **RfqActorTimeline** | 741-751 | Actor timeline | ReceivedAt, ActionAt, IsOntime |
| **RfqInvitations** | 760-787 | Supplier invitations | Decision (PENDING/PARTICIPATING/NOT_PARTICIPATING) |
| **QuotationItems** | 809-831 | Quotation submissions | SubmittedAt, SubmittedByContactId |
| **Suppliers** | 458-493 | Supplier data | Status (PENDING/COMPLETED/DECLINED), RegisteredAt |
| **QnAThreads** | 900-910 | Q&A threads | ThreadStatus (OPEN/CLOSED) |
| **QnAMessages** | 915-926 | Q&A messages | SenderType (SUPPLIER/PURCHASING), SentAt |
| **Notifications** | 935-995 | Real-time alerts | IconType (22 types), IsRead, CreatedAt |

### 1.2 Line-by-Line Coverage Summary

| Document | Total Lines | Mapped Lines | Coverage |
|----------|-------------|--------------|----------|
| 00_1RFQ_WorkFlow.txt | 33 | 33 | 100% ✅ |
| 06_Dashboard_RealTime.txt | 84 | 84 | 100% ✅ |
| **TOTAL** | **117** | **117** | **100%** ✅ |

---

## SECTION 2: RFQ Multi-Level Approval WorkFlow

### 2.1 Business Flow Mapping (Lines 1-33 of 00_1RFQ_WorkFlow.txt)

```
Line 1:  ### RFQ_Flow ปัจจุบัน
Line 3:  สมชาย (REQUESTER) - ลูกน้อง IT
Line 4:      ↓ สร้าง RFQ + ส่งอนุมัติ
Line 6:  👔 ประเสริฐ (APPROVER Level 1) - หัวหน้าแผนก IT
Line 7:      ↓ อนุมัติ/ไม่อนุมัติ
Line 9:  🏢 วิชัย (ถ้ามี ? APPROVER Level 2) - ผู้จัดการฝ่าย/Executive
Line 10:     ↓ อนุมัติ/ไม่อนุมัติ
Line 12: 🏛️ สมศักดิ์ (ถ้ามี ? APPROVER Level 3) - ผู้บริหารระดับสูง/Executive
Line 13:     ↓ อนุมัติ/ไม่อนุมัติ
Line 15: 📦 ณัฐยา (PURCHASING) - ลูกน้อง จัดซื้อ
Line 16:     ↓ เชิญ Supplier + จัดการ
Line 18: 👔 A (PURCHASING_APPROVER Level 1) - หัวหน้าแผนก PURCHASING
Line 19:     ↓ อนุมัติ/ไม่อนุมัติ
Line 21: 🏢 B (ถ้ามี ? PURCHASING_APPROVER Level 2) - ผู้จัดการฝ่าย/Executive PURCHASING
Line 22:     ↓ อนุมัติ/ไม่อนุมัติ
Line 24: 🏛️ อนุวัฒน์ (ถ้ามี ? PURCHASING_APPROVER Level 3) - ผู้บริหารระดับสูง/Executive PURCHASING
Line 25:     ↓ อนุมัติ/ไม่อนุมัติ
```

### 2.2 Database Schema for Approval Chain

#### Rfqs Table (Lines 571-620)
```sql
CREATE TABLE "Rfqs" (
  "Id" BIGSERIAL PRIMARY KEY,
  "Status" VARCHAR(20) DEFAULT 'SAVE_DRAFT',

  -- Multi-level approval tracking
  "CurrentLevel" SMALLINT DEFAULT 0,                   -- Lines 6-25: Current approval level (0-3)
  "CurrentActorId" BIGINT REFERENCES "Users"("Id"),   -- Lines 6, 9, 12, 18, 21, 24: Who is reviewing
  "CurrentActorReceivedAt" TIMESTAMP,                  -- When current actor received the RFQ

  CONSTRAINT "chk_rfq_status" CHECK ("Status" IN
    ('SAVE_DRAFT','PENDING','DECLINED','REJECTED','COMPLETED','RE_BID'))
);
```

#### UserCompanyRoles Table (Lines 382-411)
```sql
CREATE TABLE "UserCompanyRoles" (
  "Id" BIGSERIAL PRIMARY KEY,
  "UserId" BIGINT NOT NULL,
  "PrimaryRoleId" BIGINT NOT NULL REFERENCES "Roles"("Id"),

  -- Lines 6, 9, 12: APPROVER Level 1-3
  -- Lines 18, 21, 24: PURCHASING_APPROVER Level 1-3
  "ApproverLevel" SMALLINT CHECK ("ApproverLevel" BETWEEN 1 AND 3),

  UNIQUE("UserId", "CompanyId", "DepartmentId", "PrimaryRoleId")
);

COMMENT ON COLUMN "UserCompanyRoles"."ApproverLevel" IS
  'ระดับผู้อนุมัติ (1-3) สำหรับ APPROVER และ PURCHASING_APPROVER';
```

#### RfqStatusHistory Table (Lines 721-736) - CORRECTED
```sql
-- ✅ THIS IS THE CORRECT TABLE (NOT RfqApprovalHistory)
CREATE TABLE "RfqStatusHistory" (
  "Id" BIGSERIAL PRIMARY KEY,
  "RfqId" BIGINT NOT NULL REFERENCES "Rfqs"("Id"),

  -- Status transition
  "FromStatus" VARCHAR(20),                           -- Previous status
  "ToStatus" VARCHAR(20) NOT NULL,                    -- New status

  -- Actor information (Lines 3, 6, 9, 12, 15, 18, 21, 24)
  "ActionType" VARCHAR(50) NOT NULL,                  -- SUBMIT, APPROVE, DECLINE, REJECT
  "ActorId" BIGINT NOT NULL REFERENCES "Users"("Id"),
  "ActorRole" VARCHAR(30),                            -- REQUESTER, APPROVER, PURCHASING, PURCHASING_APPROVER
  "ApprovalLevel" SMALLINT,                           -- 1, 2, or 3 (Lines 6, 9, 12, 18, 21, 24)

  -- Decision (Lines 7, 10, 13, 19, 22, 25)
  "Decision" VARCHAR(20),                             -- APPROVED, DECLINED, REJECTED, SUBMITTED
  "Reason" TEXT,                                      -- Decline/Reject reason
  "Comments" TEXT,

  "ActionAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "chk_decision" CHECK ("Decision" IN ('APPROVED','DECLINED','REJECTED','SUBMITTED'))
);

COMMENT ON TABLE "RfqStatusHistory" IS 'ประวัติการเปลี่ยนสถานะ RFQ';
```

#### RfqActorTimeline Table (Lines 741-751) - NEW
```sql
-- ✅ TIMELINE OF EACH ACTOR
CREATE TABLE "RfqActorTimeline" (
  "Id" BIGSERIAL PRIMARY KEY,
  "RfqId" BIGINT NOT NULL REFERENCES "Rfqs"("Id"),
  "ActorId" BIGINT NOT NULL REFERENCES "Users"("Id"),  -- Lines 6, 9, 12, 18, 21, 24
  "ActorRole" VARCHAR(30) NOT NULL,                     -- APPROVER, PURCHASING_APPROVER

  -- Timing
  "ReceivedAt" TIMESTAMP NOT NULL,                      -- When actor received RFQ
  "ActionAt" TIMESTAMP,                                 -- When actor took action (NULL = pending)
  "IsOntime" BOOLEAN,                                   -- Did actor respond on time?

  CONSTRAINT "uk_rfq_actor" UNIQUE("RfqId", "ActorId", "ReceivedAt")
);

COMMENT ON TABLE "RfqActorTimeline" IS 'Timeline การทำงานของแต่ละ Actor';
```

### 2.3 Complete Approval Chain Query

```sql
-- Lines 3-25: Get complete approval history with actor timeline
WITH approval_chain AS (
  SELECT
    sh."RfqId",
    sh."ActorId",
    u."FirstNameTh" || ' ' || u."LastNameTh" AS "ActorName",  -- Lines 3, 6, 9, 12, 15, 18, 21, 24
    sh."ActorRole",
    sh."ApprovalLevel",                                         -- Lines 6, 9, 12, 18, 21, 24
    sh."Decision",                                              -- Lines 7, 10, 13, 19, 22, 25
    sh."FromStatus",
    sh."ToStatus",
    sh."ActionAt",
    at."ReceivedAt",
    at."IsOntime",

    -- Calculate response time
    EXTRACT(EPOCH FROM (sh."ActionAt" - at."ReceivedAt")) / 3600 AS "ResponseHours",

    -- Position title based on role and level
    CASE
      -- Lines 6, 9, 12: APPROVER levels
      WHEN sh."ActorRole" = 'APPROVER' AND sh."ApprovalLevel" = 1 THEN 'หัวหน้าแผนก'
      WHEN sh."ActorRole" = 'APPROVER' AND sh."ApprovalLevel" = 2 THEN 'ผู้จัดการฝ่าย/Executive'
      WHEN sh."ActorRole" = 'APPROVER' AND sh."ApprovalLevel" = 3 THEN 'ผู้บริหารระดับสูง/Executive'

      -- Lines 18, 21, 24: PURCHASING_APPROVER levels
      WHEN sh."ActorRole" = 'PURCHASING_APPROVER' AND sh."ApprovalLevel" = 1 THEN 'หัวหน้าแผนก PURCHASING'
      WHEN sh."ActorRole" = 'PURCHASING_APPROVER' AND sh."ApprovalLevel" = 2 THEN 'ผู้จัดการฝ่าย/Executive PURCHASING'
      WHEN sh."ActorRole" = 'PURCHASING_APPROVER' AND sh."ApprovalLevel" = 3 THEN 'ผู้บริหารระดับสูง/Executive PURCHASING'

      -- Line 15: PURCHASING
      WHEN sh."ActorRole" = 'PURCHASING' THEN 'ลูกน้อง จัดซื้อ'

      -- Line 3: REQUESTER
      WHEN sh."ActorRole" = 'REQUESTER' THEN 'ลูกน้อง IT'

      ELSE sh."ActorRole"
    END AS "PositionTitle",

    -- Sequence number for ordering
    ROW_NUMBER() OVER (PARTITION BY sh."RfqId" ORDER BY sh."ActionAt") AS "Sequence"

  FROM "RfqStatusHistory" sh
  JOIN "Users" u ON sh."ActorId" = u."Id"
  LEFT JOIN "RfqActorTimeline" at ON
    sh."RfqId" = at."RfqId"
    AND sh."ActorId" = at."ActorId"
    AND at."ReceivedAt" <= sh."ActionAt"
  WHERE sh."RfqId" = @RfqId
    AND sh."Decision" IS NOT NULL  -- Only approved/declined actions
)
SELECT
  "Sequence",
  "ActorName",
  "PositionTitle",
  "ActorRole",
  "ApprovalLevel",
  "Decision",
  "FromStatus",
  "ToStatus",
  "ReceivedAt",
  "ActionAt",
  "ResponseHours",
  "IsOntime",

  -- Visual indicator
  CASE "Decision"
    WHEN 'APPROVED' THEN '✅ อนุมัติ'
    WHEN 'DECLINED' THEN '❌ ไม่อนุมัติ'
    WHEN 'REJECTED' THEN '🚫 ปฏิเสธ'
  END AS "DecisionDisplay"

FROM approval_chain
ORDER BY "Sequence";
```

### 2.4 Dynamic Next Approver Function

```sql
-- Lines 6-25: Determine who receives RFQ next
CREATE OR REPLACE FUNCTION get_next_approver_v62(
  p_rfq_id BIGINT,
  p_current_role VARCHAR(30),
  p_current_level SMALLINT
)
RETURNS TABLE (
  "NextActorId" BIGINT,
  "NextActorName" VARCHAR(200),
  "NextRoleCode" VARCHAR(30),
  "NextLevel" SMALLINT,
  "PositionTitle" VARCHAR(200)
) AS $
DECLARE
  v_company_id BIGINT;
  v_department_id BIGINT;
  v_category_id BIGINT;
BEGIN
  -- Get RFQ context
  SELECT "CompanyId", "DepartmentId", "CategoryId"
  INTO v_company_id, v_department_id, v_category_id
  FROM "Rfqs"
  WHERE "Id" = p_rfq_id;

  -- ====================================
  -- APPROVER CHAIN (Lines 6-13)
  -- ====================================
  IF p_current_role = 'REQUESTER' THEN
    -- Line 6: Next is APPROVER Level 1 (หัวหน้าแผนก)
    RETURN QUERY
    SELECT
      u."Id",
      u."FirstNameTh" || ' ' || u."LastNameTh",
      'APPROVER'::VARCHAR(30),
      1::SMALLINT,
      'หัวหน้าแผนก'::VARCHAR(200)
    FROM "UserCompanyRoles" ucr
    JOIN "Users" u ON ucr."UserId" = u."Id"
    JOIN "Roles" r ON ucr."PrimaryRoleId" = r."Id"
    WHERE ucr."CompanyId" = v_company_id
      AND ucr."DepartmentId" = v_department_id
      AND r."RoleCode" = 'APPROVER'
      AND ucr."ApproverLevel" = 1
      AND ucr."IsActive" = TRUE
    LIMIT 1;

  ELSIF p_current_role = 'APPROVER' THEN
    -- Check if Level 2 or 3 exists
    IF EXISTS (
      SELECT 1 FROM "UserCompanyRoles" ucr
      JOIN "Roles" r ON ucr."PrimaryRoleId" = r."Id"
      WHERE ucr."CompanyId" = v_company_id
        AND ucr."DepartmentId" = v_department_id
        AND r."RoleCode" = 'APPROVER'
        AND ucr."ApproverLevel" = p_current_level + 1
        AND ucr."IsActive" = TRUE
    ) THEN
      -- Line 9 or 12: Go to next APPROVER level
      RETURN QUERY
      SELECT
        u."Id",
        u."FirstNameTh" || ' ' || u."LastNameTh",
        'APPROVER'::VARCHAR(30),
        (p_current_level + 1)::SMALLINT,
        CASE p_current_level + 1
          WHEN 2 THEN 'ผู้จัดการฝ่าย/Executive'
          WHEN 3 THEN 'ผู้บริหารระดับสูง/Executive'
        END::VARCHAR(200)
      FROM "UserCompanyRoles" ucr
      JOIN "Users" u ON ucr."UserId" = u."Id"
      JOIN "Roles" r ON ucr."PrimaryRoleId" = r."Id"
      WHERE ucr."CompanyId" = v_company_id
        AND ucr."DepartmentId" = v_department_id
        AND r."RoleCode" = 'APPROVER'
        AND ucr."ApproverLevel" = p_current_level + 1
        AND ucr."IsActive" = TRUE
      LIMIT 1;
    ELSE
      -- Line 15: No more APPROVER levels, go to PURCHASING
      RETURN QUERY
      SELECT
        r."ResponsiblePersonId",
        u."FirstNameTh" || ' ' || u."LastNameTh",
        'PURCHASING'::VARCHAR(30),
        0::SMALLINT,
        'ลูกน้อง จัดซื้อ'::VARCHAR(200)
      FROM "Rfqs" r
      JOIN "Users" u ON r."ResponsiblePersonId" = u."Id"
      WHERE r."Id" = p_rfq_id;
    END IF;

  -- ====================================
  -- PURCHASING_APPROVER CHAIN (Lines 18-25)
  -- ====================================
  ELSIF p_current_role = 'PURCHASING' THEN
    -- Line 18: Next is PURCHASING_APPROVER Level 1
    RETURN QUERY
    SELECT
      u."Id",
      u."FirstNameTh" || ' ' || u."LastNameTh",
      'PURCHASING_APPROVER'::VARCHAR(30),
      1::SMALLINT,
      'หัวหน้าแผนก PURCHASING'::VARCHAR(200)
    FROM "UserCompanyRoles" ucr
    JOIN "Users" u ON ucr."UserId" = u."Id"
    JOIN "Roles" r ON ucr."PrimaryRoleId" = r."Id"
    JOIN "UserCategoryBindings" ucb ON ucr."Id" = ucb."UserCompanyRoleId"
    WHERE ucr."CompanyId" = v_company_id
      AND r."RoleCode" = 'PURCHASING_APPROVER'
      AND ucr."ApproverLevel" = 1
      AND ucb."CategoryId" = v_category_id
      AND ucr."IsActive" = TRUE
      AND ucb."IsActive" = TRUE
    LIMIT 1;

  ELSIF p_current_role = 'PURCHASING_APPROVER' THEN
    -- Lines 21, 24: Check if next PA level exists
    IF EXISTS (
      SELECT 1 FROM "UserCompanyRoles" ucr
      JOIN "Roles" r ON ucr."PrimaryRoleId" = r."Id"
      JOIN "UserCategoryBindings" ucb ON ucr."Id" = ucb."UserCompanyRoleId"
      WHERE ucr."CompanyId" = v_company_id
        AND r."RoleCode" = 'PURCHASING_APPROVER'
        AND ucr."ApproverLevel" = p_current_level + 1
        AND ucb."CategoryId" = v_category_id
        AND ucr."IsActive" = TRUE
    ) THEN
      RETURN QUERY
      SELECT
        u."Id",
        u."FirstNameTh" || ' ' || u."LastNameTh",
        'PURCHASING_APPROVER'::VARCHAR(30),
        (p_current_level + 1)::SMALLINT,
        CASE p_current_level + 1
          WHEN 2 THEN 'ผู้จัดการฝ่าย/Executive PURCHASING'
          WHEN 3 THEN 'ผู้บริหารระดับสูง/Executive PURCHASING'
        END::VARCHAR(200)
      FROM "UserCompanyRoles" ucr
      JOIN "Users" u ON ucr."UserId" = u."Id"
      JOIN "Roles" r ON ucr."PrimaryRoleId" = r."Id"
      JOIN "UserCategoryBindings" ucb ON ucr."Id" = ucb."UserCompanyRoleId"
      WHERE ucr."CompanyId" = v_company_id
        AND r."RoleCode" = 'PURCHASING_APPROVER'
        AND ucr."ApproverLevel" = p_current_level + 1
        AND ucb."CategoryId" = v_category_id
        AND ucr."IsActive" = TRUE
      LIMIT 1;
    ELSE
      -- All approvals complete, RFQ is COMPLETED
      RETURN;
    END IF;
  END IF;
END;
$ LANGUAGE plpgsql;
```

### 2.5 Update RFQ to Next Approver

```sql
-- Called after each approval to move RFQ to next actor
CREATE OR REPLACE FUNCTION route_rfq_to_next_approver(
  p_rfq_id BIGINT
) RETURNS VOID AS $
DECLARE
  v_current_status VARCHAR(20);
  v_current_role VARCHAR(30);
  v_current_level SMALLINT;
  v_next_actor RECORD;
BEGIN
  -- Get current state
  SELECT
    r."Status",
    sh."ActorRole",
    sh."ApprovalLevel"
  INTO v_current_status, v_current_role, v_current_level
  FROM "Rfqs" r
  LEFT JOIN LATERAL (
    SELECT "ActorRole", "ApprovalLevel"
    FROM "RfqStatusHistory"
    WHERE "RfqId" = r."Id"
      AND "Decision" = 'APPROVED'
    ORDER BY "ActionAt" DESC
    LIMIT 1
  ) sh ON TRUE
  WHERE r."Id" = p_rfq_id;

  -- Get next approver
  SELECT * INTO v_next_actor
  FROM get_next_approver_v62(p_rfq_id, v_current_role, v_current_level)
  LIMIT 1;

  IF v_next_actor."NextActorId" IS NOT NULL THEN
    -- Update RFQ to next actor
    UPDATE "Rfqs"
    SET
      "CurrentActorId" = v_next_actor."NextActorId",
      "CurrentLevel" = v_next_actor."NextLevel",
      "CurrentActorReceivedAt" = CURRENT_TIMESTAMP,
      "UpdatedAt" = CURRENT_TIMESTAMP
    WHERE "Id" = p_rfq_id;

    -- Record in timeline
    INSERT INTO "RfqActorTimeline" (
      "RfqId",
      "ActorId",
      "ActorRole",
      "ReceivedAt"
    ) VALUES (
      p_rfq_id,
      v_next_actor."NextActorId",
      v_next_actor."NextRoleCode",
      CURRENT_TIMESTAMP
    );
  ELSE
    -- No more approvers, mark as COMPLETED
    UPDATE "Rfqs"
    SET
      "Status" = 'COMPLETED',
      "CurrentActorId" = NULL,
      "CurrentLevel" = 0,
      "UpdatedAt" = CURRENT_TIMESTAMP
    WHERE "Id" = p_rfq_id;
  END IF;
END;
$ LANGUAGE plpgsql;
```

---

## SECTION 3: Dashboard: Requester (RealTime)

### 3.1 Business Requirements (Lines 1-14 of 06_Dashboard_RealTime.txt)

```
Line 1:  ### Dashboard Requester (RealTime)
Line 2:   หัวข้อ ใบขอราคา
Line 3:  ตัวเลือกช่วงวันที่ (Date Range Selector)
Line 4:  Total | Save Draft | Pending | Declined | Rejected | Completed
Line 5:  จำนวน   จำนวน       จำนวน     จำนวน      จำนวน       จำนวน
Line 6:  Just now | 4 hours ago | Just now | Just now | Just now | Just now
Line 8:   หัวข้อ 5 ใบขอราคาที่ใกล้ครบกำหนดในสัปดาห์นี้
Line 9:  Format ShortNameEn-yy-mm-xxxx + ชื่อโครงการ/งาน + "Due" + วันที่ต้องการรับใบเสนอราคา
Line 11:  หัวข้อ การแจ้งเตือนล่าสุด
Line 12: Format If Rfqs.Status = "Save Draft" > Icon + "ใบขอราคาของคุณ ที่บันทึกแบบร่างไว้..."
Line 13:      else Icon+ShortNameEn-yy-mm-xxxx + "ชื่อโครงการ/งาน" + ผู้ส่ง + {action}...
```

### 3.2 Status Counts with Relative Time (Lines 4-6)

```sql
-- Lines 4-6: Real-time RFQ status counts for REQUESTER
WITH rfq_counts AS (
  SELECT
    -- Line 4: Total
    COUNT(*) AS "Total",

    -- Line 4: Save Draft
    COUNT(*) FILTER (WHERE "Status" = 'SAVE_DRAFT') AS "SaveDraft",

    -- Line 4: Pending
    COUNT(*) FILTER (WHERE "Status" = 'PENDING') AS "Pending",

    -- Line 4: Declined
    COUNT(*) FILTER (WHERE "Status" = 'DECLINED') AS "Declined",

    -- Line 4: Rejected
    COUNT(*) FILTER (WHERE "Status" = 'REJECTED') AS "Rejected",

    -- Line 4: Completed
    COUNT(*) FILTER (WHERE "Status" = 'COMPLETED') AS "Completed"

  FROM "Rfqs"
  WHERE "RequesterId" = @UserId
    AND "CreatedDate" BETWEEN @StartDate AND @EndDate  -- Line 3: Date Range
),
-- Line 6: Relative time calculation
latest_updates AS (
  SELECT
    "Status",
    MAX("UpdatedAt") AS "LastUpdate",

    -- Line 6: Format "Just now" or "4 hours ago"
    CASE
      WHEN MAX("UpdatedAt") >= CURRENT_TIMESTAMP - INTERVAL '1 minute' THEN 'Just now'
      WHEN MAX("UpdatedAt") >= CURRENT_TIMESTAMP - INTERVAL '1 hour' THEN
        FLOOR(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - MAX("UpdatedAt"))) / 60)::TEXT || ' minutes ago'
      WHEN MAX("UpdatedAt") >= CURRENT_TIMESTAMP - INTERVAL '1 day' THEN
        FLOOR(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - MAX("UpdatedAt"))) / 3600)::TEXT || ' hours ago'
      WHEN MAX("UpdatedAt") >= CURRENT_TIMESTAMP - INTERVAL '7 days' THEN
        FLOOR(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - MAX("UpdatedAt"))) / 86400)::TEXT || ' days ago'
      ELSE
        TO_CHAR(MAX("UpdatedAt"), 'DD/MM/YYYY')
    END AS "RelativeTime"

  FROM "Rfqs"
  WHERE "RequesterId" = @UserId
    AND "CreatedDate" BETWEEN @StartDate AND @EndDate
  GROUP BY "Status"
)
SELECT
  rc.*,
  COALESCE(lu_total."RelativeTime", 'No updates') AS "TotalTime",
  COALESCE(lu_draft."RelativeTime", '-') AS "SaveDraftTime",
  COALESCE(lu_pending."RelativeTime", '-') AS "PendingTime",
  COALESCE(lu_declined."RelativeTime", '-') AS "DeclinedTime",
  COALESCE(lu_rejected."RelativeTime", '-') AS "RejectedTime",
  COALESCE(lu_completed."RelativeTime", '-') AS "CompletedTime"
FROM rfq_counts rc
LEFT JOIN latest_updates lu_total ON TRUE
LEFT JOIN latest_updates lu_draft ON lu_draft."Status" = 'SAVE_DRAFT'
LEFT JOIN latest_updates lu_pending ON lu_pending."Status" = 'PENDING'
LEFT JOIN latest_updates lu_declined ON lu_declined."Status" = 'DECLINED'
LEFT JOIN latest_updates lu_rejected ON lu_rejected."Status" = 'REJECTED'
LEFT JOIN latest_updates lu_completed ON lu_completed."Status" = 'COMPLETED';
```

### 3.3 Top 5 Upcoming Deadlines (Lines 8-9)

```sql
-- Line 8: "5 ใบขอราคาที่ใกล้ครบกำหนดในสัปดาห์นี้"
--         "เงื่อนไข แสดง fix 5 รายการ สถานะ Pending โดยนับตั้งแต่ วันที่ต้องการรับใบเสนอราคา มา 5 วัน"

SELECT
  r."Id",
  r."RfqNumber",
  r."ProjectName",
  r."RequiredQuotationDate",
  c."ShortNameEn",

  -- Line 9: Format "ShortNameEn-yy-mm-xxxx + ชื่อโครงการ/งาน + Due + วันที่"
  c."ShortNameEn" || '-' ||
  TO_CHAR(r."CreatedDate", 'YY-MM-') ||
  LPAD(RIGHT(r."RfqNumber", 4), 4, '0') ||
  ' ' || r."ProjectName" ||
  ' Due ' || TO_CHAR(r."RequiredQuotationDate", 'DD/MM/YYYY') AS "DisplayText",

  -- Days until deadline
  EXTRACT(DAY FROM (r."RequiredQuotationDate" - CURRENT_DATE)) AS "DaysRemaining",

  -- Visual urgency indicator
  CASE
    WHEN r."RequiredQuotationDate" <= CURRENT_DATE THEN 'OVERDUE'
    WHEN r."RequiredQuotationDate" <= CURRENT_DATE + INTERVAL '1 day' THEN 'URGENT'
    WHEN r."RequiredQuotationDate" <= CURRENT_DATE + INTERVAL '3 days' THEN 'WARNING'
    ELSE 'NORMAL'
  END AS "UrgencyLevel"

FROM "Rfqs" r
JOIN "Companies" c ON r."CompanyId" = c."Id"
WHERE r."RequesterId" = @UserId
  AND r."Status" = 'PENDING'                           -- Line 8: สถานะ Pending
  AND r."RequiredQuotationDate" BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '5 days'  -- Line 8: มา 5 วัน
ORDER BY r."RequiredQuotationDate" ASC
LIMIT 5;                                               -- Line 8: fix 5 รายการ
```

### 3.4 Latest Notifications (Lines 11-13)

```sql
-- Lines 11-13: การแจ้งเตือนล่าสุด
WITH formatted_notifications AS (
  SELECT
    n."Id",
    n."Type",
    n."IconType",
    n."CreatedAt",
    n."IsRead",
    r."RfqNumber",
    r."ProjectName",
    r."Status",
    c."ShortNameEn",

    -- Actor who triggered notification
    sender."FirstNameTh" || ' ' || sender."LastNameTh" AS "SenderName",

    -- Line 12: Special format for SAVE_DRAFT expiring soon
    CASE
      WHEN r."Status" = 'SAVE_DRAFT' AND n."Type" = 'DRAFT_EXPIRING' THEN
        'ใบขอราคาของคุณ ที่บันทึกแบบร่างไว้ ใกล้จะหมดอายุแล้ว กรุณาตรวจสอบใบขอราคา ที่เมนู ดูใบของราคา'

      -- Line 13: else format
      ELSE
        c."ShortNameEn" || '-' ||
        TO_CHAR(r."CreatedDate", 'YY-MM-') ||
        LPAD(RIGHT(r."RfqNumber", 4), 4, '0') || ' ' ||
        r."ProjectName" || ' ' ||
        sender."FirstNameTh" || ' ' || sender."LastNameTh" || ' ' ||
        n."Message"
    END AS "FormattedMessage",

    -- Line 13: Relative time ("3 hours ago")
    CASE
      WHEN n."CreatedAt" >= CURRENT_TIMESTAMP - INTERVAL '1 minute' THEN 'Just now'
      WHEN n."CreatedAt" >= CURRENT_TIMESTAMP - INTERVAL '1 hour' THEN
        FLOOR(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - n."CreatedAt")) / 60)::TEXT || ' minutes ago'
      WHEN n."CreatedAt" >= CURRENT_TIMESTAMP - INTERVAL '1 day' THEN
        FLOOR(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - n."CreatedAt")) / 3600)::TEXT || ' hours ago'
      WHEN n."CreatedAt" >= CURRENT_TIMESTAMP - INTERVAL '7 days' THEN
        FLOOR(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - n."CreatedAt")) / 86400)::TEXT || ' days ago'
      ELSE
        TO_CHAR(n."CreatedAt", 'DD/MM/YYYY')
    END AS "RelativeTime",

    -- Action URL
    n."ActionUrl" AS "ActionUrl"

  FROM "Notifications" n
  LEFT JOIN "Rfqs" r ON n."RfqId" = r."Id"
  LEFT JOIN "Companies" c ON r."CompanyId" = c."Id"
  LEFT JOIN "Users" sender ON n."CreatedBy" = sender."Id"
  WHERE n."UserId" = @UserId
  ORDER BY n."CreatedAt" DESC
  LIMIT 10  -- Latest 10 notifications
)
SELECT
  "Id",
  "IconType",
  "FormattedMessage",
  "RelativeTime",
  "ActionUrl",
  "IsRead",
  "CreatedAt"
FROM formatted_notifications;
```

---

## SECTION 4: Dashboard: Approver (RealTime)

### 4.1 Business Requirements (Lines 15-27 of 06_Dashboard_RealTime.txt)

```
Line 15: ### Dashboard Approver (RealTime)
Line 16:  หัวข้อ ใบขอราคา
Line 17: ตัวเลือกช่วงวันที่ (Date Range Selector)
Line 18: Total | Pending
Line 19: จำนวน   จำนวน
Line 20: Just now | 4 hours ago
Line 22:  หัวข้อ 5 ใบขอราคาที่ใกล้ครบเวลาพิจารณาในสัปดาห์นี้
Line 23: Format ShortNameEn-yy-mm-xxxx + ชื่อโครงการ/งาน + "Due" + วันที่ต้องการรับใบเสนอราคา
Line 25:  หัวข้อ การแจ้งเตือนล่าสุด
Line 26: Format Icon+ShortNameEn-yy-mm-xxxx + "ชื่อโครงการ/งาน" + ผู้ส่ง + {action} + สถานะ {action}...
```

### 4.2 RFQ Counts for Approver (Lines 18-20)

```sql
-- Lines 18-20: RFQ counts for APPROVER (only show what's assigned to me or I reviewed)
WITH approver_rfqs AS (
  SELECT
    r."Id",
    r."Status",
    r."UpdatedAt",
    r."CurrentActorId",

    -- Check if this APPROVER has history with this RFQ
    EXISTS (
      SELECT 1 FROM "RfqStatusHistory" sh
      WHERE sh."RfqId" = r."Id"
        AND sh."ActorId" = @UserId
    ) AS "HasHistory"

  FROM "Rfqs" r
  WHERE r."CreatedDate" BETWEEN @StartDate AND @EndDate  -- Line 17: Date Range
    AND (
      r."CurrentActorId" = @UserId OR  -- Currently assigned to me
      EXISTS (
        SELECT 1 FROM "RfqStatusHistory" sh
        WHERE sh."RfqId" = r."Id"
          AND sh."ActorId" = @UserId
      )  -- Or I approved/declined in the past
    )
)
SELECT
  -- Line 18: Total
  COUNT(*) AS "Total",

  -- Line 18: Pending (waiting for my action)
  COUNT(*) FILTER (
    WHERE "Status" = 'PENDING'
      AND "CurrentActorId" = @UserId
  ) AS "Pending",

  -- Line 20: Relative time for Pending items
  CASE
    WHEN MAX("UpdatedAt") FILTER (WHERE "Status" = 'PENDING' AND "CurrentActorId" = @UserId) >= CURRENT_TIMESTAMP - INTERVAL '1 minute'
      THEN 'Just now'
    WHEN MAX("UpdatedAt") FILTER (WHERE "Status" = 'PENDING' AND "CurrentActorId" = @UserId) >= CURRENT_TIMESTAMP - INTERVAL '1 hour'
      THEN FLOOR(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - MAX("UpdatedAt") FILTER (WHERE "Status" = 'PENDING'))) / 60)::TEXT || ' minutes ago'
    WHEN MAX("UpdatedAt") FILTER (WHERE "Status" = 'PENDING' AND "CurrentActorId" = @UserId) >= CURRENT_TIMESTAMP - INTERVAL '1 day'
      THEN FLOOR(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - MAX("UpdatedAt") FILTER (WHERE "Status" = 'PENDING'))) / 3600)::TEXT || ' hours ago'
    ELSE
      FLOOR(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - MAX("UpdatedAt") FILTER (WHERE "Status" = 'PENDING'))) / 86400)::TEXT || ' days ago'
  END AS "PendingTime",

  -- Total time
  CASE
    WHEN MAX("UpdatedAt") >= CURRENT_TIMESTAMP - INTERVAL '1 minute' THEN 'Just now'
    WHEN MAX("UpdatedAt") >= CURRENT_TIMESTAMP - INTERVAL '1 hour' THEN
      FLOOR(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - MAX("UpdatedAt"))) / 60)::TEXT || ' minutes ago'
    WHEN MAX("UpdatedAt") >= CURRENT_TIMESTAMP - INTERVAL '1 day' THEN
      FLOOR(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - MAX("UpdatedAt"))) / 3600)::TEXT || ' hours ago'
    ELSE
      FLOOR(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - MAX("UpdatedAt"))) / 86400)::TEXT || ' days ago'
  END AS "TotalTime"

FROM approver_rfqs;
```

### 4.3 Upcoming Reviews (Lines 22-23)

```sql
-- Line 22: "5 ใบขอราคาที่ใกล้ครบเวลาพิจารณาในสัปดาห์นี้"
-- Calculate deadline based on RoleResponseTimes

WITH approver_deadlines AS (
  SELECT
    r."Id",
    r."RfqNumber",
    r."ProjectName",
    r."RequiredQuotationDate",
    r."CurrentActorReceivedAt",
    c."ShortNameEn",

    -- Get response time limit for APPROVER role
    (
      SELECT rrt."ResponseTimeDays"
      FROM "RoleResponseTimes" rrt
      JOIN "Roles" ro ON rrt."RoleId" = ro."Id"
      WHERE ro."RoleCode" = 'APPROVER'
      LIMIT 1
    ) AS "ResponseDays",

    -- Calculate my deadline
    r."CurrentActorReceivedAt" +
    (
      SELECT (rrt."ResponseTimeDays" * INTERVAL '1 day')
      FROM "RoleResponseTimes" rrt
      JOIN "Roles" ro ON rrt."RoleId" = ro."Id"
      WHERE ro."RoleCode" = 'APPROVER'
      LIMIT 1
    ) AS "MyDeadline"

  FROM "Rfqs" r
  JOIN "Companies" c ON r."CompanyId" = c."Id"
  WHERE r."CurrentActorId" = @UserId
    AND r."Status" = 'PENDING'
    AND r."RequiredQuotationDate" BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '5 days'
)
SELECT
  "Id",
  "RfqNumber",
  "ProjectName",
  "RequiredQuotationDate",

  -- Line 23: Format "ShortNameEn-yy-mm-xxxx + ชื่อโครงการ/งาน + Due + วันที่"
  "ShortNameEn" || '-' ||
  TO_CHAR("CurrentActorReceivedAt", 'YY-MM-') ||
  LPAD(RIGHT("RfqNumber", 4), 4, '0') ||
  ' ' || "ProjectName" ||
  ' Due ' || TO_CHAR("MyDeadline", 'DD/MM/YYYY HH24:MI') AS "DisplayText",

  -- Days remaining for me to decide
  EXTRACT(DAY FROM ("MyDeadline" - CURRENT_TIMESTAMP)) AS "DaysToDecide",

  -- Hours remaining
  EXTRACT(HOUR FROM ("MyDeadline" - CURRENT_TIMESTAMP)) AS "HoursToDecide",

  -- Urgency
  CASE
    WHEN "MyDeadline" <= CURRENT_TIMESTAMP THEN 'OVERDUE'
    WHEN "MyDeadline" <= CURRENT_TIMESTAMP + INTERVAL '4 hours' THEN 'URGENT'
    WHEN "MyDeadline" <= CURRENT_TIMESTAMP + INTERVAL '1 day' THEN 'WARNING'
    ELSE 'NORMAL'
  END AS "UrgencyLevel"

FROM approver_deadlines
ORDER BY "MyDeadline" ASC
LIMIT 5;
```

---

## SECTION 5: Dashboard: Purchasing (RealTime)

### 5.1 Business Requirements (Lines 28-46 of 06_Dashboard_RealTime.txt)

```
Line 28: ### Dashboard Purchasing (RealTime)
Line 29:  หัวข้อ ใบขอราคา
Line 30: ตัวเลือกช่วงวันที่
Line 31: Total | Pending | Declined | Rejected | Completed
Line 32: จำนวน   จำนวน     จำนวน      จำนวน       จำนวน
Line 33: Just now | 4 hours ago | Just now | Just now | Just now
Line 35:  หัวข้อ 5 Supplier ที่เข้าร่วมเสนอราคาเข้ามาสัปดาห์นี้
Line 36: Format ShortNameEn-yy-mm-xxxx + ชื่อโครงการ/งาน + จำนวน "ราย"
Line 38:  หัวข้อ 5 Supplier ลงทะเบียนล่าสุด
Line 39: Format Icon | "บริษัท" + ชื่อบริษัท/หน่วยงาน | คุณ (ชื่อ-สกุล ผู้ติดต่อหลัก) | เบอร์โทร | สถานะ
Line 41:  หัวข้อ 5 คำถามจาก Supplier ที่ยังไม่ได้ตอบ
Line 42: Format Icon | ชื่อบริษัท/หน่วยงาน | คนที่ถาม | สถานะ
Line 44:  หัวข้อ การแจ้งเตือนล่าสุด
Line 45: Format Icon+ShortNameEn-yy-mm-xxxx + "ชื่อโครงการ/งาน" + ผู้ส่ง + {action} + สถานะ {action}...
```

### 5.2 RFQ Status Counts (Lines 31-33)

```sql
-- Lines 31-33: RFQ counts for PURCHASING (ResponsiblePersonId)
SELECT
  COUNT(*) AS "Total",                                 -- Line 31
  COUNT(*) FILTER (WHERE "Status" = 'PENDING') AS "Pending",
  COUNT(*) FILTER (WHERE "Status" = 'DECLINED') AS "Declined",
  COUNT(*) FILTER (WHERE "Status" = 'REJECTED') AS "Rejected",
  COUNT(*) FILTER (WHERE "Status" = 'COMPLETED') AS "Completed",

  -- Line 33: Relative times
  CASE
    WHEN MAX("UpdatedAt") >= CURRENT_TIMESTAMP - INTERVAL '1 minute' THEN 'Just now'
    WHEN MAX("UpdatedAt") >= CURRENT_TIMESTAMP - INTERVAL '1 hour' THEN
      FLOOR(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - MAX("UpdatedAt"))) / 60)::TEXT || ' minutes ago'
    WHEN MAX("UpdatedAt") >= CURRENT_TIMESTAMP - INTERVAL '1 day' THEN
      FLOOR(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - MAX("UpdatedAt"))) / 3600)::TEXT || ' hours ago'
    ELSE
      FLOOR(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - MAX("UpdatedAt"))) / 86400)::TEXT || ' days ago'
  END AS "TotalTime",

  -- Per-status times
  CASE WHEN MAX("UpdatedAt") FILTER (WHERE "Status" = 'PENDING') >= CURRENT_TIMESTAMP - INTERVAL '1 hour'
    THEN FLOOR(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - MAX("UpdatedAt") FILTER (WHERE "Status" = 'PENDING'))) / 60)::TEXT || ' minutes ago'
    ELSE FLOOR(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - MAX("UpdatedAt") FILTER (WHERE "Status" = 'PENDING'))) / 3600)::TEXT || ' hours ago'
  END AS "PendingTime"

FROM "Rfqs"
WHERE "ResponsiblePersonId" = @UserId
  AND "CreatedDate" BETWEEN @StartDate AND @EndDate;  -- Line 30: Date Range
```

### 5.3 Weekly Supplier Submissions (Lines 35-36)

```sql
-- Line 35: "5 Supplier ที่เข้าร่วมเสนอราคาเข้ามาสัปดาห์นี้"
-- Line 36: Format "ShortNameEn-yy-mm-xxxx + ชื่อโครงการ/งาน + จำนวน ราย"

WITH weekly_quotations AS (
  SELECT
    qi."RfqId",
    COUNT(DISTINCT qi."SupplierId") AS "SupplierCount",
    MAX(qi."SubmittedAt") AS "LatestSubmission"
  FROM "QuotationItems" qi
  WHERE qi."SubmittedAt" >= CURRENT_DATE - INTERVAL '7 days'  -- This week
  GROUP BY qi."RfqId"
)
SELECT
  r."Id",
  r."RfqNumber",
  r."ProjectName",
  c."ShortNameEn",
  wq."SupplierCount",
  wq."LatestSubmission",

  -- Line 36: Format "ShortNameEn-yy-mm-xxxx + ชื่อโครงการ/งาน + จำนวน ราย"
  c."ShortNameEn" || '-' ||
  TO_CHAR(r."CreatedDate", 'YY-MM-') ||
  LPAD(RIGHT(r."RfqNumber", 4), 4, '0') ||
  ' ' || r."ProjectName" ||
  ' ' || wq."SupplierCount"::TEXT || ' ราย' AS "DisplayText"

FROM weekly_quotations wq
JOIN "Rfqs" r ON wq."RfqId" = r."Id"
JOIN "Companies" c ON r."CompanyId" = c."Id"
WHERE r."ResponsiblePersonId" = @UserId
ORDER BY wq."LatestSubmission" DESC, wq."SupplierCount" DESC
LIMIT 5;
```

### 5.4 Latest Supplier Registrations (Lines 38-39)

```sql
-- Line 38: "5 Supplier ลงทะเบียนล่าสุด"
-- Line 39: Format "Icon | บริษัท + ชื่อบริษัท/หน่วยงาน | คุณ (ชื่อ-สกุล ผู้ติดต่อหลัก) | เบอร์โทร | สถานะ"

SELECT
  s."Id",
  s."CompanyNameTh",                                   -- Line 39: ชื่อบริษัท/หน่วยงาน
  'บริษัท ' || s."CompanyNameTh" AS "CompanyDisplay",

  sc."FirstName" || ' ' || sc."LastName" AS "PrimaryContact",  -- Line 39: ผู้ติดต่อหลัก
  'คุณ ' || sc."FirstName" || ' ' || sc."LastName" AS "ContactDisplay",

  sc."MobileNumber",                                   -- Line 39: เบอร์โทร
  s."Status",                                          -- Line 39: สถานะ (PENDING/COMPLETED/DECLINED)
  s."RegisteredAt",

  -- Line 39: Icon based on status
  CASE s."Status"
    WHEN 'PENDING' THEN 'SUPPLIER_NEW'
    WHEN 'COMPLETED' THEN 'SUPPLIER_APPROVED'
    WHEN 'DECLINED' THEN 'SUPPLIER_DECLINED'
  END AS "IconType",

  -- Relative time
  CASE
    WHEN s."RegisteredAt" >= CURRENT_TIMESTAMP - INTERVAL '1 hour' THEN 'Just now'
    WHEN s."RegisteredAt" >= CURRENT_TIMESTAMP - INTERVAL '1 day' THEN
      FLOOR(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - s."RegisteredAt")) / 3600)::TEXT || ' hours ago'
    ELSE
      FLOOR(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - s."RegisteredAt")) / 86400)::TEXT || ' days ago'
  END AS "RegisteredTime"

FROM "Suppliers" s
LEFT JOIN "SupplierContacts" sc ON s."Id" = sc."SupplierId"
  AND sc."IsPrimaryContact" = TRUE
WHERE s."InvitedByUserId" = @UserId  -- Only suppliers I invited
ORDER BY s."RegisteredAt" DESC
LIMIT 5;
```

### 5.5 Unanswered Q&A (Lines 41-42)

```sql
-- Line 41: "5 คำถามจาก Supplier ที่ยังไม่ได้ตอบ"
-- Line 42: Format "Icon | ชื่อบริษัท/หน่วยงาน | คนที่ถาม | สถานะ"

WITH latest_messages_per_thread AS (
  SELECT
    qt."Id" AS "ThreadId",
    qt."RfqId",
    qt."SupplierId",
    qt."ThreadStatus",
    qm."MessageText",
    qm."SenderType",
    qm."SenderId",
    qm."SentAt",

    -- Get latest message in thread
    ROW_NUMBER() OVER (PARTITION BY qt."Id" ORDER BY qm."SentAt" DESC) AS "rn"

  FROM "QnAThreads" qt
  JOIN "QnAMessages" qm ON qt."Id" = qm."ThreadId"
  WHERE qt."ThreadStatus" = 'OPEN'  -- Only open threads
)
SELECT
  s."CompanyNameTh",                                   -- Line 42: ชื่อบริษัท/หน่วยงาน
  sc."FirstName" || ' ' || sc."LastName" AS "Sender", -- Line 42: คนที่ถาม
  'Waiting Reply' AS "Status",                         -- Line 42: สถานะ
  lm."MessageText",
  lm."SentAt",

  -- Line 42: Icon
  'QUESTION' AS "IconType",

  -- How long waiting
  CASE
    WHEN lm."SentAt" >= CURRENT_TIMESTAMP - INTERVAL '1 hour' THEN 'Just now'
    WHEN lm."SentAt" >= CURRENT_TIMESTAMP - INTERVAL '1 day' THEN
      FLOOR(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - lm."SentAt")) / 3600)::TEXT || ' hours ago'
    ELSE
      FLOOR(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - lm."SentAt")) / 86400)::TEXT || ' days ago'
  END AS "WaitingTime"

FROM latest_messages_per_thread lm
JOIN "Suppliers" s ON lm."SupplierId" = s."Id"
LEFT JOIN "SupplierContacts" sc ON lm."SenderId" = sc."Id"
WHERE lm."rn" = 1  -- Latest message
  AND lm."SenderType" = 'SUPPLIER'  -- Last message was from supplier (unanswered)
  AND lm."RfqId" IN (
    SELECT "Id" FROM "Rfqs" WHERE "ResponsiblePersonId" = @UserId
  )
ORDER BY lm."SentAt" ASC  -- Oldest unanswered first
LIMIT 5;
```

---

## SECTION 6: Dashboard: Supplier (RealTime)

### 6.1 Business Requirements (Lines 47-69 of 06_Dashboard_RealTime.txt)

```
Line 47: ### Dashboard Supplier (RealTime)
Line 48:  หัวข้อ รายการเสนอราคา
Line 49: ตัวเลือกช่วงวันที่
Line 50: Total | ยังไม่ตอบรับ | ตอบรับ และเข้าร่วม | ตอบรับ แต่ปฏิเสธ
Line 51: จำนวน     จำนวน           จำนวน                จำนวน
Line 52: Just now | 4 hours ago | Just now | Just now
Line 54:  หัวข้อ 5 คำเชิญ ให้เข้าร่วมรายการเสนอราคา
Lines 55-59: Invitation format details
Line 61:  หัวข้อ 5 ใบเสนอราคาที่ใกล้ครบกำหนดเสนอราคาในสัปดาห์นี้
Line 62: Format Icon+ShortNameEn-yy-mm-xxxx + "ชื่อโครงการ/งาน" + Expires date
Line 64:  หัวข้อ ถาม / ตอบ จัดซื้อล่าสุด
Line 65: Format Icon + "ชื่อโครงการ/งาน" + สถานะ
Line 67:  หัวข้อ การแจ้งเตือนล่าสุด
Line 68: Format Icon+ShortNameEn-yy-mm-xxxx + "ชื่อโครงการ/งาน" + ผู้ส่ง + {action}...
```

### 6.2 Invitation Status Counts (Lines 50-52)

```sql
-- Lines 50-52: Invitation counts for SUPPLIER
SELECT
  COUNT(*) AS "Total",                                 -- Line 50: Total

  -- Line 50: ยังไม่ตอบรับ (PENDING)
  COUNT(*) FILTER (WHERE ri."Decision" = 'PENDING') AS "NoResponse",

  -- Line 50: ตอบรับ และเข้าร่วม (PARTICIPATING)
  COUNT(*) FILTER (WHERE ri."Decision" = 'PARTICIPATING') AS "Participating",

  -- Line 50: ตอบรับ แต่ปฏิเสธ (NOT_PARTICIPATING)
  COUNT(*) FILTER (WHERE ri."Decision" = 'NOT_PARTICIPATING') AS "NotParticipating",

  -- AUTO_DECLINED also counted
  COUNT(*) FILTER (WHERE ri."Decision" = 'AUTO_DECLINED') AS "AutoDeclined",

  -- Line 52: Relative times
  CASE
    WHEN MAX(ri."InvitedAt") >= CURRENT_TIMESTAMP - INTERVAL '1 minute' THEN 'Just now'
    WHEN MAX(ri."InvitedAt") >= CURRENT_TIMESTAMP - INTERVAL '1 hour' THEN
      FLOOR(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - MAX(ri."InvitedAt"))) / 60)::TEXT || ' minutes ago'
    WHEN MAX(ri."InvitedAt") >= CURRENT_TIMESTAMP - INTERVAL '1 day' THEN
      FLOOR(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - MAX(ri."InvitedAt"))) / 3600)::TEXT || ' hours ago'
    ELSE
      FLOOR(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - MAX(ri."InvitedAt"))) / 86400)::TEXT || ' days ago'
  END AS "LatestTime"

FROM "RfqInvitations" ri
JOIN "Rfqs" r ON ri."RfqId" = r."Id"
WHERE ri."SupplierId" = @SupplierId
  AND r."CreatedDate" BETWEEN @StartDate AND @EndDate;  -- Line 49: Date Range
```

### 6.3 Latest Invitations (Lines 54-59)

```sql
-- Line 54: "5 คำเชิญ ให้เข้าร่วมรายการเสนอราคา"
-- Lines 55-59: Invitation format

SELECT
  r."Id",
  r."RfqNumber",
  r."ProjectName",
  r."RequiredQuotationDate",
  r."QuotationDeadline",
  c."ShortNameEn",
  ri."InvitedAt",
  ri."Decision",

  -- Line 56: ShortNameEn-yy-mm-xxxx
  c."ShortNameEn" || '-' ||
  TO_CHAR(r."CreatedDate", 'YY-MM-') ||
  LPAD(RIGHT(r."RfqNumber", 4), 4, '0') AS "RfqDisplayNumber",

  -- Line 57: ชื่อโครงการ/งาน
  r."ProjectName",

  -- Line 58: วันที่ต้องการใบเสนอราคา
  TO_CHAR(r."RequiredQuotationDate", 'DD/MM/YYYY') AS "RequiredDate",

  -- Line 59: ปุ่ม ดูรายละเอียด (action URL)
  '/supplier/rfqs/' || r."Id" AS "DetailUrl",

  -- Days remaining to respond
  EXTRACT(DAY FROM (r."QuotationDeadline" - CURRENT_TIMESTAMP)) AS "DaysToRespond"

FROM "RfqInvitations" ri
JOIN "Rfqs" r ON ri."RfqId" = r."Id"
JOIN "Companies" c ON r."CompanyId" = c."Id"
WHERE ri."SupplierId" = @SupplierId
  AND ri."Decision" = 'PENDING'  -- Only pending invitations
ORDER BY ri."InvitedAt" DESC
LIMIT 5;  -- Line 54: fix 5 รายการ
```

### 6.4 Upcoming Quotation Deadlines (Lines 61-62)

```sql
-- Line 61: "5 ใบเสนอราคาที่ใกล้ครบกำหนดเสนอราคาในสัปดาห์นี้"
-- Line 62: Format "Icon+ShortNameEn-yy-mm-xxxx + ชื่อโครงการ/งาน + Expires date"

SELECT
  r."Id",
  r."RfqNumber",
  r."ProjectName",
  r."QuotationDeadline",
  c."ShortNameEn",

  -- Line 62: Format
  c."ShortNameEn" || '-' ||
  TO_CHAR(r."CreatedDate", 'YY-MM-') ||
  LPAD(RIGHT(r."RfqNumber", 4), 4, '0') ||
  ' ' || r."ProjectName" ||
  ' Expires ' || TO_CHAR(r."QuotationDeadline", 'DD/MM/YYYY HH24:MI') AS "DisplayText",

  -- Line 62: Icon type
  CASE
    WHEN r."QuotationDeadline" <= CURRENT_TIMESTAMP THEN 'OVERDUE'
    WHEN r."QuotationDeadline" <= CURRENT_TIMESTAMP + INTERVAL '4 hours' THEN 'DEADLINE_WARNING'
    ELSE 'INFO'
  END AS "IconType",

  -- Days/hours remaining
  EXTRACT(DAY FROM (r."QuotationDeadline" - CURRENT_TIMESTAMP)) AS "DaysRemaining",
  EXTRACT(HOUR FROM (r."QuotationDeadline" - CURRENT_TIMESTAMP)) AS "HoursRemaining"

FROM "RfqInvitations" ri
JOIN "Rfqs" r ON ri."RfqId" = r."Id"
JOIN "Companies" c ON r."CompanyId" = c."Id"
WHERE ri."SupplierId" = @SupplierId
  AND ri."Decision" = 'PARTICIPATING'  -- Only RFQs I'm participating in
  AND r."QuotationDeadline" BETWEEN CURRENT_TIMESTAMP AND CURRENT_TIMESTAMP + INTERVAL '7 days'
ORDER BY r."QuotationDeadline" ASC
LIMIT 5;
```

### 6.5 Q&A Latest Status (Lines 64-65)

```sql
-- Line 64: "ถาม / ตอบ จัดซื้อล่าสุด"
-- Line 65: Format "Icon + ชื่อโครงการ/งาน + สถานะ"

WITH latest_qna AS (
  SELECT
    qt."Id" AS "ThreadId",
    qt."RfqId",
    qt."ThreadStatus",
    r."ProjectName",

    -- Get latest message timestamp
    (
      SELECT MAX("SentAt")
      FROM "QnAMessages" qm
      WHERE qm."ThreadId" = qt."Id"
    ) AS "LatestMessageAt",

    -- Check who sent last message
    (
      SELECT "SenderType"
      FROM "QnAMessages" qm
      WHERE qm."ThreadId" = qt."Id"
      ORDER BY "SentAt" DESC
      LIMIT 1
    ) AS "LastSenderType"

  FROM "QnAThreads" qt
  JOIN "Rfqs" r ON qt."RfqId" = r."Id"
  WHERE qt."SupplierId" = @SupplierId
)
SELECT
  "ThreadId",
  "ProjectName",                                       -- Line 65: ชื่อโครงการ/งาน

  -- Line 65: สถานะ
  CASE
    WHEN "ThreadStatus" = 'CLOSED' THEN 'Closed'
    WHEN "LastSenderType" = 'SUPPLIER' THEN 'Waiting Reply from PURCHASING'
    WHEN "LastSenderType" = 'PURCHASING' THEN 'New Reply'
    ELSE 'Open'
  END AS "Status",

  -- Line 65: Icon
  CASE
    WHEN "ThreadStatus" = 'CLOSED' THEN 'check'
    WHEN "LastSenderType" = 'PURCHASING' THEN 'REPLY'
    ELSE 'QUESTION'
  END AS "IconType",

  "LatestMessageAt",

  -- Relative time
  CASE
    WHEN "LatestMessageAt" >= CURRENT_TIMESTAMP - INTERVAL '1 hour' THEN 'Just now'
    WHEN "LatestMessageAt" >= CURRENT_TIMESTAMP - INTERVAL '1 day' THEN
      FLOOR(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - "LatestMessageAt")) / 3600)::TEXT || ' hours ago'
    ELSE
      FLOOR(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - "LatestMessageAt")) / 86400)::TEXT || ' days ago'
  END AS "LastActivityTime"

FROM latest_qna
ORDER BY "LatestMessageAt" DESC
LIMIT 5;
```

---

## SECTION 7: Dashboard: Purchasing Approver (RealTime)

### 7.1 Business Requirements (Lines 70-84 of 06_Dashboard_RealTime.txt)

```
Line 70: ### Dashboard Purchasing Approver (RealTime)
Line 71:  หัวข้อ Supplier เสนอราคา
Line 72: ตัวเลือกช่วงวันที่
Line 73: Total | Pending | Declined | Rejected | Completed
Line 74: จำนวน   จำนวน     จำนวน      จำนวน       จำนวน
Line 75: Just now | 4 hours ago | Just now | Just now | Just now
Line 77:  หัวข้อ 5 Supplier เสนอราคาเข้ามาสัปดาห์นี้
Line 78: Format ShortNameEn-yy-mm-xxxx + ชื่อโครงการ/งาน + จำนวน "ราย"
Line 80:  หัวข้อ 5 Supplier ลงทะเบียนล่าสุด
Line 81: Format Icon | "บริษัท" + ชื่อบริษัท/หน่วยงาน | คุณ (ชื่อ-สกุล ผู้ติดต่อหลัก) | เบอร์โทร | สถานะ
Line 83:  หัวข้อ การแจ้งเตือนล่าสุด
Line 84: Format Icon+ShortNameEn-yy-mm-xxxx + "ชื่อโครงการ/งาน" + ผู้ส่ง + {action}...
```

### 7.2 RFQ Status Counts (Lines 73-75)

```sql
-- Lines 73-75: PURCHASING_APPROVER dashboard counts
SELECT
  COUNT(*) AS "Total",                                 -- Line 73

  -- Pending (waiting for my action)
  COUNT(*) FILTER (
    WHERE "Status" = 'PENDING'
      AND "CurrentActorId" = @UserId
  ) AS "Pending",

  COUNT(*) FILTER (WHERE "Status" = 'DECLINED') AS "Declined",
  COUNT(*) FILTER (WHERE "Status" = 'REJECTED') AS "Rejected",
  COUNT(*) FILTER (WHERE "Status" = 'COMPLETED') AS "Completed",

  -- Line 75: Relative times
  CASE
    WHEN MAX("UpdatedAt") >= CURRENT_TIMESTAMP - INTERVAL '1 minute' THEN 'Just now'
    WHEN MAX("UpdatedAt") >= CURRENT_TIMESTAMP - INTERVAL '1 hour' THEN
      FLOOR(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - MAX("UpdatedAt"))) / 60)::TEXT || ' minutes ago'
    WHEN MAX("UpdatedAt") >= CURRENT_TIMESTAMP - INTERVAL '1 day' THEN
      FLOOR(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - MAX("UpdatedAt"))) / 3600)::TEXT || ' hours ago'
    ELSE
      FLOOR(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - MAX("UpdatedAt"))) / 86400)::TEXT || ' days ago'
  END AS "TotalTime"

FROM "Rfqs" r
WHERE r."CreatedDate" BETWEEN @StartDate AND @EndDate  -- Line 72: Date Range
  AND (
    r."CurrentActorId" = @UserId OR  -- Currently assigned to me
    EXISTS (
      SELECT 1 FROM "RfqStatusHistory" sh
      WHERE sh."RfqId" = r."Id"
        AND sh."ActorId" = @UserId
    )  -- Or I approved in the past
  );
```

### 7.3 Weekly Supplier Submissions (Lines 77-78)

```sql
-- Line 77: "5 Supplier เสนอราคาเข้ามาสัปดาห์นี้"
-- Same query as PURCHASING dashboard (Section 5.3)
-- See Lines 35-36 for details
```

### 7.4 Latest Supplier Registrations (Lines 80-81)

```sql
-- Line 80: "5 Supplier ลงทะเบียนล่าสุด"
-- Line 81: Same format as PURCHASING dashboard
-- Get suppliers pending PURCHASING_APPROVER approval

SELECT
  s."Id",
  s."CompanyNameTh",                                   -- Line 81
  'บริษัท ' || s."CompanyNameTh" AS "CompanyDisplay",

  sc."FirstName" || ' ' || sc."LastName" AS "PrimaryContact",
  'คุณ ' || sc."FirstName" || ' ' || sc."LastName" AS "ContactDisplay",

  sc."MobileNumber",                                   -- Line 81: เบอร์โทร
  s."Status",                                          -- Line 81: สถานะ
  s."RegisteredAt",

  -- Icon
  CASE s."Status"
    WHEN 'PENDING' THEN 'SUPPLIER_NEW'
    WHEN 'COMPLETED' THEN 'SUPPLIER_APPROVED'
    WHEN 'DECLINED' THEN 'SUPPLIER_DECLINED'
  END AS "IconType"

FROM "Suppliers" s
LEFT JOIN "SupplierContacts" sc ON s."Id" = sc."SupplierId"
  AND sc."IsPrimaryContact" = TRUE
WHERE s."Status" = 'PENDING'  -- Waiting for PURCHASING_APPROVER approval
ORDER BY s."RegisteredAt" DESC
LIMIT 5;
```

---

## SECTION 8: Real-Time Queries & Caching

### 8.1 Caching Strategy for Dashboards

```csharp
// Application layer - C# service implementation
public class DashboardService : IDashboardService
{
    private readonly IDbConnection _readDb;  // Dapper for READ
    private readonly IMemoryCache _cache;
    private readonly IDistributedCache _redisCache;  // For multi-server scale-out

    // Requester Dashboard
    public async Task<RequesterDashboardDto> GetRequesterDashboard(
        long userId,
        DateTime startDate,
        DateTime endDate,
        CancellationToken ct = default)
    {
        var cacheKey = $"dashboard:requester:{userId}:{startDate:yyyyMMdd}:{endDate:yyyyMMdd}";

        // Try L1 cache (in-memory)
        if (_cache.TryGetValue(cacheKey, out RequesterDashboardDto cached))
            return cached;

        // Try L2 cache (Redis)
        var redisValue = await _redisCache.GetStringAsync(cacheKey, ct);
        if (!string.IsNullOrEmpty(redisValue))
        {
            var result = JsonSerializer.Deserialize<RequesterDashboardDto>(redisValue);

            // Store in L1 cache
            _cache.Set(cacheKey, result, TimeSpan.FromSeconds(30));
            return result;
        }

        // Cache miss - query database
        var data = await QueryRequesterDashboard(userId, startDate, endDate, ct);

        // Store in both caches
        _cache.Set(cacheKey, data, TimeSpan.FromSeconds(30));  // L1: 30 seconds
        await _redisCache.SetStringAsync(
            cacheKey,
            JsonSerializer.Serialize(data),
            new DistributedCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(1)  // L2: 1 minute
            },
            ct);

        return data;
    }

    private async Task<RequesterDashboardDto> QueryRequesterDashboard(
        long userId,
        DateTime startDate,
        DateTime endDate,
        CancellationToken ct)
    {
        // Execute all queries in parallel
        var statusCountsTask = _readDb.QuerySingleAsync<StatusCountsDto>(
            RequesterQueries.GetStatusCounts,
            new { UserId = userId, StartDate = startDate, EndDate = endDate });

        var upcomingDeadlinesTask = _readDb.QueryAsync<UpcomingDeadlineDto>(
            RequesterQueries.GetUpcomingDeadlines,
            new { UserId = userId });

        var notificationsTask = _readDb.QueryAsync<NotificationDto>(
            RequesterQueries.GetLatestNotifications,
            new { UserId = userId });

        await Task.WhenAll(statusCountsTask, upcomingDeadlinesTask, notificationsTask);

        return new RequesterDashboardDto
        {
            StatusCounts = await statusCountsTask,
            UpcomingDeadlines = (await upcomingDeadlinesTask).ToList(),
            Notifications = (await notificationsTask).ToList(),
            LastRefreshed = DateTime.UtcNow
        };
    }
}
```

### 8.2 Cache Invalidation Strategy

```csharp
// Event handler - invalidate cache when RFQ status changes
public class RfqStatusChangedEventHandler : IEventHandler<RfqStatusChangedEvent>
{
    private readonly IDistributedCache _cache;
    private readonly IHubContext<DashboardHub> _hubContext;

    public async Task HandleAsync(RfqStatusChangedEvent evt, CancellationToken ct)
    {
        var rfq = await _dbContext.Rfqs
            .Include(r => r.Requester)
            .Include(r => r.CurrentActor)
            .FirstOrDefaultAsync(r => r.Id == evt.RfqId, ct);

        // Invalidate caches for affected users
        await InvalidateDashboardCache(rfq.RequesterId, "requester");

        if (rfq.CurrentActorId.HasValue)
            await InvalidateDashboardCache(rfq.CurrentActorId.Value, "approver");

        if (rfq.ResponsiblePersonId.HasValue)
            await InvalidateDashboardCache(rfq.ResponsiblePersonId.Value, "purchasing");

        // Push real-time updates via SignalR
        await PushDashboardUpdates(rfq);
    }

    private async Task InvalidateDashboardCache(long userId, string dashboardType)
    {
        // Remove all date range variations for this user
        var pattern = $"dashboard:{dashboardType}:{userId}:*";

        // Redis key pattern deletion
        var server = _redisConnection.GetServer(_redisConnection.GetEndPoints().First());
        var keys = server.Keys(pattern: pattern);

        foreach (var key in keys)
        {
            await _cache.RemoveAsync(key.ToString());
        }
    }
}
```

---

## SECTION 9: SignalR Integration

### 9.1 Dashboard Hub Implementation

```csharp
// SignalR Hub for real-time dashboard updates
public class DashboardHub : Hub
{
    private readonly ICurrentUserService _currentUser;
    private readonly ILogger<DashboardHub> _logger;

    public override async Task OnConnectedAsync()
    {
        var userId = Context.User?.FindFirst("uid")?.Value;
        var role = Context.User?.FindFirst("role")?.Value;
        var companyId = Context.User?.FindFirst("cid")?.Value;

        if (!string.IsNullOrEmpty(userId) && !string.IsNullOrEmpty(role))
        {
            // Join user-specific group
            await Groups.AddToGroupAsync(Context.ConnectionId, $"{role}:{userId}");

            // Join role-wide company group
            await Groups.AddToGroupAsync(Context.ConnectionId, $"{role}:company:{companyId}");

            _logger.LogInformation(
                "Dashboard connection: User {UserId}, Role {Role}, ConnectionId {ConnectionId}",
                userId, role, Context.ConnectionId);
        }

        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception exception)
    {
        var userId = Context.User?.FindFirst("uid")?.Value;

        _logger.LogInformation(
            "Dashboard disconnection: User {UserId}, ConnectionId {ConnectionId}",
            userId, Context.ConnectionId);

        await base.OnDisconnectedAsync(exception);
    }

    // Client can manually request refresh
    public async Task RequestDashboardRefresh()
    {
        var userId = Context.User?.FindFirst("uid")?.Value;
        var role = Context.User?.FindFirst("role")?.Value;

        // This would be handled by DashboardService
        await Clients.Caller.SendAsync("DashboardRefreshAcknowledged", new
        {
            UserId = userId,
            Role = role,
            Timestamp = DateTime.UtcNow
        });
    }
}
```

### 9.2 Push Updates to Dashboards

```csharp
// Event handler - push real-time updates via SignalR
public class RfqStatusChangedEventHandler : IEventHandler<RfqStatusChangedEvent>
{
    private readonly IHubContext<DashboardHub> _hubContext;
    private readonly IDashboardService _dashboardService;

    public async Task HandleAsync(RfqStatusChangedEvent evt, CancellationToken ct)
    {
        var rfq = await _dbContext.Rfqs
            .Include(r => r.Requester)
            .Include(r => r.ResponsiblePerson)
            .Include(r => r.CurrentActor)
            .FirstOrDefaultAsync(r => r.Id == evt.RfqId, ct);

        // ========================================
        // Update REQUESTER dashboard
        // ========================================
        var requesterUpdate = new
        {
            Type = "STATUS_COUNT_UPDATE",
            RfqId = rfq.Id,
            NewStatus = rfq.Status,
            Timestamp = DateTime.UtcNow,
            Counts = await _dashboardService.GetRequesterStatusCounts(rfq.RequesterId, ct)
        };

        await _hubContext.Clients
            .Group($"REQUESTER:{rfq.RequesterId}")
            .SendAsync("DashboardUpdate", requesterUpdate, ct);

        // ========================================
        // Update APPROVER dashboard (if applicable)
        // ========================================
        if (rfq.CurrentActorId.HasValue)
        {
            var approverUpdate = new
            {
                Type = "NEW_PENDING_RFQ",
                RfqId = rfq.Id,
                RfqNumber = rfq.RfqNumber,
                ProjectName = rfq.ProjectName,
                Timestamp = DateTime.UtcNow,
                Counts = await _dashboardService.GetApproverStatusCounts(rfq.CurrentActorId.Value, ct)
            };

            await _hubContext.Clients
                .Group($"APPROVER:{rfq.CurrentActorId}")
                .SendAsync("DashboardUpdate", approverUpdate, ct);
        }

        // ========================================
        // Update PURCHASING dashboard
        // ========================================
        if (rfq.ResponsiblePersonId.HasValue)
        {
            var purchasingUpdate = new
            {
                Type = "STATUS_COUNT_UPDATE",
                RfqId = rfq.Id,
                NewStatus = rfq.Status,
                Timestamp = DateTime.UtcNow,
                Counts = await _dashboardService.GetPurchasingStatusCounts(rfq.ResponsiblePersonId.Value, ct)
            };

            await _hubContext.Clients
                .Group($"PURCHASING:{rfq.ResponsiblePersonId}")
                .SendAsync("DashboardUpdate", purchasingUpdate, ct);
        }

        // ========================================
        // Update PURCHASING_APPROVER dashboard (if in that stage)
        // ========================================
        if (rfq.CurrentActorId.HasValue && evt.CurrentActorRole == "PURCHASING_APPROVER")
        {
            var paUpdate = new
            {
                Type = "NEW_PENDING_APPROVAL",
                RfqId = rfq.Id,
                Timestamp = DateTime.UtcNow,
                Counts = await _dashboardService.GetPurchasingApproverStatusCounts(rfq.CurrentActorId.Value, ct)
            };

            await _hubContext.Clients
                .Group($"PURCHASING_APPROVER:{rfq.CurrentActorId}")
                .SendAsync("DashboardUpdate", paUpdate, ct);
        }
    }
}
```

### 9.3 Client-Side Implementation (TypeScript)

```typescript
// Angular/React component for real-time dashboard
export class RequesterDashboardComponent implements OnInit, OnDestroy {
  private hubConnection: signalR.HubConnection;
  private refreshInterval: any;

  dashboardData: RequesterDashboardDto;

  ngOnInit() {
    // Initial load
    this.loadDashboard();

    // Setup SignalR connection
    this.hubConnection = new signalR.HubConnectionBuilder()
      .withUrl('/hubs/dashboard', {
        accessTokenFactory: () => this.authService.getAccessToken()
      })
      .withAutomaticReconnect({
        nextRetryDelayInMilliseconds: (retryContext) => {
          // Exponential backoff: 0s, 2s, 10s, 30s
          return Math.min(1000 * Math.pow(2, retryContext.previousRetryCount), 30000);
        }
      })
      .configureLogging(signalR.LogLevel.Information)
      .build();

    // Listen for dashboard updates
    this.hubConnection.on('DashboardUpdate', (data) => {
      this.handleDashboardUpdate(data);
    });

    // Handle reconnection
    this.hubConnection.onreconnected(() => {
      console.log('Dashboard reconnected, refreshing data...');
      this.loadDashboard();
    });

    // Start connection
    this.hubConnection.start()
      .then(() => console.log('Dashboard hub connected'))
      .catch(err => console.error('Dashboard hub connection error:', err));

    // Fallback: refresh every 60 seconds (in case SignalR fails)
    this.refreshInterval = setInterval(() => this.loadDashboard(), 60000);
  }

  ngOnDestroy() {
    this.hubConnection?.stop();
    clearInterval(this.refreshInterval);
  }

  private async loadDashboard() {
    try {
      const startDate = this.dateRangeFilter.startDate;
      const endDate = this.dateRangeFilter.endDate;

      this.dashboardData = await this.dashboardService.getRequesterDashboard(
        startDate,
        endDate
      );
    } catch (error) {
      console.error('Failed to load dashboard:', error);
    }
  }

  private handleDashboardUpdate(data: any) {
    switch (data.Type) {
      case 'STATUS_COUNT_UPDATE':
        // Update status counts without full reload
        this.dashboardData.StatusCounts = data.Counts;

        // Show toast notification
        this.toastr.info(
          `RFQ #${data.RfqId} status changed to ${data.NewStatus}`,
          'Dashboard Updated'
        );
        break;

      case 'NEW_NOTIFICATION':
        // Add notification to top of list
        this.dashboardData.Notifications.unshift(data.Notification);

        // Keep only 10 latest
        this.dashboardData.Notifications =
          this.dashboardData.Notifications.slice(0, 10);

        // Play notification sound
        this.audioService.playNotificationSound();
        break;

      default:
        // Unknown update type, do full refresh
        this.loadDashboard();
    }
  }
}
```

---

## SECTION 10: Complete Test Scenarios

### 10.1 Multi-Level Approval Chain Tests

#### Test Case 1: 3-Level APPROVER Chain
**Business Requirement**: Lines 6, 9, 12 of 00_1RFQ_WorkFlow.txt
**Objective**: Verify 3-level APPROVER chain works correctly

**Setup**:
```sql
-- Setup: Create 3 APPROVER levels for IT department
INSERT INTO "UserCompanyRoles"
  ("UserId", "CompanyId", "DepartmentId", "PrimaryRoleId", "ApproverLevel", "StartDate", "IsActive")
VALUES
  (101, 1, 5, 2, 1, CURRENT_DATE, TRUE),  -- Level 1: หัวหน้าแผนก IT (ประเสริฐ)
  (102, 1, 5, 2, 2, CURRENT_DATE, TRUE),  -- Level 2: ผู้จัดการฝ่าย (วิชัย)
  (103, 1, 5, 2, 3, CURRENT_DATE, TRUE);  -- Level 3: ผู้บริหารระดับสูง (สมศักดิ์)
```

**Test Steps**:
1. REQUESTER (userId=100) creates RFQ
2. System routes to APPROVER Level 1 (userId=101)
3. Level 1 approves
4. System routes to APPROVER Level 2 (userId=102)
5. Level 2 approves
6. System routes to APPROVER Level 3 (userId=103)
7. Level 3 approves
8. System routes to PURCHASING (userId=200)

**Verification SQL**:
```sql
-- Verify approval chain
SELECT
  sh."ApprovalLevel",
  u."FirstNameTh" || ' ' || u."LastNameTh" AS "ApproverName",
  sh."Decision",
  sh."ActionAt"
FROM "RfqStatusHistory" sh
JOIN "Users" u ON sh."ActorId" = u."Id"
WHERE sh."RfqId" = @TestRfqId
  AND sh."ActorRole" = 'APPROVER'
ORDER BY sh."ApprovalLevel";

-- Expected: 3 rows with Level 1, 2, 3 all APPROVED
```

**Expected Result**:
- ✅ RfqStatusHistory has 3 records (Level 1, 2, 3)
- ✅ All decisions = 'APPROVED'
- ✅ Final RFQ.CurrentActorId = PURCHASING user (userId=200)
- ✅ Final RFQ.Status = 'PENDING' (waiting for PURCHASING)

---

#### Test Case 2: Skip Optional APPROVER Levels
**Business Requirement**: Line 9 "ถ้ามี?" - Optional Level 2/3
**Objective**: System skips non-existent levels correctly

**Setup**:
```sql
-- Setup: Only Level 1 APPROVER exists
INSERT INTO "UserCompanyRoles"
  ("UserId", "CompanyId", "DepartmentId", "PrimaryRoleId", "ApproverLevel", "StartDate", "IsActive")
VALUES
  (101, 1, 5, 2, 1, CURRENT_DATE, TRUE);  -- Only Level 1
  -- NO Level 2 or 3
```

**Test Steps**:
1. REQUESTER creates RFQ
2. System routes to APPROVER Level 1
3. Level 1 approves
4. System detects no Level 2 exists
5. System routes directly to PURCHASING (skips Level 2 and 3)

**Verification SQL**:
```sql
-- Verify no Level 2/3 in history
SELECT COUNT(*)
FROM "RfqStatusHistory"
WHERE "RfqId" = @TestRfqId
  AND "ActorRole" = 'APPROVER'
  AND "ApprovalLevel" IN (2, 3);
-- Expected: 0

-- Verify next actor is PURCHASING
SELECT
  r."CurrentActorId",
  roles."RoleCode"
FROM "Rfqs" r
JOIN "Users" u ON r."CurrentActorId" = u."Id"
JOIN "UserCompanyRoles" ucr ON u."Id" = ucr."UserId"
JOIN "Roles" roles ON ucr."PrimaryRoleId" = roles."Id"
WHERE r."Id" = @TestRfqId;
-- Expected: RoleCode = 'PURCHASING'
```

**Expected Result**:
- ✅ RfqStatusHistory has only 1 APPROVER record (Level 1)
- ✅ Next actor is PURCHASING
- ✅ No errors or stuck workflow

---

### 10.2 Dashboard Real-Time Tests

#### Test Case 3: Status Count Real-Time Update
**Business Requirement**: Lines 4-6 of 06_Dashboard_RealTime.txt
**Objective**: Dashboard updates within 1 second of status change

**Test Steps**:
1. REQUESTER opens dashboard
2. Verify initial counts (e.g., Pending=5)
3. APPROVER approves one RFQ
4. Wait for SignalR update
5. Verify dashboard updates without page reload

**Verification** (Browser Console):
```javascript
// Client-side test
it('should receive real-time status count update', (done) => {
  const hubConnection = createDashboardHub();
  let initialPendingCount;

  // Get initial state
  dashboardService.getRequesterDashboard().then(data => {
    initialPendingCount = data.StatusCounts.Pending;
  });

  // Listen for update
  hubConnection.on('DashboardUpdate', (data) => {
    if (data.Type === 'STATUS_COUNT_UPDATE') {
      expect(data.Counts.Pending).toBe(initialPendingCount - 1);
      expect(Date.now() - data.Timestamp).toBeLessThan(1000); // < 1 second
      done();
    }
  });

  // Trigger approval on server
  approveRfq(testRfqId);
});
```

**Expected Result**:
- ✅ Update received via SignalR within 1 second
- ✅ Pending count decreased by 1
- ✅ No page reload required

---

#### Test Case 4: Relative Time Accuracy
**Business Requirement**: Line 6 "Just now | 4 hours ago"
**Objective**: Relative time displays correctly

**Test Data**:
```sql
-- Setup: Create RFQs with various update times
UPDATE "Rfqs" SET "UpdatedAt" = CURRENT_TIMESTAMP - INTERVAL '30 seconds' WHERE "Id" = 1;
UPDATE "Rfqs" SET "UpdatedAt" = CURRENT_TIMESTAMP - INTERVAL '2 hours' WHERE "Id" = 2;
UPDATE "Rfqs" SET "UpdatedAt" = CURRENT_TIMESTAMP - INTERVAL '2 days' WHERE "Id" = 3;
```

**Verification SQL**:
```sql
SELECT
  "Id",
  "UpdatedAt",
  CASE
    WHEN "UpdatedAt" >= CURRENT_TIMESTAMP - INTERVAL '1 minute' THEN 'Just now'
    WHEN "UpdatedAt" >= CURRENT_TIMESTAMP - INTERVAL '1 hour' THEN
      FLOOR(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - "UpdatedAt")) / 60)::TEXT || ' minutes ago'
    WHEN "UpdatedAt" >= CURRENT_TIMESTAMP - INTERVAL '1 day' THEN
      FLOOR(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - "UpdatedAt")) / 3600)::TEXT || ' hours ago'
    ELSE
      FLOOR(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - "UpdatedAt")) / 86400)::TEXT || ' days ago'
  END AS "RelativeTime"
FROM "Rfqs"
WHERE "Id" IN (1, 2, 3);
```

**Expected Result**:
- ✅ RFQ 1: "Just now"
- ✅ RFQ 2: "2 hours ago"
- ✅ RFQ 3: "2 days ago"

---

### 10.3 Performance Tests

#### Test Case 5: Dashboard Query Performance
**Objective**: All dashboard queries complete within 500ms

**Test Execution**:
```sql
EXPLAIN ANALYZE
SELECT ... -- (Status counts query from Section 3.2)
WHERE "RequesterId" = 123
  AND "CreatedDate" BETWEEN '2025-01-01' AND '2025-10-01';
```

**Expected Result**:
- ✅ Execution time < 500ms
- ✅ Uses indexes efficiently
- ✅ No sequential scans on large tables

**Required Indexes**:
```sql
-- Ensure these indexes exist
CREATE INDEX IF NOT EXISTS "idx_rfqs_requester_created"
  ON "Rfqs"("RequesterId", "CreatedDate");

CREATE INDEX IF NOT EXISTS "idx_rfqs_status_updated"
  ON "Rfqs"("Status", "UpdatedAt");

CREATE INDEX IF NOT EXISTS "idx_rfq_invitations_supplier_date"
  ON "RfqInvitations"("SupplierId", "InvitedAt");

CREATE INDEX IF NOT EXISTS "idx_quotation_items_submitted"
  ON "QuotationItems"("RfqId", "SubmittedAt");
```

---

## Summary

This detailed documentation provides **100% accurate mapping** between business requirements and database schema v6.2.2:

### Key Corrections:
1. ✅ **RfqApprovalHistory → RfqStatusHistory + RfqActorTimeline**
2. ✅ Complete multi-level approval chain implementation
3. ✅ All 5 dashboards with accurate SQL queries
4. ✅ Real-time SignalR integration
5. ✅ Caching strategy (30-second L1, 1-minute L2)
6. ✅ Complete test scenarios

### Coverage:
- **00_1RFQ_WorkFlow.txt**: 33/33 lines (100%) ✅
- **06_Dashboard_RealTime.txt**: 84/84 lines (100%) ✅
- **TOTAL**: 117/117 lines (100%) ✅

### Database Tables Used:
- Rfqs (Status, CurrentLevel, CurrentActorId)
- UserCompanyRoles (ApproverLevel 1-3)
- RfqStatusHistory (ActorRole, ApprovalLevel, Decision)
- RfqActorTimeline (ReceivedAt, ActionAt, IsOntime)
- RfqInvitations (Decision: PENDING/PARTICIPATING/NOT_PARTICIPATING)
- QuotationItems (SubmittedAt)
- Suppliers (Status, RegisteredAt)
- QnAThreads + QnAMessages (Q&A communication)
- Notifications (IconType 22 types, SignalR integration)

---

**End of Detailed Documentation**
