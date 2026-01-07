#!/bin/bash

# ========================================

# Git Wrapper Installation Script

# ========================================
 
set -e  # Exit on error
 
echo "=========================================="

echo "Installing Git Wrapper"

echo "=========================================="
 
# Check if running as root

if [[ $EUID -ne 0 ]]; then

   echo "❌ This script must be run as root (use sudo)" 

   exit 1

fi
 
# Step 1: Backup original Git binary

echo "[1/3] Backing up original Git binary..."

if [[ -f /usr/bin/git.real ]]; then

    echo "✓ Backup already exists at /usr/bin/git.real"

else

    mv /usr/bin/git /usr/bin/git.real

    echo "✓ Original Git backed up to /usr/bin/git.real"

fi
 
# Step 2: Create the wrapper script

echo "[2/3] Creating Git wrapper script..."

cat > /usr/bin/git << 'EOF'

#!/bin/bash

# =============================

# Toggle (change only this)

# =============================

BLOCK_PUSH=false   # true = block git push, false = allow all pushes

# Allowed domains when blocking is enabled

ALLOWED_DOMAINS=("lefttravel.com" "w3engineers.com")

# =============================

# Do NOT edit below this line

# =============================

if [[ "$BLOCK_PUSH" == true && "$1" == "push" ]]; then

    for arg in "$@"; do

        if [[ "$arg" == *"http"* ]]; then

            allowed=false

            for domain in "${ALLOWED_DOMAINS[@]}"; do

                [[ "$arg" == *"$domain"* ]] && allowed=true && break

            done

            if ! $allowed; then

                echo "❌ Push blocked. Allowed domains: ${ALLOWED_DOMAINS[*]}"

                exit 1

            fi

        fi

    done

    while IFS= read -r remote; do

        [[ "$remote" == *"http"* ]] || continue

        allowed=false

        for domain in "${ALLOWED_DOMAINS[@]}"; do

            [[ "$remote" == *"$domain"* ]] && allowed=true && break

        done

        if ! $allowed; then

            echo "❌ Push blocked to: $remote"

            exit 1

        fi

    done < <(/usr/bin/git.real remote -v | grep "(push)" | awk '{print $2}')

fi

exec /usr/bin/git.real "$@"

EOF
 
echo "✓ Wrapper script created"
 
# Step 3: Set permissions

echo "[3/3] Setting permissions..."

chown root:root /usr/bin/git

chmod 755 /usr/bin/git

echo "✓ Permissions set (755, root:root)"
 
echo ""

echo "✓ Installation complete"
 