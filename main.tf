provider "alicloud" {
   access_key = var.access_key
   secret_key = var.secret_key
   region     = "me-central-1"
}

data "alicloud_zones" "avail_zones" {
   available_resource_creation = "VSwitch"
}

resource "alicloud_vpc" "vpc-ali" {
    vpc_name = "vpc-ali"
    cidr_block = "10.0.0.0/8"
}

# Vswitches
resource "alicloud_vswitch" "public" {
    vswitch_name = "public vswitch"
    vpc_id       = alicloud_vpc.vpc-ali.id
    cidr_block   = "10.0.1.0/24"
    zone_id      = data.alicloud_zones.avail_zones.zones.0.id
}

resource "alicloud_vswitch" "private" {
    vswitch_name = "private vswitch"
    vpc_id       = alicloud_vpc.vpc-ali.id
    cidr_block   = "10.0.2.0/24"
    zone_id      = data.alicloud_zones.avail_zones.zones.0.id
}

resource "alicloud_instance" "web-app" {
  availability_zone          = data.alicloud_zones.avail_zones.zones.0.id
  security_groups            = [alicloud_security_group.web-app.id]

  instance_type              = "ecs.g6.large"
  system_disk_category       = "cloud_essd"
  system_disk_size           = 40
  image_id                   = "ubuntu_24_04_x64_20G_alibase_20240812.vhd"
  instance_name              = "web-app"
  vswitch_id                 = alicloud_vswitch.public.id
  internet_max_bandwidth_out = 100
  internet_charge_type       = "PayByBandwidth"
  instance_charge_type       = "PostPaid"
  status                     = "Running"
  key_name                   = alicloud_ecs_key_pair.my_priv_key.id
  user_data                  = base64encode(file("web_startup.sh"))
}

output "public_ip" {
  value = alicloud_instance.web-app.public_ip
}

resource "alicloud_ecs_key_pair" "my_priv_key" {
  key_pair_name = "my_priv_key"
  key_file      = "my_priv_key"
}

resource "alicloud_security_group" "web-app" {
  name = "web"
  vpc_id = alicloud_vpc.vpc-ali.id
}

resource "alicloud_security_group_rule" "allow_ssh_to_web" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "22/22"
  cidr_ip           = "0.0.0.0/0"
  priority          = 1
  security_group_id = alicloud_security_group.web-app.id
}

resource "alicloud_security_group_rule" "allow_http_to_web" {
  type               = "ingress"
  ip_protocol        = "tcp"
  policy             = "accept"
  port_range         = "80/80"
  cidr_ip            = "0.0.0.0/0"
  priority           = 1
  security_group_id  = alicloud_security_group.web-app.id
}
