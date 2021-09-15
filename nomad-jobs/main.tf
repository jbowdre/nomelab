provider "nomad" {
  address = "http://nomad.service.consul:4646"
}

resource "nomad_job" "tfc-agent" {
  jobspec = file("${path.module}/tfc-agent.nomad")
}

resource "nomad_job" "controller" {
  jobspec = file("${path.module}/controller.nomad")
}

resource "nomad_job" "node" {
  jobspec = file("${path.module}/node.nomad")
}

data "nomad_plugin" "nas" {
  plugin_id        = "nas"
  wait_for_healthy = true
}

resource "nomad_job" "consul-esm" {
  jobspec = file("${path.module}/consul-esm.nomad")
}

resource "nomad_job" "pi-hole" {
  jobspec = file("${path.module}/pi-hole.nomad")

  hcl2 {
    enabled  = true
    allow_fs = true
    vars = {
      "docker_password" = var.docker_password
    }
  }
}

resource "nomad_external_volume" "consul_snapshots" {
  depends_on   = [data.nomad_plugin.nas]
  type         = "csi"
  plugin_id    = "nas"
  volume_id    = "consul_snapshots"
  name         = "consul_snapshots"
  capacity_min = "70M"
  capacity_max = "210M"

  capability {
    access_mode     = "multi-node-multi-writer"
    attachment_mode = "file-system"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "nomad_job" "consul-backups" {
  jobspec    = file("${path.module}/consul-backups.nomad")
  depends_on = [nomad_external_volume.consul_snapshots]
}

resource "nomad_external_volume" "nomad_snapshots" {
  depends_on   = [data.nomad_plugin.nas]
  type         = "csi"
  plugin_id    = "nas"
  volume_id    = "nomad_snapshots"
  name         = "nomad_snapshots"
  capacity_min = "70M"
  capacity_max = "210M"

  capability {
    access_mode     = "multi-node-multi-writer"
    attachment_mode = "file-system"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "nomad_job" "nomad-backups" {
  jobspec    = file("${path.module}/nomad-backups.nomad")
  depends_on = [nomad_external_volume.nomad_snapshots]
}

resource "nomad_external_volume" "traefik" {
  depends_on   = [data.nomad_plugin.nas]
  type         = "csi"
  plugin_id    = "nas"
  volume_id    = "traefik"
  name         = "traefik"
  capacity_min = "10M"
  capacity_max = "50M"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "nomad_job" "traefik" {
  jobspec    = templatefile("${path.module}/traefik.nomad", { pilot_token = var.pilot_token })
  depends_on = [nomad_external_volume.traefik]
}

resource "nomad_external_volume" "gitlab_config" {
  depends_on   = [data.nomad_plugin.nas]
  type         = "csi"
  plugin_id    = "nas"
  volume_id    = "gitlab_config"
  name         = "gitlab_config"
  capacity_min = "1M"
  capacity_max = "10M"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "nomad_external_volume" "gitlab_data" {
  depends_on   = [data.nomad_plugin.nas]
  type         = "csi"
  plugin_id    = "nas"
  volume_id    = "gitlab_data"
  name         = "gitlab_data"
  capacity_min = "1G"
  capacity_max = "5G"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "nomad_external_volume" "gitlab_logs" {
  depends_on   = [data.nomad_plugin.nas]
  type         = "csi"
  plugin_id    = "nas"
  volume_id    = "gitlab_logs"
  name         = "gitlab_logs"
  capacity_min = "3G"
  capacity_max = "12G"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "nomad_job" "gitlab" {
  jobspec    = file("${path.module}/gitlab.nomad")
  depends_on = [nomad_external_volume.gitlab_config, nomad_external_volume.gitlab_data, nomad_external_volume.gitlab_logs]
}

resource "nomad_external_volume" "splunk_etc" {
  depends_on   = [data.nomad_plugin.nas]
  type         = "csi"
  plugin_id    = "nas"
  volume_id    = "splunk_etc"
  name         = "splunk_etc"
  capacity_min = "1G"
  capacity_max = "3G"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "nomad_external_volume" "splunk_var" {
  depends_on   = [data.nomad_plugin.nas]
  type         = "csi"
  plugin_id    = "nas"
  volume_id    = "splunk_var"
  name         = "splunk_var"
  capacity_min = "30G"
  capacity_max = "100G"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "nomad_job" "splunk" {
  jobspec    = file("${path.module}/splunk.nomad")
  depends_on = [nomad_external_volume.splunk_etc, nomad_external_volume.splunk_var]
}

resource "nomad_external_volume" "unifi" {
  depends_on   = [data.nomad_plugin.nas]
  type         = "csi"
  plugin_id    = "nas"
  volume_id    = "unifi"
  name         = "unifi"
  capacity_min = "500M"
  capacity_max = "5G"

  capability {
    access_mode     = "multi-node-multi-writer"
    attachment_mode = "file-system"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "nomad_job" "unifi" {
  jobspec    = file("${path.module}/unifi.nomad")
  depends_on = [nomad_external_volume.unifi]
}

resource "nomad_external_volume" "influxdb" {
  depends_on   = [data.nomad_plugin.nas]
  type         = "csi"
  plugin_id    = "nas"
  volume_id    = "influxdb"
  name         = "influxdb"
  capacity_min = "10G"
  capacity_max = "30G"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "nomad_job" "influxdb" {
  jobspec    = file("${path.module}/influxdb.nomad")
  depends_on = [nomad_external_volume.influxdb]
}

resource "nomad_external_volume" "grafana_etc" {
  depends_on   = [data.nomad_plugin.nas]
  type         = "csi"
  plugin_id    = "nas"
  volume_id    = "grafana_etc"
  name         = "grafana_etc"
  capacity_min = "5M"
  capacity_max = "50M"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "nomad_external_volume" "grafana_lib" {
  depends_on   = [data.nomad_plugin.nas]
  type         = "csi"
  plugin_id    = "nas"
  volume_id    = "grafana_lib"
  name         = "grafana_lib"
  capacity_min = "5M"
  capacity_max = "50M"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "nomad_job" "grafana" {
  jobspec    = file("${path.module}/grafana.nomad")
  depends_on = [nomad_external_volume.grafana_etc, nomad_external_volume.grafana_lib]
}

resource "nomad_external_volume" "prometheus" {
  depends_on   = [data.nomad_plugin.nas]
  type         = "csi"
  plugin_id    = "nas"
  volume_id    = "prometheus"
  name         = "prometheus"
  capacity_min = "10G"
  capacity_max = "30G"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "nomad_job" "prometheus" {
  jobspec = file("${path.module}/prometheus.nomad")
  depends_on = [nomad_external_volume.prometheus]
}

resource "nomad_job" "das-autoscaler" {
  jobspec = file("${path.module}/das-autoscaler.nomad")
}

resource "nomad_job" "telegraf" {
  jobspec = file("${path.module}/telegraf.nomad")
}
