-- ============================================================================
-- Migration: 001_initial_schema.up.sql
-- Description: Core schema for Simo multi-device sync & web management
-- ============================================================================

-- 1. Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    google_id VARCHAR(255) UNIQUE,
    display_name VARCHAR(255),
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- 2. User Settings table
CREATE TABLE IF NOT EXISTS user_settings (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    currency VARCHAR(10) NOT NULL DEFAULT 'VND',
    language VARCHAR(10) NOT NULL DEFAULT 'vi',
    theme_mode VARCHAR(20) NOT NULL DEFAULT 'system',
    monthly_budget NUMERIC(15, 2) DEFAULT 0,
    server_updated_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- 3. Wallets table
CREATE TABLE IF NOT EXISTS wallets (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    initial_balance NUMERIC(15, 2) NOT NULL DEFAULT 0.0,
    color VARCHAR(20) NOT NULL DEFAULT '#10B981',
    icon VARCHAR(100) NOT NULL DEFAULT 'wallet',
    currency VARCHAR(10),
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    exclude_from_total BOOLEAN NOT NULL DEFAULT FALSE,
    priority INTEGER NOT NULL DEFAULT 0,
    client_created_at TIMESTAMPTZ NOT NULL,
    client_updated_at TIMESTAMPTZ NOT NULL,
    server_updated_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    deleted_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_wallets_user_sync ON wallets(user_id, server_updated_at);

-- 4. Categories table
CREATE TABLE IF NOT EXISTS categories (
    id VARCHAR(100) NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(20) NOT NULL, -- 'income' or 'expense'
    icon VARCHAR(100),
    color VARCHAR(20),
    budget_limit NUMERIC(15, 2),
    client_created_at TIMESTAMPTZ NOT NULL,
    client_updated_at TIMESTAMPTZ NOT NULL,
    server_updated_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    deleted_at TIMESTAMPTZ,
    PRIMARY KEY (user_id, id)
);
CREATE INDEX IF NOT EXISTS idx_categories_user_sync ON categories(user_id, server_updated_at);

-- 5. Wallet Transfers table
CREATE TABLE IF NOT EXISTS wallet_transfers (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    source_wallet_id UUID NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
    destination_wallet_id UUID NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
    amount NUMERIC(15, 2) NOT NULL,
    fee NUMERIC(15, 2) NOT NULL DEFAULT 0.0,
    transfer_date TIMESTAMPTZ NOT NULL,
    note TEXT,
    client_created_at TIMESTAMPTZ NOT NULL,
    client_updated_at TIMESTAMPTZ NOT NULL,
    server_updated_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    deleted_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_transfers_user_sync ON wallet_transfers(user_id, server_updated_at);

-- 6. Recurring Configs table
CREATE TABLE IF NOT EXISTS recurring_configs (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id VARCHAR(100),
    wallet_id UUID REFERENCES wallets(id) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    amount NUMERIC(15, 2) NOT NULL,
    type VARCHAR(20) NOT NULL,
    frequency VARCHAR(20) NOT NULL,
    interval INTEGER NOT NULL DEFAULT 1,
    day_of_week INTEGER,
    day_of_month INTEGER,
    next_run TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    client_created_at TIMESTAMPTZ NOT NULL,
    client_updated_at TIMESTAMPTZ NOT NULL,
    server_updated_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    deleted_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_recurring_user_sync ON recurring_configs(user_id, server_updated_at);

-- 7. Transactions table
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    wallet_id UUID REFERENCES wallets(id) ON DELETE SET NULL,
    category_id VARCHAR(100),
    recurring_config_id UUID REFERENCES recurring_configs(id) ON DELETE SET NULL,
    amount NUMERIC(15, 2) NOT NULL,
    formula TEXT,
    note TEXT,
    type VARCHAR(20) NOT NULL, -- 'income' or 'expense'
    transaction_date DATE NOT NULL,
    client_created_at TIMESTAMPTZ NOT NULL,
    client_updated_at TIMESTAMPTZ NOT NULL,
    server_updated_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    deleted_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_transactions_user_sync ON transactions(user_id, server_updated_at);
CREATE INDEX IF NOT EXISTS idx_transactions_user_date ON transactions(user_id, transaction_date DESC);

-- 8. Monthly Budgets table
CREATE TABLE IF NOT EXISTS monthly_budgets (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    amount NUMERIC(15, 2) NOT NULL,
    client_created_at TIMESTAMPTZ NOT NULL,
    client_updated_at TIMESTAMPTZ NOT NULL,
    server_updated_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    deleted_at TIMESTAMPTZ,
    CONSTRAINT uq_monthly_budgets_user_ym UNIQUE(user_id, year, month)
);
CREATE INDEX IF NOT EXISTS idx_monthly_budgets_user_sync ON monthly_budgets(user_id, server_updated_at);

-- 9. Category Monthly Budgets table
CREATE TABLE IF NOT EXISTS category_monthly_budgets (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id VARCHAR(100) NOT NULL,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    amount NUMERIC(15, 2) NOT NULL,
    client_created_at TIMESTAMPTZ NOT NULL,
    client_updated_at TIMESTAMPTZ NOT NULL,
    server_updated_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    deleted_at TIMESTAMPTZ,
    CONSTRAINT uq_cat_monthly_budgets_user_cym UNIQUE(user_id, category_id, year, month)
);
CREATE INDEX IF NOT EXISTS idx_cat_monthly_budgets_user_sync ON category_monthly_budgets(user_id, server_updated_at);

-- 10. Saving Goals table
CREATE TABLE IF NOT EXISTS saving_goals (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    target_amount NUMERIC(15, 2) NOT NULL,
    current_amount NUMERIC(15, 2) NOT NULL DEFAULT 0.0,
    target_date DATE,
    color VARCHAR(20),
    icon VARCHAR(100),
    note TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    client_created_at TIMESTAMPTZ NOT NULL,
    client_updated_at TIMESTAMPTZ NOT NULL,
    server_updated_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    deleted_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_saving_goals_user_sync ON saving_goals(user_id, server_updated_at);

-- 11. Saving Goal Logs table
CREATE TABLE IF NOT EXISTS saving_goal_logs (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    goal_id UUID NOT NULL REFERENCES saving_goals(id) ON DELETE CASCADE,
    amount NUMERIC(15, 2) NOT NULL,
    type VARCHAR(20) NOT NULL, -- 'deposit' or 'withdraw'
    log_date TIMESTAMPTZ NOT NULL,
    note TEXT,
    client_created_at TIMESTAMPTZ NOT NULL,
    client_updated_at TIMESTAMPTZ NOT NULL,
    server_updated_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    deleted_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_saving_logs_user_sync ON saving_goal_logs(user_id, server_updated_at);

-- 12. Loan Contacts table
CREATE TABLE IF NOT EXISTS loan_contacts (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    contact_name VARCHAR(255) NOT NULL,
    type VARCHAR(20) NOT NULL, -- 'lend' or 'borrow'
    total_amount NUMERIC(15, 2) NOT NULL,
    remaining_amount NUMERIC(15, 2) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    client_created_at TIMESTAMPTZ NOT NULL,
    client_updated_at TIMESTAMPTZ NOT NULL,
    server_updated_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    deleted_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_loan_contacts_user_sync ON loan_contacts(user_id, server_updated_at);

-- 13. Loan Transactions table
CREATE TABLE IF NOT EXISTS loan_transactions (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    loan_id UUID NOT NULL REFERENCES loan_contacts(id) ON DELETE CASCADE,
    amount NUMERIC(15, 2) NOT NULL,
    type VARCHAR(20) NOT NULL,
    date TIMESTAMPTZ NOT NULL,
    due_date DATE,
    note TEXT,
    client_created_at TIMESTAMPTZ NOT NULL,
    client_updated_at TIMESTAMPTZ NOT NULL,
    server_updated_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    deleted_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_loan_tx_user_sync ON loan_transactions(user_id, server_updated_at);
