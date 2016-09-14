Brightsign  Content Delivery + Synchronization
=============================================

Synchronizing the Brightsigns has proven to be one of the toughest aspects of this project.

# Working With Brightsigns

## Overview

## Working With BrightAuthor
### Prelude: Windows in a VM

### Hosting Content for Brightsign Shows

### Setting Brightsigns up in network mode
* VLAN DHCP
 * Ensure disabled static IPs

## Show  Structure



## Network Infrastructure
Brightsigns should be on an airgapped network, away from any critical infrastructure. [^brightsigns-off-the-internet]


### Time
Each Brightsign unit can synchronize its internal clock using the [NTP Protocol](https://en.wikipedia.org/wiki/Network_Time_Protocol), allowing us the possibility of scheduling shows or activities to occur around the same time. While not accurate enough to trigger events to occur "simultaneously" this clock allows us the possibility of scheduling large-scale show changes only after the building is closed.

It's not critical to have brightsigns using NTP-synched clocks, but it is nice and offers additional functionality.

Since our Brightsigns are on their airgapped network, they cannot access a public NTP server. Instead, we our Synology NAS offers a [local NTP server](https://www.synology.com/en-us/knowledgebase/DSM/help/DSM/AdminCenter/system_ntpservice) [^synology-ntp-documentation].




[^brightsigns-off-the-internet]: I know this sounds like the words of a crazy person, but previously, our Brightsign units have been compromised as part of broader attacks on Columbia University infrastructure. Even Brightsign agrees that these things shouldn't be on the open internet.

[^synology-ntp-documentation]: Synology's [official NTP documentation](https://www.synology.com/en-us/knowledgebase/DSM/help/DSM/AdminCenter/system_ntpservice) is `¯\_(ツ)_/¯`, but this has been my process of enabling it for Synology NAS DSM 6.0. `Log into Synology | Main Menu -> Control Panel -> System: Regional Options -> NTP Service -> Enable NTP Service`.
