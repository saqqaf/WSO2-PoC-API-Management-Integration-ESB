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
