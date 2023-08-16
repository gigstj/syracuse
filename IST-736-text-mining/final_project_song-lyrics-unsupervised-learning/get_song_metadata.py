"""
Module 2: Get song metadata from the Spotify API

Using the song id provided by the get_random_song function, a call will
be made to the Spotify API to retrieve various pieces of information
about the song. The Spotipy package is used, which is a convenient Python
package for accessing the Spotify API. The information retrieved includes
the following:

song_name = the name of the song

artist_name = the name of the artist

release_date = the date that the album the song is associated with was
released. in most cases comes in full precision to the day in
yyyy-MM-dd format, but sometimes only year precision in yyyy format is
available.

release_date_precision = either "day" or "year" for the precision of the
release_date

song_duration = the duration of the song in milliseconds

song_popularity = the popularity of the track. The value will be between 0 and 100,
with 100 being the most popular. the popularity of a track is a value between 0 and
100, with 100 being the most popular. the popularity is calculated by algorithm and
is based, in the most part, on the total number of plays the track has had and how
recent those plays are. generally speaking, songs that are being played a lot now will
have a higher popularity than songs that were played a lot in the past. duplicate tracks
(e.g. the same track from a single and an album) are rated independently. note: the
popularity value may lag actual popularity by a few days: the value is not updated in
real time.

spotify_url = a direct link to the song on Spotify

danceability = danceability describes how suitable a track is for dancing based
on a combination of musical elements including tempo, rhythm stability, beat
strength, and overall regularity. a value of 0.0 is least danceable and 1.0 is
most danceable.

energy = energy is a measure from 0.0 to 1.0 and represents a perceptual measure
of intensity and activity. typically, energetic tracks feel fast, loud, and noisy.
for example, death metal has high energy, while a bach prelude scores low on the scale.
perceptual features contributing to this attribute include dynamic range, perceived
loudness, timbre, onset rate, and general entropy.

key = the key the track is in. integers map to pitches using standard pitch class
notation. E.g. 0 = C, 1 = C♯/D♭, 2 = D, and so on. if no key was detected, the value is -1.

loudness = the overall loudness of a track in decibels (dB). loudness values are
averaged across the entire track and are useful for comparing relative loudness of
tracks. loudness is the quality of a sound that is the primary psychological correlate
of physical strength (amplitude). values typically range between -60 and 0 db.

mode = mode indicates the modality (major or minor) of a track, the type of scale from
which its melodic content is derived. major is represented by 1 and minor is 0.

speechiness = speechiness detects the presence of spoken words in a track. the more
exclusively speech-like the recording (e.g. talk show, audio book, poetry), the closer
to 1.0 the attribute value. values above 0.66 describe tracks that are probably made
entirely of spoken words. values between 0.33 and 0.66 describe tracks that may contain
both music and speech, either in sections or layered, including such cases as rap music.
values below 0.33 most likely represent music and other non-speech-like tracks.

acousticness = a confidence measure from 0.0 to 1.0 of whether the track is acoustic.
1.0 represents high confidence the track is acoustic.

instrumentalness = predicts whether a track contains no vocals. "Ooh" and "aah" sounds
are treated as instrumental in this context. rap or spoken word tracks are clearly "vocal".
the closer the instrumentalness value is to 1.0, the greater likelihood the track contains
no vocal content. values above 0.5 are intended to represent instrumental tracks, but confidence
is higher as the value approaches 1.0.

liveness = detects the presence of an audience in the recording. higher liveness values
represent an increased probability that the track was performed live. a value above 0.8
provides strong likelihood that the track is live.

valence = a measure from 0.0 to 1.0 describing the musical positiveness conveyed by a track.
tracks with high valence sound more positive (e.g. happy, cheerful, euphoric), while tracks
with low valence sound more negative (e.g. sad, depressed, angry)

tempo = the overall estimated tempo of a track in beats per minute (BPM). in musical
terminology, tempo is the speed or pace of a given piece and derives directly from the
average beat duration.

time_signature = an estimated time signature. the time signature (meter) is a notational
convention to specify how many beats are in each bar (or measure). the time signature
ranges from 3 to 7 indicating time signatures of "3/4", to "7/4".

Credit to the following resources for assisting in the development of this code.

https://developer.spotify.com/documentation/web-api/reference/#/operations/get-several-audio-features
https://spotipy.readthedocs.io/
https://morioh.com/p/31b8a607b2b0
"""

