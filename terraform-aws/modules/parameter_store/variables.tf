# modules/parameter_store/variables.tf

variable "environment" {
  type = string
}

variable "server_base_url" {
  type = string
}

variable "db_host" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "jwt_secret" {
  type      = string
  sensitive = true
}

variable "token_hash_secret" {
  type      = string
  sensitive = true
}

variable "ai_server_base_url" {
  type = string
}

variable "gcs_bucket_name" {
  type = string
}

variable "gcp_project_id" {
  type = string
}

variable "redis_host" {
  type = string
}

variable "openai_api_key" {
  type      = string
  sensitive = true
}

variable "gemini_api_key" {
  type      = string
  sensitive = true
}

variable "ollama_api_key" {
  type      = string
  sensitive = true
}

variable "tags" {
  type    = map(string)
  default = {}
}