# 📋 Application Implementation Guide - Action Items

**Version:** 1.0
**Date:** 2025-09-30
**Schema Version:** v6.2.2
**Purpose:** Detailed implementation guide for application-level logic that complements database schema

---

## 🎯 Overview

Database Schema v6.2.2 รองรับ Business Requirements ครบ 100% แล้ว แต่ยังต้อง **implement application logic** ต่อไปนี้:

### Coverage Summary

| Module | Schema Ready | Application Tasks | Priority |
|--------|--------------|-------------------|----------|
| Authentication & Password Reset | ✅ 100% | 4 tasks | HIGH |
| User Management | ✅ 100% | 3 tasks | HIGH |
| Exchange Rate Management | ✅ 100% | 2 tasks | MEDIUM |
| Requester Workflow | ✅ 100% | 7 tasks | HIGH |
| Approver Workflow | ✅ 100% | 4 tasks | HIGH |
| Purchasing Assignment | ✅ 100% | 2 tasks | HIGH |

---

## 📑 Table of Contents

1. [Authentication & Password Reset](#1-authentication--password-reset)
2. [User Management](#2-user-management)
3. [Exchange Rate Management](#3-exchange-rate-management)
4. [Requester Workflow](#4-requester-workflow)
5. [Approver Workflow](#5-approver-workflow)
6. [Purchasing Assignment](#6-purchasing-assignment)
7. [Scheduled Jobs (Wolverine)](#7-scheduled-jobs-wolverine)
8. [Email & Notification Templates](#8-email--notification-templates)

---

## 1. Authentication & Password Reset

### 1.1 Password Reset Token Generation

**Priority:** HIGH
**Estimated Effort:** 2 hours
**Dependencies:** Email service (SendGrid)

**Business Requirement:**
> 00_SignIn_and_Admin.txt Lines 8-14: ลืมรหัสผ่าน → ส่งอีเมล์ → กรอกรหัสผ่านใหม่

**Schema Support:**
```sql
-- Users table (Lines 356-357)
"PasswordResetToken" VARCHAR(255)
"PasswordResetExpiry" TIMESTAMP
```

**Implementation:**

```csharp
// Services/AuthenticationService.cs
public class AuthenticationService : IAuthenticationService
{
    private readonly ErfxDbContext _writeDb;
    private readonly IEmailService _emailService;
    private readonly IConfiguration _config;

    public async Task<Result> SendPasswordResetEmailAsync(string email)
    {
        // 1. Find user by email
        var user = await _writeDb.Users
            .Where(u => u.Email == email && u.IsActive)
            .FirstOrDefaultAsync();

        if (user == null)
        {
            // Security: Don't reveal if email exists
            return Result.Success("If email exists, reset link has been sent");
        }

        // 2. Generate secure token
        var token = Convert.ToBase64String(RandomNumberGenerator.GetBytes(32));
        var expiry = DateTime.UtcNow.AddHours(1); // 1 hour expiry

        // 3. Update user record
        user.PasswordResetToken = token;
        user.PasswordResetExpiry = expiry;
        user.SecurityStamp = Guid.NewGuid().ToString(); // Invalidate existing sessions
        user.UpdatedAt = DateTime.UtcNow;

        await _writeDb.SaveChangesAsync();

        // 4. Send email
        var resetLink = $"{_config["AppUrl"]}/reset-password?token={token}&email={Uri.EscapeDataString(email)}";
        await _emailService.SendPasswordResetEmailAsync(email, user.FirstNameTh, resetLink);

        return Result.Success("If email exists, reset link has been sent");
    }

    public async Task<Result> ResetPasswordAsync(string email, string token, string newPassword)
    {
        // 1. Validate token
        var user = await _writeDb.Users
            .Where(u => u.Email == email
                && u.PasswordResetToken == token
                && u.PasswordResetExpiry > DateTime.UtcNow
                && u.IsActive)
            .FirstOrDefaultAsync();

        if (user == null)
        {
            return Result.Failure("Invalid or expired reset token");
        }

        // 2. Validate password strength
        var passwordValidation = ValidatePasswordStrength(newPassword);
        if (!passwordValidation.IsSuccess)
        {
            return passwordValidation;
        }

        // 3. Hash new password
        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(newPassword);
        user.PasswordResetToken = null;
        user.PasswordResetExpiry = null;
        user.SecurityStamp = Guid.NewGuid().ToString(); // Invalidate existing sessions
        user.UpdatedAt = DateTime.UtcNow;
        user.AccessFailedCount = 0; // Reset failed attempts
        user.LockoutEnd = null; // Remove lockout

        await _writeDb.SaveChangesAsync();

        return Result.Success("Password reset successfully");
    }

    private Result ValidatePasswordStrength(string password)
    {
        if (password.Length < 8)
            return Result.Failure("Password must be at least 8 characters");

        if (!password.Any(char.IsUpper))
            return Result.Failure("Password must contain at least one uppercase letter");

        if (!password.Any(char.IsDigit))
            return Result.Failure("Password must contain at least one number");

        return Result.Success();
    }
}
```

**Email Template:**
```html
<!-- EmailTemplates/PasswordReset.html -->
<html>
<body>
    <h2>รีเซ็ตรหัสผ่าน / Reset Password</h2>
    <p>สวัสดีคุณ {{FirstName}},</p>
    <p>คุณได้ทำการขอรีเซ็ตรหัสผ่าน กรุณาคลิกลิงก์ด้านล่างเพื่อตั้งรหัสผ่านใหม่:</p>
    <p><a href="{{ResetLink}}">รีเซ็ตรหัสผ่าน / Reset Password</a></p>
    <p>ลิงก์นี้จะหมดอายุใน 1 ชั่วโมง</p>
    <p>ถ้าคุณไม่ได้ทำการขอรีเซ็ตรหัสผ่าน กรุณาเพิกเฉยอีเมล์นี้</p>
</body>
</html>
```

---

### 1.2 Account Lockout After Failed Login Attempts

**Priority:** HIGH
**Estimated Effort:** 1 hour
**Dependencies:** None

**Schema Support:**
```sql
-- Users table (Lines 360-362)
"LockoutEnabled" BOOLEAN DEFAULT TRUE
"LockoutEnd" TIMESTAMP WITH TIME ZONE
"AccessFailedCount" INT DEFAULT 0
```

**Implementation:**

```csharp
// Services/AuthenticationService.cs
public async Task<Result<LoginResponse>> LoginAsync(LoginRequest request)
{
    var user = await _writeDb.Users
        .Include(u => u.UserCompanyRoles)
        .Where(u => u.Email == request.Email && u.IsActive)
        .FirstOrDefaultAsync();

    if (user == null)
    {
        return Result<LoginResponse>.Failure("Invalid email or password");
    }

    // Check lockout
    if (user.LockoutEnabled && user.LockoutEnd.HasValue && user.LockoutEnd > DateTimeOffset.UtcNow)
    {
        var lockoutMinutes = (user.LockoutEnd.Value - DateTimeOffset.UtcNow).TotalMinutes;
        return Result<LoginResponse>.Failure($"Account locked. Try again in {Math.Ceiling(lockoutMinutes)} minutes");
    }

    // Verify password
    if (!BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
    {
        // Increment failed count
        user.AccessFailedCount++;

        // Lockout after 5 failed attempts
        if (user.AccessFailedCount >= 5)
        {
            user.LockoutEnd = DateTimeOffset.UtcNow.AddMinutes(30); // 30 minutes lockout
            user.AccessFailedCount = 0; // Reset counter
            await _writeDb.SaveChangesAsync();

            return Result<LoginResponse>.Failure("Account locked due to multiple failed attempts. Try again in 30 minutes");
        }

        await _writeDb.SaveChangesAsync();
        return Result<LoginResponse>.Failure($"Invalid email or password. {5 - user.AccessFailedCount} attempts remaining");
    }

    // Successful login - reset counters
    user.AccessFailedCount = 0;
    user.LockoutEnd = null;
    user.LastLoginAt = DateTime.UtcNow;
    await _writeDb.SaveChangesAsync();

    // Generate JWT token
    var token = await _jwtService.GenerateTokenAsync(user);

    // Log login history (via event)
    await _eventBus.PublishAsync(new UserLoggedInEvent
    {
        UserId = user.Id,
        IpAddress = request.IpAddress,
        UserAgent = request.UserAgent
    });

    return Result<LoginResponse>.Success(new LoginResponse
    {
        Token = token,
        RefreshToken = await GenerateRefreshTokenAsync(user)
    });
}
```

---

### 1.3 Login History Tracking (Event-Driven)

**Priority:** MEDIUM
**Estimated Effort:** 1 hour
**Dependencies:** Wolverine event bus

**Schema Support:**
```sql
-- LoginHistory table (Lines 1023-1046)
CREATE TABLE "LoginHistory" (...)
```

**Implementation:**

```csharp
// Events/UserLoggedInEvent.cs
public record UserLoggedInEvent : IEvent
{
    public long UserId { get; init; }
    public string IpAddress { get; init; }
    public string UserAgent { get; init; }
}

// EventHandlers/UserLoggedInEventHandler.cs
public class UserLoggedInEventHandler : IEventHandler<UserLoggedInEvent>
{
    private readonly ErfxDbContext _writeDb;

    public async Task HandleAsync(UserLoggedInEvent @event, CancellationToken ct)
    {
        var loginHistory = new LoginHistory
        {
            UserId = @event.UserId,
            LoginAt = DateTime.UtcNow,
            IpAddress = @event.IpAddress,
            UserAgent = @event.UserAgent,
            LoginMethod = "EMAIL_PASSWORD",
            IsSuccessful = true
        };

        _writeDb.LoginHistory.Add(loginHistory);
        await _writeDb.SaveChangesAsync(ct);
    }
}
```

---

### 1.4 Email Verification

**Priority:** MEDIUM
**Estimated Effort:** 1.5 hours
**Dependencies:** Email service

**Schema Support:**
```sql
-- Users table (Lines 354-355)
"IsEmailVerified" BOOLEAN DEFAULT FALSE
"EmailVerifiedAt" TIMESTAMP
```

**Implementation:**

```csharp
public async Task<Result> SendEmailVerificationAsync(long userId)
{
    var user = await _writeDb.Users.FindAsync(userId);
    if (user == null || user.IsEmailVerified)
        return Result.Failure("Invalid request");

    var token = Convert.ToBase64String(RandomNumberGenerator.GetBytes(32));
    user.PasswordResetToken = token; // Reuse field for verification
    user.PasswordResetExpiry = DateTime.UtcNow.AddHours(24);
    await _writeDb.SaveChangesAsync();

    var verifyLink = $"{_config["AppUrl"]}/verify-email?token={token}&userId={userId}";
    await _emailService.SendEmailVerificationAsync(user.Email, user.FirstNameTh, verifyLink);

    return Result.Success();
}

public async Task<Result> VerifyEmailAsync(long userId, string token)
{
    var user = await _writeDb.Users
        .Where(u => u.Id == userId
            && u.PasswordResetToken == token
            && u.PasswordResetExpiry > DateTime.UtcNow)
        .FirstOrDefaultAsync();

    if (user == null)
        return Result.Failure("Invalid or expired verification token");

    user.IsEmailVerified = true;
    user.EmailVerifiedAt = DateTime.UtcNow;
    user.PasswordResetToken = null;
    user.PasswordResetExpiry = null;
    await _writeDb.SaveChangesAsync();

    return Result.Success("Email verified successfully");
}
```

---

## 2. User Management

### 2.1 Permission Seed Data & Role Mapping

**Priority:** HIGH (CRITICAL)
**Estimated Effort:** 3 hours
**Dependencies:** Master data seeding

**Business Requirement:**
> 00_SignIn_and_Admin.txt Lines 31-72: Permission checkboxes per role

**Schema Support:**
```sql
-- Permissions table (Lines 116-124)
-- RolePermissions table (Lines 128-140)
```

**Permission Codes Required:**

Based on Business Documentation analysis, the following permission codes must be seeded:

```sql
-- Master Data: Permissions
INSERT INTO "Permissions" ("PermissionCode", "PermissionName", "PermissionNameTh", "Module", "IsActive") VALUES
-- RFQ Module
('RFQ_CREATE', 'Create RFQ', 'สร้างใบขอราคา', 'RFQ', TRUE),
('RFQ_UPDATE', 'Update RFQ', 'แก้ไขใบขอราคา', 'RFQ', TRUE),
('RFQ_READ', 'View RFQ', 'ดูใบขอราคา', 'RFQ', TRUE),
('RFQ_DELETE', 'Delete RFQ', 'ลบใบขอราคา', 'RFQ', TRUE),

-- Approval Module
('RFQ_APPROVE', 'Approve RFQ', 'อนุมัติใบขอราคา', 'APPROVAL', TRUE),
('RFQ_DECLINE', 'Decline RFQ', 'Decline ใบขอราคา', 'APPROVAL', TRUE),
('RFQ_REJECT', 'Reject RFQ', 'Reject ใบขอราคา', 'APPROVAL', TRUE),

-- Purchasing Module
('SUPPLIER_INVITE', 'Invite Supplier', 'เชิญ Supplier', 'PURCHASING', TRUE),
('SUPPLIER_PRE_APPROVE', 'Pre-approve Supplier', 'ตรวจสอบข้อมูล Supplier', 'PURCHASING', TRUE),
('PURCHASING_INSERT', 'Insert Purchasing Data', 'เพิ่มข้อมูล', 'PURCHASING', TRUE),
('PURCHASING_CONSIDER', 'Consider Quotation', 'ตัดสินใจ', 'PURCHASING', TRUE),
('WINNER_FIRST_SELECT', 'First Winner Selection', 'เลือกผู้ชนะเบื้องต้น', 'PURCHASING', TRUE),

-- Purchasing Approver Module
('WINNER_FINAL_SELECT', 'Final Winner Selection', 'เลือกผู้ชนะสุดท้าย', 'PURCHASING_APPROVER', TRUE),
('SUPPLIER_APPROVE', 'Approve Supplier', 'อนุมัติ Supplier ใหม่', 'PURCHASING_APPROVER', TRUE),

-- Supplier Module
('QUOTATION_CREATE', 'Create Quotation', 'สร้างใบเสนอราคา', 'SUPPLIER', TRUE),
('QUOTATION_UPDATE', 'Update Quotation', 'แก้ไขใบเสนอราคา', 'SUPPLIER', TRUE),

-- Dashboard Module
('DASHBOARD_EXECUTIVE', 'Executive Dashboard', 'Dashboard สรุปผู้บริหาร', 'DASHBOARD', TRUE),
('DASHBOARD_REQUESTER', 'Requester Dashboard', 'Dashboard ผู้ร้องขอ', 'DASHBOARD', TRUE),
('DASHBOARD_APPROVER', 'Approver Dashboard', 'Dashboard ผู้อนุมัติ', 'DASHBOARD', TRUE),
('DASHBOARD_PURCHASING', 'Purchasing Dashboard', 'Dashboard จัดซื้อ', 'DASHBOARD', TRUE),
('DASHBOARD_SUPPLIER', 'Supplier Dashboard', 'Dashboard Supplier', 'DASHBOARD', TRUE),

-- Admin Module
('USER_MANAGE', 'Manage Users', 'จัดการผู้ใช้', 'ADMIN', TRUE),
('CATEGORY_MANAGE', 'Manage Categories', 'จัดการหมวดหมู่', 'ADMIN', TRUE),
('SUPPLIER_MANAGE', 'Manage Suppliers', 'จัดการ Supplier', 'ADMIN', TRUE),
('EXCHANGE_RATE_UPDATE', 'Update Exchange Rate', 'อัปเดตอัตราแลกเปลี่ยน', 'ADMIN', TRUE);
```

**Role-Permission Mapping:**

```sql
-- Map Permissions to Roles
-- REQUESTER (Create, Update)
INSERT INTO "RolePermissions" ("RoleId", "PermissionId")
SELECT r."Id", p."Id"
FROM "Roles" r, "Permissions" p
WHERE r."RoleCode" = 'REQUESTER'
  AND p."PermissionCode" IN ('RFQ_CREATE', 'RFQ_UPDATE', 'RFQ_READ', 'DASHBOARD_REQUESTER');

-- APPROVER (Consider/Approve)
INSERT INTO "RolePermissions" ("RoleId", "PermissionId")
SELECT r."Id", p."Id"
FROM "Roles" r, "Permissions" p
WHERE r."RoleCode" = 'APPROVER'
  AND p."PermissionCode" IN ('RFQ_APPROVE', 'RFQ_DECLINE', 'RFQ_REJECT', 'RFQ_READ', 'DASHBOARD_APPROVER');

-- PURCHASING (Read, Invite, Insert, Consider, Pre-approve, First Select Winner)
INSERT INTO "RolePermissions" ("RoleId", "PermissionId")
SELECT r."Id", p."Id"
FROM "Roles" r, "Permissions" p
WHERE r."RoleCode" = 'PURCHASING'
  AND p."PermissionCode" IN ('RFQ_READ', 'SUPPLIER_INVITE', 'PURCHASING_INSERT',
      'PURCHASING_CONSIDER', 'SUPPLIER_PRE_APPROVE', 'WINNER_FIRST_SELECT', 'DASHBOARD_PURCHASING');

-- PURCHASING_APPROVER (Final Winner, Approve Supplier)
INSERT INTO "RolePermissions" ("RoleId", "PermissionId")
SELECT r."Id", p."Id"
FROM "Roles" r, "Permissions" p
WHERE r."RoleCode" = 'PURCHASING_APPROVER'
  AND p."PermissionCode" IN ('WINNER_FINAL_SELECT', 'SUPPLIER_APPROVE', 'RFQ_READ', 'DASHBOARD_PURCHASING');

-- SUPPLIER (Create, Update Quotation)
INSERT INTO "RolePermissions" ("RoleId", "PermissionId")
SELECT r."Id", p."Id"
FROM "Roles" r, "Permissions" p
WHERE r."RoleCode" = 'SUPPLIER'
  AND p."PermissionCode" IN ('QUOTATION_CREATE', 'QUOTATION_UPDATE', 'DASHBOARD_SUPPLIER');

-- MANAGING_DIRECTOR (Dashboard summary executive)
INSERT INTO "RolePermissions" ("RoleId", "PermissionId")
SELECT r."Id", p."Id"
FROM "Roles" r, "Permissions" p
WHERE r."RoleCode" = 'MANAGING_DIRECTOR'
  AND p."PermissionCode" IN ('DASHBOARD_EXECUTIVE');

-- ADMIN (All management)
INSERT INTO "RolePermissions" ("RoleId", "PermissionId")
SELECT r."Id", p."Id"
FROM "Roles" r, "Permissions" p
WHERE r."RoleCode" = 'ADMIN'
  AND p."PermissionCode" IN ('USER_MANAGE', 'CATEGORY_MANAGE', 'SUPPLIER_MANAGE', 'EXCHANGE_RATE_UPDATE');
```

---

### 2.2 Role Conflict Validation

**Priority:** HIGH
**Estimated Effort:** 1 hour
**Dependencies:** None

**Business Requirement:**
> Database Schema Lines 403-408: Role conflict rules

**Schema Support:**
```sql
-- UserCompanyRoles CHECK constraint
CONSTRAINT "chk_role_rules" CHECK (
  NOT (
    ("PrimaryRoleId" = 3 AND "SecondaryRoleId" = 4) OR
    ("PrimaryRoleId" = 4 AND "SecondaryRoleId" = 3) OR
    ("PrimaryRoleId" = 3 AND "SecondaryRoleId" = 5)
  )
)
```

**Implementation:**

```csharp
// Validators/UserRoleValidator.cs
public class UserRoleValidator
{
    private readonly ErfxDbContext _db;

    public async Task<Result> ValidateRoleAssignmentAsync(UserRoleRequest request)
    {
        // Get role codes
        var primaryRole = await _db.Roles.FindAsync(request.PrimaryRoleId);
        var secondaryRole = request.SecondaryRoleId.HasValue
            ? await _db.Roles.FindAsync(request.SecondaryRoleId.Value)
            : null;

        // Rule 1: PURCHASING + APPROVER conflict
        if ((primaryRole.RoleCode == "PURCHASING" && secondaryRole?.RoleCode == "APPROVER") ||
            (primaryRole.RoleCode == "APPROVER" && secondaryRole?.RoleCode == "PURCHASING"))
        {
            return Result.Failure("PURCHASING and APPROVER roles cannot be combined");
        }

        // Rule 2: PURCHASING + PURCHASING_APPROVER conflict
        if ((primaryRole.RoleCode == "PURCHASING" && secondaryRole?.RoleCode == "PURCHASING_APPROVER") ||
            (primaryRole.RoleCode == "PURCHASING_APPROVER" && secondaryRole?.RoleCode == "PURCHASING"))
        {
            return Result.Failure("PURCHASING and PURCHASING_APPROVER roles cannot be combined");
        }

        // Rule 3: APPROVER must have DepartmentId
        if (primaryRole.RoleCode == "APPROVER" && !request.DepartmentId.HasValue)
        {
            return Result.Failure("APPROVER role requires Department assignment");
        }

        // Rule 4: APPROVER must have ApproverLevel
        if (primaryRole.RoleCode == "APPROVER" && !request.ApproverLevel.HasValue)
        {
            return Result.Failure("APPROVER role requires ApproverLevel (1-3)");
        }

        // Rule 5: PURCHASING_APPROVER must have Categories
        if (primaryRole.RoleCode == "PURCHASING_APPROVER" &&
            (request.CategoryBindings == null || !request.CategoryBindings.Any()))
        {
            return Result.Failure("PURCHASING_APPROVER role requires at least one Category binding");
        }

        // Rule 6: Check duplicate ApproverLevel per Department
        if (primaryRole.RoleCode == "APPROVER" && request.ApproverLevel.HasValue)
        {
            var duplicateLevel = await _db.UserCompanyRoles
                .Where(ucr => ucr.CompanyId == request.CompanyId
                    && ucr.DepartmentId == request.DepartmentId
                    && ucr.ApproverLevel == request.ApproverLevel
                    && ucr.UserId != request.UserId  // Exclude self when editing
                    && ucr.IsActive
                    && (ucr.EndDate == null || ucr.EndDate > DateTime.Today))
                .AnyAsync();

            if (duplicateLevel)
            {
                return Result.Failure($"ApproverLevel {request.ApproverLevel} already assigned to another user in this department");
            }
        }

        return Result.Success();
    }
}
```

---

### 2.3 Dynamic Permission Checkboxes (UI Logic)

**Priority:** MEDIUM
**Estimated Effort:** 2 hours
**Dependencies:** Frontend framework

**Implementation (React/TypeScript example):**

```typescript
// components/UserForm/PermissionCheckboxes.tsx
import React, { useEffect, useState } from 'react';

interface Permission {
  code: string;
  name: string;
  nameTh: string;
  module: string;
}

interface PermissionCheckboxesProps {
  selectedRoleCode: string;
  value: string[];
  onChange: (permissions: string[]) => void;
}

export const PermissionCheckboxes: React.FC<PermissionCheckboxesProps> = ({
  selectedRoleCode,
  value,
  onChange
}) => {
  const [availablePermissions, setAvailablePermissions] = useState<Permission[]>([]);

  useEffect(() => {
    // Fetch permissions for selected role
    const fetchPermissions = async () => {
      const response = await fetch(`/api/permissions/by-role/${selectedRoleCode}`);
      const permissions = await response.json();
      setAvailablePermissions(permissions);
    };

    if (selectedRoleCode) {
      fetchPermissions();
    }
  }, [selectedRoleCode]);

  const handleToggle = (permissionCode: string) => {
    const newValue = value.includes(permissionCode)
      ? value.filter(p => p !== permissionCode)
      : [...value, permissionCode];
    onChange(newValue);
  };

  if (!selectedRoleCode) {
    return <div>กรุณาเลือก Role ก่อน</div>;
  }

  return (
    <div className="permission-checkboxes">
      <h4>สิทธิ์การใช้งาน / Permissions</h4>
      {availablePermissions.map(permission => (
        <div key={permission.code} className="checkbox-item">
          <label>
            <input
              type="checkbox"
              checked={value.includes(permission.code)}
              onChange={() => handleToggle(permission.code)}
            />
            <span>{permission.nameTh} / {permission.name}</span>
          </label>
        </div>
      ))}
    </div>
  );
};
```

---

## 3. Exchange Rate Management

### 3.1 Exchange Rate File Upload & Parsing

**Priority:** MEDIUM
**Estimated Effort:** 3 hours
**Dependencies:** File upload service, Excel parser

**Business Requirement:**
> 00_SignIn_and_Admin.txt Line 19: อัพโหลดไฟล์ อัตราแลกเปลี่ยนประจำเดือน

**Schema Support:**
```sql
-- ExchangeRates table (Lines 1002-1025)
-- ExchangeRateHistory table (Lines 1027-1037)
```

**Expected File Format (CSV/Excel):**
```
FromCurrency,ToCurrency,Rate,EffectiveDate
USD,THB,35.50,2025-01-01
EUR,THB,39.20,2025-01-01
JPY,THB,0.25,2025-01-01
```

**Implementation:**

```csharp
// Services/ExchangeRateService.cs
public class ExchangeRateService : IExchangeRateService
{
    private readonly ErfxDbContext _writeDb;
    private readonly IFileUploadService _fileUpload;
    private readonly ICurrentUserService _currentUser;

    public async Task<Result<ExchangeRateUploadResult>> UploadExchangeRatesAsync(
        IFormFile file,
        CancellationToken ct)
    {
        // 1. Validate file
        if (!IsValidExchangeRateFile(file))
        {
            return Result<ExchangeRateUploadResult>.Failure(
                "Invalid file format. Only CSV or Excel files are accepted"
            );
        }

        // 2. Parse file
        var rates = await ParseExchangeRateFileAsync(file);
        if (rates.Count == 0)
        {
            return Result<ExchangeRateUploadResult>.Failure("No valid rates found in file");
        }

        // 3. Validate rates
        var validation = ValidateExchangeRates(rates);
        if (!validation.IsSuccess)
        {
            return Result<ExchangeRateUploadResult>.Failure(validation.Error);
        }

        // 4. Get currencies mapping
        var currencyCodes = rates.SelectMany(r => new[] { r.FromCurrency, r.ToCurrency }).Distinct();
        var currencies = await _writeDb.Currencies
            .Where(c => currencyCodes.Contains(c.CurrencyCode))
            .ToDictionaryAsync(c => c.CurrencyCode, c => c.Id);

        // 5. Process rates (upsert)
        using var transaction = await _writeDb.Database.BeginTransactionAsync(ct);

        int inserted = 0, updated = 0;
        var userId = _currentUser.UserId;

        foreach (var rate in rates)
        {
            var fromCurrencyId = currencies[rate.FromCurrency];
            var toCurrencyId = currencies[rate.ToCurrency];

            // Check if rate exists
            var existingRate = await _writeDb.ExchangeRates
                .Where(er => er.FromCurrencyId == fromCurrencyId
                    && er.ToCurrencyId == toCurrencyId
                    && er.EffectiveDate == rate.EffectiveDate)
                .FirstOrDefaultAsync(ct);

            if (existingRate != null)
            {
                // Update existing rate
                var oldRate = existingRate.Rate;
                existingRate.Rate = rate.Rate;
                existingRate.UpdatedAt = DateTime.UtcNow;
                existingRate.UpdatedBy = userId;

                // Log history
                _writeDb.ExchangeRateHistory.Add(new ExchangeRateHistory
                {
                    ExchangeRateId = existingRate.Id,
                    OldRate = oldRate,
                    NewRate = rate.Rate,
                    ChangedBy = userId,
                    ChangedAt = DateTime.UtcNow,
                    ChangeReason = "Monthly rate update via file upload"
                });

                updated++;
            }
            else
            {
                // Insert new rate
                _writeDb.ExchangeRates.Add(new ExchangeRate
                {
                    FromCurrencyId = fromCurrencyId,
                    ToCurrencyId = toCurrencyId,
                    Rate = rate.Rate,
                    EffectiveDate = rate.EffectiveDate,
                    ExpiryDate = rate.EffectiveDate.AddMonths(1).AddDays(-1), // End of month
                    Source = "MANUAL",
                    SourceReference = file.FileName,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                    CreatedBy = userId
                });

                inserted++;
            }
        }

        await _writeDb.SaveChangesAsync(ct);
        await transaction.CommitAsync(ct);

        return Result<ExchangeRateUploadResult>.Success(new ExchangeRateUploadResult
        {
            TotalProcessed = rates.Count,
            Inserted = inserted,
            Updated = updated,
            FileName = file.FileName
        });
    }

    private async Task<List<ExchangeRateDto>> ParseExchangeRateFileAsync(IFormFile file)
    {
        var rates = new List<ExchangeRateDto>();

        if (file.FileName.EndsWith(".csv", StringComparison.OrdinalIgnoreCase))
        {
            using var reader = new StreamReader(file.OpenReadStream());
            using var csv = new CsvReader(reader, CultureInfo.InvariantCulture);
            rates = csv.GetRecords<ExchangeRateDto>().ToList();
        }
        else if (file.FileName.EndsWith(".xlsx", StringComparison.OrdinalIgnoreCase))
        {
            using var stream = file.OpenReadStream();
            using var package = new ExcelPackage(stream);
            var worksheet = package.Workbook.Worksheets[0];

            // Skip header row (row 1)
            for (int row = 2; row <= worksheet.Dimension.Rows; row++)
            {
                rates.Add(new ExchangeRateDto
                {
                    FromCurrency = worksheet.Cells[row, 1].Text,
                    ToCurrency = worksheet.Cells[row, 2].Text,
                    Rate = decimal.Parse(worksheet.Cells[row, 3].Text),
                    EffectiveDate = DateTime.Parse(worksheet.Cells[row, 4].Text)
                });
            }
        }

        return rates;
    }

    private Result ValidateExchangeRates(List<ExchangeRateDto> rates)
    {
        // Check for duplicate currency pairs on same date
        var duplicates = rates
            .GroupBy(r => new { r.FromCurrency, r.ToCurrency, r.EffectiveDate })
            .Where(g => g.Count() > 1)
            .Select(g => $"{g.Key.FromCurrency}/{g.Key.ToCurrency} on {g.Key.EffectiveDate:yyyy-MM-dd}")
            .ToList();

        if (duplicates.Any())
        {
            return Result.Failure($"Duplicate rates found: {string.Join(", ", duplicates)}");
        }

        // Validate rate values
        var invalidRates = rates.Where(r => r.Rate <= 0).ToList();
        if (invalidRates.Any())
        {
            return Result.Failure("All exchange rates must be greater than zero");
        }

        return Result.Success();
    }

    private bool IsValidExchangeRateFile(IFormFile file)
    {
        var allowedExtensions = new[] { ".csv", ".xlsx" };
        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        return allowedExtensions.Contains(extension) && file.Length > 0;
    }
}
```

---

### 3.2 Temporal Exchange Rate Lookup

**Priority:** HIGH
**Estimated Effort:** 1 hour
**Dependencies:** None

**Business Requirement:**
> Exchange rates locked at quotation submission time

**Implementation:**

```csharp
// Services/ExchangeRateService.cs
public async Task<decimal?> GetExchangeRateAtDateAsync(
    long fromCurrencyId,
    long toCurrencyId,
    DateTime transactionDate)
{
    // Get exchange rate effective at transaction date
    var rate = await _readDb.QueryFirstOrDefaultAsync<decimal?>(
        @"SELECT er.""Rate""
          FROM ""ExchangeRates"" er
          WHERE er.""FromCurrencyId"" = @FromCurrencyId
            AND er.""ToCurrencyId"" = @ToCurrencyId
            AND er.""EffectiveDate"" <= @TransactionDate
            AND (er.""ExpiryDate"" IS NULL OR er.""ExpiryDate"" > @TransactionDate)
            AND er.""IsActive"" = TRUE
          ORDER BY er.""EffectiveDate"" DESC
          LIMIT 1",
        new { FromCurrencyId = fromCurrencyId, ToCurrencyId = toCurrencyId, TransactionDate = transactionDate }
    );

    return rate;
}

// Audit query to verify rate used at submission time
public async Task<ExchangeRateAuditResult> VerifyQuotationExchangeRateAsync(long quotationItemId)
{
    var result = await _readDb.QueryFirstOrDefaultAsync<ExchangeRateAuditResult>(
        @"SELECT
            qi.""Id"" AS ""QuotationItemId"",
            qi.""UnitPrice"",
            qi.""CurrencyId"",
            qi.""ConvertedUnitPrice"",
            qi.""SubmittedAt"",
            er.""Rate"" AS ""RateUsedAtSubmission"",
            (qi.""UnitPrice"" * er.""Rate"") AS ""CalculatedPrice"",
            CASE
              WHEN ABS(qi.""ConvertedUnitPrice"" - (qi.""UnitPrice"" * er.""Rate"")) < 0.01
              THEN TRUE
              ELSE FALSE
            END AS ""IsCorrect""
          FROM ""QuotationItems"" qi
          JOIN ""ExchangeRates"" er
            ON er.""FromCurrencyId"" = qi.""CurrencyId""
            AND er.""EffectiveDate"" <= DATE(qi.""SubmittedAt"")
            AND (er.""ExpiryDate"" IS NULL OR er.""ExpiryDate"" > DATE(qi.""SubmittedAt""))
          WHERE qi.""Id"" = @QuotationItemId
            AND er.""IsActive"" = TRUE
          ORDER BY er.""EffectiveDate"" DESC
          LIMIT 1",
        new { QuotationItemId = quotationItemId }
    );

    return result;
}
```

---

## 4. Requester Workflow

### 4.1 RFQ Number Generation

**Priority:** HIGH
**Estimated Effort:** 2 hours
**Dependencies:** None

**Business Requirement:**
> 02_Requester_and_Approver_WorkFlow.txt Lines 47, 51: Draft (random) vs Final (CompanyShortName-YY-MM-XXXX)

**Schema Support:**
```sql
-- Rfqs.RfqNumber VARCHAR(50) UNIQUE NOT NULL
-- Companies.ShortNameEn VARCHAR(10)
```

**Implementation:**

```csharp
// Services/RfqNumberService.cs
public class RfqNumberService : IRfqNumberService
{
    private readonly ErfxDbContext _writeDb;
    private readonly IDbConnection _readDb;

    public string GenerateDraftRfqNumber()
    {
        // Format: DRAFT-{timestamp}-{random}
        var timestamp = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
        var random = Guid.NewGuid().ToString("N").Substring(0, 8);
        return $"DRAFT-{timestamp}-{random}";
    }

    public async Task<string> GenerateFinalRfqNumberAsync(long companyId, CancellationToken ct)
    {
        // Get company short name
        var company = await _writeDb.Companies
            .Where(c => c.Id == companyId)
            .Select(c => c.ShortNameEn)
            .FirstOrDefaultAsync(ct);

        if (company == null)
        {
            throw new InvalidOperationException($"Company {companyId} not found");
        }

        // Format: {ShortName}-{YY}-{MM}-{XXXX}
        var now = DateTime.Now;
        var year = now.ToString("yy");   // "25"
        var month = now.ToString("MM");  // "01"

        var prefix = $"{company}-{year}-{month}-";

        // Get max sequence for this month (using raw SQL for performance)
        var maxSequence = await _readDb.QueryFirstOrDefaultAsync<int?>(
            @"SELECT MAX(CAST(RIGHT(""RfqNumber"", 4) AS INTEGER))
              FROM ""Rfqs""
              WHERE ""RfqNumber"" LIKE @Prefix || '%'
                AND ""RfqNumber"" NOT LIKE 'DRAFT%'",
            new { Prefix = prefix }
        );

        var nextSequence = (maxSequence ?? 0) + 1;
        var rfqNumber = $"{prefix}{nextSequence:D4}"; // Pad to 4 digits

        // Verify uniqueness (race condition protection)
        var exists = await _writeDb.Rfqs.AnyAsync(r => r.RfqNumber == rfqNumber, ct);
        if (exists)
        {
            // Retry with incremented sequence
            nextSequence++;
            rfqNumber = $"{prefix}{nextSequence:D4}";
        }

        return rfqNumber;
    }
}
```

**Example Output:**
```
Draft: DRAFT-1704034800000-a3b4c5d6
Final: ABC-25-01-0001, ABC-25-01-0002, ..., ABC-25-02-0001 (new month)
```

---

### 4.2 Draft Auto-Delete Job (Wolverine)

**Priority:** HIGH
**Estimated Effort:** 1 hour
**Dependencies:** Wolverine

**Business Requirement:**
> 02_Requester_and_Approver_WorkFlow.txt Line 46: ถ้าเลย 3 วัน ระบบจะลบอัตโนมัติ

**Schema Support:**
```sql
-- Rfqs.Status = 'SAVE_DRAFT'
-- Rfqs.CreatedDate DATE
```

**Implementation:**

```csharp
// Jobs/DraftAutoDeleteJob.cs
public class DraftAutoDeleteJob
{
    private readonly ErfxDbContext _writeDb;
    private readonly ILogger<DraftAutoDeleteJob> _logger;

    // Run daily at 2:00 AM
    [Scheduled(Hour = 2, Minute = 0)]
    public async Task ExecuteAsync(CancellationToken ct)
    {
        _logger.LogInformation("Starting draft auto-delete job");

        // Delete drafts older than 3 days
        var cutoffDate = DateTime.Today.AddDays(-3);

        var deletedCount = await _writeDb.Rfqs
            .Where(r => r.Status == "SAVE_DRAFT" && r.CreatedDate < cutoffDate)
            .ExecuteDeleteAsync(ct);

        _logger.LogInformation("Draft auto-delete job completed. Deleted {Count} drafts", deletedCount);

        // Publish event for notification (optional)
        if (deletedCount > 0)
        {
            await PublishAsync(new DraftsAutoDeletedEvent { Count = deletedCount, Date = DateTime.Today });
        }
    }
}
```

---

### 4.3 Document Upload Validation

**Priority:** HIGH
**Estimated Effort:** 2 hours
**Dependencies:** File upload service

**Business Requirement:**
> 02_Requester_and_Approver_WorkFlow.txt Line 27: ต้อง upload file ให้ครบตาม Subcategory requirements

**Schema Support:**
```sql
-- SubcategoryDocRequirements table
-- RfqDocuments table
```

**Implementation:**

```csharp
// Validators/RfqDocumentValidator.cs
public class RfqDocumentValidator
{
    private readonly IDbConnection _readDb;

    public async Task<Result<DocumentValidationResult>> ValidateRequiredDocumentsAsync(
        long rfqId,
        long subcategoryId)
    {
        // 1. Get required documents for subcategory
        var requiredDocs = await _readDb.QueryAsync<SubcategoryDocRequirement>(
            @"SELECT ""Id"", ""DocumentName"", ""IsRequired"", ""MaxFileSize"", ""AllowedExtensions""
              FROM ""SubcategoryDocRequirements""
              WHERE ""SubcategoryId"" = @SubcategoryId
                AND ""IsActive"" = TRUE
              ORDER BY ""SortOrder""",
            new { SubcategoryId = subcategoryId }
        );

        var requiredDocNames = requiredDocs
            .Where(d => d.IsRequired)
            .Select(d => d.DocumentName)
            .ToList();

        // 2. Get uploaded documents for RFQ
        var uploadedDocs = await _readDb.QueryAsync<string>(
            @"SELECT DISTINCT ""DocumentName""
              FROM ""RfqDocuments""
              WHERE ""RfqId"" = @RfqId
                AND ""DocumentType"" = 'REQUIRED'",
            new { RfqId = rfqId }
        );

        var uploadedDocNames = uploadedDocs.ToList();

        // 3. Find missing documents
        var missingDocs = requiredDocNames.Except(uploadedDocNames).ToList();

        if (missingDocs.Any())
        {
            return Result<DocumentValidationResult>.Failure(
                $"Missing required documents: {string.Join(", ", missingDocs)}"
            );
        }

        // 4. Validate file sizes and extensions
        var uploadedFiles = await _readDb.QueryAsync<RfqDocument>(
            @"SELECT rd.""DocumentName"", rd.""FileSize"", rd.""FileName""
              FROM ""RfqDocuments"" rd
              WHERE rd.""RfqId"" = @RfqId",
            new { RfqId = rfqId }
        );

        foreach (var file in uploadedFiles)
        {
            var requirement = requiredDocs.FirstOrDefault(r => r.DocumentName == file.DocumentName);
            if (requirement != null)
            {
                // Check file size (convert MB to bytes)
                var maxSizeBytes = requirement.MaxFileSize * 1024 * 1024;
                if (file.FileSize > maxSizeBytes)
                {
                    return Result<DocumentValidationResult>.Failure(
                        $"File '{file.FileName}' exceeds maximum size of {requirement.MaxFileSize} MB"
                    );
                }

                // Check file extension
                if (!string.IsNullOrEmpty(requirement.AllowedExtensions))
                {
                    var allowedExts = requirement.AllowedExtensions.Split(',').Select(e => e.Trim().ToLower());
                    var fileExt = Path.GetExtension(file.FileName).ToLower();

                    if (!allowedExts.Contains(fileExt))
                    {
                        return Result<DocumentValidationResult>.Failure(
                            $"File '{file.FileName}' has invalid extension. Allowed: {requirement.AllowedExtensions}"
                        );
                    }
                }
            }
        }

        return Result<DocumentValidationResult>.Success(new DocumentValidationResult
        {
            RequiredCount = requiredDocNames.Count,
            UploadedCount = uploadedDocNames.Count,
            MissingDocuments = new List<string>()
        });
    }
}
```

---

### 4.4 IsUrgent Flag Calculation

**Priority:** MEDIUM
**Estimated Effort:** 30 minutes
**Dependencies:** None

**Business Requirement:**
> 02_Requester_and_Approver_WorkFlow.txt Line 52: ถ้า Requester ปรับวันน้อยกว่า = งานด่วน

**Schema Support:**
```sql
-- Rfqs.IsUrgent BOOLEAN
-- Subcategories.Duration INT
```

**Implementation:**

```csharp
// Services/RfqService.cs
public bool CalculateIsUrgent(DateTime requiredQuotationDate, DateTime createdDate, int subcategoryDuration)
{
    // Default expected date = CreatedDate + Duration days
    var expectedDate = createdDate.AddDays(subcategoryDuration);

    // If requiredDate < expectedDate → Urgent
    return requiredQuotationDate < expectedDate;
}

// Usage in CreateRfqCommand
public async Task<Result<long>> CreateRfqAsync(CreateRfqCommand command)
{
    // Get subcategory duration
    var subcategory = await _writeDb.Subcategories.FindAsync(command.SubcategoryId);
    var duration = subcategory?.Duration ?? 7; // Default 7 days

    var rfq = new Rfq
    {
        // ... other fields
        CreatedDate = DateTime.Today,
        RequiredQuotationDate = command.RequiredQuotationDate,
        IsUrgent = CalculateIsUrgent(
            command.RequiredQuotationDate,
            DateTime.Today,
            duration
        )
    };

    _writeDb.Rfqs.Add(rfq);
    await _writeDb.SaveChangesAsync();

    return Result<long>.Success(rfq.Id);
}
```

---

### 4.5 Serial Number Conditional Validation

**Priority:** MEDIUM
**Estimated Effort:** 30 minutes
**Dependencies:** None

**Business Requirement:**
> 02_Requester_and_Approver_WorkFlow.txt Line 8: ถ้า Subcategory IsUseSerial Y บังคับกรอก

**Implementation:**

```csharp
// Validators/CreateRfqValidator.cs
public class CreateRfqValidator : AbstractValidator<CreateRfqCommand>
{
    private readonly IDbConnection _readDb;

    public CreateRfqValidator(IDbConnection readDb)
    {
        _readDb = readDb;

        RuleFor(x => x.SerialNumber)
            .MustAsync(async (command, serialNumber, ct) =>
            {
                // Get subcategory
                var isUseSerial = await _readDb.QueryFirstOrDefaultAsync<bool>(
                    @"SELECT ""IsUseSerialNumber""
                      FROM ""Subcategories""
                      WHERE ""Id"" = @Id",
                    new { Id = command.SubcategoryId }
                );

                // If IsUseSerialNumber = true, SerialNumber is required
                if (isUseSerial && string.IsNullOrWhiteSpace(serialNumber))
                {
                    return false;
                }

                return true;
            })
            .WithMessage("Serial Number is required for this subcategory");
    }
}
```

---

### 4.6 Budget Amount Conditional Validation

**Priority:** MEDIUM
**Estimated Effort:** 30 minutes
**Dependencies:** None

**Business Requirement:**
> 02_Requester_and_Approver_WorkFlow.txt Line 20: ถ้า ประเภทงาน = ซื้อ บังคับกรอก งบประมาณ

**Implementation:**

```csharp
// Validators/CreateRfqValidator.cs (continued)
public CreateRfqValidator(IDbConnection readDb)
{
    // ... previous rules

    RuleFor(x => x.BudgetAmount)
        .MustAsync(async (command, budgetAmount, ct) =>
        {
            // Get JobType
            var jobTypeCode = await _readDb.QueryFirstOrDefaultAsync<string>(
                @"SELECT ""JobTypeCode""
                  FROM ""JobTypes""
                  WHERE ""Id"" = @Id",
                new { Id = command.JobTypeId }
            );

            // If JobType = 'BUY', BudgetAmount is required
            if (jobTypeCode == "BUY" && (!budgetAmount.HasValue || budgetAmount.Value <= 0))
            {
                return false;
            }

            return true;
        })
        .WithMessage("Budget Amount is required when Job Type is 'BUY'");
}
```

---

### 4.7 RFQ Items Validation (At Least 1 Item)

**Priority:** HIGH
**Estimated Effort:** 30 minutes
**Dependencies:** None

**Business Requirement:**
> 02_Requester_and_Approver_WorkFlow.txt Line 50: validate สินค้า อย่างน้อย 1 รายการ

**Implementation:**

```csharp
// Validators/CreateRfqValidator.cs (continued)
RuleFor(x => x.Items)
    .NotEmpty()
    .WithMessage("At least one item is required")
    .Must(items => items != null && items.Count > 0)
    .WithMessage("RFQ must contain at least one item");

RuleForEach(x => x.Items).ChildRules(item =>
{
    item.RuleFor(i => i.ProductName)
        .NotEmpty()
        .WithMessage("Product name is required");

    item.RuleFor(i => i.Quantity)
        .GreaterThan(0)
        .WithMessage("Quantity must be greater than zero");

    item.RuleFor(i => i.UnitOfMeasure)
        .NotEmpty()
        .WithMessage("Unit of measure is required");
});
```

---

## 5. Approver Workflow

### 5.1 Approval Chain Routing

**Priority:** HIGH
**Estimated Effort:** 3 hours
**Dependencies:** Email service, Notification service

**Business Requirement:**
> 02_Requester_and_Approver_WorkFlow.txt Lines 39, 53, 66-68: Sequential approval routing

**Implementation:**

```csharp
// Services/ApprovalChainService.cs
public class ApprovalChainService : IApprovalChainService
{
    private readonly ErfxDbContext _writeDb;
    private readonly IDbConnection _readDb;
    private readonly IEmailService _emailService;
    private readonly INotificationService _notificationService;

    public async Task<Result> RouteToNextApproverAsync(long rfqId, CancellationToken ct)
    {
        // 1. Get RFQ info
        var rfq = await _writeDb.Rfqs
            .Include(r => r.Requester)
            .Include(r => r.Department)
            .FirstOrDefaultAsync(r => r.Id == rfqId, ct);

        if (rfq == null)
        {
            return Result.Failure("RFQ not found");
        }

        // 2. Get approval chain for department
        var approvalChain = await GetApprovalChainAsync(rfq.CompanyId, rfq.DepartmentId);

        if (approvalChain.Count == 0)
        {
            return Result.Failure($"No approval chain configured for department {rfq.Department.DepartmentNameTh}");
        }

        // 3. Determine next level
        var currentLevel = rfq.CurrentLevel;
        var nextLevel = currentLevel + 1;
        var nextApprover = approvalChain.FirstOrDefault(a => a.ApproverLevel == nextLevel);

        using var transaction = await _writeDb.Database.BeginTransactionAsync(ct);

        if (nextApprover != null)
        {
            // Route to next approver
            rfq.CurrentLevel = nextLevel;
            rfq.CurrentActorId = nextApprover.UserId;
            rfq.CurrentActorReceivedAt = DateTime.UtcNow;
            rfq.Status = "PENDING";
            rfq.LastActionAt = DateTime.UtcNow;

            // Add to actor timeline
            _writeDb.RfqActorTimeline.Add(new RfqActorTimeline
            {
                RfqId = rfqId,
                ActorId = nextApprover.UserId,
                ActorRole = "APPROVER",
                ReceivedAt = DateTime.UtcNow
            });

            await _writeDb.SaveChangesAsync(ct);

            // Send notification to next approver
            await _notificationService.NotifyApproverAsync(
                nextApprover.UserId,
                rfqId,
                rfq.RfqNumber,
                rfq.ProjectName
            );

            await _emailService.SendApprovalRequestEmailAsync(
                nextApprover.Email,
                nextApprover.FullName,
                rfq.RfqNumber,
                rfq.ProjectName
            );
        }
        else
        {
            // Final level - Route to Purchasing
            rfq.CurrentLevel = 0; // Reset level
            rfq.CurrentActorId = null; // Will be assigned by first Purchasing person
            rfq.Status = "PENDING";
            rfq.LastActionAt = DateTime.UtcNow;

            await _writeDb.SaveChangesAsync(ct);

            // Notify all eligible Purchasing users
            await NotifyPurchasingTeamAsync(rfq, ct);

            // Notify Requester
            await _notificationService.NotifyRequesterAsync(
                rfq.RequesterId,
                rfqId,
                "RFQ_APPROVED",
                "Your RFQ has been approved and sent to Purchasing"
            );

            // Notify all previous approvers (Line 68)
            var previousApprovers = await GetPreviousApproversAsync(rfqId);
            foreach (var approver in previousApprovers)
            {
                await _notificationService.NotifyApproverAsync(
                    approver.UserId,
                    rfqId,
                    "RFQ_FULLY_APPROVED",
                    $"RFQ {rfq.RfqNumber} has been fully approved"
                );
            }
        }

        await transaction.CommitAsync(ct);

        return Result.Success();
    }

    private async Task<List<ApproverInfo>> GetApprovalChainAsync(long companyId, long departmentId)
    {
        var chain = await _readDb.QueryAsync<ApproverInfo>(
            @"SELECT
                ucr.""ApproverLevel"",
                u.""Id"" AS ""UserId"",
                u.""Email"",
                u.""FirstNameTh"" || ' ' || u.""LastNameTh"" AS ""FullName""
              FROM ""UserCompanyRoles"" ucr
              JOIN ""Users"" u ON ucr.""UserId"" = u.""Id""
              JOIN ""Roles"" r ON ucr.""PrimaryRoleId"" = r.""Id""
              WHERE ucr.""CompanyId"" = @CompanyId
                AND ucr.""DepartmentId"" = @DepartmentId
                AND r.""RoleCode"" = 'APPROVER'
                AND ucr.""IsActive"" = TRUE
                AND (ucr.""EndDate"" IS NULL OR ucr.""EndDate"" > CURRENT_DATE)
              ORDER BY ucr.""ApproverLevel""",
            new { CompanyId = companyId, DepartmentId = departmentId }
        );

        return chain.ToList();
    }

    private async Task<List<ApproverInfo>> GetPreviousApproversAsync(long rfqId)
    {
        var approvers = await _readDb.QueryAsync<ApproverInfo>(
            @"SELECT DISTINCT
                u.""Id"" AS ""UserId"",
                u.""Email"",
                u.""FirstNameTh"" || ' ' || u.""LastNameTh"" AS ""FullName""
              FROM ""RfqActorTimeline"" rat
              JOIN ""Users"" u ON rat.""ActorId"" = u.""Id""
              WHERE rat.""RfqId"" = @RfqId
                AND rat.""ActorRole"" = 'APPROVER'
                AND rat.""ActionAt"" IS NOT NULL",
            new { RfqId = rfqId }
        );

        return approvers.ToList();
    }

    private async Task NotifyPurchasingTeamAsync(Rfq rfq, CancellationToken ct)
    {
        // Get all Purchasing users bound to RFQ's category
        var purchasingUsers = await _readDb.QueryAsync<PurchasingUserInfo>(
            @"SELECT DISTINCT
                u.""Id"" AS ""UserId"",
                u.""Email"",
                u.""FirstNameTh"" || ' ' || u.""LastNameTh"" AS ""FullName""
              FROM ""Users"" u
              JOIN ""UserCompanyRoles"" ucr ON u.""Id"" = ucr.""UserId""
              JOIN ""UserCategoryBindings"" ucb ON ucr.""Id"" = ucb.""UserCompanyRoleId""
              JOIN ""Roles"" r ON ucr.""PrimaryRoleId"" = r.""Id""
              WHERE ucb.""CategoryId"" = @CategoryId
                AND (ucb.""SubcategoryId"" = @SubcategoryId OR ucb.""SubcategoryId"" IS NULL)
                AND r.""RoleCode"" = 'PURCHASING'
                AND ucb.""IsActive"" = TRUE
                AND ucr.""IsActive"" = TRUE
                AND u.""IsActive"" = TRUE",
            new { CategoryId = rfq.CategoryId, SubcategoryId = rfq.SubcategoryId }
        );

        foreach (var user in purchasingUsers)
        {
            await _notificationService.NotifyPurchasingAsync(
                user.UserId,
                rfq.Id,
                "NEW_RFQ",
                $"New RFQ {rfq.RfqNumber} requires your attention"
            );

            await _emailService.SendNewRfqNotificationAsync(
                user.Email,
                user.FullName,
                rfq.RfqNumber,
                rfq.ProjectName
            );
        }
    }
}
```

---

### 5.2 Reject/Decline Actions

**Priority:** HIGH
**Estimated Effort:** 2 hours
**Dependencies:** Email service, Notification service

**Business Requirement:**
> 02_Requester_and_Approver_WorkFlow.txt Lines 60-63: Reject (END) vs Declined (back to Requester)

**Implementation:**

```csharp
// Commands/RejectRfqCommand.cs
public class RejectRfqCommandHandler : ICommandHandler<RejectRfqCommand>
{
    private readonly ErfxDbContext _writeDb;
    private readonly ICurrentUserService _currentUser;
    private readonly IEmailService _emailService;
    private readonly INotificationService _notificationService;

    public async Task<Result> HandleAsync(RejectRfqCommand command, CancellationToken ct)
    {
        var rfq = await _writeDb.Rfqs
            .Include(r => r.Requester)
            .FirstOrDefaultAsync(r => r.Id == command.RfqId, ct);

        if (rfq == null)
        {
            return Result.Failure("RFQ not found");
        }

        using var transaction = await _writeDb.Database.BeginTransactionAsync(ct);

        // Update RFQ status to REJECTED
        rfq.Status = "REJECTED";
        rfq.RejectReason = command.Reason;
        rfq.LastActionAt = DateTime.UtcNow;
        rfq.UpdatedAt = DateTime.UtcNow;
        rfq.UpdatedBy = _currentUser.UserId;

        // Update actor timeline
        var timeline = await _writeDb.RfqActorTimeline
            .Where(rat => rat.RfqId == command.RfqId
                && rat.ActorId == _currentUser.UserId
                && rat.ActionAt == null)
            .FirstOrDefaultAsync(ct);

        if (timeline != null)
        {
            timeline.ActionAt = DateTime.UtcNow;
            timeline.IsOntime = DateTime.UtcNow <= timeline.ReceivedAt.AddDays(GetResponseTimeDays("APPROVER"));
        }

        // Insert status history
        _writeDb.RfqStatusHistory.Add(new RfqStatusHistory
        {
            RfqId = command.RfqId,
            FromStatus = "PENDING",
            ToStatus = "REJECTED",
            ActionType = "REJECT",
            ActorId = _currentUser.UserId,
            ActorRole = "APPROVER",
            ApprovalLevel = rfq.CurrentLevel,
            Decision = "REJECTED",
            Reason = command.Reason,
            ActionAt = DateTime.UtcNow
        });

        await _writeDb.SaveChangesAsync(ct);
        await transaction.CommitAsync(ct);

        // Send notification to Requester
        await _notificationService.NotifyRequesterAsync(
            rfq.RequesterId,
            rfq.Id,
            "RFQ_REJECTED",
            $"Your RFQ {rfq.RfqNumber} has been rejected"
        );

        await _emailService.SendRfqRejectedEmailAsync(
            rfq.Requester.Email,
            rfq.Requester.FirstNameTh,
            rfq.RfqNumber,
            rfq.ProjectName,
            command.Reason
        );

        return Result.Success();
    }
}

// Commands/DeclineRfqCommand.cs
public class DeclineRfqCommandHandler : ICommandHandler<DeclineRfqCommand>
{
    private readonly ErfxDbContext _writeDb;
    private readonly ICurrentUserService _currentUser;
    private readonly IEmailService _emailService;
    private readonly INotificationService _notificationService;

    public async Task<Result> HandleAsync(DeclineRfqCommand command, CancellationToken ct)
    {
        var rfq = await _writeDb.Rfqs
            .Include(r => r.Requester)
            .FirstOrDefaultAsync(r => r.Id == command.RfqId, ct);

        if (rfq == null)
        {
            return Result.Failure("RFQ not found");
        }

        using var transaction = await _writeDb.Database.BeginTransactionAsync(ct);

        // Update RFQ status to DECLINED
        rfq.Status = "DECLINED";
        rfq.DeclineReason = command.Reason;
        rfq.CurrentActorId = rfq.RequesterId; // Back to Requester
        rfq.CurrentActorReceivedAt = DateTime.UtcNow;
        rfq.CurrentLevel = 0; // Reset approval level
        rfq.LastActionAt = DateTime.UtcNow;
        rfq.UpdatedAt = DateTime.UtcNow;
        rfq.UpdatedBy = _currentUser.UserId;

        // Update actor timeline
        var timeline = await _writeDb.RfqActorTimeline
            .Where(rat => rat.RfqId == command.RfqId
                && rat.ActorId == _currentUser.UserId
                && rat.ActionAt == null)
            .FirstOrDefaultAsync(ct);

        if (timeline != null)
        {
            timeline.ActionAt = DateTime.UtcNow;
            timeline.IsOntime = DateTime.UtcNow <= timeline.ReceivedAt.AddDays(GetResponseTimeDays("APPROVER"));
        }

        // Add Requester back to timeline
        _writeDb.RfqActorTimeline.Add(new RfqActorTimeline
        {
            RfqId = command.RfqId,
            ActorId = rfq.RequesterId,
            ActorRole = "REQUESTER",
            ReceivedAt = DateTime.UtcNow
        });

        // Insert status history
        _writeDb.RfqStatusHistory.Add(new RfqStatusHistory
        {
            RfqId = command.RfqId,
            FromStatus = "PENDING",
            ToStatus = "DECLINED",
            ActionType = "DECLINE",
            ActorId = _currentUser.UserId,
            ActorRole = "APPROVER",
            ApprovalLevel = rfq.CurrentLevel,
            Decision = "DECLINED",
            Reason = command.Reason,
            ActionAt = DateTime.UtcNow
        });

        await _writeDb.SaveChangesAsync(ct);
        await transaction.CommitAsync(ct);

        // Send notification to Requester
        await _notificationService.NotifyRequesterAsync(
            rfq.RequesterId,
            rfq.Id,
            "RFQ_DECLINED",
            $"Your RFQ {rfq.RfqNumber} needs revision"
        );

        await _emailService.SendRfqDeclinedEmailAsync(
            rfq.Requester.Email,
            rfq.Requester.FirstNameTh,
            rfq.RfqNumber,
            rfq.ProjectName,
            command.Reason
        );

        return Result.Success();
    }
}
```

---

### 5.3 Accept Action (Multi-level)

**Priority:** HIGH
**Estimated Effort:** 2 hours
**Dependencies:** ApprovalChainService

**Implementation:**

```csharp
// Commands/AcceptRfqCommand.cs
public class AcceptRfqCommandHandler : ICommandHandler<AcceptRfqCommand>
{
    private readonly ErfxDbContext _writeDb;
    private readonly ICurrentUserService _currentUser;
    private readonly IApprovalChainService _approvalChainService;

    public async Task<Result> HandleAsync(AcceptRfqCommand command, CancellationToken ct)
    {
        var rfq = await _writeDb.Rfqs.FindAsync(command.RfqId);
        if (rfq == null)
        {
            return Result.Failure("RFQ not found");
        }

        using var transaction = await _writeDb.Database.BeginTransactionAsync(ct);

        // Update actor timeline
        var timeline = await _writeDb.RfqActorTimeline
            .Where(rat => rat.RfqId == command.RfqId
                && rat.ActorId == _currentUser.UserId
                && rat.ActionAt == null)
            .FirstOrDefaultAsync(ct);

        if (timeline != null)
        {
            timeline.ActionAt = DateTime.UtcNow;
            timeline.IsOntime = DateTime.UtcNow <= timeline.ReceivedAt.AddDays(GetResponseTimeDays("APPROVER"));
        }

        // Insert status history (APPROVED decision, but status stays PENDING until final)
        _writeDb.RfqStatusHistory.Add(new RfqStatusHistory
        {
            RfqId = command.RfqId,
            FromStatus = "PENDING",
            ToStatus = "PENDING", // Stays PENDING until final approval
            ActionType = "APPROVE",
            ActorId = _currentUser.UserId,
            ActorRole = "APPROVER",
            ApprovalLevel = rfq.CurrentLevel,
            Decision = "APPROVED",
            Comments = command.Comments,
            ActionAt = DateTime.UtcNow
        });

        rfq.LastActionAt = DateTime.UtcNow;
        await _writeDb.SaveChangesAsync(ct);
        await transaction.CommitAsync(ct);

        // Route to next approver or Purchasing
        await _approvalChainService.RouteToNextApproverAsync(command.RfqId, ct);

        return Result.Success();
    }
}
```

---

### 5.4 Status Transition Validation

**Priority:** MEDIUM
**Estimated Effort:** 1 hour
**Dependencies:** None

**Implementation:**

```csharp
// Services/RfqStatusValidator.cs
public class RfqStatusValidator
{
    // Valid status transitions
    private static readonly Dictionary<string, List<string>> ValidTransitions = new()
    {
        ["SAVE_DRAFT"] = new() { "PENDING", "DECLINED" },
        ["PENDING"] = new() { "PENDING", "DECLINED", "REJECTED", "COMPLETED", "RE_BID" },
        ["DECLINED"] = new() { "PENDING" },
        ["REJECTED"] = new() { }, // Terminal state
        ["COMPLETED"] = new() { "RE_BID" },
        ["RE_BID"] = new() { "PENDING", "COMPLETED" }
    };

    public Result ValidateStatusTransition(string currentStatus, string newStatus, string actorRole)
    {
        // Check if transition is allowed
        if (!ValidTransitions.ContainsKey(currentStatus))
        {
            return Result.Failure($"Invalid current status: {currentStatus}");
        }

        if (!ValidTransitions[currentStatus].Contains(newStatus))
        {
            return Result.Failure($"Cannot transition from {currentStatus} to {newStatus}");
        }

        // Role-based validation
        if (newStatus == "REJECTED" && actorRole != "APPROVER")
        {
            return Result.Failure("Only APPROVER can reject RFQ");
        }

        if (newStatus == "DECLINED" && actorRole != "APPROVER")
        {
            return Result.Failure("Only APPROVER can decline RFQ");
        }

        if (newStatus == "RE_BID" && actorRole != "PURCHASING_APPROVER")
        {
            return Result.Failure("Only PURCHASING_APPROVER can initiate re-bid");
        }

        return Result.Success();
    }
}
```

---

## 6. Purchasing Assignment

### 6.1 First-Come-First-Serve Mechanism

**Priority:** HIGH
**Estimated Effort:** 2 hours
**Dependencies:** None

**Business Requirement:**
> 02_Requester_and_Approver_WorkFlow.txt Lines 70-73: คนไหนเข้ามา Accept ก่อน คนนั้นเป็นผู้ดำเนินงาน

**Schema Support:**
```sql
-- Rfqs.ResponsiblePersonId
-- Rfqs.ResponsiblePersonAssignedAt (v6.2.2)
```

**Implementation:**

```csharp
// Commands/AcceptRfqAndInviteCommand.cs
public class AcceptRfqAndInviteCommandHandler : ICommandHandler<AcceptRfqAndInviteCommand>
{
    private readonly ErfxDbContext _writeDb;
    private readonly ICurrentUserService _currentUser;

    public async Task<Result> HandleAsync(AcceptRfqAndInviteCommand command, CancellationToken ct)
    {
        // Optimistic locking: Only assign if not yet assigned
        var rfq = await _writeDb.Rfqs
            .Where(r => r.Id == command.RfqId && r.ResponsiblePersonId == null)
            .FirstOrDefaultAsync(ct);

        if (rfq == null)
        {
            // Either RFQ doesn't exist or already assigned
            var existingRfq = await _writeDb.Rfqs.FindAsync(command.RfqId);
            if (existingRfq == null)
            {
                return Result.Failure("RFQ not found");
            }

            if (existingRfq.ResponsiblePersonId != null)
            {
                // Already assigned to someone else
                var responsiblePerson = await _writeDb.Users.FindAsync(existingRfq.ResponsiblePersonId);
                return Result.Failure(
                    $"This RFQ has already been assigned to {responsiblePerson.FirstNameTh} {responsiblePerson.LastNameTh}"
                );
            }
        }

        using var transaction = await _writeDb.Database.BeginTransactionAsync(ct);

        // Assign to current Purchasing user (First-come-first-serve)
        rfq.ResponsiblePersonId = _currentUser.UserId;
        rfq.ResponsiblePersonAssignedAt = DateTime.UtcNow; // v6.2.2: Temporal proof
        rfq.CurrentActorId = _currentUser.UserId;
        rfq.LastActionAt = DateTime.UtcNow;

        // Add to actor timeline
        _writeDb.RfqActorTimeline.Add(new RfqActorTimeline
        {
            RfqId = command.RfqId,
            ActorId = _currentUser.UserId,
            ActorRole = "PURCHASING",
            ReceivedAt = DateTime.UtcNow
        });

        // Insert status history
        _writeDb.RfqStatusHistory.Add(new RfqStatusHistory
        {
            RfqId = command.RfqId,
            FromStatus = "PENDING",
            ToStatus = "PENDING",
            ActionType = "ACCEPT_AND_ASSIGN",
            ActorId = _currentUser.UserId,
            ActorRole = "PURCHASING",
            Decision = "APPROVED",
            ActionAt = DateTime.UtcNow
        });

        await _writeDb.SaveChangesAsync(ct);

        // Proceed with supplier invitation logic...
        // (Implementation in next section)

        await transaction.CommitAsync(ct);

        return Result.Success("RFQ assigned to you successfully");
    }
}
```

---

### 6.2 Dashboard Query (Exclusive Assignment)

**Priority:** HIGH
**Estimated Effort:** 1 hour
**Dependencies:** None

**Business Requirement:**
> 02_Requester_and_Approver_WorkFlow.txt Line 72: A กับ C จะไม่เห็นงานนี้

**Implementation:**

```csharp
// Queries/GetPurchasingDashboardQuery.cs
public class GetPurchasingDashboardQueryHandler : IQueryHandler<GetPurchasingDashboardQuery, DashboardResult>
{
    private readonly IDbConnection _readDb;
    private readonly ICurrentUserService _currentUser;

    public async Task<DashboardResult> HandleAsync(GetPurchasingDashboardQuery query, CancellationToken ct)
    {
        // 1. Get RFQs assigned to current user (Purchased by me)
        var assignedRfqs = await _readDb.QueryAsync<RfqListItem>(
            @"SELECT
                r.""Id"",
                r.""RfqNumber"",
                r.""ProjectName"",
                r.""Status"",
                r.""CreatedDate"",
                r.""RequiredQuotationDate"",
                r.""IsUrgent"",
                r.""ResponsiblePersonAssignedAt""
              FROM ""Rfqs"" r
              WHERE r.""ResponsiblePersonId"" = @UserId
                AND r.""Status"" IN ('PENDING', 'COMPLETED', 'RE_BID')
              ORDER BY r.""IsUrgent"" DESC, r.""RequiredQuotationDate"" ASC",
            new { UserId = _currentUser.UserId }
        );

        // 2. Get unassigned RFQs for categories I'm responsible for
        var unassignedRfqs = await _readDb.QueryAsync<RfqListItem>(
            @"SELECT DISTINCT
                r.""Id"",
                r.""RfqNumber"",
                r.""ProjectName"",
                r.""Status"",
                r.""CreatedDate"",
                r.""RequiredQuotationDate"",
                r.""IsUrgent""
              FROM ""Rfqs"" r
              JOIN ""UserCategoryBindings"" ucb
                ON r.""CategoryId"" = ucb.""CategoryId""
                AND (r.""SubcategoryId"" = ucb.""SubcategoryId"" OR ucb.""SubcategoryId"" IS NULL)
              JOIN ""UserCompanyRoles"" ucr
                ON ucb.""UserCompanyRoleId"" = ucr.""Id""
              JOIN ""Roles"" role
                ON ucr.""PrimaryRoleId"" = role.""Id""
              WHERE ucr.""UserId"" = @UserId
                AND role.""RoleCode"" = 'PURCHASING'
                AND r.""ResponsiblePersonId"" IS NULL  -- ✅ Only unassigned
                AND r.""Status"" = 'PENDING'
                AND ucb.""IsActive"" = TRUE
                AND ucr.""IsActive"" = TRUE
              ORDER BY r.""IsUrgent"" DESC, r.""RequiredQuotationDate"" ASC",
            new { UserId = _currentUser.UserId }
        );

        return new DashboardResult
        {
            AssignedToMe = assignedRfqs.ToList(),
            AvailableForAssignment = unassignedRfqs.ToList()
        };
    }
}
```

---

## 7. Scheduled Jobs (Wolverine)

### 7.1 Draft Auto-Delete Job

**Already covered in Section 4.2**

---

### 7.2 Deadline Reminder Job

**Priority:** MEDIUM
**Estimated Effort:** 2 hours
**Dependencies:** Email service, Notification service

**Implementation:**

```csharp
// Jobs/DeadlineReminderJob.cs
public class DeadlineReminderJob
{
    private readonly IDbConnection _readDb;
    private readonly ErfxDbContext _writeDb;
    private readonly IEmailService _emailService;
    private readonly INotificationService _notificationService;
    private readonly ILogger<DeadlineReminderJob> _logger;

    // Run every hour
    [Scheduled(Minute = 0)]
    public async Task ExecuteAsync(CancellationToken ct)
    {
        _logger.LogInformation("Starting deadline reminder job");

        // Find RFQs approaching deadline (within 24 hours) that haven't been reminded recently
        var upcomingDeadlines = await _readDb.QueryAsync<RfqDeadlineInfo>(
            @"SELECT
                r.""Id"",
                r.""RfqNumber"",
                r.""ProjectName"",
                r.""RequiredQuotationDate"",
                r.""CurrentActorId"",
                r.""Status"",
                u.""Email"",
                u.""FirstNameTh""
              FROM ""Rfqs"" r
              LEFT JOIN ""Users"" u ON r.""CurrentActorId"" = u.""Id""
              WHERE r.""Status"" IN ('PENDING', 'RE_BID')
                AND r.""RequiredQuotationDate"" BETWEEN NOW() AND NOW() + INTERVAL '24 hours'
                AND (r.""LastReminderSentAt"" IS NULL OR r.""LastReminderSentAt"" < NOW() - INTERVAL '12 hours')
                AND r.""CurrentActorId"" IS NOT NULL"
        );

        foreach (var rfq in upcomingDeadlines)
        {
            // Send reminder notification
            await _notificationService.SendDeadlineReminderAsync(
                rfq.CurrentActorId.Value,
                rfq.Id,
                rfq.RfqNumber,
                rfq.RequiredQuotationDate
            );

            // Send reminder email
            await _emailService.SendDeadlineReminderEmailAsync(
                rfq.Email,
                rfq.FirstNameTh,
                rfq.RfqNumber,
                rfq.ProjectName,
                rfq.RequiredQuotationDate
            );

            // Update last reminder sent
            await _writeDb.Rfqs
                .Where(r => r.Id == rfq.Id)
                .ExecuteUpdateAsync(r => r.SetProperty(x => x.LastReminderSentAt, DateTime.UtcNow), ct);
        }

        _logger.LogInformation("Deadline reminder job completed. Sent {Count} reminders", upcomingDeadlines.Count());
    }
}
```

---

### 7.3 Overdue Status Update Job

**Priority:** MEDIUM
**Estimated Effort:** 1 hour
**Dependencies:** None

**Implementation:**

```csharp
// Jobs/OverdueStatusUpdateJob.cs
public class OverdueStatusUpdateJob
{
    private readonly ErfxDbContext _writeDb;
    private readonly ILogger<OverdueStatusUpdateJob> _logger;

    // Run every hour
    [Scheduled(Minute = 30)]
    public async Task ExecuteAsync(CancellationToken ct)
    {
        _logger.LogInformation("Starting overdue status update job");

        // Mark RFQs as overdue
        var updated = await _writeDb.Rfqs
            .Where(r => r.Status == "PENDING"
                && r.RequiredQuotationDate < DateTime.Now
                && !r.IsOverdue)
            .ExecuteUpdateAsync(r => r.SetProperty(x => x.IsOverdue, true), ct);

        _logger.LogInformation("Overdue status update job completed. Updated {Count} RFQs", updated);
    }
}
```

---

## 8. Email & Notification Templates

### 8.1 Email Templates

**Priority:** MEDIUM
**Estimated Effort:** 4 hours (all templates)
**Dependencies:** SendGrid/SMTP service

**Required Email Templates:**

1. **Password Reset** (Already covered in Section 1.1)
2. **Email Verification**
3. **RFQ Approval Request**
4. **RFQ Rejected**
5. **RFQ Declined**
6. **RFQ Fully Approved**
7. **New RFQ for Purchasing**
8. **Deadline Reminder**
9. **Supplier Invitation**
10. **Quotation Received**

**Example Implementation:**

```csharp
// Services/EmailService.cs
public class EmailService : IEmailService
{
    private readonly SendGridClient _sendGridClient;
    private readonly IConfiguration _config;

    public async Task SendApprovalRequestEmailAsync(
        string email,
        string fullName,
        string rfqNumber,
        string projectName)
    {
        var templateData = new
        {
            fullName,
            rfqNumber,
            projectName,
            approvalUrl = $"{_config["AppUrl"]}/approver/rfqs/{rfqNumber}"
        };

        await SendTemplatedEmailAsync(
            email,
            "RFQ_APPROVAL_REQUEST",
            $"RFQ {rfqNumber} requires your approval",
            templateData
        );
    }

    public async Task SendRfqRejectedEmailAsync(
        string email,
        string fullName,
        string rfqNumber,
        string projectName,
        string reason)
    {
        var templateData = new
        {
            fullName,
            rfqNumber,
            projectName,
            reason,
            viewUrl = $"{_config["AppUrl"]}/requester/rfqs/{rfqNumber}"
        };

        await SendTemplatedEmailAsync(
            email,
            "RFQ_REJECTED",
            $"RFQ {rfqNumber} has been rejected",
            templateData
        );
    }

    private async Task SendTemplatedEmailAsync(
        string email,
        string templateId,
        string subject,
        object templateData)
    {
        var message = new SendGridMessage
        {
            From = new EmailAddress(_config["Email:FromAddress"], _config["Email:FromName"]),
            Subject = subject,
            TemplateId = _config[$"Email:Templates:{templateId}"]
        };

        message.AddTo(email);
        message.SetTemplateData(templateData);

        await _sendGridClient.SendEmailAsync(message);
    }
}
```

---

## 9. Implementation Priority Matrix

### Phase 1: Critical Path (Week 1-2)

| Task | Module | Priority | Effort | Dependencies |
|------|--------|----------|--------|--------------|
| Permission Seed Data | User Management | CRITICAL | 3h | None |
| RFQ Number Generation | Requester | HIGH | 2h | None |
| Approval Chain Routing | Approver | HIGH | 3h | Email service |
| First-Come-First-Serve | Purchasing | HIGH | 2h | None |
| Document Validation | Requester | HIGH | 2h | File upload |
| Reject/Decline Actions | Approver | HIGH | 2h | Email service |

**Total Effort:** ~14 hours

---

### Phase 2: Essential Features (Week 3-4)

| Task | Module | Priority | Effort | Dependencies |
|------|--------|----------|--------|--------------|
| Password Reset | Authentication | HIGH | 2h | Email service |
| Account Lockout | Authentication | HIGH | 1h | None |
| Draft Auto-Delete Job | Requester | HIGH | 1h | Wolverine |
| Role Conflict Validation | User Management | HIGH | 1h | None |
| Email Templates | All | MEDIUM | 4h | SendGrid |
| Dashboard Queries | All | MEDIUM | 3h | None |

**Total Effort:** ~12 hours

---

### Phase 3: Enhancement Features (Week 5-6)

| Task | Module | Priority | Effort | Dependencies |
|------|--------|----------|--------|--------------|
| Exchange Rate Upload | Admin | MEDIUM | 3h | File parser |
| Email Verification | Authentication | MEDIUM | 1.5h | Email service |
| Dynamic Permission UI | User Management | MEDIUM | 2h | Frontend |
| IsUrgent Calculation | Requester | MEDIUM | 0.5h | None |
| Deadline Reminder Job | System | MEDIUM | 2h | Email/Notification |
| Status Transition Validation | Approver | MEDIUM | 1h | None |

**Total Effort:** ~10 hours

---

## 10. Testing Checklist

### Unit Tests Required

- [ ] RFQ Number generation (draft vs final, monthly reset)
- [ ] Approval chain routing (multi-level, department-based)
- [ ] First-come-first-serve assignment (race condition)
- [ ] Document validation (required vs optional, file size, extensions)
- [ ] Role conflict validation
- [ ] Password strength validation
- [ ] Exchange rate temporal lookup
- [ ] Status transition validation
- [ ] IsUrgent calculation

### Integration Tests Required

- [ ] Approval workflow end-to-end
- [ ] Purchasing assignment flow
- [ ] Email sending (mock SMTP)
- [ ] Notification delivery
- [ ] File upload and validation
- [ ] Draft auto-delete job
- [ ] Deadline reminder job
- [ ] Exchange rate upload

### Performance Tests Required

- [ ] Dashboard queries (1000+ RFQs)
- [ ] Approval chain query (concurrent requests)
- [ ] First-come-first-serve (race condition handling)
- [ ] Exchange rate lookup (temporal queries)

---

## 📝 Conclusion

**Total Implementation Effort:** ~36 hours (excluding testing)

**Critical Dependencies:**
1. Email Service (SendGrid/SMTP) - **14 tasks depend on this**
2. Wolverine Event Bus - **3 scheduled jobs**
3. File Upload Service - **2 tasks**
4. Notification Service - **All workflows**

**Next Steps:**
1. Set up project infrastructure (Wolverine, SendGrid, Azure Blob)
2. Implement Phase 1 tasks (Critical Path)
3. Write comprehensive unit tests
4. Implement Phase 2 tasks (Essential Features)
5. Integration testing
6. Implement Phase 3 tasks (Enhancements)
7. Performance testing
8. UAT preparation

---

**Document Version:** 1.0
**Last Updated:** 2025-09-30
**Maintained By:** Development Team