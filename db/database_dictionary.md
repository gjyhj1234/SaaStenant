# SaaStenant 数据库字典

> 本文档是 **AI 编程优先** 的数据库字典，不是建表 SQL。

> 目标：让 AI 能基于本文档稳定生成实体类、枚举、关联关系和值对象，并在程序运行时由应用来维护数据库结构。

## 1. 文档使用说明

- 本字典按“模块 -> 表 -> 字段”展开，适合直接提供给 AI 用于生成实体类。
- 主键统一建议映射为 `Long`；时间字段统一建议映射为 `LocalDateTime` 或 `LocalDate`。
- 所有 `*_status`、`*_type`、`*_mode`、`*_level`、`*_scope` 等字段，建议由 AI 生成强类型枚举。
- 所有 `JSONB` 字段，建议映射为 `JsonNode`、`Map<String, Object>` 或独立值对象。
- 若后续应用采用 JPA / MyBatis / MyBatis-Plus / EF Core / Prisma 等 ORM，请以“字段类型 + 是否可空 + 默认值 + 约束 + 关系说明”为准生成实体。

## 2. 全局建模约定

| 主题 | 约定 |
| --- | --- |
| 主键 | 统一为 `BIGSERIAL/BIGINT` 语义，建议实体类型使用 `Long` |
| 时间 | `TIMESTAMP` -> `LocalDateTime`，`DATE` -> `LocalDate` |
| 金额 | `DECIMAL(18,2)` / `DECIMAL(18,4)` -> `BigDecimal` |
| JSON 配置 | `JSONB` -> `JsonNode` / `Map<String,Object>` / 独立值对象 |
| 软删除 | 仅部分表包含 `deleted_at`，为空表示未删除 |
| 审计字段 | 多数业务表包含 `created_at`、`updated_at`，建议抽取基类实体 |
| 多租户 | 租户域数据通常直接持有 `tenant_id`；平台级字典表不持有 `tenant_id` |
| 安全字段 | 密码、密钥、密文类字段只保存摘要或密文，不应生成明文字段逻辑 |

## 3. 模块总览

| 模块 | 表数量 | 主要表 |
| --- | ---: | --- |
| 1. 平台管理体系 | 10 | `platform_users`, `platform_roles`, `platform_permissions`, `platform_role_permissions`, `platform_role_members` ... |
| 2. 租户生命周期体系 | 4 | `tenants`, `tenant_initialization_tasks`, `tenant_lifecycle_events`, `tenant_data_jobs` |
| 3. 租户信息体系 | 5 | `tenant_groups`, `tenant_domains`, `tenant_tags`, `tenant_tag_bindings`, `tenant_group_members` |
| 4. 租户资源管理 | 2 | `tenant_resource_quotas`, `tenant_resource_usage_stats` |
| 5. 租户配置中心 | 4 | `tenant_system_configs`, `tenant_feature_flags`, `tenant_parameters`, `tenant_ui_brandings` |
| 6. SaaS套餐系统 | 3 | `saas_packages`, `saas_package_versions`, `saas_package_capabilities` |
| 7. 订阅系统 | 3 | `tenant_subscriptions`, `tenant_trials`, `tenant_subscription_changes` |
| 8. 计费与账单系统 | 4 | `billing_invoices`, `billing_invoice_items`, `payment_orders`, `payment_refunds` |
| 9. API与集成平台 | 6 | `tenant_api_keys`, `tenant_api_usage_stats`, `webhook_events`, `tenant_webhooks`, `tenant_webhook_events` ... |
| 10. 平台运营体系 | 2 | `tenant_daily_stats`, `platform_monitor_metrics` |
| 11. 日志与审计 | 3 | `operation_logs`, `audit_logs`, `system_logs` |
| 12. 通知系统 | 2 | `notification_templates`, `notifications` |
| 13. 文件与存储 | 3 | `storage_strategies`, `tenant_files`, `file_access_policies` |
| 14. 技术基础设施 | 3 | `rate_limit_policies`, `data_isolation_policies`, `infrastructure_components` |

## 4. AI 生成实体建议

- 建议每张表生成一个实体类，类名优先采用本文档中的“建议实体名”。
- 对中间关系表（如 `platform_role_permissions`、`tenant_tag_bindings`）可直接生成轻量关系实体，不建议引入复杂领域行为。
- `*_logs`、`*_stats`、`*_items`、`*_events`、`*_changes` 这类表建议作为追加型或统计型实体处理，通常不做强更新。
- `current_plan_id`、`current_subscription_id` 这类“当前指针”字段应保留 nullable，避免实体初始化时出现循环依赖。
- 建议为所有带 CHECK 枚举的字段额外生成枚举类型，并在实体注释中保留本文档的中文业务解释。

## 模块：1. 平台管理体系

### platform_users（平台用户）

- **建议实体名**：`PlatformUser`
- **业务用途**：记录 SaaS 平台管理员账号信息，用于登录、认证、禁用、锁定和基础账号维护。
- **主要关系**：无直接外键，主要作为独立主档或日志表使用。
- **表级约束**：无额外表级约束。
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `username` | `VARCHAR(64)` | `String` | 否 | - | UNIQUE / NOT NULL | 平台管理员登录账号。 |
| `email` | `VARCHAR(128)` | `String` | 否 | - | UNIQUE / NOT NULL | 平台管理员邮箱。 |
| `phone` | `VARCHAR(32)` | `String` | 是 | - | - | 平台管理员手机号。 |
| `display_name` | `VARCHAR(128)` | `String` | 否 | - | NOT NULL | 平台管理员显示名称。 |
| `password_hash` | `VARCHAR(255)` | `String` | 否 | - | NOT NULL | 密码摘要，不保存明文。 |
| `password_salt` | `VARCHAR(128)` | `String` | 是 | - | - | 密码盐值；如算法自带盐可为空。 |
| `status` | `VARCHAR(32)` | `String` | 否 | 'active' | NOT NULL / CHECK(status IN ('active', 'disabled', 'deleted', 'locked')) | 业务状态字段。应根据 CHECK 约束生成枚举。 |
| `password_expires_at` | `TIMESTAMP` | `LocalDateTime` | 是 | - | - | 密码过期时间。 |
| `last_login_at` | `TIMESTAMP` | `LocalDateTime` | 是 | - | - | 最近一次登录时间。 |
| `last_login_ip` | `VARCHAR(64)` | `String` | 是 | - | - | 最近一次登录 IP。 |
| `failed_login_count` | `INTEGER` | `Integer` | 否 | 0 | NOT NULL | 累计连续失败登录次数。 |
| `locked_until` | `TIMESTAMP` | `LocalDateTime` | 是 | - | - | 账户锁定截止时间。 |
| `mfa_enabled` | `BOOLEAN` | `Boolean` | 否 | FALSE | NOT NULL | 是否启用 MFA。 |
| `remark` | `TEXT` | `String` | 是 | - | - | 备注信息。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |
| `updated_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 更新时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |
| `deleted_at` | `TIMESTAMP` | `LocalDateTime` | 是 | - | - | 软删除时间；为空表示未删除。 |

### platform_roles（平台角色）

- **建议实体名**：`PlatformRole`
- **业务用途**：定义平台级角色，用于管理员分工、授权和角色治理。
- **主要关系**：`created_by` -> `platform_users`；`updated_by` -> `platform_users`
- **表级约束**：无额外表级约束。
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `code` | `VARCHAR(64)` | `String` | 否 | - | UNIQUE / NOT NULL | 业务字段。 |
| `name` | `VARCHAR(128)` | `String` | 否 | - | NOT NULL | 业务字段。 |
| `description` | `TEXT` | `String` | 是 | - | - | 描述说明。 |
| `status` | `VARCHAR(32)` | `String` | 否 | 'active' | NOT NULL / CHECK(status IN ('active', 'disabled')) | 业务状态字段。应根据 CHECK 约束生成枚举。 |
| `created_by` | `BIGINT` | `Long` | 是 | - | FK->platform_users | 创建人平台用户 ID。 |
| `updated_by` | `BIGINT` | `Long` | 是 | - | FK->platform_users | 更新人平台用户 ID。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |
| `updated_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 更新时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

### platform_permissions（平台权限）

- **建议实体名**：`PlatformPermission`
- **业务用途**：定义平台菜单、API、操作和数据权限，是平台 RBAC 的基础字典。
- **主要关系**：`parent_id` -> `platform_permissions`
- **表级约束**：无额外表级约束。
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `code` | `VARCHAR(128)` | `String` | 否 | - | UNIQUE / NOT NULL | 业务字段。 |
| `name` | `VARCHAR(128)` | `String` | 否 | - | NOT NULL | 业务字段。 |
| `permission_type` | `VARCHAR(32)` | `String` | 否 | - | NOT NULL / CHECK(permission_type IN ('menu', 'api', 'operation', 'data')) | 类型字段，建议生成枚举。 |
| `parent_id` | `BIGINT` | `Long` | 是 | - | FK->platform_permissions | 关联 `platform_permissions` 表主键。 |
| `resource` | `VARCHAR(255)` | `String` | 是 | - | - | 业务字段。 |
| `action` | `VARCHAR(64)` | `String` | 是 | - | - | 业务字段。 |
| `path` | `VARCHAR(255)` | `String` | 是 | - | - | 业务字段。 |
| `method` | `VARCHAR(16)` | `String` | 是 | - | - | 业务字段。 |
| `data_scope_rule` | `JSONB` | `JsonNode/Map<String,Object>` | 是 | - | - | 业务字段。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |
| `updated_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 更新时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

### platform_role_permissions（平台角色权限关系）

- **建议实体名**：`PlatformRolePermission`
- **业务用途**：维护角色与权限的多对多授权关系。
- **主要关系**：`role_id` -> `platform_roles`；`permission_id` -> `platform_permissions`；`granted_by` -> `platform_users`
- **表级约束**：`UNIQUE (role_id, permission_id)`
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `role_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->platform_roles | 关联 `platform_roles` 表主键。 |
| `permission_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->platform_permissions | 关联 `platform_permissions` 表主键。 |
| `granted_by` | `BIGINT` | `Long` | 是 | - | FK->platform_users | 关联 `platform_users` 表主键。 |
| `granted_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 时间字段。 |

