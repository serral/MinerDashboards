# Dashboard Work Log

## Prerequisites

1. Scripts are written in Bash, a Linux host is required to scrape metrics.
2. Scripts require curl and jq, these can be installed manualy with apt or by running the setup script below.
3. CPU temperature metrics are only compatable on Windows miners.
4. These instructions assume that miners, proxy, and InfluxDB are on the same network. Port forwarding is required otherwise.

## Database Setup

1. Install InfluxDB.
2. Install an InfluxDB Client (influxdb-client on Linux).
3. Create a database for the metrics to be written to.

    For this example, a single database 'MoneroMetrics' will be used.

5. Open the InfluxDB port (8086) on the computer's firewall.

    The process for this will be dependant on the operating system InfluxDB runs on.

### Setup Script    
    
On a clean Ubuntu 20.04 install, the following commands will setup this environment.

Note: Configure all variables within ```< >``` to reflect your settings.

```shell
#!/bin/bash
apt -y update
#echo "y" | sudo ufw enable
#ufw allow 8086/tcp
echo "deb https://repos.influxdata.com/ubuntu focal stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
wget -qO- https://repos.influxdata.com/influxdb.key | sudo apt-key add -
source /etc/lsb-release
echo "deb https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
apt -y install curl
apt -y install jq
#apt -y install influxdb
apt -y install influxdb2
apt -y install influxdb-client
service influxdb start
curl -POST http://localhost:8086/query --data-urlencode "q=CREATE DATABASE MoneroMetrics WITH DURATION 30d"
```

## Metric Setup

1. Enable XMRig HTTP API on miners and/or XMRig proxy.

    In the XMRig config.json file, locate the API settings and set:
    - enabled = true
    - host = IP address of the miner
    - port = port number to connect to
    - access-token = leave as 'null' for no access token, or type one of your choice in quotes

```json
{
    "api": {
        "id": null,
        "worker-id": "Miner 1"
    },
    "http": {
        "enabled": true,
        "host": "192.168.1.100",
        "port": 9999,
        "access-token": null,
        "restricted": true
    }
}
```

2. Open the API port on the miner's firewall.

    The process for this will be dependant on the operating system the miner runs on.

3. Install Core Temp on miners.

    Core Temp will be used to monitor the CPU temperature of the miner. This will only work on Windows.

4. Enable global shared memory & run on startup in Core Temp on miners.

    In Core Temp GUI: 
    
    - Options > Settings > General (Enable Start Core Temp with Windows)
    - Options > Settings > Advanced (Enable SNMP)

5. Install CoreTempTelegraf on miners.

    CoreTempTelegraf will be used to query the CPU temperature from Core Temp in a way that can be written to a database. 
    The executable can be found in the references section of this document.

6. Install Telegraf on miners.

    Telegraf will be used to write the CPU temperature to the InfluxDB.

7. Configure Telegraf to write to InfluxDB database.

    In the telegraf.conf file, locate the InfluxDB output section under Output Plugins and set:
    - urls = the IP address and port number of the InfluxDB server
    - database = the name of the database created in Step 3 of Database Setup

```powershell
[[outputs.influxdb]]
  ## The full HTTP or UDP URL for your InfluxDB instance.
   urls = ["http://192.168.1.10:8086"]

  ## The target database for metrics; will be created as needed.
   database = "MoneroMetrics"
```

8. Configure Telegrad to get Core Temp metrics.

    In the telegraf.conf file, under the Input Plugins section, delete any undesired metrics and add the following input for CoreTempTelegraf
    For this example, CoreTempTelegraf.exe is located in the root of C:\ - If not, specify the path accordingly.


```powershell
[[inputs.exec]]
   commands = [
      'powershell -Command "C:\CoreTempTelegraf"'
   ]
   data_format = "influx"
```

