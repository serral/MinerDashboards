#!/bin/bash
#ProxyMetrics.sh

ProxyStats=$(curl -X GET -H "Content-Type: application/json" http://<IP>:<PORT>/2/summary)

MinerCount=$(echo $ProxyStats | jq -r '.miners.now')
UpTime=$(echo $ProxyStats | jq -r '.uptime')

curl -XPOST "http://${INFLUX_HOST}/api/v2/write?org=${INFLUX_ORG}&bucket=${INFLUX_BUCKET}&precision=ns" --header "Authorization: Token ${INFLUX_TOKEN}" --header "Content-Type: text/plain; charset=utf-8" --header "Accept: application/json" --data-binary "ProxyMetrics MinerCount=$MinerCount,UpTime=$UpTime"