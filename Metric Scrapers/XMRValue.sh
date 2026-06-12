#!/bin/bash
#XMRValue.sh

# Requires: CMC_PRO_API_KEY, INFLUX_HOST, INFLUX_ORG, INFLUX_BUCKET, INFLUX_TOKEN

XMRMetrics=$(curl -s -X GET \
  -H "X-CMC_PRO_API_KEY: ${CMC_PRO_API_KEY}" \
  -H "Accept: application/json" \
  -d "symbol=XMR" -G \
  https://pro-api.coinmarketcap.com/v2/cryptocurrency/quotes/latest)

XMRValue=$(echo "$XMRMetrics" | jq '.data.XMR[].quote.USD.price')
DayChange=$(echo "$XMRMetrics" | jq '.data.XMR[].quote.USD.percent_change_24h')
HourChange=$(echo "$XMRMetrics" | jq '.data.XMR[].quote.USD.percent_change_1h')

# Skip the write if the API call failed (key/rate-limit/network)
if [ -z "$XMRValue" ] || [ "$XMRValue" = "null" ]; then
    echo "XMRValue.sh: no price returned, skipping write" >&2
    exit 1
fi

curl -XPOST "http://${INFLUX_HOST}/api/v2/write?org=${INFLUX_ORG}&bucket=${INFLUX_BUCKET}&precision=ns" \
  --header "Authorization: Token ${INFLUX_TOKEN}" \
  --header "Content-Type: text/plain; charset=utf-8" \
  --header "Accept: application/json" \
  --data-binary "XMRValue XMRValue=$XMRValue,DayChange=$DayChange,HourChange=$HourChange"