8. (Optional but recommended) Configure Telegraf as Windows service on miners, see reference at the bottom of this file for details.
9. Create Scheduled Task to run Monero Wallet RPC Server on startup.

    The process for this will be dependant on the operating system the wallet runs on. The following example is for Monero Wallet GUI on Windows.
    
    Note: Configure all variables within ```< >``` to reflect your settings.

```powershell
monero-wallet-rpc.exe --wallet-file <WALLET_FILE> --rpc-bind-port <PORT> --daemon-address <IP>:<PORT> --password <PASSWORD> --rpc-bind-ip 0.0.0.0 --confirm-external-bind --disable-rpc-login
```

10. Create a free developer account on CoinMarketCap.com and get an API key.

    This will be used to get the current market value and percent change in the last 24 hours.

## Metric Scraping

   Note: In each bash script, configure all variables within ```< >``` to reflect your settings.

1. Create a bash script for each miner to get metrics from the XMRig API and write to InfluxDB.

    The following example gets:
    - Current Hash Rate (HashRate)
    - Miner ID (Miner)
    - Current Algorithm (Algo)
    - Miner UpTime (UpTime)

```shell
#!/bin/bash
#Miner1Metrics.sh

MinerStats=$(curl -X GET -H "Content-Type: application/json" http://<IP>:<PORT>/1/summary)

HashRate=$(echo $MinerStats | jq -r '.hashrate.total[0]')
Miner=$(echo $MinerStats | jq -r '.worker_id')
Algo=$(echo $MinerStats | jq -r '.algo')
UpTime=$(echo $MinerStats | jq -r '.uptime')

curl -i -XPOST 'http://<IP>:<PORT>/write?db=MoneroMetrics' --data-binary "MinerMetrics,Miner=$Miner,Algo=$Algo UpTime=$UpTime,HashRate=$HashRate"
```

2. Create a bash script to get metrics from the proxy API / pool API and write to InfluxDB.

    The following example gets:
    - Number of miners connected (MinerCount)
    - Proxy UpTime (UpTime)

```shell
#!/bin/bash
#ProxyMetrics.sh

ProxyStats=$(curl -X GET -H "Content-Type: application/json" http://<IP>:<PORT>/1/summary)

MinerCount=$(echo $ProxyStats | jq -r '.miners.now')
UpTime=$(echo $ProxyStats | jq -r '.uptime')

curl -i -XPOST 'http://<IP>:<PORT>/write?db=MoneroMetrics' --data-binary "ProxyMetrics MinerCount=$MinerCount,UpTime=$UpTime"
```

3. Create a bash script to get metrics from pool API and write to InfluxDB.

    The following example gets:
    - Pool Hash Rate (PoolHashRate)
    - Hash Rate of all miners connected to pool (MinerHashRate)
    - Last Payment Received (LastPayment)
    - Amount mined since last payment (AmountDue)

```shell
#!/bin/bash
#PoolMetrics.sh

PoolHashRate=$(curl -X GET -H "Content-Type: application/json" https://api.moneroocean.stream/pool/stats)
MinerHashRate=$(curl https://api.moneroocean.stream/miner/<ADDRESS>/chart/hashrate)
LastPayment=$(curl -X GET -H "Content-Type: application/json" https://api.moneroocean.stream/miner/<ADDRESS>/payments)
AmountDue=$(curl -X GET -H "Content-Type: application/json" https://api.moneroocean.stream/miner/<ADDRESS>/stats)

PoolHashRate=$(echo $PoolHashRate | jq '.pool_statistics.hashRate')
MinerHashRate=$(echo $MinerHashRate | jq '.[0].hs2')
LastPayment=$(echo $LastPayment | jq '.[0].ts')

Now=$(date +%s)
LastPayment=(`expr $Now - $LastPayment`)

PreAmount=$(echo $AmountDue | jq '.amtDue')
AmountDue=$(printf %13s $PreAmount | tr ' ' 0 | sed 's/............$/.&/')

if [ -z "$LastPayment" ]; then LastPayment=0
fi

curl -i -XPOST 'http://<IP>:<PORT>/write?db=MoneroMetrics' --data-binary "PoolMetrics,Pool=MoneroOcean PoolHashRate=$PoolHashRate,MinerHashRate=$MinerHashRate,LastPayment=$LastPayment,AmountDue=$AmountDue"
```

