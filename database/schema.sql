-- ================================
-- EcoClassify Database Schema
-- ================================
-- This file contains the SQL commands to set up the database schema
-- for the EcoClassify application in Supabase

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ================================
-- Users Table
-- ================================
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    avatar_url TEXT,
    bio TEXT,
    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    last_login_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);

-- ================================
-- Classifications Table
-- ================================
CREATE TABLE IF NOT EXISTS classifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    image_path VARCHAR(500) NOT NULL,
    original_filename VARCHAR(255),
    file_size INTEGER,
    image_width INTEGER,
    image_height INTEGER,
    predicted_class VARCHAR(50) NOT NULL,
    confidence DECIMAL(5,2) NOT NULL CHECK (confidence >= 0 AND confidence <= 100),
    class_probabilities JSONB,
    processing_time_ms INTEGER,
    model_version VARCHAR(50) DEFAULT 'mobilenetv2_v1.0',
    is_correct BOOLEAN, -- User feedback on prediction accuracy
    user_feedback TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_classifications_user_id ON classifications(user_id);
CREATE INDEX IF NOT EXISTS idx_classifications_predicted_class ON classifications(predicted_class);
CREATE INDEX IF NOT EXISTS idx_classifications_created_at ON classifications(created_at);
CREATE INDEX IF NOT EXISTS idx_classifications_confidence ON classifications(confidence);

-- ================================
-- User Statistics View
-- ================================
CREATE OR REPLACE VIEW user_statistics AS
SELECT 
    u.id as user_id,
    u.username,
    u.email,
    COUNT(c.id) as total_classifications,
    AVG(c.confidence) as average_confidence,
    MAX(c.created_at) as last_classification_at,
    COUNT(CASE WHEN c.created_at >= NOW() - INTERVAL '7 days' THEN 1 END) as classifications_last_7_days,
    COUNT(CASE WHEN c.created_at >= NOW() - INTERVAL '30 days' THEN 1 END) as classifications_last_30_days,
    JSON_OBJECT_AGG(
        c.predicted_class, 
        class_counts.count
    ) FILTER (WHERE c.predicted_class IS NOT NULL) as class_distribution
FROM users u
LEFT JOIN classifications c ON u.id = c.user_id
LEFT JOIN (
    SELECT 
        user_id, 
        predicted_class, 
        COUNT(*) as count
    FROM classifications 
    GROUP BY user_id, predicted_class
) class_counts ON u.id = class_counts.user_id
GROUP BY u.id, u.username, u.email;

