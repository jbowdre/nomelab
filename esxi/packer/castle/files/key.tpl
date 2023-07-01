{{- /* key.tpl */ -}}
{{ with secret "pki/intermediate/issue/lab-bowdre-net" "common_name=vault.service.consul" "alt_names=vault.lab.bowdre.net" "ip_sans=192.168.1.81,192.168.1.82,192.168.1.83,192.168.1.84,192.168.1.85,192.168.1.86,127.0.0.1" "ttl=4444h" }}
{{ .Data.private_key }}{{ end }}