packer {
  required_plugins {
    virtualbox = {
      version = ">= 1.0.5"
      source  = "github.com/hashicorp/virtualbox"
    }
  }
}

source "virtualbox-ovf" "ubuntu_base" {
  # 1. Point this directly to the extracted OVF file from step 1
  source_path      = "/home/eran/Downloads/bento-extracted/box.ovf"
  
  # 2. VirtualBox connection credentials default for Bento templates
  ssh_username     = "vagrant"
  ssh_password     = "vagrant"
  shutdown_command = "echo 'vagrant' | sudo -S shutdown -P now"
  
  # 3. Tells packer to run headlessly (set to true) or show the GUI window (set to false)
  headless         = true
  
  # 4. Save format parameters
  output_directory = "output-custom-ubuntu"
}

build {
  sources = ["source.virtualbox-ovf.ubuntu_base"]

  # Run your custom mirror installation script
  provisioner "shell" {
    execute_command = "echo 'vagrant' | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    script          = "./setup.sh"
  }

  # This post-processor automatically packages the finished VirtualBox VM 
  # back into a flawless .box file for your Vagrant inventory!
  post-processor "vagrant" {
    output = "output-custom-ubuntu/package.box"
  }
}