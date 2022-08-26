#!/bin/bash

# example script to unlock and configure the snowcone itself

# Unlock the device, this requires the manifest and unlock code from AWS
snowballEdge unlock-device

# Determine the interface id of the physical network adapter
snowballEdge describe-device | jq -r '.PhysicalNetworkInterfaces[0].PhysicalNetworkInterfaceId'

# Create a virtual network adapter to attach to EC2 instances
snowballEdge create-virtual-network-interface --ip-address-assignment dhcp --physical-network-interface-id 's.ni-85b8a7143ffcee9ff'

# List available certificates on the snowcone
snowballEdge list-certificates

# Export the snowcone certificates
snowballEdge get-certificate --certificate-arn "arn:aws:snowball-device:::certificate/97ab5543859043f0a7678d21f02da550" > snowcone_cert.pem

# Add snowcone certificate to the system trust store and update
sudo cp snowcone_cert.pem /etc/pki/ca-trust/source/anchors/snowcone_cert.pem
sudo chown root.root /etc/pki/ca-trust/source/anchors/snowcone_cert.pem
sudo chmod 0644 /etc/pki/ca-trust/source/anchors/snowcone_cert.pem
sudo restorecon -v /etc/pki/ca-trust/source/anchors/snowcone_cert.pem
sudo update-ca-trust
sudo update-ca-trust extract

# List access keys
snowballEdge list-access-keys

# Get secret key associated with access key above
snowballEdge get-secret-access-key --access-key-id "access_key from above command"

# Create a key-pair for instances to use
snow create-key-pair --key-name danclark-snowcone

# Describe available AMIs
snow describe-images

# Launch and instance
#snc1.micro (1 CPU and 1 GB RAM), snc1.small (1 CPU and 2 GB RAM), and snc1.medium (2 CPU and 4 GB RAM).
snow run-instances --image-id s.ami-019808f1c0995a94a --key-name danclark-snowcone --instance-type snc1.medium

# Attach the virtual network device to the instance. Need to wait until the instance is in the right state
snow associate-address --public-ip 192.168.1.174 --instance-id s.i


