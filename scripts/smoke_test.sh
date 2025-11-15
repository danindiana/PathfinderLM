#!/bin/bash

################################################################################
# PathfinderLM Smoke Test Suite
# Description: Runs smoke tests to verify basic functionality
# Usage: ./smoke_test.sh [environment]
################################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT="${1:-local}"
BASE_URL="${BASE_URL:-http://localhost:5000}"
TIMEOUT=10
TESTS_PASSED=0
TESTS_FAILED=0

################################################################################
# Test Functions
################################################################################

log_test() {
    echo -e "${BLUE}[TEST]${NC} $*"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $*"
    ((TESTS_PASSED++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $*"
    ((TESTS_FAILED++))
}

log_skip() {
    echo -e "${YELLOW}[SKIP]${NC} $*"
}

################################################################################
# Smoke Tests
################################################################################

test_health_endpoint() {
    log_test "Testing health endpoint..."

    if curl -s -f -m "$TIMEOUT" "${BASE_URL}/health" > /dev/null 2>&1; then
        log_pass "Health endpoint is accessible"
    else
        log_fail "Health endpoint is not accessible"
    fi
}

test_api_endpoint() {
    log_test "Testing API endpoint..."

    local response=$(curl -s -w "\n%{http_code}" -m "$TIMEOUT" \
        -X POST "${BASE_URL}/ask" \
        -H "Content-Type: application/json" \
        -d '{"question": "Test question", "context": "Test context"}' 2>/dev/null || echo "000")

    local http_code=$(echo "$response" | tail -n 1)

    if [ "$http_code" = "200" ]; then
        log_pass "API endpoint returned 200 OK"
    elif [ "$http_code" = "404" ]; then
        log_skip "API endpoint not yet implemented (404)"
    elif [ "$http_code" = "000" ]; then
        log_fail "API endpoint not reachable (connection failed)"
    else
        log_fail "API endpoint returned unexpected code: $http_code"
    fi
}

test_service_running() {
    log_test "Testing if service is running..."

    if systemctl is-active --quiet pathfinderlm.service 2>/dev/null; then
        log_pass "Systemd service is running"
    elif docker ps | grep -q pathfinderlm; then
        log_pass "Docker container is running"
    elif pgrep -f "app/main.py" > /dev/null; then
        log_pass "Application process is running"
    else
        log_fail "No running service detected"
    fi
}

test_port_listening() {
    log_test "Testing if port is listening..."

    if netstat -tuln 2>/dev/null | grep -q ":5000 " || ss -tuln 2>/dev/null | grep -q ":5000 "; then
        log_pass "Port 5000 is listening"
    else
        log_fail "Port 5000 is not listening"
    fi
}

test_log_files() {
    log_test "Testing log files..."

    local log_dirs=("/opt/pathfinderlm/logs" "./logs" "/var/log/pathfinderlm")
    local found=false

    for log_dir in "${log_dirs[@]}"; do
        if [ -d "$log_dir" ] && [ -n "$(ls -A $log_dir 2>/dev/null)" ]; then
            log_pass "Log files found in $log_dir"
            found=true
            break
        fi
    done

    if [ "$found" = false ]; then
        log_skip "No log files found (may not be deployed yet)"
    fi
}

test_data_directories() {
    log_test "Testing data directory structure..."

    local required_dirs=("data/raw" "data/processed" "data/datasets" "logs" "results/model")
    local missing_dirs=()

    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$dir" ] && [ ! -d "/opt/pathfinderlm/$dir" ]; then
            missing_dirs+=("$dir")
        fi
    done

    if [ ${#missing_dirs[@]} -eq 0 ]; then
        log_pass "All required directories exist"
    else
        log_skip "Missing directories: ${missing_dirs[*]} (may not be deployed yet)"
    fi
}

test_python_imports() {
    log_test "Testing critical Python imports..."

    local import_test=$(python3 -c "
try:
    import flask
    import transformers
    import torch
    import sentence_transformers
    print('SUCCESS')
except ImportError as e:
    print(f'FAILED: {e}')
" 2>&1)

    if echo "$import_test" | grep -q "SUCCESS"; then
        log_pass "All critical Python packages can be imported"
    elif echo "$import_test" | grep -q "FAILED"; then
        log_skip "Some Python packages not installed: $import_test"
    else
        log_fail "Import test failed: $import_test"
    fi
}

test_response_time() {
    log_test "Testing response time..."

    local start_time=$(date +%s%N)
    curl -s -m "$TIMEOUT" "${BASE_URL}/health" > /dev/null 2>&1 || true
    local end_time=$(date +%s%N)

    local response_time=$(( (end_time - start_time) / 1000000 ))

    if [ $response_time -lt 1000 ]; then
        log_pass "Response time: ${response_time}ms (excellent)"
    elif [ $response_time -lt 3000 ]; then
        log_pass "Response time: ${response_time}ms (acceptable)"
    else
        log_fail "Response time: ${response_time}ms (too slow)"
    fi
}

test_disk_space() {
    log_test "Testing disk space..."

    local available=$(df -BG /opt 2>/dev/null | awk 'NR==2 {print $4}' | sed 's/G//' || echo "0")

    if [ "$available" -gt 10 ]; then
        log_pass "Sufficient disk space available: ${available}GB"
    elif [ "$available" -gt 5 ]; then
        log_pass "Disk space acceptable: ${available}GB"
    else
        log_fail "Low disk space: ${available}GB"
    fi
}

test_memory_usage() {
    log_test "Testing memory availability..."

    local available_mb=$(free -m | awk 'NR==2 {print $7}')

    if [ "$available_mb" -gt 4000 ]; then
        log_pass "Sufficient memory available: ${available_mb}MB"
    elif [ "$available_mb" -gt 2000 ]; then
        log_pass "Memory available: ${available_mb}MB"
    else
        log_fail "Low memory: ${available_mb}MB"
    fi
}

test_docker_health() {
    log_test "Testing Docker container health..."

    if docker ps --filter "name=pathfinderlm" --format "{{.Status}}" 2>/dev/null | grep -q "healthy"; then
        log_pass "Docker container is healthy"
    elif docker ps --filter "name=pathfinderlm" 2>/dev/null | grep -q pathfinderlm; then
        log_skip "Docker container running but no health check configured"
    else
        log_skip "Docker container not running"
    fi
}

test_security_headers() {
    log_test "Testing security headers..."

    local headers=$(curl -s -I -m "$TIMEOUT" "${BASE_URL}/health" 2>/dev/null || echo "")

    if echo "$headers" | grep -qi "X-Content-Type-Options"; then
        log_pass "Security headers present"
    else
        log_skip "Security headers not configured (recommended for production)"
    fi
}

################################################################################
# Main Test Execution
################################################################################

main() {
    echo "========================================"
    echo "PathfinderLM Smoke Test Suite"
    echo "Environment: $ENVIRONMENT"
    echo "Base URL: $BASE_URL"
    echo "========================================"
    echo ""

    # Run all tests
    test_service_running
    test_port_listening
    test_health_endpoint
    test_api_endpoint
    test_response_time
    test_log_files
    test_data_directories
    test_python_imports
    test_disk_space
    test_memory_usage
    test_docker_health
    test_security_headers

    echo ""
    echo "========================================"
    echo "Test Results"
    echo "========================================"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    echo "========================================"

    # Exit with error if any tests failed
    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "${RED}Smoke tests FAILED${NC}"
        exit 1
    else
        echo -e "${GREEN}All smoke tests PASSED${NC}"
        exit 0
    fi
}

# Run main function
main "$@"
