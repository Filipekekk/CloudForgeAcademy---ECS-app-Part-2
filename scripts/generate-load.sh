#!/bin/bash
set -e

ALB_URL=$(cd ../part3 && terraform output -raw alb_url)

echo "🔥 Generating load on $ALB_URL"
echo "Press Ctrl+C to stop"

if command -v ab &> /dev/null; then
    ab -n 100000 -c 50 -t 600 $ALB_URL/
else
    echo "Using curl (install apache2-utils for better performance)"
    for i in {1..50}; do
        (while true; do curl -s $ALB_URL/ > /dev/null; done) &
    done
    wait
fi