#!/bin/bash
sudo yum group install "Development Tools"

wget http://ftp.gnu.org/gnu/automake/automake-1.14.tar.gz
tar xvzf automake-1.14.tar.gz
cd automake-1.14
./configure
make
sudo make install
sudo cp /bin/automake /usr/local/bin

cd
wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-1.6.tar.gz
tar -xzf jq-1.6.tar.gz
cd jq-1.6
automake
autoreconf -fi && ./configure --disable-maintainer-mode && make && make install
jq --version
