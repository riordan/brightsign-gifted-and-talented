BrightAuthor (and working in VirtualBox)
========================================

Authoring content for Brightsigns usually happens within their [BrightAuthor software](https://www.brightsign.biz/digital-signage-products/brightauthor), a Windows-only program that's used to create "Shows" (content) as well as configuring Brightsign units.

We work on Mac OSX. So that's a bit of a pain. This document should serve as a guide to working with BrightAuthor inside VirtualBox.

# Getting Windows and installing BrightAuthor

1. Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads) **AND Virtualbox Guest Additions**. Guest additions is needed to share files between your "Host OS (mac)" and the "Guest OS" (windows). Make sure you install the guest additions version thats the same as your core virtualbox installation.
2. Download an [IE VM from Microsoft](https://developer.microsoft.com/en-us/microsoft-edge/tools/vms/). Microsoft provides free versions of Windows in virtual machines available for web developers to test different versions of Internet Explorer. I've been working with `Virtual Machine: IE11 on Win7 | Platform: VirtualBox`
3. Add the IE VM to VirtualBox and wait a minute while you deal with the cognitive dissonance that comes from seeing Windows on your pristine Mac.
4. Open Internet Explorer. Yeah. You're doing this. Install the latest version of [BrightAuthor software](https://www.brightsign.biz/digital-signage-products/brightauthor).

## 5. [Set up a "Shared Folder" with the host computer](http://www.htpcbeginner.com/setup-virtualbox-shared-folders-linux-windows/)
for saving and moving brightsign files to SD cards.


## Set VirtualBox to deal with smaller monitors (and big windows)
6. If you're using a small-screened laptop, some of the critical windows in BrightAuthor are too big to fit on a standard 12-in Macbook, so you'll have to configure VirtualBox to be ok with fake monitor sizes.
