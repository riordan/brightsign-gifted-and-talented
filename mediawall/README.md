Brown Institute Mediawall Documentation
========================================
These are to be the design documents for the Brown Institute's Mediawall project.

The edges are very rough.

This guide is divided up into several sections:
* [Hardware Setup](hardware-setup.md) - which describes the physical system layout (focused around our Brightsign installation), and brightsign hardware setup steps
* [Network Setup (TKTK)] - Which describes our networking environment, setup steps for the Synology NAS (local file storage and web server for new content), and file organization structure for each of the "shows"
* [Synchronization](synchronization.md) - Which describes the theory of how we "push" content to each Brightsign unit, and how we keep presentation timing synchronized across multiple Brightsign units

This guide is not yet complete, nor is it organized fully chronologically, so there may be things in other sections that are needed to fully configure the system. For that, I apologize.


# Rough Setup Steps
This order may change, but this is the rough sketch of things:

1. Map the physical installation (screen layout and assigning an ID to each screen and brightsign controller)
2. Set up parallel network infrastructure for the Brightsigns (VLAN or a physically separate network)
3. Set up (and secure) a Synology NAS (or a similar network drive) that sits between the internet (push content over sftp) and the parallel network infrastructure for the Brightsigns (serve content over http)
4. Use BrightAuthor to create unique setup SD Cards for each of the Brightsign units tied to its ID. These will use Brightsign "Simple File Networking" to check a unique URL for each Brightsign unit's unique "Presentation".
5. Use BrightAuthor and the physical installation map to create a unique "Presentation" for each unit, customized to its specific ID and screen orientation. Rather than update each "Presentation" manually, it will have a unique "Data Feed" (brightsign RSS) holding the video or photos, which is simpler to maintain.
6. Publish the media content (individual feeds, video) and BrightAuthor presentations to the Synology so it can be picked up by the Brightsigns
7. Insert the specific SD Card to its corresponding brightsign unit
8. Hopefully pop champagne to celebrate. Otherwise, start drinking whiskey from the bottle to assist with troubleshooting.

# System Overview
## The Art
The Mediawall consists of 2 "Frames", each composed of a large number of monitors of four sizes, positioned irregularly along a wall, behind reflective glass. //TKTK

## Shows

# Active Nextsteps:
* Inner wall
  * [ ] Get ACCURATE list of MAC addresses to NOC
  * [ ] Get brightsigns on vlan to use proper DHCP and get correct IP address
  * [x] Figure out if show data is being transferred to brightsigns at all
  * [x] Get a show to play on inner brightsigns
  * [ ] Get Marty to replace burnt out screens (2: 35, 42 - both 10")
  * [x] Working Test of a single show over the VLAN network -> synology
  * [ ] Create custom presentation template for each screen (Photo + Feed)
  * [ ] Create custom presentation template for each screen (Video + Feed)
* Outer Wall
  * [ ] Schedule time w/ marty for assessment + maintainance
  * [ ] Make map of outer brightsigns (~30)
    * [ ] UnitID -> Screen placement
    * [ ] UnitID -> Screen orientation
    * [ ] UnitID -> Screen size
    * [ ] UnitID -> MAC address
  * [ ] Inventory all broken screens
  * [ ] Patch firmware on all units
  * [ ]
* Physical Maintenance (overall)
  * [ ] Inquire about remotes & IR extenders
* Software
  * [ ] Screen schema
  * [ ] Photo folder -> screen feed allocator
  * [ ] Brightsign datafeed format writer
  * [ ] Devops lol
* Creating Shows
  * [ ] Create Synology Folder Templates [1-50]
  * [ ] Create Setup Cards for all units [1-50]
  * [ ] Create correct orientation show for all units w/ content

You can create the setup cards w/ software patch, even if you don't have all the screens orientations yet.
  1. Write software to QUICKLY author show content
  2. Create 3 templates for photos (Landscape - 0, Portrait-left 90, Portrait-right 270)
  3. Create ALL setup cards and label them
  4. Inventory outside wall (getting directions)
  5. Create show wall.yml for correct directions
  6. Configure each show presentation to be driven by the correct feed w/ correct orientation
  7. Author show
  8. Push show contents to each folder and feed
