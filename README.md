# autowinscript-proxmox
Bash script meant to run in a Proxmox Virtual Environment. Will automatically pull the Windows Server 2022 Eval iso into your local datastore, download and mount the iso for VirtIO drivers,  create a VM with your specifications (or just use default), boot the system ready for a quick install. Good for in a homelab. Helps with building and rebuilding Active Directory over and over until you just give up.

Run on host using: bash -c "$(wget -qLO - https://raw.githubusercontent.com/autowinscript/autowinscript-proxmox/main/win2022.sh)"

Note: I have only tested this in my environment. I am not responsible for any damage running this script may cause.

Also Note: Downloading Windows is currently BUGGED! Script will still work with an iso called server2022.iso in the local store.
