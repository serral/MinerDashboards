#!/bin/bash
#XMRValue.sh

#XMRMetrics=$(curl -X GET -H "X-CMC_PRO_API_KEY: <API_KEY>" -H "Accept: application/json" -d "symbol=XMR" -G https://pro-api.coinmarketcap.com/v2/cryptocurrency/quotes/latest)
XMRMetrics=$(curl -X GET -H "X-CMC_PRO_API_KEY: 90c4bba5-b422-444e-8a2b-90e79eb930df" -H "Accept: application/json" -d "symbol=XMR" -G https://pro-api.coinmarketcap.com/v2/cryptocurrency/quotes/latest)

XMRValue=$(echo $XMRMetrics | jq '.data.XMR [] .quote.USD.price')
DayChange=$(echo $XMRMetrics | jq '.data.XMR [] .quote.USD.percent_change_24h')
HourChange=$(echo $XMRMetrics | jq '.data.XMR [] .quote.USD.percent_change_1h')


#curl -i -XPOST 'http://<IP>:<PORT>/write?db=MoneroMetrics' --data-binary "XMRValue XMRValue=$XMRValue,DayChange=$DayChange"

#curl -XPOST "http://${INFLUX_HOST}/api/v2/write?org=${INFLUX_ORG}&bucket=${INFLUX_BUCKET}&precision=ns" --header "Authorization: Token ${INFLUX_TOKEN}" --header "Content-Type: text/plain; charset=utf-8" --header "Accept: application/json" --data-binary "XMRValue XMRValue=$XMRValue,DayChange=$DayChange"
curl -XPOST "http://${INFLUX_HOST}/api/v2/write?org=${INFLUX_ORG}&bucket=${INFLUX_BUCKET}&precision=ns" --header "Authorization: Token ${INFLUX_TOKEN}" --header "Content-Type: text/plain; charset=utf-8" --header "Accept: application/json" --data-binary "XMRValue XMRValue=$XMRValue,DayChange=$DayChange,HourChange=$HourChange"


echo XMRValue
echo $XMRValue
echo DayChange
echo $DayChange
echo  HourChange
echo $HourChange
