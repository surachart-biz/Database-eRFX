-- =============================================
-- TRANSLATIONS SEED DATA
-- Covers all sections 2-9 of the system
-- =============================================

-- SECTION 2: COMPANY & ORGANIZATION
INSERT INTO "Translations" ("Module", "Key", "LanguageCode", "Value") VALUES
-- Company Status
('COMPANY', 'STATUS_ACTIVE', 'th', 'ใช้งาน'),
('COMPANY', 'STATUS_ACTIVE', 'en', 'Active'),
('COMPANY', 'STATUS_INACTIVE', 'th', 'ไม่ใช้งาน'),
('COMPANY', 'STATUS_INACTIVE', 'en', 'Inactive'),

-- Department Labels
('DEPARTMENT', 'LABEL_NAME', 'th', 'แผนก'),
('DEPARTMENT', 'LABEL_NAME', 'en', 'Department'),
('DEPARTMENT', 'LABEL_MANAGER', 'th', 'ผู้จัดการ'),
('DEPARTMENT', 'LABEL_MANAGER', 'en', 'Manager');

-- SECTION 3: USER MANAGEMENT
INSERT INTO "Translations" ("Module", "Key", "LanguageCode", "Value") VALUES
-- User Status
('USER', 'STATUS_ACTIVE', 'th', 'ใช้งาน'),
('USER', 'STATUS_ACTIVE', 'en', 'Active'),
('USER', 'STATUS_INACTIVE', 'th', 'ไม่ใช้งาน'),
('USER', 'STATUS_INACTIVE', 'en', 'Inactive'),

-- Roles
('ROLE', 'SUPER_ADMIN', 'th', 'ผู้ดูแลระบบสูงสุด'),
('ROLE', 'SUPER_ADMIN', 'en', 'Super Administrator'),
('ROLE', 'ADMIN', 'th', 'ผู้ดูแลระบบ'),
('ROLE', 'ADMIN', 'en', 'Administrator'),
('ROLE', 'REQUESTER', 'th', 'ผู้ขอซื้อ'),
('ROLE', 'REQUESTER', 'en', 'Requester'),
('ROLE', 'APPROVER', 'th', 'ผู้อนุมัติ'),
('ROLE', 'APPROVER', 'en', 'Approver'),
('ROLE', 'PURCHASING', 'th', 'จัดซื้อ'),
('ROLE', 'PURCHASING', 'en', 'Purchasing'),
('ROLE', 'PURCHASING_APPROVER', 'th', 'ผู้อนุมัติจัดซื้อ'),
('ROLE', 'PURCHASING_APPROVER', 'en', 'Purchasing Approver'),
('ROLE', 'SUPPLIER', 'th', 'ผู้ขาย'),
('ROLE', 'SUPPLIER', 'en', 'Supplier'),
('ROLE', 'MANAGING_DIRECTOR', 'th', 'ผู้บริหาร'),
('ROLE', 'MANAGING_DIRECTOR', 'en', 'Managing Director'),

-- Permissions
('PERMISSION', 'CREATE', 'th', 'สร้าง'),
('PERMISSION', 'CREATE', 'en', 'Create'),
('PERMISSION', 'UPDATE', 'th', 'แก้ไข'),
('PERMISSION', 'UPDATE', 'en', 'Update'),
('PERMISSION', 'READ', 'th', 'ดูข้อมูล'),
('PERMISSION', 'READ', 'en', 'Read'),
('PERMISSION', 'DELETE', 'th', 'ลบ'),
('PERMISSION', 'DELETE', 'en', 'Delete'),
('PERMISSION', 'CONSIDER', 'th', 'ตัดสินใจ'),
('PERMISSION', 'CONSIDER', 'en', 'Consider'),
('PERMISSION', 'INVITE', 'th', 'เชิญ Supplier'),
('PERMISSION', 'INVITE', 'en', 'Invite Supplier'),
('PERMISSION', 'INSERT', 'th', 'เพิ่มข้อมูล'),
('PERMISSION', 'INSERT', 'en', 'Insert'),
('PERMISSION', 'PRE_APPROVE', 'th', 'ตรวจสอบข้อมูล Supplier'),
('PERMISSION', 'PRE_APPROVE', 'en', 'Pre Approve Supplier'),
('PERMISSION', 'FIRST_SELECT_WINNER', 'th', 'เลือกผู้ชนะเบื้องต้น'),
('PERMISSION', 'FIRST_SELECT_WINNER', 'en', 'First Select Winner'),
('PERMISSION', 'FINAL_WINNER', 'th', 'เลือกผู้ชนะสุดท้าย'),
('PERMISSION', 'FINAL_WINNER', 'en', 'Final Winner'),
('PERMISSION', 'APPROVE_SUPPLIER', 'th', 'อนุมัติ Supplier ใหม่'),
('PERMISSION', 'APPROVE_SUPPLIER', 'en', 'Approve Supplier');

