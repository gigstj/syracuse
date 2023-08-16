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
def GetStocksData():

    """
    This function returns a dataframe with the daily closing price for the DJI and NASDAQ
    indexes from yahoo finance.
    """
    
    # Get the DJI price data
    DJIData = Ticker("DJI").history(period = "max", interval = "1d")
    
    # Add date as a column instead of being the index
    DJIData["Date"] = [str(Date)[0:10] for Date in DJIData.index]

    # Only keep the date and the closing price columns
    DJIData = DJIData[["Date", "Close"]]

    # Rename the columns
    DJIData.columns = ["Date", "DJIPrice"]

    # Reset the indices
    DJIData = DJIData.reset_index(drop = True)

    # Get the NASDAQ price data
    NASDAQData = Ticker("^IXIC").history(period = "max", interval = "1d")

    # Add date as a column instead of being the index
    NASDAQData["Date"] = [str(Date)[0:10] for Date in NASDAQData.index]

    # Only keep the date and the closing price columns
    NASDAQData = NASDAQData[["Date", "Close"]]

    # Rename the columns
    NASDAQData.columns = ["Date", "NASDAQPrice"]

    # Reset the indices
    NASDAQData = NASDAQData.reset_index(drop = True)

    # Join the DJI and NASDAQ data
    Stocks = DJIData.merge(NASDAQData, how = "outer")

    # Return the final dataframe
    return Stocks