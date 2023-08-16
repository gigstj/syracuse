# Import the necessary packages
from requests import Request, Session
from json import loads
from pandas import DataFrame
from datetime import datetime

"""
Resources
https://coinmarketcap.com/api/documentation/v1/#operation/getV2CryptocurrencyQuotesHistorical  
https://www.datascienceexamples.com/coinmarketcap-api-with-python/
"""

# Define a function to return the CoinMarketCap data
def GetCoinMarketCapData(APIKey, AssetTickerList):

    """
    This function takes in an API Key for CoinMarketCap and a comma separated list of
    crypto tickers and returns a dataframe with the latest circulating supply, maximum
    supply, and coin market cap rank for each ticker.
    """
    
    # The quotes latest endpoint will be used
    Endpoint = "https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest"
    
    # Save a comma separated list of the desired fields
    DesiredFields = "cmc_rank,circulating_supply,max_supply"
    
    # Save the headers for the API call
    Headers = {
        "Accepts" : "application/json",
        "X-CMC_PRO_API_KEY" : APIKey
    }
    
    # Save the parameters for the API call
    Parameters = {
      "symbol" : AssetTickerList,
      "skip_invalid" : True,
      "aux" : DesiredFields
      }
      
     # Start a new session and update the headers
    CMCSession = Session()
    CMCSession.headers.update(Headers)
    
    # Make the API call and save the data
    Response = CMCSession.get(Endpoint, params = Parameters)
    Data = loads(Response.text)
    
    # Save the data into a dataframe
    CoinMarketDataframe = DataFrame(columns = ["Ticker", "Date", "CirculatingSupply", "MaximumSupply", "CMCRank"])
    for Ticker in Data["data"]:
        CirculatingSupply = Data["data"][Ticker]["circulating_supply"]
        MaximumSupply = Data["data"][Ticker]["max_supply"]
        CMCRank = Data["data"][Ticker]["cmc_rank"]
        CMCDictionary = {
            "Ticker" : Ticker,
            "Date" : datetime.now().strftime("%Y-%m-%d"),
            "CirculatingSupply" : CirculatingSupply,
            "MaximumSupply" : MaximumSupply,
            "CMCRank" : CMCRank
        }
        CoinMarketDataframe = CoinMarketDataframe.append(CMCDictionary, ignore_index = True)
        
    # Return the coinmarket dataframe
    return CoinMarketDataframe