from spotipy.oauth2 import SpotifyClientCredentials
from spotipy import Spotify

def get_song_metadata(spotify_client_id, spotify_client_secret, spotify_song_id):
    
    # Save credentials for the spotipy package
    credentials = SpotifyClientCredentials(spotify_client_id, spotify_client_secret)

    # Authenticate and initiate spotify object
    spotify = Spotify(client_credentials_manager = credentials)
    
    # Save the song metadata (JSON format)
    song_info = spotify.track(spotify_song_id)
    
    # Save the song audio features (JSON format)
    spotify_audio_dict = spotify.audio_features(spotify_song_id)[0]
    
    # Retrieve the song name
    try: song_name = song_info["name"]
    except: song_name = None

    # Retrieve the artist name
    try: artist_name = song_info["artists"][0]["name"]
    except: artist_name = None

    # Retrieve the release date
    try: release_date = song_info["album"]["release_date"]
    except: release_date = None
    
    # Retrieve the release date precision
    try: release_date_precision = song_info["album"]["release_date_precision"]
    except: release_date_precision = None

    # Retrieve the song duration
    try: song_duration = song_info["duration_ms"]
    except: song_duration = None

    # Retrieve the song popularity
    try: song_popularity = song_info["popularity"]
    except: song_popularity = None

    # Retrieve a direct link
    try: spotify_url = song_info["external_urls"]["spotify"]
    except: spotify_url = None

    # Retrieve the danceability
    try: danceability = spotify_audio_dict["danceability"]
    except: danceability = None

    # Retrieve the energy
    try: energy = spotify_audio_dict["energy"]
    except: energy = None

    # Retrieve the key
    try: key = spotify_audio_dict["key"]
    except: key = None

    # Retrieve the loudness
    try: loudness = spotify_audio_dict["loudness"]
    except: loudness = None

    # Retrieve the mode
    try: mode = spotify_audio_dict["mode"]
    except: mode = None

    # Retrieve the speechiness
    try: speechiness = spotify_audio_dict["speechiness"]
    except: speechiness = None

    # Retrieve the acousticness
    try: acousticness = spotify_audio_dict["acousticness"]
    except: acousticness = None

    # Retrieve the instrumentalness
    try: instrumentalness = spotify_audio_dict["instrumentalness"]
    except: instrumentalness = None

    # Retrieve the liveness
    try: liveness = spotify_audio_dict["liveness"]
    except: liveness = None

    # Retrieve the valence
    try: valence = spotify_audio_dict["valence"]
    except: valence = None

    # Retrieve the tempo
    try: tempo = spotify_audio_dict["tempo"]
    except: tempo = None

    # Retrieve the time_signature
    try: time_signature = spotify_audio_dict["time_signature"]
    except: time_signature = None
    
    # Save all of that in a dictionary
    audio_dict = {
        "SongId" : spotify_song_id,
        "SpotifyUrl" : spotify_url,
        "SongName" : song_name,
        "ArtistName" : artist_name,
        "ReleaseDate" : release_date,
        "ReleaseDatePrecision" : release_date_precision,
        "DurationMs" : song_duration,
        "Danceability" : danceability,
        "Energy" : energy,
        "Key" : key,
        "Loudness" : loudness,
        "Mode" : mode,
        "Speechiness" : speechiness,
        "Acousticness" : acousticness,
        "Instrumentalness" : instrumentalness,
        "Liveness" : liveness,
        "Valence" : valence,
        "Tempo" : tempo,
        "TimeSignature" : time_signature,
        "Popularity" : song_popularity
    }
    
    # Return the audio dictionary
    return audio_dict