-- SECTION 4: SUPPLIER MANAGEMENT
INSERT INTO "Translations" ("Module", "Key", "LanguageCode", "Value") VALUES
-- Supplier Status
('SUPPLIER', 'STATUS_PENDING', 'th', 'รอการอนุมัติ'),
('SUPPLIER', 'STATUS_PENDING', 'en', 'Pending'),
('SUPPLIER', 'STATUS_COMPLETED', 'th', 'อนุมัติแล้ว'),
('SUPPLIER', 'STATUS_COMPLETED', 'en', 'Completed'),
('SUPPLIER', 'STATUS_DECLINED', 'th', 'ส่งกลับแก้ไข'),
('SUPPLIER', 'STATUS_DECLINED', 'en', 'Declined'),

-- Business Types
('BUSINESS_TYPE', 'INDIVIDUAL', 'th', 'บุคคลธรรมดา'),
('BUSINESS_TYPE', 'INDIVIDUAL', 'en', 'Individual'),
('BUSINESS_TYPE', 'JURISTIC', 'th', 'นิติบุคคล'),
('BUSINESS_TYPE', 'JURISTIC', 'en', 'Juristic Person'),

-- Job Types
('JOB_TYPE', 'BUY', 'th', 'ซื้อ'),
('JOB_TYPE', 'BUY', 'en', 'Buy'),
('JOB_TYPE', 'SELL', 'th', 'ขาย'),
('JOB_TYPE', 'SELL', 'en', 'Sell'),
('JOB_TYPE', 'BOTH', 'th', 'ทั้งซื้อและขาย'),
('JOB_TYPE', 'BOTH', 'en', 'Both Buy and Sell'),

-- Document Types
('DOCUMENT', 'COMPANY_CERT', 'th', 'หนังสือรับรอง'),
('DOCUMENT', 'COMPANY_CERT', 'en', 'Company Registration Certificate'),
('DOCUMENT', 'PP20', 'th', 'ภ.พ.20'),
('DOCUMENT', 'PP20', 'en', 'VAT Registration (Por Por 20)'),
('DOCUMENT', 'FINANCIAL_REPORT', 'th', 'รายงานทางการเงิน'),
('DOCUMENT', 'FINANCIAL_REPORT', 'en', 'Financial Statement'),
('DOCUMENT', 'COMPANY_PROFILE', 'th', 'แนะนำบริษัท'),
('DOCUMENT', 'COMPANY_PROFILE', 'en', 'Company Profile'),
('DOCUMENT', 'NDA', 'th', 'หนังสือสัญญารักษาความลับ'),
('DOCUMENT', 'NDA', 'en', 'Non-Disclosure Agreement'),
('DOCUMENT', 'ID_CARD', 'th', 'สำเนาบัตรประชาชน'),
('DOCUMENT', 'ID_CARD', 'en', 'ID Card Copy'),
('DOCUMENT', 'OTHER', 'th', 'อื่นๆ'),
('DOCUMENT', 'OTHER', 'en', 'Other');

-- SECTION 5: RFQ MANAGEMENT
INSERT INTO "Translations" ("Module", "Key", "LanguageCode", "Value") VALUES
-- RFQ Status
('RFQ', 'STATUS_SAVE_DRAFT', 'th', 'บันทึกแบบร่าง'),
('RFQ', 'STATUS_SAVE_DRAFT', 'en', 'Save Draft'),
('RFQ', 'STATUS_PENDING', 'th', 'รอดำเนินการ'),
('RFQ', 'STATUS_PENDING', 'en', 'Pending'),
('RFQ', 'STATUS_DECLINED', 'th', 'ส่งกลับแก้ไข'),
('RFQ', 'STATUS_DECLINED', 'en', 'Declined'),
('RFQ', 'STATUS_REJECTED', 'th', 'ปฏิเสธ'),
('RFQ', 'STATUS_REJECTED', 'en', 'Rejected'),
('RFQ', 'STATUS_COMPLETED', 'th', 'เสร็จสิ้น'),
('RFQ', 'STATUS_COMPLETED', 'en', 'Completed'),
('RFQ', 'STATUS_RE_BID', 'th', 'เชิญเสนอราคาใหม่'),
('RFQ', 'STATUS_RE_BID', 'en', 'Re-Bid'),

