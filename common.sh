#!/usr/bin/env bash

set -euo pipefail

RED="31"
GREEN="32"
BOLDRED="\e[1;${RED}m"
BOLDGREEN="\e[1;${GREEN}m"
ENDCOLOR="\e[0m"

DEPENDENCIES=./.deps
ALACRITTY_DEPENDENCIES_DIR=${DEPENDENCIES}/alacritty
POLYBAR_DEPENDENCIES_DIR=${DEPENDENCIES}/polybar
POWERLEVEL10K_DEPENDENCIES_DIR=${DEPENDENCIES}/powerlevel10k
FONTS_DEPENDENCIES_DIR=${DEPENDENCIES}/fonts
BTOP_DEPENDENCIES_DIR=${DEPENDENCIES}/btop
TMUX_DEPENDENCIES_DIR=${DEPENDENCIES}/tmux
LAZYGIT_DEPENDENCIES_DIR=${DEPENDENCIES}/lazygit
I3_GAPS_DEPENDENCIES_DIR=${DEPENDENCIES}/i3-gaps
I3LOCK_COLOR_DEPENDENCIES_DIR=${DEPENDENCIES}/i3lock-color
XCB_DEPENDENCIES_DIR=${DEPENDENCIES}/xcb
PICOM_DEPENDENCIES_DIR=${DEPENDENCIES}/picom
VSCODE_DEPENDENCIES_DIR=${DEPENDENCIES}/vscode-latest.deb

SETTINGS=./settings/
I3_SETTINGS_DIR=${SETTINGS}/i3
POLYBAR_SETTINGS_DIR=${SETTINGS}/polybar
I3LOCK_COLOR_SETTINGS_DIR=${SETTINGS}/i3lock
DUNST_SETTINGS_DIR=${SETTINGS}/dunst
TMUX_SETTINGS_FILE=${SETTINGS}/tmux/tmux.conf
ALACRITTY_SETTINGS_DIR=${SETTINGS}/alacritty
RANGER_SETTINGS_DIR=${SETTINGS}/ranger
PICOM_SETTINGS_DIR=${SETTINGS}/picom
ROFI_THEME_FILE=${SETTINGS}/rofi/nord.rasi

ALACRITTY_CONFIG=$(realpath -m ~/.config/alacritty)
ROFI_CONFIG=$(realpath -m ~/.config/rofi)
RANGER_CONFIG=$(realpath -m ~/.config/ranger)
TMUX_CONFIG_FILE=$(realpath -m ~/.tmux.conf)
I3_CONFIG=$(realpath -m ~/.config/i3)
I3LOCK_COLOR_CONFIG=$(realpath -m ~/.config/i3lock)
VSCODE_CONFIG=$(realpath -m ~/.config/Code/User)
DUNST_CONFIG=$(realpath -m ~/.config/dunst)
POLYBAR_CONFIG=$(realpath -m ~/.config/polybar)
PICOM_CONFIG=$(realpath -m ~/.config/picom)

DEFAULT_BG=./wallpapers/bg_001.jpg
WALLPAPERS_STORAGE=$(realpath -m ~/.wallpaper.jpg)

function generate_backup() {
    local path=$1

    if [[ -d "${path}" ]]; then
        echo -e "${BOLDGREEN}generating backup "${path}"...${ENDCOLOR}"}

        local dirname=$(dirname ${path})
        local basename=$(basename ${path})
        local index=$(find ${dirname} -maxdepth 1 -iname "${basename}*" | wc -l)
        cp -r ${path} ${path}.bak.${index}
    fi
}

