#!/bin/bash
OS=`uname`
KIVY=`which kivy`

# utility variables
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
magenta=`tput setaf 5`
cyan=`tput setaf 6`
white=`tput setaf 7`
reset=`tput sgr0`

function header { echo "${yellow}====[ ${blue}${1} ${yellow}]====${reset}"; }
function info { echo "${yellow}==> ${white}${1}${reset}"; }
function error { echo "${yellow}==> ${red}${1}${reset}"; exit 1; }



function install_linux {
    if [ "$(whoami)" != "root" ]; then
        sudo su -s "$0"
        exit
    fi
    function install_package {
        PACKAGE_MANAGER=`which apt-get`
        if [[ ! -z "${PACKAGE_MANAGER}" ]]; then
            ${PACKAGE_MANAGER} --yes --force-yes install ${@} || \
                error "could not install ${@}!"
        fi
    }
    function install_package_repo {
        if [[ ! -z "$(which add-apt-repository)" ]]; then
            sudo add-apt-repository -y ${1} && \
            sudo apt-get -y update || \
                error "could not add repo ${1}!"
        fi
    }
    header "Installing for Linux"
    export DISPLAY=:0

    if [[ -z "$( which pip )" ]]; then
        install_package python-pip \
                        python-dev
    fi
    if [[ -z "$( which gcc )" ]]; then
        install_package build-essential
    fi
    if [[ -z "$( which mkimage )" ]]; then
        install_package u-boot-tools
    fi
    if [[ -z "$(which git)" ]]; then
        install_package git
    fi
    if [[ -z "$(which gksu)" ]]; then
        install_package gksu
    fi
    if [[ -z "$(which fastboot)" ]]; then
        install_package android-tools-fastboot
    fi
    if [[ -z "img2simg" ]]; then
        install_package android-tools-fsutils
    fi
    
    PIP=`which pip`

    if [[ -z "$( which kivy )" ]]; then
        install_package python-kivy
        sudo ln -s /usr/bin/python2.7 /usr/local/bin/kivy
    fi
    if [[ -z "$( ${PIP} show libusb1)" ]]; then
        ${PIP} install libusb1 || error "could not install libusb1!"
    fi
    if [[ -z "$( ${PIP} show flask)" ]]; then
        ${PIP} install flask || error "could not install flask!"
    fi
    if [[ -z "$( ${PIP} show flask-socketio)" ]]; then
        ${PIP} install flask-socketio || error "could not install flask-socketio!"
    fi
    if [[ -z "$( ${PIP} show eventlet)" ]]; then
        ${PIP} install eventlet || error "could not install eventlet!"
    fi
}

function install_flasher {
    if [[ ! -d "CHIP-flasher" ]]; then
        git clone --branch=autodetect https://github.com/NextThingCo/CHIP-flasher
    else
        pushd CHIP-flasher
        git pull
        popd
    fi
    cd CHIP-flasher/flasher
    
    if [[ ! -d "tools" ]]; then
        mdkir tools
        cd tools
        if [[ ! -d "sunxi-tools" ]]; then
            git clone https://github.com/NextThingCo/sunxi-tools
            make -C sunxi-tools fel
            ln -s "sunxi-tools/fel" /usr/local/bin/fel
        fi
        if [[ ! -d "CHIP-tools" ]]; then
            git clone https://github.com/NextThingCo/CHIP-tools
        fi
    fi

    if [[ "$(uname)" == "Linux" ]]; then
        SCRIPTDIR="$(dirname $(readlink -e $0) )" #/flasher"
        HOMEDIR="$(eval echo "~${SUDO_USER}")"
        sed -i.bak "s%^\(Icon=\).*%\1${SCRIPTDIR}/logo.png%" $SCRIPTDIR/chip-flasher.desktop
        sed -i.bak "s%^\(Exec=\).*%\1${SCRIPTDIR}/start.sh%" $SCRIPTDIR/chip-flasher.desktop
        cp ${SCRIPTDIR}/chip-flasher.desktop ${HOMEDIR}/Desktop
        chown $(logname):$(logname) ${HOMEDIR}/Desktop/chip-flasher.desktop
        chown -R $(logname):$(logname) ${SCRIPTDIR}
        usermod -a -G dialout "${SUDO_USER}"
        usermod -a -G dialout "${SUDO_USER}"

    fi
}

case "${OS}" in
    Linux)  install_linux; install_flasher ;;
esac



#apt-get install python-kivy python-serial
#ln -s /usr/bin/python2.7 /usr/local/bin/kivy
#ln -s ~/Desktop/CHIP-tools ~/Desktop/CHIP-flasher/flasher/tools

#for web
#apt-get install python-dev
#pip install flask
#pip install flask-socketio
#pip install eventlet
#https://github.com/miguelgrinberg/Flask-SocketIO/issues/184