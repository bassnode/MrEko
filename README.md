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

    # Output a 30 minute playlist which builds from tempo 120 to 185 BPM. See notes on TimedPlaylists below.
    mreko playlist --timed 1800 --tempo 120 --final 185 > morning_commute.pls

    # Output an hour-long playlist which gradually decreases in energy.
    mreko playlist --timed 3600 --energy 100 --final 30 > evening_wind_down.pls

Requirements:
-------------
* [ffmpeg](http://www.ffmpeg.org/download.html) in your path.
* an [Echonest API token](http://developer.echonest.com/) which goes here: ~/.mreko/echonest_api.key

TimedPlaylists:
---------------
TimedPlaylists are different than standard Playlists in that they are both limited by time (surprise!) and are built around one "facet".
A facet is one of the Playlist options such as tempo, key, energy, mode, etc.  You specify the length of the playlist (in seconds), the facet
upon which the playlist is filtered and sorted, and then the initial and final values for the facet. E.g. a 45 minute playlist which starts in
Minor key and ends Major:
    mreko playlist --timed 2700 --mode minor --final major

Notes:
------
MrEko will make an audio fingerprint of a music file and attempt to use it (along with ID3 tags) to retrieve data from Echonest.
This can be fast but not always successful due to Echonest catalog limitations, so some songs must be uploaded to Echonest.
This means that scanning a large and/or somewhat eclectic library **could take a good while**.
