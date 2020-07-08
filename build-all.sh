 #!/usr/bin/bash
 
 set -o nounset
 set -o errexit

 yum update -y && yum install ncurses buildah -y
./openjdk/from-scratch.sh centos 8 jre 8
./openjdk/from-scratch.sh centos 8 jdk 8
./openjdk/from-scratch.sh centos 8 jre 11
./openjdk/from-scratch.sh centos 8 jdk 11

./mule-4/runtime/ee-from-scratch.sh centos 8 4.1.4 8
./mule-4/runtime/ee-from-scratch.sh centos 8 4.2.2 8
./mule-4/runtime/ee-from-scratch.sh centos 8 4.2.2 11
./mule-4/runtime/ee-from-scratch.sh centos 8 4.3.0 8
./mule-4/runtime/ee-from-scratch.sh centos 8 4.3.0 11

buildah login --username jam01 --password $QUAY_PASSWD quay.io
for i in $(buildah images | grep 'quay.io/jam01' | awk '{print $1":"$2}')
do
  buildah push $i
done
