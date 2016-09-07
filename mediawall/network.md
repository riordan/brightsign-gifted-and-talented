Network Setup
=============

One cannot secure Brightsign units on the open internet without a firewall. So we built a very complex set of workarounds instead.

# Network Overview

## Background


# The VLAN
* DHCP (in exchange for a MAC address)

# Synology
## Services
* Samba (Filesharing - getting content to the network share)
* SFTP - Port 2222 - Getting content to the network share remotely
* SSH - Port 2222 - Remote administration
* NTP - Port 123 - Brightsign time sync
* Web admin (HTTPS) - port 5001
* Web server: - port 80 - VHOST gurley-private.brown.columbia.edu maps to /mediawall - where all content lives

## Organization
- `/mediawall/` - WEBROOT - http://gurley-private.brown.columbia.edu
  - `/mediawall/screen/` - location of all Brightsign screens
    - `/mediawall/screen/00/` - Each Brightsign units custom Folder
      - `/mediawall/screen/00/presentation/` - Brightsign Presentation folder
      - `/mediawall/screen/00/feed.xml`
      - 
Note: Brightsign IDs are 2-digits long to ensure that low-digit folders don't collide with high digit folders (e.g. 01, 02, 03 vs 1, 10, 11...)
