#!/bin/bash
#Miner1Metrics.sh

# Optional GMiner Support
# GMiner=`python3 <PATH>/GMiner.py`
# c=0
# for metric in ${GMiner}; do
#     eval "var$c=$metric";
#    c=$((c+1));
# done

# Algo=$(echo $var0)
# HashRate=$(echo $var1)
# UpTime=$(echo $var3)

MinerStats=$(curl -X GET -H "Content-Type: application/json" http://<IP>:<PORT>/2/summary)

HashRate=$(echo $MinerStats | jq -r '.hashrate.total[0]')
Miner=$(echo $MinerStats | jq -r '.worker_id')
Algo=$(echo $MinerStats | jq -r '.algo')
UpTime=$(echo $MinerStats | jq -r '.uptime')

curl -XPOST "http://${INFLUX_HOST}/api/v2/write?org=${INFLUX_ORG}&bucket=${INFLUX_BUCKET}&precision=ns" --header "Authorization: Token ${INFLUX_TOKEN}" --header "Content-Type: text/plain; charset=utf-8" --header "Accept: application/json" --data-binary "MinerMetrics,Miner=$Miner,Algo=$Algo UpTime=$UpTime,HashRate=$HashRate"