-- ================================
-- Classification Categories Table
-- ================================
CREATE TABLE IF NOT EXISTS classification_categories (
    id SERIAL PRIMARY KEY,
    category_name VARCHAR(50) UNIQUE NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    description TEXT,
    color_hex VARCHAR(7) NOT NULL,
    icon_class VARCHAR(50),
    recycling_info JSONB,
    environmental_impact JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default categories
INSERT INTO classification_categories (category_name, display_name, description, color_hex, icon_class, recycling_info, environmental_impact) VALUES
('cardboard', 'Cardboard', 'Corrugated boxes, packaging materials, and cardboard containers', '#f39c12', 'fas fa-box', 
 '{"recyclable": true, "preparation": ["Remove tape and staples", "Break down boxes", "Keep dry"], "bin_type": "recycling"}',
 '{"co2_saved_per_kg": 0.7, "trees_saved_per_ton": 17, "energy_saved_percent": 24}'
),
('glass', 'Glass', 'Bottles, jars, and glass containers', '#27ae60', 'fas fa-wine-bottle',
 '{"recyclable": true, "preparation": ["Remove lids and caps", "Rinse containers", "Separate by color"], "bin_type": "recycling"}',
 '{"co2_saved_per_kg": 0.3, "energy_saved_percent": 30, "infinite_recycling": true}'
),
('metal', 'Metal', 'Aluminum cans, steel containers, and metal packaging', '#3498db', 'fas fa-cog',
 '{"recyclable": true, "preparation": ["Rinse containers", "Remove labels if possible", "Crush cans"], "bin_type": "recycling"}',
 '{"co2_saved_per_kg": 1.2, "energy_saved_percent": 95, "mining_reduction": true}'
),
('paper', 'Paper', 'Newspapers, magazines, office paper, and books', '#9b59b6', 'fas fa-file-alt',
 '{"recyclable": true, "preparation": ["Remove staples", "Keep dry", "Separate grades"], "bin_type": "recycling"}',
 '{"co2_saved_per_kg": 1.0, "trees_saved_per_ton": 17, "water_saved_percent": 50}'
),
('plastic', 'Plastic', 'Bottles, containers, and plastic packaging', '#e74c3c', 'fas fa-bottle-water',
 '{"recyclable": "depends", "preparation": ["Check recycling number", "Rinse thoroughly", "Remove caps"], "bin_type": "recycling"}',
 '{"co2_saved_per_kg": 0.5, "oil_saved_per_kg": 0.6, "ocean_protection": true}'
);

-- ================================
-- User Achievements Table
-- ================================
CREATE TABLE IF NOT EXISTS user_achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    achievement_type VARCHAR(50) NOT NULL,
    achievement_name VARCHAR(100) NOT NULL,
    description TEXT,
    icon_class VARCHAR(50),
    badge_color VARCHAR(7),
    points_awarded INTEGER DEFAULT 0,
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, achievement_type)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id ON user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_type ON user_achievements(achievement_type);

-- ================================
-- Application Settings Table
-- ================================
CREATE TABLE IF NOT EXISTS app_settings (
    id SERIAL PRIMARY KEY,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value JSONB NOT NULL,
    description TEXT,
    is_public BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default settings
INSERT INTO app_settings (setting_key, setting_value, description, is_public) VALUES
('model_info', '{"name": "MobileNetV2", "version": "1.0", "accuracy": 93.67, "training_date": "2024-01-15"}', 'Current model information', true),
('classification_limits', '{"daily_limit": 50, "monthly_limit": 1000, "file_size_mb": 16}', 'Classification limits per user', false),
('maintenance_mode', '{"enabled": false, "message": ""}', 'Maintenance mode settings', false);

-- ================================
-- Analytics and Reporting Views
-- ================================

-- Daily Classification Stats
CREATE OR REPLACE VIEW daily_classification_stats AS
SELECT 
    DATE(created_at) as classification_date,
    COUNT(*) as total_classifications,
    COUNT(DISTINCT user_id) as unique_users,
    AVG(confidence) as average_confidence,
    predicted_class,
    COUNT(*) as class_count
FROM classifications
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at), predicted_class
ORDER BY classification_date DESC, class_count DESC;

-- Monthly User Growth
CREATE OR REPLACE VIEW monthly_user_growth AS
SELECT 
    DATE_TRUNC('month', created_at) as month,
    COUNT(*) as new_users,
    SUM(COUNT(*)) OVER (ORDER BY DATE_TRUNC('month', created_at)) as cumulative_users
FROM users
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY month;

-- Top Performing Users
CREATE OR REPLACE VIEW top_users_by_activity AS
SELECT 
    u.id,
    u.username,
    u.email,
    COUNT(c.id) as total_classifications,
    AVG(c.confidence) as average_confidence,
    MAX(c.created_at) as last_activity,
    COUNT(CASE WHEN c.created_at >= NOW() - INTERVAL '7 days' THEN 1 END) as recent_activity
FROM users u
LEFT JOIN classifications c ON u.id = c.user_id
GROUP BY u.id, u.username, u.email
HAVING COUNT(c.id) > 0
ORDER BY total_classifications DESC, average_confidence DESC
LIMIT 50;

-- ================================
-- Functions for Business Logic
-- ================================

