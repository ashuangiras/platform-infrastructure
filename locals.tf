# Port assignment registry — host port is the map KEY.
#
# Duplicate keys are a Terraform parse error, so port conflicts are caught at
# `terraform validate` time rather than at runtime.
#
# When adding a new service, add its port(s) here first. If the port is already
# present, Terraform will refuse to parse the file and you must resolve the
# conflict before proceeding.
#
# Internal-only ports (PostgreSQL 5432, Redis 6379) are listed here too so the
# full picture is visible even though they are not exposed on the host.

locals {
  port_assignments = {
    # ── Storage ──────────────────────────────────────────────────────────────
    9000 = "minio-api"
    9001 = "minio-console"

    # ── Secrets ──────────────────────────────────────────────────────────────
    8200 = "vault-api"

    # ── Discovery ────────────────────────────────────────────────────────────
    8500 = "consul-http"
    8600 = "consul-dns-udp"

    # ── Data (internal — not bound to host, listed for visibility) ───────────
    # 5432 = "postgresql"   # host port not exposed; container-network only
    # 6379 = "redis"        # host port not exposed; container-network only

    # ── Identity ─────────────────────────────────────────────────────────────
    9080 = "authentik-http"
    9444 = "authentik-https"
  }
}
