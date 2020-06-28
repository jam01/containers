podman login quay.io

podman create -it -v $PWD:$PWD:Z -v /var/lib/containers:/var/lib/containers --privileged -w $PWD --name centos-buildah centos:8 /bin/bash
podman start centos-buildah
podman exec centos-buildah bash -c "yum update -y && yum install ncurses buildah -y"
podman exec centos-buildah bash -c "./openjdk/from-scratch.sh centos 8 jre 8"
podman exec centos-buildah bash -c "./openjdk/from-scratch.sh centos 8 jdk 8"
podman exec centos-buildah bash -c "./openjdk/from-scratch.sh centos 8 jre 11"
podman exec centos-buildah bash -c "./openjdk/from-scratch.sh centos 8 jdk 11"

podman exec centos-buildah bash -c "./mule-4/runtime/ee-from-scratch.sh centos 8 4.1.4 8"
podman exec centos-buildah bash -c "./mule-4/runtime/ee-from-scratch.sh centos 8 4.2.2 8"
podman exec centos-buildah bash -c "./mule-4/runtime/ee-from-scratch.sh centos 8 4.2.2 11"
podman exec centos-buildah bash -c "./mule-4/runtime/ee-from-scratch.sh centos 8 4.3.0 8"
podman exec centos-buildah bash -c "./mule-4/runtime/ee-from-scratch.sh centos 8 4.3.0 11"

podman exec centos-buildah bash -c "./mule-4/builder/from-scratch.sh 8"
podman exec centos-buildah bash -c "./mule-4/builder/from-scratch.sh 11"

podman stop --all
podman rm --all
