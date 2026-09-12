# Miner Dashboarding

This repository contains bash scripts that scrape metrics from XMRig miners, XMRig proxies, GMiners, CoreTemp, the MoneroOcean pool, CoinMarketCap, Wemo Insight power plugs, and Monero wallets in order to write to InfluxDB for display on Grafana dashboards.

Detailed instructions are documented in the [Work Log](../main/WORKLOG.md)

## Credits

This project is a fork of [MrClappy/MinerDashboards](https://github.com/MrClappy/MinerDashboards), which has not been updated in several years. All credit for the original scripts, dashboards, and setup approach goes to that project. This fork has since diverged with the following changes:

- Migrated from InfluxDB 1.x to InfluxDB 2.x (`/api/v2/write`, org/bucket/token auth instead of an unauthenticated `/write?db=` endpoint).
- Removed hardcoded IPs, ports, and API keys from the scripts in favor of environment variables (`INFLUX_HOST`, `INFLUX_TOKEN`, `MINER_HOST`, `WALLET_HOST`, `CMC_API_KEY`, etc.).
- Added [direnv](https://direnv.net/) support (`.env.example`) so those environment variables are loaded automatically per-project instead of being edited into the scripts by hand. See the [Work Log](../main/WORKLOG.md#environment-setup-direnv) for setup steps.
- Added a failure guard to `XMRValue.sh` so a failed/rate-limited CoinMarketCap call skips the InfluxDB write instead of writing `null`.
- Stopped tracking `.DS_Store` and other local artifacts.

![Imgur Image](https://i.imgur.com/5v7XJJ9.png)
# 
![Imgur Image](https://i.imgur.com/tetE4Jy.png)
# 
![Imgur Image](https://i.imgur.com/Ze4xAjb.png)
