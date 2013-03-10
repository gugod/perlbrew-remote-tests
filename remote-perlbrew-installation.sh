#!/bin/bash

curl -kL http://install.perlbrew.pl | bash

source ~/perl5/perlbrew/etc/bashrc
hash -r

command which perlbrew
