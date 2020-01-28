FROM centos:8 AS content-builder

ARG repo="https://github.com/ComplianceAsCode/content"
ARG branch="master"

RUN dnf -y install cmake make git /usr/bin/python3 python3-pyyaml python3-jinja2 openscap-utils \
    && rm -rf /var/cache/yum
RUN  git clone $repo content
WORKDIR /content
COPY build-ocp4-content.sh .
RUN chmod u+x ./build-ocp4-content.sh && ./build-ocp4-content.sh

FROM registry.access.redhat.com/ubi8/ubi-minimal
WORKDIR /
COPY --from=content-builder /content/build/ssg-ocp4-ds.xml .