### platform_role_members（平台角色成员关系）

- **建议实体名**：`PlatformRoleMember`
- **业务用途**：维护平台用户与角色的多对多归属关系。
- **主要关系**：`role_id` -> `platform_roles`；`user_id` -> `platform_users`；`assigned_by` -> `platform_users`
- **表级约束**：`UNIQUE (role_id, user_id)`
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `role_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->platform_roles | 关联 `platform_roles` 表主键。 |
| `user_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->platform_users | 关联 `platform_users` 表主键。 |
| `assigned_by` | `BIGINT` | `Long` | 是 | - | FK->platform_users | 关联 `platform_users` 表主键。 |
| `assigned_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 时间字段。 |

### platform_password_policies（平台密码策略）

- **建议实体名**：`PlatformPasswordPolicy`
- **业务用途**：定义密码复杂度、过期策略、历史重用限制和登录失败锁定阈值。
- **主要关系**：`created_by` -> `platform_users`；`updated_by` -> `platform_users`
- **表级约束**：无额外表级约束。
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `policy_name` | `VARCHAR(128)` | `String` | 否 | - | NOT NULL | 名称。 |
| `min_length` | `INTEGER` | `Integer` | 否 | 8 | NOT NULL | 业务字段。 |
| `max_length` | `INTEGER` | `Integer` | 否 | 64 | NOT NULL | 业务字段。 |
| `require_uppercase` | `BOOLEAN` | `Boolean` | 否 | TRUE | NOT NULL | 业务字段。 |
| `require_lowercase` | `BOOLEAN` | `Boolean` | 否 | TRUE | NOT NULL | 业务字段。 |
| `require_number` | `BOOLEAN` | `Boolean` | 否 | TRUE | NOT NULL | 业务字段。 |
| `require_special` | `BOOLEAN` | `Boolean` | 否 | TRUE | NOT NULL | 业务字段。 |
| `password_expire_days` | `INTEGER` | `Integer` | 否 | 90 | NOT NULL | 业务字段。 |
| `prevent_reuse_count` | `INTEGER` | `Integer` | 否 | 5 | NOT NULL | 数量统计字段。 |
| `login_fail_lock_threshold` | `INTEGER` | `Integer` | 否 | 5 | NOT NULL | 业务字段。 |
| `lock_duration_minutes` | `INTEGER` | `Integer` | 否 | 30 | NOT NULL | 业务字段。 |
| `is_default` | `BOOLEAN` | `Boolean` | 否 | FALSE | NOT NULL | 布尔标记字段。 |
| `created_by` | `BIGINT` | `Long` | 是 | - | FK->platform_users | 创建人平台用户 ID。 |
| `updated_by` | `BIGINT` | `Long` | 是 | - | FK->platform_users | 更新人平台用户 ID。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |
| `updated_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 更新时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

### platform_security_policies（平台安全策略）

- **建议实体名**：`PlatformSecurityPolicy`
- **业务用途**：定义 IP 白名单、MFA、会话时长等平台安全治理规则。
- **主要关系**：`password_policy_id` -> `platform_password_policies`；`created_by` -> `platform_users`；`updated_by` -> `platform_users`
- **表级约束**：无额外表级约束。
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `policy_name` | `VARCHAR(128)` | `String` | 否 | - | NOT NULL | 名称。 |
| `ip_whitelist_required` | `BOOLEAN` | `Boolean` | 否 | FALSE | NOT NULL | 业务字段。 |
| `mfa_required` | `BOOLEAN` | `Boolean` | 否 | FALSE | NOT NULL | 业务字段。 |
| `session_timeout_minutes` | `INTEGER` | `Integer` | 否 | 30 | NOT NULL | 业务字段。 |
| `password_policy_id` | `BIGINT` | `Long` | 是 | - | FK->platform_password_policies | 关联 `platform_password_policies` 表主键。 |
| `extra_policy` | `JSONB` | `JsonNode/Map<String,Object>` | 是 | - | - | 业务字段。 |
| `is_default` | `BOOLEAN` | `Boolean` | 否 | FALSE | NOT NULL | 布尔标记字段。 |
| `created_by` | `BIGINT` | `Long` | 是 | - | FK->platform_users | 创建人平台用户 ID。 |
| `updated_by` | `BIGINT` | `Long` | 是 | - | FK->platform_users | 更新人平台用户 ID。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |
| `updated_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 更新时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

### platform_ip_whitelists（平台 IP 白名单）

- **建议实体名**：`PlatformIpWhitelist`
- **业务用途**：维护平台级或平台用户级的访问白名单。
- **主要关系**：`subject_id` -> `platform_users`；`created_by` -> `platform_users`
- **表级约束**：`CHECK ((subject_type = 'platform' AND subject_id IS NULL) OR (subject_type = 'user' AND subject_id IS NOT NULL))`
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `subject_type` | `VARCHAR(32)` | `String` | 否 | - | NOT NULL / CHECK(subject_type IN ('platform', 'user')) | 类型字段，建议生成枚举。 |
| `subject_id` | `BIGINT` | `Long` | 是 | - | FK->platform_users | 关联 `platform_users` 表主键。 |
| `ip_address` | `VARCHAR(64)` | `String` | 否 | - | NOT NULL | 业务字段。 |
| `ip_cidr` | `VARCHAR(64)` | `String` | 是 | - | - | 业务字段。 |
| `description` | `TEXT` | `String` | 是 | - | - | 描述说明。 |
| `status` | `VARCHAR(32)` | `String` | 否 | 'active' | NOT NULL / CHECK(status IN ('active', 'disabled')) | 业务状态字段。应根据 CHECK 约束生成枚举。 |
| `effective_from` | `TIMESTAMP` | `LocalDateTime` | 是 | - | - | 业务字段。 |
| `effective_to` | `TIMESTAMP` | `LocalDateTime` | 是 | - | - | 业务字段。 |
| `created_by` | `BIGINT` | `Long` | 是 | - | FK->platform_users | 创建人平台用户 ID。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

### platform_mfa_settings（平台 MFA 配置）

- **建议实体名**：`PlatformMfaSetting`
- **业务用途**：保存平台用户的多因素认证配置和验证状态。
- **主要关系**：`user_id` -> `platform_users`
- **表级约束**：无额外表级约束。
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `user_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->platform_users | 关联 `platform_users` 表主键。 |
| `provider_type` | `VARCHAR(32)` | `String` | 否 | - | NOT NULL / CHECK(provider_type IN ('totp', 'sms', 'email', 'app')) | 类型字段，建议生成枚举。 |
| `secret_ciphertext` | `TEXT` | `String` | 是 | - | - | 业务字段。 |
| `phone` | `VARCHAR(32)` | `String` | 是 | - | - | 业务字段。 |
| `email` | `VARCHAR(128)` | `String` | 是 | - | - | 业务字段。 |
| `is_primary` | `BOOLEAN` | `Boolean` | 否 | FALSE | NOT NULL | 布尔标记字段。 |
| `status` | `VARCHAR(32)` | `String` | 否 | 'active' | NOT NULL / CHECK(status IN ('pending', 'active', 'disabled')) | 业务状态字段。应根据 CHECK 约束生成枚举。 |
| `verified_at` | `TIMESTAMP` | `LocalDateTime` | 是 | - | - | 时间字段。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |
| `updated_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 更新时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

### platform_login_logs（平台登录日志）

- **建议实体名**：`PlatformLoginLog`
- **业务用途**：记录平台管理员登录结果、来源 IP、UA 和失败原因。
- **主要关系**：`user_id` -> `platform_users`
- **表级约束**：无额外表级约束。
- **索引说明**：`idx_platform_login_logs_user_time`(普通，字段：user_id, occurred_at DESC`)

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `user_id` | `BIGINT` | `Long` | 是 | - | FK->platform_users | 关联 `platform_users` 表主键。 |
| `username` | `VARCHAR(64)` | `String` | 是 | - | - | 业务字段。 |
| `login_type` | `VARCHAR(32)` | `String` | 否 | 'password' | NOT NULL / CHECK(login_type IN ('password', 'mfa', 'api', 'sso')) | 类型字段，建议生成枚举。 |
| `login_status` | `VARCHAR(32)` | `String` | 否 | - | NOT NULL / CHECK(login_status IN ('success', 'failed', 'locked', 'disabled')) | 状态字段，建议生成枚举。 |
| `ip_address` | `VARCHAR(64)` | `String` | 是 | - | - | 业务字段。 |
| `user_agent` | `TEXT` | `String` | 是 | - | - | 业务字段。 |
| `failure_reason` | `TEXT` | `String` | 是 | - | - | 业务字段。 |
| `occurred_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 时间字段。 |

## 模块：2. 租户生命周期体系

### tenants（租户主表）

- **建议实体名**：`Tenant`
- **业务用途**：租户核心主数据表，承载租户身份、状态、隔离模式、联系信息和当前套餐/订阅指针。
- **主要关系**：`group_id` -> `tenant_groups`；`created_by` -> `platform_users`；`current_plan_id` 后置外键指向 `saas_package_versions.id`。；`current_subscription_id` 后置外键指向 `tenant_subscriptions.id`。；之所以后置，是因为 `tenants` 与订阅/套餐存在循环引用，实体生成时这两个字段应保留为可空 Long 引用。
- **表级约束**：无额外表级约束。
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `tenant_code` | `VARCHAR(64)` | `String` | 否 | - | UNIQUE / NOT NULL | 租户唯一编码，建议同时作为业务检索键。 |
| `tenant_name` | `VARCHAR(128)` | `String` | 否 | - | NOT NULL | 租户名称。 |
| `enterprise_name` | `VARCHAR(255)` | `String` | 是 | - | - | 企业主体名称。 |
| `contact_name` | `VARCHAR(128)` | `String` | 是 | - | - | 租户联系人。 |
| `contact_phone` | `VARCHAR(32)` | `String` | 是 | - | - | 联系人手机号。 |
| `contact_email` | `VARCHAR(128)` | `String` | 是 | - | - | 联系人邮箱。 |
| `source_type` | `VARCHAR(32)` | `String` | 否 | 'admin' | NOT NULL / CHECK(source_type IN ('self_service', 'admin', 'api')) | 租户来源：自助注册、管理员创建、API 创建。 |
| `lifecycle_status` | `VARCHAR(32)` | `String` | 否 | 'trial' | NOT NULL / CHECK(lifecycle_status IN ('trial', 'active', 'expiring', 'expired', 'suspended', 'closed', 'deleted')) | 租户生命周期状态。应生成枚举。 |
| `current_plan_id` | `BIGINT` | `Long` | 是 | - | - | 当前生效套餐版本 ID。 |
| `current_subscription_id` | `BIGINT` | `Long` | 是 | - | - | 当前生效订阅记录 ID。 |
| `group_id` | `BIGINT` | `Long` | 是 | - | FK->tenant_groups | 所属租户分组 ID。 |
| `industry_tag` | `VARCHAR(64)` | `String` | 是 | - | - | 行业标签快照值。 |
| `customer_level` | `VARCHAR(64)` | `String` | 是 | - | - | 客户级别快照值。 |
| `customer_source` | `VARCHAR(64)` | `String` | 是 | - | - | 客户来源快照值。 |
| `default_language` | `VARCHAR(32)` | `String` | 否 | 'zh-CN' | NOT NULL | 默认语言，例如 zh-CN。 |
| `default_timezone` | `VARCHAR(64)` | `String` | 否 | 'Asia/Shanghai' | NOT NULL | 默认时区，例如 Asia/Shanghai。 |
| `isolation_mode` | `VARCHAR(32)` | `String` | 否 | 'shared_database' | NOT NULL / CHECK(isolation_mode IN ('shared_database', 'schema_isolated', 'database_isolated', 'hybrid')) | 多租户隔离模式。应生成枚举。 |
| `database_name` | `VARCHAR(128)` | `String` | 是 | - | - | 数据库隔离模式下的数据库名。 |
| `schema_name` | `VARCHAR(128)` | `String` | 是 | - | - | Schema 隔离模式下的 schema 名。 |
| `default_domain` | `VARCHAR(255)` | `String` | 是 | - | - | 租户默认访问域名。 |
| `enabled` | `BOOLEAN` | `Boolean` | 否 | TRUE | NOT NULL | 启用标记。建议实体类型使用 Boolean。 |
| `opened_at` | `TIMESTAMP` | `LocalDateTime` | 是 | - | - | 开通时间。 |
| `activated_at` | `TIMESTAMP` | `LocalDateTime` | 是 | - | - | 启用时间。 |
| `expires_at` | `TIMESTAMP` | `LocalDateTime` | 是 | - | - | 到期时间。 |
| `suspended_at` | `TIMESTAMP` | `LocalDateTime` | 是 | - | - | 暂停时间。 |
| `closed_at` | `TIMESTAMP` | `LocalDateTime` | 是 | - | - | 关闭时间。 |
| `deleted_at` | `TIMESTAMP` | `LocalDateTime` | 是 | - | - | 软删除时间；为空表示未删除。 |
| `created_by` | `BIGINT` | `Long` | 是 | - | FK->platform_users | 创建人平台用户 ID。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |
| `updated_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 更新时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