-- Function to update user statistics
CREATE OR REPLACE FUNCTION update_user_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- This function can be called after classification inserts
    -- to update user-related statistics or trigger achievements
    
    -- Check for achievements based on classification count
    INSERT INTO user_achievements (user_id, achievement_type, achievement_name, description, icon_class, badge_color, points_awarded)
    SELECT 
        NEW.user_id,
        'classification_milestone',
        CASE 
            WHEN user_classification_count = 1 THEN 'First Classification'
            WHEN user_classification_count = 10 THEN 'Getting Started'
            WHEN user_classification_count = 50 THEN 'Eco Warrior'
            WHEN user_classification_count = 100 THEN 'Classification Master'
            WHEN user_classification_count = 500 THEN 'Sustainability Champion'
        END,
        CASE 
            WHEN user_classification_count = 1 THEN 'Completed your first waste classification!'
            WHEN user_classification_count = 10 THEN 'Classified 10 items - you''re getting the hang of it!'
            WHEN user_classification_count = 50 THEN 'Classified 50 items - you''re an eco warrior!'
            WHEN user_classification_count = 100 THEN 'Classified 100 items - you''re a master!'
            WHEN user_classification_count = 500 THEN 'Classified 500 items - you''re a sustainability champion!'
        END,
        'fas fa-trophy',
        '#f39c12',
        CASE 
            WHEN user_classification_count = 1 THEN 10
            WHEN user_classification_count = 10 THEN 50
            WHEN user_classification_count = 50 THEN 100
            WHEN user_classification_count = 100 THEN 200
            WHEN user_classification_count = 500 THEN 500
        END
    FROM (
        SELECT COUNT(*) as user_classification_count
        FROM classifications
        WHERE user_id = NEW.user_id
    ) counts
    WHERE user_classification_count IN (1, 10, 50, 100, 500)
    ON CONFLICT (user_id, achievement_type) DO NOTHING;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for user stats updates
DROP TRIGGER IF EXISTS trigger_update_user_stats ON classifications;
CREATE TRIGGER trigger_update_user_stats
    AFTER INSERT ON classifications
    FOR EACH ROW
    EXECUTE FUNCTION update_user_stats();

