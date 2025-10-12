-- ============================================
-- IOT DEVICES TABLE (ESP32 Controllers)
-- ============================================
CREATE TABLE iot_devices (
    id UUID primary KEY,
    device_id VARCHAR(100) UNIQUE NOT NULL,  -- e.g., "ESP32_DEVICE_001"
    device_name VARCHAR(255),
    
    -- Ownership (optional - can be assigned to property)
    assigned_to_property_id UUID,  -- References properties(id) in property-service
    
    -- Device Info
    mac_address VARCHAR(20),
    firmware_version VARCHAR(50),
    hardware_version VARCHAR(50),
    
    -- Network
    ip_address INET,
    last_ip_address INET,
    
    -- Location
    installation_location VARCHAR(500),
    
    -- Status
    status VARCHAR(20) DEFAULT 'ACTIVE',  -- ACTIVE, INACTIVE, ERROR, MAINTENANCE
    last_heartbeat TIMESTAMP WITH TIME ZONE,
    
    -- Metadata
    notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,

    -- AUDIT & CORRELATION
    correlation_id UUID,
    request_id VARCHAR(100),
    trace_id VARCHAR(100),
    span_id VARCHAR(100),
);

CREATE INDEX idx_iot_devices_device_id ON iot_devices(device_id);
CREATE INDEX idx_iot_devices_property_id ON iot_devices(assigned_to_property_id);
CREATE INDEX idx_iot_devices_status ON iot_devices(status);
CREATE INDEX idx_iot_devices_last_heartbeat ON iot_devices(last_heartbeat);

-- ============================================
-- METERS TABLE (Physical Smart Meters)
-- ============================================
CREATE TABLE meters (
    id UUID PRIMARY KEY,
    meter_id VARCHAR(100) UNIQUE NOT NULL,  -- e.g., "ESP32_DEVICE_001-1"
    
    -- Device linkage
    device_id UUID NOT NULL REFERENCES iot_devices(id) ON DELETE CASCADE,
    meter_number INTEGER NOT NULL,  -- Position on ESP32 (1, 2, 3, etc.)
    
    -- Meter Hardware Info
    meter_model VARCHAR(100) DEFAULT 'EM113016-04',
    manufacturer VARCHAR(100) DEFAULT 'Ivy Metering',
    serial_number VARCHAR(100) UNIQUE,
    hardware_version VARCHAR(50),
    software_version VARCHAR(50),
    manufacture_date DATE,
    installation_date DATE,
    
    -- Communication Protocol
    protocol VARCHAR(20) DEFAULT 'DLT645_2007',  -- DLT645_1997, DLT645_2007, MODBUS
    meter_address VARCHAR(50),  -- DLT645 meter address (12 digits)
    meter_password VARCHAR(50),  -- DLT645 meter password (8 digits)
    modbus_address INTEGER,
    baud_rate INTEGER DEFAULT 9600,
    
    -- Meter Type
    phase_type VARCHAR(20) DEFAULT 'SINGLE',  -- SINGLE, THREE_PHASE
    meter_type VARCHAR(50) DEFAULT 'ENERGY',  -- ENERGY, WATER, GAS
    
    -- Configuration
    ct_ratio DECIMAL(10,2) DEFAULT 1.0,
    voltage_rating DECIMAL(10,2) DEFAULT 230.0,  -- Volts
    current_rating DECIMAL(10,2) DEFAULT 60.0,   -- Amperes
    
    -- Thresholds
    overload_threshold DECIMAL(10,2),  -- kW
    current_threshold DECIMAL(10,2),   -- Amperes
    overcurrent_threshold DECIMAL(10,2),
    
    -- Relay Configuration
    has_relay BOOLEAN DEFAULT true,
    relay_status VARCHAR(20) DEFAULT 'UNKNOWN',  -- ON, OFF, UNKNOWN, ERROR
    relay_control_logic VARCHAR(50),
    relay_auto_control_enabled BOOLEAN DEFAULT false,
    
    -- Assignment Status
    assignment_status VARCHAR(20) DEFAULT 'UNASSIGNED',  -- UNASSIGNED, ASSIGNED, IN_SERVICE, FAULTY, RETIRED
    assigned_to_property_id UUID,  -- Property it's installed in
    assigned_to_room_id UUID,      -- Specific room
    assigned_at TIMESTAMP WITH TIME ZONE,
    
    -- Service Status
    status VARCHAR(20) DEFAULT 'ACTIVE',  -- ACTIVE, INACTIVE, MAINTENANCE, FAULTY, RETIRED
    last_reading_at TIMESTAMP WITH TIME ZONE,
    last_maintenance_date DATE,
    next_maintenance_date DATE,
    
    -- Replacement tracking
    replaced_by_meter_id UUID,  -- If meter was replaced, ID of new meter
    replacement_reason TEXT,
    replacement_date DATE,
    
    -- Metadata
    notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
        -- AUDIT & CORRELATION
    correlation_id UUID,
    request_id VARCHAR(100),
    trace_id VARCHAR(100),
    span_id VARCHAR(100),

    UNIQUE(device_id, meter_number)
);

