# VIDIOT
A utility for downloading videos and/or audio from websites

## Options

| short option  | long option             | argument | default arg | possible args | explanation |
| ------------: | :-----------            | :------- | ----------: | :------------ | :---------- |
|   -l | <nobr>--loop</nobr>              |||| After processing a queued request, find the next, or sleep until one is available. The default is to just exit. | 
| -np  | <nobr>--noplaylist</nobr>        |||| If the requested download is part of a YouTube playlist, do not download the entire playlist.  The default is to download all before considering the request complete.
| -mts | <nobr>--modifytimestamp </nobr>  |||| Update the timestmp of the file using the 'Last-modified' header of the URL to the item. Default behavior is not to use the header, and just let the OS set the timestamp as it normally would.  
| -vf  | <nobr>--videoformat</nobr>       | **format** | ```mp4```  | ```mp4, vid```  | Use **format** encoder for video content.
| -af  | <nobr>--audioformat</nobr>       | **format** | ```mp3```  | ```mp3, aac```  | Use *format* encoder for audio-only content.
| -vaf | <nobr>--videoaudioformat</nobr>  | **format** | ```m4a```  | ```m4a```       | Use *format* encoder for AV (audio+video) content.
| -ab  | <nobr>--audiobitrate</nobr>      | **bits**   | ```320k``` | *bitrate* | Use *bits* bitrate to encode the output when extracting audio only.  Bitrates are specified as a number followed by an optional character representing magnitude, e.g., **128k**  
| -vab | <nobr>--videoaudiobitrate</nobr> | **bits**   | ```320k``` | *bitrate* | Use *bits* bitrate to encode the audio stream when extracting video.  Bitrates are specified as a number followed by an optional character representing magnitude, e.g., **256k**  
| -Mh  | <nobr>--maxheight</nobr>         | **pixels** | ```720``` | *integer* | When choosing the version of the video to download, don't choose one that is more than *pixels* pixels tall (e.g., the '1080' in 1080p usually corresponds to a resolution of 1920*1080).  The default is 720.  
| -mh  | <nobr>--minheight</nobr>         | **pixels** | ```10```  | *integer* | When choosing the version of the video to download, don't choose one that is less than *pixels* pixels tall (see *--maxheight* for details)'
| -cb  | <nobr>--cookies-from-browser</nobr> | **browser** | ```chrome``` | ```chrome, opera, edge, safari, ...``` | Use cookies for the **browser** browser to gain the same capabilities as you have in the browser (e.g.,YouTube Premium).  You should make sure you are authenticated in the browser if using this option.  The default is to download as just an anonymous user with all of the privileges that an anonymous user has. |
| -v   | <nobr>--verbose</nobr>           |||| Provides extra logging to *STDOUT* |
| -s   | <nobr>--sleeptime</nobr>         | *seconds* | ```5``` | *integer* | When looping (i.e. *--loop* option), sleep for *seconds* seconds between iterations. |
| -s   | <nobr>--simulate</nobr>          |||| Don't actually execute the executable that does the downloading; just show the command that would have been called (for debugging)  
| -qd  | <nobr>--queuedir</nobr>          | **path** | *see explanation* | *see explanation* | Look for requests in the *path* folder.  This can be a full path or a relative path, but must exist.  Default is the 'Downloads' folder in the current user's home directory.  
| -dd  | <nobr>--downloaddir</nobr>       | **path** | *see explanation* | *see explanation* | Download to the *path* folder.  This can be a full path or a relative path, but must exist.  Default is the 'DownloadedMusic' folder in the folder where we look for requests (see *--queuedir*).  
| -qp  | <nobr>--queuepattern</nobr>      | **pattern** | ``` VIDIOT*.tsv ``` | *see explanation* | Expect requests to be files named according to the pattern "*pattern*".  This isn't interpreted as a regex, but just using the OS's filename pattern scheme.
| -e   | <nobr>--executable</nobr>        | **path** | <nobr>```/opt/homebrew/bin/yt-dlp ```</nobr> | *see explanation* | Use **path** as the path to the executable that does the downloading.  This can be a full path or a relative path, but must exist.
| -nr  | <nobr>--no_rm</nobr>             |||| Don't remove the request file(s) after processing the request.  The default is to remove the request file if the download exited successfully. 