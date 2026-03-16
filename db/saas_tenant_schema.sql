BEGIN;

-- 1. 平台管理体系
CREATE TABLE IF NOT EXISTS platform_users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(64) NOT NULL UNIQUE,
    email VARCHAR(128) NOT NULL UNIQUE,
    phone VARCHAR(32),
    display_name VARCHAR(128) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    password_salt VARCHAR(128),
    status VARCHAR(32) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'disabled', 'deleted', 'locked')),
    password_expires_at TIMESTAMP,
    last_login_at TIMESTAMP,
    last_login_ip VARCHAR(64),
    failed_login_count INTEGER NOT NULL DEFAULT 0,
    locked_until TIMESTAMP,
    mfa_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    remark TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS platform_roles (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(64) NOT NULL UNIQUE,
    name VARCHAR(128) NOT NULL,
    description TEXT,
    status VARCHAR(32) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'disabled')),
    created_by BIGINT REFERENCES platform_users(id),
    updated_by BIGINT REFERENCES platform_users(id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS platform_permissions (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(128) NOT NULL UNIQUE,
    name VARCHAR(128) NOT NULL,
    permission_type VARCHAR(32) NOT NULL CHECK (permission_type IN ('menu', 'api', 'operation', 'data')),
    parent_id BIGINT REFERENCES platform_permissions(id),
    resource VARCHAR(255),
    action VARCHAR(64),
    path VARCHAR(255),
    method VARCHAR(16),
    data_scope_rule JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS platform_role_permissions (
    id BIGSERIAL PRIMARY KEY,
    role_id BIGINT NOT NULL REFERENCES platform_roles(id) ON DELETE CASCADE,
    permission_id BIGINT NOT NULL REFERENCES platform_permissions(id) ON DELETE CASCADE,
    granted_by BIGINT REFERENCES platform_users(id),
    granted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (role_id, permission_id)
);

CREATE TABLE IF NOT EXISTS platform_role_members (
    id BIGSERIAL PRIMARY KEY,
    role_id BIGINT NOT NULL REFERENCES platform_roles(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES platform_users(id) ON DELETE CASCADE,
    assigned_by BIGINT REFERENCES platform_users(id),
    assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (role_id, user_id)
);

CREATE TABLE IF NOT EXISTS platform_password_policies (
    id BIGSERIAL PRIMARY KEY,
    policy_name VARCHAR(128) NOT NULL,
    min_length INTEGER NOT NULL DEFAULT 8,
    max_length INTEGER NOT NULL DEFAULT 64,
    require_uppercase BOOLEAN NOT NULL DEFAULT TRUE,
    require_lowercase BOOLEAN NOT NULL DEFAULT TRUE,
    require_number BOOLEAN NOT NULL DEFAULT TRUE,
    require_special BOOLEAN NOT NULL DEFAULT TRUE,
    password_expire_days INTEGER NOT NULL DEFAULT 90,
    prevent_reuse_count INTEGER NOT NULL DEFAULT 5,
    login_fail_lock_threshold INTEGER NOT NULL DEFAULT 5,
    lock_duration_minutes INTEGER NOT NULL DEFAULT 30,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_by BIGINT REFERENCES platform_users(id),
    updated_by BIGINT REFERENCES platform_users(id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS platform_security_policies (
    id BIGSERIAL PRIMARY KEY,
    policy_name VARCHAR(128) NOT NULL,
    ip_whitelist_required BOOLEAN NOT NULL DEFAULT FALSE,
    mfa_required BOOLEAN NOT NULL DEFAULT FALSE,
    session_timeout_minutes INTEGER NOT NULL DEFAULT 30,
    password_policy_id BIGINT REFERENCES platform_password_policies(id),
    extra_policy JSONB,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_by BIGINT REFERENCES platform_users(id),
    updated_by BIGINT REFERENCES platform_users(id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS platform_ip_whitelists (
    id BIGSERIAL PRIMARY KEY,
    subject_type VARCHAR(32) NOT NULL CHECK (subject_type IN ('platform', 'user')),
    subject_id BIGINT,
    ip_address VARCHAR(64) NOT NULL,
    ip_cidr VARCHAR(64),
    description TEXT,
    status VARCHAR(32) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'disabled')),
    effective_from TIMESTAMP,
    effective_to TIMESTAMP,
    created_by BIGINT REFERENCES platform_users(id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS platform_mfa_settings (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES platform_users(id) ON DELETE CASCADE,
    provider_type VARCHAR(32) NOT NULL CHECK (provider_type IN ('totp', 'sms', 'email', 'app')),
    secret_ciphertext TEXT,
    phone VARCHAR(32),
    email VARCHAR(128),
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    status VARCHAR(32) NOT NULL DEFAULT 'active' CHECK (status IN ('pending', 'active', 'disabled')),
    verified_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS platform_login_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES platform_users(id),
    username VARCHAR(64),
    login_type VARCHAR(32) NOT NULL DEFAULT 'password' CHECK (login_type IN ('password', 'mfa', 'api', 'sso')),
    login_status VARCHAR(32) NOT NULL CHECK (login_status IN ('success', 'failed', 'locked', 'disabled')),
    ip_address VARCHAR(64),
    user_agent TEXT,
    failure_reason TEXT,
    occurred_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. 租户生命周期体系 + 3. 租户信息体系
CREATE TABLE IF NOT EXISTS tenant_groups (
    id BIGSERIAL PRIMARY KEY,
    group_code VARCHAR(64) NOT NULL UNIQUE,
    group_name VARCHAR(128) NOT NULL,
    description TEXT,
    parent_id BIGINT REFERENCES tenant_groups(id),
    created_by BIGINT REFERENCES platform_users(id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tenants (
    id BIGSERIAL PRIMARY KEY,
    tenant_code VARCHAR(64) NOT NULL UNIQUE,
    tenant_name VARCHAR(128) NOT NULL,
    enterprise_name VARCHAR(255),
    contact_name VARCHAR(128),
    contact_phone VARCHAR(32),
    contact_email VARCHAR(128),
    source_type VARCHAR(32) NOT NULL DEFAULT 'admin' CHECK (source_type IN ('self_service', 'admin', 'api')),
    lifecycle_status VARCHAR(32) NOT NULL DEFAULT 'trial' CHECK (lifecycle_status IN ('trial', 'active', 'expiring', 'expired', 'suspended', 'closed', 'deleted')),
    current_plan_id BIGINT,
    current_subscription_id BIGINT,
    group_id BIGINT REFERENCES tenant_groups(id),
    industry_tag VARCHAR(64),
    customer_level VARCHAR(64),
    customer_source VARCHAR(64),
    default_language VARCHAR(32) NOT NULL DEFAULT 'zh-CN',
    default_timezone VARCHAR(64) NOT NULL DEFAULT 'Asia/Shanghai',
    isolation_mode VARCHAR(32) NOT NULL DEFAULT 'shared_database' CHECK (isolation_mode IN ('shared_database', 'schema_isolated', 'database_isolated', 'hybrid')),
    database_name VARCHAR(128),
    schema_name VARCHAR(128),
    default_domain VARCHAR(255),
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    opened_at TIMESTAMP,
    activated_at TIMESTAMP,
    expires_at TIMESTAMP,
    suspended_at TIMESTAMP,
    closed_at TIMESTAMP,
    deleted_at TIMESTAMP,
    created_by BIGINT REFERENCES platform_users(id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tenant_domains (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    domain VARCHAR(255) NOT NULL,
    domain_type VARCHAR(32) NOT NULL CHECK (domain_type IN ('default', 'subdomain', 'custom')),
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    verification_status VARCHAR(32) NOT NULL DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'failed')),
    verification_token VARCHAR(128),
    verified_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (domain),
    UNIQUE (tenant_id, domain)
);

CREATE TABLE IF NOT EXISTS tenant_tags (
    id BIGSERIAL PRIMARY KEY,
    tag_key VARCHAR(64) NOT NULL,
    tag_value VARCHAR(128) NOT NULL,
    tag_type VARCHAR(32) NOT NULL CHECK (tag_type IN ('industry', 'customer_level', 'customer_source', 'custom')),
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tag_key, tag_value)
);

CREATE TABLE IF NOT EXISTS tenant_tag_bindings (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    tag_id BIGINT NOT NULL REFERENCES tenant_tags(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tenant_id, tag_id)
);

CREATE TABLE IF NOT EXISTS tenant_group_members (
    id BIGSERIAL PRIMARY KEY,
    group_id BIGINT NOT NULL REFERENCES tenant_groups(id) ON DELETE CASCADE,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (group_id, tenant_id)
);

CREATE TABLE IF NOT EXISTS tenant_initialization_tasks (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    task_type VARCHAR(32) NOT NULL CHECK (task_type IN ('database', 'config', 'plan', 'resource')),
    task_status VARCHAR(32) NOT NULL DEFAULT 'pending' CHECK (task_status IN ('pending', 'running', 'success', 'failed')),
    details JSONB,
    started_at TIMESTAMP,
    finished_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tenant_lifecycle_events (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    event_type VARCHAR(32) NOT NULL CHECK (event_type IN ('register', 'open', 'enable', 'suspend', 'resume', 'close', 'delete', 'expire')),
    from_status VARCHAR(32),
    to_status VARCHAR(32),
    reason TEXT,
    operator_id BIGINT REFERENCES platform_users(id),
    metadata JSONB,
    occurred_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tenant_data_jobs (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    job_type VARCHAR(32) NOT NULL CHECK (job_type IN ('archive', 'backup', 'migration', 'cleanup')),
    job_status VARCHAR(32) NOT NULL DEFAULT 'pending' CHECK (job_status IN ('pending', 'running', 'success', 'failed')),
    storage_path VARCHAR(255),
    payload JSONB,
    started_at TIMESTAMP,
    finished_at TIMESTAMP,
    created_by BIGINT REFERENCES platform_users(id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 4. 租户资源管理 + 14. 配额系统/限流系统
CREATE TABLE IF NOT EXISTS tenant_resource_quotas (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    quota_type VARCHAR(32) NOT NULL CHECK (quota_type IN ('user_count', 'api_calls', 'concurrent_requests', 'storage_size', 'database_size', 'file_count')),
    quota_limit BIGINT NOT NULL,
    warning_threshold BIGINT,
    reset_cycle VARCHAR(32) CHECK (reset_cycle IN ('none', 'hourly', 'daily', 'weekly', 'monthly', 'yearly')),
    effective_from TIMESTAMP,
    effective_to TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tenant_id, quota_type)
);

CREATE TABLE IF NOT EXISTS tenant_resource_usage_stats (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    metric_date DATE NOT NULL,
    user_count INTEGER NOT NULL DEFAULT 0,
    api_call_count BIGINT NOT NULL DEFAULT 0,
    concurrent_request_peak INTEGER NOT NULL DEFAULT 0,
    storage_bytes BIGINT NOT NULL DEFAULT 0,
    database_bytes BIGINT NOT NULL DEFAULT 0,
    file_count BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tenant_id, metric_date)
);

CREATE TABLE IF NOT EXISTS rate_limit_policies (
    id BIGSERIAL PRIMARY KEY,
    subject_type VARCHAR(32) NOT NULL CHECK (subject_type IN ('api', 'tenant', 'ip')),
    subject_key VARCHAR(255) NOT NULL,
    window_seconds INTEGER NOT NULL,
    limit_count INTEGER NOT NULL,
    burst_limit INTEGER,
    status VARCHAR(32) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'disabled')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (subject_type, subject_key)
);

-- 5. 租户配置中心
CREATE TABLE IF NOT EXISTS tenant_system_configs (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    system_name VARCHAR(128),
    logo_url VARCHAR(255),
    system_theme VARCHAR(64),
    default_language VARCHAR(32),
    default_timezone VARCHAR(64),
    extra_config JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tenant_id)
);

CREATE TABLE IF NOT EXISTS tenant_feature_flags (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    feature_key VARCHAR(128) NOT NULL,
    feature_name VARCHAR(128) NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT FALSE,
    rollout_type VARCHAR(32) NOT NULL DEFAULT 'full' CHECK (rollout_type IN ('full', 'closed', 'gray')),
    rollout_config JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tenant_id, feature_key)
);

CREATE TABLE IF NOT EXISTS tenant_parameters (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    param_key VARCHAR(128) NOT NULL,
    param_name VARCHAR(128) NOT NULL,
    param_type VARCHAR(32) NOT NULL CHECK (param_type IN ('system', 'extension', 'custom')),
    param_value JSONB NOT NULL,
    is_encrypted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tenant_id, param_key)
);

CREATE TABLE IF NOT EXISTS tenant_ui_brandings (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    brand_name VARCHAR(128),
    login_page_config JSONB,
    ui_theme JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tenant_id)
);

-- 6. SaaS 套餐系统
CREATE TABLE IF NOT EXISTS saas_packages (
    id BIGSERIAL PRIMARY KEY,
    package_code VARCHAR(64) NOT NULL UNIQUE,
    package_name VARCHAR(128) NOT NULL,
    description TEXT,
    status VARCHAR(32) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'disabled', 'deleted')),
    created_by BIGINT REFERENCES platform_users(id),
    updated_by BIGINT REFERENCES platform_users(id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS saas_package_versions (
    id BIGSERIAL PRIMARY KEY,
    package_id BIGINT NOT NULL REFERENCES saas_packages(id) ON DELETE CASCADE,
    version_code VARCHAR(64) NOT NULL,
    version_name VARCHAR(128) NOT NULL,
    edition_type VARCHAR(32) NOT NULL CHECK (edition_type IN ('free', 'standard', 'professional', 'enterprise')),
    billing_cycle VARCHAR(32) NOT NULL DEFAULT 'monthly' CHECK (billing_cycle IN ('monthly', 'quarterly', 'yearly', 'one_time')),
    price DECIMAL(18, 2) NOT NULL DEFAULT 0,
    currency_code VARCHAR(16) NOT NULL DEFAULT 'CNY',
    trial_days INTEGER NOT NULL DEFAULT 0,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    effective_from TIMESTAMP,
    effective_to TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (package_id, version_code)
);

CREATE TABLE IF NOT EXISTS saas_package_capabilities (
    id BIGSERIAL PRIMARY KEY,
    package_version_id BIGINT NOT NULL REFERENCES saas_package_versions(id) ON DELETE CASCADE,
    capability_key VARCHAR(128) NOT NULL,
    capability_name VARCHAR(128) NOT NULL,
    capability_type VARCHAR(32) NOT NULL CHECK (capability_type IN ('feature', 'user_limit', 'storage_limit', 'api_limit', 'concurrency_limit', 'custom')),
    capability_value JSONB NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (package_version_id, capability_key)
);

-- 7. 订阅系统
CREATE TABLE IF NOT EXISTS tenant_subscriptions (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    package_version_id BIGINT NOT NULL REFERENCES saas_package_versions(id),
    subscription_status VARCHAR(32) NOT NULL CHECK (subscription_status IN ('active', 'expiring', 'expired', 'suspended', 'cancelled')),
    subscription_type VARCHAR(32) NOT NULL DEFAULT 'formal' CHECK (subscription_type IN ('trial', 'formal')),
    started_at TIMESTAMP NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    auto_renew BOOLEAN NOT NULL DEFAULT FALSE,
    cancelled_at TIMESTAMP,
    created_by BIGINT REFERENCES platform_users(id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tenant_trials (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    package_version_id BIGINT REFERENCES saas_package_versions(id),
    started_at TIMESTAMP NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    converted_subscription_id BIGINT REFERENCES tenant_subscriptions(id),
    status VARCHAR(32) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'converted', 'cancelled')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tenant_id, started_at)
);

CREATE TABLE IF NOT EXISTS tenant_subscription_changes (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    subscription_id BIGINT REFERENCES tenant_subscriptions(id) ON DELETE SET NULL,
    change_type VARCHAR(32) NOT NULL CHECK (change_type IN ('subscribe', 'upgrade', 'downgrade', 'renew', 'cancel', 'trial_to_formal')),
    from_package_version_id BIGINT REFERENCES saas_package_versions(id),
    to_package_version_id BIGINT REFERENCES saas_package_versions(id),
    effective_at TIMESTAMP NOT NULL,
    remark TEXT,
    created_by BIGINT REFERENCES platform_users(id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 8. 计费与账单系统
CREATE TABLE IF NOT EXISTS billing_invoices (
    id BIGSERIAL PRIMARY KEY,
    invoice_no VARCHAR(64) NOT NULL UNIQUE,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    subscription_id BIGINT REFERENCES tenant_subscriptions(id),
    invoice_status VARCHAR(32) NOT NULL CHECK (invoice_status IN ('pending', 'issued', 'paid', 'overdue', 'cancelled')),
    billing_period_start TIMESTAMP NOT NULL,
    billing_period_end TIMESTAMP NOT NULL,
    subtotal_amount DECIMAL(18, 2) NOT NULL DEFAULT 0,
    extra_amount DECIMAL(18, 2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(18, 2) NOT NULL DEFAULT 0,
    total_amount DECIMAL(18, 2) NOT NULL DEFAULT 0,
    currency_code VARCHAR(16) NOT NULL DEFAULT 'CNY',
    issued_at TIMESTAMP,
    due_at TIMESTAMP,
    paid_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS billing_invoice_items (
    id BIGSERIAL PRIMARY KEY,
    invoice_id BIGINT NOT NULL REFERENCES billing_invoices(id) ON DELETE CASCADE,
    item_type VARCHAR(32) NOT NULL CHECK (item_type IN ('package_fee', 'usage_fee', 'extra_fee')),
    item_name VARCHAR(128) NOT NULL,
    quantity DECIMAL(18, 4) NOT NULL DEFAULT 1,
    unit_price DECIMAL(18, 4) NOT NULL DEFAULT 0,
    amount DECIMAL(18, 2) NOT NULL DEFAULT 0,
    item_metadata JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS payment_orders (
    id BIGSERIAL PRIMARY KEY,
    order_no VARCHAR(64) NOT NULL UNIQUE,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    invoice_id BIGINT REFERENCES billing_invoices(id),
    payment_channel VARCHAR(32) NOT NULL CHECK (payment_channel IN ('alipay', 'wechat', 'bank_transfer', 'offline', 'other')),
    payment_status VARCHAR(32) NOT NULL CHECK (payment_status IN ('pending', 'paid', 'failed', 'cancelled', 'refunded', 'partial_refunded')),
    amount DECIMAL(18, 2) NOT NULL,
    currency_code VARCHAR(16) NOT NULL DEFAULT 'CNY',
    third_party_txn_no VARCHAR(128),
    paid_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS payment_refunds (
    id BIGSERIAL PRIMARY KEY,
    refund_no VARCHAR(64) NOT NULL UNIQUE,
    payment_order_id BIGINT NOT NULL REFERENCES payment_orders(id) ON DELETE CASCADE,
    refund_status VARCHAR(32) NOT NULL CHECK (refund_status IN ('pending', 'success', 'failed', 'cancelled')),
    refund_amount DECIMAL(18, 2) NOT NULL,
    refund_reason TEXT,
    refunded_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 9. API 与集成平台
CREATE TABLE IF NOT EXISTS tenant_api_keys (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    key_name VARCHAR(128) NOT NULL,
    access_key VARCHAR(128) NOT NULL UNIQUE,
    secret_hash VARCHAR(255) NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'disabled', 'deleted')),
    quota_limit BIGINT,
    rate_limit INTEGER,
    last_used_at TIMESTAMP,
    expires_at TIMESTAMP,
    created_by BIGINT REFERENCES platform_users(id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tenant_api_usage_stats (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    api_key_id BIGINT REFERENCES tenant_api_keys(id) ON DELETE SET NULL,
    stat_date DATE NOT NULL,
    api_path VARCHAR(255) NOT NULL,
    request_count BIGINT NOT NULL DEFAULT 0,
    success_count BIGINT NOT NULL DEFAULT 0,
    error_count BIGINT NOT NULL DEFAULT 0,
    average_latency_ms INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tenant_id, api_key_id, stat_date, api_path)
);

CREATE TABLE IF NOT EXISTS webhook_events (
    id BIGSERIAL PRIMARY KEY,
    event_code VARCHAR(128) NOT NULL UNIQUE,
    event_name VARCHAR(128) NOT NULL,
    description TEXT,
    payload_schema JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tenant_webhooks (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    webhook_name VARCHAR(128) NOT NULL,
    target_url VARCHAR(500) NOT NULL,
    secret_token_hash VARCHAR(255),
    status VARCHAR(32) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'disabled')),
    retry_policy JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tenant_webhook_events (
    id BIGSERIAL PRIMARY KEY,
    webhook_id BIGINT NOT NULL REFERENCES tenant_webhooks(id) ON DELETE CASCADE,
    event_id BIGINT NOT NULL REFERENCES webhook_events(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (webhook_id, event_id)
);

CREATE TABLE IF NOT EXISTS webhook_delivery_logs (
    id BIGSERIAL PRIMARY KEY,
    webhook_id BIGINT NOT NULL REFERENCES tenant_webhooks(id) ON DELETE CASCADE,
    event_id BIGINT REFERENCES webhook_events(id),
    delivery_status VARCHAR(32) NOT NULL CHECK (delivery_status IN ('pending', 'success', 'failed')),
    request_headers JSONB,
    request_body JSONB,
    response_status_code INTEGER,
    response_body TEXT,
    retry_count INTEGER NOT NULL DEFAULT 0,
    delivered_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 10. 平台运营体系
CREATE TABLE IF NOT EXISTS tenant_daily_stats (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    stat_date DATE NOT NULL,
    active_user_count INTEGER NOT NULL DEFAULT 0,
    new_user_count INTEGER NOT NULL DEFAULT 0,
    api_call_count BIGINT NOT NULL DEFAULT 0,
    storage_bytes BIGINT NOT NULL DEFAULT 0,
    resource_score DECIMAL(10, 2) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (tenant_id, stat_date)
);

CREATE TABLE IF NOT EXISTS platform_monitor_metrics (
    id BIGSERIAL PRIMARY KEY,
    component_name VARCHAR(128) NOT NULL,
    metric_type VARCHAR(32) NOT NULL CHECK (metric_type IN ('service_status', 'system_load', 'api_performance')),
    metric_key VARCHAR(128) NOT NULL,
    metric_value DECIMAL(18, 4) NOT NULL,
    metric_unit VARCHAR(32),
    collected_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 11. 日志与审计
CREATE TABLE IF NOT EXISTS operation_logs (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT REFERENCES tenants(id) ON DELETE SET NULL,
    operator_type VARCHAR(32) NOT NULL CHECK (operator_type IN ('platform_user', 'tenant_user', 'system')),
    operator_id BIGINT,
    action VARCHAR(128) NOT NULL,
    resource_type VARCHAR(64),
    resource_id VARCHAR(128),
    request_id VARCHAR(128),
    ip_address VARCHAR(64),
    user_agent TEXT,
    operation_result VARCHAR(32) NOT NULL CHECK (operation_result IN ('success', 'failed')),
    details JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS audit_logs (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT REFERENCES tenants(id) ON DELETE SET NULL,
    audit_type VARCHAR(64) NOT NULL,
    severity VARCHAR(32) NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    subject_type VARCHAR(64),
    subject_id VARCHAR(128),
    change_summary JSONB,
    compliance_tag VARCHAR(64),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS system_logs (
    id BIGSERIAL PRIMARY KEY,
    service_name VARCHAR(128) NOT NULL,
    log_level VARCHAR(16) NOT NULL CHECK (log_level IN ('debug', 'info', 'warn', 'error', 'fatal')),
    trace_id VARCHAR(128),
    message TEXT NOT NULL,
    context JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 12. 通知系统
CREATE TABLE IF NOT EXISTS notification_templates (
    id BIGSERIAL PRIMARY KEY,
    template_code VARCHAR(64) NOT NULL UNIQUE,
    template_name VARCHAR(128) NOT NULL,
    channel VARCHAR(32) NOT NULL CHECK (channel IN ('email', 'sms', 'site_message')),
    subject_template VARCHAR(255),
    body_template TEXT NOT NULL,
    variables JSONB,
    status VARCHAR(32) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'disabled')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS notifications (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT REFERENCES tenants(id) ON DELETE CASCADE,
    template_id BIGINT REFERENCES notification_templates(id),
    channel VARCHAR(32) NOT NULL CHECK (channel IN ('email', 'sms', 'site_message')),
    recipient VARCHAR(255) NOT NULL,
    subject VARCHAR(255),
    body TEXT NOT NULL,
    send_status VARCHAR(32) NOT NULL CHECK (send_status IN ('pending', 'sent', 'failed', 'read')),
    sent_at TIMESTAMP,
    read_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 13. 文件与存储
CREATE TABLE IF NOT EXISTS storage_strategies (
    id BIGSERIAL PRIMARY KEY,
    strategy_code VARCHAR(64) NOT NULL UNIQUE,
    strategy_name VARCHAR(128) NOT NULL,
    provider_type VARCHAR(32) NOT NULL CHECK (provider_type IN ('local', 's3', 'oss', 'cos', 'minio', 'other')),
    bucket_name VARCHAR(255),
    base_path VARCHAR(255),
    config JSONB,
    status VARCHAR(32) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'disabled')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tenant_files (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    storage_strategy_id BIGINT REFERENCES storage_strategies(id),
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_ext VARCHAR(32),
    mime_type VARCHAR(128),
    file_size BIGINT NOT NULL DEFAULT 0,
    checksum VARCHAR(128),
    uploader_type VARCHAR(32) NOT NULL CHECK (uploader_type IN ('platform_user', 'tenant_user', 'system')),
    uploader_id BIGINT,
    visibility VARCHAR(32) NOT NULL DEFAULT 'private' CHECK (visibility IN ('private', 'tenant', 'public')),
    download_count BIGINT NOT NULL DEFAULT 0,
    last_downloaded_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS file_access_policies (
    id BIGSERIAL PRIMARY KEY,
    file_id BIGINT NOT NULL REFERENCES tenant_files(id) ON DELETE CASCADE,
    subject_type VARCHAR(32) NOT NULL CHECK (subject_type IN ('tenant', 'user', 'role', 'public')),
    subject_id VARCHAR(128),
    permission_code VARCHAR(32) NOT NULL CHECK (permission_code IN ('read', 'write', 'delete', 'download')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (file_id, subject_type, subject_id, permission_code)
);

-- 14. 技术基础设施
CREATE TABLE IF NOT EXISTS data_isolation_policies (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT REFERENCES tenants(id) ON DELETE CASCADE,
    isolation_type VARCHAR(32) NOT NULL CHECK (isolation_type IN ('tenant_id', 'access_control', 'security_policy')),
    policy_name VARCHAR(128) NOT NULL,
    policy_config JSONB NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'disabled')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS infrastructure_components (
    id BIGSERIAL PRIMARY KEY,
    component_type VARCHAR(32) NOT NULL CHECK (component_type IN ('cache', 'scheduler', 'config_center', 'service_discovery')),
    component_name VARCHAR(128) NOT NULL,
    endpoint VARCHAR(255),
    status VARCHAR(32) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'disabled', 'degraded')),
    component_config JSONB,
    last_heartbeat_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (component_type, component_name)
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'fk_tenants_current_plan'
    ) THEN
        ALTER TABLE tenants
            ADD CONSTRAINT fk_tenants_current_plan
            FOREIGN KEY (current_plan_id) REFERENCES saas_package_versions(id);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'fk_tenants_current_subscription'
    ) THEN
        ALTER TABLE tenants
            ADD CONSTRAINT fk_tenants_current_subscription
            FOREIGN KEY (current_subscription_id) REFERENCES tenant_subscriptions(id);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_platform_login_logs_user_time ON platform_login_logs (user_id, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_tenant_lifecycle_events_tenant_time ON tenant_lifecycle_events (tenant_id, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_tenant_data_jobs_tenant_type ON tenant_data_jobs (tenant_id, job_type);
CREATE INDEX IF NOT EXISTS idx_usage_stats_tenant_date ON tenant_resource_usage_stats (tenant_id, metric_date DESC);
CREATE INDEX IF NOT EXISTS idx_feature_flags_tenant_enabled ON tenant_feature_flags (tenant_id, enabled);
CREATE INDEX IF NOT EXISTS idx_subscriptions_tenant_status ON tenant_subscriptions (tenant_id, subscription_status);
CREATE INDEX IF NOT EXISTS idx_invoices_tenant_status ON billing_invoices (tenant_id, invoice_status);
CREATE INDEX IF NOT EXISTS idx_payment_orders_tenant_status ON payment_orders (tenant_id, payment_status);
CREATE INDEX IF NOT EXISTS idx_api_usage_tenant_date ON tenant_api_usage_stats (tenant_id, stat_date DESC);
CREATE INDEX IF NOT EXISTS idx_webhook_delivery_status_time ON webhook_delivery_logs (delivery_status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_operation_logs_tenant_time ON operation_logs (tenant_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_tenant_time ON audit_logs (tenant_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_tenant_status ON notifications (tenant_id, send_status);
CREATE INDEX IF NOT EXISTS idx_tenant_files_tenant_visibility ON tenant_files (tenant_id, visibility);
CREATE INDEX IF NOT EXISTS idx_platform_monitor_metrics_type_time ON platform_monitor_metrics (metric_type, collected_at DESC);

COMMIT;
