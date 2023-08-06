#!/bin/bash

# https://github.com/Gamerou/cloudflare_access_ip_whitelist
# Script provided by Gamerou

# Cloudflare API-Token
api_token="YOUR_CLOUDFLARE_API_TOKEN"

# Discord Webhook URL
discord_webhook_url="YOUR_DISCORD_WEBHOOK_URL"

# Policy details
account_identifier="YOUR_ACCOUNT_IDENTIFIER"
app_uuid="YOUR_APP_UUID"
policy_uuid="YOUR_POLICY_UUID"

# Cloudflare API endpoint for updating Access Policy
api_url="https://api.cloudflare.com/client/v4/accounts/${account_identifier}/access/apps/${app_uuid}/policies/${policy_uuid}"

# Get IPv4 and IPv6 addresses from Home Assistant
current_ipv4=$(curl -s -X GET "http://homeassistant.local/api/states/sensor.YOUR_IP_SENSOR_IPV4" -H "Authorization: Bearer YOUR_HOMEASSISTANT_BEARER_TOKEN" | jq -r '.state')
current_ipv6=$(curl -s -X GET "http://homeassistant.local/api/states/sensor.YOUR_IP_SENSOR_IPV6" -H "Authorization: Bearer YOUR_HOMEASSISTANT_BEARER_TOKEN" | jq -r '.state')

echo "Current IPv4 Address: ${current_ipv4}"
echo "Current IPv6 Address: ${current_ipv6}"

# Policy data to update with current IP addresses
policy_data='{
  "name": "IP",
  "decision": "bypass",
  "include": [
    {
      "ip": {
        "ip": "'"${current_ipv4}"'"
      }
    },
    {
      "ip": {
        "ip": "'"${current_ipv6}"'"
      }
    }
  ],
  "exclude": [],
  "require": []
}'

# Send the PUT request to update the policy
response=$(curl -s -X PUT -H "Content-Type: application/json" -H "X-Auth-Email: YOUR_CLOUDFLARE_EMAIL" -H "X-Auth-Key: ${api_token}" --data "${policy_data}" "${api_url}")

# Check if policy update was successful
if [ "$(echo "${response}" | jq -r '.success')" = "true" ]; then
  echo "Successfully updated Access Policy: ${policy_uuid}"
  # Send success message to Discord
  discord_message="Successfully updated Cloudflare Access Policy with IPv4: ${current_ipv4} and IPv6: ${current_ipv6}"
  curl -H "Content-Type: application/json" -d "{\"content\": \"$discord_message\"}" "${discord_webhook_url}"
else
  echo "Error updating Access Policy: ${response}"
  # Send error message to Discord
  discord_message="Error updating Cloudflare Access Policy. Response: ${response}"
  curl -H "Content-Type: application/json" -d "{\"content\": \"$discord_message\"}" "${discord_webhook_url}"
fi