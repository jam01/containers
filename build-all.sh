#!/usr/bin/bash

set -o nounset
set -o errexit

yum update -y
curl -OJ https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
yum install ncurses buildah ./epel-release-latest-*.noarch.rpm -y

./openjdk/from-scratch.sh centos 8 11
./openjdk/from-scratch.sh centos 8 14

./mule-4/runtime/ee-from-scratch.sh centos 8 4.2.2 11
./mule-4/runtime/ee-from-scratch.sh centos 8 4.2.2 14
./mule-4/runtime/ee-from-scratch.sh centos 8 4.3.0 11
./mule-4/runtime/ee-from-scratch.sh centos 8 4.3.0 14

buildah login --username jam01 --password $QUAY_PASSWD quay.io
for i in $(buildah images | grep 'quay.io/jam01' | awk '{print $1":"$2}')
do
  buildah push $i
done
