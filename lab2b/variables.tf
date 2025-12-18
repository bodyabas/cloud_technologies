variable "allowed_locations" {
  description = "List of allowed Azure locations for the lab"
  type        = list(string)
  default     = ["eastus", "westeurope"]
}
