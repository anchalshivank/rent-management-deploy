-- ============================================
-- AUTH SERVICE DATABASE SCHEMA
-- Database: rent_auth_db
-- ============================================

-- Note: Keycloak manages its own tables
-- We only store minimal user mapping

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY,
    keycloak_user_id VARCHAR(255) UNIQUE NOT NULL,
    
    phone_number VARCHAR(20) UNIQUE,
    user_type VARCHAR(20) NOT NULL CHECK (user_type IN ('tenant', 'owner', 'admin')),
    score INT NOT NULL DEFAULT 500,
    email VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    
    is_active BOOLEAN DEFAULT true,
    email_verified BOOLEAN DEFAULT false,
    
    -- AUDIT & CORRELATION
    correlation_id UUID,
    request_id VARCHAR(100),
    trace_id VARCHAR(100),
    span_id VARCHAR(100),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    created_by_service VARCHAR(50) DEFAULT 'auth-service',
    updated_by_service VARCHAR(50),
    
    deleted BOOLEAN DEFAULT false,
    deleted_at TIMESTAMP WITH TIME ZONE,
    deleted_by UUID,
    deletion_reason TEXT,
    
    version INTEGER DEFAULT 1
);

CREATE INDEX idx_users_keycloak_id ON users(keycloak_user_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone_number);
CREATE INDEX idx_users_type ON users(user_type);
CREATE INDEX idx_users_correlation_id ON users(correlation_id);
CREATE INDEX idx_users_deleted ON users(deleted);

CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();



CREATE TABLE user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Address
    address_line1 VARCHAR(500),
    address_line2 VARCHAR(500),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    postal_code VARCHAR(20),
    
    -- KYC Documents
    id_proof_type VARCHAR(50),  -- AADHAAR, PAN, PASSPORT, DRIVING_LICENSE
    id_proof_number VARCHAR(100),
    id_proof_verified BOOLEAN DEFAULT false,
    
    -- Bank Details (for owners)
    bank_account_number VARCHAR(50),
    bank_ifsc_code VARCHAR(20),
    bank_name VARCHAR(200),
    
    -- Emergency Contact
    emergency_contact_name VARCHAR(200),
    emergency_contact_phone VARCHAR(20),
    emergency_contact_relation VARCHAR(50),
    
    -- AUDIT & CORRELATION
    correlation_id UUID,
    request_id VARCHAR(100),
    trace_id VARCHAR(100),
    span_id VARCHAR(100),
        
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id)
);

CREATE INDEX idx_user_profiles_user_id ON user_profiles(user_id);