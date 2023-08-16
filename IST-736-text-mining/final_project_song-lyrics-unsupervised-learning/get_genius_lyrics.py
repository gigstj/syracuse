"""
Module 4: Get genius lyrics from web scraping Genius.com

Genius.com is one of the most popular domains for getting song lyrics. Unfortunately,
Genius.com does not include lyrics as part of their API. Therefore, the only way to
get the lyrics is to use web scraping. The following code will attempt to web scrape the
lyrics from a given genius.com lyrics link.

The genius.com page returns two different versions of html, so the correct version must be
dynamically selected. The Beatufiul Soup package will assist in extracting the text from
there.

No cleaning will be done to the lyrics, so they will come out in their rawest form.
The reason for this is to leave the cleaning process up to the user, since there can be
different needs depending on the task.

Web scraping is not always perfect. As such, there may be times where the lyrics are not
successfully captured. If there is any kind of error along the way, a value of None will
be returned.

Credit to the following resources for assisting in the development of this code.

https://stackoverflow.com/questions/63722512/error-while-scraping-website-using-beautifulsoup  
"""

from requests import get
from bs4 import BeautifulSoup

def get_genius_lyrics(genius_lyrics_link):

    # Attempt to scrape the lyrics
    version1 = """div[class^="Lyrics__Container"]""" # The first version of html
    version2 = """.song_body-lyrics p""" # The second version of html
    try:
        page = get(genius_lyrics_link) # Establish a connection to the web page
        soup1 = BeautifulSoup(page.content, "lxml") # Scrape the content from the web page
        soup2 = soup1.select(version1 + "," + version2) # Dynamically select the correct html version
        lyrics = "\n".join([tag.get_text(separator = "\n") for tag in soup2]) # Extract the lyrics
    except:
        lyrics = None # If there was an error, return None
    
    # Return the lyrics
    return lyrics