-- RFQ Labels
('RFQ', 'LABEL_NUMBER', 'th', 'เลขที่เอกสาร'),
('RFQ', 'LABEL_NUMBER', 'en', 'RFQ Number'),
('RFQ', 'LABEL_PROJECT', 'th', 'ชื่อโครงงาน/งาน'),
('RFQ', 'LABEL_PROJECT', 'en', 'Project Name'),
('RFQ', 'LABEL_CATEGORY', 'th', 'กลุ่มสินค้า/บริการ'),
('RFQ', 'LABEL_CATEGORY', 'en', 'Category'),
('RFQ', 'LABEL_SUBCATEGORY', 'th', 'หมวดหมู่ย่อยสินค้า/บริการ'),
('RFQ', 'LABEL_SUBCATEGORY', 'en', 'Subcategory'),
('RFQ', 'LABEL_REQUESTER', 'th', 'ผู้ร้องขอ'),
('RFQ', 'LABEL_REQUESTER', 'en', 'Requester'),
('RFQ', 'LABEL_COMPANY', 'th', 'บริษัทผู้ร้องขอ'),
('RFQ', 'LABEL_COMPANY', 'en', 'Requester Company'),
('RFQ', 'LABEL_DEPARTMENT', 'th', 'ฝ่ายงานที่ร้องขอ'),
('RFQ', 'LABEL_DEPARTMENT', 'en', 'Department'),
('RFQ', 'LABEL_RESPONSIBLE', 'th', 'ผู้รับผิดชอบ'),
('RFQ', 'LABEL_RESPONSIBLE', 'en', 'Responsible Person'),
('RFQ', 'LABEL_BUDGET', 'th', 'งบประมาณ'),
('RFQ', 'LABEL_BUDGET', 'en', 'Budget'),
('RFQ', 'LABEL_REQUIRED_DATE', 'th', 'วันที่ต้องการใบเสนอราคา'),
('RFQ', 'LABEL_REQUIRED_DATE', 'en', 'Required Quotation Date'),
('RFQ', 'LABEL_SUBMISSION_DEADLINE', 'th', 'วันที่สิ้นสุดการเสนอราคา'),
('RFQ', 'LABEL_SUBMISSION_DEADLINE', 'en', 'Submission Deadline'),
('RFQ', 'LABEL_URGENT', 'th', 'งานด่วน'),
('RFQ', 'LABEL_URGENT', 'en', 'Urgent'),

-- RFQ Items
('RFQ_ITEM', 'LABEL_SEQUENCE', 'th', 'ลำดับ'),
('RFQ_ITEM', 'LABEL_SEQUENCE', 'en', 'No.'),
('RFQ_ITEM', 'LABEL_CODE', 'th', 'รหัส'),
('RFQ_ITEM', 'LABEL_CODE', 'en', 'Code'),
('RFQ_ITEM', 'LABEL_DESCRIPTION', 'th', 'สินค้า'),
('RFQ_ITEM', 'LABEL_DESCRIPTION', 'en', 'Item'),
('RFQ_ITEM', 'LABEL_BRAND', 'th', 'ยี่ห้อ'),
('RFQ_ITEM', 'LABEL_BRAND', 'en', 'Brand'),
('RFQ_ITEM', 'LABEL_MODEL', 'th', 'รุ่น'),
('RFQ_ITEM', 'LABEL_MODEL', 'en', 'Model'),
('RFQ_ITEM', 'LABEL_QUANTITY', 'th', 'จำนวน'),
('RFQ_ITEM', 'LABEL_QUANTITY', 'en', 'Quantity'),
('RFQ_ITEM', 'LABEL_UNIT', 'th', 'หน่วย'),
('RFQ_ITEM', 'LABEL_UNIT', 'en', 'Unit'),
('RFQ_ITEM', 'LABEL_SPECIFICATIONS', 'th', 'รายละเอียดสินค้า'),
('RFQ_ITEM', 'LABEL_SPECIFICATIONS', 'en', 'Specifications');

