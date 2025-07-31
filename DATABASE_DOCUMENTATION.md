# Savessa Database Documentation

## Overview

This document provides comprehensive documentation for the Savessa app's PostgreSQL database. It includes information about the database schema, tables, relationships, and SQL commands needed for the system to work effectively.

## Connection Details

The PostgreSQL database connection details are stored in environment variables for security reasons. 
See the `.env.example` file for the required environment variables structure.

```
# Example structure (DO NOT use these values in production)
DB_HOST=your-database-host.example.com
DB_PORT=5432
DB_NAME=your_database_name
DB_USER=your_username
DB_PASSWORD=your_password
DB_SSL=require
```

## Database Schema

The database schema consists of the following tables:

### Users Table

Stores information about users of the application.

```sql
CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    other_names VARCHAR(100),
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('admin', 'member')),
    password_hash VARCHAR(255) NOT NULL,
    profile_image_url VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
```

### Groups Table

Stores information about savings groups.

```sql
CREATE TABLE IF NOT EXISTS groups (
    group_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    created_by INT NOT NULL REFERENCES users(user_id),
    contribution_amount DECIMAL(12, 2) NOT NULL,
    contribution_frequency VARCHAR(20) NOT NULL CHECK (contribution_frequency IN ('weekly', 'monthly', 'quarterly', 'yearly')),
    start_date DATE NOT NULL,
    end_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP
);
```

### Group Members Table

Manages the many-to-many relationship between users and groups.

```sql
CREATE TABLE IF NOT EXISTS group_members (
    group_member_id SERIAL PRIMARY KEY,
    group_id INT NOT NULL REFERENCES groups(group_id),
    user_id INT NOT NULL REFERENCES users(user_id),
    role VARCHAR(20) NOT NULL CHECK (role IN ('admin', 'member')),
    joined_at TIMESTAMP NOT NULL DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(group_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_group_members_group_id ON group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user_id ON group_members(user_id);
```

### Savings Table

Records contributions made by users to groups.

```sql
CREATE TABLE IF NOT EXISTS savings (
    saving_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(user_id),
    group_id INT NOT NULL REFERENCES groups(group_id),
    amount DECIMAL(12, 2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    payment_reference VARCHAR(100),
    receipt_url VARCHAR(255),
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'verified', 'rejected')),
    contribution_date DATE NOT NULL,
    verified_by INT REFERENCES users(user_id),
    verified_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_savings_user_id ON savings(user_id);
CREATE INDEX IF NOT EXISTS idx_savings_group_id ON savings(group_id);
CREATE INDEX IF NOT EXISTS idx_savings_contribution_date ON savings(contribution_date);
```

### Transactions Table

Tracks all financial transactions in the system.

```sql
CREATE TABLE IF NOT EXISTS transactions (
    transaction_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(user_id),
    group_id INT REFERENCES groups(group_id),
    saving_id INT REFERENCES savings(saving_id),
    transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('deposit', 'withdrawal', 'transfer', 'fee')),
    amount DECIMAL(12, 2) NOT NULL,
    fee DECIMAL(12, 2) DEFAULT 0,
    payment_method VARCHAR(50) NOT NULL,
    payment_reference VARCHAR(100),
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'completed', 'failed')),
    description TEXT,
    transaction_date TIMESTAMP NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_group_id ON transactions(group_id);
CREATE INDEX IF NOT EXISTS idx_transactions_transaction_date ON transactions(transaction_date);
```

### Notifications Table

Stores notifications for users.

```sql
CREATE TABLE IF NOT EXISTS notifications (
    notification_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(user_id),
    group_id INT REFERENCES groups(group_id),
    title VARCHAR(100) NOT NULL,
    message TEXT NOT NULL,
    notification_type VARCHAR(50) NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
```

### Announcements Table

Stores group announcements.

```sql
CREATE TABLE IF NOT EXISTS announcements (
    announcement_id SERIAL PRIMARY KEY,
    group_id INT NOT NULL REFERENCES groups(group_id),
    created_by INT NOT NULL REFERENCES users(user_id),
    title VARCHAR(100) NOT NULL,
    body TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_announcements_group_id ON announcements(group_id);
```

### Blockchain Records Table

Stores records of blockchain transactions.

