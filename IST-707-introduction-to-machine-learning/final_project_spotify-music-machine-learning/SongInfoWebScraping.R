#-------------------------------------------------------------------------------#
### initialization ###

require(dplyr)
require(rvest)
require(stringr)
require(sqldf)

#-------------------------------------------------------------------------------#
### web scraping function defined below ###

# test links - used these to build out the web scraping logic

# song_wiki_link <- 'https://en.wikipedia.org/wiki/Saturnz_Barz'
# song_wiki_link <- 'https://en.wikipedia.org/wiki/Hate_to_Say_I_Told_You_So'
# song_wiki_link <- 'https://en.wikipedia.org/wiki/Heaven%27s_Just_a_Sin_Away'
# song_wiki_link <- 'https://en.wikipedia.org/wiki/Good_Vibrations'
# song_wiki_link <- 'https://en.wikipedia.org/wiki/Love_Wins_(song)'

#-------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------#

song_wiki_scraper <- function(song_wiki_link, song_info_part) {
  
# the song part info arg is an input as either 'Genre', 'Label', 'Songwriter', 'Producer'

#---------| read the web page based on the link that was input |----------------#

song_wiki_page <- read_html(song_wiki_link)

#------| return a list of all of the pieces of the infobox table |--------------#

iteration1  <-
song_wiki_page            %>%
html_nodes('.vevent')     %>%
html_children()           %>%
html_children()

#------| filter the list down just to the piece that contains the input |-------#

iteration2 <-
  iteration1[which(
    grepl(song_info_part, iteration1))]

#------| special case: if iteration2 has more than 1 element |------------------#

# does iteration2 contain more than one element?
testlength <- ifelse(
  length(iteration2) > 1,
    TRUE, FALSE)

# if yes, are the elements the same or are they different?
testunique <- ifelse(
  testlength == TRUE &
  length(unique(as.character(iteration2))) == 1,
    TRUE, FALSE)

# if they are the same, just take the first element
iteration2 <- if (testunique == TRUE) {
  iteration2[1]} else {iteration2}

# if they are not the same, does one of them have a seperated hlist?
# if yes, take that one, otherwise just take the first element
iteration2 <- if (testunique == FALSE & testlength == TRUE) {
  if (max(TRUE %in% grepl('hlist-separated', iteration2))) {
    iteration2[which(grepl('hlist-separated', iteration2))]} else {
      iteration2[1]}} else {
        iteration2}

#------| check if iteration2 is nested with more than one |---------------------#

# if there is a seperated hlist, then it is nested
testnested <- ifelse(
  max(grepl('hlist-separated', iteration2)), TRUE, FALSE)

# special case: sometimes it is nested without a seperated hlist
testnested2 <- ifelse(
  testnested == FALSE &
  length(unique(unlist(str_locate_all(iteration2 %>% html_text(), '\\n')))) > 1,
    TRUE, FALSE)

#-----------------------| drill down into the next level |----------------------#

iteration3 <- 
  iteration2 %>%
  html_children()

#-----------------| ilter it down to just the piece that we need |--------------#

iteration4 <-
  iteration3[which(
    grepl('hlist', iteration3))]

#----------| parse the final result dependent on several logical tests|---------#

iteration5 <-
  
  # if it was hidden nested, drill down 2 layers then get text
  
  if (testnested2 == TRUE)  {
         iteration4       %>%
         html_children()  %>%
         html_children()  %>%
         html_text()        }   else if (
  
  # if it was not nested, no drill down necessary just get text
           
      testnested == FALSE) {
         iteration4       %>%
         html_text()        }   else    {

  # if it was nested but not hidden nested, drill down 3 layers then get text
           
        iteration4        %>%
        html_children()   %>%
        html_children()   %>%
        html_children()   %>%
        html_text()         }

#-------------------| clean up the result as needed |---------------------------#

# get rid of (s) where it exists. no effect if it doesn't exist.
# for example, sometimes there is songwriter or songwriter(s)

iteration5 <-
  trimws(gsub('\\(s\\)', '', iteration5))

#-------------------------------------------------------------------------------#

return(iteration5)
}

