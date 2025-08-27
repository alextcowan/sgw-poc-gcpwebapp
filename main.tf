# Configure the Google Cloud provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Create a firewall rule to allow HTTPS and SSH from within the VPC
resource "google_compute_firewall" "allow_internal_https" {
  name    = "allow-internal-https-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["443", "22"] # HTTPS and SSH
  }

  # This allows traffic from any source within the same VPC
  source_ranges = ["10.128.0.0/9"]
  target_tags   = ["web-server"]
}

# Firewall rule to allow IAP for SSH
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "allow-iap-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # This is the IP range for Google's IAP service
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["web-server"]
}

# Create the Google Compute Engine instance
resource "google_compute_instance" "apache_vm" {
  name         = "apache-internal-vm"
  machine_type = "e2-micro" # A small, cost-effective machine type
  zone         = var.zone
  tags         = ["web-server"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  # This network interface has NO external IP address
  network_interface {
    network = "default"
  }

  # The startup script to install and configure Apache
  # Use the templatefile function to inject variables into the startup script
  metadata_startup_script = templatefile("startup.sh.tpl", {
    fqdn = "${var.hostname}.${var.dns_zone_name}"
  })


  // Allows the instance to be shut down
  allow_stopping_for_update = true
}

# A Cloud Router is required for Cloud NAT
resource "google_compute_router" "router" {
  name    = "nat-router"
  network = "default"
  region  = var.region
}

# The Cloud NAT Gateway configuration
resource "google_compute_router_nat" "nat_gateway" {
  name                               = "nat-gateway-config"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  nat_ip_allocate_option             = "AUTO_ONLY"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Create a private DNS managed zone for the domain.
resource "google_dns_managed_zone" "private_zone" {
  name       = "internal-pwa-zone"
  # Use the variable for the DNS zone name (and add the required trailing dot)
  dns_name   = "${var.dns_zone_name}."
  visibility = "private"

  private_visibility_config {
    networks {
      network_url = "projects/${var.project_id}/global/networks/default"
    }
  }
}

# Create the 'A' record to point the hostname to the VM's internal IP.
resource "google_dns_record_set" "pwa_record" {
  # Combine the hostname and zone name variables to create the full FQDN
  name         = "${var.hostname}.${var.dns_zone_name}."
  managed_zone = google_dns_managed_zone.private_zone.name
  type         = "A"
  ttl          = 300

  # Dynamically get the internal IP from the VM resource
  rrdatas = [google_compute_instance.apache_vm.network_interface[0].network_ip]
}
