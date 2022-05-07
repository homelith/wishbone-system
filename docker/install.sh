#!/bin/bash

INTERNAL_USER=guser
GOWIN_TOOL_VERSION=1.9.8
GOWIN_ROOT_DIR=/opt/Gowin
INSTALLER_DIR=/opt/install_files
INSTALLER_DOWNLOAD_URI=http://cdn.gowinsemi.com.cn/Gowin_V1.9.8_linux.tar.gz
INSTALLER_ARCHIVE=Gowin_V1.9.8_linux.tar.gz

# check if installer file and download it
if [ ! -f ${INSTALLER_DIR}/${INSTALLER_ARCHIVE} ]; then
    echo "no '${INSTALLER_DIR}/${INSTALLER_ARCHIVE}' found, downloading from gowin official..."
    sudo wget -O ${INSTALLER_DIR}/${INSTALLER_ARCHIVE} ${INSTALLER_DOWNLOAD_URI}
else
    echo "use existing '${INSTALLER_DIR}/${INSTALLER_ARCHIVE}'"
fi

# prepare workdir
#WORK_DIR=installer_temp
#mkdir -p ${WORK_DIR}
#cd ${WORK_DIR}

# extract toolchain
echo "prepare ${GOWIN_ROOT_DIR}/${GOWIN_TOOL_VERSION}"
sudo mkdir -p ${GOWIN_ROOT_DIR}/${GOWIN_TOOL_VERSION}
echo "extracting toolchain ..."
sudo tar zxf ${INSTALLER_DIR}/${INSTALLER_ARCHIVE} -C ${GOWIN_ROOT_DIR}/${GOWIN_TOOL_VERSION}
echo "changing toolchain owner to root ..."
sudo chown root:root -R ${GOWIN_ROOT_DIR}/${GOWIN_TOOL_VERSION}
echo "changing permission on gwlicense.ini ..."
sudo chmod 777 ${GOWIN_ROOT_DIR}/${GOWIN_TOOL_VERSION}/IDE/bin/gwlicense.ini
echo "changing permission on programmer db ..."
sudo chmod 777 -R ${GOWIN_ROOT_DIR}/${GOWIN_TOOL_VERSION}/Programmer/bin/data

# introduce PATH
source /root/settings.sh