### tenant_initialization_tasks（租户初始化任务）

- **建议实体名**：`TenantInitializationTask`
- **业务用途**：记录租户初始化数据库、配置、套餐和资源等异步任务。
- **主要关系**：`tenant_id` -> `tenants`
- **表级约束**：无额外表级约束。
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `tenant_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->tenants | 关联 `tenants` 表主键。 |
| `task_type` | `VARCHAR(32)` | `String` | 否 | - | NOT NULL / CHECK(task_type IN ('database', 'config', 'plan', 'resource')) | 类型字段，建议生成枚举。 |
| `task_status` | `VARCHAR(32)` | `String` | 否 | 'pending' | NOT NULL / CHECK(task_status IN ('pending', 'running', 'success', 'failed')) | 状态字段，建议生成枚举。 |
| `details` | `JSONB` | `JsonNode/Map<String,Object>` | 是 | - | - | 业务字段。 |
| `started_at` | `TIMESTAMP` | `LocalDateTime` | 是 | - | - | 时间字段。 |
| `finished_at` | `TIMESTAMP` | `LocalDateTime` | 是 | - | - | 时间字段。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

### tenant_lifecycle_events（租户生命周期事件）

- **建议实体名**：`TenantLifecycleEvent`
- **业务用途**：记录租户开通、启用、暂停、恢复、关闭和删除等状态迁移事件。
- **主要关系**：`tenant_id` -> `tenants`；`operator_id` -> `platform_users`
- **表级约束**：无额外表级约束。
- **索引说明**：`idx_tenant_lifecycle_events_tenant_time`(普通，字段：tenant_id, occurred_at DESC`)

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `tenant_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->tenants | 关联 `tenants` 表主键。 |
| `event_type` | `VARCHAR(32)` | `String` | 否 | - | NOT NULL / CHECK(event_type IN ('register', 'open', 'enable', 'suspend', 'resume', 'close', 'delete', 'expire')) | 类型字段，建议生成枚举。 |
| `from_status` | `VARCHAR(32)` | `String` | 是 | - | - | 状态字段，建议生成枚举。 |
| `to_status` | `VARCHAR(32)` | `String` | 是 | - | - | 状态字段，建议生成枚举。 |
| `reason` | `TEXT` | `String` | 是 | - | - | 业务字段。 |
| `operator_id` | `BIGINT` | `Long` | 是 | - | FK->platform_users | 关联 `platform_users` 表主键。 |
| `metadata` | `JSONB` | `JsonNode/Map<String,Object>` | 是 | - | - | 附加元数据。 |
| `occurred_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 时间字段。 |

### tenant_data_jobs（租户数据任务）

