# VM Template - Quick Reference

## Creating the Base Template

After successfully setting up your VM with Docker and all prerequisites:

```bash
# 1. Clean up the VM (optional but recommended)
# Inside VM:
sudo apt clean
sudo apt autoremove
history -c

# 2. Power off the VM (from host)
VBoxManage controlvm "inception-vm" poweroff

# 3. Export as template
VBoxManage export inception-vm \
  -o ~/inception-base-template.ova \
  --manifest \
  --options nomacs

# This creates inception-base-template.ova (~1-2 GB)
```

## Using the Template for Evaluation

```bash
# 1. Import the template
VBoxManage import inception-base-template.ova \
  --vsys 0 \
  --vmname inception-eval

# 2. (Optional) Adjust RAM/CPUs if needed
VBoxManage modifyvm "inception-eval" --memory 4096 --cpus 2

# 3. Start the VM
VBoxManage startvm "inception-eval" --type gui

# 4. Login and clone/pull project
# Inside VM (credentials from template):
git clone https://github.com/MaNafromSaar/inception.git
cd inception
git pull  # if already cloned

# 5. Add .env file (provided by evaluator via Google Drive)
cp /path/to/credentials.txt srcs/.env

# 6. Run the project
make
```

## Sharing with Evaluators

### Option 1: USB Stick

```bash
# Copy to USB drive
cp inception-base-template.ova /media/usb/
```

Most reliable method for in-person evaluations.

### Option 2: Own VServer

```bash
# Upload to your server
scp inception-base-template.ova user@your-server.com:/path/to/public/

# Share download link
# Example: https://your-server.com/files/inception-base-template.ova
```

### Option 3: File Sharing Service

Use a simple file sharing service like **SwissTransfer** or **WeTransfer**:

1. Upload `inception-base-template.ova` 
2. Generate shareable link
3. Send link to evaluator
4. Files auto-delete after download/expiry

**Note**: Choose services that don't require account creation for download.

## Template Contents

The base template includes:
- ✅ Debian 11 (Bullseye) headless installation
- ✅ Docker Engine and Docker Compose installed
- ✅ User added to docker and sudo groups
- ✅ Firewall (UFW) configured
- ✅ Git and build tools installed
- ✅ Clean, minimal system (~8-10 GB disk usage)

The template does NOT include:
- ❌ Project files (clone fresh during evaluation)
- ❌ Credentials (.env file)
- ❌ Docker images (built during `make`)
- ❌ Any project data

## Benefits

**Time savings:**
- OS installation: ~~15 minutes~~ → 2 minutes
- Docker setup: ~~5 minutes~~ → 0 minutes
- Total: **~18 minutes saved per evaluation**

**Reliability:**
- No risk of misclicking during installation
- Consistent environment every time
- Evaluator focuses on project, not VM setup

**Subject Compliance:**
- ✅ "Done on a Virtual Machine" - Yes
- ✅ "Set up environment from scratch" - Docker services still built from scratch
- ✅ Template is just a time-saving tool, not part of deliverables

## Advanced: Multiple Templates

You can create templates at different stages:

```bash
# 1. Base OS only
VBoxManage export inception-vm -o base-os.ova

# 2. OS + Docker
VBoxManage export inception-vm -o base-docker.ova

# 3. Everything ready
VBoxManage export inception-vm -o base-full.ova
```

Use different templates for different purposes (testing, evaluation, development).

## Cleanup

To remove templates and VMs:

```bash
# Remove VM
VBoxManage unregistervm "inception-eval" --delete

# Remove OVA file
rm ~/inception-base-template.ova
```
