"""
Module 6: Collecting the data

This top level script will use all of the modules to collect the data.
It will continue to collect songs until a user specified number of songs
are collected.

Each iteration, the function will save to a csv file. That way, if there
is any interruption, the data up to that point will be saved.
"""

import pandas
from put_together_song_data import put_together_song_data

# Have the user input the desired number of songs
number_of_songs = input("Input Your Desired Number of Songs: ")

# Have the user input their spotify client id
my_spotify_client_id = input("Input Your Spotify Client Id: ")

# Have the user input their spotify client secret
my_spotify_client_secret = input("Input Your Spotify Client Secret: ")

# Have the user input their genius client access token
my_genius_client_access_token = input("Input Your Genius Client Access Token: ")

# Create a new blank csv with the necessary columns
song_master_template = pandas.DataFrame(columns = [
    "SongId",
    "SpotifyUrl",
    "SongName",
    "ArtistName",
    "ReleaseDate",
    "ReleaseDatePrecision",
    "DurationMs",
    "Danceability",
    "Energy",
    "Key",
    "Loudness",
    "Mode",
    "Speechiness",
    "Acousticness",
    "Instrumentalness",
    "Liveness",
    "Valence",
    "Tempo",
    "TimeSignature",
    "Popularity",
    "GeniusUrl",
    "AnnotationCount",
    "LyricsState",
    "PageViews",
    "SongLyrics"
])

# Write that csv file to the pathway specified
song_master_template.to_csv("song_master.csv", index = False)

# Initiate a song counter
song_counter = 0

# Loop through as many songs as possible writing each time
while song_counter < int(number_of_songs):
    
    # Read in the current song master
    temp_song_master = pandas.read_csv("song_master.csv")
    
    # Gather a new song dictionary
    temp_song_dict = put_together_song_data(my_spotify_client_id, my_spotify_client_secret, my_genius_client_access_token)
    
    # Check that the new song doesnt already exist
    song_check = temp_song_dict["SongId"] in temp_song_master.SongId
    
    # If the song already exists, start a new loop
    if song_check: continue
    
    # Append the dictionary to the song master
    temp_song_master = temp_song_master.append(temp_song_dict, ignore_index = True)
    
    # Write the new song master
    try: temp_song_master.write_csv("song_master.csv", index = False)
    except: continue
    
    # Add one to the counter after each iteration
    song_counter += 1
    
    # Print a progress update after each iteration
    print(song_counter, " Songs Gathered...")