```sql
CREATE TABLE IF NOT EXISTS blockchain_records (
    record_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id),
    group_id INT REFERENCES groups(group_id),
    saving_id INT REFERENCES savings(saving_id),
    transaction_id INT REFERENCES transactions(transaction_id),
    record_type VARCHAR(50) NOT NULL,
    blockchain_hash VARCHAR(255) NOT NULL,
    blockchain_timestamp TIMESTAMP NOT NULL,
    data JSONB NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_blockchain_records_user_id ON blockchain_records(user_id);
CREATE INDEX IF NOT EXISTS idx_blockchain_records_group_id ON blockchain_records(group_id);
CREATE INDEX IF NOT EXISTS idx_blockchain_records_blockchain_hash ON blockchain_records(blockchain_hash);
```

### Savings Goals Table

Tracks savings goals for users and groups.

```sql
CREATE TABLE IF NOT EXISTS savings_goals (
    goal_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(user_id),
    group_id INT REFERENCES groups(group_id),
    name VARCHAR(100) NOT NULL,
    target_amount DECIMAL(12, 2) NOT NULL,
    current_amount DECIMAL(12, 2) DEFAULT 0,
    start_date DATE NOT NULL,
    target_date DATE NOT NULL,
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_savings_goals_user_id ON savings_goals(user_id);
CREATE INDEX IF NOT EXISTS idx_savings_goals_group_id ON savings_goals(group_id);
```

### Audit Logs Table

Records system activities for auditing purposes.

```sql
CREATE TABLE IF NOT EXISTS audit_logs (
    log_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id),
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id INT NOT NULL,
    old_value JSONB,
    new_value JSONB,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);
```

## Triggers

Triggers for automatically updating timestamps.

```sql
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_timestamp
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_groups_timestamp
BEFORE UPDATE ON groups
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_savings_timestamp
BEFORE UPDATE ON savings
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_transactions_timestamp
BEFORE UPDATE ON transactions
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_announcements_timestamp
BEFORE UPDATE ON announcements
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_savings_goals_timestamp
BEFORE UPDATE ON savings_goals
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();
```

## Common Queries

### User Registration

```sql
INSERT INTO users (
    first_name, last_name, other_names, email, phone, role, password_hash, created_at
) VALUES (
    'John', 'Doe', 'Smith', 'john.doe@example.com', '+233123456789', 'member', 'hashed_password_here', NOW()
);
```

### User Authentication

```sql
SELECT * FROM users WHERE email = 'john.doe@example.com' AND is_active = TRUE;
```

### Create a Group

```sql
INSERT INTO groups (
    name, description, created_by, contribution_amount, contribution_frequency, start_date, created_at
) VALUES (
    'Family Savings', 'Monthly savings for our family', 1, 500.00, 'monthly', '2025-08-01', NOW()
);
```

### Add a User to a Group

```sql
INSERT INTO group_members (
    group_id, user_id, role, joined_at
) VALUES (
    1, 2, 'member', NOW()
);
```

### Record a Savings Contribution

```sql
INSERT INTO savings (
    user_id, group_id, amount, payment_method, status, contribution_date, created_at
) VALUES (
    1, 1, 500.00, 'mobile_money', 'pending', '2025-08-01', NOW()
);
```

### Record a Transaction

```sql
INSERT INTO transactions (
    user_id, group_id, saving_id, transaction_type, amount, payment_method, status, description, transaction_date
) VALUES (
    1, 1, 1, 'deposit', 500.00, 'mobile_money', 'completed', 'Monthly contribution', NOW()
);
```

### Get User's Savings History

```sql
SELECT s.*, g.name as group_name
FROM savings s
JOIN groups g ON s.group_id = g.group_id
WHERE s.user_id = 1
ORDER BY s.contribution_date DESC;
```

### Get Group's Total Savings

```sql
SELECT g.name, SUM(s.amount) as total_savings
FROM savings s
JOIN groups g ON s.group_id = g.group_id
WHERE s.group_id = 1 AND s.status = 'verified'
GROUP BY g.name;
```

## Database Maintenance

### Backup Database

```bash
pg_dump -h pg-20190fe4-savessa.h.aivencloud.com -p 24322 -U avnadmin -d defaultdb -f savessa_backup.sql
```

### Restore Database

```bash
psql -h pg-20190fe4-savessa.h.aivencloud.com -p 24322 -U avnadmin -d defaultdb -f savessa_backup.sql
```

## Conclusion

This database schema provides a solid foundation for the Savessa app, supporting all the required features including user management, group savings, transactions, notifications, and blockchain integration. The schema is designed to be scalable and maintainable, with appropriate indexes and constraints to ensure data integrity and performance.