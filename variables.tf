variable "project_id" {
  description = "The GCP Project ID to deploy resources into."
  type        = string
}

variable "region" {
  description = "The GCP region to deploy resources into."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone to deploy resources into."
  type        = string
  default     = "us-central1-a"
}

variable "dns_zone_name" {
  description = "The DNS zone name to be created (e.g., gcp.securebrowsing.cloud)."
  type        = string
}

variable "hostname" {
  description = "The simple hostname for the A record (e.g., pwa)."
  type        = string
}
