Notes
=======




# Networked File Structure:
Root structure:
 - `brightsign-dumps/` - empty directory
 - `feed_cache/` - empty directory
 - `pool/` - Asset storage. 2 directories deep. This is two levels deep, and the subdirectories are organized by the last two hex digits (oh fine, characters) of the sha1 hash of the file. SO... to make sense of this: a file with the sha1sum of `03cfd743661f07975fa2f1220c5194cbaff48451` would be located at `pool/5/1/sha1-03cfd743661f07975fa2f1220c5194cbaff48451`.
- `autoplugin.brs` - a do not delete warning
- `autorun.brs` - Presumibly a startup script
- `current-sync.xml` - manifest of what projects to download and run. This appears to be everything necessary for connection rules (where to go to download a future sync and credentials to do so), what projects to download (instructions on how to run a project - itself an xml file), media assets for a presentation, and the schedule which each presentation runs for

**Don't put any additional files or folders into the presentation folder** when it gets written to disk. It's worth noting that the HD1020 units seem to crash whenever there's other content on there (i.e. my silly `kiddie_pool/` folders with the normalized files inside the `pool/` directory). Not sure if this is true for networked mode, but it sure is true when it's running direct from an SDCard.

# Differences between publishing to simple network vs writing to sdcard

The good news here is that the system structure for a networked presentation appears to be pretty close to the SDcard.

<table>
  <tr>
    <th>Local Mode (SDcard)</th>
    <th>Network Mode</th>
  </tr>
  <tr>
    <td>
      * file manifest: `local-sync.xml` - all the files on the card.

    </td>

    <td>
      * File Manifest: `current-sync.xml` - all the files on the network.
    </td>
  </tr>
</table>


# Things you still have to do:
* [x] figure out pool filesystem structure
  * all "files" are enumerated in a `-sync` manifest. Then written into pool renamed as: `pool/sha1(filecontents)[-2]/sha1(filecontents)[-1]/sha1-sha1(filecontents)`
* [ ] Determine all the differences between a local sync and a network sync
* [ ] Determine all the things that are used for the video characteristics probe (e.g. `<probe>2|TT=MP4|IX=Y|AP=2|AC=AAC|ACH=2|ASR=44100|AD=00002061|VP=1|VC=H264|W=320|H=240|VD=000020b7|CD=0|D=000020b8|FT=00000000</probe>`)
 * [ ] Write a script to do that automagically
* [ ] Replace a video by hand
* [ ] Replace a video automagically
* [ ] Automate creation of a master playlist (w/ video) and guest presentation (w/ video)



# Making sense of the video probe date
`<probe>2|TT=MP4|IX=Y|AP=2|AC=AAC|ACH=2|ASR=44100|AD=00002061|VP=1|VC=H264|W=320|H=240|VD=000020b7|CD=0|D=000020b8|FT=00000000</probe>`


From [Brightscript object docs](http://docs.brightsign.biz/display/DOC/roVideoPlayer):

> ProbeFile(filename As String) As roAssociativeArray
>
> Returns an associative array containing metadata about the specified video file. To retrieve metadata about a file that is currently playing, use the GetStreamInfo() method instead. The returned associative array can contain the following parameters:
>
> * Source: The URI of the file
> * Encapsulation: The encapsulation of the video
> * AudioFormat: The format of the audio file
> * AudioSampleRate: The audio sample rate (in hertz)
> * AudioChannelCount: The number of audio channels
> * AudioDuration: The duration of the audio track
> * VideoFormat: The format of the video file
> * VideoColorDepth: The color depth of the video (in bits)
> * VideoWidth: The width of the video (in pixels)
> * VideoHeight: The height of the video (in pixels)
> * VideoAspectRatio: The aspect ratio of the video
> * VideoDuration: The duration of the video
