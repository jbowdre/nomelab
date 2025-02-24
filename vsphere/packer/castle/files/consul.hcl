# Full configuration options can be found at https://www.consul.io/docs/agent/options.html

advertise_addr = "{{ GetInterfaceIP `ens192` }}"

auto_encrypt {
  allow_tls = true
}

autopilot {
  upgrade_version_tag = "build"
}

bootstrap_expect = 3

ca_file = "/etc/consul.d/consul-agent-ca.pem"

cert_file = "/etc/consul.d/dc1-server-consul.pem"

client_addr = "0.0.0.0"

connect {
  enabled                            = true
  enable_mesh_gateway_wan_federation = true
}

datacenter = "dc1"

data_dir = "/opt/consul"

enable_local_script_checks = true

// encrypt = ""

key_file = "/etc/consul.d/dc1-server-consul-key.pem"

log_level = "INFO"

node_meta {
  build = "0.0.0"
}

ports {
  grpc  = 8502
  http  = -1
  https = 8501
}

primary_datacenter = "dc1"

retry_join = ["192.168.1.81", "192.168.1.82", "192.168.1.83", "192.168.1.84", "192.168.1.85", "192.168.1.86"]

server = true

telemetry {
  disable_hostname          = true
  dogstatsd_addr            = "localhost:8125"
  prometheus_retention_time = "30s"
}

ui_config {
  enabled = true
}

verify_incoming     = false
verify_incoming_rpc = true

verify_outgoing = true

verify_server_hostname = true