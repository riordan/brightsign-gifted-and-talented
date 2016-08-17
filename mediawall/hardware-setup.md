Hardware Setup
==============

# Brightsign Units:

## Basics
The setup is made of two large "Frames" of monitors, each connected to a BrightSign HD (1020).

Each "Frame" consists of:
* an outer 42" monitor in portrait orientation (tallscreen) connected to a Brightsign over HDMI 1080p
* 20 - 30 inner monitors of varying sizes and orientations connected to a Brightsign unit over VGA. The monitors come in 8", 10", 12", and 15" sizes and are at a resolution of 1024x768

## Updating & documenting
Before the brightsign units can be used in this installation they must be:
* Identified and Mapped - tying each BRIGHTSIGN UNIT to its MONITOR
 * Each monitor's Brightsign Unit ID (a number in our case), size, place, and orientation is recorded
* MAC Address recorded - so it can be tied into the proper network
* Updated to the latest firmware - **NECESSARY PRIOR TO CONNECTING TO NETWORK, ESPECIALLY POST-HACK**

### Identified and Mapped
Identifying which monitor is controlled by which brightsign box lets you create content specific to each monitor. Each monitor is controlled by an individual brightsign.

1. Draw a map of the physical monitor display, identifying the (approimate) position of each monitor relative to one another, its size (e.g. 8 in, 10 in, 12 in, 15 in), and orientation (portrait, landscape).
2. Unplug one active Brightsign unit at a time, noting which monitor shuts off when the brightsign is unplugged. Record this on the map from Step 1. Plug the brightsign back in once identified. If you are working with an installation where all the brightsigns are off, plug each unit in one at a time, then unplug it again once identified.
3. Once you've mapped and IDed each unit, identify the screen rotation (it may be 0, 90, 180, 270, based on which direction is "up" in traditional portrait mode). To do this, boot the unit without any SD card in it, which will display an info screen in the default orientation.
4. Use this info screen to determine the MAC address of each Brightsign (if you don't have access to the bottom of each Brightsign because you've screwed it into the wall) and the firmware version for the next two steps.

### Identifying the MAC Address
Before the devices can be connected to the VLAN (see #Network section below), their network card MAC address must be determined, and tied to each Brightsign unit ID.

The MAC Address is printed on the bottom of each Brightsign unit, so it may be found by reading it off the label.

OR if can't get to the bottom of each unit because you've screwed each Brightsign to the wall, as we've done, the Brightsign Info Screen, described in Step 3 above, also displays the MAC address when you power the unit up without an SD card inserted.

Record the MAC Address, add it to a spreadsheet tracking each unit, as well as the map document.

### Patch the Firmware
There are two ways to patch the firmware on a Brightsign unit: with an SD Card and over the network once a persistent installation has been set up. We don't have a working network yet, so we're going with the SD Card option.

Firmware can be downloaded from [Brightsign's Download site](https://www.brightsign.biz/downloads/overview), and in our case we want firmware for the [Brightsign HD (1020) unit](https://www.brightsign.biz/downloads/hd-series). Use this to check if there's new firmware for the unit (compared to the firmware displayed on the info screen).

Because we want to reflash the players entirely, I've used the BrightAuthor show authoring environment to [set up a new player](https://www.youtube.com/watch?v=rmnh783ug0o). Rather than save the files directly to an SD Card, I save them to a folder in the filesystem, then copy them to an SD Card. Be sure to click the "Upgrade Firmware" button to specify patching to the latest stable version for a Brightsign 1020.

See Brightauthor section [TODO] for instructions on running BrightAuthor in a Virtual Machine.

`The other option is download the firmware directly and put it on a blank SD Card, which I haven't tried yet.`

To patch the Brightsign, unplug it, insert the HD card with the firmware upgrade, and plug the power back in. The upgrade will take several minutes, during which the Upgrade light will flash. If successful, the Brightsign will attempt to delete the new firmware off the SD card once it has completed. It is possible to preserve the firmware upgrade on the SD card by sliding the write protect switch on (usually down). However by turning write protect on, it will trigger an error at the end of the upgrade process, whereby the upgrade and error lights will flash rapidly 12 times; this is ok. Remove the SD card, unplug and replug the Brightsign, and when the info screen pops up, you should see the firmware at the latest version.

# Network
