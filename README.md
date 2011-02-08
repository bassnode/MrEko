MrEko
=====
MrEko analyzes your music and lets you ask him in-depth questions about it.  He answers in playlists.

Example:
--------
    # Scan all your music
    mreko scan ~/Music/*.mp3

    # Output a PLS playlist of mid-tempo, minor-key music
    mreko playlist --min-tempo 100 --max-tempo 120 --mode minor --format pls > rainy_day_suicidal_playlist.pls

    # Output a playlist of shorter,  up-tempo, danceable, major-keyed songs
    mreko playlist --preset gym --format pls > sweaty_playlist.pls

Requirements:
-------------
* [ffmpeg](http://www.ffmpeg.org/download.htmlr) in your path.
* an [Echonest API token](http://developer.echonest.com/) which goes here: ~/.mr_eko/echonest_api.key

Notes:
------
MrEko will make an audio fingerprint of a music file and attempt to use it to identify the song.  This is faster but not always possible (due to Echonest limitations) so some songs must be uploaded to Echonest.  This means that scanning a large, somewhat eclectic library could take a good while.
