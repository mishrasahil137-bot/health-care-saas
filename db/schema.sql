CREATE TABLE IF NOT EXISTS tenants (
 id BIGSERIAL PRIMARY KEY, name VARCHAR(180) NOT NULL, slug VARCHAR(100) UNIQUE NOT NULL,
 type VARCHAR(20) NOT NULL CHECK (type IN ('clinic','medical','both')),
 status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active','suspended')),
 plan VARCHAR(40) NOT NULL DEFAULT 'starter', created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS users (
 id BIGSERIAL PRIMARY KEY, tenant_id BIGINT REFERENCES tenants(id) ON DELETE CASCADE,
 name VARCHAR(160) NOT NULL, email VARCHAR(180) UNIQUE NOT NULL, password_hash TEXT NOT NULL,
 role VARCHAR(30) NOT NULL CHECK (role IN ('super_admin','admin','doctor','pharmacist','receptionist','accountant')),
 active BOOLEAN NOT NULL DEFAULT TRUE, must_change_password BOOLEAN NOT NULL DEFAULT TRUE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS patients (
 id BIGSERIAL PRIMARY KEY, tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
 patient_code VARCHAR(40), name VARCHAR(180) NOT NULL, phone VARCHAR(30), dob DATE, gender VARCHAR(20),
 blood_group VARCHAR(8), address TEXT, allergies TEXT, notes TEXT, created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS patients_tenant_idx ON patients(tenant_id);
CREATE TABLE IF NOT EXISTS doctors (
 id BIGSERIAL PRIMARY KEY, tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
 name VARCHAR(180) NOT NULL, specialty VARCHAR(120), phone VARCHAR(30), consultation_fee NUMERIC(12,2) DEFAULT 0, active BOOLEAN DEFAULT TRUE
);
CREATE TABLE IF NOT EXISTS appointments (
 id BIGSERIAL PRIMARY KEY, tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
 patient_id BIGINT REFERENCES patients(id) ON DELETE SET NULL, doctor_id BIGINT REFERENCES doctors(id) ON DELETE SET NULL,
 appointment_at TIMESTAMPTZ NOT NULL, status VARCHAR(24) NOT NULL DEFAULT 'scheduled', reason TEXT, created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS prescriptions (
 id BIGSERIAL PRIMARY KEY, tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
 patient_id BIGINT NOT NULL REFERENCES patients(id) ON DELETE CASCADE, doctor_id BIGINT REFERENCES doctors(id) ON DELETE SET NULL,
 diagnosis TEXT, items JSONB NOT NULL DEFAULT '[]', advice TEXT, created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS suppliers (
 id BIGSERIAL PRIMARY KEY, tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
 name VARCHAR(180) NOT NULL, phone VARCHAR(30), email VARCHAR(180), address TEXT
);
CREATE TABLE IF NOT EXISTS medicines (
 id BIGSERIAL PRIMARY KEY, tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
 name VARCHAR(180) NOT NULL, sku VARCHAR(80), barcode VARCHAR(100), batch_no VARCHAR(100),
 expiry_date DATE, purchase_price NUMERIC(12,2) NOT NULL DEFAULT 0, sale_price NUMERIC(12,2) NOT NULL DEFAULT 0,
 stock_qty NUMERIC(12,2) NOT NULL DEFAULT 0, reorder_level NUMERIC(12,2) NOT NULL DEFAULT 10,
 supplier_id BIGINT REFERENCES suppliers(id) ON DELETE SET NULL, created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS medicines_tenant_idx ON medicines(tenant_id);
CREATE TABLE IF NOT EXISTS invoices (
 id BIGSERIAL PRIMARY KEY, tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
 invoice_no VARCHAR(60) NOT NULL, kind VARCHAR(20) NOT NULL CHECK (kind IN ('clinic','pharmacy')),
 patient_id BIGINT REFERENCES patients(id) ON DELETE SET NULL, subtotal NUMERIC(12,2) NOT NULL DEFAULT 0,
 tax NUMERIC(12,2) NOT NULL DEFAULT 0, discount NUMERIC(12,2) NOT NULL DEFAULT 0,
 total NUMERIC(12,2) NOT NULL DEFAULT 0, paid NUMERIC(12,2) NOT NULL DEFAULT 0,
 payment_method VARCHAR(30) DEFAULT 'cash', status VARCHAR(20) DEFAULT 'unpaid', items JSONB NOT NULL DEFAULT '[]',
 created_at TIMESTAMPTZ DEFAULT NOW(), UNIQUE(tenant_id, invoice_no)
);
CREATE TABLE IF NOT EXISTS expenses (
 id BIGSERIAL PRIMARY KEY, tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
 title VARCHAR(180) NOT NULL, category VARCHAR(100), amount NUMERIC(12,2) NOT NULL, expense_date DATE NOT NULL DEFAULT CURRENT_DATE, notes TEXT
);
CREATE TABLE IF NOT EXISTS audit_logs (
 id BIGSERIAL PRIMARY KEY, tenant_id BIGINT, user_id BIGINT, action VARCHAR(120) NOT NULL,
 entity VARCHAR(80), entity_id BIGINT, metadata JSONB DEFAULT '{}', created_at TIMESTAMPTZ DEFAULT NOW()
);

-- HEALTH CARE 2.0: laboratory and pharmacy operations
ALTER TABLE tenants DROP CONSTRAINT IF EXISTS tenants_type_check;
ALTER TABLE tenants ADD CONSTRAINT tenants_type_check CHECK (type IN ('clinic','medical','both','laboratory','full'));
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS created_by BIGINT REFERENCES users(id) ON DELETE SET NULL;
CREATE TABLE IF NOT EXISTS lab_tests (
 id BIGSERIAL PRIMARY KEY, tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
 test_code VARCHAR(60) NOT NULL, name VARCHAR(180) NOT NULL, department VARCHAR(120), sample_type VARCHAR(100),
 price NUMERIC(12,2) NOT NULL DEFAULT 0, turnaround_hours INTEGER NOT NULL DEFAULT 24, active BOOLEAN NOT NULL DEFAULT TRUE,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), UNIQUE(tenant_id,test_code)
);
CREATE INDEX IF NOT EXISTS lab_tests_tenant_idx ON lab_tests(tenant_id);
CREATE TABLE IF NOT EXISTS lab_orders (
 id BIGSERIAL PRIMARY KEY, tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
 patient_id BIGINT NOT NULL REFERENCES patients(id) ON DELETE RESTRICT, doctor_id BIGINT REFERENCES doctors(id) ON DELETE SET NULL,
 ordered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), status VARCHAR(24) NOT NULL DEFAULT 'collected' CHECK(status IN ('ordered','collected','processing','reported','cancelled')),
 priority VARCHAR(20) NOT NULL DEFAULT 'normal' CHECK(priority IN ('normal','urgent','stat')),
 test_ids JSONB NOT NULL DEFAULT '[]', clinical_notes TEXT, results JSONB NOT NULL DEFAULT '{}', reported_at TIMESTAMPTZ,
 created_by BIGINT REFERENCES users(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS lab_orders_tenant_idx ON lab_orders(tenant_id,ordered_at DESC);
CREATE TABLE IF NOT EXISTS pharmacy_purchases (
 id BIGSERIAL PRIMARY KEY, tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
 supplier_id BIGINT REFERENCES suppliers(id) ON DELETE SET NULL, invoice_no VARCHAR(80) NOT NULL,
 total NUMERIC(12,2) NOT NULL DEFAULT 0, items JSONB NOT NULL DEFAULT '[]', notes TEXT,
 created_by BIGINT REFERENCES users(id) ON DELETE SET NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
 UNIQUE(tenant_id,invoice_no)
);
CREATE INDEX IF NOT EXISTS purchases_tenant_idx ON pharmacy_purchases(tenant_id,created_at DESC);
CREATE TABLE IF NOT EXISTS invoice_payments (
 id BIGSERIAL PRIMARY KEY, tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
 invoice_id BIGINT NOT NULL REFERENCES invoices(id) ON DELETE CASCADE, amount NUMERIC(12,2) NOT NULL CHECK(amount>0),
 method VARCHAR(30) NOT NULL DEFAULT 'cash', received_by BIGINT REFERENCES users(id) ON DELETE SET NULL,
 created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
