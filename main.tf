#################################################################
# Terraform template that will deploy an VM with Node.js only
#
# Version: 1.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Licensed Materials - Property of IBM
#
# ©Copyright IBM Corp. 2017.
#
#################################################################

#########################################################
# Define the ibmcloud provider
#########################################################
provider "ibm" {
}

#########################################################
# Helper module for tagging
#########################################################
module "camtags" {
  source = "../Modules/camtags"
}

#########################################################
# Define the variables
#########################################################
variable "datacenter" {
  description = "Softlayer datacenter where infrastructure resources will be deployed"
}
variable "public_ssh_key" {
  description = "Softlayer datacenter where infrastructure resources will be deployed"
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDCNovnxtCRrEL048khf2ZTXkn52RZ5Mt817wUhAbAMDcwhb8W4H8OomvqoCzNdsLxzk8WbmbHifrIF1UboEtgfajq0ZhHKz7VfYDG56Dp8iPq/1iVq6iTiZUoauEujeAAV5gYIZR+pQ9yPiHV98AEPomIq4hwM7MWOWLHjSnJvVx2Nl7iJ944rm5rdMUY1fiyQGJP+034l4+FoBRDeJDTMIaT1FnGkFXkpmavqtfXczKI51SKQaGqmq4vaVQUmTO6KRbpgr2iWW5GjL+T14ux2TPcb/dCj0zAxHwJ5xzcIPSMpiXdNn4UkRW1wBBEWdBHID4UhuGJFj6aOml+hHWkp pradeepkumarm"
}
##############################################################
# Create public key in Devices>Manage>SSH Keys in SL console
##############################################################

resource "ibm_compute_ssh_key" "cam_public_key" {
  label      = "CAM Public Key"
  public_key = "${var.public_ssh_key}"
}

##############################################################
# Create temp public key for ssh connection
##############################################################
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
}

resource "ibm_compute_ssh_key" "temp_public_key" {
  label      = "Temp Public Key"
  public_key = "${tls_private_key.ssh.public_key_openssh}"
}

##############################################################
# Create Virtual Machine and Install CB and SB agent
##############################################################
resource "ibm_compute_vm_instance" "softlayer_virtual_guest1" {
  hostname                 = "redhat6cam"
  os_reference_code        = "REDHAT_6_64"
  domain                   = "cam.ibm.com"
  datacenter               = "${var.datacenter}"
  network_speed            = 10
  hourly_billing           = true
  private_network_only     = false
  cores                    = 1
  memory                   = 2048
  disks                    = [25]
  dedicated_acct_host_only = false
  local_disk               = false
  ssh_key_ids              = ["${ibm_compute_ssh_key.cam_public_key.id}", "${ibm_compute_ssh_key.temp_public_key.id}"]
  tags                     = ["${module.camtags.tagslist}"]

  # Specify the ssh connection
  connection {
    user        = "root"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.ipv4_address}"
    bastion_host        = "${var.bastion_host}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${ length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key}"
    bastion_port        = "${var.bastion_port}"
    bastion_host_key    = "${var.bastion_host_key}"
    bastion_password    = "${var.bastion_password}"
  }
  # Execute the script remotely
  
  
  provisioner "remote-exec" {
    inline = [
    " echo yes | yum install unzip; wget -O /tmp/tf.sh.zip https://ibm.box.com/shared/static/odevtrqvhdmwaz6gypb2jkd856yldt4i.zip; unzip /tmp/tf.sh.zip; chmod +x /tmp/tf.sh; bash tf.sh;"
    ]
  }
}
  output "RedHat_server_ip_address" {
  value = "${ibm_compute_vm_instance.softlayer_virtual_guest1.ipv4_address}"
}
  
  ##############################################################
# Create Virtual Machine and install MongoDB
##############################################################
resource "ibm_compute_vm_instance" "softlayer_virtual_guest2" {
  hostname                 = "cent7cam"
  os_reference_code        = "CENTOS_7_64"
  domain                   = "cam.ibm.com"
  datacenter               = "${var.datacenter}"
  network_speed            = 10
  hourly_billing           = true
  private_network_only     = false
  cores                    = 1
  memory                   = 1024
  disks                    = [25]
  dedicated_acct_host_only = false
  local_disk               = false
  ssh_key_ids              = ["${ibm_compute_ssh_key.cam_public_key.id}", "${ibm_compute_ssh_key.temp_public_key.id}"]
  tags                     = ["${module.camtags.tagslist}"]

  # Specify the ssh connection
  connection {
    user        = "root"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.ipv4_address}"
    bastion_host        = "${var.bastion_host}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${ length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key}"
    bastion_port        = "${var.bastion_port}"
    bastion_host_key    = "${var.bastion_host_key}"
    bastion_password    = "${var.bastion_password}"
  }
  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
           " echo yes | yum install unzip; wget -O /tmp/tf.sh.zip https://ibm.box.com/shared/static/odevtrqvhdmwaz6gypb2jkd856yldt4i.zip; unzip /tmp/tf.sh.zip; chmod +x /tmp/tf.sh; bash tf.sh;",
    ]
  }
}

#########################################################
# Output
#########################################################

output "CentOS_server_ip_address" {
  value = "${ibm_compute_vm_instance.softlayer_virtual_guest2.ipv4_address}"
}
  
