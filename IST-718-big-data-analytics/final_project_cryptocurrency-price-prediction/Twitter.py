# Import the necessary packages
from tweepy import Client
from datetime import datetime, timedelta

"""
Resources
https://developer.twitter.com/en/docs/twitter-api/tweets/counts/introduction  
https://dev.to/twitterdev/a-comprehensive-guide-for-using-the-twitter-api-v2-using-tweepy-in-python-15d9  
https://docs.tweepy.org/en/stable/client.html  
https://developer.twitter.com/en/docs/twitter-api/tweets/search/integrate/build-a-query
"""

# Define a function to return the tweet count
def GetTwitterTweetCount(TwitterBearerToken, AssetTicker):

    """
    This function returns the tweet count over the last 24 hours for
    any tweets that contain a hashtag with the given cryptocurrency ticker.
    """
    
    # Save the start time stamp
    StartTime = datetime.strftime(datetime.now() - timedelta(days = 1), "%Y-%m-%d") + "T00:00:00Z"
    
    # Save the end time time stamp
    EndTime = datetime.strftime(datetime.now(), "%Y-%m-%d") + "T00:00:00Z"
    
    # Initiate a tweepy client
    TweepyClient = Client(bearer_token =  TwitterBearerToken)
    
    # Return the tweet count
    return TweepyClient.get_recent_tweets_count(
        query = "#" + AssetTicker,
        start_time = StartTime,
        end_time = EndTime,
        granularity = "day"
    ).meta["total_tweet_count"]