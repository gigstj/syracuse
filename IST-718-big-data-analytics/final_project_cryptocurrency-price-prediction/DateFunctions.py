# Import the necessary packages
from pandas import Timestamp, to_datetime, Series, date_range
from datetime import datetime
from calendar import monthrange
from re import match

"""
Resources
https://itnext.io/working-with-timezone-and-python-using-pytz-library-4931e61e5152
https://techoverflow.net/2019/05/16/how-to-get-number-of-days-in-month-in-python/
https://stackoverflow.com/questions/50449453/pandas-datetime64-to-string
https://pandas.pydata.org/docs/reference/api/pandas.Series.dt.tz_convert.html
"""

# Define the GetCurrentDateTimeEpoch function
def GetCurrentDateTimeEpoch(TimezoneIn):

    """
    This function takes in a specified timezone, which would normally be the user's
    local timezone, and returns the current datetime in epoch format. For a list of
    valid timezones see all_timezones from the pytz package.
    """
        
    # Make sure that the timezone is valid
    if TimezoneIn not in all_timezones:
        raise Exception("Error, please provide a valid timezone. For a list of options see all_timezones from the pytz package")
        
    # Create the timestamp object and return it
    return int(Timestamp(
        year = datetime.now().year,
        month = datetime.now().month,
        day = datetime.now().day,
        hour = datetime.now().hour,
        minute = datetime.now().minute,
        second = datetime.now().second,
        tz = TimezoneIn
    ).timestamp())
    
# Define the ConvertDateTimeToEpoch function
def ConvertDateTimeToEpoch(datetimestring, TimezoneIn):

    """
    This function takes in a datetimestring in yyyy-MM-dd hh:mm:ss format as well as
    a specified timezone, which would normally be the user's local timezone, and returns
    the datetime in epoch format. For a list of valid timezones, see all_timezones from
    the pytz package.
    """

    # Make sure that the datetimestring is a string
    if not isinstance(datetimestring, str):
        raise Exception("Error, please provide a valid datetimestring. The value provided must be a string in yyyy-MM-dd hh:mm:ss format")
        
    # Make sure that the datetimestring follows yyyy-MM-dd hh:mm:ss format
    if not bool(match("[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]\s[0-2][0-9]:[0-5][0-9]:[0-5][0-9]$", datetimestring)):
        raise Exception("Error, please provide a valid datetimestring. The value provided must be a string in yyyy-MM-dd hh:mm:ss format")
        
    # Make sure that the timezone is valid
    if TimezoneIn not in all_timezones:
        raise Exception("Error, please provide a valid timezone. For a list of options see all_timezones from the pytz package")
        
    # Create the timestamp object and return it
    return int(Timestamp(
        year = int(datetimestring[0:4]),
        month = int(datetimestring[5:7]),
        day = int(datetimestring[8:10]),
        hour = int(datetimestring[11:13]),
        minute = int(datetimestring[14:16]),
        second = int(datetimestring[17:19]),
        tz = TimezoneIn
    ).timestamp())

# Define the ConvertDatePartsToEpoch function
def ConvertDatePartsToEpoch(Year, Month, Day, Hour, Minute, Second, TimezoneIn):

    """
    This function takes in a year, month, day, hour, minute, second, and a specified
    timezone, which would normally be the user's local timezone, and returns the datetime
    in epoch format. For a list of valid timezones, see all_timezones from the pytz package.
    """

    # Make sure that the year is a 4 digit integer
    if len(str(Year)) != 4 or not isinstance(year, int):
        raise Exception("Error, please provide a valid year. The year must be a 4 digit integer")
        
    # Make sure that the month is an integer between 1 and 12
    if Month not in list(range(1, 13)):
        raise Exception("Error, please provide a valid month. The month must be an integer between 1 and 12")
        
    # Make sure that the day is a valid day based on the year and month
    if Day not in list(range(1, monthrange(year, month)[1] + 1)):
        raise Exception("Error, please provide a valid day. The day must an integer between 1 and 31 and must be in range for the given year and month")
        
    # Make sure that the hour is an integer between 0 and 23
    if Hour not in list(range(0, 24)):
        raise Exception("Error, please provide a valid hour. The hour must be an integer between 0 and 23")
        
    # Make sure that the minute is an integer between 0 and 59
    if Minute not in list(range(0, 60)):
        raise Exception("Error, please provide a valid minute. The minute must be an integer between 0 and 59")
        
    # Make sure that the second is an integer between 0 and 59
    if Second not in list(range(0, 60)):
        raise Exception("Error, please provide a valid second. The second must be an integer between 0 and 59")
        
    # Make sure that the timezone is valid
    if TimezoneIn not in all_timezones:
        raise Exception("Error, please provide a valid timezone. For a list of options see all_timezones from the pytz package")
    
    # Create the timestamp object and return it
    return int(Timestamp(
        year = year,
        month = month,
        day = day,
        hour = hour,
        minute = minute,
        second = second,
        tz = TimezoneIn
    ).timestamp())
    
# Define the ConvertEpochToDateTime function
def ConvertEpochToDateTime(DateTimeEpoch, TimezoneOut = "UTC"):

    """
    This function takes in a datetime in epoch format and a specified timezone,
    which is the timezone that the user wants the datetime in, and returns the datetime
    in yyyy-MM-dd hh:mm:ss format. If no timezone is specified then the datetime is
    returned in the UTC timezone.
    """

    # Make sure that the timezone is valid
    if TimezoneOut not in all_timezones:
        raise Exception("Error, please provide a valid timezone. For a list of options see all_timezones from the pytz package")

    # Save the date parts from the epoch datetime
    Year = str(to_datetime(DateTimeEpoch, unit = "s").year)
    Month = str(to_datetime(DateTimeEpoch, unit = "s").month)
    Month = "0" + month if len(month) == 1 else month
    Day = str(to_datetime(DateTimeEpoch, unit = "s").day)
    Day = "0" + day if len(day) == 1 else day
    Hour = str(to_datetime(DateTimeEpoch, unit = "s").hour)
    Hour = "0" + hour if len(hour) == 1 else hour
    Minute = str(to_datetime(DateTimeEpoch, unit = "s").minute)
    Minute = "0" + minute if len(minute) == 1 else minute
    Second = str(to_datetime(DateTimeEpoch, unit = "s").second)
    Second = "0" + second if len(second) == 1 else second
    
    # Make a datetime string out of the date parts
    DateTimeString = Year + "-" + Month + "-" + Day + " " + Hour + ":" + Minute + ":" + Second
    
    # If no timezone_out was specified then return the datetimestring
    if TimezoneOut == "UTC":
        return DateTimeString + " " + TimezoneOut
        
    # Otherwise convert the datetimestring to the specified timezone then return it
    else:
        DateTimeSeriesUTC = Series(date_range(DateTimeString, periods = 1, tz = "UTC"))
        DateTimeSeriesUTC.index = ["DateTimeUTC"]
        DateTimeConverted = DateTimeSeriesUTC.dt.tz_convert(tz = TimezoneOut).dt.tz_localize(None)
        return str(DateTimeConverted["DateTimeUTC"]) + " " + TimezoneOut