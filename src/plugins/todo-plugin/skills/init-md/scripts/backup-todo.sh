#!/usr/bin/env bash
set -euo pipefail

if [ -f "./TODO.md" ]; then
    BACKUP="TODO_backup_$(date +"%Y%m%d_%H%M%S").md"
    mv "./TODO.md" "./${BACKUP}"
    echo "${BACKUP}"
fi
