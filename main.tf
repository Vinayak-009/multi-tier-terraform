# Create a VPC network
resource "google_compute_network" "vpc_network" {
  name                    = "new-vpc"
  auto_create_subnetworks = false
}

# Create a subnet within the VPC
resource "google_compute_subnetwork" "subnet" {
  name                     = "my-subnet"
  ip_cidr_range            = "10.0.1.0/24"
  network                  = google_compute_network.vpc_network.name
  region                   = var.region
}

# Define instance template
resource "google_compute_instance_template" "my_instance_template" {
  name         = "my-instance-template"
  machine_type = "e2-micro"
  
  disk {
    source_image = "debian-cloud/debian-10"
  }

  network_interface {
    network    = google_compute_network.vpc_network.self_link
    subnetwork = google_compute_subnetwork.subnet.self_link
  }

  metadata = {
    user-data = file("${path.module}/user-data.sh")
  }

  # Add network tags to allow HTTP and HTTPS traffic
  tags = ["http-server", "https-server"]
}


# Create a managed instance group
resource "google_compute_instance_group_manager" "mig" {
  name               = "instance-group-1"
  base_instance_name = "my-instance"
  zone               = var.zone

  version {
    instance_template = google_compute_instance_template.my_instance_template.id
  }
  
  target_size = 1
}



# Create firewall rules
resource "google_compute_firewall" "http_ingress" {
  name        = "allow-http-from-vpc"
  network     = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  description   = "HTTP from VPC"
}

resource "google_compute_firewall" "ssh_ingress" {
  name        = "allow-ssh"
  network     = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  description   = "SSH"
}

resource "google_compute_firewall" "egress_all" {
  name        = "allow-egress-all"
  network     = google_compute_network.vpc_network.name

  allow {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
  description   = "Allow all egress traffic"
}
# Create an external HTTPS load balancer
resource "google_compute_global_forwarding_rule" "lb_forwarding_rule" {
  name       = "my-lb-forwarding-rule"
  target     = google_compute_target_http_proxy.lb_proxy.self_link
  port_range = "443"
}

resource "google_compute_target_http_proxy" "lb_proxy" {
  name               = "my-lb-proxy"
  url_map            = google_compute_url_map.lb_url_map.self_link
}

resource "google_compute_url_map" "lb_url_map" {
  name            = "my-lb-url-map"
  default_service = google_compute_backend_service.lb_backend_service.self_link
}

resource "google_compute_backend_service" "lb_backend_service" {
  name             = "my-lb-backend-service"
  protocol         = "HTTPS"
  timeout_sec      = 30
  port_name        = "https"
  enable_cdn       = true
  health_checks    = [google_compute_health_check.lb_health_check.self_link]
}

resource "google_compute_health_check" "lb_health_check" {
  name               = "my-lb-health-check"
  check_interval_sec = 5
  timeout_sec        = 5
  http_health_check {
    port       = 80
    request_path = "/"
  }
}
