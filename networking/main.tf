module "docker_network" {
  source = "git::https://github.com/ashuangiras/platform-modules.git//modules/networking/docker-network?ref=main"

  name   = "platform-backend"
  driver = "bridge"
  # Keep internal = false so Docker can pull images on first run.
  # Tighten to true after all images are cached locally.
  internal = false

  ipam_config = {
    subnet  = var.subnet
    gateway = var.gateway
  }

  labels = {
    "platform.env" = var.environment
  }
}
