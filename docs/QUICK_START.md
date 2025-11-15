# PathfinderLM CI/CD Quick Start Guide

## For Developers

### Local Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/danindiana/PathfinderLM.git
   cd PathfinderLM
   ```

2. **Install dependencies**
   ```bash
   make install-dev
   ```

3. **Run tests**
   ```bash
   make test
   ```

4. **Run locally with Docker**
   ```bash
   make docker-build
   make docker-run
   ```

5. **Test the application**
   ```bash
   make smoke-test
   ```

### Pre-commit Checks

Before committing code, run:

```bash
make validate
```

This will:
- Run code linters (Black, isort, Flake8, Pylint)
- Run security scans (Bandit, Safety)
- Run unit tests with coverage

### Making Changes

1. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes

3. Run validation:
   ```bash
   make validate
   ```

4. Commit and push:
   ```bash
   git add .
   git commit -m "Description of changes"
   git push origin feature/your-feature-name
   ```

5. Create a Pull Request on GitHub

## For DevOps/System Administrators

### Initial Server Setup

#### Prerequisites
- Ubuntu 22.04 LTS server
- Root/sudo access
- Internet connectivity
- (Optional) NVIDIA GPU for ML acceleration

#### Setup Steps

1. **SSH into your server**
   ```bash
   ssh user@your-server-ip
   ```

2. **Clone the repository**
   ```bash
   git clone https://github.com/danindiana/PathfinderLM.git
   cd PathfinderLM
   ```

3. **Run bare metal setup**
   ```bash
   sudo ./scripts/setup_bare_metal.sh
   ```

   This will install:
   - Python 3.10 and dependencies
   - Docker and Docker Compose
   - NVIDIA drivers (if GPU detected)
   - Prometheus and Grafana
   - Firewall and security tools
   - System optimizations

4. **Reboot if needed**
   ```bash
   sudo reboot
   ```

5. **Verify installation**
   ```bash
   # Check Docker
   docker --version

   # Check Python
   python3 --version

   # Check GPU (if available)
   nvidia-smi

   # Check services
   systemctl status docker
   systemctl status prometheus
   ```

### Deploying the Application

#### Option 1: Manual Deployment

```bash
# For staging
sudo ./scripts/deploy.sh staging

# For production
sudo ./scripts/deploy.sh production
```

#### Option 2: Using Makefile

```bash
# Deploy to staging
make deploy-staging

# Deploy to production (requires confirmation)
make deploy-production
```

#### Option 3: Automated via GitHub Actions

1. **For Staging**: Trigger the workflow manually
   - Go to GitHub Actions
   - Select "CD - Bare Metal Deployment"
   - Click "Run workflow"
   - Select "staging" environment

2. **For Production**: Push a version tag
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

### Post-Deployment Verification

1. **Check service status**
   ```bash
   systemctl status pathfinderlm
   ```

2. **View logs**
   ```bash
   journalctl -u pathfinderlm -f
   ```

3. **Run smoke tests**
   ```bash
   ./scripts/smoke_test.sh
   ```

4. **Access monitoring**
   - Prometheus: http://your-server-ip:9090
   - Grafana: http://your-server-ip:3000
   - Application: http://your-server-ip:5000

### Common Operations

#### Restart Service
```bash
sudo systemctl restart pathfinderlm
```

#### View Application Logs
```bash
# Real-time logs
tail -f /opt/pathfinderlm/logs/app.log

# System logs
journalctl -u pathfinderlm -f
```

#### Update Application
```bash
cd /opt/pathfinderlm
git pull origin main
sudo ./scripts/deploy.sh production
```

#### Rollback Deployment
```bash
# Find backup
ls -lt /opt/backups/pathfinderlm/

# Restore
cd /opt/backups/pathfinderlm/YYYYMMDD_HHMMSS
sudo tar -xzf pathfinderlm.tar.gz -C /opt/
sudo systemctl restart pathfinderlm
```

## CI/CD Pipeline Overview

### Automated Testing (CI)

Triggered on every push and pull request:

1. **Linting** - Code quality checks
2. **Security Scanning** - Vulnerability detection
3. **Unit Tests** - Test coverage across Python 3.9-3.11
4. **Docker Build** - Container image creation
5. **Smoke Tests** - Basic functionality validation

### Automated Deployment (CD)

Triggered on:
- Manual workflow dispatch (staging)
- Git version tags (production)

Deployment steps:
1. Create release package
2. Transfer to server
3. Create backup
4. Stop services
5. Deploy new version
6. Install dependencies
7. Start services
8. Run health checks
9. Run smoke tests
10. Monitor or rollback if needed

## Environment URLs

- **Local Development**: http://localhost:5000
- **Staging**: https://staging.pathfinderlm.local
- **Production**: https://pathfinderlm.local

## Monitoring & Dashboards

### Prometheus
- **URL**: http://server-ip:9090
- **Purpose**: Metrics collection

### Grafana
- **URL**: http://server-ip:3000
- **Default Login**: admin/admin (change on first use)
- **Purpose**: Visualization and alerting

## Getting Help

### Documentation
- [Complete CI/CD Guide](CICD_GUIDE.md)
- [Project README](../README.md)
- [Architecture Documentation](../README.md#architecture)

### Support
- GitHub Issues: https://github.com/danindiana/PathfinderLM/issues
- GitHub Discussions: https://github.com/danindiana/PathfinderLM/discussions

## Quick Command Reference

```bash
# Development
make install-dev    # Install dev dependencies
make test          # Run tests
make lint          # Run linters
make format        # Format code
make validate      # Full validation

# Docker
make docker-build  # Build image
make docker-run    # Run container
make docker-stop   # Stop container
make docker-logs   # View logs

# Deployment
make deploy-staging     # Deploy to staging
make deploy-production  # Deploy to production
make smoke-test        # Run smoke tests

# Maintenance
make clean         # Clean build artifacts
systemctl status pathfinderlm  # Check service
journalctl -u pathfinderlm -f  # View logs
```

## Next Steps

1. **Developers**: Read the [CI/CD Guide](CICD_GUIDE.md) for detailed workflow
2. **DevOps**: Configure monitoring and set up automated backups
3. **Security**: Configure SSL/TLS certificates for production
4. **Optimization**: Review and tune system parameters

---

**Need more help?** Check the [complete CI/CD documentation](CICD_GUIDE.md) or open an issue on GitHub.
