# SignIn and Admin Complete Cross-Reference
# Database Schema v6.2.2 Analysis

**Document Version**: 3.0
**Created**: 2025-09-30
**Database Schema**: erfq-db-schema-v62.sql
**Business Documentation**: 00_SignIn_and_Admin.txt (94 lines)

---

## Document Purpose

This document provides **100% line-by-line mapping** between business requirements in `00_SignIn_and_Admin.txt` and the database schema `erfq-db-schema-v62.sql`. Every single line is analyzed and mapped to corresponding database fields, complete with SQL queries, validation rules, and implementation details.

---

## Version History

| Version | Date | Changes | Lines Covered |
|---------|------|---------|---------------|
| 1.0 | Initial | First draft | Partial |
| 2.0 | Revision | Added more details | 80% |
| 3.0 | 2025-09-30 | **Complete line-by-line mapping** | **100% (94/94 lines)** |

---

## Table of Contents

1. [Line-by-Line Mapping Summary](#section-1-line-by-line-mapping-summary)
2. [Authentication System (Sign In)](#section-2-authentication-system-sign-in)
3. [Password Reset Flow](#section-3-password-reset-flow)
4. [Admin: User Management](#section-4-admin-user-management)
5. [Admin: Exchange Rate Management](#section-5-admin-exchange-rate-management)
6. [Admin: Category & Supplier Management](#section-6-admin-category--supplier-management)
7. [Database Schema Overview](#section-7-database-schema-overview)
8. [SQL Query Templates](#section-8-sql-query-templates)
9. [Security & Validation Rules](#section-9-security--validation-rules)
10. [Test Scenarios](#section-10-test-scenarios)

---

## SECTION 1: Line-by-Line Mapping Summary

### Complete Coverage: 94/94 Lines (100%)

#### Authentication & Password Reset (Lines 1-14)
| Lines | Topic | Schema Tables | Status |
|-------|-------|---------------|--------|
| 1-7 | Sign In Screen | Users, SupplierContacts, LoginHistory, RefreshTokens | ✅ Mapped |
| 8-10 | Forgot Password | Users.PasswordResetToken, Users.PasswordResetExpiry | ✅ Mapped |
| 11-14 | Reset Password Form | Users.PasswordHash, Users.SecurityStamp | ✅ Mapped |

#### Admin Workflow (Lines 16-94)
| Lines | Topic | Schema Tables | Status |
|-------|-------|---------------|--------|
| 17-22 | User Management + Exchange Rate | Users, UserCompanyRoles, ExchangeRates | ✅ Mapped |
| 23-75 | Add/Edit User Form | Users, UserCompanyRoles, Roles, RolePermissions | ✅ Mapped |
| 77-80 | Category & Supplier Management | Suppliers, SupplierCategories, Categories | ✅ Mapped |
| 81-94 | Edit Category Form | SupplierCategories, Categories, Subcategories | ✅ Mapped |

---

## SECTION 2: Authentication System (Sign In)

### Business Documentation Mapping (Lines 1-7)

```
Line 1: ### หน้าจอ Sign In
Line 2: เข้าสู่ระบบ
Line 3: Dropdown list สามารถเลือก ภาษาได้ ไทย/อังกฤษ
Line 4: input txt
Line 5: input txt รหัสผ่าน
Line 6: ลืมรหัสผ่าน? ฟังก์ชัน: นำทางไปยังหน้าจอ "ลืมรหัสผ่าน"
Line 7: ปุ่ม เข้าสู่ระบบ ฟังก์ชัน: จะพาผู้ใช้ไป แดชบอร์ด ตาม Role หลัก
```

### Database Schema Mapping

#### 2.1 User Authentication Tables

**Users Table** (Lines 342-375)
```sql
CREATE TABLE "Users" (
  "Id" BIGSERIAL PRIMARY KEY,
  "Email" VARCHAR(100) UNIQUE NOT NULL,              -- Line 4: input txt email
  "PasswordHash" VARCHAR(255) NOT NULL,              -- Line 5: input txt รหัสผ่าน
  "PreferredLanguage" VARCHAR(5) DEFAULT 'th',       -- Line 3: Dropdown ภาษา
  "SecurityStamp" VARCHAR(100),                      -- Password validation
  "LastLoginAt" TIMESTAMP,                           -- Line 7: Track last login
  "LockoutEnabled" BOOLEAN DEFAULT TRUE,             -- Security: Account lockout
  "LockoutEnd" TIMESTAMP WITH TIME ZONE,             -- Security: Lockout expiry
  "AccessFailedCount" INT DEFAULT 0,                 -- Security: Failed attempts
  "Status" VARCHAR(20) DEFAULT 'ACTIVE',
  "IsActive" BOOLEAN DEFAULT TRUE,
  ...
  CONSTRAINT "chk_preferred_language" CHECK ("PreferredLanguage" IN ('th','en'))
);
```

**SupplierContacts Table** (Lines 498-530)
```sql
CREATE TABLE "SupplierContacts" (
  "Id" BIGSERIAL PRIMARY KEY,
  "SupplierId" BIGINT NOT NULL REFERENCES "Suppliers"("Id"),
  "Email" VARCHAR(100) NOT NULL,                     -- Line 4: Supplier email
  "PasswordHash" VARCHAR(255),                       -- Line 5: Supplier password
  "PreferredLanguage" VARCHAR(5) DEFAULT 'th',       -- Line 3: Language selection
  "SecurityStamp" VARCHAR(100),
  "LastLoginAt" TIMESTAMP,                           -- Line 7: Track login
  "FailedLoginAttempts" INT DEFAULT 0,               -- Security
  "LockoutEnd" TIMESTAMP WITH TIME ZONE,             -- Security
  ...
  UNIQUE("SupplierId", "Email"),
  CONSTRAINT "chk_contact_language" CHECK ("PreferredLanguage" IN ('th','en'))
);
```

**LoginHistory Table** (Lines 1068-1088)
```sql
CREATE TABLE "LoginHistory" (
  "Id" BIGSERIAL PRIMARY KEY,
  "UserType" VARCHAR(20) NOT NULL,                   -- 'Employee' or 'SupplierContact'
  "UserId" BIGINT,                                   -- FK to Users
  "ContactId" BIGINT,                                -- FK to SupplierContacts
  "Email" VARCHAR(100),
  "LoginAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,     -- Line 7: Login timestamp
  "LoginIp" VARCHAR(45),                             -- Security: IP tracking
  "UserAgent" TEXT,                                  -- Security: Browser info
  "DeviceInfo" TEXT,                                 -- Security: Device info
  "Country" VARCHAR(100),                            -- GeoIP
  "City" VARCHAR(100),                               -- GeoIP
  "Success" BOOLEAN NOT NULL,                        -- Login result
  "FailureReason" VARCHAR(200),                      -- Failed login reason
  "SessionId" VARCHAR(100),
  "RefreshTokenId" BIGINT REFERENCES "RefreshTokens"("Id"),
  "LogoutAt" TIMESTAMP,
  "LogoutType" VARCHAR(20),

  CONSTRAINT "chk_login_user_type" CHECK ("UserType" IN ('Employee', 'SupplierContact'))
);
```

**RefreshTokens Table** (Lines 1044-1063)
```sql
CREATE TABLE "RefreshTokens" (
  "Id" BIGSERIAL PRIMARY KEY,
  "Token" VARCHAR(500) UNIQUE NOT NULL,              -- JWT Refresh Token
  "UserType" VARCHAR(20) NOT NULL,                   -- 'Employee' or 'SupplierContact'
  "UserId" BIGINT,                                   -- FK to Users
  "ContactId" BIGINT,                                -- FK to SupplierContacts
  "ExpiresAt" TIMESTAMP NOT NULL,                    -- Token expiry
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "CreatedByIp" VARCHAR(45),
  "RevokedAt" TIMESTAMP,                             -- Token revocation
  "RevokedByIp" VARCHAR(45),
  "ReplacedByToken" VARCHAR(500),                    -- Token rotation
  "ReasonRevoked" VARCHAR(100),

  CONSTRAINT "chk_refresh_user_type" CHECK ("UserType" IN ('Employee', 'SupplierContact')),
  CONSTRAINT "chk_refresh_user_ref" CHECK (
    ("UserType" = 'Employee' AND "UserId" IS NOT NULL AND "ContactId" IS NULL) OR
    ("UserType" = 'SupplierContact' AND "ContactId" IS NOT NULL AND "UserId" IS NULL)
  )
);
```

#### 2.2 UserCompanyRoles (For Dashboard Routing)

**Line 7 Business Rule**: "จะพาผู้ใช้ไป แดชบอร์ด ตาม Role หลัก"

```sql
CREATE TABLE "UserCompanyRoles" (
  "Id" BIGSERIAL PRIMARY KEY,
  "UserId" BIGINT NOT NULL REFERENCES "Users"("Id"),
  "CompanyId" BIGINT NOT NULL REFERENCES "Companies"("Id"),
  "DepartmentId" BIGINT REFERENCES "Departments"("Id"),
  "PrimaryRoleId" BIGINT NOT NULL REFERENCES "Roles"("Id"),  -- Line 7: Role หลัก
  "SecondaryRoleId" BIGINT REFERENCES "Roles"("Id"),
  "ApproverLevel" SMALLINT CHECK ("ApproverLevel" BETWEEN 1 AND 3),
  "IsActive" BOOLEAN DEFAULT TRUE,
  ...
);
```

**Roles Table** (Lines 82-95)
```sql
CREATE TABLE "Roles" (
  "Id" BIGSERIAL PRIMARY KEY,
  "RoleCode" VARCHAR(30) UNIQUE NOT NULL,
  "RoleNameTh" VARCHAR(100) NOT NULL,
  "RoleNameEn" VARCHAR(100),

  CONSTRAINT "chk_role_code" CHECK ("RoleCode" IN
    ('SUPER_ADMIN','ADMIN','REQUESTER','APPROVER','PURCHASING',
     'PURCHASING_APPROVER','SUPPLIER','MANAGING_DIRECTOR'))
);
```

### 2.3 Authentication Flow

#### Step 1: Login Request (Line 7)
```sql
-- 1. Validate user exists
SELECT
  u."Id",
  u."Email",
  u."PasswordHash",
  u."SecurityStamp",
  u."PreferredLanguage",                    -- Line 3: Selected language
  u."Status",
  u."IsActive",
  u."LockoutEnabled",
  u."LockoutEnd",
  u."AccessFailedCount"
FROM "Users" u
WHERE u."Email" = @Email
  AND u."IsActive" = TRUE
  AND u."Status" = 'ACTIVE';

-- 2. Check if account is locked
SELECT
  CASE
    WHEN "LockoutEnabled" = TRUE
     AND "LockoutEnd" IS NOT NULL
     AND "LockoutEnd" > CURRENT_TIMESTAMP
    THEN TRUE
    ELSE FALSE
  END AS "IsLockedOut"
FROM "Users"
WHERE "Email" = @Email;

-- 3. Verify password hash (BCrypt in application code)
-- BCrypt.Verify(@Password, user.PasswordHash)

-- 4. If password invalid, increment failed attempts
UPDATE "Users"
SET
  "AccessFailedCount" = "AccessFailedCount" + 1,
  "LockoutEnd" = CASE
    WHEN "AccessFailedCount" + 1 >= 5
    THEN CURRENT_TIMESTAMP + INTERVAL '30 minutes'
    ELSE "LockoutEnd"
  END,
  "UpdatedAt" = CURRENT_TIMESTAMP
WHERE "Email" = @Email;

-- 5. If password valid, reset failed attempts
UPDATE "Users"
SET
  "AccessFailedCount" = 0,
  "LockoutEnd" = NULL,
  "LastLoginAt" = CURRENT_TIMESTAMP,          -- Line 7: Track login
  "UpdatedAt" = CURRENT_TIMESTAMP
WHERE "Id" = @UserId;
```

#### Step 2: Get User Roles & Permissions (Line 7: Dashboard Routing)
```sql
-- Get user's primary role for dashboard routing
WITH user_roles AS (
  SELECT
    ucr."UserId",
    ucr."CompanyId",
    ucr."PrimaryRoleId",
    r."RoleCode" AS "PrimaryRoleCode",          -- Line 7: Role หลัก
    r."RoleNameTh",
    ucr."DepartmentId",
    ucr."ApproverLevel"
  FROM "UserCompanyRoles" ucr
  JOIN "Roles" r ON ucr."PrimaryRoleId" = r."Id"
  WHERE ucr."UserId" = @UserId
    AND ucr."IsActive" = TRUE
    AND (ucr."StartDate" <= CURRENT_DATE)
    AND (ucr."EndDate" IS NULL OR ucr."EndDate" >= CURRENT_DATE)
)
SELECT * FROM user_roles;

-- Get all permissions for the role
SELECT
  p."PermissionCode",
  p."PermissionName",
  p."Module"
FROM "RolePermissions" rp
JOIN "Permissions" p ON rp."PermissionId" = p."Id"
WHERE rp."RoleId" = @PrimaryRoleId
  AND rp."IsActive" = TRUE
  AND p."IsActive" = TRUE;

-- Get category bindings (for PURCHASING/PURCHASING_APPROVER)
SELECT
  ucb."CategoryId",
  c."CategoryNameTh",
  ucb."SubcategoryId",
  s."SubcategoryNameTh"
FROM "UserCategoryBindings" ucb
JOIN "Categories" c ON ucb."CategoryId" = c."Id"
LEFT JOIN "Subcategories" s ON ucb."SubcategoryId" = s."Id"
WHERE ucb."UserCompanyRoleId" IN (
  SELECT "Id" FROM "UserCompanyRoles"
  WHERE "UserId" = @UserId AND "IsActive" = TRUE
)
AND ucb."IsActive" = TRUE;
```

#### Step 3: Generate JWT Token (Line 7)
```csharp
// JWT Claims Structure
var claims = new[]
{
    new Claim("uid", user.Id.ToString()),
    new Claim("email", user.Email),
    new Claim("name", $"{user.FirstNameTh} {user.LastNameTh}"),
    new Claim("role", primaryRole.RoleCode),              // Line 7: Primary role
    new Claim("cid", selectedCompanyId.ToString()),
    new Claim("companies", string.Join(",", companyIds)),
    new Claim("categories", string.Join(",", categoryIds)), // PURCHASING only
    new Claim("level", approverLevel?.ToString() ?? ""),    // APPROVER only
    new Claim("dept", departmentId?.ToString() ?? ""),
    new Claim("lang", user.PreferredLanguage),            // Line 3: Language
    new Claim("aud", "internal"),                          // Audience
    new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
};

// Access Token (15 minutes expiry)
var accessToken = new JwtSecurityToken(
    issuer: _config["Jwt:Issuer"],
    audience: _config["Jwt:Audience"],
    claims: claims,
    expires: DateTime.UtcNow.AddMinutes(15),
    signingCredentials: signingCredentials
);

// Refresh Token (7 days expiry)
var refreshToken = GenerateRefreshToken();
```

#### Step 4: Create Refresh Token Record
```sql
INSERT INTO "RefreshTokens" (
  "Token",
  "UserType",
  "UserId",
  "ExpiresAt",
  "CreatedByIp"
) VALUES (
  @RefreshToken,
  'Employee',
  @UserId,
  CURRENT_TIMESTAMP + INTERVAL '7 days',
  @ClientIpAddress
)
RETURNING "Id";
```

#### Step 5: Record Login History
```sql
INSERT INTO "LoginHistory" (
  "UserType",
  "UserId",
  "Email",
  "LoginAt",                                 -- Line 7: Login timestamp
  "LoginIp",
  "UserAgent",
  "DeviceInfo",
  "Country",
  "City",
  "Success",
  "SessionId",
  "RefreshTokenId"
) VALUES (
  'Employee',
  @UserId,
  @Email,
  CURRENT_TIMESTAMP,
  @ClientIp,
  @UserAgent,
  @DeviceInfo,
  @Country,
  @City,
  TRUE,
  @SessionId,
  @RefreshTokenId
);
```

#### Step 6: Dashboard Routing Logic (Line 7)
```csharp
// Line 7: "จะพาผู้ใช้ไป แดชบอร์ด ตาม Role หลัก"
public string GetDashboardUrl(string primaryRoleCode)
{
    return primaryRoleCode switch
    {
        "REQUESTER" => "/requester/dashboard",
        "APPROVER" => "/approver/dashboard",
        "PURCHASING" => "/purchasing/dashboard",
        "PURCHASING_APPROVER" => "/purchasing-approver/dashboard",
        "MANAGING_DIRECTOR" => "/md/dashboard",
        "ADMIN" => "/admin/dashboard",
        "SUPER_ADMIN" => "/super-admin/dashboard",
        _ => "/home"
    };
}
```

### 2.4 Supplier Contact Authentication

#### Supplier Login Query
```sql
-- 1. Validate supplier contact
SELECT
  sc."Id",
  sc."SupplierId",
  sc."Email",
  sc."PasswordHash",
  sc."SecurityStamp",
  sc."PreferredLanguage",                   -- Line 3: Language
  sc."IsActive",
  sc."FailedLoginAttempts",
  sc."LockoutEnd",
  s."Status" AS "SupplierStatus",
  s."CompanyNameTh"
FROM "SupplierContacts" sc
JOIN "Suppliers" s ON sc."SupplierId" = s."Id"
WHERE sc."Email" = @Email
  AND sc."IsActive" = TRUE
  AND s."Status" = 'COMPLETED'              -- Supplier must be approved
  AND s."IsActive" = TRUE;

-- 2. Update last login
UPDATE "SupplierContacts"
SET
  "FailedLoginAttempts" = 0,
  "LockoutEnd" = NULL,
  "LastLoginAt" = CURRENT_TIMESTAMP,
  "UpdatedAt" = CURRENT_TIMESTAMP
WHERE "Id" = @ContactId;

-- 3. Record login history
INSERT INTO "LoginHistory" (
  "UserType",
  "ContactId",
  "Email",
  "LoginAt",
  "LoginIp",
  "UserAgent",
  "Success"
) VALUES (
  'SupplierContact',
  @ContactId,
  @Email,
  CURRENT_TIMESTAMP,
  @ClientIp,
  @UserAgent,
  TRUE
);
```

#### Supplier JWT Claims
```csharp
var claims = new[]
{
    new Claim("cid", supplierContact.Id.ToString()),
    new Claim("sid", supplierContact.SupplierId.ToString()),
    new Claim("email", supplierContact.Email),
    new Claim("name", $"{supplierContact.FirstName} {supplierContact.LastName}"),
    new Claim("role", "SUPPLIER"),
    new Claim("lang", supplierContact.PreferredLanguage),  // Line 3
    new Claim("aud", "supplier"),                           // Audience: supplier
    new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
};
```

### 2.5 Security Features

#### Account Lockout (After 5 Failed Attempts)
```sql
-- Check lockout status
SELECT
  "Email",
  "AccessFailedCount",
  "LockoutEnd",
  CASE
    WHEN "LockoutEnd" IS NOT NULL AND "LockoutEnd" > CURRENT_TIMESTAMP
    THEN EXTRACT(EPOCH FROM ("LockoutEnd" - CURRENT_TIMESTAMP))/60
    ELSE 0
  END AS "MinutesRemaining"
FROM "Users"
WHERE "Email" = @Email;

-- Unlock account manually (ADMIN only)
UPDATE "Users"
SET
  "AccessFailedCount" = 0,
  "LockoutEnd" = NULL,
  "UpdatedAt" = CURRENT_TIMESTAMP,
  "UpdatedBy" = @AdminUserId
WHERE "Email" = @Email;
```

#### Session Management
```sql
-- Get active sessions
SELECT
  lh."Id",
  lh."LoginAt",
  lh."LoginIp",
  lh."DeviceInfo",
  lh."LogoutAt",
  rt."ExpiresAt" AS "TokenExpiresAt"
FROM "LoginHistory" lh
LEFT JOIN "RefreshTokens" rt ON lh."RefreshTokenId" = rt."Id"
WHERE lh."UserId" = @UserId
  AND lh."Success" = TRUE
  AND lh."LogoutAt" IS NULL
ORDER BY lh."LoginAt" DESC;

-- Logout (Revoke refresh token)
UPDATE "RefreshTokens"
SET
  "RevokedAt" = CURRENT_TIMESTAMP,
  "RevokedByIp" = @ClientIp,
  "ReasonRevoked" = 'User Logout'
WHERE "Id" = @RefreshTokenId;

-- Update login history
UPDATE "LoginHistory"
SET
  "LogoutAt" = CURRENT_TIMESTAMP,
  "LogoutType" = 'Manual'
WHERE "SessionId" = @SessionId;
```

---

## SECTION 3: Password Reset Flow

### Business Documentation Mapping (Lines 8-14)

```
Line 8:  ### หน้าจอ ลืมรหัสผ่าน
Line 9:  input txt อีเมล์
Line 10: ปุ่ม รีเซ็ตรหัสผ่าน ฟังก์ชัน: รีเซ็ตรหัสผ่านด้วยอีเมลที่ใช้งาน
Line 11: ### หน้าจอ กรอกรหัสผ่านใหม่
Line 12: input txt รหัสผ่าน
Line 13: input txt ยืนยันรหัสผ่าน
Line 14: ปุ่ม บันทึกรหัสผ่านใหม่
```

### Database Schema Mapping

**Users Table (Password Reset Fields)**
```sql
CREATE TABLE "Users" (
  ...
  "PasswordHash" VARCHAR(255) NOT NULL,         -- Line 12, 13: New password
  "PasswordResetToken" VARCHAR(255),            -- Line 10: Reset token
  "PasswordResetExpiry" TIMESTAMP,              -- Line 10: Token expiry
  "SecurityStamp" VARCHAR(100),                 -- Invalidate old tokens
  ...
);
```

**SupplierContacts Table (Password Reset Fields)**
```sql
CREATE TABLE "SupplierContacts" (
  ...
  "PasswordHash" VARCHAR(255),                  -- Line 12, 13: New password
  "PasswordResetToken" VARCHAR(255),            -- Line 10: Reset token
  "PasswordResetExpiry" TIMESTAMP,              -- Line 10: Token expiry
  "SecurityStamp" VARCHAR(100),                 -- Invalidate old tokens
  ...
);
```

### 3.1 Step 1: Request Password Reset (Lines 9-10)

#### Validate Email
```sql
-- For internal users
SELECT
  "Id",
  "Email",
  "FirstNameTh",
  "LastNameTh",
  "PreferredLanguage",
  "IsActive",
  "Status"
FROM "Users"
WHERE "Email" = @Email                          -- Line 9: input txt อีเมล์
  AND "IsActive" = TRUE
  AND "Status" = 'ACTIVE';

-- For supplier contacts
SELECT
  sc."Id",
  sc."Email",
  sc."FirstName",
  sc."LastName",
  sc."PreferredLanguage",
  sc."IsActive",
  s."Status" AS "SupplierStatus"
FROM "SupplierContacts" sc
JOIN "Suppliers" s ON sc."SupplierId" = s."Id"
WHERE sc."Email" = @Email                       -- Line 9
  AND sc."IsActive" = TRUE
  AND s."Status" = 'COMPLETED';
```

#### Generate Reset Token & Save
```sql
-- Line 10: "รีเซ็ตรหัสผ่านด้วยอีเมลที่ใช้งาน"
-- Generate secure token (in application code)
-- Token = Convert.ToBase64String(RandomNumberGenerator.GetBytes(32))

-- Save token to database (Internal Users)
UPDATE "Users"
SET
  "PasswordResetToken" = @Token,
  "PasswordResetExpiry" = CURRENT_TIMESTAMP + INTERVAL '1 hour',  -- 1 hour expiry
  "SecurityStamp" = @NewSecurityStamp,
  "UpdatedAt" = CURRENT_TIMESTAMP
WHERE "Email" = @Email;

-- Save token to database (Supplier Contacts)
UPDATE "SupplierContacts"
SET
  "PasswordResetToken" = @Token,
  "PasswordResetExpiry" = CURRENT_TIMESTAMP + INTERVAL '1 hour',
  "SecurityStamp" = @NewSecurityStamp,
  "UpdatedAt" = CURRENT_TIMESTAMP
WHERE "Email" = @Email;
```

#### Send Reset Email (Line 10)
```csharp
// Email content (See: 0.1.1 Forgot Password Thank you.png)
var resetUrl = $"{_config["AppUrl"]}/reset-password?token={token}&email={email}";

var emailContent = new
{
    To = email,
    Subject = language == "th"
        ? "รีเซ็ตรหัสผ่าน - eRFX System"
        : "Reset Password - eRFX System",
    Body = language == "th"
        ? $@"
            <h2>คำขอรีเซ็ตรหัสผ่าน</h2>
            <p>คุณได้ร้องขอการรีเซ็ตรหัสผ่าน</p>
            <p>กรุณาคลิกลิงก์ด้านล่างเพื่อรีเซ็ตรหัสผ่าน:</p>
            <a href='{resetUrl}'>รีเซ็ตรหัสผ่าน</a>
            <p>ลิงก์นี้จะหมดอายุใน 1 ชั่วโมง</p>
          "
        : $@"
            <h2>Password Reset Request</h2>
            <p>You requested a password reset</p>
            <p>Please click the link below to reset your password:</p>
            <a href='{resetUrl}'>Reset Password</a>
            <p>This link will expire in 1 hour</p>
          "
};

// Send via SendGrid
await _emailService.SendAsync(emailContent);
```

### 3.2 Step 2: Validate Reset Token (Line 11)

```sql
-- Validate token (Internal Users)
SELECT
  "Id",
  "Email",
  "PasswordResetToken",
  "PasswordResetExpiry",
  "SecurityStamp",
  CASE
    WHEN "PasswordResetExpiry" > CURRENT_TIMESTAMP THEN TRUE
    ELSE FALSE
  END AS "IsTokenValid"
FROM "Users"
WHERE "Email" = @Email
  AND "PasswordResetToken" = @Token
  AND "PasswordResetExpiry" > CURRENT_TIMESTAMP
  AND "IsActive" = TRUE;

-- Validate token (Supplier Contacts)
SELECT
  sc."Id",
  sc."Email",
  sc."PasswordResetToken",
  sc."PasswordResetExpiry",
  sc."SecurityStamp",
  CASE
    WHEN sc."PasswordResetExpiry" > CURRENT_TIMESTAMP THEN TRUE
    ELSE FALSE
  END AS "IsTokenValid"
FROM "SupplierContacts" sc
JOIN "Suppliers" s ON sc."SupplierId" = s."Id"
WHERE sc."Email" = @Email
  AND sc."PasswordResetToken" = @Token
  AND sc."PasswordResetExpiry" > CURRENT_TIMESTAMP
  AND sc."IsActive" = TRUE
  AND s."Status" = 'COMPLETED';
```

### 3.3 Step 3: Set New Password (Lines 12-14)

#### Password Validation Rules
```csharp
// Line 12, 13: Validation
public class PasswordValidationRules
{
    public const int MinLength = 8;
    public const int MaxLength = 50;
    public static bool RequireDigit = true;
    public static bool RequireLowercase = true;
    public static bool RequireUppercase = true;
    public static bool RequireNonAlphanumeric = true;

    public static bool Validate(string password, string confirmPassword)
    {
        if (password != confirmPassword)                      // Line 13
            return false;

        if (password.Length < MinLength || password.Length > MaxLength)
            return false;

        if (RequireDigit && !password.Any(char.IsDigit))
            return false;

        if (RequireLowercase && !password.Any(char.IsLower))
            return false;

        if (RequireUppercase && !password.Any(char.IsUpper))
            return false;

        if (RequireNonAlphanumeric && !password.Any(ch => !char.IsLetterOrDigit(ch)))
            return false;

        return true;
    }
}
```

#### Update Password (Line 14)
```sql
-- Line 14: "บันทึกรหัสผ่านใหม่"
-- Hash password (BCrypt in application code)
-- PasswordHash = BCrypt.HashPassword(@NewPassword, workFactor: 12)

-- Update password (Internal Users)
UPDATE "Users"
SET
  "PasswordHash" = @NewPasswordHash,           -- Line 12, 13
  "PasswordResetToken" = NULL,                 -- Clear token
  "PasswordResetExpiry" = NULL,                -- Clear expiry
  "SecurityStamp" = @NewSecurityStamp,         -- Generate new stamp
  "AccessFailedCount" = 0,                     -- Reset failed attempts
  "LockoutEnd" = NULL,                         -- Clear lockout
  "UpdatedAt" = CURRENT_TIMESTAMP
WHERE "Email" = @Email
  AND "PasswordResetToken" = @Token
  AND "PasswordResetExpiry" > CURRENT_TIMESTAMP;

-- Update password (Supplier Contacts)
UPDATE "SupplierContacts"
SET
  "PasswordHash" = @NewPasswordHash,
  "PasswordResetToken" = NULL,
  "PasswordResetExpiry" = NULL,
  "SecurityStamp" = @NewSecurityStamp,
  "FailedLoginAttempts" = 0,
  "LockoutEnd" = NULL,
  "UpdatedAt" = CURRENT_TIMESTAMP
WHERE "Email" = @Email
  AND "PasswordResetToken" = @Token
  AND "PasswordResetExpiry" > CURRENT_TIMESTAMP;
```

#### Revoke All Existing Tokens (Security)
```sql
-- Revoke all refresh tokens for user (force re-login)
UPDATE "RefreshTokens"
SET
  "RevokedAt" = CURRENT_TIMESTAMP,
  "ReasonRevoked" = 'Password Reset'
WHERE "UserType" = 'Employee'
  AND "UserId" = @UserId
  AND "RevokedAt" IS NULL;

-- For supplier contacts
UPDATE "RefreshTokens"
SET
  "RevokedAt" = CURRENT_TIMESTAMP,
  "ReasonRevoked" = 'Password Reset'
WHERE "UserType" = 'SupplierContact'
  AND "ContactId" = @ContactId
  AND "RevokedAt" IS NULL;
```

#### Send Confirmation Email
```csharp
// Email content (See: 0.2.1 Reset Password Thank.png)
var emailContent = new
{
    To = email,
    Subject = language == "th"
        ? "รีเซ็ตรหัสผ่านสำเร็จ - eRFX System"
        : "Password Reset Successful - eRFX System",
    Body = language == "th"
        ? @"
            <h2>รีเซ็ตรหัสผ่านสำเร็จ</h2>
            <p>รหัสผ่านของคุณถูกเปลี่ยนเรียบร้อยแล้ว</p>
            <p>หากคุณไม่ได้ทำการเปลี่ยนแปลงนี้ กรุณาติดต่อผู้ดูแลระบบทันที</p>
          "
        : @"
            <h2>Password Reset Successful</h2>
            <p>Your password has been successfully changed</p>
            <p>If you did not make this change, please contact system administrator immediately</p>
          "
};

await _emailService.SendAsync(emailContent);
```

### 3.4 Security Best Practices

#### Token Expiry Management
```sql
-- Clean up expired tokens (Scheduled job - daily)
UPDATE "Users"
SET
  "PasswordResetToken" = NULL,
  "PasswordResetExpiry" = NULL
WHERE "PasswordResetExpiry" < CURRENT_TIMESTAMP
  AND "PasswordResetToken" IS NOT NULL;

UPDATE "SupplierContacts"
SET
  "PasswordResetToken" = NULL,
  "PasswordResetExpiry" = NULL
WHERE "PasswordResetExpiry" < CURRENT_TIMESTAMP
  AND "PasswordResetToken" IS NOT NULL;
```

#### Rate Limiting (Prevent Abuse)
```csharp
// In-memory rate limiting (Redis recommended for production)
public class PasswordResetRateLimiter
{
    private static Dictionary<string, (int Count, DateTime ResetTime)> _attempts = new();

    public static bool CanRequestReset(string email)
    {
        if (!_attempts.ContainsKey(email))
        {
            _attempts[email] = (1, DateTime.UtcNow.AddHours(1));
            return true;
        }

        var (count, resetTime) = _attempts[email];

        if (DateTime.UtcNow > resetTime)
        {
            _attempts[email] = (1, DateTime.UtcNow.AddHours(1));
            return true;
        }

        if (count >= 3)  // Max 3 requests per hour
            return false;

        _attempts[email] = (count + 1, resetTime);
        return true;
    }
}
```

---

## SECTION 4: Admin: User Management

### Business Documentation Mapping (Lines 17-75)

```
Line 17: ### หน้าจอ User Management + Update Exchange Rate
Line 20: ตารางรายชื่อผู้ใช้ ช่องค้นหา (Search Box)
Line 21: ตารางแสดงข้อมูล รหัสพนักงาน | ชื่อ | นามสกุล | อีเมล | บริษัท | บทบาท | สิทธิ์การเข้าถึง | แก้ไข/ลบ
Line 22: ปุ่ม เพิ่มผู้ใช้ใหม่/แก้ไขข้อมูล ฟังก์ชัน: Pop Up Add New User
Lines 23-75: Add New User/Edit User Form
```

### 4.1 User List Query (Lines 20-21)

```sql
-- Line 20: "ช่องค้นหา (Search Box): ค้นหาข้อความอิสระในหลายฟิลด์
-- (รหัสพนักงาน, ชื่อ-นามสกุล, อีเมล หรือ บริษัท)"
-- Line 21: Display columns

WITH user_info AS (
  SELECT
    u."Id",
    u."EmployeeCode",                          -- Line 21: รหัสพนักงาน
    u."FirstNameTh",                           -- Line 21: ชื่อ
    u."LastNameTh",                            -- Line 21: นามสกุล
    u."Email",                                 -- Line 21: อีเมล
    u."PreferredLanguage",
    u."IsActive",
    u."Status",
    u."CreatedAt",

    -- Company info
    STRING_AGG(DISTINCT c."ShortNameEn", ', '
      ORDER BY c."ShortNameEn") AS "Companies",  -- Line 21: บริษัท

    -- Primary role
    STRING_AGG(DISTINCT r."RoleNameTh", ', '
      ORDER BY r."RoleNameTh") AS "Roles",       -- Line 21: บทบาท

    -- Permissions count
    COUNT(DISTINCT rp."PermissionId") AS "PermissionCount"  -- Line 21: สิทธิ์การเข้าถึง

  FROM "Users" u
  LEFT JOIN "UserCompanyRoles" ucr ON u."Id" = ucr."UserId" AND ucr."IsActive" = TRUE
  LEFT JOIN "Companies" c ON ucr."CompanyId" = c."Id"
  LEFT JOIN "Roles" r ON ucr."PrimaryRoleId" = r."Id"
  LEFT JOIN "RolePermissions" rp ON r."Id" = rp."RoleId" AND rp."IsActive" = TRUE
  WHERE u."IsDeleted" = FALSE
  GROUP BY u."Id", u."EmployeeCode", u."FirstNameTh", u."LastNameTh",
           u."Email", u."PreferredLanguage", u."IsActive", u."Status", u."CreatedAt"
)
SELECT * FROM user_info
WHERE
  -- Line 20: Search filter
  (
    @SearchTerm IS NULL OR
    "EmployeeCode" ILIKE '%' || @SearchTerm || '%' OR
    "FirstNameTh" ILIKE '%' || @SearchTerm || '%' OR
    "LastNameTh" ILIKE '%' || @SearchTerm || '%' OR
    "Email" ILIKE '%' || @SearchTerm || '%' OR
    "Companies" ILIKE '%' || @SearchTerm || '%'
  )
ORDER BY "CreatedAt" DESC;
```

### 4.2 Get User Details for Edit (Line 22)

```sql
-- Get user basic info (Lines 23-29)
SELECT
  u."Id",
  u."EmployeeCode",                            -- Line 25
  u."FirstNameTh",                             -- Line 26
  u."FirstNameEn",
  u."LastNameTh",                              -- Line 27
  u."LastNameEn",
  u."Email",                                   -- Line 28
  u."PhoneNumber",
  u."MobileNumber",
  u."PreferredLanguage",
  u."IsActive"
FROM "Users" u
WHERE u."Id" = @UserId;

-- Get user's company roles (Lines 30-75)
SELECT
  ucr."Id" AS "UserCompanyRoleId",
  ucr."CompanyId",                             -- Line 29: บริษัท
  c."ShortNameEn" AS "CompanyName",
  ucr."DepartmentId",
  d."DepartmentNameTh",
  ucr."PrimaryRoleId",                         -- Line 31: บทบาทหลัก
  r1."RoleCode" AS "PrimaryRoleCode",
  r1."RoleNameTh" AS "PrimaryRoleName",
  ucr."SecondaryRoleId",                       -- Line 52: บทบาทรอง
  r2."RoleCode" AS "SecondaryRoleCode",
  r2."RoleNameTh" AS "SecondaryRoleName",
  ucr."PositionId",
  p."PositionNameTh",
  ucr."ApproverLevel",
  ucr."StartDate",                             -- Line 74: วันที่เริ่มต้น
  ucr."EndDate",                               -- Line 75: วันที่สิ้นสุด
  ucr."IsActive"
FROM "UserCompanyRoles" ucr
JOIN "Companies" c ON ucr."CompanyId" = c."Id"
LEFT JOIN "Departments" d ON ucr."DepartmentId" = d."Id"
JOIN "Roles" r1 ON ucr."PrimaryRoleId" = r1."Id"
LEFT JOIN "Roles" r2 ON ucr."SecondaryRoleId" = r2."Id"
LEFT JOIN "Positions" p ON ucr."PositionId" = p."Id"
WHERE ucr."UserId" = @UserId;

-- Get role permissions (Lines 32-72: Checkboxes)
SELECT
  rp."RoleId",
  r."RoleCode",
  p."PermissionCode",
  p."PermissionName",
  p."Module",
  rp."IsActive"
FROM "RolePermissions" rp
JOIN "Roles" r ON rp."RoleId" = r."Id"
JOIN "Permissions" p ON rp."PermissionId" = p."Id"
WHERE rp."RoleId" IN (@PrimaryRoleId, @SecondaryRoleId)
  AND rp."IsActive" = TRUE;

-- Get category bindings (for PURCHASING/PURCHASING_APPROVER)
SELECT
  ucb."CategoryId",
  c."CategoryNameTh",
  ucb."SubcategoryId",
  s."SubcategoryNameTh"
FROM "UserCategoryBindings" ucb
JOIN "Categories" c ON ucb."CategoryId" = c."Id"
LEFT JOIN "Subcategories" s ON ucb."SubcategoryId" = s."Id"
WHERE ucb."UserCompanyRoleId" = @UserCompanyRoleId
  AND ucb."IsActive" = TRUE;
```

### 4.3 Create New User (Line 22: "เพิ่มผู้ใช้ใหม่")

```sql
BEGIN;

-- Step 1: Insert user (Lines 25-28)
INSERT INTO "Users" (
  "EmployeeCode",                              -- Line 25: *รหัสพนักงาน
  "FirstNameTh",                               -- Line 26: *ชื่อ
  "LastNameTh",                                -- Line 27: *นามสกุล
  "Email",                                     -- Line 28: *อีเมล
  "PasswordHash",                              -- Auto-generated temp password
  "PreferredLanguage",
  "Status",
  "IsActive",
  "CreatedBy"
) VALUES (
  @EmployeeCode,
  @FirstNameTh,
  @LastNameTh,
  @Email,
  @TempPasswordHash,  -- BCrypt hash of temp password (e.g., "TempPass123!")
  'th',
  'ACTIVE',
  TRUE,
  @AdminUserId
)
RETURNING "Id" AS "NewUserId";

-- Step 2: Insert company role (Lines 29-52)
INSERT INTO "UserCompanyRoles" (
  "UserId",
  "CompanyId",                                 -- Line 29: *บริษัท
  "DepartmentId",
  "PrimaryRoleId",                             -- Line 31: บทบาทหลัก
  "SecondaryRoleId",                           -- Line 52: บทบาทรอง (optional)
  "ApproverLevel",                             -- For APPROVER role
  "StartDate",                                 -- Line 74: *วันที่เริ่มต้น
  "EndDate",                                   -- Line 75: วันที่สิ้นสุด (optional)
  "IsActive",
  "CreatedBy"
) VALUES (
  @NewUserId,
  @CompanyId,
  @DepartmentId,
  @PrimaryRoleId,
  @SecondaryRoleId,
  @ApproverLevel,
  @StartDate,
  @EndDate,
  TRUE,
  @AdminUserId
)
RETURNING "Id" AS "UserCompanyRoleId";

-- Step 3: Insert category bindings (for PURCHASING/PURCHASING_APPROVER)
-- Only if PrimaryRoleCode IN ('PURCHASING', 'PURCHASING_APPROVER')
INSERT INTO "UserCategoryBindings" (
  "UserCompanyRoleId",
  "CategoryId",
  "SubcategoryId"
)
SELECT
  @UserCompanyRoleId,
  unnest(@CategoryIds::BIGINT[]),
  unnest(@SubcategoryIds::BIGINT[])  -- Can be NULL
;

COMMIT;
```

#### Send Welcome Email
```csharp
var welcomeEmail = new
{
    To = newUser.Email,
    Subject = "ยินดีต้อนรับสู่ระบบ eRFX",
    Body = $@"
        <h2>บัญชีของคุณถูกสร้างแล้ว</h2>
        <p>รหัสพนักงาน: {newUser.EmployeeCode}</p>
        <p>อีเมล: {newUser.Email}</p>
        <p>รหัสผ่านชั่วคราว: {tempPassword}</p>
        <p>กรุณาเปลี่ยนรหัสผ่านเมื่อเข้าสู่ระบบครั้งแรก</p>
        <a href='{loginUrl}'>เข้าสู่ระบบ</a>
    "
};

await _emailService.SendAsync(welcomeEmail);
```

### 4.4 Permission Checkboxes Mapping (Lines 32-72)

#### REQUESTER Role (Lines 32-34, 53-55)
```
Line 32: if select : Requester
Line 33:   input checkbox : สร้าง (Create)
Line 34:   input checkbox : แก้ไข (Update)
```

**Permission Codes**:
- `RFQ_CREATE`
- `RFQ_UPDATE`

#### APPROVER Role (Lines 35-36, 56-57)
```
Line 35: if select : Approver
Line 36:   input checkbox : ตัดสินใจ (consider)
```

**Permission Codes**:
- `RFQ_APPROVE`
- `RFQ_FORWARD`
- `RFQ_DECLINE`

#### PURCHASING Role (Lines 37-43, 58-64)
```
Line 37: if select : Purchasing
Line 38:   input checkbox : ดูข้อมูล (Read)
Line 39:   input checkbox : เชิญ Supplier (Invite)
Line 40:   input checkbox : เพิ่มข้อมูล (Insert)
Line 41:   input checkbox : ตัดสินใจ (consider)
Line 42:   input checkbox : ตรวจสอบข้อมูลSupplier (Pre Approve)
Line 43:   input checkbox : เลือกผู้ชนะเบื้องต้น(Frist Select Winner)
```

**Permission Codes**:
- `RFQ_READ`
- `SUPPLIER_INVITE`
- `RFQ_INSERT_DATA`
- `RFQ_DECIDE`
- `SUPPLIER_PRE_APPROVE`
- `WINNER_SELECT_FIRST`

#### SUPPLIER Role (Lines 44-46, 65-67)
```
Line 44: if select : Supplier
Line 45:   input checkbox : สร้าง (Create)
Line 46:   input checkbox : แก้ไข (Update)
```

**Permission Codes**:
- `QUOTATION_CREATE`
- `QUOTATION_UPDATE`

#### PURCHASING_APPROVER Role (Lines 47-49, 68-70)
```
Line 47: if select : Purchasing Approver
Line 48:   input checkbox : เลือกผู้ชนะสุดท้าย(Final Winner)
Line 49:   input checkbox : อนุมัติ Supplier ใหม่(Approver Supplier)
```

**Permission Codes**:
- `WINNER_SELECT_FINAL`
- `SUPPLIER_APPROVE`

#### MANAGING_DIRECTOR Role (Lines 50-51, 71-72)
```
Line 50: if select : Managing director
Line 51:   input checkbox : Dashboard summary executive
```

**Permission Codes**:
- `DASHBOARD_EXECUTIVE`
- `REPORTS_VIEW_ALL`

### 4.5 Update User (Line 22: "แก้ไขข้อมูล")

```sql
BEGIN;

-- Update user basic info (Lines 25-28)
UPDATE "Users"
SET
  "EmployeeCode" = @EmployeeCode,              -- Line 25
  "FirstNameTh" = @FirstNameTh,                -- Line 26
  "LastNameTh" = @LastNameTh,                  -- Line 27
  "Email" = @Email,                            -- Line 28
  "UpdatedAt" = CURRENT_TIMESTAMP,
  "UpdatedBy" = @AdminUserId
WHERE "Id" = @UserId;

-- Update existing company role
UPDATE "UserCompanyRoles"
SET
  "CompanyId" = @CompanyId,                    -- Line 29
  "DepartmentId" = @DepartmentId,
  "PrimaryRoleId" = @PrimaryRoleId,            -- Line 31
  "SecondaryRoleId" = @SecondaryRoleId,        -- Line 52
  "ApproverLevel" = @ApproverLevel,
  "StartDate" = @StartDate,                    -- Line 74
  "EndDate" = @EndDate,                        -- Line 75
  "UpdatedAt" = CURRENT_TIMESTAMP,
  "UpdatedBy" = @AdminUserId
WHERE "Id" = @UserCompanyRoleId;

-- Update category bindings
-- Delete old bindings
DELETE FROM "UserCategoryBindings"
WHERE "UserCompanyRoleId" = @UserCompanyRoleId;

-- Insert new bindings
INSERT INTO "UserCategoryBindings" (
  "UserCompanyRoleId",
  "CategoryId",
  "SubcategoryId"
)
SELECT
  @UserCompanyRoleId,
  unnest(@CategoryIds::BIGINT[]),
  unnest(@SubcategoryIds::BIGINT[])
;

COMMIT;
```

### 4.6 Delete User (Line 21: "ลบ")

```sql
-- Soft delete (recommended)
UPDATE "Users"
SET
  "IsDeleted" = TRUE,
  "DeletedAt" = CURRENT_TIMESTAMP,
  "DeletedBy" = @AdminUserId,
  "IsActive" = FALSE
WHERE "Id" = @UserId;

-- Deactivate all roles
UPDATE "UserCompanyRoles"
SET
  "IsActive" = FALSE,
  "EndDate" = CURRENT_DATE,
  "UpdatedAt" = CURRENT_TIMESTAMP,
  "UpdatedBy" = @AdminUserId
WHERE "UserId" = @UserId;

-- Revoke all tokens
UPDATE "RefreshTokens"
SET
  "RevokedAt" = CURRENT_TIMESTAMP,
  "ReasonRevoked" = 'User Deleted'
WHERE "UserType" = 'Employee'
  AND "UserId" = @UserId
  AND "RevokedAt" IS NULL;
```

### 4.7 Role Expiry Date Logic (Lines 73-75)

```
Line 73: ระยะเวลาในการใช้งานบทบาท : radio button ไม่มีวันหมดอายุ , มีวันหมดอายุ
Line 74: *วันที่เริ่มต้นบทบาท :  date
Line 75:  วันที่สิ้นสุดบทบาท :  date
```

#### Check Role Expiry (Scheduled Job)
```sql
-- Find expired roles (run daily)
SELECT
  ucr."Id",
  ucr."UserId",
  u."Email",
  u."FirstNameTh",
  u."LastNameTh",
  r."RoleNameTh",
  ucr."EndDate"
FROM "UserCompanyRoles" ucr
JOIN "Users" u ON ucr."UserId" = u."Id"
JOIN "Roles" r ON ucr."PrimaryRoleId" = r."Id"
WHERE ucr."IsActive" = TRUE
  AND ucr."EndDate" IS NOT NULL                -- Line 73: มีวันหมดอายุ
  AND ucr."EndDate" < CURRENT_DATE;

-- Auto-deactivate expired roles
UPDATE "UserCompanyRoles"
SET
  "IsActive" = FALSE,
  "UpdatedAt" = CURRENT_TIMESTAMP
WHERE "IsActive" = TRUE
  AND "EndDate" IS NOT NULL
  AND "EndDate" < CURRENT_DATE;

-- Send notification to users with expiring roles (7 days before)
SELECT
  u."Email",
  u."FirstNameTh",
  r."RoleNameTh",
  ucr."EndDate",
  (ucr."EndDate" - CURRENT_DATE) AS "DaysRemaining"
FROM "UserCompanyRoles" ucr
JOIN "Users" u ON ucr."UserId" = u."Id"
JOIN "Roles" r ON ucr."PrimaryRoleId" = r."Id"
WHERE ucr."IsActive" = TRUE
  AND ucr."EndDate" IS NOT NULL
  AND ucr."EndDate" BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '7 days';
```

---

## SECTION 5: Admin: Exchange Rate Management

### Business Documentation Mapping (Lines 18-19)

```
Line 18: ตารางอัตราแลกเปลี่ยนรายเดือน พร้อมปุ่มอัปโหลดไฟล์ รองรับสกุลเงินและอัตราแลกเปลี่ยน ซึ่งจะอัปเดตเดือนละครั้ง
Line 19: ปุ่ม อัพโหลดไฟล์ ฟังก์ชัน: นำเข้า อัตราแลกเปลี่ยนประจำเดือน สกุลเงิน , อัตราแลกเปลี่ยน
```

### Database Schema Mapping

**ExchangeRates Table** (Lines 1002-1020)
```sql
CREATE TABLE "ExchangeRates" (
  "Id" BIGSERIAL PRIMARY KEY,
  "FromCurrencyId" BIGINT NOT NULL REFERENCES "Currencies"("Id"),  -- Line 19: สกุลเงิน
  "ToCurrencyId" BIGINT NOT NULL REFERENCES "Currencies"("Id"),
  "Rate" DECIMAL(15,6) NOT NULL,                                   -- Line 19: อัตราแลกเปลี่ยน
  "EffectiveDate" DATE NOT NULL,                                   -- Line 18: รายเดือน (1st of month)
  "ExpiryDate" DATE,
  "Source" VARCHAR(50) DEFAULT 'MANUAL',
  "SourceReference" VARCHAR(100),
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "CreatedBy" BIGINT REFERENCES "Users"("Id"),
  "UpdatedAt" TIMESTAMP,
  "UpdatedBy" BIGINT REFERENCES "Users"("Id"),

  UNIQUE("FromCurrencyId", "ToCurrencyId", "EffectiveDate"),
  CONSTRAINT "chk_exchange_rate_positive" CHECK ("Rate" > 0),
  CONSTRAINT "chk_exchange_rate_validity" CHECK (
    "ExpiryDate" IS NULL OR "ExpiryDate" > "EffectiveDate"
  ),
  CONSTRAINT "chk_exchange_rate_currencies" CHECK ("FromCurrencyId" != "ToCurrencyId")
);
```

**Currencies Table** (Lines 169-178)
```sql
CREATE TABLE "Currencies" (
  "Id" BIGSERIAL PRIMARY KEY,
  "CurrencyCode" VARCHAR(3) UNIQUE NOT NULL,   -- ISO 4217 (THB, USD, EUR, etc.)
  "CurrencyNameTh" VARCHAR(100) NOT NULL,
  "CurrencyNameEn" VARCHAR(100),
  "Symbol" VARCHAR(10),
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 5.1 Display Exchange Rates (Line 18)

```sql
-- Line 18: "ตารางอัตราแลกเปลี่ยนรายเดือน"
-- Get current month's exchange rates
WITH current_rates AS (
  SELECT
    er."Id",
    cf."CurrencyCode" AS "FromCurrency",
    cf."CurrencyNameTh" AS "FromCurrencyName",
    cf."Symbol" AS "FromSymbol",
    ct."CurrencyCode" AS "ToCurrency",
    ct."CurrencyNameTh" AS "ToCurrencyName",
    ct."Symbol" AS "ToSymbol",
    er."Rate",
    er."EffectiveDate",
    er."ExpiryDate",
    er."Source",
    er."CreatedAt",
    u."FirstNameTh" || ' ' || u."LastNameTh" AS "CreatedBy"
  FROM "ExchangeRates" er
  JOIN "Currencies" cf ON er."FromCurrencyId" = cf."Id"
  JOIN "Currencies" ct ON er."ToCurrencyId" = ct."Id"
  LEFT JOIN "Users" u ON er."CreatedBy" = u."Id"
  WHERE er."IsActive" = TRUE
    AND er."EffectiveDate" = DATE_TRUNC('month', CURRENT_DATE)  -- Current month
  ORDER BY cf."CurrencyCode", ct."CurrencyCode"
)
SELECT * FROM current_rates;

-- Get all months with exchange rates (for dropdown/filter)
SELECT DISTINCT
  TO_CHAR("EffectiveDate", 'YYYY-MM') AS "YearMonth",
  TO_CHAR("EffectiveDate", 'Month YYYY') AS "MonthDisplay",
  COUNT(*) AS "RateCount"
FROM "ExchangeRates"
WHERE "IsActive" = TRUE
GROUP BY TO_CHAR("EffectiveDate", 'YYYY-MM'), TO_CHAR("EffectiveDate", 'Month YYYY')
ORDER BY "YearMonth" DESC;
```

### 5.2 Upload Exchange Rates File (Line 19)

#### Expected File Format (Excel/CSV)
```
FromCurrency | ToCurrency | Rate      | EffectiveDate
-------------|------------|-----------|---------------
USD          | THB        | 35.850000 | 2025-10-01
EUR          | THB        | 39.120000 | 2025-10-01
JPY          | THB        | 0.241000  | 2025-10-01
CNY          | THB        | 4.950000  | 2025-10-01
GBP          | THB        | 45.200000 | 2025-10-01
```

#### Import Process
```sql
BEGIN;

-- Step 1: Validate currencies exist
WITH upload_data AS (
  SELECT * FROM unnest(
    @FromCurrencyCodes::VARCHAR[],
    @ToCurrencyCodes::VARCHAR[],
    @Rates::DECIMAL[],
    @EffectiveDates::DATE[]
  ) AS t("FromCode", "ToCode", "Rate", "EffectiveDate")
),
validated_data AS (
  SELECT
    ud.*,
    cf."Id" AS "FromCurrencyId",
    ct."Id" AS "ToCurrencyId"
  FROM upload_data ud
  LEFT JOIN "Currencies" cf ON ud."FromCode" = cf."CurrencyCode"
  LEFT JOIN "Currencies" ct ON ud."ToCode" = ct."CurrencyCode"
)
SELECT
  COUNT(*) AS "TotalRows",
  COUNT(CASE WHEN "FromCurrencyId" IS NULL THEN 1 END) AS "InvalidFromCurrency",
  COUNT(CASE WHEN "ToCurrencyId" IS NULL THEN 1 END) AS "InvalidToCurrency",
  COUNT(CASE WHEN "Rate" <= 0 THEN 1 END) AS "InvalidRate"
FROM validated_data;

-- Step 2: Deactivate existing rates for the same month
UPDATE "ExchangeRates"
SET
  "IsActive" = FALSE,
  "UpdatedAt" = CURRENT_TIMESTAMP,
  "UpdatedBy" = @AdminUserId
WHERE DATE_TRUNC('month', "EffectiveDate") = DATE_TRUNC('month', @NewEffectiveDate)
  AND "IsActive" = TRUE;

-- Step 3: Insert new rates
INSERT INTO "ExchangeRates" (
  "FromCurrencyId",
  "ToCurrencyId",
  "Rate",
  "EffectiveDate",
  "ExpiryDate",
  "Source",
  "SourceReference",
  "CreatedBy"
)
SELECT
  vd."FromCurrencyId",
  vd."ToCurrencyId",
  vd."Rate",
  vd."EffectiveDate",
  (DATE_TRUNC('month', vd."EffectiveDate") + INTERVAL '1 month - 1 day')::DATE AS "ExpiryDate",
  'FILE_UPLOAD',                               -- Line 19: Source = File Upload
  @FileName,
  @AdminUserId
FROM validated_data vd
WHERE vd."FromCurrencyId" IS NOT NULL
  AND vd."ToCurrencyId" IS NOT NULL
  AND vd."Rate" > 0
ON CONFLICT ("FromCurrencyId", "ToCurrencyId", "EffectiveDate")
DO UPDATE SET
  "Rate" = EXCLUDED."Rate",
  "Source" = EXCLUDED."Source",
  "SourceReference" = EXCLUDED."SourceReference",
  "UpdatedAt" = CURRENT_TIMESTAMP,
  "UpdatedBy" = @AdminUserId;

COMMIT;
```

#### Import Error Handling
```csharp
public class ExchangeRateImportResult
{
    public int TotalRows { get; set; }
    public int SuccessRows { get; set; }
    public int ErrorRows { get; set; }
    public List<string> Errors { get; set; } = new();

    public void AddError(int rowNumber, string message)
    {
        Errors.Add($"Row {rowNumber}: {message}");
    }
}

public async Task<ExchangeRateImportResult> ImportExchangeRatesAsync(
    IFormFile file,
    long adminUserId)
{
    var result = new ExchangeRateImportResult();

    // Parse file (Excel/CSV)
    var rows = await ParseFileAsync(file);
    result.TotalRows = rows.Count;

    var validRows = new List<ExchangeRateRow>();

    for (int i = 0; i < rows.Count; i++)
    {
        var row = rows[i];

        // Validate
        if (string.IsNullOrEmpty(row.FromCurrency))
        {
            result.AddError(i + 2, "FromCurrency is required");
            continue;
        }

        if (string.IsNullOrEmpty(row.ToCurrency))
        {
            result.AddError(i + 2, "ToCurrency is required");
            continue;
        }

        if (row.Rate <= 0)
        {
            result.AddError(i + 2, "Rate must be greater than 0");
            continue;
        }

        if (row.FromCurrency == row.ToCurrency)
        {
            result.AddError(i + 2, "FromCurrency and ToCurrency must be different");
            continue;
        }

        validRows.Add(row);
    }

    // Import valid rows
    if (validRows.Any())
    {
        await ImportToDatabase(validRows, adminUserId, file.FileName);
        result.SuccessRows = validRows.Count;
    }

    result.ErrorRows = result.TotalRows - result.SuccessRows;

    return result;
}
```

### 5.3 Exchange Rate Usage in Quotations

#### Get Effective Rate at Submission Time
```sql
-- Line 18: "อัตราแลกเปลี่ยนรายเดือน ซึ่งจะอัปเดตเดือนละครั้ง"
-- Get exchange rate effective at quotation submission time
-- This is used in QuotationItems.ConvertedUnitPrice calculation

SELECT
  er."Rate"
FROM "ExchangeRates" er
WHERE er."FromCurrencyId" = @SupplierCurrencyId
  AND er."ToCurrencyId" = @CompanyCurrencyId
  AND er."EffectiveDate" <= @SubmittedAt
  AND (er."ExpiryDate" IS NULL OR er."ExpiryDate" >= @SubmittedAt)
  AND er."IsActive" = TRUE
ORDER BY er."EffectiveDate" DESC
LIMIT 1;

-- Fallback: If no rate found, use latest available
SELECT
  er."Rate",
  er."EffectiveDate"
FROM "ExchangeRates" er
WHERE er."FromCurrencyId" = @SupplierCurrencyId
  AND er."ToCurrencyId" = @CompanyCurrencyId
  AND er."IsActive" = TRUE
ORDER BY er."EffectiveDate" DESC
LIMIT 1;
```

### 5.4 Manual Exchange Rate Entry

```sql
-- Line 19: Admin can also manually add individual rates
INSERT INTO "ExchangeRates" (
  "FromCurrencyId",
  "ToCurrencyId",
  "Rate",
  "EffectiveDate",
  "ExpiryDate",
  "Source",
  "CreatedBy"
) VALUES (
  (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = @FromCode),
  (SELECT "Id" FROM "Currencies" WHERE "CurrencyCode" = @ToCode),
  @Rate,
  @EffectiveDate,
  @ExpiryDate,
  'MANUAL',
  @AdminUserId
)
ON CONFLICT ("FromCurrencyId", "ToCurrencyId", "EffectiveDate")
DO UPDATE SET
  "Rate" = EXCLUDED."Rate",
  "Source" = EXCLUDED."Source",
  "UpdatedAt" = CURRENT_TIMESTAMP,
  "UpdatedBy" = @AdminUserId;
```

---

## SECTION 6: Admin: Category & Supplier Management

### Business Documentation Mapping (Lines 77-94)

```
Line 77: ### หน้าจอ Category Management + Supplier management
Line 78: ช่องค้นหา ค้นหาข้อความอิสระในหลายฟิลด์ (ชื่อบริษัท / หน่วยงาน, ชื่อ-นามสกุล, เบอร์มือถือ หรือ อีเมล)
Line 79: ตารางราง  เลขประจำตัวผู้เสียภาษี  |   ชื่อบริษัท / หน่วยงาน  |   ผู้ติดต่อ  |   อีเมล  |   กลุ่มสินค้า / บริการ  |   หมวดหมู่ย่อยสินค้า / บริการ  | แก้ไข/ลบ
Line 80: ไอคอน edit ฟังก์ชัน pop up จัดการกลุ่มสินค้า และหมวดหมู่ย่อยสินค้า
Lines 81-94: Edit Category Form
```

### 6.1 Supplier List with Categories (Lines 78-79)

```sql
-- Line 78: Search box - "ค้นหาข้อความอิสระในหลายฟิลด์"
-- Line 79: Display columns

WITH supplier_info AS (
  SELECT
    s."Id",
    s."TaxId",                                 -- Line 79: เลขประจำตัวผู้เสียภาษี
    s."CompanyNameTh",                         -- Line 79: ชื่อบริษัท / หน่วยงาน
    s."Status",

    -- Primary contact info (Line 79: ผู้ติดต่อ, อีเมล)
    STRING_AGG(
      DISTINCT CASE WHEN sc."IsPrimaryContact" = TRUE
      THEN sc."FirstName" || ' ' || sc."LastName"
      END, ', '
    ) AS "PrimaryContacts",                    -- Line 79: ผู้ติดต่อ

    STRING_AGG(
      DISTINCT CASE WHEN sc."IsPrimaryContact" = TRUE
      THEN sc."Email"
      END, ', '
    ) AS "PrimaryEmails",                      -- Line 79: อีเมล

    STRING_AGG(
      DISTINCT CASE WHEN sc."IsPrimaryContact" = TRUE
      THEN sc."MobileNumber"
      END, ', '
    ) AS "PrimaryPhones",                      -- Line 78: เบอร์มือถือ

    -- Categories (Line 79: กลุ่มสินค้า / บริการ)
    STRING_AGG(
      DISTINCT c."CategoryNameTh", ', '
      ORDER BY c."CategoryNameTh"
    ) AS "Categories",

    -- Subcategories (Line 79: หมวดหมู่ย่อยสินค้า / บริการ)
    STRING_AGG(
      DISTINCT sub."SubcategoryNameTh", ', '
      ORDER BY sub."SubcategoryNameTh"
    ) AS "Subcategories"

  FROM "Suppliers" s
  LEFT JOIN "SupplierContacts" sc ON s."Id" = sc."SupplierId" AND sc."IsActive" = TRUE
  LEFT JOIN "SupplierCategories" scat ON s."Id" = scat."SupplierId" AND scat."IsActive" = TRUE
  LEFT JOIN "Categories" c ON scat."CategoryId" = c."Id"
  LEFT JOIN "Subcategories" sub ON scat."SubcategoryId" = sub."Id"
  WHERE s."IsActive" = TRUE
    AND s."Status" = 'COMPLETED'               -- Only approved suppliers
  GROUP BY s."Id", s."TaxId", s."CompanyNameTh", s."Status"
)
SELECT * FROM supplier_info
WHERE
  -- Line 78: Search filter
  @SearchTerm IS NULL OR
  "TaxId" ILIKE '%' || @SearchTerm || '%' OR
  "CompanyNameTh" ILIKE '%' || @SearchTerm || '%' OR
  "PrimaryContacts" ILIKE '%' || @SearchTerm || '%' OR
  "PrimaryEmails" ILIKE '%' || @SearchTerm || '%' OR
  "PrimaryPhones" ILIKE '%' || @SearchTerm || '%'
ORDER BY "CompanyNameTh";
```

### 6.2 Get Supplier Categories for Edit (Lines 80-82)

```sql
-- Line 80: "pop up จัดการกลุ่มสินค้า และหมวดหมู่ย่อยสินค้า"
-- Line 82: "แสดง เลขประจำตัวผู้เสียภาษี ,ชื่อบริษัท / หน่วยงาน ,ชื่อ,นามสกุล,เบอร์มือถือ"

-- Get supplier basic info
SELECT
  s."Id",
  s."TaxId",                                   -- Line 82
  s."CompanyNameTh",                           -- Line 82

  -- Primary contact
  sc."FirstName",                              -- Line 82: ชื่อ
  sc."LastName",                               -- Line 82: นามสกุล
  sc."MobileNumber",                           -- Line 82: เบอร์มือถือ
  sc."Email"                                   -- Line 83: อีเมล
FROM "Suppliers" s
LEFT JOIN "SupplierContacts" sc ON s."Id" = sc."SupplierId"
  AND sc."IsPrimaryContact" = TRUE
  AND sc."IsActive" = TRUE
WHERE s."Id" = @SupplierId;

-- Get current category assignments
SELECT
  scat."Id",
  scat."CategoryId",
  c."CategoryCode",
  c."CategoryNameTh",
  scat."SubcategoryId",
  sub."SubcategoryCode",
  sub."SubcategoryNameTh"
FROM "SupplierCategories" scat
JOIN "Categories" c ON scat."CategoryId" = c."Id"
LEFT JOIN "Subcategories" sub ON scat."SubcategoryId" = sub."Id"
WHERE scat."SupplierId" = @SupplierId
  AND scat."IsActive" = TRUE;

-- Get all available categories (Lines 84-85)
SELECT
  "Id",
  "CategoryCode",
  "CategoryNameTh",                            -- Line 84: Dropdown List Category
  "SortOrder"
FROM "Categories"
WHERE "IsActive" = TRUE
ORDER BY "SortOrder", "CategoryNameTh";

-- Get subcategories for selected category (Line 85)
SELECT
  "Id",
  "SubcategoryCode",
  "SubcategoryNameTh",                         -- Line 85: Dropdown List SubCategory
  "SortOrder"
FROM "Subcategories"
WHERE "CategoryId" = @CategoryId
  AND "IsActive" = TRUE
ORDER BY "SortOrder", "SubcategoryNameTh";
```

### 6.3 Update Supplier Categories (Lines 86-87)

```
Line 86: ปุ่ม เพิ่ม ฟังก์ชัน: เพิ่ม Category ,SubCategory ในหน้า ui
Line 87: ปุ่ม บันทึกการเปลี่ยนแปลง ฟังก์ชัน: ปรับแก้ Category และ Subcategory ผูกกับ Supplier
Line 88: หมายเหตุ :  สามารถ add ได้หลาย Category แล้วมาเลือก  Subcategory
```

#### Update Email (Line 83)
```sql
-- Line 83: "อีเมล *  input กรอก email"
-- Update primary contact email
UPDATE "SupplierContacts"
SET
  "Email" = @NewEmail,
  "UpdatedAt" = CURRENT_TIMESTAMP,
  "UpdatedBy" = @AdminUserId
WHERE "SupplierId" = @SupplierId
  AND "IsPrimaryContact" = TRUE;
```

#### Save Category Changes (Line 87)
```sql
BEGIN;

-- Step 1: Deactivate all existing category assignments
UPDATE "SupplierCategories"
SET
  "IsActive" = FALSE
WHERE "SupplierId" = @SupplierId;

-- Step 2: Insert new category assignments
-- Line 88: "สามารถ add ได้หลาย Category แล้วมาเลือก  Subcategory"
INSERT INTO "SupplierCategories" (
  "SupplierId",
  "CategoryId",                                -- Line 84
  "SubcategoryId"                              -- Line 85 (can be NULL)
)
SELECT
  @SupplierId,
  unnest(@CategoryIds::BIGINT[]),
  unnest(@SubcategoryIds::BIGINT[])            -- Use NULL for categories without subcategory
ON CONFLICT ("SupplierId", "CategoryId", "SubcategoryId")
DO UPDATE SET
  "IsActive" = TRUE;

COMMIT;
```

### 6.4 Example: Multiple Categories Assignment (Lines 89-94)

```
Line 89: ตัวอย่าง   การเพิ่ม Category  และ Subcategory ใน บริษัท Supplier A
Line 90:   Category  ☑    บริการด้านเทคโนโลยี   >  Subcategory  ☑    ไอที/ คอมพิวเตอร์และอุปกรณ์
Line 91:                                                          ☑    อุปกรณ์ต่อพ่วงคอมพิวเตอร์
Line 92:                                                          ☑    บริการให้คำปรึกษาและพัฒนาระบบซอฟต์แวร์
Line 93:   Category  ☑    เครื่องจักรการพิมพ์    >  Subcategory  ☑    เครื่องพิมพ์เลเซอร์
Line 94:                                                          ☑    เครื่องพิมพ์ดิจิทัล (Digital Printing)
```

#### SQL Example
```sql
-- Example data structure for Lines 90-94
INSERT INTO "SupplierCategories" ("SupplierId", "CategoryId", "SubcategoryId")
VALUES
  -- บริการด้านเทคโนโลยี (Category ID = 5)
  (@SupplierId, 5, 101),  -- ไอที/ คอมพิวเตอร์และอุปกรณ์
  (@SupplierId, 5, 102),  -- อุปกรณ์ต่อพ่วงคอมพิวเตอร์
  (@SupplierId, 5, 103),  -- บริการให้คำปรึกษาและพัฒนาระบบซอฟต์แวร์

  -- เครื่องจักรการพิมพ์ (Category ID = 8)
  (@SupplierId, 8, 201),  -- เครื่องพิมพ์เลเซอร์
  (@SupplierId, 8, 202)   -- เครื่องพิมพ์ดิจิทัล (Digital Printing)
;

-- Verify assignment
SELECT
  c."CategoryNameTh" AS "Category",
  s."SubcategoryNameTh" AS "Subcategory"
FROM "SupplierCategories" sc
JOIN "Categories" c ON sc."CategoryId" = c."Id"
LEFT JOIN "Subcategories" s ON sc."SubcategoryId" = s."Id"
WHERE sc."SupplierId" = @SupplierId
  AND sc."IsActive" = TRUE
ORDER BY c."SortOrder", s."SortOrder";

-- Result:
-- Category                    | Subcategory
-- ---------------------------|------------------------------------------
-- บริการด้านเทคโนโลยี           | ไอที/ คอมพิวเตอร์และอุปกรณ์
-- บริการด้านเทคโนโลยี           | อุปกรณ์ต่อพ่วงคอมพิวเตอร์
-- บริการด้านเทคโนโลยี           | บริการให้คำปรึกษาและพัฒนาระบบซอฟต์แวร์
-- เครื่องจักรการพิมพ์           | เครื่องพิมพ์เลเซอร์
-- เครื่องจักรการพิมพ์           | เครื่องพิมพ์ดิจิทัล (Digital Printing)
```

---

## SECTION 7: Database Schema Overview

### 7.1 Core Authentication Tables

| Table | Primary Key | Key Columns | Purpose |
|-------|-------------|-------------|---------|
| Users | Id | Email, PasswordHash, PreferredLanguage | Internal user accounts |
| SupplierContacts | Id | SupplierId, Email, PasswordHash | Supplier user accounts |
| LoginHistory | Id | UserType, UserId, ContactId, LoginAt | Login/logout tracking |
| RefreshTokens | Id | Token, UserType, UserId, ContactId | JWT refresh tokens |

### 7.2 User Management Tables

| Table | Primary Key | Key Columns | Purpose |
|-------|-------------|-------------|---------|
| Companies | Id | ShortNameEn, Status | Multi-company support |
| Departments | Id | CompanyId, DepartmentCode | Department structure |
| Roles | Id | RoleCode, RoleNameTh | 8 system roles |
| Permissions | Id | PermissionCode, Module | System permissions |
| RolePermissions | Id | RoleId, PermissionId | Role-permission mapping |
| UserCompanyRoles | Id | UserId, CompanyId, PrimaryRoleId | User role assignments |
| UserCategoryBindings | Id | UserCompanyRoleId, CategoryId | PURCHASING category bindings |

### 7.3 Supplier Management Tables

| Table | Primary Key | Key Columns | Purpose |
|-------|-------------|-------------|---------|
| Suppliers | Id | TaxId, CompanyNameTh, Status | Supplier companies |
| SupplierContacts | Id | SupplierId, Email, IsPrimaryContact | Supplier contacts |
| SupplierCategories | Id | SupplierId, CategoryId, SubcategoryId | Supplier category bindings |
| SupplierDocuments | Id | SupplierId, DocumentType | Supplier registration docs |

### 7.4 Master Data Tables

| Table | Primary Key | Key Columns | Purpose |
|-------|-------------|-------------|---------|
| Currencies | Id | CurrencyCode, Symbol | Currency master data |
| ExchangeRates | Id | FromCurrencyId, ToCurrencyId, Rate, EffectiveDate | Monthly exchange rates |
| Categories | Id | CategoryCode, CategoryNameTh | Product/service categories |
| Subcategories | Id | CategoryId, SubcategoryCode | Category subdivisions |

---

## SECTION 8: SQL Query Templates

### 8.1 Authentication Queries

#### Internal User Login
```sql
-- Validate credentials and get user info
SELECT
  u."Id",
  u."Email",
  u."PasswordHash",
  u."SecurityStamp",
  u."PreferredLanguage",
  u."Status",
  u."IsActive",
  u."LockoutEnabled",
  u."LockoutEnd",
  u."AccessFailedCount",

  -- Primary company and role
  ucr."CompanyId",
  c."ShortNameEn" AS "CompanyName",
  ucr."PrimaryRoleId",
  r."RoleCode" AS "PrimaryRoleCode",
  r."RoleNameTh" AS "PrimaryRoleName",
  ucr."DepartmentId",
  ucr."ApproverLevel"

FROM "Users" u
LEFT JOIN "UserCompanyRoles" ucr ON u."Id" = ucr."UserId"
  AND ucr."IsActive" = TRUE
  AND (ucr."EndDate" IS NULL OR ucr."EndDate" >= CURRENT_DATE)
LEFT JOIN "Companies" c ON ucr."CompanyId" = c."Id"
LEFT JOIN "Roles" r ON ucr."PrimaryRoleId" = r."Id"
WHERE u."Email" = @Email
  AND u."IsActive" = TRUE
  AND u."Status" = 'ACTIVE'
LIMIT 1;
```

#### Supplier Contact Login
```sql
-- Validate supplier contact credentials
SELECT
  sc."Id",
  sc."SupplierId",
  sc."Email",
  sc."PasswordHash",
  sc."SecurityStamp",
  sc."PreferredLanguage",
  sc."FirstName",
  sc."LastName",
  sc."IsPrimaryContact",
  sc."CanSubmitQuotation",
  sc."FailedLoginAttempts",
  sc."LockoutEnd",

  -- Supplier info
  s."CompanyNameTh",
  s."Status" AS "SupplierStatus"

FROM "SupplierContacts" sc
JOIN "Suppliers" s ON sc."SupplierId" = s."Id"
WHERE sc."Email" = @Email
  AND sc."IsActive" = TRUE
  AND s."Status" = 'COMPLETED'
  AND s."IsActive" = TRUE;
```

### 8.2 User Management Queries

#### Get User Full Profile
```sql
-- Complete user profile with all roles and permissions
WITH user_roles AS (
  SELECT
    ucr."UserId",
    ucr."Id" AS "UserCompanyRoleId",
    ucr."CompanyId",
    c."ShortNameEn" AS "CompanyName",
    ucr."DepartmentId",
    d."DepartmentNameTh",
    ucr."PrimaryRoleId",
    r1."RoleCode" AS "PrimaryRoleCode",
    r1."RoleNameTh" AS "PrimaryRoleName",
    ucr."SecondaryRoleId",
    r2."RoleCode" AS "SecondaryRoleCode",
    r2."RoleNameTh" AS "SecondaryRoleName",
    ucr."ApproverLevel",
    ucr."StartDate",
    ucr."EndDate",
    ucr."IsActive"
  FROM "UserCompanyRoles" ucr
  JOIN "Companies" c ON ucr."CompanyId" = c."Id"
  LEFT JOIN "Departments" d ON ucr."DepartmentId" = d."Id"
  JOIN "Roles" r1 ON ucr."PrimaryRoleId" = r1."Id"
  LEFT JOIN "Roles" r2 ON ucr."SecondaryRoleId" = r2."Id"
  WHERE ucr."UserId" = @UserId
),
user_categories AS (
  SELECT
    ucr."UserId",
    STRING_AGG(DISTINCT c."CategoryNameTh", ', ') AS "Categories",
    STRING_AGG(DISTINCT s."SubcategoryNameTh", ', ') AS "Subcategories"
  FROM "UserCompanyRoles" ucr
  JOIN "UserCategoryBindings" ucb ON ucr."Id" = ucb."UserCompanyRoleId"
  JOIN "Categories" c ON ucb."CategoryId" = c."Id"
  LEFT JOIN "Subcategories" s ON ucb."SubcategoryId" = s."Id"
  WHERE ucr."UserId" = @UserId
    AND ucb."IsActive" = TRUE
  GROUP BY ucr."UserId"
)
SELECT
  u."Id",
  u."EmployeeCode",
  u."FirstNameTh",
  u."LastNameTh",
  u."Email",
  u."PhoneNumber",
  u."PreferredLanguage",
  u."Status",
  u."LastLoginAt",
  ur.*,
  uc."Categories",
  uc."Subcategories"
FROM "Users" u
LEFT JOIN user_roles ur ON u."Id" = ur."UserId"
LEFT JOIN user_categories uc ON u."Id" = uc."UserId"
WHERE u."Id" = @UserId;
```

#### Search Users with Filters
```sql
-- Advanced user search with multiple filters
SELECT
  u."Id",
  u."EmployeeCode",
  u."FirstNameTh" || ' ' || u."LastNameTh" AS "FullName",
  u."Email",
  u."Status",
  u."IsActive",
  STRING_AGG(DISTINCT c."ShortNameEn", ', ') AS "Companies",
  STRING_AGG(DISTINCT r."RoleNameTh", ', ') AS "Roles"
FROM "Users" u
LEFT JOIN "UserCompanyRoles" ucr ON u."Id" = ucr."UserId"
LEFT JOIN "Companies" c ON ucr."CompanyId" = c."Id"
LEFT JOIN "Roles" r ON ucr."PrimaryRoleId" = r."Id"
WHERE u."IsDeleted" = FALSE
  AND (@SearchTerm IS NULL OR
       u."EmployeeCode" ILIKE '%' || @SearchTerm || '%' OR
       u."FirstNameTh" ILIKE '%' || @SearchTerm || '%' OR
       u."LastNameTh" ILIKE '%' || @SearchTerm || '%' OR
       u."Email" ILIKE '%' || @SearchTerm || '%')
  AND (@CompanyId IS NULL OR ucr."CompanyId" = @CompanyId)
  AND (@RoleId IS NULL OR ucr."PrimaryRoleId" = @RoleId)
  AND (@Status IS NULL OR u."Status" = @Status)
GROUP BY u."Id", u."EmployeeCode", u."FirstNameTh", u."LastNameTh",
         u."Email", u."Status", u."IsActive"
ORDER BY u."CreatedAt" DESC
LIMIT @PageSize OFFSET @Offset;
```

### 8.3 Exchange Rate Queries

#### Get Effective Rate
```sql
-- Get exchange rate for specific date and currency pair
SELECT
  er."Rate",
  er."EffectiveDate",
  er."Source",
  cf."CurrencyCode" AS "FromCurrency",
  ct."CurrencyCode" AS "ToCurrency"
FROM "ExchangeRates" er
JOIN "Currencies" cf ON er."FromCurrencyId" = cf."Id"
JOIN "Currencies" ct ON er."ToCurrencyId" = ct."Id"
WHERE er."FromCurrencyId" = @FromCurrencyId
  AND er."ToCurrencyId" = @ToCurrencyId
  AND er."EffectiveDate" <= @TargetDate
  AND (er."ExpiryDate" IS NULL OR er."ExpiryDate" >= @TargetDate)
  AND er."IsActive" = TRUE
ORDER BY er."EffectiveDate" DESC
LIMIT 1;
```

#### Convert Amount Between Currencies
```sql
-- Convert amount using exchange rate
WITH rate_info AS (
  SELECT "Rate"
  FROM "ExchangeRates"
  WHERE "FromCurrencyId" = @FromCurrencyId
    AND "ToCurrencyId" = @ToCurrencyId
    AND "EffectiveDate" <= @ConversionDate
    AND "IsActive" = TRUE
  ORDER BY "EffectiveDate" DESC
  LIMIT 1
)
SELECT
  @Amount AS "OriginalAmount",
  @Amount * r."Rate" AS "ConvertedAmount",
  r."Rate" AS "ExchangeRate"
FROM rate_info r;
```

### 8.4 Supplier Category Queries

#### Get Suppliers by Category
```sql
-- Find suppliers for specific category/subcategory
SELECT DISTINCT
  s."Id",
  s."TaxId",
  s."CompanyNameTh",
  s."CompanyEmail",
  s."CompanyPhone",
  s."Status",

  -- Primary contact
  sc."FirstName" || ' ' || sc."LastName" AS "PrimaryContact",
  sc."Email" AS "ContactEmail",
  sc."MobileNumber" AS "ContactPhone"

FROM "Suppliers" s
JOIN "SupplierCategories" scat ON s."Id" = scat."SupplierId"
LEFT JOIN "SupplierContacts" sc ON s."Id" = sc."SupplierId"
  AND sc."IsPrimaryContact" = TRUE
WHERE s."Status" = 'COMPLETED'
  AND s."IsActive" = TRUE
  AND scat."IsActive" = TRUE
  AND scat."CategoryId" = @CategoryId
  AND (@SubcategoryId IS NULL OR scat."SubcategoryId" = @SubcategoryId)
ORDER BY s."CompanyNameTh";
```

---

## SECTION 9: Security & Validation Rules

### 9.1 Password Security

#### Password Complexity Requirements
- **Minimum Length**: 8 characters
- **Maximum Length**: 50 characters
- **Required Characters**:
  - At least 1 uppercase letter (A-Z)
  - At least 1 lowercase letter (a-z)
  - At least 1 digit (0-9)
  - At least 1 special character (!@#$%^&*()_+-=[]{}|;:'",.<>?/)

#### Password Hashing
- **Algorithm**: BCrypt
- **Work Factor**: 12 (recommended for 2025)
- **Salt**: Auto-generated per password

```csharp
// Hash password
var passwordHash = BCrypt.HashPassword(password, workFactor: 12);

// Verify password
var isValid = BCrypt.Verify(password, passwordHash);
```

### 9.2 Account Lockout Policy

| Condition | Action | Duration |
|-----------|--------|----------|
| 5 failed login attempts | Lock account | 30 minutes |
| Password reset requested | Invalidate all sessions | Immediate |
| Role expired | Auto-deactivate role | On expiry date |
| User deleted | Revoke all tokens | Immediate |

### 9.3 Session Management

#### JWT Token Expiry
- **Access Token**: 15 minutes
- **Refresh Token**: 7 days
- **Password Reset Token**: 1 hour

#### Security Stamp
- Generated on: Password change, role change, critical info update
- Purpose: Invalidate existing tokens
- Algorithm: GUID (Globally Unique Identifier)

### 9.4 Input Validation Rules

#### Email (Lines 4, 9, 28, 83)
```csharp
[Required]
[EmailAddress]
[MaxLength(100)]
[RegularExpression(@"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")]
public string Email { get; set; }
```

#### Employee Code (Line 25)
```csharp
[Required]
[MaxLength(50)]
[RegularExpression(@"^[A-Z0-9\-]+$", ErrorMessage = "Only uppercase letters, numbers, and hyphens allowed")]
public string EmployeeCode { get; set; }
```

#### Names (Lines 26, 27)
```csharp
[Required]
[MaxLength(100)]
[RegularExpression(@"^[\u0E00-\u0E7Fa-zA-Z\s]+$", ErrorMessage = "Only Thai and English letters allowed")]
public string FirstName { get; set; }
```

#### Password Reset Token
```csharp
[Required]
[MinLength(32)]
[MaxLength(255)]
public string Token { get; set; }
```

### 9.5 Authorization Rules

#### Role-Based Access Control (RBAC)
```csharp
// Line 7: Dashboard access based on primary role
[Authorize(Roles = "REQUESTER")]
public IActionResult RequesterDashboard() { }

[Authorize(Roles = "APPROVER")]
public IActionResult ApproverDashboard() { }

[Authorize(Roles = "PURCHASING")]
public IActionResult PurchasingDashboard() { }
```

#### Permission-Based Access Control
```csharp
// Lines 32-72: Checkboxes represent permissions
[RequirePermission("RFQ_CREATE")]  // Line 33, 54
public async Task<IActionResult> CreateRfq() { }

[RequirePermission("SUPPLIER_INVITE")]  // Line 39
public async Task<IActionResult> InviteSupplier() { }

[RequirePermission("WINNER_SELECT_FINAL")]  // Line 48
public async Task<IActionResult> SelectWinner() { }
```

---

## SECTION 10: Test Scenarios

### 10.1 Authentication Test Cases

#### Test Case 1: Internal User Login (Lines 1-7)
**Given**: Valid internal user credentials
**When**: User submits login form with email and password
**Then**:
1. System validates email exists in Users table
2. System verifies password hash matches
3. System resets AccessFailedCount to 0
4. System updates LastLoginAt timestamp
5. System generates JWT access token and refresh token
6. System inserts record in LoginHistory
7. System redirects to dashboard based on PrimaryRoleCode

**SQL Validation**:
```sql
-- Verify login was recorded
SELECT * FROM "LoginHistory"
WHERE "UserId" = @UserId
  AND "Success" = TRUE
ORDER BY "LoginAt" DESC
LIMIT 1;

-- Verify failed attempts were reset
SELECT "AccessFailedCount"
FROM "Users"
WHERE "Id" = @UserId;
-- Expected: 0

-- Verify refresh token was created
SELECT * FROM "RefreshTokens"
WHERE "UserId" = @UserId
  AND "RevokedAt" IS NULL
ORDER BY "CreatedAt" DESC
LIMIT 1;
```

#### Test Case 2: Failed Login - Invalid Password (Line 5)
**Given**: Valid email but incorrect password
**When**: User submits login form
**Then**:
1. System increments AccessFailedCount
2. If AccessFailedCount >= 5, set LockoutEnd to +30 minutes
3. System inserts failed login in LoginHistory
4. System returns error message (do not reveal if email exists)

**SQL Validation**:
```sql
-- Verify failed attempt was counted
SELECT "AccessFailedCount", "LockoutEnd"
FROM "Users"
WHERE "Email" = @Email;

-- Verify failed login was logged
SELECT * FROM "LoginHistory"
WHERE "Email" = @Email
  AND "Success" = FALSE
ORDER BY "LoginAt" DESC
LIMIT 1;
```

#### Test Case 3: Account Lockout (Security)
**Given**: User has 5 failed login attempts
**When**: User attempts to login
**Then**:
1. System checks LockoutEnd > CURRENT_TIMESTAMP
2. System rejects login attempt
3. System returns error message: "Account is locked for 30 minutes"

**SQL Validation**:
```sql
-- Check lockout status
SELECT
  "Email",
  "AccessFailedCount",
  "LockoutEnd",
  CASE
    WHEN "LockoutEnd" > CURRENT_TIMESTAMP THEN TRUE
    ELSE FALSE
  END AS "IsLocked"
FROM "Users"
WHERE "Email" = @Email;
```

#### Test Case 4: Supplier Contact Login (Lines 1-7)
**Given**: Valid supplier contact credentials
**When**: Supplier contact submits login form
**Then**:
1. System validates email in SupplierContacts table
2. System checks Supplier.Status = 'COMPLETED'
3. System verifies password hash
4. System generates JWT with audience = 'supplier'
5. System redirects to supplier dashboard

**SQL Validation**:
```sql
-- Verify supplier is approved
SELECT
  sc."Email",
  s."Status"
FROM "SupplierContacts" sc
JOIN "Suppliers" s ON sc."SupplierId" = s."Id"
WHERE sc."Email" = @Email;
-- Expected: Status = 'COMPLETED'

-- Verify login was recorded
SELECT * FROM "LoginHistory"
WHERE "ContactId" = @ContactId
  AND "UserType" = 'SupplierContact'
  AND "Success" = TRUE
ORDER BY "LoginAt" DESC
LIMIT 1;
```

### 10.2 Password Reset Test Cases

#### Test Case 5: Request Password Reset (Lines 8-10)
**Given**: User clicks "Forgot Password" link
**When**: User enters email and clicks reset button
**Then**:
1. System validates email exists (don't reveal if not)
2. System generates secure random token (32 bytes)
3. System updates PasswordResetToken and PasswordResetExpiry (+1 hour)
4. System sends email with reset link
5. System returns success message (even if email not found - security)

**SQL Validation**:
```sql
-- Verify token was saved
SELECT
  "Email",
  "PasswordResetToken",
  "PasswordResetExpiry",
  CASE
    WHEN "PasswordResetExpiry" > CURRENT_TIMESTAMP THEN TRUE
    ELSE FALSE
  END AS "IsTokenValid"
FROM "Users"
WHERE "Email" = @Email;
```

#### Test Case 6: Reset Password with Valid Token (Lines 11-14)
**Given**: User has valid reset token from email
**When**: User enters new password and confirmation
**Then**:
1. System validates token exists and not expired
2. System validates password meets complexity requirements
3. System validates password = confirmPassword
4. System updates PasswordHash (BCrypt)
5. System clears PasswordResetToken and PasswordResetExpiry
6. System generates new SecurityStamp
7. System revokes all RefreshTokens for user
8. System sends confirmation email

**SQL Validation**:
```sql
-- Verify password was updated and token cleared
SELECT
  "Email",
  "PasswordResetToken",
  "PasswordResetExpiry",
  "SecurityStamp"
FROM "Users"
WHERE "Email" = @Email;
-- Expected: PasswordResetToken = NULL, new SecurityStamp

-- Verify all tokens were revoked
SELECT COUNT(*) AS "ActiveTokens"
FROM "RefreshTokens"
WHERE "UserId" = @UserId
  AND "RevokedAt" IS NULL;
-- Expected: 0
```

#### Test Case 7: Expired Reset Token (Line 10)
**Given**: User has reset token older than 1 hour
**When**: User tries to use expired token
**Then**:
1. System validates PasswordResetExpiry < CURRENT_TIMESTAMP
2. System rejects reset attempt
3. System returns error: "Reset link has expired"

**SQL Validation**:
```sql
-- Check token expiry
SELECT
  "PasswordResetExpiry" < CURRENT_TIMESTAMP AS "IsExpired"
FROM "Users"
WHERE "Email" = @Email
  AND "PasswordResetToken" = @Token;
-- Expected: TRUE
```

### 10.3 User Management Test Cases

#### Test Case 8: Create New User (Lines 22-75)
**Given**: Admin opens "Add New User" popup
**When**: Admin fills form and clicks save
**Then**:
1. System validates all required fields (*)
2. System checks email uniqueness
3. System inserts into Users table
4. System generates temporary password
5. System inserts into UserCompanyRoles table
6. System inserts category bindings (if PURCHASING role)
7. System sends welcome email with temp password

**SQL Validation**:
```sql
-- Verify user was created
SELECT
  u."Id",
  u."EmployeeCode",
  u."Email",
  u."Status"
FROM "Users" u
WHERE u."Email" = @NewEmail;

-- Verify role was assigned
SELECT
  ucr."CompanyId",
  r."RoleCode",
  ucr."StartDate",
  ucr."EndDate"
FROM "UserCompanyRoles" ucr
JOIN "Roles" r ON ucr."PrimaryRoleId" = r."Id"
WHERE ucr."UserId" = @NewUserId;

-- Verify category bindings (for PURCHASING)
SELECT
  c."CategoryNameTh",
  s."SubcategoryNameTh"
FROM "UserCategoryBindings" ucb
JOIN "Categories" c ON ucb."CategoryId" = c."Id"
LEFT JOIN "Subcategories" s ON ucb."SubcategoryId" = s."Id"
WHERE ucb."UserCompanyRoleId" IN (
  SELECT "Id" FROM "UserCompanyRoles" WHERE "UserId" = @NewUserId
);
```

#### Test Case 9: Role with Expiry Date (Lines 73-75)
**Given**: Admin assigns role with EndDate = 2025-12-31
**When**: System runs daily scheduled job on 2026-01-01
**Then**:
1. System finds UserCompanyRoles with EndDate < CURRENT_DATE
2. System sets IsActive = FALSE
3. System sends notification to user

**SQL Validation**:
```sql
-- Find expired roles
SELECT
  u."Email",
  r."RoleNameTh",
  ucr."EndDate",
  ucr."IsActive"
FROM "UserCompanyRoles" ucr
JOIN "Users" u ON ucr."UserId" = u."Id"
JOIN "Roles" r ON ucr."PrimaryRoleId" = r."Id"
WHERE ucr."EndDate" < CURRENT_DATE;

-- Verify auto-deactivation
UPDATE "UserCompanyRoles"
SET "IsActive" = FALSE
WHERE "EndDate" < CURRENT_DATE
  AND "IsActive" = TRUE;
```

#### Test Case 10: Delete User (Line 21)
**Given**: Admin clicks delete button on user row
**When**: Admin confirms deletion
**Then**:
1. System soft deletes user (IsDeleted = TRUE)
2. System deactivates all UserCompanyRoles
3. System revokes all RefreshTokens
4. System does NOT hard delete (maintain audit trail)

**SQL Validation**:
```sql
-- Verify soft delete
SELECT
  "Email",
  "IsDeleted",
  "DeletedAt",
  "DeletedBy"
FROM "Users"
WHERE "Id" = @UserId;
-- Expected: IsDeleted = TRUE

-- Verify roles deactivated
SELECT COUNT(*) AS "ActiveRoles"
FROM "UserCompanyRoles"
WHERE "UserId" = @UserId
  AND "IsActive" = TRUE;
-- Expected: 0

-- Verify tokens revoked
SELECT COUNT(*) AS "ActiveTokens"
FROM "RefreshTokens"
WHERE "UserId" = @UserId
  AND "RevokedAt" IS NULL;
-- Expected: 0
```

### 10.4 Exchange Rate Test Cases

#### Test Case 11: Upload Exchange Rates (Line 19)
**Given**: Admin uploads CSV with monthly exchange rates
**When**: System processes file
**Then**:
1. System validates all currencies exist in Currencies table
2. System validates all rates > 0
3. System validates FromCurrency != ToCurrency
4. System deactivates existing rates for same month
5. System inserts new rates with EffectiveDate = 1st of month
6. System sets ExpiryDate = last day of month
7. System returns summary (success count, error count)

**SQL Validation**:
```sql
-- Verify rates were imported for current month
SELECT
  cf."CurrencyCode" AS "From",
  ct."CurrencyCode" AS "To",
  er."Rate",
  er."EffectiveDate",
  er."ExpiryDate",
  er."Source"
FROM "ExchangeRates" er
JOIN "Currencies" cf ON er."FromCurrencyId" = cf."Id"
JOIN "Currencies" ct ON er."ToCurrencyId" = ct."Id"
WHERE DATE_TRUNC('month', er."EffectiveDate") = DATE_TRUNC('month', CURRENT_DATE)
  AND er."IsActive" = TRUE;
-- Expected: Source = 'FILE_UPLOAD'

-- Verify old rates were deactivated
SELECT COUNT(*) AS "OldActiveRates"
FROM "ExchangeRates"
WHERE DATE_TRUNC('month', "EffectiveDate") = DATE_TRUNC('month', CURRENT_DATE)
  AND "IsActive" = TRUE
  AND "Source" != 'FILE_UPLOAD';
-- Expected: 0
```

#### Test Case 12: Get Effective Exchange Rate (Line 18)
**Given**: Supplier submits quotation on 2025-10-15
**When**: System calculates ConvertedUnitPrice
**Then**:
1. System looks up exchange rate for October 2025
2. System uses rate with EffectiveDate <= 2025-10-15
3. System applies rate to UnitPrice

**SQL Validation**:
```sql
-- Get effective rate for specific date
SELECT
  "Rate",
  "EffectiveDate"
FROM "ExchangeRates"
WHERE "FromCurrencyId" = @SupplierCurrencyId
  AND "ToCurrencyId" = @CompanyCurrencyId
  AND "EffectiveDate" <= '2025-10-15'
  AND ("ExpiryDate" IS NULL OR "ExpiryDate" >= '2025-10-15')
  AND "IsActive" = TRUE
ORDER BY "EffectiveDate" DESC
LIMIT 1;

-- Verify conversion calculation
SELECT
  @UnitPrice AS "OriginalPrice",
  @UnitPrice * er."Rate" AS "ConvertedPrice",
  er."Rate"
FROM "ExchangeRates" er
WHERE ...
```

### 10.5 Supplier Category Test Cases

#### Test Case 13: Update Supplier Categories (Lines 86-94)
**Given**: Admin opens Edit Category popup for Supplier A
**When**: Admin adds multiple categories with subcategories
**Then**:
1. System deactivates all existing SupplierCategories
2. System inserts new category assignments
3. System supports multiple subcategories per category
4. System updates primary contact email if changed

**SQL Validation**:
```sql
-- Verify categories were updated
SELECT
  c."CategoryNameTh",
  s."SubcategoryNameTh"
FROM "SupplierCategories" sc
JOIN "Categories" c ON sc."CategoryId" = c."Id"
LEFT JOIN "Subcategories" s ON sc."SubcategoryId" = s."Id"
WHERE sc."SupplierId" = @SupplierId
  AND sc."IsActive" = TRUE
ORDER BY c."SortOrder", s."SortOrder";

-- Expected result matches Lines 90-94:
-- บริการด้านเทคโนโลยี | ไอที/ คอมพิวเตอร์และอุปกรณ์
-- บริการด้านเทคโนโลยี | อุปกรณ์ต่อพ่วงคอมพิวเตอร์
-- บริการด้านเทคโนโลยี | บริการให้คำปรึกษาและพัฒนาระบบซอฟต์แวร์
-- เครื่องจักรการพิมพ์ | เครื่องพิมพ์เลเซอร์
-- เครื่องจักรการพิมพ์ | เครื่องพิมพ์ดิจิทัล
```

#### Test Case 14: Search Suppliers by Category (Line 78)
**Given**: Admin searches for "เทคโนโลยี" in search box
**When**: System performs search
**Then**:
1. System searches across TaxId, CompanyName, Contact names, Phone, Email
2. System also searches in Category and Subcategory names
3. System returns matching suppliers

**SQL Validation**:
```sql
-- Search test
SELECT
  s."CompanyNameTh",
  STRING_AGG(DISTINCT c."CategoryNameTh", ', ') AS "Categories"
FROM "Suppliers" s
LEFT JOIN "SupplierCategories" scat ON s."Id" = scat."SupplierId"
LEFT JOIN "Categories" c ON scat."CategoryId" = c."Id"
WHERE s."IsActive" = TRUE
  AND (
    s."CompanyNameTh" ILIKE '%เทคโนโลยี%' OR
    c."CategoryNameTh" ILIKE '%เทคโนโลยี%'
  )
GROUP BY s."Id", s."CompanyNameTh";
```

---

## Summary

This document provides **100% coverage** of all 94 lines in `00_SignIn_and_Admin.txt`, mapped to database schema v6.2.2. Every business requirement has been analyzed and documented with:

✅ **Complete line-by-line mapping**
✅ **Database schema fields**
✅ **SQL query templates**
✅ **Validation rules**
✅ **Security best practices**
✅ **Comprehensive test scenarios**

### Key Features Covered:

1. **Authentication System** (Lines 1-14)
   - Internal user login with JWT
   - Supplier contact login
   - Password reset flow
   - Account lockout after 5 failed attempts
   - Session management with refresh tokens

2. **User Management** (Lines 17-75)
   - Create/edit/delete users
   - Role assignments (primary + secondary)
   - Permission checkboxes for all 8 roles
   - Category bindings for PURCHASING
   - Role expiry date management

3. **Exchange Rate Management** (Lines 18-19)
   - Monthly exchange rate upload
   - File import (CSV/Excel)
   - Currency conversion logic
   - Historical rate tracking

4. **Supplier Category Management** (Lines 77-94)
   - Category and subcategory assignment
   - Multiple categories per supplier
   - Search and filter functionality
   - Primary contact email update

### Database Tables Used:
- Users, SupplierContacts
- LoginHistory, RefreshTokens
- UserCompanyRoles, Roles, RolePermissions
- UserCategoryBindings
- Suppliers, SupplierCategories
- ExchangeRates, Currencies
- Categories, Subcategories

**Total Lines Mapped**: 94/94 (100%)

---

**End of Document**