-- SECTION 6: WORKFLOW & APPROVAL
INSERT INTO "Translations" ("Module", "Key", "LanguageCode", "Value") VALUES
-- Actions
('ACTION', 'APPROVE', 'th', 'อนุมัติ'),
('ACTION', 'APPROVE', 'en', 'Approve'),
('ACTION', 'ACCEPT', 'th', 'ยอมรับ'),
('ACTION', 'ACCEPT', 'en', 'Accept'),
('ACTION', 'DECLINE', 'th', 'ส่งกลับแก้ไข'),
('ACTION', 'DECLINE', 'en', 'Decline'),
('ACTION', 'REJECT', 'th', 'ปฏิเสธ'),
('ACTION', 'REJECT', 'en', 'Reject'),
('ACTION', 'SUBMIT', 'th', 'ส่ง'),
('ACTION', 'SUBMIT', 'en', 'Submit'),
('ACTION', 'SAVE_DRAFT', 'th', 'บันทึกแบบร่าง'),
('ACTION', 'SAVE_DRAFT', 'en', 'Save Draft'),
('ACTION', 'PREVIEW', 'th', 'พรีวิวก่อนส่ง'),
('ACTION', 'PREVIEW', 'en', 'Preview'),
('ACTION', 'RE_BID', 'th', 'เชิญเสนอราคาใหม่'),
('ACTION', 'RE_BID', 'en', 'Re-Bid'),

-- Decision
('DECISION', 'APPROVED', 'th', 'อนุมัติแล้ว'),
('DECISION', 'APPROVED', 'en', 'Approved'),
('DECISION', 'DECLINED', 'th', 'ส่งกลับแก้ไข'),
('DECISION', 'DECLINED', 'en', 'Declined'),
('DECISION', 'REJECTED', 'th', 'ปฏิเสธแล้ว'),
('DECISION', 'REJECTED', 'en', 'Rejected'),
('DECISION', 'SUBMITTED', 'th', 'ส่งแล้ว'),
('DECISION', 'SUBMITTED', 'en', 'Submitted'),

-- Timeline Status
('TIMELINE', 'ONTIME', 'th', 'ตรงเวลา'),
('TIMELINE', 'ONTIME', 'en', 'On Time'),
('TIMELINE', 'DELAY', 'th', 'ล่าช้า'),
('TIMELINE', 'DELAY', 'en', 'Delayed'),
('TIMELINE', 'OVERDUE', 'th', 'เกินกำหนด'),
('TIMELINE', 'OVERDUE', 'en', 'Overdue');

-- SECTION 7: QUOTATION MANAGEMENT
INSERT INTO "Translations" ("Module", "Key", "LanguageCode", "Value") VALUES
-- Invitation Status
('INVITATION', 'STATUS_NO_RESPONSE', 'th', 'ยังไม่ตอบรับ'),
('INVITATION', 'STATUS_NO_RESPONSE', 'en', 'No Response'),
('INVITATION', 'STATUS_RESPONDED', 'th', 'ตอบรับแล้ว'),
('INVITATION', 'STATUS_RESPONDED', 'en', 'Responded'),

-- Invitation Decision
('INVITATION', 'DECISION_PENDING', 'th', 'รอการตอบรับ'),
('INVITATION', 'DECISION_PENDING', 'en', 'Pending'),
('INVITATION', 'DECISION_PARTICIPATING', 'th', 'เข้าร่วม'),
('INVITATION', 'DECISION_PARTICIPATING', 'en', 'Participating'),
('INVITATION', 'DECISION_NOT_PARTICIPATING', 'th', 'ไม่เข้าร่วม'),
('INVITATION', 'DECISION_NOT_PARTICIPATING', 'en', 'Not Participating'),
('INVITATION', 'DECISION_AUTO_DECLINED', 'th', 'ระบบปฏิเสธอัตโนมัติ'),
('INVITATION', 'DECISION_AUTO_DECLINED', 'en', 'Auto Declined'),

