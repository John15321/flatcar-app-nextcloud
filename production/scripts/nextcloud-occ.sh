#!/bin/bash
cd /opt/nextcloud
/opt/bin/docker-compose exec -u www-data nextcloud php occ "$@"