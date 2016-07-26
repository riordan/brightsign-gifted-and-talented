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

## Brightsign Support Note:
> I'm sure you're already aware that the players don't need (and in almost all cases should not have) inbound access from the Internet, so that's the last I'm going to mention of it unless you ask. :)
> 
> If your content is only video and you don't need separate audio for each display, you might want to consider using a BrightWall. BrightWall might not have existing back when you did your initial installation.
> 
> With a BrightWall, you would just set up a single Regular BrightWall Presentation set up for the 50 displays (the row/column dimensions don't really matter for this kind of use), and you can assign video content to each display and publish it as a single project though you do have to tell it which screen "maps" to which unit, though most times it remembers.
> 
> That said, in response to your usage scenario, the current-sync.xml is the "sync spec" and it contains all the files for the presentation and their download locations. Files within the pool folder are stored by their SHA-1 hash value, in subfolders corresponding to the last two hash digits. So, if a file's hash ends in cd, it would be in /pool/c/d stored.
> 
> However, this only matters to the associated autorun which downloads the files per the sync spec, and when everything has completed downloading, it interprets the autoplay file for the presentation.
> 
> So unless you're authoring with BrightAuthor and can deliver an autoplay file that the core autorun can interpret, it's probably not much use to create a sync spec outside of just swapping content in a presentation. It would get a bunch of files downloaded, but not do anything after that.
> 
> The probe comes from ffprobe and is used as a hinting mechanism, again for the autorun+autoplay combination to display content.
> 
> Depending on the complexity of what you intend to display it might be easier to just use a data feed to populate a state.
> 
> The core question is, how do you envision the content the players are showing? I get that they should all be in sync, but are they all playing simple video, or are some of them showing content in a different layout, with additional information like time or a schedule?
> 
> Once we have a better understanding of that, we can make more recommendations.
> 
> // Brandon -- --- -- --- ---
> TIP: If you can't find what you're looking for in our support section, try using Google to search our site:
> Search for _search_terms_ site:brightsign.biz
> For example, supported touchscreens site:brightsign.biz
