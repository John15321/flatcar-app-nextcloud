#!/bin/bash

# Development Helper Scripts

echo "🐳 Nextcloud Development Helper Scripts"
echo "======================================="
echo ""

if [ ! -f docker-compose.yml ]; then
    echo "❌ Error: Run this script from the nextcloud directory"
    exit 1
fi

case "$1" in
    "logs")
        echo "📋 Viewing logs for: ${2:-all services}"
        docker-compose logs -f "$2"
        ;;
    "shell")
        echo "🖥️  Opening shell in Nextcloud container..."
        docker-compose exec nextcloud bash
        ;;
    "occ")
        shift
        echo "⚙️  Running Nextcloud OCC command: $*"
        docker-compose exec -u www-data nextcloud php occ "$@"
        ;;
    "restart")
        echo "🔄 Restarting services..."
        docker-compose down && docker-compose up -d
        ;;
    "status")
        echo "📊 Service status:"
        docker-compose ps
        ;;
    "clean")
        echo "🧹 Cleaning up..."
        docker-compose down
        docker system prune -f
        ;;
    *)
        echo "Usage: $0 {logs|shell|occ|restart|status|clean}"
        echo ""
        echo "Commands:"
        echo "  logs [service]  - View logs (optionally for specific service)"
        echo "  shell          - Open bash shell in Nextcloud container"
        echo "  occ [args]     - Run Nextcloud OCC commands"
        echo "  restart        - Restart all services"
        echo "  status         - Show service status"
        echo "  clean          - Stop services and clean up"
        echo ""
        echo "Examples:"
        echo "  $0 logs nextcloud"
        echo "  $0 occ user:list"
        echo "  $0 occ app:enable files_external"
        ;;
esac