#-------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------#

#-------------------------------------------------------------------------------#
# initialize empty song master. Each record will be appended here.

song_master <- data.frame()

#-------------------------------------------------------------------------------#
# initialize the for loop. Currently testing on 50 iterations.

for (song_artist_ID in paste(song_artist$song_name, song_artist$artist_name)) {

#-------------------------------------------------------------------------------#
# initialize variables. Everything starts off as NA - values assigned later

song_wiki_link    <- NA
song_single       <- NA
song_isalbum      <- NA
song_isartist     <- NA
song_released     <- NA
song_genre        <- NA
song_label        <- NA
song_songwriter   <- NA
song_producer     <- NA

#-------------------------------------------------------------------------------#
# dynamically create the google search link

song_search_text <- paste(song_artist_ID, 'Wikipedia')
song_search_text <- gsub(' ', '+', song_search_text) %>% trimws()
song_google_link <- paste0("https://www.google.com/search?q=", song_search_text)

#-------------------------------------------------------------------------------#
# attempt to retrieve wikipedia link from google search

# read the first page of google search
skiptonext <- FALSE
tryCatch({
  
google_search_page <- read_html(song_google_link)

# this is a list of links on google page
google_search_result <-
  (google_search_page    %>%
  html_nodes('body')     %>%
  html_children()) [2]   %>%
  html_children()        %>%
  html_nodes('a')        %>%
  html_attr('href')},

error = function(e) {skiptonext <<- TRUE})

if (skiptonext) { #----------------------
song_sample$song_wiki_link    <- NA
song_sample$song_single       <- NA
song_sample$song_isalbum      <- NA
song_sample$song_isartist     <- NA
song_sample$song_released     <- NA
song_sample$song_genre        <- NA
song_sample$song_label        <- NA
song_sample$song_songwriter   <- NA
song_sample$song_producer     <- NA

print(paste0('song skipped: ', song_artist_ID, ' #',
   which(paste(song_artist$song_name, song_artist$artist_name) == song_artist_ID)))}

if (skiptonext) {next} #----------------

# parse the list of links for the wiki link
# if the wiki link is there, this is reliable
# if its not there, might return incorrect link
# if its incorrect, program will realize it later
google_search_result <- 
  google_search_result[which(
    ! grepl('search?', google_search_result) &
    ! grepl('maps'   , google_search_result) &
      grepl('url?'   , google_search_result) &
      grepl('wiki'   , google_search_result))] [1]

# the link is buried between two characters
# the first character is the first '=' sign of the string
parseresultstart <-
  unique(unlist(str_locate_all(google_search_result, '='))) [1] + 1

# the second character is the first '&' sign of the string
parseresultend <-
  unique(unlist(str_locate_all(google_search_result, '&'))) [1] - 1

# extract the link by the text between the '=' and the '&'
song_wiki_link <-
  substr(google_search_result, parseresultstart, parseresultend)

# special case: if there is an apostrophe in the link,
# it gets encoded as '%27'. The '%', however, is
# also encoded as '%25'. Decode '%25' to '%' for it to work.
song_wiki_link <-
  gsub('\\%25', '\\%', song_wiki_link)

song_sample <- data.frame(cbind('song_wiki_link' = song_wiki_link,
                                'song_id' = song_artist_ID))

#-------------------------------------------------------------------------------#
# read the page, if error, everything NA and skip to next loop iteration

skiptonext <- FALSE
tryCatch({
  song_wiki_page <- 
    read_html(song_wiki_link)},
error = function(e) {
  skiptonext <<- TRUE})

if (skiptonext) { #----------------------
song_sample$song_wiki_link    <- NA
song_sample$song_single       <- NA
song_sample$song_isalbum      <- NA
song_sample$song_isartist     <- NA
song_sample$song_released     <- NA
song_sample$song_genre        <- NA
song_sample$song_label        <- NA
song_sample$song_songwriter   <- NA
song_sample$song_producer     <- NA

print(paste0('song skipped: ', song_artist_ID, ' #',
   which(paste(song_artist$song_name, song_artist$artist_name) == song_artist_ID)))}

if (skiptonext) {next} #----------------

#-------------------------------------------------------------------------------#
# attempt to scrape the info box, 

tryCatch(                   {
  song_table_infobox        <-
    song_wiki_page          %>%
    html_nodes('.vevent')   %>%
    html_table()            %>%
    .[[1]]                  },
error = function(e)         {
  song_table_infobox   <<- NA
  song_single          <<- NA
  song_isalbum         <<- NA})

#-------------------------------------------------------------------------------#
# if it has the word Single it is a single

tryCatch({
  song_single <- ifelse(
    max(TRUE %in%
      grepl('Single', song_table_infobox)),
  1, 0) },
error = function(e) {
  song_single <<- NA})

#-------------------------------------------------------------------------------#
# if it has the word Album it is an album

tryCatch({
  song_isalbum <- ifelse(
    max(TRUE %in%
      grepl('Album', song_table_infobox)),
    1, 0) },
error = function(e) {
  song_isalbum <<- NA})

#-------------------------------------------------------------------------------#
# attempt to scrape .plainlist node then check it for certain text
# words like 'Origin', 'Born', indicate artist homepage and not a song

tryCatch({
  song_artist_test <-
    as.character(
    (song_wiki_page %>%
    html_nodes('.plainlist')) [1])},
error = function(e) {
  song_artist_test <<- NA})

tryCatch({
song_isartist <- ifelse(
  max(TRUE %in%
    grepl('Origin',         song_artist_test)   |
    grepl('Born',           song_artist_test)   |
    grepl('Occupation',     song_artist_test)   |
    grepl('Years active',   song_artist_test)   |
    grepl('Website',        song_artist_test)  ),
  1, 0)},
error = function(e) {
  song_isartist <<- NA})

#-------------------------------------------------------------------------------#
# retrieve the song release date based on the infobox node

tryCatch({
  song_released <- as.character(
    song_table_infobox[which(
      song_table_infobox[,1] == 'Released'), 2]) },
error = function(e) {
  song_released <<- NA})

#-------------------------------------------------------------------------------#
# move forward with scraping song data

tryCatch({song_genre        <- song_wiki_scraper(song_wiki_link, 'Genre')},
  error = function(e) {song_genre        <<- NA})

tryCatch({song_label        <- song_wiki_scraper(song_wiki_link , 'Label')},
  error = function(e) {song_label        <<- NA})

tryCatch({song_songwriter   <- song_wiki_scraper(song_wiki_link , 'Songwriter')},
  error = function(e) {song_songwriter   <<- NA})

tryCatch({song_producer     <- song_wiki_scraper(song_wiki_link , 'Producer')},
  error = function(e) {song_producer     <<- NA})

#-------------------------------------------------------------------------------#
# piece it all together into the song sample dataframe

song_sample$song_wiki_link    <- song_wiki_link
song_sample$song_single       <- song_single
song_sample$song_isalbum      <- song_isalbum
song_sample$song_isartist     <- song_isartist
song_sample$song_released     <- song_released
song_sample$song_genre        <- list(song_genre)
song_sample$song_label        <- list(song_label)
song_sample$song_songwriter   <- list(song_songwriter)
song_sample$song_producer     <- list(song_producer)

#-------------------------------------------------------------------------------#
# append the data to the main dataframe and print progress update

song_master <- rbind(song_master, song_sample)

print(paste0('song recorded: ', song_artist_ID, ' #',
   which(paste(song_artist$song_name, song_artist$artist_name) == song_artist_ID)))

}

#-------------------------------------------------------------------------------#