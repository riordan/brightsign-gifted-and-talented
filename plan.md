Project Plan
============
# Where We're At
Philosophizing. Soon to move to Proof of Concept

# The Ideal


# Getting There
This plan is inspired by a video from Brightsign on how to synchronize presentations ([mp4](_media/brightsign-sync-presentation.mp4)) between several units. It was never published on their site, which explains why we tried something close to this in the past, but may have not intuited some details that are necessary to keep it working (it's not that intuitive).

## Proof of Concept
- [ ] Set up two or more brightsign units as a Synchronized presentation
- [ ] Ensure the players can run videos that do not fall out of sync (e.g showing a video that requires perfect alignment) across many loopings (e.g. 1-2 weeks)
- [ ] Ensure that the videos can be changed out at the NAS regularly and the new videos will be propagated to their correct players

## Baseline
* [ ] A script that is aware of the configuration of both "Frames" and can assemble a presentation of images that cycles through each of the images with the correct orientations with a variety of transitions / reveal patterns. Takes as an input a series of images, outputs n videos.
* [ ] A second script that copies each of the videos to a network drive, where each brightsign in the array is configured to fetch its corresponding video and loop appropriately.
* [ ] Both "Frames" are set up to run from this system, which is off of the official Columbia network.

## First Draft

## Slightly More Ideal
