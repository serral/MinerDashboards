#!/bin/bash
#PowerMetrics.sh

PowerDraw=$(curl -H 'Content-type:text/xml;  charset=utf-8' -H 'SOAPACTION:"urn:Belkin:service:insight:1#GetInsightParams"' -d '<?xml version="1.0" encoding="utf-8"?><s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:GetInsightParams xmlns:u="urn:Belkin:service:insight:1"></u:GetInsightParams></s:Body></s:Envelope>' "http://${POWER_HOST}:49153/upnp/control/insight1")

PowerDraw=$(echo $PowerDraw | cut -d'|' -f8)

curl -XPOST "http://${INFLUX_HOST}/api/v2/write?org=${INFLUX_ORG}&bucket=${INFLUX_BUCKET}&precision=ns" --header "Authorization: Token ${INFLUX_TOKEN}" --header "Content-Type: text/plain; charset=utf-8" --header "Accept: application/json" --data-binary "PowerDraw PowerDraw=$PowerDraw"
