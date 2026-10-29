# Add a target server to Grafana monitoring

The monitoring stack uses Prometheus to collect metrics and Grafana to display them. Replace the example hostnames and IP addresses below with your own values:

- Grafana: `https://grafana.example.com`
- Target server: `app.example.com` / `<TARGET_SERVER_IP>`
- Monitoring server: `<MONITORING_SERVER_IP>`

## 1. Prepare the target server

The following steps assume an Ubuntu server. Install and start the node exporter to expose host metrics on port `9100`:

```bash
sudo apt update
sudo apt install -y prometheus-node-exporter
sudo systemctl enable --now prometheus-node-exporter
```

If the target server runs Docker and you also want container metrics, install Docker if needed, then start cAdvisor on port `8080`:

```bash
sudo docker run -d \
  --name=cadvisor \
  --restart unless-stopped \
  -p 8080:8080 \
  -v /:/rootfs:ro \
  -v /var/run:/var/run:ro \
  -v /sys:/sys:ro \
  -v /var/lib/docker:/var/lib/docker:ro \
  -v /dev/disk:/dev/disk:ro \
  gcr.io/cadvisor/cadvisor:latest
```

Allow inbound TCP traffic to ports `9100` and `8080` **only from the monitoring server's IP** in the target server's firewall or cloud firewall. Do not expose these exporter ports to the whole internet. If only host metrics are needed, open only port `9100`.

Check the endpoints from the monitoring server before proceeding:

```bash
curl http://<TARGET_SERVER_IP>:9100/metrics
curl http://<TARGET_SERVER_IP>:8080/metrics
```

The second check applies only when cAdvisor is running.

## 2. Add the target to Prometheus

SSH to the monitoring server and edit `/opt/monitoring/prometheus.yml`. Add the target to the corresponding existing `scrape_configs` job:

```yaml
- job_name: 'mern_vm_node_exporters'
  static_configs:
    - targets: ['<TARGET_SERVER_IP>:9100']
      labels:
        instance_name: 'app.example.com'
        vm_ip: '<TARGET_SERVER_IP>'

- job_name: 'mern_vm_cadvisors'
  static_configs:
    - targets: ['<TARGET_SERVER_IP>:8080']
      labels:
        instance_name: 'app.example.com'
        vm_ip: '<TARGET_SERVER_IP>'
```

Use the actual target server IP in both target entries and `vm_ip`. Use the example hostname (or your own hostname) as the display label. If cAdvisor is not enabled, omit its job entry.

Validate the Prometheus configuration and restart Prometheus:

```bash
cd /opt/monitoring
docker-compose exec prometheus promtool check config /etc/prometheus/prometheus.yml
docker-compose restart prometheus
```

## 3. Add it to the Grafana dashboard

1. Open `https://grafana.example.com` and edit the dashboard's custom `vm` variable.
2. Add entries for the new target, using the same display name and IP/ports, for example:

   ```text
   app.example.com:9100 : <TARGET_SERVER_IP>:9100, app.example.com:8080 : <TARGET_SERVER_IP>:8080
   ```

3. Save the variable and dashboard, then select the new target in the dashboard.

Adding a target to the Grafana variable alone does not make Prometheus collect its metrics; complete both the Prometheus and dashboard steps.

## Dashboard JSON backup

After editing the dashboard, use **Dashboard → Edit → Save dashboard → Copy JSON to clipboard**. The repository for the dashboard JSON is:

```text
https://github.com/falktron-how/grafana-dashboards/blob/main/dashboards/falktron-dashboard.json
```

## Git ignore and Terraform files

The [`.gitignore`](./.gitignore) in this folder excludes local Terraform data and secrets:

- `.terraform/`, Terraform state files (`*.tfstate*`), plans (`*.tfplan`), and crash logs.
- Variable files (`*.tfvars`, `*.tfvars.json`), which may contain API tokens, passwords, or SSH private keys.
- Local override files, `.env`, private key files (`*.pem`, `*.key`), and `.vscode/` settings.

Keep `terraform.tfvars` local. Create it from a safe template if needed, and never commit credentials or private keys. Keep `.terraform.lock.hcl` tracked so Terraform provider versions remain reproducible.