-- Quotation Labels
('QUOTATION', 'LABEL_UNIT_PRICE', 'th', 'ราคาต่อหน่วย'),
('QUOTATION', 'LABEL_UNIT_PRICE', 'en', 'Unit Price'),
('QUOTATION', 'LABEL_TOTAL_PRICE', 'th', 'ราคารวม'),
('QUOTATION', 'LABEL_TOTAL_PRICE', 'en', 'Total Price'),
('QUOTATION', 'LABEL_CURRENCY', 'th', 'สกุลเงิน'),
('QUOTATION', 'LABEL_CURRENCY', 'en', 'Currency'),
('QUOTATION', 'LABEL_COMPANY_PRICE', 'th', 'ราคาของบริษัท'),
('QUOTATION', 'LABEL_COMPANY_PRICE', 'en', 'Company Price'),
('QUOTATION', 'LABEL_MOQ', 'th', 'จำนวนขั้นต่ำ'),
('QUOTATION', 'LABEL_MOQ', 'en', 'MOQ'),
('QUOTATION', 'LABEL_DLT', 'th', 'ระยะเวลาส่งมอบ (วัน)'),
('QUOTATION', 'LABEL_DLT', 'en', 'Delivery Time (Days)'),
('QUOTATION', 'LABEL_CREDIT', 'th', 'เครดิต (วัน)'),
('QUOTATION', 'LABEL_CREDIT', 'en', 'Credit (Days)'),
('QUOTATION', 'LABEL_WARRANTY', 'th', 'รับประกัน (วัน)'),
('QUOTATION', 'LABEL_WARRANTY', 'en', 'Warranty (Days)'),
('QUOTATION', 'LABEL_INCOTERM', 'th', 'เงื่อนไขการส่งมอบ'),
('QUOTATION', 'LABEL_INCOTERM', 'en', 'Inco Term'),
('QUOTATION', 'LABEL_DOCUMENT', 'th', 'ใบเสนอราคา'),
('QUOTATION', 'LABEL_DOCUMENT', 'en', 'Quotation Document'),

-- Winner Status
('WINNER', 'LABEL_WINNER', 'th', 'ผู้ชนะ'),
('WINNER', 'LABEL_WINNER', 'en', 'Winner'),
('WINNER', 'LABEL_RANK', 'th', 'ลำดับ'),
('WINNER', 'LABEL_RANK', 'en', 'Rank'),
('WINNER', 'LABEL_SYSTEM_SELECTED', 'th', 'ระบบเลือก'),
('WINNER', 'LABEL_SYSTEM_SELECTED', 'en', 'System Selected'),
('WINNER', 'LABEL_USER_SELECTED', 'th', 'ผู้ใช้เลือก'),
('WINNER', 'LABEL_USER_SELECTED', 'en', 'User Selected'),
('WINNER', 'LABEL_REASON', 'th', 'เหตุผล'),
('WINNER', 'LABEL_REASON', 'en', 'Reason');

-- SECTION 8: COMMUNICATION & Q&A
INSERT INTO "Translations" ("Module", "Key", "LanguageCode", "Value") VALUES
-- Q&A Status
('QNA', 'STATUS_OPEN', 'th', 'เปิด'),
('QNA', 'STATUS_OPEN', 'en', 'Open'),
('QNA', 'STATUS_CLOSED', 'th', 'ปิด'),
('QNA', 'STATUS_CLOSED', 'en', 'Closed'),

-- Q&A Labels
('QNA', 'LABEL_QUESTION', 'th', 'คำถาม'),
('QNA', 'LABEL_QUESTION', 'en', 'Question'),
('QNA', 'LABEL_ANSWER', 'th', 'คำตอบ'),
('QNA', 'LABEL_ANSWER', 'en', 'Answer'),
('QNA', 'LABEL_ASK_QUESTION', 'th', 'ส่งคำถาม'),
('QNA', 'LABEL_ASK_QUESTION', 'en', 'Ask Question'),
('QNA', 'LABEL_REPLY', 'th', 'ตอบกลับ'),
('QNA', 'LABEL_REPLY', 'en', 'Reply'),
('QNA', 'LABEL_AWAITING', 'th', 'รอคำตอบ'),
('QNA', 'LABEL_AWAITING', 'en', 'Awaiting Reply'),
('QNA', 'LABEL_RESPONDED', 'th', 'ตอบแล้ว'),
('QNA', 'LABEL_RESPONDED', 'en', 'Responded');

