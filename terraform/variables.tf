variable "primary_region" {
  default = "us-east-1"
}
variable "secondary_region" {
  default = "ap-south-1"
}
variable "app_name" {
  default = "multi-region-app"
}
variable "instance_type" {
  default = "t3.micro"
}
variable "min_size" {
  default = 2
}
variable "max_size" {
  default = 6
}
