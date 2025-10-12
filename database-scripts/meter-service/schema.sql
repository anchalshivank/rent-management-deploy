-- ============================================
-- METER READINGS TABLE (Time-Series Data)
-- ============================================
CREATE TABLE meter_readings (
    id BIGSERIAL PRIMARY KEY,
    meter_id VARCHAR(100) NOT NULL,  -- Meter ID (cross-service reference)
    reading_timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Energy Consumption
    total_active_energy DECIMAL(15,4),  -- kWh
    total_reactive_energy DECIMAL(15,4),  -- kvarh
    
    -- Tariff-based Energy (T1, T2, T3, T4)
    t1_active_energy DECIMAL(15,4),
    t2_active_energy DECIMAL(15,4),
    t3_active_energy DECIMAL(15,4),
    t4_active_energy DECIMAL(15,4),
    
    t1_reactive_energy DECIMAL(15,4),
    t2_reactive_energy DECIMAL(15,4),
    t3_reactive_energy DECIMAL(15,4),
    t4_reactive_energy DECIMAL(15,4),
    
    -- Forward/Reverse Energy
    forward_active_energy DECIMAL(15,4),
    reverse_active_energy DECIMAL(15,4),
    forward_reactive_energy DECIMAL(15,4),
    reverse_reactive_energy DECIMAL(15,4),
    
    -- Single Phase Values (always populated)
    voltage DECIMAL(10,2),  -- V
    current DECIMAL(10,3),  -- A
    active_power DECIMAL(12,4),  -- kW
    reactive_power DECIMAL(12,4),  -- kvar
    apparent_power DECIMAL(12,4),  -- kVA
    power_factor DECIMAL(5,3),
    
    -- Three Phase Values (NULL for single-phase meters)
    phase_a_voltage DECIMAL(10,2),
    phase_b_voltage DECIMAL(10,2),
    phase_c_voltage DECIMAL(10,2),
    
    phase_a_current DECIMAL(10,3),
    phase_b_current DECIMAL(10,3),
    phase_c_current DECIMAL(10,3),
    
    phase_a_active_power DECIMAL(12,4),
    phase_b_active_power DECIMAL(12,4),
    phase_c_active_power DECIMAL(12,4),
    
    phase_a_reactive_power DECIMAL(12,4),
    phase_b_reactive_power DECIMAL(12,4),
    phase_c_reactive_power DECIMAL(12,4),
    
    phase_a_apparent_power DECIMAL(12,4),
    phase_b_apparent_power DECIMAL(12,4),
    phase_c_apparent_power DECIMAL(12,4),
    
    phase_a_power_factor DECIMAL(5,3),
    phase_b_power_factor DECIMAL(5,3),
    phase_c_power_factor DECIMAL(5,3),
    
    -- Common fields
    grid_frequency DECIMAL(6,2),  -- Hz
    max_active_demand DECIMAL(12,4),
    max_reactive_demand DECIMAL(12,4),
    
    -- Status
    relay_status VARCHAR(20),
    temperature DECIMAL(5,2),
    alert_status VARCHAR(50),
    
    -- Raw data for debugging
    raw_data TEXT,

        -- AUDIT & CORRELATION
    correlation_id UUID,
    request_id VARCHAR(100),
    trace_id VARCHAR(100),
    span_id VARCHAR(100),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for time-series queries
CREATE INDEX idx_meter_readings_meter_id ON meter_readings(meter_id);
CREATE INDEX idx_meter_readings_timestamp ON meter_readings(reading_timestamp DESC);
CREATE INDEX idx_meter_readings_meter_timestamp ON meter_readings(meter_id, reading_timestamp DESC);

-- ============================================
-- RELAY COMMANDS TABLE
-- ============================================
CREATE TABLE relay_commands (
    id UUID PRIMARY KEY,
    meter_id VARCHAR(100) NOT NULL,
    
    -- Command
    command VARCHAR(20) NOT NULL,  -- ON, OFF
    command_status VARCHAR(20) DEFAULT 'PENDING',  -- PENDING, SENT, SUCCESS, FAILED, TIMEOUT
    
    -- User who issued command
    requested_by UUID NOT NULL,
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Execution timeline
    sent_at TIMESTAMP WITH TIME ZONE,
    acknowledged_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Response from device
    response_code VARCHAR(50),
    response_message TEXT,
    error_message TEXT,
    
    -- Retry mechanism
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    next_retry_at TIMESTAMP WITH TIME ZONE,
    
    -- Context
    reason VARCHAR(500),
    notes TEXT,

        -- AUDIT & CORRELATION
    correlation_id UUID,
    request_id VARCHAR(100),
    trace_id VARCHAR(100),
    span_id VARCHAR(100),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_relay_commands_meter_id ON relay_commands(meter_id);
CREATE INDEX idx_relay_commands_status ON relay_commands(command_status);
CREATE INDEX idx_relay_commands_requested_at ON relay_commands(requested_at DESC);
CREATE INDEX idx_relay_commands_requested_by ON relay_commands(requested_by);

-- ============================================
-- DEVICE HEARTBEATS TABLE
-- ============================================
CREATE TABLE device_heartbeats (
    id BIGSERIAL PRIMARY KEY,
    device_id VARCHAR(100) NOT NULL,
    heartbeat_timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Device health
    uptime_seconds BIGINT,
    free_memory_kb INTEGER,
    wifi_signal_strength INTEGER,  -- RSSI
    connected_meters_count INTEGER,
    
    -- Network
    ip_address INET,
    mac_address VARCHAR(20),
    
    -- Firmware
    firmware_version VARCHAR(50),

        -- AUDIT & CORRELATION
    correlation_id UUID,
    request_id VARCHAR(100),
    trace_id VARCHAR(100),
    span_id VARCHAR(100),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_heartbeat_device_id ON device_heartbeats(device_id);
CREATE INDEX idx_heartbeat_timestamp ON device_heartbeats(heartbeat_timestamp DESC);

-- ============================================
-- METER EVENTS TABLE (Alerts & Anomalies)
-- ============================================
CREATE TABLE meter_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    meter_id VARCHAR(100) NOT NULL,
    
    event_type VARCHAR(50) NOT NULL,  -- OVERLOAD, OVERCURRENT, OFFLINE, TAMPER, LOW_POWER_FACTOR
    severity VARCHAR(20) DEFAULT 'INFO',  -- INFO, WARNING, ERROR, CRITICAL
    
    event_timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    event_value DECIMAL(15,4),
    threshold_value DECIMAL(15,4),
    
    description TEXT,
    
    -- Resolution
    resolved BOOLEAN DEFAULT false,
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by UUID,
    resolution_notes TEXT,
    
    -- Notification status
    notification_sent BOOLEAN DEFAULT false,
    notification_sent_at TIMESTAMP WITH TIME ZONE,
    
        -- AUDIT & CORRELATION
    correlation_id UUID,
    request_id VARCHAR(100),
    trace_id VARCHAR(100),
    span_id VARCHAR(100),

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_meter_events_meter_id ON meter_events(meter_id);
CREATE INDEX idx_meter_events_type ON meter_events(event_type);
CREATE INDEX idx_meter_events_severity ON meter_events(severity);
CREATE INDEX idx_meter_events_timestamp ON meter_events(event_timestamp DESC);
CREATE INDEX idx_meter_events_resolved ON meter_events(resolved);

-- ============================================
-- FROZEN DATA TABLE (Daily/Monthly snapshots)
-- ============================================
CREATE TABLE meter_frozen_data (
    id UUID PRIMARY KEY,
    meter_id VARCHAR(100) NOT NULL,
    freeze_type VARCHAR(20) NOT NULL,  -- DAILY, MONTHLY
    freeze_date DATE NOT NULL,
    
    -- Frozen values
    total_active_energy DECIMAL(15,4),
    total_reactive_energy DECIMAL(15,4),
    
    t1_active_energy DECIMAL(15,4),
    t2_active_energy DECIMAL(15,4),
    t3_active_energy DECIMAL(15,4),
    t4_active_energy DECIMAL(15,4),
    
    -- Consumption (difference from previous)
    daily_consumption DECIMAL(15,4),
    monthly_consumption DECIMAL(15,4),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

        -- AUDIT & CORRELATION
    correlation_id UUID,
    request_id VARCHAR(100),
    trace_id VARCHAR(100),
    span_id VARCHAR(100),
    
    UNIQUE(meter_id, freeze_type, freeze_date)
);

CREATE INDEX idx_frozen_meter_id ON meter_frozen_data(meter_id);
CREATE INDEX idx_frozen_date ON meter_frozen_data(freeze_date DESC);
CREATE INDEX idx_frozen_type ON meter_frozen_data(freeze_type);