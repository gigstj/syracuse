#-------------------------------------------------------------------------------#
### initialization ###

require(dplyr)
require(rvest)
require(stringr)
require(sqldf)

#-------------------------------------------------------------------------------#
### web scraping function defined below ###

# test links - used these to build out the web scraping logic

# album_wiki_link <- 'https://en.wikipedia.org/wiki/Anthology_(Alien_Ant_Farm_album)'
# album_wiki_link <- 'https://en.wikipedia.org/wiki/Wonder_What%27s_Next'
# album_wiki_link <- 'https://en.wikipedia.org/wiki/Wut_Wut'
# album_wiki_link <- 'https://en.wikipedia.org/wiki/Prophets_of_Rage'
# album_wiki_link <- 'https://en.wikipedia.org/wiki/Psychotic_Reaction_(album)'

#-------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------#

album_wiki_scraper <- function(album_wiki_link, album_info_part) {

#---------| read the web page based on the link that was input |----------------#

album_wiki_page <- read_html(album_wiki_link)

#------| return a list of all of the pieces of the infobox table |--------------#

iteration1  <-
album_wiki_page           %>%
html_nodes('.haudio')     %>%
html_children()           %>%
html_children()

#------| filter the list down just to the piece that contains the input |-------#

iteration2 <-
  iteration1[which(
    grepl(album_info_part, iteration1))]

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

artist_album <- as.data.frame(cbind('song_id' = song_master2[which(is.na(song_master2$song_release_year)),1]))
song_info_lookup <- unique(as.data.frame(cbind('song_id' = paste(song_info[,1], song_info[,2]), 'artist_name' = song_info[,2], 'album_names' = song_info[,3])))
artist_album <- left_join(artist_album, song_info_lookup, on = 'song_id')
artist_album <- unique(artist_album[,-1])

# album_master <- data.frame()

#-------------------------------------------------------------------------------#
# initialize the for loop. Currently testing on 50 iterations.

for (album_artist_ID in paste(new_artist_album2$artist_name, new_artist_album2$album_names)) {

#-------------------------------------------------------------------------------#
# initialize variables. Everything starts off as NA - values assigned later

album_wiki_link    <- NA
album_released     <- NA
album_genre        <- NA
album_label        <- NA
album_producer     <- NA

#-------------------------------------------------------------------------------#
# dynamically create the google search link

album_search_text <- paste(album_artist_ID, 'Album Wikipedia')
album_search_text <- gsub(' ', '+', album_search_text) %>% trimws()
album_google_link <- paste0("https://www.google.com/search?q=", album_search_text)

#-------------------------------------------------------------------------------#
# attempt to retrieve wikipedia link from google search

# read the first page of google search
skiptonext <- FALSE
tryCatch({
  
google_search_page <- read_html(album_google_link)

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
album_sample$album_wiki_link    <- NA
album_sample$album_released     <- NA
album_sample$album_genre        <- NA
album_sample$album_label        <- NA
album_sample$album_producer     <- NA

print(paste0('album skipped: ', album_artist_ID, ' #',
   which(paste(artist_album$artist_name, artist_album$album_names) == album_artist_ID)))}

if (skiptonext) {next} #----------------

# parse the list of links for the wiki link
# if the wiki link is there, this is reliable
# if its not there, might return incorrect link
# if its incorrect, program will realize it later
skiptonext <- FALSE
google_search_result <- 
  google_search_result[which(
    ! grepl('search?', google_search_result) &
    ! grepl('maps'   , google_search_result) &
      grepl('url?'   , google_search_result) &
      grepl('wiki'   , google_search_result))] [1]
if (is.na(google_search_result)) {skiptonext <<- TRUE}
if (skiptonext) {next}

# the link is buried between two characters
# the first character is the first '=' sign of the string
parseresultstart <-
  unique(unlist(str_locate_all(google_search_result, '='))) [1] + 1

# the second character is the first '&' sign of the string
parseresultend <-
  unique(unlist(str_locate_all(google_search_result, '&'))) [1] - 1

# extract the link by the text between the '=' and the '&'
album_wiki_link <-
  substr(google_search_result, parseresultstart, parseresultend)

# special case: if there is an apostrophe in the link,
# it gets encoded as '%27'. The '%', however, is
# also encoded as '%25'. Decode '%25' to '%' for it to work.
album_wiki_link <-
  gsub('\\%25', '\\%', album_wiki_link)

album_sample <- data.frame(cbind('album_wiki_link' = album_wiki_link,
                                'album_id' = album_artist_ID))

#-------------------------------------------------------------------------------#
# read the page, if error, everything NA and skip to next loop iteration

skiptonext <- FALSE
tryCatch({
  album_wiki_page <- 
    read_html(album_wiki_link)},
error = function(e) {
  skiptonext <<- TRUE})

if (skiptonext) { #----------------------
album_sample$album_wiki_link    <- NA
album_sample$album_released     <- NA
album_sample$album_genre        <- NA
album_sample$album_label        <- NA
album_sample$album_producer     <- NA

print(paste0('album skipped: ', album_artist_ID, ' #',
   which(paste(artist_album$album_names, artist_album$artist_name) == album_artist_ID)))}

if (skiptonext) {next} #----------------

#-------------------------------------------------------------------------------#
# attempt to scrape the info box, 

tryCatch(                   {
  album_table_infobox        <-
    album_wiki_page          %>%
    html_nodes('.haudio')   %>%
    html_table()            %>%
    .[[1]]                  },
error = function(e)         {
  album_table_infobox   <<- NA
  album_single          <<- NA
  album_isalbum         <<- NA})

#-------------------------------------------------------------------------------#
# retrieve the song release date based on the infobox node

tryCatch({
  album_released <- as.character(
    album_table_infobox[which(
      album_table_infobox[,1] == 'Released'), 2]) },
error = function(e) {
  album_released <<- NA})

#-------------------------------------------------------------------------------#
# move forward with scraping song data

tryCatch({album_genre        <- album_wiki_scraper(album_wiki_link, 'Genre')},
  error = function(e) {album_genre        <<- NA})

tryCatch({album_label        <- album_wiki_scraper(album_wiki_link , 'Label')},
  error = function(e) {album_label        <<- NA})

tryCatch({album_producer     <- album_wiki_scraper(album_wiki_link , 'Producer')},
  error = function(e) {album_producer     <<- NA})

#-------------------------------------------------------------------------------#
# piece it all together into the song sample dataframe

album_sample$album_wiki_link    <- album_wiki_link
album_sample$album_released     <- album_released
album_sample$album_genre        <- list(album_genre)
album_sample$album_label        <- list(album_label)
album_sample$album_producer     <- list(album_producer)

#-------------------------------------------------------------------------------#
# append the data to the main dataframe and print progress update

album_master <- rbind(album_master, album_sample)

print(paste0('album recorded: ', album_artist_ID, ' #',
   which(paste(artist_album$artist_name, artist_album$album_names) == album_artist_ID)))

}

#-------------------------------------------------------------------------------#