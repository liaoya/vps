# Ubuntu for VPS

```bash
hostnamectl set-hostname <>
timedatectl set-timezone UTC
# Make sudo work without warning
echo $(hostname -I) $(hostname)  | tee -a /etc/hosts

swapoff -a
sed -i 's|^/swapfile|# /swapfile|' /etc/fstab
sed -i 's|^/swap.img|# /swap.img|' /etc/fstab
rm -f /swapfile /swap.img

sed -i -e "/# set PATH so it includes user's private bin if it exists/,+4d" ~/.profile
cat <<'EOF' | tee -a ~/.profile
# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] && ! test "${PATH#*$HOME/bin}" != "$PATH"; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] && ! test "${PATH#*"$HOME"/.local/bin}" != "$PATH"; then
    PATH="$HOME/.local/bin:$PATH"
fi
EOF

mkdir -p ~/.bashrc.d ~/.bash_completion.d ~/.local/bin ~/Downloads ~/Documents
cat <<'EOF' | tee -a ~/.bashrc
[ -d ~/.bashrc.d ] && for _script in ~/.bashrc.d/*.sh; do [ -f "${_script}" ] && source "${_script}"; done
[ -d ~/.bash_completion.d ] && for _script in ~/.bash_completion.d/*.sh; do [ -f "${_script}" ] && source "${_script}"; done
EOF

if ! grep -s -q "^pathmunge () {" "${HOME}/.bashrc"; then
    cat <<'EOF' >> ~/.bashrc
pathmunge () {
    case ":${PATH}:" in
        *:"$1":*)
        ;;
        *)
            if [ "$2" = "after" ] ; then
                PATH=$PATH:$1
            else
                PATH=$1:$PATH
            fi
    esac
}
#[[ -d "${HOME}/.local/bin" ]] &&  pathmunge "${HOME}/.local/bin"
pathmunge /sbin
EOF
    [[ -d "${HOME}/.local/bin" ]] || mkdir -p "${HOME}/.local/bin"
    source ~/.bashrc
fi

sudo bash -c 'curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh'
sudo chown 0:0 /usr/local/bin/uv*

[[ -f /etc/apt/sources.list.save ]] || cp -pr /etc/apt/sources.list /etc/apt/sources.list.save
MIRROR_URL=http://mirrors.ubuntu.com/JP.txt
wget ${MIRROR_URL}
apt-smart -F $(basename ${MIRROR_URL}) -a
[[ -f /etc/apt/sources.list.save ]] && cp -pr /etc/apt/sources.list.save /etc/apt/sources.list
sed -i -e 's/^deb-src/#deb-src/' /etc/apt/sources.list

export APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=yes
export DEBIAN_FRONTEND=noninteractive

apt update -qq -y
# apt upgrade -qq -y -o "Dpkg::Use-Pty=0"
apt install -qq -y software-properties-common # for ppa

apt install -qq -y bc
VERSION=$(echo "$(lsb_release -r | cut -d':' -f2 | tr -d '[:space:]') * 100 / 1" | bc)

declare -a ppa_repos
ppa_repos+=(ppa:ansible/ansible ppa:fish-shell/release-3)
ppa_repos+=(ppa:deadsnakes/ppa ppa:pypy/ppa) # ppa:deadsnakes/ppa for various python
ppa_repos+=(ppa:maveonair/helix-editor)
ppa_repos+=(ppa:neovim-ppa/unstable) # ppa:neovim-ppa/stable is very old
if [[ ${VERSION} -eq 1804 ]]; then
    # ppa:deadsnakes/ppa for various python
    # ppa:git-core/ppa, now ppa:savoury1/backports has latest git
    ppa_repos+=(ppa:savoury1/backports)
    ppa_repos+=(ppa:apt-fast/stable ppa:codeblocks-devs/release ppa:deadsnakes/ppa ppa:kelleyk/emacs ppa:fish-shell/release-3
        ppa:lazygit-team/release
        ppa:kimura-o/ppa-tig ppa:pypy/ppa ppa:unilogicbv/shellcheck
        ppa:jonathonf/vim)
elif [[ ${VERSION} -eq 2004 ]]; then
    # ppa:deadsnakes/ppa for various python
    # ppa:git-core/ppa, now ppa:savoury1/backports has latest git
    # ppa:mtvoid/ppa for emacs27
    # ppa:mjuhasz/backports for tmux 3.1b
    ppa_repos+=(ppa:savoury1/backports)
    ppa_repos+=(ppa:ansible/ansible ppa:fish-shell/release-3 ppa:jonathonf/vim ppa:kelebek333/xfce-4.16 ppa:mjuhasz/backports)
elif [[ ${VERSION} -eq 2204 ]]; then
    ppa_repos+=(ppa:savoury1/backports)
    ppa_repos+=(ppa:fish-shell/release-3 ppa:jonathonf/vim)
fi
for ppa in "${ppa_repos[@]}"; do add-apt-repository -y "$ppa"; done

if [[ ! -f /etc/needrestart/needrestart.conf ]]; then
    apt-get update -qy
    apt-get install needrestart
fi
sed -i -e '/^\$nrconf{restart}/d' -e "/^#\$nrconf{restart}/a \$nrconf{restart} = 'a';" /etc/needrestart/needrestart.conf

apt-get update -qq -y
apt-get upgrade -q -y

UBUNTU_VERSION=$(lsb_release -r | cut -d':' -f2 | tr -d '[:space:]')
apt-get install -qy --no-install-recommends "linux-generic-hwe-${UBUNTU_VERSION}"

apt-get install -qq -y certbot curl docker.io docker-compose-v2 dos2unix fish git gnupg moreutils nmon nano powerline sshpass tig tmux ufw vim
apt-get install -qq -y python3-distutils

curl https://zyedidia.github.io/eget.sh | sh
mv ./eget /usr/local/bin
chown 0:0 /usr/local/bin/eget
eget --upgrade-only --to=/usr/local/bin --asset="jq-linux-amd64" jqlang/jq
eget --upgrade-only --to=/usr/local/bin --asset="^.tar.gz" mikefarah/yq
eget --upgrade-only --to=/usr/local/bin --asset="^musl" starship/starship
eget --upgrade-only --to=/usr/local/bin zellij-org/zellij

mkdir ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 644 ~/.ssh/authorized_keys

# create normal user
SUDO_USER=tshen
useradd -g users -s /bin/bash -m "$SUDO_USER"
echo "$(id -un $SUDO_USER) ALL=(ALL) NOPASSWD: ALL" | tee "/etc/sudoers.d/$(id -un $SUDO_USER)"
SUDO_USER_DIR=$(getent passwd "$SUDO_USER" | cut -d: -f6)
mkdir "$SUDO_USER_DIR/.ssh"
touch "$SUDO_USER_DIR/.ssh/authorized_keys"
chown -R "$(id -u $SUDO_USER):$(id -g $SUDO_USER)" "$SUDO_USER_DIR/.ssh"
chmod 700 "$SUDO_USER_DIR/.ssh"
chmod 644 "$SUDO_USER_DIR/.ssh/authorized_keys"
getent group docker && usermod -aG docker "${SUDO_USER}"


# https://unix.stackexchange.com/questions/130786/can-i-remove-files-in-var-log-journal-and-var-cache-abrt-di-usr
echo "SystemMaxUse=100M" | sudo tee -a /etc/systemd/journald.conf
sudo systemctl daemon-reload
sudo systemctl restart systemd-journald.service
sudo journalctl --disk-usage

ufw default deny incoming
ufw default allow outgoing

ufw allow ssh
ufw status
# Make sure ssh is allowed
ufw enable
ufw status
```

