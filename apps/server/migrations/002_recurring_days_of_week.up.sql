-- ============================================================================
-- Migration: 002_recurring_days_of_week.up.sql
-- Description: Add multi-weekday scheduling support (ISO 1=Mon..7=Sun CSV) to recurring_configs
-- ============================================================================

ALTER TABLE recurring_configs
    ADD COLUMN IF NOT EXISTS days_of_week VARCHAR(20);
