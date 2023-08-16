# Import the necessary packages
from pandas import DataFrame
from yfinance import Ticker

"""
Resources
https://www.youtube.com/watch?v=R3kwD3RfxTU  
https://github.com/ranaroussi/yfinance  
https://stackoverflow.com/questions/52139506/accessing-a-pandas-index-like-a-regular-column  
"""

# Define a function to get crypto price data
def GetYahooFinancePriceData(AssetTicker):

    """
    This function takes in a ticker symbol and returns a dataframe
    of the historical price data from yahoo finance for the max
    duration of time in daily intervals in USD.
    """
    
    # Get the yahoo finance data for the given ticker symbol
    YahooFinanceData = Ticker(AssetTicker + "-USD").history(period = "max", interval = "1d")
    
    # Add date as a column instead of being the index
    YahooFinanceData["Date"] = [str(Date)[0:10] for Date in YahooFinanceData.index]
    
    # Add the ticker symbol as a new column
    YahooFinanceData["Ticker"] = AssetTicker
    
    # Return YahooFinanceData as the output of the function
    return YahooFinanceData.loc[:, ["Ticker", "Date", "Open", "High", "Low", "Close", "Volume"]].reset_index(level = None, drop = True)
    
