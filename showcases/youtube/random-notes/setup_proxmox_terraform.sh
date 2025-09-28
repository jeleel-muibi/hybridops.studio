#!/bin/bash

# Step 1: Create the Role
pveum role add TeraformProvision -privs \
"Datastore.AllocateSpace,Datastore.Audit,Pool.Allocate,SDN.Use,Sys.Audit,Sys.Console,Sys.Modify,Sys.PowerMgmt,VM.Allocate,VM.Audit,VM.Clone,VM.Config.CDROM,VM.Config.CPU,VM.Config.Cloudinit,VM.Config.Disk,VM.Config.HWType,VM.Config.Memory,VM.Config.Network,VM.Config.Options,VM.Migrate,VM.Monitor,VM.PowerMgmt"

# Step 2: Create the Group
pveum groupadd terraform-group

# Step 3: Create the User with a placeholder password
pveum useradd TeraformProvisioner@pve -password 'ChangeMe123!'

# Step 4: Add the User to the Group
pveum groupmod terraform-group -add TeraformProvisioner@pve

# Step 5: Assign the Role to the Group at root level
pveum aclmod / -group terraform-group -role TeraformProvision

echo "Setup complete. Please change the password for TeraformProvisioner@pve immediately."
