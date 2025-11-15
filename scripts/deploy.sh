#!/bin/bash

################################################################################
# PathfinderLM Bare Metal Deployment Script
# Description: Automates deployment to Ubuntu 22.04 bare metal servers
# Usage: ./deploy.sh [staging|production]
################################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT="${1:-staging}"
APP_NAME="pathfinderlm"
APP_USER="pathfinder"
APP_DIR="/opt/${APP_NAME}"
BACKUP_DIR="/opt/backups/${APP_NAME}"
LOG_FILE="/var/log/${APP_NAME}/deploy.log"
PYTHON_VERSION="3.10"

# Server configuration (would be loaded from secure config)
if [ "$ENVIRONMENT" = "production" ]; then
    SERVER_HOST="${PROD_SERVER_HOST:-production.local}"
    SERVER_PORT="${PROD_SERVER_PORT:-5000}"
else
    SERVER_HOST="${STAGING_SERVER_HOST:-staging.local}"
    SERVER_PORT="${STAGING_SERVER_PORT:-5001}"
fi

################################################################################
# Logging Functions
################################################################################

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[✗]${NC} $*" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $*" | tee -a "$LOG_FILE"
}

################################################################################
# Utility Functions
################################################################################

check_prerequisites() {
    log "Checking prerequisites..."

    # Check if running on Ubuntu 22.04
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [ "$VERSION_ID" != "22.04" ]; then
            log_warning "Not running on Ubuntu 22.04 (detected: $VERSION_ID)"
        fi
    fi

    # Check for required commands
    local required_cmds=("python3" "pip3" "docker" "git" "systemctl")
    for cmd in "${required_cmds[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "$cmd is not installed"
            exit 1
        fi
    done

    log_success "Prerequisites check passed"
}

create_backup() {
    log "Creating backup of current deployment..."

    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="${BACKUP_DIR}/${timestamp}"

    mkdir -p "$backup_path"

    if [ -d "$APP_DIR" ]; then
        tar -czf "${backup_path}/${APP_NAME}.tar.gz" -C "$(dirname $APP_DIR)" "$(basename $APP_DIR)"
        log_success "Backup created at $backup_path"
        echo "$backup_path" > /tmp/pathfinderlm_last_backup
    else
        log_warning "No existing installation to backup"
    fi
}

stop_services() {
    log "Stopping application services..."

    # Stop systemd service if it exists
    if systemctl is-active --quiet ${APP_NAME}.service 2>/dev/null; then
        systemctl stop ${APP_NAME}.service
        log_success "Systemd service stopped"
    fi

    # Stop Docker containers if running
    if docker ps -q -f name=${APP_NAME} | grep -q .; then
        docker stop ${APP_NAME} || true
        log_success "Docker containers stopped"
    fi

    log_success "Services stopped"
}

deploy_application() {
    log "Deploying application to $APP_DIR..."

    # Create app directory structure
    mkdir -p "$APP_DIR"/{data/{raw,processed,datasets},logs,results/model,configs}

    # Copy application files
    if [ -d "$(pwd)/app" ]; then
        cp -r app "$APP_DIR/"
        cp -r scripts "$APP_DIR/" 2>/dev/null || true
        cp -r docs "$APP_DIR/" 2>/dev/null || true
        cp requirements.txt "$APP_DIR/" 2>/dev/null || true
        cp Dockerfile "$APP_DIR/" 2>/dev/null || true
        cp docker-compose.yml "$APP_DIR/" 2>/dev/null || true
    fi

    # Set ownership
    if id "$APP_USER" &>/dev/null; then
        chown -R ${APP_USER}:${APP_USER} "$APP_DIR"
    else
        log_warning "User $APP_USER does not exist, skipping ownership change"
    fi

    log_success "Application deployed"
}