-- SECTION 9: NOTIFICATION SYSTEM
INSERT INTO "Translations" ("Module", "Key", "LanguageCode", "Value") VALUES
-- Notification Types
('NOTIFICATION', 'TYPE_INFO', 'th', 'ข้อมูล'),
('NOTIFICATION', 'TYPE_INFO', 'en', 'Info'),
('NOTIFICATION', 'TYPE_SUCCESS', 'th', 'สำเร็จ'),
('NOTIFICATION', 'TYPE_SUCCESS', 'en', 'Success'),
('NOTIFICATION', 'TYPE_WARNING', 'th', 'คำเตือน'),
('NOTIFICATION', 'TYPE_WARNING', 'en', 'Warning'),
('NOTIFICATION', 'TYPE_ERROR', 'th', 'ข้อผิดพลาด'),
('NOTIFICATION', 'TYPE_ERROR', 'en', 'Error'),

-- Notification Priority
('NOTIFICATION', 'PRIORITY_LOW', 'th', 'ต่ำ'),
('NOTIFICATION', 'PRIORITY_LOW', 'en', 'Low'),
('NOTIFICATION', 'PRIORITY_NORMAL', 'th', 'ปกติ'),
('NOTIFICATION', 'PRIORITY_NORMAL', 'en', 'Normal'),
('NOTIFICATION', 'PRIORITY_HIGH', 'th', 'สูง'),
('NOTIFICATION', 'PRIORITY_HIGH', 'en', 'High'),
('NOTIFICATION', 'PRIORITY_URGENT', 'th', 'ด่วน'),
('NOTIFICATION', 'PRIORITY_URGENT', 'en', 'Urgent'),

-- Notification Messages
('NOTIFICATION', 'MSG_RFQ_CREATED', 'th', 'สร้างใบขอเสนอราคา {rfqNumber} แล้ว'),
('NOTIFICATION', 'MSG_RFQ_CREATED', 'en', 'RFQ {rfqNumber} has been created'),
('NOTIFICATION', 'MSG_RFQ_APPROVED', 'th', 'อนุมัติใบขอเสนอราคา {rfqNumber} แล้ว'),
('NOTIFICATION', 'MSG_RFQ_APPROVED', 'en', 'RFQ {rfqNumber} has been approved'),
('NOTIFICATION', 'MSG_RFQ_DECLINED', 'th', 'ส่งกลับใบขอเสนอราคา {rfqNumber} เพื่อแก้ไข'),
('NOTIFICATION', 'MSG_RFQ_DECLINED', 'en', 'RFQ {rfqNumber} has been declined for revision'),
('NOTIFICATION', 'MSG_RFQ_REJECTED', 'th', 'ปฏิเสธใบขอเสนอราคา {rfqNumber}'),
('NOTIFICATION', 'MSG_RFQ_REJECTED', 'en', 'RFQ {rfqNumber} has been rejected'),
('NOTIFICATION', 'MSG_SUPPLIER_INVITED', 'th', 'คุณได้รับเชิญให้เสนอราคา {rfqNumber}'),
('NOTIFICATION', 'MSG_SUPPLIER_INVITED', 'en', 'You have been invited to quote for {rfqNumber}'),
('NOTIFICATION', 'MSG_QUOTATION_RECEIVED', 'th', 'ได้รับใบเสนอราคาจาก {supplierName}'),
('NOTIFICATION', 'MSG_QUOTATION_RECEIVED', 'en', 'Quotation received from {supplierName}'),
('NOTIFICATION', 'MSG_WINNER_SELECTED', 'th', 'เลือกผู้ชนะสำหรับ {rfqNumber} แล้ว'),
('NOTIFICATION', 'MSG_WINNER_SELECTED', 'en', 'Winner selected for {rfqNumber}'),
('NOTIFICATION', 'MSG_QNA_NEW_QUESTION', 'th', '{supplierName} ถามคำถามใหม่'),
('NOTIFICATION', 'MSG_QNA_NEW_QUESTION', 'en', '{supplierName} asked a new question'),
('NOTIFICATION', 'MSG_QNA_ANSWERED', 'th', 'คำถามของคุณได้รับคำตอบแล้ว'),
('NOTIFICATION', 'MSG_QNA_ANSWERED', 'en', 'Your question has been answered'),
('NOTIFICATION', 'MSG_DEADLINE_REMINDER', 'th', 'เหลือเวลา {hours} ชั่วโมงก่อนหมดเขตส่งเอกสาร'),
('NOTIFICATION', 'MSG_DEADLINE_REMINDER', 'en', '{hours} hours remaining before deadline');

