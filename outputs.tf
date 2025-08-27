output "vm_internal_ip" {
  description = "The internal IP address of the Apache VM."
  value       = google_compute_instance.apache_vm.network_interface[0].network_ip
}
