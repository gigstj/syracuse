"""
Module 5: Putting it all together

The main purpose of this module is to use modules 1 - 4 to get the song data
and ensure that the data is in the appropriate form for further use. That means
combining all of the information together and outputting one nice dictionary.

This module also does some checks on the outputs from the modules, and ensures that
the data is fit for use. There are several checks including:

(a) the song is in English
(b) the lyrics are not None
(c) the length of the lyrics is greater than a specified threshold
    
If any of these conditions are violated, the entire program will restart. It will
continue to try to get another song until the conditions are satisfied.

The number of attempts is tracked incase a problem occurs that causes the loop to
get stuck. The loop will break at 100 consecutive failures.
"""

from time import perf_counter
from langid import langid
from get_random_song import get_random_song
from get_song_metadata import get_song_metadata
from get_genius_link import get_genius_link
from get_genius_lyrics import get_genius_lyrics

def put_together_song_data(spotify_client_id, spotify_client_secret, genius_client_access_token):

    # Start a timer
    start = perf_counter()

    # Initiate the conditions that need to be met
    condition1 = False
    condition2 = False
    condition3 = False
    
    # Number of attempts
    attempt_counter = 0
    
    # Loop through the modules until all the conditions are met
    while condition1 == False or condition2 == False or condition3 == False:
    
        # Check the attempt counter, if it is at 100 break out and print a message
        if attempt_counter >= 100:
            print("Error Maximum Number of Attempts Reached")
            break
    
        # Module 1: get a random song
        try:
            song_id = get_random_song(spotify_client_id, spotify_client_secret)
        except:
            attempt_counter += 1
            continue
        
        # Module 2: get song metadata
        try:
            song_metadata = get_song_metadata(spotify_client_id, spotify_client_secret, song_id)
        except:
            attempt_counter += 1
            continue
        
        # Module 3: get genius link
        try:
            genius_dict = get_genius_link(genius_client_access_token, song_metadata["SongName"], song_metadata["ArtistName"])
        except:
            attempt_counter += 1
            continue
            
        if genius_dict["GeniusUrl"] == None:
            attempt_counter += 1
            continue
        
        # Module 4: get genius lyrics
        try:
            genius_lyrics = get_genius_lyrics(genius_dict["GeniusUrl"])
        except:
            attempt_counter += 1
            continue
        
        # Check that the song is in english
        try:
            language = langid.classify(genius_lyrics)[0]
        except:
            attempt_counter += 1
            continue
            
        if language == "en":
            condition1 = True
        else:
            attempt_counter += 1
            continue
            
        # Check that the lyrics are not None
        if genius_lyrics != None:
            condition2 = True
        else:
            attempt_counter += 1
            continue
            
        # Check that the lyrics meet the specified length
        if len(genius_lyrics) > 50:
            condition3 = True
        else:
            attempt_counter += 1
            continue
            
    # After exiting the loop, put everything together
    final_dict = {**song_metadata, **genius_dict}
    final_dict["SongLyrics"] = genius_lyrics
    final_dict["Attempts"] = attempt_counter + 1
    
    # Clock out and add the time elapsed as an attribute
    end = perf_counter()
    final_dict["CollectionTime"] = end - start
    
    # Finally return the dictionary
    return final_dict