```bash
cat <<EOF | tee /etc/profile.d/starship.sh
#!/bin/bash

if [[ $TERM != linux && $TERM != vt220 ]] && command -v starship 1>/dev/null 2>&1; then
    eval "$(starship init bash)"
fi
EOF

mkdir -p /etc/fish/conf.d

cat <<EOF | tee /etc/fish/conf.d/starship.fish
#!/bin/env fish

if command -sq starship
    starship init fish | source
end
EOF

cat <<EOF | tee /etc/starship.toml
command_timeout=1000

[localip]
disabled=true

[shell]
disabled=false
style="black bold"
EOF

echo '#!/bin/bash' | tee /usr/local/bin/starship_precmd
chmod a+x /usr/local/bin/starship_precmd
```

## Enable BBR in 18.04

```bash
if ! grep -q "tcp_bbr" "/etc/modules-load.d/modules.conf"; then
    echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
fi
modprobe tcp_bbr

SYSCTL_FILE=/etc/sysctl.d/90-tcp-bbr.conf
echo "Current configuration: "
sysctl net.ipv4.tcp_available_congestion_control
sysctl net.ipv4.tcp_congestion_control

# apply new config
if ! grep -q "net.core.default_qdisc = fq" "$SYSCTL_FILE"; then
    echo "net.core.default_qdisc = fq" >> $SYSCTL_FILE
fi
if ! grep -q "net.ipv4.tcp_congestion_control = bbr" "$SYSCTL_FILE"; then
    echo "net.ipv4.tcp_congestion_control = bbr" >> $SYSCTL_FILE
fi

# check if we can apply the config now
if lsmod | grep -q "tcp_bbr"; then
    sysctl -p $SYSCTL_FILE
    echo "BBR is available now."
elif modprobe tcp_bbr; then
    sysctl -p $SYSCTL_FILE
    echo "BBR is available now."
else
    echo "Please reboot to enable BBR."
fi
```

