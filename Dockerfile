FROM fedora AS content-builder

ARG repo=https://github.com/jhrozek/content.git
ARG branch
ENV branch ${branch:-ek_ocp4}

RUN dnf -y install cmake make git python3-pyyaml python3-jinja2 openscap-utils \
    && rm -rf /var/cache/yum
RUN  git clone $repo
WORKDIR /content
COPY build-ocp4-content.sh .
RUN chmod u+x ./build-ocp4-content.sh && ./build-ocp4-content.sh

FROM fedora
WORKDIR /var/lib/content
COPY --from=content-builder /content/build/ssg-ocp4-ds.xml .
