#-------------------------------------------------------------------------------#
### initialization ###

require(dplyr)
require(rvest)
require(stringr)
require(sqldf)

#-------------------------------------------------------------------------------#
### web scraping function defined below ###

# test links - used these to build out the web scraping logic

# artist_wiki_link <- 'https://en.wikipedia.org/wiki/ASAP_Ferg'
# artist_wiki_link <- 'https://en.wikipedia.org/wiki/Chris_Webby'
# artist_wiki_link <- 'https://en.wikipedia.org/wiki/Kream'
# artist_wiki_link <- 'https://en.wikipedia.org/wiki/Nina_Sky_(album)'
# artist_wiki_link <- 'https://en.wikipedia.org/wiki/Psychotic_Reaction_(album)'

#-------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------#

artist_wiki_scraper <- function(artist_wiki_link, artist_info_part) {

#---------| read the web page based on the link that was input |----------------#

artist_wiki_page <- read_html(artist_wiki_link)

#------| return a list of all of the pieces of the infobox table |--------------#

iteration1  <-
artist_wiki_page          %>%
html_nodes('.plainlist')  %>%
html_children()           %>%
html_children()

#------| filter the list down just to the piece that contains the input |-------#

iteration2 <-
  iteration1[which(
    grepl(artist_info_part, iteration1))]
  
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
tryCatch({
testnested <- ifelse(
  max(grepl('hlist-separated', iteration2)), TRUE, FALSE)}, warning = function(e) {
    testnested <<- FALSE})

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
# initialize empty artist master. Each record will be appended here.

artist_T <- unique(as.data.frame(cbind('song_artist' = song_artist[,2])))

artist_master <- data.frame()

#-------------------------------------------------------------------------------#
# initialize the for loop. Currently testing on 50 iterations.

for (artist_ID in artist_T$song_artist) {

#-------------------------------------------------------------------------------#
# initialize variables. Everything starts off as NA - values assigned later

artist_wiki_link    <- NA
artist_born         <- NA
artist_origin       <- NA
artist_yearsactive  <- NA
artist_genre        <- NA
artist_label        <- NA

#-------------------------------------------------------------------------------#
# dynamically create the google search link

artist_search_text <- paste(artist_ID, 'Wikipedia')
artist_search_text <- gsub(' ', '+', artist_search_text) %>% trimws()
artist_google_link <- paste0("https://www.google.com/search?q=", artist_search_text)

#-------------------------------------------------------------------------------#
# attempt to retrieve wikipedia link from google search

# read the first page of google search
skiptonext <- FALSE
tryCatch({
  
google_search_page <- read_html(artist_google_link)

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
artist_sample$artist_wiki_link    <- NA
artist_sample$artist_born         <- NA
artist_sample$artist_origin       <- NA
artist_sample$artist_yearsactive  <- NA
artist_sample$genre               <- NA
artist_sample$label               <- NA

print(paste0('artist skipped: ', artist_ID, ' #',
   which(artist_T$song_artist == artist_ID)))}

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
artist_wiki_link <-
  substr(google_search_result, parseresultstart, parseresultend)

# special case: if there is an apostrophe in the link,
# it gets encoded as '%27'. The '%', however, is
# also encoded as '%25'. Decode '%25' to '%' for it to work.
artist_wiki_link <-
  gsub('\\%25', '\\%', artist_wiki_link)

artist_sample <- data.frame(cbind('artist_wiki_link' = artist_wiki_link,
                                'artist_id' = artist_ID))

#-------------------------------------------------------------------------------#
# read the page, if error, everything NA and skip to next loop iteration

skiptonext <- FALSE
tryCatch({
  artist_wiki_page <- 
    read_html(artist_wiki_link)},
error = function(e) {
  skiptonext <<- TRUE})

if (skiptonext) { #----------------------
artist_sample$artist_wiki_link    <- NA
artist_sample$artist_born         <- NA
artist_sample$artist_origin       <- NA
artist_sample$artist_yearsactive  <- NA
artist_sample$artist_genre        <- NA
artist_sample$artist_label        <- NA

print(paste0('artist skipped: ', artist_ID, ' #',
   which(artist_T$song_artist == artist_ID)))}

if (skiptonext) {next} #----------------

#-------------------------------------------------------------------------------#
# attempt to scrape the info box, 

infoboxskip <- FALSE
tryCatch(                   {
  artist_table_infobox        <-
    (artist_wiki_page          %>%
    html_nodes('.plainlist')) [1] %>%
    html_table() %>%
    .[[1]]                  },
error = function(e)         {
  artist_table_infobox   <<- NA
  infoboxskip <<- TRUE})

if (infoboxskip) {
tryCatch(                   {
  artist_table_infobox        <-
    (artist_wiki_page          %>%
    html_nodes('.vcard')) [1] %>%
    html_table() %>%
    .[[1]]                  },
error = function(e)         {
  artist_table_infobox   <<- NA})}
    
#-------------------------------------------------------------------------------#
# retrieve information from the infobox node

# standardize to lower case
tryCatch({
lowercase_artist_info <- c()
for (element in artist_table_infobox[,1]) {
newelement <- tolower(element)
lowercase_artist_info <- c(lowercase_artist_info, newelement)}
new_artist_table_infobox <- data.frame(cbind('X1' = lowercase_artist_info, 'X2' = artist_table_infobox[,2]))
}, error = function(e) {new_artist_table_infobox <<- NA})

# when the artist was born
tryCatch({
  artist_born <- as.character(
    new_artist_table_infobox[which(
      new_artist_table_infobox[,1] == 'born'), 2]) },
error = function(e) {
  artist_born <<- NA})

# where the artist was born
tryCatch({
  artist_origin <- as.character(
    new_artist_table_infobox[which(
      new_artist_table_infobox[,1] == 'origin'), 2]) },
error = function(e) {
  artist_origin <<- NA})

# years the artist has been active
tryCatch({
  artist_yearsactive <- as.character(
    new_artist_table_infobox[which(grepl('years',
      new_artist_table_infobox[,1])), 2]) },
error = function(e) {
  artist_yearsactive <<- NA})

tryCatch({artist_genre        <- artist_wiki_scraper(artist_wiki_link, 'Genre')},
  error = function(e) {artist_genre        <<- NA})

if (length(artist_genre) == 0) {
  
    tryCatch({
    artist_genre <- as.character(
      new_artist_table_infobox[which(grepl('genre',
        new_artist_table_infobox[,1])), 2]) },
  error = function(e) {
    artist_genre <<- NA})}

tryCatch({artist_label        <- artist_wiki_scraper(artist_wiki_link, 'Label')},
  error = function(e) {artist_label        <<- NA})

if (length(artist_label) == 0) {
  
    tryCatch({
    artist_label <- as.character(
      new_artist_table_infobox[which(grepl('label',
        new_artist_table_infobox[,1])), 2]) },
  error = function(e) {
    artist_label <<- NA})}

#-------------------------------------------------------------------------------#
# piece it all together into the song sample dataframe

tryCatch({artist_sample$artist_wiki_link    <- artist_wiki_link}, error = function(e) {artist_sample$artist_wiki_link    <<- NA})
tryCatch({artist_sample$artist_born     <- artist_born }, error = function(e) {artist_sample$artist_born     <<- NA})
tryCatch({artist_sample$artist_origin    <- artist_origin}, error = function(e) {artist_sample$artist_origin    <<- NA})
tryCatch({artist_sample$artist_yearsactive    <- artist_yearsactive}, error = function(e) {artist_sample$artist_yearsactive    <<- NA})
tryCatch({artist_sample$artist_genre    <- list(artist_genre)}, error = function(e) {artist_sample$artist_genre    <<- NA})
tryCatch({artist_sample$artist_label    <- list(artist_label)}, error = function(e) {artist_sample$artist_label    <<- NA})

#-------------------------------------------------------------------------------#
# append the data to the main dataframe and print progress update

artist_master <- rbind(artist_master, artist_sample)

print(paste0('artist recorded: ', artist_ID, ' #',
   which(artist_T$song_artist == artist_ID)))

}