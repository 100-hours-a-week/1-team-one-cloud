# environments/prod/variables.tf

variable "server_base_url" {
  type    = string
  default = "https://raisedeveloper.com"
}

variable "db_host" {
  type    = string
  default = "localhost"
}

variable "ai_server_base_url" {
  type    = string
  default = "http://to-be-created:8000"
}

variable "gcs_bucket_name" {
  type    = string
  default = "raise-developer-prod-bucket"
}

variable "gcp_project_id" {
  type    = string
  default = "project-e2fc2245-be96-4876-af6"
}

variable "redis_host" {
  type    = string
  default = "localhost"
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