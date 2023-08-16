"""
Module 1: Retrieve a random song from the Spotify API

The way this module works is as follows:
(a) a call is made to the Spotify API which conducts a search
(b) many results are returned, as if searching in the Spotify app
(c) the selected offset serves as the index of the result to return.

The following criteria is used for the search
(a) a search term (selected randomly from a list of 15 different search terms)
(b) a year (selected randomly from all years between 1970 and the current year)
(b) an offset (selected randomly from a list of integers between 0 and 1000)

Depending on the search term and the year, different results will show up in
the search. There are 15 search terms to choose from; one with a wildcard in
front of the string, one with a wildcard in the middle of the string, and one
with the wildcard at the end of the string, for each of the 5 vowels in the
alphabet. According to the documentation on the Spotify web API reference page,
the offset must be an integer between 0 and 1000. Additionally, I am using an
argument to specify that only US songs should be returned.

The user must have a valid set of Spotify API credentials which are used
as arguments in the function. These can be acquired by signing up for a Spotify
developer account.

Credit to the following resources for assisting in the development of this code.

https://developer.spotify.com/documentation/web-api/reference/#/operations/search
https://github.com/ZipBomb/spotify-song-suggestion/blob/master/random_song.py
"""

from random import randint, choice
from datetime import datetime
from base64 import b64encode
from requests import post, get
from json import loads

def get_random_song(spotify_client_id, spotify_client_secret):

    # Select a random search term from a list of 15 search terms
    random_term = [
        "%25a%25", "a%25", "%25a",   # Search terms for vowel "a"
        "%25e%25", "e%25", "%25e",   # Search terms for vowel "e"
        "%25i%25", "i%25", "%25i",   # Search terms for vowel "i"
        "%25o%25", "o%25", "%25o",   # Search terms for vowel "o"
        "%25u%25", "u%25", "%25u"    # Search terms for vowel "u"
    ] [randint(0, 14)]
    
    # Select a random offset between 1 and 1000
    random_offset = randint(0, 1000)
    
    # Select a random year between 1970 and the current year
    random_year = randint(1970, datetime.now().year)

    # Save some initial url info for accessing the api
    url_token = "https://accounts.spotify.com/api/token"
    url_api = "https://api.spotify.com/v1"

    # Get the client token
    client_token = spotify_client_id + ":" + spotify_client_secret
    client_token = client_token.encode("UTF-8")
    client_token = b64encode(client_token)
    client_token = client_token.decode("ascii")

    # Get the access token
    headers = {"Authorization": "Basic " + client_token}
    data = {"grant_type": "client_credentials"}
    request = post(url_token, data = data, headers = headers)
    access_token = loads(request.text)["access_token"]

    # Make the song request and get the song info
    headers = {"Authorization": "Bearer " + access_token}
    base_query = "q=track:" + random_term + " year:" + str(random_year)
    more_args = "&type=track&offset=" + str(random_offset) + "&market=US"
    api_call = url_api + "/search?" + base_query + more_args
    request = get(api_call, headers = headers)
    song_info = choice(loads(request.text)["tracks"]["items"])

    # Return the song id
    return song_info["id"]