#!/bin/bash
wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
chmod +x jq-linux64
mv jq-linux64 jq
sudo cp jq /usr/local/bin/

