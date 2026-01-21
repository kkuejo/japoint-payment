-- JAPOINT Payment History Database Schema

-- Payments table - stores all payment transactions
CREATE TABLE IF NOT EXISTS payments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tx_hash TEXT UNIQUE NOT NULL,
    sender_address TEXT NOT NULL,
    shop_address TEXT NOT NULL,
    company_address TEXT NOT NULL,
    total_amount TEXT NOT NULL,  -- Store as string to handle large numbers
    shop_amount TEXT NOT NULL,
    company_amount TEXT NOT NULL,
    japt_amount TEXT NOT NULL,
    plan_type TEXT NOT NULL,     -- 'transfer5' or 'transfer10'
    block_number INTEGER NOT NULL,
    block_timestamp INTEGER NOT NULL,
    created_at TEXT DEFAULT (datetime('now'))
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_payments_sender ON payments(sender_address);
CREATE INDEX IF NOT EXISTS idx_payments_shop ON payments(shop_address);
CREATE INDEX IF NOT EXISTS idx_payments_timestamp ON payments(block_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_payments_plan_type ON payments(plan_type);

-- Daily summary table for quick aggregations
CREATE TABLE IF NOT EXISTS daily_summary (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL,
    plan_type TEXT NOT NULL,
    total_transactions INTEGER DEFAULT 0,
    total_jpyc TEXT DEFAULT '0',
    total_japt TEXT DEFAULT '0',
    total_shop_revenue TEXT DEFAULT '0',
    total_company_revenue TEXT DEFAULT '0',
    UNIQUE(date, plan_type)
);

CREATE INDEX IF NOT EXISTS idx_daily_summary_date ON daily_summary(date DESC);
