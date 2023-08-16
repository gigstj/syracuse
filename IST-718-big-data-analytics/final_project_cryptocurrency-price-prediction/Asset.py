# Import the necessary packages
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from bs4 import BeautifulSoup
from re import findall, sub

"""
Resources
https://help.coinbase.com/en/coinbase/supported-crypto
https://www.youtube.com/watch?v=b5jt2bhSeXs
https://stackoverflow.com/questions/64717302/deprecationwarning-executable-path-has-been-deprecated-selenium-python
"""

# Define a function for getting the assets
def GetCoinbaseAssetDictionary(ChromeDriverPath):

    """
    This function scrapes the coinbase asset directory web page for the tickers
    and slugs that coinbase supports. The Selenium package is used with a Google
    Chrome driver. The Google Chrome driver must be installed separately. The
    path to the Google Chrome Driver .exe file is passed in as an argument.
    Selenium is used to access the rendered HTML source code of this web page
    since it is javascript based. Once the HTML source code is saved, BeautifulSoup
    is used to extract the information.
    """

    # Save the path to the chrome web driver
    PATH = Service(ChromeDriverPath)
    
    # Start a selenium session in chrome
    Driver = webdriver.Chrome(service = PATH)
    
    # Navigate to the coinbase asset directory page
    Driver.get("https://help.coinbase.com/en/coinbase/supported-crypto")
    
    # Save the html source code for the page
    SourceCode = Driver.page_source
    
    # Quit the selenium session
    Driver.quit()
    
    # Read the html source code with beautiful soup
    Soup = BeautifulSoup(SourceCode, "lxml")
    
    # Dictionary to save the information in
    Asset = {}

    # Iteration 1 of HTML elements
    for Item1 in Soup.find_all(name = "section", attrs = {"class" : "crypto-base-asset"}):

        # Iteration 2 of HTML elements
        for Item2 in Item1.find_all(name = "ul", attrs = {"class" : "crypto-base-asset__list"}):

            # Some coins like BTC and ETH have more than one "li" node
            # This changes how the information gets captured
            
            # Iteration 3 of HTML elements if there is more than one "li" node
            if len(Item2) > 1:
                Item2 = list(Item2)[0]
                for Item3 in Item2.find_all(name = "a", attrs = {"class" : "crypto-base-asset__link"}):
                    Slug = sub("\(.*\)", "", Item3.text).strip()
                    Ticker = findall("\(.*\)", Item3.text)[0].replace("(", "").replace(")", "").upper()
                    Asset[Ticker] = Slug

            # Iteration 3 and 4 of HTML elements if there is one "li" node
            if len(Item2) == 1:
                for Item3 in Item2.find_all(name = "li", attrs = {"class" : "crypto-base-asset__item"}):
                    for Item4 in Item3.find_all(name = "a", attrs = {"class" : "crypto-base-asset__link"}):
                        Slug = sub("\(.*\)", "", Item4.text).strip()
                        Ticker = findall("\(.*\)", Item4.text)[0].replace("(", "").replace(")", "").upper()
                        Asset[Ticker] = Slug
    
    # Return the Asset dictionary
    return Asset