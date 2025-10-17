# -*- mode: ruby -*-
# vi: set ft=ruby :

# This Vagrantfile sets up a Docker container using Vagrant. It specifies 
# the build directory, container name, and ensures the container remains
# running after provisioning.
# To use this Vagrantfile, ensure you have Docker and Vagrant installed
# on your machine. Then, run `vagrant up` in the directory containing this 
# Vagrantfile to build and start the Docker container.
# Create a custom Docker network:
# docker network create \
#   --driver bridge \
#   --subnet 192.168.2.0/24 \
#   x_net

Vagrant.configure("2") do |config|
  config.vm.provider "docker" do |d|
    d.build_dir = "."
    d.name = "monit"
    d.create_args = [
      "--network", "x_net"
    ]
    d.remains_running = true
  end

  config.vm.provision "docker" do |p|
    p.run "monit"
  end
end
