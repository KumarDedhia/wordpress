#!/usr/bin/env bash
set -euo pipefail

echo "=== Docker Debug Information ==="
echo ""

echo "1. Docker Version:"
docker version
echo ""

echo "2. Docker Info:"
docker info | head -n 30
echo ""

echo "3. Current User & Groups:"
id
echo ""

echo "4. Docker Socket Permissions:"
ls -la /var/run/docker.sock
echo ""

echo "5. Container Status:"
docker ps -a
echo ""

echo "6. SELinux Status (if available):"
if command -v getenforce &> /dev/null; then
    getenforce
else
    echo "SELinux not available"
fi
echo ""

echo "7. AppArmor Status (if available):"
if command -v aa-status &> /dev/null; then
    sudo aa-status | grep docker || echo "No Docker AppArmor profiles"
else
    echo "AppArmor not available"
fi
echo ""

echo "8. Recent Docker Daemon Logs:"
journalctl -u docker -n 50 --no-pager
echo ""

echo "9. Container Inspect (wordpress_ftp):"
docker inspect wordpress_ftp 2>/dev/null | grep -A 10 -E "(State|Status|Runtime|Privileged|SecurityOpt)" || echo "Container not found or inspect failed"
echo ""

echo "10. Cgroup Driver:"
docker info | grep -i "cgroup"
echo ""

echo "11. Runtime:"
docker info | grep -i "runtime"
echo ""

echo "12. Storage Driver:"
docker info | grep -A 5 "Storage Driver"
echo ""
