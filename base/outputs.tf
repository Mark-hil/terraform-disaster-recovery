output "primary_vpc_id" {
  description = "ID of the primary VPC"
  value       = module.primary_vpc.vpc_id
}

output "dr_vpc_id" {
  description = "ID of the DR VPC"
  value       = module.dr_vpc.vpc_id
}

output "primary_subnet_ids" {
  description = "List of subnet IDs in primary VPC"
  value       = concat(module.primary_vpc.private_subnet_ids, module.primary_vpc.public_subnet_ids)
}

output "dr_subnet_ids" {
  description = "List of subnet IDs in DR VPC"
  value       = concat(module.dr_vpc.private_subnet_ids, module.dr_vpc.public_subnet_ids)
}
