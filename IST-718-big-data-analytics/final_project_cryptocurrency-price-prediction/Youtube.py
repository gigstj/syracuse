# Import the necessary packages
from googleapiclient.discovery import build
from pandas import DataFrame, read_csv, date_range, concat
from datetime import datetime, date, timedelta

"""
Resources
https://developers.google.com/youtube/v3/docs/search/list  
https://medium.com/mcd-unison/youtube-data-api-v3-in-python-tutorial-with-examples-e829a25d2ebd#caae  
https://www.analyticssteps.com/blogs/how-extract-analyze-youtube-data-using-youtube-api  
https://medium.com/easyread/understanding-about-rfc-3339-for-datetime-formatting-in-software-engineering-940aa5d5f68a
"""

# Define a function to return the youtube video count
def GetYoutubeVideoCount(YoutubeAPIKey, Slug, AfterDate, BeforeDate):

    """
    This function takes in a youtube API key (more instruction on how to get this in
    the resources), a cryptocurrency slug (such as "bitcion" or "ethereum"), an after date
    (in yyyy-mm-dd format), and a before date (in yyyy-mm-dd format) and returns the
    estimated number of youtube videos that show up in the search.
    """

    # Youtube API requires that the publishedAfter and publishedBefore arguments
    # are RFC 3339 formatted date-time values (example: 1970-01-01T00:00:00Z)
    # See https://developers.google.com/youtube/v3/docs/search/list for documentation

    # Convert AfterDate into required format for API call
    AfterDateConverted = AfterDate + "T00:00:00Z"

    # Convert BeforeDate into required format for API call
    BeforeDateConverted = BeforeDate + "T00:00:00Z"

    # Save youtube API information
    APIServiceName = "youtube"
    APIVersion = "v3"

    # Initiate a youtube client
    YoutubeClient = build(APIServiceName, APIVersion, developerKey = YoutubeAPIKey)

    # Construct the API request
    YoutubeRequest = YoutubeClient.search().list(
        part = "id, snippet",
        type = "video",
        q = Slug,
        publishedAfter = AfterDateConverted,
        publishedBefore = BeforeDateConverted,
        fields = "pageInfo.totalResults",
    )

    # Execute the API request
    YoutubeResponse = YoutubeRequest.execute()

    # Return the response
    return YoutubeResponse["pageInfo"]["totalResults"]