install_dependencies() {
    log "Installing Python dependencies..."

    cd "$APP_DIR"

    # Create virtual environment if it doesn't exist
    if [ ! -d "venv" ]; then
        python3 -m venv venv
    fi

    # Activate virtual environment and install dependencies
    source venv/bin/activate
    pip install --upgrade pip setuptools wheel

    if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt
        log_success "Dependencies installed"
    else
        log_warning "No requirements.txt found"
    fi

    deactivate
}

setup_systemd_service() {
    log "Setting up systemd service..."

    cat > /etc/systemd/system/${APP_NAME}.service << EOF
[Unit]
Description=PathfinderLM AI Life Coach Service
After=network.target

[Service]
Type=simple
User=${APP_USER}
Group=${APP_USER}
WorkingDirectory=${APP_DIR}
Environment="PATH=${APP_DIR}/venv/bin"
ExecStart=${APP_DIR}/venv/bin/python3 ${APP_DIR}/app/main.py
Restart=always
RestartSec=10
StandardOutput=append:${APP_DIR}/logs/app.log
StandardError=append:${APP_DIR}/logs/error.log

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=${APP_DIR}/data ${APP_DIR}/logs ${APP_DIR}/results

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    log_success "Systemd service configured"
}

start_services() {
    log "Starting application services..."

    # Start systemd service
    systemctl enable ${APP_NAME}.service
    systemctl start ${APP_NAME}.service

    # Wait for service to start
    sleep 5

    if systemctl is-active --quiet ${APP_NAME}.service; then
        log_success "Application service started successfully"
    else
        log_error "Failed to start application service"
        systemctl status ${APP_NAME}.service
        return 1
    fi
}

run_health_check() {
    log "Running health checks..."

    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "http://localhost:${SERVER_PORT}/health" > /dev/null 2>&1; then
            log_success "Health check passed"
            return 0
        fi

        log "Health check attempt $attempt/$max_attempts..."
        sleep 2
        ((attempt++))
    done

    log_error "Health check failed after $max_attempts attempts"
    return 1
}

run_smoke_tests() {
    log "Running smoke tests..."

    if [ -f "${APP_DIR}/scripts/smoke_test.sh" ]; then
        bash "${APP_DIR}/scripts/smoke_test.sh"
        log_success "Smoke tests passed"
    else
        log_warning "Smoke test script not found"
    fi
}

rollback() {
    log_error "Deployment failed, initiating rollback..."

    if [ -f /tmp/pathfinderlm_last_backup ]; then
        local backup_path=$(cat /tmp/pathfinderlm_last_backup)

        if [ -f "${backup_path}/${APP_NAME}.tar.gz" ]; then
            stop_services
            rm -rf "$APP_DIR"
            tar -xzf "${backup_path}/${APP_NAME}.tar.gz" -C "$(dirname $APP_DIR)"
            start_services
            log_success "Rollback completed"
        else
            log_error "Backup file not found, cannot rollback"
        fi
    else
        log_error "No backup reference found"
    fi
}

################################################################################
# Main Deployment Flow
################################################################################

main() {
    log "========================================"
    log "PathfinderLM Deployment - $ENVIRONMENT"
    log "========================================"

    # Pre-deployment checks
    check_prerequisites

    # Confirmation for production
    if [ "$ENVIRONMENT" = "production" ]; then
        echo -e "${RED}WARNING: You are about to deploy to PRODUCTION${NC}"
        read -p "Are you sure you want to continue? (yes/no): " -r
        if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
            log "Deployment cancelled"
            exit 0
        fi
    fi

    # Create backup
    create_backup

    # Stop running services
    stop_services

    # Deploy application
    deploy_application

    # Install dependencies
    install_dependencies

    # Setup systemd service
    setup_systemd_service

    # Start services
    if ! start_services; then
        rollback
        exit 1
    fi

    # Run health checks
    if ! run_health_check; then
        rollback
        exit 1
    fi

    # Run smoke tests
    run_smoke_tests

    log_success "========================================"
    log_success "Deployment completed successfully!"
    log_success "Environment: $ENVIRONMENT"
    log_success "========================================"
}

# Trap errors and rollback
trap 'rollback' ERR

# Run main function
main "$@"
