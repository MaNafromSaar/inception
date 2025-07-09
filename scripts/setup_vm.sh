# ...existing code from setup_vm.sh...

echo ""
echo "Adding project domains to /etc/hosts for local resolution..."

# Check if the domain entry already exists to prevent duplicates.
if ! grep -q "127.0.0.1 mnaumann.42.fr" /etc/hosts; then
    # Append the line to the hosts file.
    # This script is expected to be run with sudo, so direct redirection is fine.
    echo "127.0.0.1 mnaumann.42.fr static.mnaumann.42.fr" >> /etc/hosts
    echo "Domains successfully added to /etc/hosts."
else
    echo "Domains already present in /etc/hosts. No changes made."
fi
