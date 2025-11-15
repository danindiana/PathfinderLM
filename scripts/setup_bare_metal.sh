#!/bin/bash

################################################################################
# PathfinderLM Bare Metal Server Setup
# Description: Initial setup script for Ubuntu 22.04 bare metal servers
# Usage: sudo ./setup_bare_metal.sh
################################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="pathfinderlm"
APP_USER="pathfinder"
APP_DIR="/opt/${APP_NAME}"
PYTHON_VERSION="3.10"

################################################################################
# Utility Functions
################################################################################

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $*"
}

log_error() {
    echo -e "${RED}[✗]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $*"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

check_os() {
    if [ ! -f /etc/os-release ]; then
        log_error "Cannot detect OS version"
        exit 1
    fi

    . /etc/os-release

    if [ "$ID" != "ubuntu" ] || [ "$VERSION_ID" != "22.04" ]; then
        log_warning "This script is designed for Ubuntu 22.04"
        log_warning "Detected: $ID $VERSION_ID"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

################################################################################
# Setup Functions
################################################################################

update_system() {
    log "Updating system packages..."
    apt-get update
    apt-get upgrade -y
    log_success "System updated"
}

install_system_packages() {
    log "Installing system packages..."

    apt-get install -y \
        build-essential \
        curl \
        wget \
        git \
        vim \
        htop \
        tmux \
        net-tools \
        ufw \
        fail2ban \
        ca-certificates \
        gnupg \
        lsb-release

    log_success "System packages installed"
}

install_python() {
    log "Installing Python ${PYTHON_VERSION}..."

    apt-get install -y \
        python${PYTHON_VERSION} \
        python${PYTHON_VERSION}-dev \
        python${PYTHON_VERSION}-venv \
        python3-pip

    # Set Python 3.10 as default
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 1
    update-alternatives --install /usr/bin/pip3 pip3 /usr/bin/pip${PYTHON_VERSION} 1

    # Upgrade pip
    python3 -m pip install --upgrade pip setuptools wheel

    log_success "Python ${PYTHON_VERSION} installed"
}

install_docker() {
    log "Installing Docker..."

    # Remove old versions
    apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

    # Install dependencies
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # Add Docker's official GPG key
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # Set up repository
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Start and enable Docker
    systemctl start docker
    systemctl enable docker

    # Test Docker installation
    docker --version

    log_success "Docker installed"
}

install_nvidia_drivers() {
    log "Checking for NVIDIA GPU..."

    if lspci | grep -i nvidia > /dev/null; then
        log "NVIDIA GPU detected, installing drivers..."

        # Add NVIDIA driver repository
        apt-get install -y ubuntu-drivers-common

        # Install recommended driver
        ubuntu-drivers autoinstall

        # Install NVIDIA Container Toolkit
        distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
        curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add -
        curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
            tee /etc/apt/sources.list.d/nvidia-docker.list

        apt-get update
        apt-get install -y nvidia-container-toolkit

        # Restart Docker
        systemctl restart docker

        log_success "NVIDIA drivers and container toolkit installed"
        log_warning "System reboot recommended to activate NVIDIA drivers"
    else
        log_warning "No NVIDIA GPU detected, skipping driver installation"
    fi
}

setup_firewall() {
    log "Configuring firewall..."

    # Enable UFW
    ufw --force enable

    # Default policies
    ufw default deny incoming
    ufw default allow outgoing

    # Allow SSH
    ufw allow 22/tcp

    # Allow application port
    ufw allow 5000/tcp

    # Allow HTTPS (for future use)
    ufw allow 443/tcp

    # Reload firewall
    ufw reload

    log_success "Firewall configured"
}

setup_fail2ban() {
    log "Configuring Fail2Ban..."

    # Create local configuration
    cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = 22
logpath = /var/log/auth.log
EOF

    # Restart Fail2Ban
    systemctl restart fail2ban
    systemctl enable fail2ban

    log_success "Fail2Ban configured"
}

create_app_user() {
    log "Creating application user..."

    if id "$APP_USER" &>/dev/null; then
        log_warning "User $APP_USER already exists"
    else
        useradd -r -m -s /bin/bash "$APP_USER"
        log_success "User $APP_USER created"
    fi

    # Add user to docker group
    usermod -aG docker "$APP_USER" 2>/dev/null || true
}

setup_app_directories() {
    log "Setting up application directories..."

    # Create main application directory
    mkdir -p "$APP_DIR"/{data/{raw,processed,datasets},logs,results/model,configs}

    # Create backup directory
    mkdir -p /opt/backups/${APP_NAME}

    # Create log directory
    mkdir -p /var/log/${APP_NAME}

    # Set ownership
    chown -R ${APP_USER}:${APP_USER} "$APP_DIR"
    chown -R ${APP_USER}:${APP_USER} /opt/backups/${APP_NAME}
    chown -R ${APP_USER}:${APP_USER} /var/log/${APP_NAME}

    # Set permissions
    chmod 755 "$APP_DIR"
    chmod 750 "$APP_DIR"/data
    chmod 750 "$APP_DIR"/logs

    log_success "Application directories created"
}

install_monitoring_tools() {
    log "Installing monitoring tools..."

    # Install monitoring packages
    apt-get install -y \
        prometheus \
        prometheus-node-exporter \
        grafana

    # Enable services
    systemctl enable prometheus
    systemctl enable prometheus-node-exporter
    systemctl enable grafana-server

    log_success "Monitoring tools installed"
}

setup_swap() {
    log "Setting up swap space..."

    local swap_size="8G"

    if [ -f /swapfile ]; then
        log_warning "Swap file already exists"
    else
        # Create swap file
        fallocate -l $swap_size /swapfile
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile

        # Make swap permanent
        if ! grep -q '/swapfile' /etc/fstab; then
            echo '/swapfile none swap sw 0 0' >> /etc/fstab
        fi

        log_success "Swap space configured ($swap_size)"
    fi
}

optimize_system() {
    log "Optimizing system settings..."

    # Increase file descriptor limits
    cat >> /etc/security/limits.conf << EOF
* soft nofile 65535
* hard nofile 65535
EOF

    # Optimize kernel parameters
    cat >> /etc/sysctl.conf << EOF
# Network optimizations
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 8192
net.core.netdev_max_backlog = 5000

# Memory optimizations
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
EOF

    sysctl -p

    log_success "System optimized"
}

display_summary() {
    echo ""
    echo "========================================"
    echo "Setup Complete!"
    echo "========================================"
    echo ""
    echo "Application Details:"
    echo "  - User: $APP_USER"
    echo "  - Directory: $APP_DIR"
    echo "  - Logs: /var/log/${APP_NAME}"
    echo "  - Backups: /opt/backups/${APP_NAME}"
    echo ""
    echo "Next Steps:"
    echo "  1. Reboot the system (if NVIDIA drivers were installed)"
    echo "  2. Deploy the application using: make deploy-production"
    echo "  3. Configure monitoring dashboards"
    echo "  4. Set up SSL certificates"
    echo ""
    echo "Services Status:"
    systemctl is-active docker && echo "  ✓ Docker: Running" || echo "  ✗ Docker: Not Running"
    systemctl is-active fail2ban && echo "  ✓ Fail2Ban: Running" || echo "  ✗ Fail2Ban: Not Running"
    ufw status | grep -q "active" && echo "  ✓ Firewall: Active" || echo "  ✗ Firewall: Inactive"
    echo ""
    echo "========================================"
}

################################################################################
# Main Setup Flow
################################################################################

main() {
    echo "========================================"
    echo "PathfinderLM Bare Metal Server Setup"
    echo "Ubuntu 22.04 LTS"
    echo "========================================"
    echo ""

    check_root
    check_os

    update_system
    install_system_packages
    install_python
    install_docker
    install_nvidia_drivers
    setup_firewall
    setup_fail2ban
    create_app_user
    setup_app_directories
    install_monitoring_tools
    setup_swap
    optimize_system

    display_summary
}

# Run main function
main "$@"
