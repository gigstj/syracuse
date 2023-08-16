# Import the necessary packages
from pytrends.request import TrendReq
from pandas import DataFrame

"""
Resources
https://lazarinastoy.com/the-ultimate-guide-to-pytrends-google-trends-api-with-python/#interestovertime  
https://pypi.org/project/pytrends/  
https://predictivehacks.com/get-google-trends-using-python/  
https://github.com/GeneralMills/pytrends/issues/388  
https://stackoverflow.com/questions/49732639/pytrends-google-trends-daily-freq  
https://github.com/qztseng/google-trends-daily/blob/master/google%20Trend%20daily%20data%20for%20iphone.ipynb  
https://jackolson415.medium.com/how-to-collect-google-trends-data-in-python-with-the-pytrends-api-535384dfa940
"""

# Define a function to return the last 5 years of daily google trend interest for a ticker
def GetGoogleTrendData(Keyword):

    """
    This function takes in a keyword and returns a dataframe with the last 5 years of google
    trend interest over time by day. The dataframe starts off by week but resampling is used
    to extrapolate into days.
    """
    
    # Initiate PyTrend
    PyTrend = TrendReq()
    
    # Build the payload
    PyTrend.build_payload([Keyword])
    
    # Get the interest overtime for the last 5 years in weekly increments
    InterestWeekly = PyTrend.interest_over_time()
    
    # Use resampling to extrapolate the weekly increments into daily increments
    InterestDaily = DataFrame(InterestWeekly[Keyword].resample("d", convention = "start").pad()).reset_index()
    
    # Rename the columns
    InterestDaily.columns = ["Date", "InterestLevel"]
    
    # Return the InterestDaily dataframe
    return InterestDaily