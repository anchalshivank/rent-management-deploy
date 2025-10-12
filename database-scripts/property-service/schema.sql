-- ============================================
-- PROPERTIES TABLE
-- ============================================
CREATE TABLE properties (
    id UUID PRIMARY key,
    owner_id UUID NOT NULL,  -- References users(id) in user-service
    
    -- Property Details
    property_name VARCHAR(255) NOT NULL,
    property_type VARCHAR(50) NOT NULL,  -- APARTMENT, PG, HOSTEL, VILLA, INDEPENDENT_HOUSE
    
    -- Address
    address_line1 VARCHAR(500) NOT NULL,
    address_line2 VARCHAR(500),
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL DEFAULT 'India',
    postal_code VARCHAR(20) NOT NULL,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    
    -- Property Metadata
    total_rooms INTEGER NOT NULL DEFAULT 0,
    total_floors INTEGER DEFAULT 1,
    built_year INTEGER,
    carpet_area DECIMAL(10,2),  -- in sq ft
    
    -- Registration
    property_registration_number VARCHAR(100),
    property_tax_number VARCHAR(100),
    
    -- Status
    status VARCHAR(20) DEFAULT 'ACTIVE',  -- ACTIVE, INACTIVE, UNDER_MAINTENANCE
    verification_status VARCHAR(20) DEFAULT 'PENDING',  -- PENDING, VERIFIED, REJECTED
    verified_at TIMESTAMP WITH TIME ZONE,
    verified_by UUID,  -- Admin user who verified
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()

        
    -- AUDIT & CORRELATION
    correlation_id UUID,
    request_id VARCHAR(100),
    trace_id VARCHAR(100),
    span_id VARCHAR(100),
);

CREATE INDEX idx_properties_owner_id ON properties(owner_id);
CREATE INDEX idx_properties_status ON properties(status);
CREATE INDEX idx_properties_verification ON properties(verification_status);
CREATE INDEX idx_properties_city ON properties(city);

-- ============================================
-- ROOMS TABLE
-- ============================================
CREATE TABLE rooms (
    id UUID PRIMARY KEY,
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    
    -- Room Details
    room_number VARCHAR(50) NOT NULL,
    room_name VARCHAR(100),
    floor_number INTEGER,
    room_type VARCHAR(50),  -- SINGLE, DOUBLE, SHARED, STUDIO
    
    -- Room Specifications
    carpet_area DECIMAL(10,2),  -- in sq ft
    has_attached_bathroom BOOLEAN DEFAULT false,
    has_ac BOOLEAN DEFAULT false,
    has_balcony BOOLEAN DEFAULT false,
    furnishing_type VARCHAR(50),  -- FURNISHED, SEMI_FURNISHED, UNFURNISHED
    
    -- Occupancy
    max_occupancy INTEGER DEFAULT 1,
    current_occupancy INTEGER DEFAULT 0,
    
    -- Rental Info
    monthly_rent DECIMAL(10,2),
    security_deposit DECIMAL(10,2),


    
    -- Status
    status VARCHAR(20) DEFAULT 'VACANT',  -- VACANT, OCCUPIED, UNDER_MAINTENANCE, RESERVED
    
    -- Meter Assignment (will be linked from meter-service)
    meter_id VARCHAR(100),  -- Meter ID from meter-service
    meter_assigned_at TIMESTAMP WITH TIME ZONE,

            -- AUDIT & CORRELATION
    correlation_id UUID,
    request_id VARCHAR(100),
    trace_id VARCHAR(100),
    span_id VARCHAR(100),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    
    
    UNIQUE(property_id, room_number)
);

CREATE INDEX idx_rooms_property_id ON rooms(property_id);
CREATE INDEX idx_rooms_status ON rooms(status);
CREATE INDEX idx_rooms_meter_id ON rooms(meter_id);

-- ============================================
-- TENANCY AGREEMENTS (Room assignments to tenants)
-- ============================================
CREATE TABLE tenancy_agreements (
    id UUID PRIMARY KEY,
    
    -- Linkages
    room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL,  -- References users(id) in user-service
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    
    -- Agreement Details
    agreement_number VARCHAR(100) UNIQUE,
    start_date DATE NOT NULL,
    end_date DATE,
    
    -- Financial Terms
    monthly_rent DECIMAL(10,2) NOT NULL,
    security_deposit DECIMAL(10,2) NOT NULL,
    deposit_paid BOOLEAN DEFAULT false,
    deposit_paid_date DATE,
    
    -- Utilities
    electricity_included BOOLEAN DEFAULT false,
    water_included BOOLEAN DEFAULT false,
    
    -- Agreement Status
    status VARCHAR(20) DEFAULT 'ACTIVE',  -- ACTIVE, EXPIRED, TERMINATED, PENDING
    
    -- Termination
    termination_date DATE,
    termination_reason TEXT,
    termination_notice_period INTEGER,  -- in days
    
    -- Documents
    agreement_document_url VARCHAR(500),

            -- AUDIT & CORRELATION
    correlation_id UUID,
    request_id VARCHAR(100),
    trace_id VARCHAR(100),
    span_id VARCHAR(100),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_tenancy_room_id ON tenancy_agreements(room_id);
CREATE INDEX idx_tenancy_tenant_id ON tenancy_agreements(tenant_id);
CREATE INDEX idx_tenancy_property_id ON tenancy_agreements(property_id);
CREATE INDEX idx_tenancy_status ON tenancy_agreements(status);
CREATE INDEX idx_tenancy_dates ON tenancy_agreements(start_date, end_date);

-- ============================================
-- PROPERTY VERIFICATION REQUESTS
-- ============================================
CREATE TABLE property_verification_requests (
    id UUID PRIMARY KEY,
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    
    -- Documents submitted
    ownership_proof_url VARCHAR(500),
    property_tax_receipt_url VARCHAR(500),
    property_photos JSONB,  -- Array of photo URLs
    
    -- Verification
    status VARCHAR(20) DEFAULT 'PENDING',  -- PENDING, APPROVED, REJECTED
    reviewed_by UUID,  -- Admin user
    reviewed_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,

    -- AUDIT & CORRELATION
    correlation_id UUID,
    request_id VARCHAR(100),
    trace_id VARCHAR(100),
    span_id VARCHAR(100),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_verification_property_id ON property_verification_requests(property_id);
CREATE INDEX idx_verification_status ON property_verification_requests(status);