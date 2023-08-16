"""
Module 3: Get the Genius.com link from the Genius API

Next, based on the song name and the artist name, a search is conducted for the song on
the genius API. Similar to the Spotify search, the search may return multiple results.
To ensure that the correct song is chosen, the artist name must be a match. The first
search result where the artist name matches is selected. In most cases, the correct result
will be the first result, but not always.

The challenge is that not all of the Genius links can be easily formed. It is true that all
of the Genius links follow the same general format of https://genius.com/artistname-songname-lyrics
(for example https://genius.com/Mac-miller-good-news-lyrics), so you would think that it could
be easily constructed using the artist name and the song name. But this does not always work. For
example, when the title of a song from Spotify does not match exactly what it is on Genius, the
URL would not be valid. Not only that, but the URL might not even exist in the first place, for example
if it hasnt been created yet on genius. This process ensures that a valid link is found.

The user must have a valid set of Genius API credentials. The client access token is used as
an argument in the function. This can be acquired by signing up for a Genius developer account.

In addition to the link to the Genius page for the song, a few additional pieces of information
will be gathered in this function as described below:

genius_url = the url for the song lyrics on genius

annotation_count = how many annotations have been made to the lyrics for the song

lyrics_state =

page_views = the number of times that the page has been viewed on genius

Credit to the following resources for assisting in the development of this code.

https://bigishdata.com/2016/09/27/getting-song-lyrics-from-geniuss-api-scraping/
https://melaniewalsh.github.io/Intro-Cultural-Analytics/04-Data-Collection/07-Genius-API.html#your-turn
"""

from requests import get

def get_genius_link(genius_client_access_token, song_name, artist_name):

    # Construct the genius search url
    genius_search_url = "".join([
        "http://api.genius.com",
        "/search?q=",
        song_name,
        "&access_token=",
        genius_client_access_token
    ])
    
    # Make the API call and get the json response
    response = get(genius_search_url)
    json_data = response.json()
    
    # Iterate through each hit until the artist is a match
    try:
        song_info = None
        for hit in json_data["response"]["hits"]:
            if hit["result"]["primary_artist"]["name"] == artist_name:
                song_info = hit["result"]
                break
    except:
        song_info = None
        
    # Retrieve the url for the page
    try: path = song_info["path"]
    except: path = None
    try: genius_url = "https://www.genius.com" + path
    except: genius_url = None
    
    # Retrieve the annotation count
    try: annotation_count = song_info["annotation_count"]
    except: annotation_count = None
    
    # Retrieve the lyrics state
    try: lyrics_state = song_info["lyrics_state"]
    except: lyrics_state = None
    
    # Retrieve the page views
    try: page_views = song_info["stats"]["pageviews"]
    except: page_views = None
    
    # Save all of that in a dictionary
    genius_dict = {
        "GeniusUrl" : genius_url,
        "AnnotationCount" : annotation_count,
        "LyricsState" : lyrics_state,
        "PageViews" : page_views
    }
    
    # Return the dictionary
    return genius_dict