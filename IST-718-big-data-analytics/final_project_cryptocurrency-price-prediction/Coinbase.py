# Import the necessary packages
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from os.path import join, isfile, exists
from time import sleep
from PIL import Image
from pytesseract import pytesseract
from time import sleep
from numpy import random
from pickle import dump, load

"""
Resources
https://www.youtube.com/watch?v=ekSXaKaBgSM
https://stackoverflow.com/questions/41721734/take-screenshot-of-full-page-with-selenium-python-with-chromedriver
https://pythonforundergradengineers.com/how-to-install-pytesseract.html
https://www.geeksforgeeks.org/how-to-extract-text-from-images-with-python/
https://github.com/UB-Mannheim/tesseract/wiki
https://www.geeksforgeeks.org/python-pil-image-crop-method/
https://stackoverflow.com/questions/36492263/why-am-i-getting-tile-cannot-extend-outside-image-error-when-trying-to-split-ima
https://piprogramming.org/articles/How-to-make-Selenium-undetectable-and-stealth--7-Ways-to-hide-your-Bot-Automation-from-Detection-0000000017.html
"""

# Define a function to get coinbase metrics
def GetCoinbaseMetrics(AssetSlug, ChromeDriverPath, TesseractPath):

    """
    This function scrapes the coinbase asset summary web page for various metrics
    about a given slug. The Selenium package is used with a Google Chrome driver.
    The Google Chrome driver must be installed separately. The path to the Google
    chromedriver.exe file is passed in as an argument. Selenium is used to take
    a screen shot of the asset summary page and then that screen shot is parsed by
    cropping it with the PIL package and parsing the text with the pytesseract package.
    The path to the tesseract.exe file is passed in as an argument. This must be
    installed seperately. Make sure that in the argument that the backslash before
    tesseract.exe is escaped because otherwise it will interpret it as a tab delimiter.
    Here is what that would look like "C:\Program Files\Tesseract-OCR\\tesseract.exe".
    NOTE: This might not work consistently from computer to computer. You might need to
    adjust the dimensions in the screen capture. The window.scrollTo, Left, Upper, Right,
    and Lower values may need to be adjusted.
    """

    # Save the path to the chrome web driver
    PATH = Service(ChromeDriverPath)
    
    # Set the options for the chrome webdriver
    Options = webdriver.ChromeOptions()
    Options.add_argument("window-size=1280,800")
    Options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/74.0.3729.169 Safari/537.36")
    Options.add_experimental_option("excludeSwitches", ["enable-automation"])
    
    # Start a selenium session in chrome
    Driver = webdriver.Chrome(service = PATH, options = Options)
    
    # Sleep for a random amount of time between 2 and 30 seconds
    sleep(random.randint(2, 30))
    
    # Navigate to the coinbase asset directory page
    Driver.get("https://www.coinbase.com/price/" + AssetSlug)
    
    # If cookies already exist, add them
    if exists(join(".", "Cookies.pkl")):
        Cookies = load(open("Cookies.pkl", "rb"))
        for Cookie in Cookies:
            Driver.add_cookie(Cookie)
        
    # Otherwise save new cookies
    else:
        dump(Driver.get_cookies(), open("Cookies.pkl","wb"))
    
    # Sleep for a random amount of time between 2 and 30 seconds
    sleep(random.randint(2, 30))
    
    # Maximize the window
    Driver.maximize_window()
    
    # Sleep for a random amount of time between 8 and 30 seconds
    sleep(random.randint(8, 30))
    
    # Scroll to the start of the summary section
    Driver.execute_script("window.scrollTo(0, 571.76)")
    
    # Sleep for a random amount of time between 10 and 30 seconds
    sleep(random.randint(10, 30))
    
    # Take a screenshot and save it to the working directory as a .png file
    Driver.save_screenshot(join(".", "CoinbaseSummary.png"))
    
    # Quit the selenium session
    Driver.quit()   
    
    # Open the image as a PIL image object
    CoinbaseImage = Image.open(join(".", "CoinbaseSummary.png"))
    
    # Crop around the circulating supply metric and save a new image
    Left = 485; Upper = 135; Right = 590; Lower = 170
    CirculatingSupplyImage = CoinbaseImage.crop((Left, Upper, Right, Lower))
    
    # Crop around the typical hold time metric and save a new image
    Left = 675; Upper = 135; Right = 750; Lower = 170
    TypicalHoldTimeImage = CoinbaseImage.crop((Left, Upper, Right, Lower))
    
    # Crop around the percent buy metric and save a new image
    Left = 120; Upper = 240; Right = 185; Lower = 270
    PercentBuyImage = CoinbaseImage.crop((Left, Upper, Right, Lower))
    
    # Crop around the percent sell metric and save a new image
    Left = 375; Upper = 240; Right = 430; Lower = 270
    PercentSellImage = CoinbaseImage.crop((Left, Upper, Right, Lower))
    
    # Crop around the popularity metric and save a new image
    Left = 490; Upper = 240; Right = 520; Lower = 270
    PopularityImage = CoinbaseImage.crop((Left, Upper, Right, Lower))
    
    # Set the pytesseract to where the tesseract.exe is
    pytesseract.tesseract_cmd = TesseractPath
    
    # Extract the text from the circulating supply image
    CirculatingSupplyText = pytesseract.image_to_string(CirculatingSupplyImage).strip()
    
    # Extract the text from the typical hold time image
    TypicalHoldTimeText = pytesseract.image_to_string(TypicalHoldTimeImage).strip()
    
    # Extract the text from the percent buy image
    PercentBuyText = pytesseract.image_to_string(PercentBuyImage).strip()
    
    # Extract the text from the percent sell image
    PercentSellText = pytesseract.image_to_string(PercentSellImage).strip()
    
    # Extract the text from the popularity image
    PopularityText = pytesseract.image_to_string(PopularityImage).strip()
    
    # Return a dictionary with each piece of information
    return {
        "Slug" : AssetSlug,
        "CirculatingSupply" : CirculatingSupplyText,
        "TypicalHoldTime" : TypicalHoldTimeText,
        "PercentBuy" : PercentBuyText,
        "PercentSell" : PercentSellText,
        "Popularity" : PopularityText
    }