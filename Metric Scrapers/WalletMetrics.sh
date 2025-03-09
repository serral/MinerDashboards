#!/bin/bash
#WalletMetrics.sh


#WalletBalance=$(curl http://<IP>:<PORT>/json_rpc -d '{"jsonrpc":"2.0","id":"0","method":"get_balance","params":{"account_index":0,"address_indices":[0,1]}}' -H 'Content-Type: application/json')
WalletBalance=$(curl http://10.0.0.105:18083/json_rpc -d '{"jsonrpc":"2.0","id":"0","method":"get_balance","params":{"account_index":0,"address_indices":[0]}}' -H 'Content-Type: application/json')
#address_indices array may vary. Check output of monero-wallet-rpc


WalletBalance=$(echo $WalletBalance | jq -r '.result.balance')
WalletBalance=$(echo "$WalletBalance * 0.000000000001" | bc)

curl -XPOST "http://${INFLUX_HOST}/api/v2/write?org=${INFLUX_ORG}&bucket=${INFLUX_BUCKET}&precision=ns" --header "Authorization: Token ${INFLUX_TOKEN}" --header "Content-Type: text/plain; charset=utf-8" --header "Accept: application/json" --data-binary "WalletBalance,Coin=XMR WalletBalance=$WalletBalance"
