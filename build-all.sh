#!/usr/bin/bash

podman login quay.io

podman create -it -v $PWD:$PWD:Z -v /var/lib/containers:/var/lib/containers --privileged -w $PWD --name centos-buildah centos:8 /bin/bash
podman start centos-buildah
podman exec centos-buildah bash -c "yum update -y && yum install buildah -y"
podman exec centos-buildah bash -c "./openjdk/openjdk-scratch.sh centos 8"
podman exec centos-buildah bash -c "./mule4/runtime/mule4-ee-scratch.sh centos 8 4.1.4 8"
podman exec centos-buildah bash -c "./mule4/runtime/mule4-ee-scratch.sh centos 8 4.1.4 11"
podman exec centos-buildah bash -c "./mule4/runtime/mule4-ee-scratch.sh centos 8 4.2.2 8"
podman exec centos-buildah bash -c "./mule4/runtime/mule4-ee-scratch.sh centos 8 4.2.2 11"
podman exec centos-buildah bash -c "./mule4/runtime/mule4-ee-scratch.sh centos 8 4.3.0 8"
podman exec centos-buildah bash -c "./mule4/runtime/mule4-ee-scratch.sh centos 8 4.3.0 11"
podman exec centos-buildah bash -c "./mule4/builder/mule4-builder.sh"

# podman create -it -v $PWD:$PWD:Z -v /var/lib/containers:/var/lib/containers --privileged -w $PWD --name fedora-buildah fedora:29 /bin/bash
# podman start fedora-buildah
# podman exec fedora-buildah bash -c "dnf upgrade -y && dnf install buildah ncurses -y"
# podman exec fedora-buildah bash -c "./openjdk/openjdk-scratch.sh fedora 29"
# podman exec fedora-buildah bash -c "./mule4/builder/mule4-builder.sh"
# podman exec fedora-buildah bash -c "./mule4/runtime/mule4-ee-scratch.sh fedora 29 4.1.4"

podman stop --all
podman rm --all

# podman push quay.io/jam01/openjdk:8u{version}-jre-slim-centos
# podman push quay.io/jam01/openjdk:8-jre-slim-centos

# podman push quay.io/jam01/mule4-ee:4.1.4-centos-openjdk
# podman push quay.io/jam01/mule4-ee:4.1.4-centos-openjdk-jaeger

# podman tag quay.io/jam01/openjdk:8-jre-slim-fedora quay.io/jam01/openjdk:latest
# podman push quay.io/jam01/openjdk:8u{version}-jre-slim-fedora
# podman push quay.io/jam01/openjdk:8-jre-slim-fedora
# podman push quay.io/jam01/openjdk:latest

# podman tag quay.io/jam01/mule4-ee:4.1.4-fedora-openjdk quay.io/jam01/mule4-ee:latest
# podman tag quay.io/jam01/mule4-ee:4.1.4-fedora-openjdk-jaeger quay.io/jam01/mule4-ee:latest-jaeger
# podman push quay.io/jam01/mule4-ee:4.1.4-fedora-openjdk
# podman push quay.io/jam01/mule4-ee:4.1.4-fedora-openjdk-jaeger
