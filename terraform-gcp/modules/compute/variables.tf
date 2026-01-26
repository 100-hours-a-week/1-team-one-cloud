variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "zone" {
  description = "GCP Zone"
  type        = string
}

variable "instance_name" {
  description = "Name of the instance"
  type        = string
}

variable "machine_type" {
  description = "Machine type"
  type        = string
}

variable "boot_disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 10
}

variable "subnet_self_link" {
  description = "Self link of the subnet where the instance will be created"
  type        = string
}

variable "service_account_email" {
  description = "Service account email address. If null, the default Compute Engine service account is used."
  type        = string
  default     = null
}

variable "boot_disk_image" {
  description = "Boot disk image link or family"
  type        = string
  default     = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2404-lts-amd64"
}

variable "boot_disk_type" {
  description = "Boot disk type (pd-balanced, pd-ssd, pd-standard)"
  type        = string
  default     = "pd-balanced"
}

variable "tags" {
  description = "Network tags for the instance"
  type        = list(string)
  default     = ["ssh-enabled", "web-server"]
}

variable "static_ip" {
  description = "Static external IP address. If null, ephemeral IP is used."
  type        = string
  default     = null
}
