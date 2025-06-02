#!/bin/bash
cd /opt/nextcloud
/opt/bin/docker-compose logs -f "$@"