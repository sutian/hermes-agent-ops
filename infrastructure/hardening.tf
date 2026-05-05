# CIS-inspired hardening for log server VM
# Applied via cloud-init in main.tf

# Disable password authentication (key-only)
# Ensure SSH keys are configured in ssh_keys variable

# Automatic security updates
# "apt-get install -y unattended-upgrades" via cloud-init

# System tuning for observability workload
# - Increase inotify limits
# - Increase file descriptor limits
# - Disable unnecessary services
