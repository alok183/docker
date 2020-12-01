#!/bin/bash

#Error handling function
function funErrorExit() {
  echo
  echo "ERROR: $${PROGNAME}: $${1:-"Unknown Error"}" 1>&2
  #Script End time
  scriptEndTime=$(date +%s)
  echo "---------------------------------"
  echo "completed with error"
  echo "script runtime: $((scriptEndTime - scriptStartTime))s "
  echo "---------------------------------"
  #  exit 1
}

add_repo() {

  echo "---------------------------------"
  echo "Running $${FUNCNAME[0]}"
  echo "---------------------------------"
  echo "Adding repo ..."
  distro=$(sed -n 's/^distroverpkg=//p' /etc/yum.conf) &&
    releasever=$(rpm -q --qf "%{version}" -f /etc/$distro) &&
    basearch=$(rpm -q --qf "%{arch}" -f /etc/$distro) &&
    echo "Retrieved os arch values for setting up salt repo" ||
    funErrorExit "$${FUNCNAME[0]}: Failed to get os arch values for salt repo"
  rpm --import https://repo.saltstack.com/${SALT_REPO}/redhat/7/x86_64/archive/${SALT_ARCH_RELEASE}/SALTSTACK-GPG-KEY.pub
  cat >/etc/yum.repos.d/saltstack.repo <<EOF
[saltstack-repo]
name=SaltStack repo for RHEL/CentOS $releasever
baseurl=https://repo.saltstack.com/${SALT_REPO}/redhat/$releasever/$basearch/archive/${SALT_ARCH_RELEASE}
enabled=1
gpgcheck=1
gpgkey=https://repo.saltstack.com/${SALT_REPO}/redhat/$releasever/$basearch/archive/${SALT_ARCH_RELEASE}/SALTSTACK-GPG-KEY.pub
EOF

}

master_conf() {
  echo "Installing salt-master ..."

  if [ "$SALT_REPO" = "py3" ]; then
    curl -SLO https://github.com/saltstack/salt-bootstrap/archive/develop.zip
    unzip develop.zip
    salt-bootstrap-develop/bootstrap-salt.sh -M -N -X -x python3
  else
    yum clean expire-cache &&
      yum install -y salt-master ||
      funErrorExit "$${FUNCNAME[0]}: Failed to install salt-master"
  fi
  #thorium configuration for automatic key removal
  cat >>/etc/salt/master <<EOF
engines:
  - thorium: {}
EOF
  mkdir -p /srv/thorium
  cat >/srv/thorium/key_clean.sls <<EOF
statreg:
  status.reg

keydel:
  key.timeout:
    - require:
      - status: statreg
    - delete: 3600
EOF
  cat >/srv/thorium/top.sls <<EOF
base:
  '*':
    - key_clean
EOF

  #reactor configuration for automatic key acceptance
  cat >/etc/salt/master.d/auto-accept.conf <<EOF
open_mode: True
auto_accept: True
EOF

  systemctl enable salt-master && systemctl start salt-master ||
    funErrorExit "$${FUNCNAME[0]}: Failed starting salt daemon"
  salt-key -L
  if [[ $? -eq 0 ]]; then
    echo "Salt master setup successful"
  else
    funErrorExit "$${FUNCNAME[0]}: Salt master setup failed"
  fi
}

############### minion ###########
minion_conf() {
  echo "Installing salt-minion ..."
  if [ "$SALT_REPO" = "py3" ]; then
    curl -SLO https://github.com/saltstack/salt-bootstrap/archive/develop.zip
    unzip develop.zip
    salt-bootstrap-develop/bootstrap-salt.sh -X -x python3.6
  else
    yum clean expire-cache &&
      yum install -y salt-minion ||
      funErrorExit "$${FUNCNAME[0]}: Failed to install salt-minion"
  fi
  cat >/etc/salt/minion.d/primary.conf <<EOF
master: salt-master
id: salt-minion-$(hostname)
EOF
  cat >>/etc/salt/minion <<EOF
beacons:
  status:
    - interval: 10
EOF

  systemctl enable salt-minion && systemctl start salt-minion ||
    funErrorExit "$${FUNCNAME[0]}: Salt-minion configuration failed"

}

/usr/lib/systemd/systemd --system &
# sleep 10
add_repo
# Variables from env
echo "Salt Role   :  $SALT_ROLE"
echo "Salt verssion   :  $SALT_ARCH_RELEASE"
echo "SALT_REPO    : $SALT_REPO"
if [ "$SALT_ROLE" = "salt-master" ]; then
  master_conf
fi
if [ "$SALT_ROLE" = "salt-minion" ]; then
  minion_conf
fi
#/usr/sbin/init
tail -f /dev/null