4. Create a bash script to get metrics from Wemo Insight plug and write to InfluxDB.

    The following example gets:
    - Current power draw in milliwatts (PowerDraw)

```shell
#!/bin/bash
#PowerMetrics.sh

PowerDraw=$(curl -H 'Content-type:text/xml;  charset=utf-8' -H 'SOAPACTION:"urn:Belkin:service:insight:1#GetInsightParams"' -d '<?xml version="1.0" encoding="utf-8"?><s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:GetInsightParams xmlns:u="urn:Belkin:service:insight:1"></u:GetInsightParams></s:Body></s:Envelope>' 'http://<IP>:49153/upnp/control/insight1')

PowerDraw=$(echo $PowerDraw | cut -d'|' -f8)

curl -i -XPOST 'http://<IP>:<PORT>/write?db=MoneroMetrics' --data-binary "PowerDraw PowerDraw=$PowerDraw"
```

5. Create a bash script to pull metrics from CoinMarketCap API and write to InfluxDB.

    The following example gets:
    - Current XMR Market Value (XMRValue)
    - Percent of Change in Last 24 Hours (24hChange)

```shell
#!/bin/bash
#XMRMetrics.sh

XMRMetrics=$(curl -X GET -H "X-CMC_PRO_API_KEY: <API_KEY>" -H "Accept: application/json" -d "symbol=XMR" -G https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest)

XMRValue=$(echo $XMRMetrics | jq '.data.XMR.quote.USD.price')
DayChange=$(echo $XMRMetrics | jq '.data.XMR.quote.USD.percent_change_24h')

curl -i -XPOST 'http://<IP>:<PORT>/write?db=MoneroMetrics' --data-binary "XMRValue XMRValue=$XMRValue,DayChange=$DayChange"
```

6. Create a bash script to get metrics from Monero Wallet RPC server.

    The following example gets:
    - Current Wallet Balance (WalletBalance)

```shell
#!/bin/bash
#WalletMetrics.sh

WalletBalance=$(curl http://<IP>:<PORT>/json_rpc -d '{"jsonrpc":"2.0","id":"0","method":"get_balance","params":{"account_index":0,"address_indices":[0,1]}}' -H 'Content-Type: application/json')

WalletBalance=$(echo $WalletBalance | jq -r '.result.balance')
WalletBalance=$(echo "$WalletBalance * 0.000000000001" | bc)

curl -i -XPOST 'http://<IP>:<PORT>/write?db=MoneroMetrics' --data-binary "WalletBalance,Coin=XMR WalletBalance=$WalletBalance"
```

## Metric Scraping Automation

1. Make all scripts executable using 'chmod +x <SCRIPT_NAME>'

2. Create cron jobs to run each bash script at regular intervals.

    The following example runs all scripts once every minute, with the exception of XMRMetrics.sh due to free CoinMarketCap API accounts being limited to 333 
    requests per day. 1440 minutes in a day / 333 maximum daily requests = a minimum request interval of 4.3 minutes - this is rounded to 5 minutes for safety.

    Note: The MoneroOcean API also provides a current XMR value metric without this request limit. CoinMarketCap is used in this case solely for additional 
    information such as % of change, etc.

```shell
* * * * * /root/Scripts/MetricScrapers/Miner1Metrics.sh
* * * * * /root/Scripts/MetricScrapers/Miner2Metrics.sh
* * * * * /root/Scripts/MetricScrapers/ProxyMetrics.sh
* * * * * /root/Scripts/MetricScrapers/PoolMetrics.sh
* * * * * /root/Scripts/MetricScrapers/PowerMetrics.sh
* * * * * /root/Scripts/MetricScrapers/WalletMetrics.sh
*/5  * * * * /root/Scripts/MetricScrapers/XMRMetrics.sh
```

