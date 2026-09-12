#!/bin/bash
#PoolMetrics.sh

PoolHashRate=$(curl -X GET -H "Content-Type: application/json" https://api.moneroocean.stream/pool/stats)
MinerHashRate=$(curl https://api.moneroocean.stream/miner/${XMR_ADDRESS}/chart/hashrate)
LastPayment=$(curl -X GET -H "Content-Type: application/json" https://api.moneroocean.stream/miner/${XMR_ADDRESS}/payments)
AmountDue=$(curl -X GET -H "Content-Type: application/json" https://api.moneroocean.stream/miner/${XMR_ADDRESS}/stats)


PoolHashRate=$(echo $PoolHashRate | jq '.pool_statistics.hashRate')
MinerHashRate=$(echo $MinerHashRate | jq '.[0].hs2')
LastPayment=$(echo $LastPayment | jq '.[0].ts')

Now=$(date +%s)
LastPayment=(`expr $Now - $LastPayment`)

PreAmount=$(echo $AmountDue | jq '.amtDue')
AmountDue=$(printf %13s $PreAmount | tr ' ' 0 | sed 's/............$/.&/')

if [ -z "$LastPayment" ]; then 
LastPayment=0
fi

#curl -i -XPOST 'http://<IP>:<PORT>/write?db=MoneroMetrics' --data-binary "PoolMetrics,Pool=MoneroOcean PoolHashRate=$PoolHashRate,MinerHashRate=$MinerHashRate,LastPayment=$LastPayment,AmountDue=$AmountDue"
curl -XPOST "http://${INFLUX_HOST}/api/v2/write?org=${INFLUX_ORG}&bucket=${INFLUX_BUCKET}&precision=ns" --header "Authorization: Token ${INFLUX_TOKEN}" --header "Content-Type: text/plain; charset=utf-8" --header "Accept: application/json" --data-binary "PoolMetrics,Pool=MoneroOcean PoolHashRate=$PoolHashRate,MinerHashRate=$MinerHashRate,LastPayment=$LastPayment,AmountDue=$AmountDue"
