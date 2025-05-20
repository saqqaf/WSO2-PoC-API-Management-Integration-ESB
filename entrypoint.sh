#!/usr/bin/env bash
set -e

# pick up your hostname from an env var (passed via Compose)
HOST="${API_M_HOSTNAME:-localhost}"
PORT="443"

# 1) write a minimal deployment.toml
cat > /home/wso2carbon/wso2am-4.3.0/repository/conf/deployment.toml <<EOF
[server]
# carbon should advertise THIS as its hostname in every URL it generates
hostname = "${HOST}"
# respect X-Forwarded-Host / Proto so internal 9443 → external 443
enable_port_forward = true

# if you ever front everything at a path-prefix, uncomment below:
# proxy_context_path = "/apim"

[super_admin]
username = "${super_admin_username:-admin}"
password = "${super_admin_password:-admin}"
create_admin_account = true

[database.shared_db]
type = "postgres"
url = "jdbc:postgresql://${DB_HOST:-postgres}:${DB_PORT:-5432}/${DB_NAME:-wso2am}"
username = "${DB_USERNAME:-wso2carbon}"
password = "${DB_PASSWORD:-wso2carbon}"
driver = "org.postgresql.Driver"

[database.apim_db]
type = "postgres"
url = "jdbc:postgresql://${DB_HOST:-postgres}:${DB_PORT:-5432}/${DB_NAME:-wso2am}"
username = "${DB_USERNAME:-wso2carbon}"
password = "${DB_PASSWORD:-wso2carbon}"
driver = "org.postgresql.Driver"

[user_store]
type = "database"
class = "org.wso2.carbon.user.core.jdbc.JDBCUserStoreManager"
tenant_manager = "org.wso2.carbon.user.core.tenant.JDBCTenantManager"
read_only = false
max_user_name_list_length = 100
max_role_name_list_length = 100
user_roles_cache_enabled = true
properties.DriverName = "org.postgresql.Driver"
properties.URL = "jdbc:postgresql://${DB_HOST:-postgres}:${DB_PORT:-5432}/${DB_NAME:-wso2am}"
properties.UserName = "${DB_USERNAME:-wso2carbon}"
properties.Password = "${DB_PASSWORD:-wso2carbon}"
properties.UserNameUnique = "true"
properties.IsEmailUserName = "false"
properties.StoreSaltedPassword = "true"
properties.ReadGroups = "true"
properties.WriteGroups = "true"
properties.ReadOnly = "false"
properties.UserRolesCacheEnabled = "true"
properties.MaxUserNameListLength = "100"
properties.MaxRoleNameListLength = "100"
properties.UserNameSearchFilter = "UserName"
properties.RoleNameSearchFilter = "RoleName"
properties.UserNameAttribute = "UserName"
properties.RoleNameAttribute = "RoleName"
properties.UserNameListFilter = "UserName"
properties.RoleNameListFilter = "RoleName"
properties.UserNameProperty = "UserName"
properties.RoleNameProperty = "RoleName"
properties.UserNameListProperty = "UserName"
properties.RoleNameListProperty = "RoleName"

# (you _could_ add more [apim.*].url overrides here,
#  but we're going to fix the webapps next)
EOF

# 2) find every settings.json in all portals and patch origin
find /home/wso2carbon/wso2am-4.3.0/repository/deployment/server/webapps -type f -path "*/site/public/conf/settings.json" \
  -exec sed -i \
    -e "s/\"host\": \".*\"/\"host\": \"${HOST}\"/" \
    -e "s/\"port\": [0-9]\+/, \"port\": ${PORT}/" \
    -e "s#\"basePath\": \".*\"#\"basePath\": \"https://${HOST}\"#" \
    {} +

# now hand off to the normal WSO2 startup script
exec /home/wso2carbon/wso2am-4.3.0/bin/api-manager.sh