- **建议实体名**：`TenantDataJob`
- **业务用途**：记录租户数据归档、备份、迁移、清理等后台作业。
- **主要关系**：`tenant_id` -> `tenants`；`created_by` -> `platform_users`
- **表级约束**：无额外表级约束。
- **索引说明**：`idx_tenant_data_jobs_tenant_type`(普通，字段：tenant_id, job_type`)

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `tenant_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->tenants | 关联 `tenants` 表主键。 |
| `job_type` | `VARCHAR(32)` | `String` | 否 | - | NOT NULL / CHECK(job_type IN ('archive', 'backup', 'migration', 'cleanup')) | 类型字段，建议生成枚举。 |
| `job_status` | `VARCHAR(32)` | `String` | 否 | 'pending' | NOT NULL / CHECK(job_status IN ('pending', 'running', 'success', 'failed')) | 状态字段，建议生成枚举。 |
| `storage_path` | `VARCHAR(255)` | `String` | 是 | - | - | 路径信息。 |
| `payload` | `JSONB` | `JsonNode/Map<String,Object>` | 是 | - | - | 任务或事件的 JSON 载荷。 |
| `started_at` | `TIMESTAMP` | `LocalDateTime` | 是 | - | - | 时间字段。 |
| `finished_at` | `TIMESTAMP` | `LocalDateTime` | 是 | - | - | 时间字段。 |
| `created_by` | `BIGINT` | `Long` | 是 | - | FK->platform_users | 创建人平台用户 ID。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

## 模块：3. 租户信息体系

### tenant_groups（租户分组）

- **建议实体名**：`TenantGroup`
- **业务用途**：定义租户分组，用于分类管理、归类统计和分层运营。
- **主要关系**：`parent_id` -> `tenant_groups`；`created_by` -> `platform_users`
- **表级约束**：无额外表级约束。
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `group_code` | `VARCHAR(64)` | `String` | 否 | - | UNIQUE / NOT NULL | 业务编码。 |
| `group_name` | `VARCHAR(128)` | `String` | 否 | - | NOT NULL | 名称。 |
| `description` | `TEXT` | `String` | 是 | - | - | 描述说明。 |
| `parent_id` | `BIGINT` | `Long` | 是 | - | FK->tenant_groups | 关联 `tenant_groups` 表主键。 |
| `created_by` | `BIGINT` | `Long` | 是 | - | FK->platform_users | 创建人平台用户 ID。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |
| `updated_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 更新时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

### tenant_domains（租户域名）

- **建议实体名**：`TenantDomain`
- **业务用途**：维护租户默认域名、子域名、自定义域名以及域名验证状态。
- **主要关系**：`tenant_id` -> `tenants`
- **表级约束**：`UNIQUE (domain)`；`UNIQUE (tenant_id, domain)`
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `tenant_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->tenants | 关联 `tenants` 表主键。 |
| `domain` | `VARCHAR(255)` | `String` | 否 | - | NOT NULL | 租户域名。 |
| `domain_type` | `VARCHAR(32)` | `String` | 否 | - | NOT NULL / CHECK(domain_type IN ('default', 'subdomain', 'custom')) | 域名类型：默认域名/子域名/自定义域名。 |
| `is_primary` | `BOOLEAN` | `Boolean` | 否 | FALSE | NOT NULL | 是否主域名。 |
| `verification_status` | `VARCHAR(32)` | `String` | 否 | 'pending' | NOT NULL / CHECK(verification_status IN ('pending', 'verified', 'failed')) | 域名验证状态。 |
| `verification_token` | `VARCHAR(128)` | `String` | 是 | - | - | 域名验证令牌。 |
| `verified_at` | `TIMESTAMP` | `LocalDateTime` | 是 | - | - | 域名验证通过时间。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

### tenant_tags（租户标签）

- **建议实体名**：`TenantTag`
- **业务用途**：定义行业、客户等级、客户来源等可复用标签。
- **主要关系**：无直接外键，主要作为独立主档或日志表使用。
- **表级约束**：`UNIQUE (tag_key, tag_value)`
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `tag_key` | `VARCHAR(64)` | `String` | 否 | - | NOT NULL | 业务字段。 |
| `tag_value` | `VARCHAR(128)` | `String` | 否 | - | NOT NULL | 值字段。 |
| `tag_type` | `VARCHAR(32)` | `String` | 否 | - | NOT NULL / CHECK(tag_type IN ('industry', 'customer_level', 'customer_source', 'custom')) | 类型字段，建议生成枚举。 |
| `description` | `TEXT` | `String` | 是 | - | - | 描述说明。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

### tenant_tag_bindings（租户标签绑定）

- **建议实体名**：`TenantTagBinding`
- **业务用途**：维护租户与标签的多对多关系。
- **主要关系**：`tenant_id` -> `tenants`；`tag_id` -> `tenant_tags`
- **表级约束**：`UNIQUE (tenant_id, tag_id)`
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `tenant_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->tenants | 关联 `tenants` 表主键。 |
| `tag_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->tenant_tags | 关联 `tenant_tags` 表主键。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

### tenant_group_members（租户分组成员）

- **建议实体名**：`TenantGroupMember`
- **业务用途**：维护租户与分组的归类关系。
- **主要关系**：`group_id` -> `tenant_groups`；`tenant_id` -> `tenants`
- **表级约束**：`UNIQUE (group_id, tenant_id)`
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `group_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->tenant_groups | 关联 `tenant_groups` 表主键。 |
| `tenant_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->tenants | 关联 `tenants` 表主键。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

## 模块：4. 租户资源管理

### tenant_resource_quotas（租户资源配额）

- **建议实体名**：`TenantResourceQuota`
- **业务用途**：定义用户数、API 调用、并发、存储、数据库容量、文件数量等资源配额。
- **主要关系**：`tenant_id` -> `tenants`
- **表级约束**：`UNIQUE (tenant_id, quota_type)`
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `tenant_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->tenants | 关联 `tenants` 表主键。 |
| `quota_type` | `VARCHAR(32)` | `String` | 否 | - | NOT NULL / CHECK(quota_type IN ('user_count', 'api_calls', 'concurrent_requests', 'storage_size', 'database_size', 'file_count')) | 配额类型。应生成枚举。 |
| `quota_limit` | `BIGINT` | `Long` | 否 | - | NOT NULL | 配额上限值。 |
| `warning_threshold` | `BIGINT` | `Long` | 是 | - | - | 预警阈值。 |
| `reset_cycle` | `VARCHAR(32) CHECK (reset_cycle IN ('none', 'hourly', 'daily', 'weekly', 'monthly', 'yearly'))` | `String` | 是 | - | CHECK(reset_cycle IN ('none', 'hourly', 'daily', 'weekly', 'monthly', 'yearly')) | 配额重置周期。 |
| `effective_from` | `TIMESTAMP` | `LocalDateTime` | 是 | - | - | 业务字段。 |
| `effective_to` | `TIMESTAMP` | `LocalDateTime` | 是 | - | - | 业务字段。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |
| `updated_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 更新时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

### tenant_resource_usage_stats（租户资源使用统计）

- **建议实体名**：`TenantResourceUsageStat`
- **业务用途**：按天统计租户资源实际使用量，用于配额判断和运营分析。
- **主要关系**：`tenant_id` -> `tenants`
- **表级约束**：`UNIQUE (tenant_id, metric_date)`
- **索引说明**：`idx_usage_stats_tenant_date`(普通，字段：tenant_id, metric_date DESC`)

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `tenant_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->tenants | 关联 `tenants` 表主键。 |
| `metric_date` | `DATE` | `LocalDate` | 否 | - | NOT NULL | 统计日期。建议实体类型使用 LocalDate。 |
| `user_count` | `INTEGER` | `Integer` | 否 | 0 | NOT NULL | 数量统计字段。 |
| `api_call_count` | `BIGINT` | `Long` | 否 | 0 | NOT NULL | 数量统计字段。 |
| `concurrent_request_peak` | `INTEGER` | `Integer` | 否 | 0 | NOT NULL | 业务字段。 |
| `storage_bytes` | `BIGINT` | `Long` | 否 | 0 | NOT NULL | 字节数。 |
| `database_bytes` | `BIGINT` | `Long` | 否 | 0 | NOT NULL | 字节数。 |
| `file_count` | `BIGINT` | `Long` | 否 | 0 | NOT NULL | 数量统计字段。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

## 模块：5. 租户配置中心

### tenant_system_configs（租户系统配置）

- **建议实体名**：`TenantSystemConfig`
- **业务用途**：维护租户系统名称、Logo、主题、语言、时区等基础系统配置。
- **主要关系**：`tenant_id` -> `tenants`
- **表级约束**：`UNIQUE (tenant_id)`
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `tenant_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->tenants | 关联 `tenants` 表主键。 |
| `system_name` | `VARCHAR(128)` | `String` | 是 | - | - | 名称。 |
| `logo_url` | `VARCHAR(255)` | `String` | 是 | - | - | URL 地址。 |
| `system_theme` | `VARCHAR(64)` | `String` | 是 | - | - | 业务字段。 |
| `default_language` | `VARCHAR(32)` | `String` | 是 | - | - | 业务字段。 |
| `default_timezone` | `VARCHAR(64)` | `String` | 是 | - | - | 业务字段。 |
| `extra_config` | `JSONB` | `JsonNode/Map<String,Object>` | 是 | - | - | 扩展 JSON 配置。建议实体中映射为 JsonNode、Map<String,Object> 或自定义值对象。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |
| `updated_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 更新时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

### tenant_feature_flags（租户功能开关）

- **建议实体名**：`TenantFeatureFlag`
- **业务用途**：维护租户功能启停和灰度开关配置。
- **主要关系**：`tenant_id` -> `tenants`
- **表级约束**：`UNIQUE (tenant_id, feature_key)`
- **索引说明**：`idx_feature_flags_tenant_enabled`(普通，字段：tenant_id, enabled`)

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `tenant_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->tenants | 关联 `tenants` 表主键。 |
| `feature_key` | `VARCHAR(128)` | `String` | 否 | - | NOT NULL | 功能标识 Key。 |
| `feature_name` | `VARCHAR(128)` | `String` | 否 | - | NOT NULL | 功能名称。 |
| `enabled` | `BOOLEAN` | `Boolean` | 否 | FALSE | NOT NULL | 启用标记。建议实体类型使用 Boolean。 |
| `rollout_type` | `VARCHAR(32)` | `String` | 否 | 'full' | NOT NULL / CHECK(rollout_type IN ('full', 'closed', 'gray')) | 发布策略：全量、关闭、灰度。 |
| `rollout_config` | `JSONB` | `JsonNode/Map<String,Object>` | 是 | - | - | 灰度配置 JSON。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |
| `updated_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 更新时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

### tenant_parameters（租户参数配置）

- **建议实体名**：`TenantParameter`
- **业务用途**：维护系统参数、扩展参数和自定义参数。
- **主要关系**：`tenant_id` -> `tenants`
- **表级约束**：`UNIQUE (tenant_id, param_key)`
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `tenant_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->tenants | 关联 `tenants` 表主键。 |
| `param_key` | `VARCHAR(128)` | `String` | 否 | - | NOT NULL | 参数键。 |
| `param_name` | `VARCHAR(128)` | `String` | 否 | - | NOT NULL | 参数名称。 |
| `param_type` | `VARCHAR(32)` | `String` | 否 | - | NOT NULL / CHECK(param_type IN ('system', 'extension', 'custom')) | 参数类型：系统/扩展/自定义。 |
| `param_value` | `JSONB` | `JsonNode/Map<String,Object>` | 否 | - | NOT NULL | 参数值 JSON。 |
| `is_encrypted` | `BOOLEAN` | `Boolean` | 否 | FALSE | NOT NULL | 是否加密存储。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |
| `updated_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 更新时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

### tenant_ui_brandings（租户品牌配置）

- **建议实体名**：`TenantUiBranding`
- **业务用途**：维护品牌名称、登录页配置和 UI 主题等品牌化参数。
- **主要关系**：`tenant_id` -> `tenants`
- **表级约束**：`UNIQUE (tenant_id)`
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `tenant_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->tenants | 关联 `tenants` 表主键。 |
| `brand_name` | `VARCHAR(128)` | `String` | 是 | - | - | 名称。 |
| `login_page_config` | `JSONB` | `JsonNode/Map<String,Object>` | 是 | - | - | 配置 JSON。 |
| `ui_theme` | `JSONB` | `JsonNode/Map<String,Object>` | 是 | - | - | 业务字段。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |
| `updated_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 更新时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

## 模块：6. SaaS套餐系统

### saas_packages（SaaS 套餐）

- **建议实体名**：`SaasPackage`
- **业务用途**：定义 SaaS 套餐主档。
- **主要关系**：`created_by` -> `platform_users`；`updated_by` -> `platform_users`
- **表级约束**：无额外表级约束。
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `package_code` | `VARCHAR(64)` | `String` | 否 | - | UNIQUE / NOT NULL | 业务编码。 |
| `package_name` | `VARCHAR(128)` | `String` | 否 | - | NOT NULL | 名称。 |
| `description` | `TEXT` | `String` | 是 | - | - | 描述说明。 |
| `status` | `VARCHAR(32)` | `String` | 否 | 'active' | NOT NULL / CHECK(status IN ('active', 'disabled', 'deleted')) | 业务状态字段。应根据 CHECK 约束生成枚举。 |
| `created_by` | `BIGINT` | `Long` | 是 | - | FK->platform_users | 创建人平台用户 ID。 |
| `updated_by` | `BIGINT` | `Long` | 是 | - | FK->platform_users | 更新人平台用户 ID。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |
| `updated_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 更新时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

### saas_package_versions（SaaS 套餐版本）

- **建议实体名**：`SaasPackageVersion`
- **业务用途**：定义套餐版本、版本类型、价格、试用天数和计费周期。
- **主要关系**：`package_id` -> `saas_packages`
- **表级约束**：`UNIQUE (package_id, version_code)`
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `package_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->saas_packages | 关联 `saas_packages` 表主键。 |
| `version_code` | `VARCHAR(64)` | `String` | 否 | - | NOT NULL | 套餐版本编码。 |
| `version_name` | `VARCHAR(128)` | `String` | 否 | - | NOT NULL | 套餐版本名称。 |
| `edition_type` | `VARCHAR(32)` | `String` | 否 | - | NOT NULL / CHECK(edition_type IN ('free', 'standard', 'professional', 'enterprise')) | 版本类型：免费/标准/专业/企业。 |
| `billing_cycle` | `VARCHAR(32)` | `String` | 否 | 'monthly' | NOT NULL / CHECK(billing_cycle IN ('monthly', 'quarterly', 'yearly', 'one_time')) | 计费周期。 |
| `price` | `DECIMAL(18, 2)` | `BigDecimal` | 否 | 0 | NOT NULL | 套餐价格。建议实体类型使用 BigDecimal。 |
| `currency_code` | `VARCHAR(16)` | `String` | 否 | 'CNY' | NOT NULL | 币种编码。 |
| `trial_days` | `INTEGER` | `Integer` | 否 | 0 | NOT NULL | 试用天数。 |
| `is_default` | `BOOLEAN` | `Boolean` | 否 | FALSE | NOT NULL | 布尔标记字段。 |
| `enabled` | `BOOLEAN` | `Boolean` | 否 | TRUE | NOT NULL | 启用标记。建议实体类型使用 Boolean。 |
| `effective_from` | `TIMESTAMP` | `LocalDateTime` | 是 | - | - | 业务字段。 |
| `effective_to` | `TIMESTAMP` | `LocalDateTime` | 是 | - | - | 业务字段。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |
| `updated_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 更新时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

### saas_package_capabilities（套餐能力配置）

- **建议实体名**：`SaasPackageCapability`
- **业务用途**：定义套餐版本对应的功能模块、用户限制、存储限制、API 限制和并发限制。
- **主要关系**：`package_version_id` -> `saas_package_versions`
- **表级约束**：`UNIQUE (package_version_id, capability_key)`
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `package_version_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->saas_package_versions | 关联 `saas_package_versions` 表主键。 |
| `capability_key` | `VARCHAR(128)` | `String` | 否 | - | NOT NULL | 业务字段。 |
| `capability_name` | `VARCHAR(128)` | `String` | 否 | - | NOT NULL | 名称。 |
| `capability_type` | `VARCHAR(32)` | `String` | 否 | - | NOT NULL / CHECK(capability_type IN ('feature', 'user_limit', 'storage_limit', 'api_limit', 'concurrency_limit', 'custom')) | 类型字段，建议生成枚举。 |
| `capability_value` | `JSONB` | `JsonNode/Map<String,Object>` | 否 | - | NOT NULL | 值字段。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |
| `updated_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 更新时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

## 模块：7. 订阅系统

### tenant_subscriptions（租户订阅）

- **建议实体名**：`TenantSubscription`
- **业务用途**：维护租户当前或历史套餐订阅记录。
- **主要关系**：`tenant_id` -> `tenants`；`package_version_id` -> `saas_package_versions`；`created_by` -> `platform_users`
- **表级约束**：无额外表级约束。
- **索引说明**：`idx_subscriptions_tenant_status`(普通，字段：tenant_id, subscription_status`)

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `tenant_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->tenants | 关联 `tenants` 表主键。 |
| `package_version_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->saas_package_versions | 关联 `saas_package_versions` 表主键。 |
| `subscription_status` | `VARCHAR(32)` | `String` | 否 | - | NOT NULL / CHECK(subscription_status IN ('active', 'expiring', 'expired', 'suspended', 'cancelled')) | 订阅状态。应生成枚举。 |
| `subscription_type` | `VARCHAR(32)` | `String` | 否 | 'formal' | NOT NULL / CHECK(subscription_type IN ('trial', 'formal')) | 订阅类型：试用/正式。 |
| `started_at` | `TIMESTAMP` | `LocalDateTime` | 否 | - | NOT NULL | 订阅开始时间。 |
| `expires_at` | `TIMESTAMP` | `LocalDateTime` | 否 | - | NOT NULL | 订阅结束时间。 |
| `auto_renew` | `BOOLEAN` | `Boolean` | 否 | FALSE | NOT NULL | 是否自动续费。 |
| `cancelled_at` | `TIMESTAMP` | `LocalDateTime` | 是 | - | - | 时间字段。 |
| `created_by` | `BIGINT` | `Long` | 是 | - | FK->platform_users | 创建人平台用户 ID。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |
| `updated_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 更新时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

### tenant_trials（租户试用记录）

- **建议实体名**：`TenantTrial`
- **业务用途**：维护试用开通、试用周期和转正式记录。
- **主要关系**：`tenant_id` -> `tenants`；`package_version_id` -> `saas_package_versions`；`converted_subscription_id` -> `tenant_subscriptions`
- **表级约束**：`UNIQUE (tenant_id, started_at)`
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `tenant_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->tenants | 关联 `tenants` 表主键。 |
| `package_version_id` | `BIGINT` | `Long` | 是 | - | FK->saas_package_versions | 关联 `saas_package_versions` 表主键。 |
| `started_at` | `TIMESTAMP` | `LocalDateTime` | 否 | - | NOT NULL | 时间字段。 |
| `expires_at` | `TIMESTAMP` | `LocalDateTime` | 否 | - | NOT NULL | 时间字段。 |
| `converted_subscription_id` | `BIGINT` | `Long` | 是 | - | FK->tenant_subscriptions | 关联 `tenant_subscriptions` 表主键。 |
| `status` | `VARCHAR(32)` | `String` | 否 | 'active' | NOT NULL / CHECK(status IN ('active', 'expired', 'converted', 'cancelled')) | 业务状态字段。应根据 CHECK 约束生成枚举。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |
| `updated_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 更新时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

### tenant_subscription_changes（订阅变更记录）

- **建议实体名**：`TenantSubscriptionChange`
- **业务用途**：记录订阅开通、升级、降级、续费、取消、试用转正式等动作。
- **主要关系**：`tenant_id` -> `tenants`；`subscription_id` -> `tenant_subscriptions`；`from_package_version_id` -> `saas_package_versions`；`to_package_version_id` -> `saas_package_versions`；`created_by` -> `platform_users`
- **表级约束**：无额外表级约束。
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `tenant_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->tenants | 关联 `tenants` 表主键。 |
| `subscription_id` | `BIGINT` | `Long` | 是 | - | FK->tenant_subscriptions | 关联 `tenant_subscriptions` 表主键。 |
| `change_type` | `VARCHAR(32)` | `String` | 否 | - | NOT NULL / CHECK(change_type IN ('subscribe', 'upgrade', 'downgrade', 'renew', 'cancel', 'trial_to_formal')) | 类型字段，建议生成枚举。 |
| `from_package_version_id` | `BIGINT` | `Long` | 是 | - | FK->saas_package_versions | 关联 `saas_package_versions` 表主键。 |
| `to_package_version_id` | `BIGINT` | `Long` | 是 | - | FK->saas_package_versions | 关联 `saas_package_versions` 表主键。 |
| `effective_at` | `TIMESTAMP` | `LocalDateTime` | 否 | - | NOT NULL | 时间字段。 |
| `remark` | `TEXT` | `String` | 是 | - | - | 备注信息。 |
| `created_by` | `BIGINT` | `Long` | 是 | - | FK->platform_users | 创建人平台用户 ID。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

## 模块：8. 计费与账单系统

### billing_invoices（账单）

- **建议实体名**：`BillingInvoice`
- **业务用途**：维护租户账单主单据和计费区间。
- **主要关系**：`tenant_id` -> `tenants`；`subscription_id` -> `tenant_subscriptions`
- **表级约束**：无额外表级约束。
- **索引说明**：`idx_invoices_tenant_status`(普通，字段：tenant_id, invoice_status`)

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `invoice_no` | `VARCHAR(64)` | `String` | 否 | - | UNIQUE / NOT NULL | 账单编号。 |
| `tenant_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->tenants | 关联 `tenants` 表主键。 |
| `subscription_id` | `BIGINT` | `Long` | 是 | - | FK->tenant_subscriptions | 关联 `tenant_subscriptions` 表主键。 |
| `invoice_status` | `VARCHAR(32)` | `String` | 否 | - | NOT NULL / CHECK(invoice_status IN ('pending', 'issued', 'paid', 'overdue', 'cancelled')) | 账单状态。 |
| `billing_period_start` | `TIMESTAMP` | `LocalDateTime` | 否 | - | NOT NULL | 账单周期开始时间。 |
| `billing_period_end` | `TIMESTAMP` | `LocalDateTime` | 否 | - | NOT NULL | 账单周期结束时间。 |
| `subtotal_amount` | `DECIMAL(18, 2)` | `BigDecimal` | 否 | 0 | NOT NULL | 基础费用小计。 |
| `extra_amount` | `DECIMAL(18, 2)` | `BigDecimal` | 否 | 0 | NOT NULL | 附加费用。 |
| `discount_amount` | `DECIMAL(18, 2)` | `BigDecimal` | 否 | 0 | NOT NULL | 优惠金额。 |
| `total_amount` | `DECIMAL(18, 2)` | `BigDecimal` | 否 | 0 | NOT NULL | 账单总金额。 |
| `currency_code` | `VARCHAR(16)` | `String` | 否 | 'CNY' | NOT NULL | 业务编码。 |
| `issued_at` | `TIMESTAMP` | `LocalDateTime` | 是 | - | - | 时间字段。 |
| `due_at` | `TIMESTAMP` | `LocalDateTime` | 是 | - | - | 时间字段。 |
| `paid_at` | `TIMESTAMP` | `LocalDateTime` | 是 | - | - | 时间字段。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |
| `updated_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 更新时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

### billing_invoice_items（账单明细）

- **建议实体名**：`BillingInvoiceItem`
- **业务用途**：维护账单中的套餐费用、按量费用和附加费用明细。
- **主要关系**：`invoice_id` -> `billing_invoices`
- **表级约束**：无额外表级约束。
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `invoice_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->billing_invoices | 关联 `billing_invoices` 表主键。 |
| `item_type` | `VARCHAR(32)` | `String` | 否 | - | NOT NULL / CHECK(item_type IN ('package_fee', 'usage_fee', 'extra_fee')) | 类型字段，建议生成枚举。 |
| `item_name` | `VARCHAR(128)` | `String` | 否 | - | NOT NULL | 名称。 |
| `quantity` | `DECIMAL(18, 4)` | `BigDecimal` | 否 | 1 | NOT NULL | 业务字段。 |
| `unit_price` | `DECIMAL(18, 4)` | `BigDecimal` | 否 | 0 | NOT NULL | 业务字段。 |
| `amount` | `DECIMAL(18, 2)` | `BigDecimal` | 否 | 0 | NOT NULL | 业务字段。 |
| `item_metadata` | `JSONB` | `JsonNode/Map<String,Object>` | 是 | - | - | 业务字段。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

### payment_orders（支付订单）

- **建议实体名**：`PaymentOrder`
- **业务用途**：维护账单对应的支付订单和第三方交易状态。
- **主要关系**：`tenant_id` -> `tenants`；`invoice_id` -> `billing_invoices`
- **表级约束**：无额外表级约束。
- **索引说明**：`idx_payment_orders_tenant_status`(普通，字段：tenant_id, payment_status`)

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `order_no` | `VARCHAR(64)` | `String` | 否 | - | UNIQUE / NOT NULL | 支付订单号。 |
| `tenant_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->tenants | 关联 `tenants` 表主键。 |
| `invoice_id` | `BIGINT` | `Long` | 是 | - | FK->billing_invoices | 关联 `billing_invoices` 表主键。 |
| `payment_channel` | `VARCHAR(32)` | `String` | 否 | - | NOT NULL / CHECK(payment_channel IN ('alipay', 'wechat', 'bank_transfer', 'offline', 'other')) | 支付渠道。 |
| `payment_status` | `VARCHAR(32)` | `String` | 否 | - | NOT NULL / CHECK(payment_status IN ('pending', 'paid', 'failed', 'cancelled', 'refunded', 'partial_refunded')) | 支付状态。 |
| `amount` | `DECIMAL(18, 2)` | `BigDecimal` | 否 | - | NOT NULL | 支付金额。 |
| `currency_code` | `VARCHAR(16)` | `String` | 否 | 'CNY' | NOT NULL | 业务编码。 |
| `third_party_txn_no` | `VARCHAR(128)` | `String` | 是 | - | - | 第三方交易流水号。 |
| `paid_at` | `TIMESTAMP` | `LocalDateTime` | 是 | - | - | 时间字段。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |
| `updated_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 更新时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

### payment_refunds（退款记录）

- **建议实体名**：`PaymentRefund`
- **业务用途**：维护支付订单退款记录。
- **主要关系**：`payment_order_id` -> `payment_orders`
- **表级约束**：无额外表级约束。
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `refund_no` | `VARCHAR(64)` | `String` | 否 | - | UNIQUE / NOT NULL | 退款单号。 |
| `payment_order_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->payment_orders | 关联 `payment_orders` 表主键。 |
| `refund_status` | `VARCHAR(32)` | `String` | 否 | - | NOT NULL / CHECK(refund_status IN ('pending', 'success', 'failed', 'cancelled')) | 退款状态。 |
| `refund_amount` | `DECIMAL(18, 2)` | `BigDecimal` | 否 | - | NOT NULL | 退款金额。 |
| `refund_reason` | `TEXT` | `String` | 是 | - | - | 业务字段。 |
| `refunded_at` | `TIMESTAMP` | `LocalDateTime` | 是 | - | - | 时间字段。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |
| `updated_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 更新时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

## 模块：9. API与集成平台

### tenant_api_keys（租户 API Key）

- **建议实体名**：`TenantApiKey`
- **业务用途**：维护租户 API Key、密钥摘要、配额和状态。
- **主要关系**：`tenant_id` -> `tenants`；`created_by` -> `platform_users`
- **表级约束**：无额外表级约束。
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `tenant_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->tenants | 关联 `tenants` 表主键。 |
| `key_name` | `VARCHAR(128)` | `String` | 否 | - | NOT NULL | 名称。 |
| `access_key` | `VARCHAR(128)` | `String` | 否 | - | UNIQUE / NOT NULL | 公开访问 Key。 |
| `secret_hash` | `VARCHAR(255)` | `String` | 否 | - | NOT NULL | 密钥摘要，不保存明文密钥。 |
| `status` | `VARCHAR(32)` | `String` | 否 | 'active' | NOT NULL / CHECK(status IN ('active', 'disabled', 'deleted')) | 业务状态字段。应根据 CHECK 约束生成枚举。 |
| `quota_limit` | `BIGINT` | `Long` | 是 | - | - | Key 级别配额上限。 |
| `rate_limit` | `INTEGER` | `Integer` | 是 | - | - | Key 级别限流值。 |
| `last_used_at` | `TIMESTAMP` | `LocalDateTime` | 是 | - | - | 最近使用时间。 |
| `expires_at` | `TIMESTAMP` | `LocalDateTime` | 是 | - | - | Key 过期时间。 |
| `created_by` | `BIGINT` | `Long` | 是 | - | FK->platform_users | 创建人平台用户 ID。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |
| `updated_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 更新时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

### tenant_api_usage_stats（API 调用统计）

- **建议实体名**：`TenantApiUsageStat`
- **业务用途**：按天和接口维度统计 API 调用次数、成功数、失败数和延迟。
- **主要关系**：`tenant_id` -> `tenants`；`api_key_id` -> `tenant_api_keys`
- **表级约束**：无额外表级约束。
- **索引说明**：`idx_api_usage_tenant_date`(普通，字段：tenant_id, stat_date DESC`)；`uq_api_usage_stats_with_key`(唯一，字段：tenant_id, api_key_id, stat_date, api_path`，条件：api_key_id IS NOT NULL)；`uq_api_usage_stats_without_key`(唯一，字段：tenant_id, stat_date, api_path`，条件：api_key_id IS NULL)

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `tenant_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->tenants | 关联 `tenants` 表主键。 |
| `api_key_id` | `BIGINT` | `Long` | 是 | - | FK->tenant_api_keys | 关联 `tenant_api_keys` 表主键。 |
| `stat_date` | `DATE` | `LocalDate` | 否 | - | NOT NULL | 统计日期。建议实体类型使用 LocalDate。 |
| `api_path` | `VARCHAR(255)` | `String` | 否 | - | NOT NULL | 接口路径或业务 API 标识。 |
| `request_count` | `BIGINT` | `Long` | 否 | 0 | NOT NULL | 请求总次数。 |
| `success_count` | `BIGINT` | `Long` | 否 | 0 | NOT NULL | 成功次数。 |
| `error_count` | `BIGINT` | `Long` | 否 | 0 | NOT NULL | 失败次数。 |
| `average_latency_ms` | `INTEGER` | `Integer` | 否 | 0 | NOT NULL | 平均耗时（毫秒）。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

### webhook_events（Webhook 事件定义）

- **建议实体名**：`WebhookEvent`
- **业务用途**：定义系统支持推送的 Webhook 事件。
- **主要关系**：无直接外键，主要作为独立主档或日志表使用。
- **表级约束**：无额外表级约束。
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `event_code` | `VARCHAR(128)` | `String` | 否 | - | UNIQUE / NOT NULL | 业务编码。 |
| `event_name` | `VARCHAR(128)` | `String` | 否 | - | NOT NULL | 名称。 |
| `description` | `TEXT` | `String` | 是 | - | - | 描述说明。 |
| `payload_schema` | `JSONB` | `JsonNode/Map<String,Object>` | 是 | - | - | 业务字段。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

### tenant_webhooks（租户 Webhook）

- **建议实体名**：`TenantWebhook`
- **业务用途**：维护租户注册的 Webhook 地址、状态和重试策略。
- **主要关系**：`tenant_id` -> `tenants`
- **表级约束**：无额外表级约束。
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `tenant_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->tenants | 关联 `tenants` 表主键。 |
| `webhook_name` | `VARCHAR(128)` | `String` | 否 | - | NOT NULL | 名称。 |
| `target_url` | `VARCHAR(500)` | `String` | 否 | - | NOT NULL | Webhook 目标地址。 |
| `secret_token_hash` | `VARCHAR(255)` | `String` | 是 | - | - | Webhook 签名密钥摘要。 |
| `status` | `VARCHAR(32)` | `String` | 否 | 'active' | NOT NULL / CHECK(status IN ('active', 'disabled')) | 业务状态字段。应根据 CHECK 约束生成枚举。 |
| `retry_policy` | `JSONB` | `JsonNode/Map<String,Object>` | 是 | - | - | 重试策略 JSON。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |
| `updated_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 更新时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

### tenant_webhook_events（Webhook 事件订阅关系）

- **建议实体名**：`TenantWebhookEvent`
- **业务用途**：维护 Webhook 与事件的订阅绑定关系。
- **主要关系**：`webhook_id` -> `tenant_webhooks`；`event_id` -> `webhook_events`
- **表级约束**：`UNIQUE (webhook_id, event_id)`
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `webhook_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->tenant_webhooks | 关联 `tenant_webhooks` 表主键。 |
| `event_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->webhook_events | 关联 `webhook_events` 表主键。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

### webhook_delivery_logs（Webhook 推送日志）

- **建议实体名**：`WebhookDeliveryLog`
- **业务用途**：记录每次 Webhook 推送的请求体、响应码、响应体和重试次数。
- **主要关系**：`webhook_id` -> `tenant_webhooks`；`event_id` -> `webhook_events`
- **表级约束**：无额外表级约束。
- **索引说明**：`idx_webhook_delivery_status_time`(普通，字段：delivery_status, created_at DESC`)

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `webhook_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->tenant_webhooks | 关联 `tenant_webhooks` 表主键。 |
| `event_id` | `BIGINT` | `Long` | 是 | - | FK->webhook_events | 关联 `webhook_events` 表主键。 |
| `delivery_status` | `VARCHAR(32)` | `String` | 否 | - | NOT NULL / CHECK(delivery_status IN ('pending', 'success', 'failed')) | 状态字段，建议生成枚举。 |
| `request_headers` | `JSONB` | `JsonNode/Map<String,Object>` | 是 | - | - | 推送请求头 JSON。 |
| `request_body` | `JSONB` | `JsonNode/Map<String,Object>` | 是 | - | - | 推送请求体 JSON。 |
| `response_status_code` | `INTEGER` | `Integer` | 是 | - | - | 接收端响应状态码。 |
| `response_body` | `TEXT` | `String` | 是 | - | - | 接收端响应体。 |
| `retry_count` | `INTEGER` | `Integer` | 否 | 0 | NOT NULL | 数量统计字段。 |
| `delivered_at` | `TIMESTAMP` | `LocalDateTime` | 是 | - | - | 时间字段。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

## 模块：10. 平台运营体系

### tenant_daily_stats（租户日统计）

- **建议实体名**：`TenantDailyStat`
- **业务用途**：按天沉淀租户活跃、存储、资源分等运营统计数据。
- **主要关系**：`tenant_id` -> `tenants`
- **表级约束**：`UNIQUE (tenant_id, stat_date)`
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `tenant_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->tenants | 关联 `tenants` 表主键。 |
| `stat_date` | `DATE` | `LocalDate` | 否 | - | NOT NULL | 统计日期。建议实体类型使用 LocalDate。 |
| `active_user_count` | `INTEGER` | `Integer` | 否 | 0 | NOT NULL | 活跃用户数。 |
| `new_user_count` | `INTEGER` | `Integer` | 否 | 0 | NOT NULL | 新增用户数。 |
| `api_call_count` | `BIGINT` | `Long` | 否 | 0 | NOT NULL | API 调用量。 |
| `storage_bytes` | `BIGINT` | `Long` | 否 | 0 | NOT NULL | 存储使用字节数。 |
| `resource_score` | `DECIMAL(10, 2)` | `BigDecimal` | 否 | 0 | NOT NULL | 资源使用评分。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

### platform_monitor_metrics（平台监控指标）

- **建议实体名**：`PlatformMonitorMetric`
- **业务用途**：记录平台服务状态、系统负载和接口性能等指标。
- **主要关系**：无直接外键，主要作为独立主档或日志表使用。
- **表级约束**：无额外表级约束。
- **索引说明**：`idx_platform_monitor_metrics_type_time`(普通，字段：metric_type, collected_at DESC`)

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `component_name` | `VARCHAR(128)` | `String` | 否 | - | NOT NULL | 名称。 |
| `metric_type` | `VARCHAR(32)` | `String` | 否 | - | NOT NULL / CHECK(metric_type IN ('service_status', 'system_load', 'api_performance')) | 监控指标类型。 |
| `metric_key` | `VARCHAR(128)` | `String` | 否 | - | NOT NULL | 指标键。 |
| `metric_value` | `DECIMAL(18, 4)` | `BigDecimal` | 否 | - | NOT NULL | 指标值。 |
| `metric_unit` | `VARCHAR(32)` | `String` | 是 | - | - | 指标单位。 |
| `collected_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 时间字段。 |

## 模块：11. 日志与审计

### operation_logs（操作日志）

- **建议实体名**：`OperationLog`
- **业务用途**：记录平台用户、租户用户或系统触发的操作日志。
- **主要关系**：`tenant_id` -> `tenants`
- **表级约束**：`CHECK ((operator_type = 'system' AND operator_id IS NULL) OR (operator_type IN ('platform_user', 'tenant_user') AND operator_id IS NOT NULL))`
- **索引说明**：`idx_operation_logs_tenant_time`(普通，字段：tenant_id, created_at DESC`)

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `tenant_id` | `BIGINT` | `Long` | 是 | - | FK->tenants | 关联 `tenants` 表主键。 |
| `operator_type` | `VARCHAR(32)` | `String` | 否 | - | NOT NULL / CHECK(operator_type IN ('platform_user', 'tenant_user', 'system')) | 操作主体类型：平台用户/租户用户/系统。 |
| `operator_id` | `BIGINT` | `Long` | 是 | - | - | 操作主体 ID。系统触发时为空。 |
| `action` | `VARCHAR(128)` | `String` | 否 | - | NOT NULL | 动作编码。 |
| `resource_type` | `VARCHAR(64)` | `String` | 是 | - | - | 资源类型。 |
| `resource_id` | `VARCHAR(128)` | `String` | 是 | - | - | 资源标识。 |
| `request_id` | `VARCHAR(128)` | `String` | 是 | - | - | 链路请求 ID。 |
| `ip_address` | `VARCHAR(64)` | `String` | 是 | - | - | 业务字段。 |
| `user_agent` | `TEXT` | `String` | 是 | - | - | 业务字段。 |
| `operation_result` | `VARCHAR(32)` | `String` | 否 | - | NOT NULL / CHECK(operation_result IN ('success', 'failed')) | 操作结果。 |
| `details` | `JSONB` | `JsonNode/Map<String,Object>` | 是 | - | - | 操作详情 JSON。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

### audit_logs（审计日志）

- **建议实体名**：`AuditLog`
- **业务用途**：记录审计事件、严重等级、合规标签和变更摘要。
- **主要关系**：`tenant_id` -> `tenants`
- **表级约束**：无额外表级约束。
- **索引说明**：`idx_audit_logs_tenant_time`(普通，字段：tenant_id, created_at DESC`)

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `tenant_id` | `BIGINT` | `Long` | 是 | - | FK->tenants | 关联 `tenants` 表主键。 |
| `audit_type` | `VARCHAR(64)` | `String` | 否 | - | NOT NULL | 审计类型。 |
| `severity` | `VARCHAR(32)` | `String` | 否 | - | NOT NULL / CHECK(severity IN ('low', 'medium', 'high', 'critical')) | 风险等级。 |
| `subject_type` | `VARCHAR(64)` | `String` | 是 | - | - | 审计对象类型。 |
| `subject_id` | `VARCHAR(128)` | `String` | 是 | - | - | 审计对象标识。 |
| `change_summary` | `JSONB` | `JsonNode/Map<String,Object>` | 是 | - | - | 变更摘要 JSON。 |
| `compliance_tag` | `VARCHAR(64)` | `String` | 是 | - | - | 合规标签。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

### system_logs（系统日志）

- **建议实体名**：`SystemLog`
- **业务用途**：记录平台服务级系统日志。
- **主要关系**：无直接外键，主要作为独立主档或日志表使用。
- **表级约束**：无额外表级约束。
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `service_name` | `VARCHAR(128)` | `String` | 否 | - | NOT NULL | 名称。 |
| `log_level` | `VARCHAR(16)` | `String` | 否 | - | NOT NULL / CHECK(log_level IN ('debug', 'info', 'warn', 'error', 'fatal')) | 日志等级。 |
| `trace_id` | `VARCHAR(128)` | `String` | 是 | - | - | 链路追踪 ID。 |
| `message` | `TEXT` | `String` | 否 | - | NOT NULL | 日志正文。 |
| `context` | `JSONB` | `JsonNode/Map<String,Object>` | 是 | - | - | 上下文 JSON。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

## 模块：12. 通知系统

### notification_templates（消息模板）

- **建议实体名**：`NotificationTemplate`
- **业务用途**：维护邮件、短信、站内信模板。
- **主要关系**：无直接外键，主要作为独立主档或日志表使用。
- **表级约束**：无额外表级约束。
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `template_code` | `VARCHAR(64)` | `String` | 否 | - | UNIQUE / NOT NULL | 业务编码。 |
| `template_name` | `VARCHAR(128)` | `String` | 否 | - | NOT NULL | 名称。 |
| `channel` | `VARCHAR(32)` | `String` | 否 | - | NOT NULL / CHECK(channel IN ('email', 'sms', 'site_message')) | 模板发送渠道。 |
| `subject_template` | `VARCHAR(255)` | `String` | 是 | - | - | 通知标题模板。 |
| `body_template` | `TEXT` | `String` | 否 | - | NOT NULL | 通知正文模板。 |
| `variables` | `JSONB` | `JsonNode/Map<String,Object>` | 是 | - | - | 模板变量定义。 |
| `status` | `VARCHAR(32)` | `String` | 否 | 'active' | NOT NULL / CHECK(status IN ('active', 'disabled')) | 业务状态字段。应根据 CHECK 约束生成枚举。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |
| `updated_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 更新时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

### notifications（通知记录）

- **建议实体名**：`Notification`
- **业务用途**：记录实际发送给租户或用户的通知。
- **主要关系**：`tenant_id` -> `tenants`；`template_id` -> `notification_templates`
- **表级约束**：无额外表级约束。
- **索引说明**：`idx_notifications_tenant_status`(普通，字段：tenant_id, send_status`)

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `tenant_id` | `BIGINT` | `Long` | 是 | - | FK->tenants | 关联 `tenants` 表主键。 |
| `template_id` | `BIGINT` | `Long` | 是 | - | FK->notification_templates | 关联 `notification_templates` 表主键。 |
| `channel` | `VARCHAR(32)` | `String` | 否 | - | NOT NULL / CHECK(channel IN ('email', 'sms', 'site_message')) | 业务字段。 |
| `recipient` | `VARCHAR(255)` | `String` | 否 | - | NOT NULL | 接收人地址、手机号或用户标识。 |
| `subject` | `VARCHAR(255)` | `String` | 是 | - | - | 通知标题。 |
| `body` | `TEXT` | `String` | 否 | - | NOT NULL | 通知正文。 |
| `send_status` | `VARCHAR(32)` | `String` | 否 | - | NOT NULL / CHECK(send_status IN ('pending', 'sent', 'failed', 'read')) | 发送状态。 |
| `sent_at` | `TIMESTAMP` | `LocalDateTime` | 是 | - | - | 时间字段。 |
| `read_at` | `TIMESTAMP` | `LocalDateTime` | 是 | - | - | 时间字段。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

## 模块：13. 文件与存储

### storage_strategies（存储策略）

- **建议实体名**：`StorageStrategy`
- **业务用途**：定义本地、S3、OSS、COS、MinIO 等存储策略。
- **主要关系**：无直接外键，主要作为独立主档或日志表使用。
- **表级约束**：无额外表级约束。
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `strategy_code` | `VARCHAR(64)` | `String` | 否 | - | UNIQUE / NOT NULL | 业务编码。 |
| `strategy_name` | `VARCHAR(128)` | `String` | 否 | - | NOT NULL | 名称。 |
| `provider_type` | `VARCHAR(32)` | `String` | 否 | - | NOT NULL / CHECK(provider_type IN ('local', 's3', 'oss', 'cos', 'minio', 'other')) | 存储提供商类型。 |
| `bucket_name` | `VARCHAR(255)` | `String` | 是 | - | - | 存储桶名称。 |
| `base_path` | `VARCHAR(255)` | `String` | 是 | - | - | 基础存储路径。 |
| `config` | `JSONB` | `JsonNode/Map<String,Object>` | 是 | - | - | 存储配置 JSON。 |
| `status` | `VARCHAR(32)` | `String` | 否 | 'active' | NOT NULL / CHECK(status IN ('active', 'disabled')) | 业务状态字段。应根据 CHECK 约束生成枚举。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |
| `updated_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 更新时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

### tenant_files（租户文件）

- **建议实体名**：`TenantFile`
- **业务用途**：记录上传文件、所属租户、可见性、下载统计和校验信息。
- **主要关系**：`tenant_id` -> `tenants`；`storage_strategy_id` -> `storage_strategies`
- **表级约束**：`CHECK ((uploader_type = 'system' AND uploader_id IS NULL) OR (uploader_type IN ('platform_user', 'tenant_user') AND uploader_id IS NOT NULL))`
- **索引说明**：`idx_tenant_files_tenant_visibility`(普通，字段：tenant_id, visibility`)

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `tenant_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->tenants | 关联 `tenants` 表主键。 |
| `storage_strategy_id` | `BIGINT` | `Long` | 是 | - | FK->storage_strategies | 关联 `storage_strategies` 表主键。 |
| `file_name` | `VARCHAR(255)` | `String` | 否 | - | NOT NULL | 原始文件名。 |
| `file_path` | `VARCHAR(500)` | `String` | 否 | - | NOT NULL | 文件物理路径或对象 Key。 |
| `file_ext` | `VARCHAR(32)` | `String` | 是 | - | - | 文件扩展名。 |
| `mime_type` | `VARCHAR(128)` | `String` | 是 | - | - | MIME 类型。 |
| `file_size` | `BIGINT` | `Long` | 否 | 0 | NOT NULL | 文件大小（字节）。 |
| `checksum` | `VARCHAR(128)` | `String` | 是 | - | - | 文件校验和。 |
| `uploader_type` | `VARCHAR(32)` | `String` | 否 | - | NOT NULL / CHECK(uploader_type IN ('platform_user', 'tenant_user', 'system')) | 上传者类型。 |
| `uploader_id` | `BIGINT` | `Long` | 是 | - | - | 上传者 ID；系统上传时为空。 |
| `visibility` | `VARCHAR(32)` | `String` | 否 | 'private' | NOT NULL / CHECK(visibility IN ('private', 'tenant', 'public')) | 文件可见性范围。 |
| `download_count` | `BIGINT` | `Long` | 否 | 0 | NOT NULL | 下载次数。 |
| `last_downloaded_at` | `TIMESTAMP` | `LocalDateTime` | 是 | - | - | 最近下载时间。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |
| `updated_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 更新时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

### file_access_policies（文件访问策略）

- **建议实体名**：`FileAccessPolicy`
- **业务用途**：定义文件在租户、用户、角色、公开范围内的访问权限。
- **主要关系**：`file_id` -> `tenant_files`
- **表级约束**：`CHECK ((subject_type = 'public' AND subject_id IS NULL) OR (subject_type IN ('tenant', 'user', 'role') AND subject_id IS NOT NULL))`
- **索引说明**：`uq_file_access_policy_scoped_subject`(唯一，字段：file_id, subject_type, subject_id, permission_code`，条件：subject_id IS NOT NULL)；`uq_file_access_policy_public`(唯一，字段：file_id, subject_type, permission_code`，条件：subject_id IS NULL)

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `file_id` | `BIGINT` | `Long` | 否 | - | NOT NULL / FK->tenant_files | 关联 `tenant_files` 表主键。 |
| `subject_type` | `VARCHAR(32)` | `String` | 否 | - | NOT NULL / CHECK(subject_type IN ('tenant', 'user', 'role', 'public')) | 授权主体类型：租户/用户/角色/公开。 |
| `subject_id` | `VARCHAR(128)` | `String` | 是 | - | - | 授权主体标识；公开时为空。 |
| `permission_code` | `VARCHAR(32)` | `String` | 否 | - | NOT NULL / CHECK(permission_code IN ('read', 'write', 'delete', 'download')) | 权限编码。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

## 模块：14. 技术基础设施

### rate_limit_policies（限流策略）

- **建议实体名**：`RateLimitPolicy`
- **业务用途**：定义 API、租户、IP 维度的限流规则。
- **主要关系**：无直接外键，主要作为独立主档或日志表使用。
- **表级约束**：`UNIQUE (subject_type, subject_key)`
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `subject_type` | `VARCHAR(32)` | `String` | 否 | - | NOT NULL / CHECK(subject_type IN ('api', 'tenant', 'ip')) | 类型字段，建议生成枚举。 |
| `subject_key` | `VARCHAR(255)` | `String` | 否 | - | NOT NULL | 业务字段。 |
| `window_seconds` | `INTEGER` | `Integer` | 否 | - | NOT NULL | 业务字段。 |
| `limit_count` | `INTEGER` | `Integer` | 否 | - | NOT NULL | 数量统计字段。 |
| `burst_limit` | `INTEGER` | `Integer` | 是 | - | - | 业务字段。 |
| `status` | `VARCHAR(32)` | `String` | 否 | 'active' | NOT NULL / CHECK(status IN ('active', 'disabled')) | 业务状态字段。应根据 CHECK 约束生成枚举。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |
| `updated_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 更新时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

### data_isolation_policies（数据隔离策略）

- **建议实体名**：`DataIsolationPolicy`
- **业务用途**：定义租户数据隔离、访问控制和安全策略。
- **主要关系**：`tenant_id` -> `tenants`
- **表级约束**：无额外表级约束。
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `tenant_id` | `BIGINT` | `Long` | 是 | - | FK->tenants | 关联 `tenants` 表主键。 |
| `isolation_type` | `VARCHAR(32)` | `String` | 否 | - | NOT NULL / CHECK(isolation_type IN ('tenant_id', 'access_control', 'security_policy')) | 隔离策略类型。 |
| `policy_name` | `VARCHAR(128)` | `String` | 否 | - | NOT NULL | 策略名称。 |
| `policy_config` | `JSONB` | `JsonNode/Map<String,Object>` | 否 | - | NOT NULL | 策略配置 JSON。 |
| `status` | `VARCHAR(32)` | `String` | 否 | 'active' | NOT NULL / CHECK(status IN ('active', 'disabled')) | 业务状态字段。应根据 CHECK 约束生成枚举。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |
| `updated_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 更新时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

### infrastructure_components（基础设施组件）

- **建议实体名**：`InfrastructureComponent`
- **业务用途**：维护缓存、任务调度、配置中心、服务发现等基础组件。
- **主要关系**：无直接外键，主要作为独立主档或日志表使用。
- **表级约束**：`UNIQUE (component_type, component_name)`
- **索引说明**：未在当前字典中定义额外索引。

| 字段 | 数据类型 | 建议实体类型 | 可空 | 默认值 | 关键约束 | 字段说明 |
| --- | --- | --- | --- | --- | --- | --- |
| `id` | `BIGSERIAL PRIMARY KEY` | `Long` | 否 | - | PK / NOT NULL | 主键 ID。建议实体类型使用 Long。 |
| `component_type` | `VARCHAR(32)` | `String` | 否 | - | NOT NULL / CHECK(component_type IN ('cache', 'scheduler', 'config_center', 'service_discovery')) | 基础组件类型。 |
| `component_name` | `VARCHAR(128)` | `String` | 否 | - | NOT NULL | 组件名称。 |
| `endpoint` | `VARCHAR(255)` | `String` | 是 | - | - | 组件访问地址。 |
| `status` | `VARCHAR(32)` | `String` | 否 | 'active' | NOT NULL / CHECK(status IN ('active', 'disabled', 'degraded')) | 业务状态字段。应根据 CHECK 约束生成枚举。 |
| `component_config` | `JSONB` | `JsonNode/Map<String,Object>` | 是 | - | - | 组件配置 JSON。 |
| `last_heartbeat_at` | `TIMESTAMP` | `LocalDateTime` | 是 | - | - | 最近心跳时间。 |
| `created_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 创建时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |
| `updated_at` | `TIMESTAMP` | `LocalDateTime` | 否 | CURRENT_TIMESTAMP | NOT NULL | 更新时间。建议实体类型使用 LocalDateTime/OffsetDateTime。 |

## 5. 常见枚举建议

| 字段模式 | 建议生成枚举 | 说明 |
| --- | --- | --- |
| `status` / `*_status` | 是 | 例如账户状态、订阅状态、支付状态、发送状态等 |
| `*_type` | 是 | 例如权限类型、域名类型、渠道类型、组件类型等 |
| `isolation_mode` | 是 | 多租户隔离模式 |
| `billing_cycle` | 是 | 月付、季付、年付、一次性 |
| `visibility` | 是 | 文件可见性：private / tenant / public |

## 6. 生成实体时的特别注意事项

1. **不要把本文档当成 SQL 执行脚本**；它是 AI 生成实体、DTO、枚举、值对象和关系映射的依据。
2. **所有摘要/密文类字段**（如 `password_hash`、`secret_hash`、`secret_ciphertext`、`secret_token_hash`）都应保留为安全字段，不要生成明文派生字段。
3. **中间表和统计表** 通常不需要复杂行为，可用简单实体或聚合内部对象表示。
4. **JSONB 字段** 若业务稳定，建议拆出独立值对象；若业务灵活，建议使用 `JsonNode`。
5. **表级唯一约束和部分唯一索引** 需要在 ORM 层通过唯一注解、唯一索引配置或仓储层校验体现。
6. **多态主体字段**（如 `operator_type/operator_id`、`uploader_type/uploader_id`）在实体层应明确建模为“类型 + 目标标识”，不要误建成单一外键对象。

## 7. 后续扩展建议

- 若后续需要自动生成实体，可将本文档进一步拆分为 `数据库总览 + 每表独立字典 + AI Prompt 模板`。
- 若后续需要真正维护数据库结构，建议由应用在运行时根据实体和迁移框架（如 Flyway / Liquibase）同步，而不是直接维护手写 SQL。
- 若未来新增“租户用户体系”，建议与当前平台用户体系分离建模，避免平台管理员和租户终端用户混用。