-- Function to get user dashboard data
CREATE OR REPLACE FUNCTION get_user_dashboard_data(p_user_id UUID)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_classifications', COALESCE(COUNT(c.id), 0),
        'average_confidence', COALESCE(ROUND(AVG(c.confidence), 2), 0),
        'class_distribution', COALESCE(
            jsonb_object_agg(c.predicted_class, class_counts.count) 
            FILTER (WHERE c.predicted_class IS NOT NULL), 
            '{}'::jsonb
        ),
        'recent_activity', COALESCE(
            COUNT(CASE WHEN c.created_at >= NOW() - INTERVAL '7 days' THEN 1 END), 
            0
        ),
        'achievements_count', COALESCE(achievement_counts.count, 0),
        'environmental_impact', jsonb_build_object(
            'co2_saved_kg', COALESCE(COUNT(c.id) * 0.5, 0),
            'items_recycled', COALESCE(COUNT(c.id), 0),
            'waste_diverted_kg', COALESCE(COUNT(c.id) * 0.3, 0)
        )
    ) INTO result
    FROM users u
    LEFT JOIN classifications c ON u.id = c.user_id
    LEFT JOIN (
        SELECT 
            user_id, 
            predicted_class, 
            COUNT(*) as count
        FROM classifications 
        WHERE user_id = p_user_id
        GROUP BY user_id, predicted_class
    ) class_counts ON u.id = class_counts.user_id AND c.predicted_class = class_counts.predicted_class
    LEFT JOIN (
        SELECT user_id, COUNT(*) as count
        FROM user_achievements
        WHERE user_id = p_user_id
        GROUP BY user_id
    ) achievement_counts ON u.id = achievement_counts.user_id
    WHERE u.id = p_user_id
    GROUP BY u.id, achievement_counts.count;
    
    RETURN COALESCE(result, '{}'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- ================================
-- Row Level Security (RLS) Policies
-- ================================

-- Enable RLS on tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE classifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;

-- Users can only see and edit their own data
CREATE POLICY users_policy ON users
    FOR ALL USING (auth.uid()::text = id::text);

-- Users can only see their own classifications
CREATE POLICY classifications_policy ON classifications
    FOR ALL USING (auth.uid()::text = user_id::text);

-- Users can only see their own achievements
CREATE POLICY achievements_policy ON user_achievements
    FOR ALL USING (auth.uid()::text = user_id::text);

-- Public read access to classification categories and app settings
CREATE POLICY categories_read_policy ON classification_categories
    FOR SELECT USING (true);

CREATE POLICY settings_read_policy ON app_settings
    FOR SELECT USING (is_public = true);

-- ================================
-- Sample Data for Testing
-- ================================

-- Note: In production, remove this section
-- Insert a test user (password: 'testpass123')
-- INSERT INTO users (id, username, email, password_hash) VALUES
-- ('12345678-1234-1234-1234-123456789012', 'testuser', 'test@example.com', 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3');

-- Insert sample classifications
-- INSERT INTO classifications (user_id, image_path, predicted_class, confidence, class_probabilities) VALUES
-- ('12345678-1234-1234-1234-123456789012', 'test_image_1.jpg', 'plastic', 95.5, '{"plastic": 95.5, "glass": 2.1, "metal": 1.2, "paper": 0.8, "cardboard": 0.4}'),
-- ('12345678-1234-1234-1234-123456789012', 'test_image_2.jpg', 'cardboard', 88.3, '{"cardboard": 88.3, "paper": 8.1, "plastic": 2.1, "metal": 1.0, "glass": 0.5}');

-- ================================
-- Indexes for Performance
-- ================================

-- Additional composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_classifications_user_date ON classifications(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_classifications_class_confidence ON classifications(predicted_class, confidence DESC);
CREATE INDEX IF NOT EXISTS idx_users_active_created ON users(is_active, created_at DESC) WHERE is_active = true;

-- GIN index for JSONB columns
CREATE INDEX IF NOT EXISTS idx_classifications_probabilities ON classifications USING GIN(class_probabilities);
CREATE INDEX IF NOT EXISTS idx_app_settings_value ON app_settings USING GIN(setting_value);

-- ================================
-- Comments for Documentation
-- ================================

COMMENT ON TABLE users IS 'User accounts and profile information';
COMMENT ON TABLE classifications IS 'Waste classification results and metadata';
COMMENT ON TABLE classification_categories IS 'Available waste categories and their properties';
COMMENT ON TABLE user_achievements IS 'User achievements and badges';
COMMENT ON TABLE app_settings IS 'Application configuration settings';

COMMENT ON COLUMN classifications.class_probabilities IS 'JSON object containing probability scores for all classes';
COMMENT ON COLUMN classifications.confidence IS 'Confidence score of the predicted class (0-100)';
COMMENT ON COLUMN classifications.is_correct IS 'User feedback on prediction accuracy';

-- ================================
-- Database Maintenance
-- ================================

-- Function to clean up old uploads (run periodically)
CREATE OR REPLACE FUNCTION cleanup_old_data()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- Delete classifications older than 2 years
    DELETE FROM classifications 
    WHERE created_at < NOW() - INTERVAL '2 years';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    -- Log the cleanup operation
    INSERT INTO app_settings (setting_key, setting_value, description)
    VALUES (
        'last_cleanup', 
        jsonb_build_object('date', NOW(), 'deleted_records', deleted_count),
        'Last data cleanup operation'
    )
    ON CONFLICT (setting_key) 
    DO UPDATE SET 
        setting_value = EXCLUDED.setting_value,
        updated_at = NOW();
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;