function install_required_packages() {
    sudo apt update -y
    sudo apt install -y \
        libcanberra-gtk-module libcanberra-gtk3-module libjsoncpp-dev build-essential                                \
        xcb libxcb-composite0-dev libxcb1-dev libxcb-keysyms1-dev libpango1.0-dev libxcb-util0-dev libxcb-icccm4-dev \
        libyajl-dev libstartup-notification0-dev libxcb-randr0-dev libev-dev libxcb-cursor-dev libxcb-xinerama0-dev  \
        libxcb-xrm0 libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev autoconf xutils-dev dh-autoreconf unzip git \
        libxcb-xrm-dev x11-xserver-utils compton rofi binutils gcc make cmake pkg-config fakeroot python3            \
        python3-xcbgen xcb-proto libxcb-ewmh-dev wireless-tools libiw-dev libasound2-dev libpulse-dev libxcb-shape0  \
        libxcb-shape0-dev libcurl4-openssl-dev libmpdclient-dev pavucontrol python3-pip rxvt-unicode compton         \
        ninja-build meson python3 curl playerctl
}

function install_package() {
    local readonly package_name=$1

    echo -e "${BOLDGREEN}installing ${package_name}...${ENDCOLOR}"

    sudo apt install -y "${package_name}"
}

function install_pip_package() {
    local readonly package_name=$1

    echo -e "${BOLDGREEN}installing ${package_name}...${ENDCOLOR}"

    pip install "${package_name}"
}

function install_i3_gaps() {
    echo -e "${BOLDGREEN}installing i3 gaps...${ENDCOLOR}"

    if [[ ! -d "${I3_GAPS_DEPENDENCIES_DIR}" ]]; then
        git clone https://github.com/Airblader/i3 ${I3_GAPS_DEPENDENCIES_DIR}
    fi

    pushd "${I3_GAPS_DEPENDENCIES_DIR}"
        rm -rf build/
        mkdir -p build
        pushd build
            meson --prefix /usr/local
            ninja
            sudo ninja install
        popd
    popd
}

function install_i3lock() {
    echo -e "${BOLDGREEN}installing i3lock-color...${ENDCOLOR}"

    sudo apt install -y autoconf gcc make pkg-config libpam0g-dev libcairo2-dev libfontconfig1-dev \
        libxcb-composite0-dev libev-dev libx11-xcb-dev libxcb-xkb-dev libxcb-xinerama0-dev         \
        libxcb-randr0-dev libxcb-image0-dev libxcb-util0-dev libxcb-xrm-dev libxkbcommon-dev       \
        libxkbcommon-x11-dev libjpeg-dev

    if [[ ! -d "${I3LOCK_COLOR_DEPENDENCIES_DIR}" ]]; then
        git clone https://github.com/Raymo111/i3lock-color.git ${I3LOCK_COLOR_DEPENDENCIES_DIR}
    fi

    pushd "${I3LOCK_COLOR_DEPENDENCIES_DIR}"
        ./build.sh
        ./install-i3lock-color.sh
    popd
}

function install_polybar() {
    echo -e "${BOLDGREEN}installing polybar...${ENDCOLOR}"

    sudo apt install cmake cmake-data pkg-config python3-sphinx libcairo2-dev libxcb1-dev \
        libxcb-util0-dev libxcb-randr0-dev libxcb-composite0-dev python3-xcbgen xcb-proto \
        libxcb-image0-dev libxcb-ewmh-dev libxcb-icccm4-dev libxcb-xkb-dev libxcb-xrm-dev \
        libxcb-cursor-dev libasound2-dev libpulse-dev libjsoncpp-dev libmpdclient-dev \
        libcurl4-openssl-dev libnl-genl-3-dev libuv1-dev

    if [[ ! -d "${POLYBAR_DEPENDENCIES_DIR}" ]]; then
        echo -e "${BOLDGREEN}downloading polybar...${ENDCOLOR}"
        git clone --recursive https://github.com/polybar/polybar "${POLYBAR_DEPENDENCIES_DIR}"
    fi

    pushd "${POLYBAR_DEPENDENCIES_DIR}"
        rm -rf build/
        mkdir build/
        pushd build/
            cmake ..
            make -j$(nproc)
            sudo make install
        popd
    popd
}

