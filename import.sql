ALTER TABLE users ADD COLUMN jail_time INT DEFAULT 0;
ALTER TABLE users ADD COLUMN jail_base INT DEFAULT 0;
ALTER TABLE users ADD COLUMN jail_reason VARCHAR(255) DEFAULT '';