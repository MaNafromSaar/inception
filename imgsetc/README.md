# Evaluation Assets for Inception Project

This folder contains large binary files needed for evaluation. These files are gitignored due to size.

## Contents

### 1. Debian ISO
- **File**: `debian-11.11.0-amd64-netinst.iso`
- **Size**: ~400 MB
- **Purpose**: Base OS installation
- **Generate**: Run `../scripts/prepare_vm.sh` (downloads to ~/Downloads, copy here)

### 2. VM Template (OVA)
- **File**: `inception-base-template.ova`
- **Size**: ~1-2 GB
- **Purpose**: Pre-configured VM for quick evaluation
- **Credentials**: user=`mana`, password=`abc`, root=`abc`
- **Generate**: See [Creating the Template](#creating-the-template) below

### 3. Credentials
- **File**: `credentials.txt`
- **Size**: ~2 KB
- **Purpose**: `.env` file content for evaluators
- **Location**: Copy from `../secrets/credentials.txt`

---

## Creating the Template

### Step 1: Set up a working VM

Use Method 2 (Semi-Automated) from VM_SETUP_GUIDE.md:

```bash
# Download ISO (if not already done)
cd /home/mnaumann/Desktop/Inception
bash scripts/prepare_vm.sh

# Create VM
bash scripts/create_inception_vm.sh

# Boot VM and install Debian (follow prompts)
# After installation, run setup_vm.sh inside the VM
```

### Step 2: Clean up the VM (optional but recommended)

Inside the VM, before exporting:

```bash
# Clean package cache
sudo apt clean
sudo apt autoremove -y

# Clear bash history
history -c

# Shutdown
sudo poweroff
```

### Step 3: Export as OVA

On your host machine:

```bash
# Wait for VM to shut down completely
sleep 5

# Export to imgsetc folder
VBoxManage export inception-vm \
  -o /home/mnaumann/Desktop/Inception/imgsetc/inception-base-template.ova \
  --manifest \
  --options nomacs

# This takes 2-5 minutes depending on VM size
```

### Step 4: Copy credentials

```bash
cp /home/mnaumann/Desktop/Inception/secrets/credentials.txt \
   /home/mnaumann/Desktop/Inception/imgsetc/
```

### Step 5: Verify contents

```bash
cd /home/mnaumann/Desktop/Inception/imgsetc
ls -lh

# You should see:
# - inception-base-template.ova (~1-2 GB)
# - credentials.txt (~2 KB)
# - (optional) debian ISO if you want to include it
```

---

## For Evaluation

### Option 1: USB Stick

```bash
# Copy entire folder to USB
cp -r imgsetc /media/usb/inception-eval/

# Or copy individual files
cp imgsetc/inception-base-template.ova /media/usb/
cp imgsetc/credentials.txt /media/usb/
```

### Option 2: Upload to vServer

```bash
# Upload via SCP
scp imgsetc/inception-base-template.ova user@your-server.com:/var/www/html/files/
scp imgsetc/credentials.txt user@your-server.com:/var/www/html/files/

# Share download links with evaluators
```

### Option 3: File Sharing Service

Upload `inception-base-template.ova` to SwissTransfer/WeTransfer, share link.

---

## Using the Template (Evaluator Instructions)

1. **Import the OVA**:
   ```bash
   VBoxManage import inception-base-template.ova --vsys 0 --vmname inception-eval
   ```

2. **Start the VM**:
   ```bash
   VBoxManage startvm "inception-eval" --type gui
   ```

3. **Inside VM** (login with credentials from template):
   - **User**: `mana`
   - **Password**: `abc`
   - **Root password**: `abc` (use `su -` in terminal)
   
   Then continue with project setup:
   ```bash
   cd ~
   git clone https://github.com/MaNafromSaar/inception.git
   cd inception
   
   # Copy credentials.txt content to srcs/.env
   cp /path/to/credentials.txt srcs/.env
   
   # Run the project
   make
   ```

4. **Access** (from host machine):
   - Add to `/etc/hosts`: `127.0.0.1 mnaumann.42.fr`
   - Open browser: `https://localhost:8443` (NAT mode) or `https://mnaumann.42.fr`

---

## Notes

- The OVA contains Debian 11 + Docker + prerequisites
- It does NOT contain project files or Docker images (evaluator builds fresh)
- Size: Expect 1-2 GB for the OVA file
- Default template credentials: `inception` / `inception123` (can be changed)

---

## Disk Space Requirements

- **Development**: ~10 GB (VM + Docker images)
- **imgsetc folder**: ~2-3 GB (OVA + ISO if included)
- **USB Stick**: Minimum 4 GB recommended