-- COMMON LABELS
INSERT INTO "Translations" ("Module", "Key", "LanguageCode", "Value") VALUES
-- Buttons
('COMMON', 'BTN_SAVE', 'th', 'บันทึก'),
('COMMON', 'BTN_SAVE', 'en', 'Save'),
('COMMON', 'BTN_CANCEL', 'th', 'ยกเลิก'),
('COMMON', 'BTN_CANCEL', 'en', 'Cancel'),
('COMMON', 'BTN_EDIT', 'th', 'แก้ไข'),
('COMMON', 'BTN_EDIT', 'en', 'Edit'),
('COMMON', 'BTN_DELETE', 'th', 'ลบ'),
('COMMON', 'BTN_DELETE', 'en', 'Delete'),
('COMMON', 'BTN_ADD', 'th', 'เพิ่ม'),
('COMMON', 'BTN_ADD', 'en', 'Add'),
('COMMON', 'BTN_SEARCH', 'th', 'ค้นหา'),
('COMMON', 'BTN_SEARCH', 'en', 'Search'),
('COMMON', 'BTN_EXPORT', 'th', 'ส่งออก'),
('COMMON', 'BTN_EXPORT', 'en', 'Export'),
('COMMON', 'BTN_IMPORT', 'th', 'นำเข้า'),
('COMMON', 'BTN_IMPORT', 'en', 'Import'),
('COMMON', 'BTN_UPLOAD', 'th', 'อัพโหลด'),
('COMMON', 'BTN_UPLOAD', 'en', 'Upload'),
('COMMON', 'BTN_DOWNLOAD', 'th', 'ดาวน์โหลด'),
('COMMON', 'BTN_DOWNLOAD', 'en', 'Download'),

-- Messages
('COMMON', 'MSG_CONFIRM_DELETE', 'th', 'คุณแน่ใจที่จะลบรายการนี้?'),
('COMMON', 'MSG_CONFIRM_DELETE', 'en', 'Are you sure you want to delete this item?'),
('COMMON', 'MSG_SAVE_SUCCESS', 'th', 'บันทึกข้อมูลสำเร็จ'),
('COMMON', 'MSG_SAVE_SUCCESS', 'en', 'Data saved successfully'),
('COMMON', 'MSG_DELETE_SUCCESS', 'th', 'ลบข้อมูลสำเร็จ'),
('COMMON', 'MSG_DELETE_SUCCESS', 'en', 'Data deleted successfully'),
('COMMON', 'MSG_ERROR', 'th', 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง'),
('COMMON', 'MSG_ERROR', 'en', 'An error occurred. Please try again'),
('COMMON', 'MSG_REQUIRED_FIELD', 'th', 'กรุณากรอกข้อมูลที่จำเป็น'),
('COMMON', 'MSG_REQUIRED_FIELD', 'en', 'Please fill in required fields'),

-- Date/Time
('DATETIME', 'TODAY', 'th', 'วันนี้'),
('DATETIME', 'TODAY', 'en', 'Today'),
('DATETIME', 'YESTERDAY', 'th', 'เมื่อวาน'),
('DATETIME', 'YESTERDAY', 'en', 'Yesterday'),
('DATETIME', 'DAYS_AGO', 'th', '{days} วันที่แล้ว'),
('DATETIME', 'DAYS_AGO', 'en', '{days} days ago'),
('DATETIME', 'HOURS_AGO', 'th', '{hours} ชั่วโมงที่แล้ว'),
('DATETIME', 'HOURS_AGO', 'en', '{hours} hours ago'),
('DATETIME', 'MINUTES_AGO', 'th', '{minutes} นาทีที่แล้ว'),
('DATETIME', 'MINUTES_AGO', 'en', '{minutes} minutes ago'),
('DATETIME', 'JUST_NOW', 'th', 'เมื่อสักครู่'),
('DATETIME', 'JUST_NOW', 'en', 'Just now');