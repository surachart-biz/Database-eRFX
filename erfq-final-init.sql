-- =============================================
-- E-RFQ System Complete Database Schema v5.0
-- Production Ready Version
-- Database: erfq_system
-- PostgreSQL Version: 14+
-- Last Updated: January 2025
-- =============================================

-- =============================================
-- DATABASE CONFIGURATION
-- =============================================
CREATE ROLE erfx WITH LOGIN PASSWORD 'erfx_2025' SUPERUSER;

CREATE DATABASE erfxdb_dev WITH OWNER = erfx ENCODING = 'UTF8' LC_COLLATE = 'en_US.UTF-8' LC_CTYPE = 'en_US.UTF-8' TABLESPACE = pg_default CONNECTION LIMIT = -1 TEMPLATE template0;

-- Enable Required Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";    -- สำหรับ generate UUID
CREATE EXTENSION IF NOT EXISTS "pgcrypto";     -- สำหรับ encryption