CREATE INDEX idx_meters_meter_id ON meters(meter_id);
CREATE INDEX idx_meters_device_id ON meters(device_id);
CREATE INDEX idx_meters_serial_number ON meters(serial_number);
CREATE INDEX idx_meters_assignment_status ON meters(assignment_status);
CREATE INDEX idx_meters_status ON meters(status);
CREATE INDEX idx_meters_property_id ON meters(assigned_to_property_id);
CREATE INDEX idx_meters_room_id ON meters(assigned_to_room_id);
CREATE INDEX idx_meters_relay_status ON meters(relay_status);

-- ============================================
-- METER ASSIGNMENT HISTORY
-- ============================================
CREATE TABLE meter_assignment_history (
    id UUID PRIMARY KEY,
    meter_id UUID NOT NULL REFERENCES meters(id) ON DELETE CASCADE,
    
    -- Assignment details
    property_id UUID,
    room_id UUID,
    tenant_id UUID,
    
    -- Timeline
    assigned_at TIMESTAMP WITH TIME ZONE NOT NULL,
    unassigned_at TIMESTAMP WITH TIME ZONE,
    
    -- Reason
    assignment_type VARCHAR(50),  -- NEW_INSTALLATION, REPLACEMENT, RELOCATION
    unassignment_reason VARCHAR(50),  -- TENANT_MOVED, METER_FAULT, UPGRADE
    
    -- Readings at assignment/unassignment
    opening_reading DECIMAL(15,4),
    closing_reading DECIMAL(15,4),
    
    notes TEXT,

        -- AUDIT & CORRELATION
    correlation_id UUID,
    request_id VARCHAR(100),
    trace_id VARCHAR(100),
    span_id VARCHAR(100),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID
);

CREATE INDEX idx_assignment_history_meter_id ON meter_assignment_history(meter_id);
CREATE INDEX idx_assignment_history_property_id ON meter_assignment_history(property_id);
CREATE INDEX idx_assignment_history_room_id ON meter_assignment_history(room_id);
CREATE INDEX idx_assignment_history_dates ON meter_assignment_history(assigned_at, unassigned_at);

-- ============================================
-- METER MAINTENANCE LOG
-- ============================================
CREATE TABLE meter_maintenance_log (
    id UUID PRIMARY KEY,
    meter_id UUID NOT NULL REFERENCES meters(id) ON DELETE CASCADE,
    
    -- Maintenance details
    maintenance_type VARCHAR(50) NOT NULL,  -- ROUTINE, REPAIR, REPLACEMENT, CALIBRATION
    maintenance_date DATE NOT NULL,
    
    -- Issue & Resolution
    issue_description TEXT,
    resolution_description TEXT,
    
    -- Technician
    technician_name VARCHAR(200),
    technician_contact VARCHAR(20),
    
    -- Cost
    cost DECIMAL(10,2),
    
    -- Parts replaced
    parts_replaced JSONB,
    
    -- Status after maintenance
    meter_status_after VARCHAR(20),  -- OPERATIONAL, NON_OPERATIONAL, NEEDS_REPLACEMENT
    
    -- Documents
    maintenance_report_url VARCHAR(500),
    
        -- AUDIT & CORRELATION
    correlation_id UUID,
    request_id VARCHAR(100),
    trace_id VARCHAR(100),
    span_id VARCHAR(100),

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID
);

CREATE INDEX idx_maintenance_meter_id ON meter_maintenance_log(meter_id);
CREATE INDEX idx_maintenance_date ON meter_maintenance_log(maintenance_date DESC);
CREATE INDEX idx_maintenance_type ON meter_maintenance_log(maintenance_type);

-- ============================================
-- METER CONFIGURATION
-- ============================================
CREATE TABLE meter_configuration (
    id UUID PRIMARY KEY,
    meter_id UUID NOT NULL REFERENCES meters(id) ON DELETE CASCADE,
    
    -- Time Zone & Holiday Configuration
    time_zones JSONB,
    holidays JSONB,
    time_periods JSONB,
    
    -- Display Configuration
    display_mode VARCHAR(50),
    rotation_time INTEGER,
    pulse_output_type VARCHAR(50),
    
    -- Tariff Configuration
    rate_selection INTEGER DEFAULT 1,
    tariff_rates JSONB,  -- Store rate structure
    
    -- Other configs
    season_switch BOOLEAN DEFAULT false,
    measurement_mode VARCHAR(50),
    so_ratio_output DECIMAL(10,4),
    
    -- Sync status
    config_version INTEGER DEFAULT 1,
    last_synced_at TIMESTAMP WITH TIME ZONE,
    sync_status VARCHAR(20) DEFAULT 'PENDING',  -- PENDING, SYNCED, FAILED
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
        -- AUDIT & CORRELATION
    correlation_id UUID,
    request_id VARCHAR(100),
    trace_id VARCHAR(100),
    span_id VARCHAR(100),
    UNIQUE(meter_id)
);

CREATE INDEX idx_meter_config_meter_id ON meter_configuration(meter_id);
CREATE INDEX idx_meter_config_sync_status ON meter_configuration(sync_status);