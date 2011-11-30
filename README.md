MrEko
=====
MrEko analyzes your music and lets you ask him in-depth questions about it.  He answers in playlists.

Example:
--------
    # Scan a directory, recursively:
    mreko scan ~/Music/iTunes

    # Scan a set of files
    mreko scan jakob-semaphore.mp3 pelican-drought.mp3

    # Output a PLS playlist of fast, minor-key music
    mreko playlist --tempo '>120' --mode minor --format pls > rainy_day_suicidal_playlist.pls

    # Output a playlist of shorter,  up-tempo, danceable, major-keyed songs
    mreko playlist --preset gym --format pls > sweaty_playlist.pls

Requirements:
-------------
* [ffmpeg](http://www.ffmpeg.org/download.htmlr) in your path.
* an [Echonest API token](http://developer.echonest.com/) which goes here: ~/.mreko/echonest_api.key

Notes:
------
MrEko will make an audio fingerprint of a music file and attempt to use it to identify the song.  This is faster but not always successful (due to Echonest limitations) so some songs must be uploaded to Echonest.  This means that scanning a large and/or somewhat eclectic library **could take a good while**.