## Enable fastopen in 18.04

```bash
SYSCTL_FILE=/etc/sysctl.d/90-tcp-fastopen.conf
touch "${SYSCTL_FILE}"
sed -i '/net\.ipv4\.tcp_fastopen/d' /etc/sysctl.conf
sed -i '/net\.ipv4\.tcp_fastopen/d' "${SYSCTL_FILE}"
echo "net.ipv4.tcp_fastopen = 3" > "${SYSCTL_FILE}"
```

```bash
# https://shadowsocks.org/guide/advanced.html
cat <<EOF | tee /etc/sysctl.d/90-shadowsocks.conf
fs.file-max = 51200

net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.netdev_max_backlog = 250000
net.core.somaxconn = 4096

net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mem = 25600 51200 102400
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_mtu_probing = 1
# net.ipv4.tcp_congestion_control = hybla
EOF
```

## Run with normal user

```bash
sed -i -e "/# set PATH so it includes user's private bin if it exists/,+4d" ~/.profile
cat <<'EOF' | tee -a ~/.profile
# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] && ! test "${PATH#*$HOME/bin}" != "$PATH"; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] && ! test "${PATH#*"$HOME"/.local/bin}" != "$PATH"; then
    PATH="$HOME/.local/bin:$PATH"
fi
EOF

mkdir -p ~/.bashrc.d ~/.bash_completion.d ~/.local/bin ~/Downloads ~/Documents
cat <<'EOF' | tee -a ~/.bashrc
[ -d ~/.bashrc.d ] && for _script in ~/.bashrc.d/*.sh; do [ -f "${_script}" ] && source "${_script}"; done
[ -d ~/.bash_completion.d ] && for _script in ~/.bash_completion.d/*.sh; do [ -f "${_script}" ] && source "${_script}"; done
EOF

if ! grep -s -q "^pathmunge () {" "${HOME}/.bashrc"; then
    cat <<'EOF' >> ~/.bashrc
pathmunge () {
    case ":${PATH}:" in
        *:"$1":*)
        ;;
        *)
            if [ "$2" = "after" ] ; then
                PATH=$PATH:$1
            else
                PATH=$1:$PATH
            fi
    esac
}
#[[ -d "${HOME}/.local/bin" ]] &&  pathmunge "${HOME}/.local/bin"
pathmunge /sbin
EOF
    [[ -d "${HOME}/.local/bin" ]] || mkdir -p "${HOME}/.local/bin"
    source ~/.bashrc
fi

cat <<'EOF' > "${HOME}/.tmux.conf"
bind-key C-m set-option -g mouse \; display-message "Mouse #{?mouse,on,off}"
set -g buffer-limit 10000
set -g default-shell /usr/bin/fish
set -g history-limit 5000
set -g renumber-windows on
EOF

tmuxfile=$(find /usr/share -iname powerline.conf 2>/dev/null | grep tmux/powerline.conf)
if [[ -n $tmuxfile ]]; then
    echo "source ${tmuxfile}" >> "${HOME}/.tmux.conf"
fi
```

### Setup ntp

```bash
sudo apt install -q -y chrony ntpdate
sudo sed -i 's/^pool /# pool/g' /etc/chrony/chrony.conf
echo 'server 0.us.pool.ntp.org iburst maxsources 4' | sudo tee -a /etc/chrony/chrony.conf
echo 'server 1.us.pool.ntp.org iburst maxsources 4' | sudo tee -a /etc/chrony/chrony.conf
echo 'server 2.us.pool.ntp.org iburst maxsources 4' | sudo tee -a /etc/chrony/chrony.conf
echo 'server 3.us.pool.ntp.org iburst maxsources 4' | sudo tee -a /etc/chrony/chrony.conf
sudo ntpdate -u 0.us.pool.ntp.org
sudo systemctl enable chrony
sudo systemctl start chrony
```
