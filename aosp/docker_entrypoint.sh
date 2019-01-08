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
if [ -z ${USER_NAME+x} ]; then USER_NAME="aosp"; fi
if [ -z ${GROUP_NAME+x} ]; then GROUP_NAME="aosp"; fi
if [ -z ${USER_PASSWD+x} ]; then USER_PASSWD="aosp"; fi

# ccache
export CCACHE_DIR=/tmp/ccache
export USE_CCACHE=1

# create user
msg="Init: Creating user UID:UNAME/GID:GNAME/PASSWD [$USER_ID:$USER_NAME/$GROUP_ID:$GROUP_NAME/$USER_PASSWD]" && echo -e "\033[34m$msg\033[0m\c"
groupadd -g $GROUP_ID -r $GROUP_NAME && \
useradd -u $USER_ID --create-home -r -p $USER_PASSWD -g $GROUP_NAME $USER_NAME
chown $USER_NAME:$GROUP_NAME /tmp/ccache /aosp
echo -e "\r\033[32m$msg - done\033[0m"

# copy configs
msg="Init: copy configs" && echo -e "\033[34m$msg\033[0m\c"
USER_HOME=/home/$USER_NAME
cp -rf /data/home/.ssh $USER_HOME/
cp -rf /data/home/.repoconfig $USER_HOME/
cp -rf /data/home/.gitconfig $USER_HOME/
chown -R $USER_NAME:$GROUP_NAME $USER_HOME/.ssh $USER_HOME/.repoconfig $USER_HOME/.gitconfig
chmod 600 $USER_HOME/.ssh/id_rsa

if [ ! -z "$PROJECT_PATH" ]; then
    mkdir -p $(dirname $PROJECT_PATH)
    ln -s /aosp $(dirname $PROJECT_PATH/null)
    chown $USER_NAME:$GROUP_NAME $PROJECT_PATH
    cd $PROJECT_PATH
fi
echo -e "\r\033[32m$msg - done\033[0m"

echo -e "\033[36m===============>\033[0m"
echo ""

# Default to 'bash' if no arguments are provided
args=$@
if [ -z "$args" ]; then
  args="bash"
fi

# save args as launch script
LAUNCH_SCRIPT=$USER_HOME/launch.sh
echo "$args" >> $LAUNCH_SCRIPT
chmod 777 $LAUNCH_SCRIPT

# init .bashrc
USER_BASHRC=$USER_NAME/.bashrc
echo "PS1_OLD=\$PS1" >> $USER_BASHRC
echo "PS1=\"[AOSP_ENV] \$PS1\"" >> $USER_BASHRC

# Execute command as `aosp` user
export HOME=$USER_HOME
exec sudo -E -u $USER_NAME $USER_HOME/launch.sh
