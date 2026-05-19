#!/bin/bash
set -e

# Ensure the active venv symlink exists (defaults to the Python 3.8 venv on first boot)
if [ ! -L /opt/patroni/venv ]; then
    ln -s /opt/venv38 /opt/patroni/venv
fi

# Run Patroni in the foreground using whichever virtual environment is currently linked
exec /opt/patroni/venv/bin/patroni /etc/patroni/patroni.yml
