#!/bin/bash
set -e

# This script designed to be used a docker ENTRYPOINT "workaround" missing docker
# feature discussed in docker/docker#7198, allow to have executable in the docker
# container manipulating files in the shared volume owned by the USER_ID:GROUP_ID.
#
# It creates a user named `aosp` with selected USER_ID and GROUP_ID (or
# 1000 if not specified).

# Example:
#
#  docker run -ti -e USER_ID=$(id -u) -e GROUP_ID=$(id -g) imagename bash
#

# Reasonable defaults if no USER_ID/GROUP_ID environment variables are set.
if [ -z ${USER_ID+x} ]; then USER_ID=1000; fi
if [ -z ${GROUP_ID+x} ]; then GROUP_ID=1000; fi

# ccache
export CCACHE_DIR=/tmp/ccache
export USE_CCACHE=1

msg="docker_entrypoint: Creating user UID/GID [$USER_ID/$GROUP_ID]" && echo -e "$msg\c"
groupadd -g $GROUP_ID -r aosp && \
useradd -u $USER_ID --create-home -r -p aosp -g aosp aosp
chown aosp:aosp /tmp/ccache /aosp
echo -e "\r$msg - done"

#msg="docker_entrypoint: Copying .gitconfig and .ssh/config to new user home" && echo $msg
#cp /root/.gitconfig /home/aosp/.gitconfig && \
#chown aosp:aosp /home/aosp/.gitconfig && \
#mkdir -p /home/aosp/.ssh && \
#cp /root/.ssh/config /home/aosp/.ssh/config && \
#chown aosp:aosp -R /home/aosp/.ssh &&
#echo "$msg - done"

msg="copy configs" && echo -e "$msg\c"
cp -rf /data/home/.ssh /home/aosp/
cp -rf /data/home/.repoconfig /home/aosp/
cp -rf /data/home/.gitconfig /home/aosp/
chown -R aosp:aosp /home/aosp/.ssh /home/aosp/.repoconfig /home/aosp/.gitconfig
chmod 600 /home/aosp/.ssh/id_rsa

if [ ! -z "$REAL_PATH" ]; then
    mkdir -p $(dirname $REAL_PATH)
    ln -s /aosp $REAL_PATH
    chown aosp:aosp $REAL_PATH
    cd $REAL_PATH
fi
echo -e "\r$msg - done"

echo "===============>"
echo ""

# Default to 'bash' if no arguments are provided
args=$@
if [ -z "$args" ]; then
  args="bash"
fi

# save args as launch script
echo "export PS1=\"[aosp] \$PS1\"" > /home/aosp/launch.sh
echo "$args" >> /home/aosp/launch.sh
chmod 777 /home/aosp/launch.sh

# Execute command as `aosp` user
export HOME=/home/aosp
exec sudo -E -u aosp /home/aosp/launch.sh