function install_picom() {
    if [[ ! -d ${PICOM_DEPENDENCIES_DIR} ]]; then
        echo -e "${BOLDGREEN}downloading picom...${ENDCOLOR}"

        git clone https://github.com/ibhagwan/picom.git ${PICOM_DEPENDENCIES_DIR}
        pushd ${PICOM_DEPENDENCIES_DIR}
            git submodule update --init --recursive
        popd
    fi

    if ! command -v picom &> /dev/null; then
        echo -e "${BOLDGREEN}installing picom...${ENDCOLOR}"

        sudo apt install -y meson libxext-dev libxcb1-dev libxcb-damage0-dev libxcb-xfixes0-dev \
            libxcb-shape0-dev libxcb-render-util0-dev libxcb-render0-dev libxcb-randr0-dev \
            libxcb-composite0-dev libxcb-image0-dev libxcb-present-dev libxcb-xinerama0-dev \
            libpixman-1-dev libdbus-1-dev libconfig-dev libgl1-mesa-dev libpcre2-dev libevdev-dev \
            uthash-dev libev-dev libx11-xcb-dev libxcb-glx0-dev

        pushd ${PICOM_DEPENDENCIES_DIR}
            meson --buildtype=release . build
            ninja -C build
            sudo ninja -C build install
        popd
    fi
}

function install_vscode() {
    echo -e "${BOLDGREEN}installing vscode...${ENDCOLOR}"

    wget https://update.code.visualstudio.com/latest/linux-deb-x64/stable -O "${VSCODE_DEPENDENCIES_DIR}"
    sudo dpkg -i "${VSCODE_DEPENDENCIES_DIR}"

    echo -e "${BOLDGREEN}configuring vscode...${ENDCOLOR}"

    pushd ./vscode/
        mkdir -p "${VSCODE_CONFIG}"
        cp settings.json keybindings.json "${VSCODE_CONFIG}"
        cat extensions.txt | xargs -n 1 code --install-extension
    popd
}

function install_rust() {
    echo -e "${BOLDGREEN}installing rustup...${ENDCOLOR}"

    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    source ${HOME}/.cargo/env

    echo -e "${BOLDGREEN}updating rust...${ENDCOLOR}"
    rustup default nightly && rustup update
}

function install_alacritty() {
    echo -e "${BOLDGREEN}installing alacritty...${ENDCOLOR}"

    sudo apt-get install -y cmake pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev \
        autotools-dev automake libncurses-dev

    if [[ ! -d ${ALACRITTY_DEPENDENCIES_DIR} ]]; then
        echo -e "${BOLDGREEN}downloading alacritty...${ENDCOLOR}"

        git clone https://github.com/alacritty/alacritty.git ${ALACRITTY_DEPENDENCIES_DIR}
    fi

    pushd ${ALACRITTY_DEPENDENCIES_DIR}
        cargo build --release
        #infocmp alacritty &> /dev/null
        sudo cp target/release/alacritty /usr/local/bin
    popd
}

function install_btop() {
    echo -e "${BOLDGREEN}installing btop...${ENDCOLOR}"

    mkdir -p "${BTOP_DEPENDENCIES_DIR}"
    wget https://github.com/aristocratos/btop/releases/download/v1.1.4/btop-x86_64-linux-musl.tbz -P "${BTOP_DEPENDENCIES_DIR}"
    pushd "${BTOP_DEPENDENCIES_DIR}"
        tar -xvjf btop-x86_64-linux-musl.tbz
        bash install.sh
    popd
}

function install_dockly() {
    echo -e "${BOLDGREEN}installing dockly...${ENDCOLOR}"

    if ! command -v npm &> /dev/null; then
        curl -o- https://deb.nodesource.com/setup_18.x -o nodesource_setup.sh | sudo bash
        sudo apt-get install -y nodejs
    fi

    sudo npm install -g dockly
}

function install_lazygit() {
    echo -e "${BOLDGREEN}installing lazygit...${ENDCOLOR}"

    mkdir -p "${LAZYGIT_DEPENDENCIES_DIR}"
    wget https://github.com/jesseduffield/lazygit/releases/download/v0.34/lazygit_0.34_Linux_x86_64.tar.gz -P "${LAZYGIT_DEPENDENCIES_DIR}"
    pushd "${LAZYGIT_DEPENDENCIES_DIR}"
        tar -xf lazygit_0.34_Linux_x86_64.tar.gz
        sudo cp lazygit /usr/local/bin
    popd
}

