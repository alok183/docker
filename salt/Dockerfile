ARG BASE_IMAGE=centos:7
FROM $BASE_IMAGE
ENV container=docker
ARG SCRIPT_NAME
RUN yum update -y ;\
yum install unzip -y;\
systemctl enable named.service ;\
yum clean expire-cache ;\
mkdir -p /run/systemd/system;

RUN echo "name is $SCRIPT_NAME"
COPY *setup.sh /opt/

# VOLUME [ "/sys/fs/cgroup" ]
# ENTRYPOINT [ "sh","/opt/"$SCRIPT_NAME".sh" ]
