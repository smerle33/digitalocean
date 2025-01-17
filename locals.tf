resource "random_string" "suffix" {
  length  = 8
  special = false
}

locals {
  cluster_name           = lower("jenkins-infra-doks-${random_string.suffix.result}")
  doks_version           = data.digitalocean_kubernetes_versions.k8s.latest_version
  minimal_node_pool_size = "s-1vcpu-2gb" # Available sizes: `doctl compute size list`
}