function install_tmux() {
    echo -e "${BOLDGREEN}installing tmux...${ENDCOLOR}"

    sudo apt install -y libevent-dev bison byacc

    if [[ ! -d "${TMUX_DEPENDENCIES_DIR}" ]]; then
        git clone https://github.com/tmux/tmux.git "${TMUX_DEPENDENCIES_DIR}"
    fi

    pushd "${TMUX_DEPENDENCIES_DIR}"
        git checkout 3.2

        sh autogen.sh
        ./configure
        make

        sudo mv tmux /usr/bin
    popd
}

function install_firefox() {
    echo -e "${BOLDGREEN}installing firefox...${ENDCOLOR}"
    wget -O ~/FirefoxSetup.tar.bz2 "https://download.mozilla.org/?product=firefox-latest&os=linux64"
    sudo tar xjf ~/FirefoxSetup.tar.bz2 -C /opt/
    rm ~/FirefoxSetup.tar.bz2
    sudo mv /usr/bin/firefox /usr/bin/firefox_backup
    sudo ln -s /opt/firefox/firefox /usr/bin/firefox
}

function install_powerlevel10k() {
    echo -e "${BOLDGREEN}installing powerlevel10k...${ENDCOLOR}"

    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${POWERLEVEL10K_DEPENDENCIES_DIR}"
    sudo rm -rf /usr/local/share/powerlevel10k/
    sudo cp -r "${POWERLEVEL10K_DEPENDENCIES_DIR}" /usr/local/share/powerlevel10k
    echo "source /usr/local/share/powerlevel10k/powerlevel10k.zsh-theme" >> ~/.zshrc
}

function install_bat() {
    echo -e "${BOLDGREEN}installing bat...${ENDCOLOR}"

    wget https://github.com/sharkdp/bat/releases/download/v0.18.3/bat_0.18.3_amd64.deb -P ${DEPENDENCIES}
    sudo dpkg -i ${DEPENDENCIES}/bat_0.18.3_amd64.deb
}

function install_lsd() {
    echo -e "${BOLDGREEN}installing lsd...${ENDCOLOR}"

    wget https://github.com/Peltoche/lsd/releases/download/0.20.1/lsd_0.20.1_amd64.deb -P ${DEPENDENCIES}
    sudo dpkg -i ${DEPENDENCIES}/lsd_0.20.1_amd64.deb
}

function install_ueberzug() {
    echo -e "${BOLDGREEN}installing ueberzug...${ENDCOLOR}"

    sudo apt install -y libxext-dev

    pip install -U ueberzug
    sudo pip install -U ueberzug
}

function install_xcb_util_xrm() {
    echo -e "${BOLDGREEN}installing xcb-util-xrm...${ENDCOLOR}"

    git clone --recursive https://github.com/Airblader/xcb-util-xrm.git "${XCB_DEPENDENCIES_DIR}"
    pushd "${XCB_DEPENDENCIES_DIR}"
        ./autogen.sh
        make
        sudo make install
    popd
}

function install_fonts_awesome() {
    echo -e "${BOLDGREEN}installing fonts awesome...${ENDCOLOR}"

    sudo mkdir -p /usr/share/fonts/opentype
    sudo git clone https://github.com/adobe-fonts/source-code-pro.git /usr/share/fonts/opentype/scp

    mkdir -p "${FONTS_DEPENDENCIES_DIR}"
    pushd "${FONTS_DEPENDENCIES_DIR}"
        wget https://use.fontawesome.com/releases/v5.0.13/fontawesome-free-5.0.13.zip
        unzip fontawesome-free-5.0.13.zip
        pushd fontawesome-free-5.0.13
            sudo cp use-on-desktop/* /usr/share/fonts
            sudo fc-cache -f -v
        popd
    popd
}
