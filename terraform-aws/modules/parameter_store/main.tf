# modules/parameter_store/main.tf

# Backend Parameters
# Server
resource "aws_ssm_parameter" "server_base_url" {
  name  = "/${var.environment}/backend/SERVER_BASE_URL"
  type  = "String"
  value = var.server_base_url
  tags  = var.tags
}

# Database
resource "aws_ssm_parameter" "db_host" {
  name  = "/${var.environment}/backend/DB_HOST"
  type  = "String"
  value = var.db_host
  tags  = var.tags
}

resource "aws_ssm_parameter" "db_port" {
  name  = "/${var.environment}/backend/DB_PORT"
  type  = "String"
  value = "3306"
  tags  = var.tags
}

resource "aws_ssm_parameter" "db_name" {
  name  = "/${var.environment}/backend/DB_NAME"
  type  = "String"
  value = "raise_developer"
  tags  = var.tags
}

resource "aws_ssm_parameter" "db_user" {
  name  = "/${var.environment}/backend/DB_USER"
  type  = "String"
  value = "admin"
  tags  = var.tags
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/${var.environment}/backend/DB_PASSWORD"
  type  = "SecureString"
  value = var.db_password
  tags  = var.tags
}

# JWT
resource "aws_ssm_parameter" "jwt_secret" {
  name  = "/${var.environment}/backend/JWT_SECRET"
  type  = "SecureString"
  value = var.jwt_secret
  tags  = var.tags
}

resource "aws_ssm_parameter" "token_hash_secret" {
  name  = "/${var.environment}/backend/TOKEN_HASH_SECRET"
  type  = "SecureString"
  value = var.token_hash_secret
  tags  = var.tags
}

# Spring
resource "aws_ssm_parameter" "spring_profiles_active" {
  name  = "/${var.environment}/backend/SPRING_PROFILES_ACTIVE"
  type  = "String"
  value = "prod"
  tags  = var.tags
}

# Firebase
resource "aws_ssm_parameter" "fire_base_path" {
  name  = "/${var.environment}/backend/FIRE_BASE_PATH"
  type  = "String"
  value = "file:/etc/secrets/firebase-key.json"
  tags  = var.tags
}

# AI Server
resource "aws_ssm_parameter" "ai_server_base_url" {
  name  = "/${var.environment}/backend/AI_SERVER_BASE_URL"
  type  = "String"
  value = var.ai_server_base_url
  tags  = var.tags
}

resource "aws_ssm_parameter" "ai_server_routine_api" {
  name  = "/${var.environment}/backend/AI_SERVER_ROUTINE_API"
  type  = "String"
  value = "/api/v1/routines"
  tags  = var.tags
}

resource "aws_ssm_parameter" "ai_server_routine_async_api" {
  name  = "/${var.environment}/backend/AI_SERVER_ROUTINE_ASYNC_API"
  type  = "String"
  value = "/api/v2/routines"
  tags  = var.tags
}

# GCS
resource "aws_ssm_parameter" "gcs_bucket_name" {
  name  = "/${var.environment}/backend/GCS_BUCKET_NAME"
  type  = "String"
  value = var.gcs_bucket_name
  tags  = var.tags
}

resource "aws_ssm_parameter" "gcs_credentials_path" {
  name  = "/${var.environment}/backend/GCS_CREDENTIALS_PATH"
  type  = "String"
  value = "file:/etc/secrets/backend-sa-key.json"
  tags  = var.tags
}

resource "aws_ssm_parameter" "gcp_project_id" {
  name  = "/${var.environment}/backend/GCP_PROJECT_ID"
  type  = "String"
  value = var.gcp_project_id
  tags  = var.tags
}

# Redis
resource "aws_ssm_parameter" "spring_data_redis_host" {
  name  = "/${var.environment}/backend/SPRING_DATA_REDIS_HOST"
  type  = "String"
  value = var.redis_host
  tags  = var.tags
}

resource "aws_ssm_parameter" "spring_data_redis_port" {
  name  = "/${var.environment}/backend/SPRING_DATA_REDIS_PORT"
  type  = "String"
  value = "6379"
  tags  = var.tags
}

# ========== AI Parameters ==========

# Environment
resource "aws_ssm_parameter" "ai_app_env" {
  name  = "/${var.environment}/ai/APP_ENV"
  type  = "String"
  value = "prod"
  tags  = var.tags
}

resource "aws_ssm_parameter" "ai_log_level" {
  name  = "/${var.environment}/ai/LOG_LEVEL"
  type  = "String"
  value = "DEBUG"
  tags  = var.tags
}

resource "aws_ssm_parameter" "ai_log_dir" {
  name  = "/${var.environment}/ai/LOG_DIR"
  type  = "String"
  value = "logs"
  tags  = var.tags
}

resource "aws_ssm_parameter" "ai_log_file_name" {
  name  = "/${var.environment}/ai/LOG_FILE_NAME"
  type  = "String"
  value = "app.log"
  tags  = var.tags
}

resource "aws_ssm_parameter" "ai_metrics_enabled" {
  name  = "/${var.environment}/ai/METRICS_ENABLED"
  type  = "String"
  value = "false"
  tags  = var.tags
}

# Server
resource "aws_ssm_parameter" "ai_host" {
  name  = "/${var.environment}/ai/HOST"
  type  = "String"
  value = "0.0.0.0"
  tags  = var.tags
}

resource "aws_ssm_parameter" "ai_port" {
  name  = "/${var.environment}/ai/PORT"
  type  = "String"
  value = "8000"
  tags  = var.tags
}

# LLM API Keys
resource "aws_ssm_parameter" "openai_api_key" {
  name  = "/${var.environment}/ai/OPENAI_API_KEY"
  type  = "SecureString"
  value = var.openai_api_key
  tags  = var.tags
}

resource "aws_ssm_parameter" "gemini_api_key" {
  name  = "/${var.environment}/ai/GEMINI_API_KEY"
  type  = "SecureString"
  value = var.gemini_api_key
  tags  = var.tags
}

resource "aws_ssm_parameter" "ollama_api_key" {
  name  = "/${var.environment}/ai/OLLAMA_API_KEY"
  type  = "SecureString"
  value = var.ollama_api_key
  tags  = var.tags
}

# URLs
resource "aws_ssm_parameter" "callback_url" {
  name  = "/${var.environment}/ai/CALLBACK_URL"
  type  = "String"
  value = "https://raisedeveloper.com/api/routines/callback"
  tags  = var.tags
}

resource "aws_ssm_parameter" "exercise_api_url" {
  name  = "/${var.environment}/ai/EXERCISE_API_URL"
  type  = "String"
  value = "https://raisedeveloper.com/api/exercise"
  tags  = var.tags
}