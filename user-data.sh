#!/bin/bash

sudo apt-get update

sudo apt-get install -y apache2

# Start Apache and enable it on boot

sudo service apache2 start
