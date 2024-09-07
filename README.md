# autowinscript-proxmox
Proxmox script to automatically pull the Windows Server 2022 Eval iso into your local datastore, create a VM, download and mount the iso for VirtIO drivers, bot the system and ready for a quick install. Good for building and rebuilding Active Directory over and over until you just give up.

Run on host using: bash -c "$(wget -qLO - https://github.com/autowinscript/autowinscript-proxmox/blob/main/win2022.sh)"

Note: I have only tested this in my environment. I am not responsible for any damage running this script may cause.
