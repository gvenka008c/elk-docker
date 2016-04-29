#!/bin/bash
echo "Starting Supervisor"
/usr/bin/supervisord -c /etc/supervisord.conf >> /dev/null
