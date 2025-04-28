locals {
  # Common resource naming
  name_prefix = "${var.environment}-${var.project_name}"
  
  # Common tags
  common_tags = merge(var.tags, {
    Environment = var.environment
    Region      = "DR"
    ManagedBy   = "terraform"
  })

  # DR settings
  dr_instance_type = "t3.micro"  # Cost-effective instance type for DR
  dr_instance_state = "stopped"  # DR instances start in stopped state
  
  # Container settings
  container_images = {
    frontend = "markhill97/chat-app-frontend:latest"
    backend  = "markhill97/chat-app-backend:latest"
  }
  
  container_ports = {
    frontend = 3000
    backend  = 8000
  }
}