## Grafana Dashboarding

1. Install Grafana or create a free Grafana Cloud account.

    Note: To use a Grafana Cloud account, you must port forward your InfluxDB port to your external IP address. The instructions and scripts provided here are unauthenticated, exposing your database to the internet in this state is a very bad idea. 
    [See here for instructions on enabling authentication.](https://docs.influxdata.com/influxdb/v1.8/administration/authentication_and_authorization/#authentication)

2. Add the MoneroMetrics database as an InfluxDB Input Source in Grafana.
3. Query the database to display metrics in Grafana Dashboard panels as desired.

    Note: Specific panel configurations are dependant on personal preference.
    
### Example Queries

 - Get Total Hash Rate: SELECT mean("MinerHashRate") FROM "PoolMetrics" WHERE $timeFilter GROUP BY time($__interval) fill(null)
 - Get Pool Hash Rate: SELECT mean("PoolHashRate") FROM "PoolMetrics" WHERE $timeFilter GROUP BY time($__interval) fill(null)
 - Get Last Payment: SELECT mean("LastPayment") FROM "PoolMetrics" WHERE $timeFilter GROUP BY time($__interval) fill(null)
 - Get Amount Due: SELECT last("AmountDue") FROM "PoolMetrics" WHERE $timeFilter GROUP BY time($__interval) fill(null)
 - Get Miner Hash Rate: SELECT mean("HashRate") FROM "MinerMetrics" WHERE ("Miner" = '<MINER_ID>') AND $timeFilter
 - Get Current Algo: SELECT * FROM "MinerMetrics" WHERE ("Miner" = '<MINER_ID>') AND $timeFilter (filter Algo column in panel)
 - Get CPU Temp: SELECT "temperature" FROM "coretemp_cpu" WHERE ("host" = '<MINER_COMPUTER_NAME>') AND $timeFilter
 - Get Wattage: SELECT last("PowerDraw") FROM "PowerDraw" WHERE $timeFilter GROUP BY time($__interval) fill(null)
 - Get Proxy Uptime: SELECT last("UpTime") FROM "ProxyMetrics" WHERE $timeFilter GROUP BY time($__interval) fill(null)
 - Get Current XMR Value: SELECT mean("XMRValue) FROM "XMRValue" WHERE $timeFilter GROUP BY time($__interval) fill(null)
 - Get Day % Value Change: SELECT mean("24hChange") FROM "XMRValue" WHERE $timeFilter GROUP BY time($__interval) fill(null)
 - Get Wallet Balance: SELECT last("WalletBalance") FROM "WalletMetrics" WHERE $timeFilter GROUP BY time($__interval) fill(null)

## References

- [XMRig HTTP API](https://xmrig.com/docs/miner/api)
- [MoneroOcean API](https://github.com/MoneroOcean/nodejs-pool/blob/master/lib/api.js)
- [CoinMarketCap API](https://coinmarketcap.com/api/documentation/v1/)
- [Wemo Insight SOAP](https://github.com/tigoe/WeMoExamples)
- [Telegraf Windows Service](https://docs.influxdata.com/telegraf/v1.17/administration/windows_service/)
- [CoreTempTelegraf](https://tomk.xyz/k/coretemptelegraf)
- [Monero Wallet RPC](https://www.getmonero.org/resources/developer-guides/wallet-rpc.html)

## Donations

If you find this information helpful, donations are greatly appreciated!

XMR:47zEuqnGse6LBQMF9hnRGxGn7bLgJQXzZThjqFMFsqb152PVmiPP5eXfK7vNPpQTX5W5BmAqqu6DeVdUrT7nG5NyMNxvMr2
