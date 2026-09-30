output "global_accelerator_dns" {
  value = aws_globalaccelerator_accelerator.this.dns_name
}
output "global_accelerator_ips" {
  value = aws_globalaccelerator_accelerator.this.ip_sets
}
output "primary_alb_dns" {
  value = module.primary.alb_dns
}
output "secondary_alb_dns" {
  value = module.secondary.alb_dns
}
output "primary_ecr" {
  value = module.primary.ecr_url
}
output "secondary_ecr" {
  value = module.secondary.ecr_url
}
