Provider.tf


# Define Google Cloud provider and version block
terraform {
  required_version = ">= 0.13"
}

# Configure Google Cloud provider
provider "google" {
  credentials = file("path to your sa key")
  project     = var.project_id
  region      = var.region
}
