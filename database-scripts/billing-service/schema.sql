-- ============================================
-- BILLING CYCLES TABLE
-- ============================================
CREATE TABLE billing_cycles (
    id UUID PRIMARY KEY,
    
    -- Linkages
    tenancy_agreement_id UUID NOT NULL,  -- From property-service
    meter_id VARCHAR(100) NOT NULL,
    tenant_id UUID NOT NULL,
    property_id UUID NOT NULL,
    room_id UUID NOT NULL,
    
    -- Billing period
    cycle_start_date DATE NOT NULL,
    cycle_end_date DATE NOT NULL,
    billing_month VARCHAR(7) NOT NULL,  -- YYYY-MM format
    
    -- Energy readings
    opening_reading DECIMAL(15,4),
    closing_reading DECIMAL(15,4),
    total_consumption DECIMAL(15,4),
    
    -- Tariff breakdown
    t1_consumption DECIMAL(15,4),
    t2_consumption DECIMAL(15,4),
    t3_consumption DECIMAL(15,4),
    t4_consumption DECIMAL(15,4),
    
    -- Cost calculation
    rate_per_kwh DECIMAL(10,4),
    energy_cost DECIMAL(12,2),
    fixed_charges DECIMAL(10,2),
    tax_amount DECIMAL(10,2),
    total_amount DECIMAL(12,2),
    
    -- Billing status
    bill_status VARCHAR(20) DEFAULT 'GENERATED',  -- GENERATED, SENT, PAID, OVERDUE, DISPUTED
    bill_generated_at TIMESTAMP WITH TIME ZONE,
    bill_sent_at TIMESTAMP WITH TIME ZONE,
    due_date DATE,
    
    -- Payment
    payment_status VARCHAR(20) DEFAULT 'PENDING',  -- PENDING, PAID, PARTIALLY_PAID, OVERDUE
    paid_amount DECIMAL(12,2) DEFAULT 0,
    payment_date DATE,
    payment_method VARCHAR(50),
    payment_reference VARCHAR(100),
    
    -- Documents
    bill_document_url VARCHAR(500),
    payment_receipt_url VARCHAR(500),
    
        
    -- AUDIT & CORRELATION
    correlation_id UUID,
    request_id VARCHAR(100),
    trace_id VARCHAR(100),
    span_id VARCHAR(100),

    notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(meter_id, billing_month)
);

CREATE INDEX idx_billing_tenancy_id ON billing_cycles(tenancy_agreement_id);
CREATE INDEX idx_billing_meter_id ON billing_cycles(meter_id);
CREATE INDEX idx_billing_tenant_id ON billing_cycles(tenant_id);
CREATE INDEX idx_billing_dates ON billing_cycles(cycle_start_date, cycle_end_date);
CREATE INDEX idx_billing_status ON billing_cycles(bill_status);
CREATE INDEX idx_billing_payment_status ON billing_cycles(payment_status);
CREATE INDEX idx_billing_month ON billing_cycles(billing_month);