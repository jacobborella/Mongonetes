#!/bin/bash
sudo yum update -y &&  sudo amazon-linux-extras install -y docker
sudo usermod -aG docker $USER
sudo reboot

