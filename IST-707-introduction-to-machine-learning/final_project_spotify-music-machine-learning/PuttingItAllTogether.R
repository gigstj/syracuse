#-------------------------------------------------------------------------------#
# packages

require(readr)
require(dplyr)
require(ggplot2)
require(stringr)
require(rvest)

#-------------------------------------------------------------------------------#
### store raw versions of data from web scraping (these will be kept for reference)

raw_song_master     <- unique(song_master[, c(1:10)])
raw_album_master    <- unique(album_master[, c(1:6)])
raw_artist_master   <- unique(artist_master[, c(1:7)])

### store new versions of data from web scraping (these will be further processed)

song_master_T     <- raw_song_master
album_master_T    <- raw_album_master
artist_master_T   <- raw_artist_master

#-------------------------------------------------------------------------------#
### create a function to un-nest nested lists

unpack_data <- function(packed_variable_list) {
  unpacked_variable_list <- c()
  for (packed_variable_1 in packed_variable_list) {
    unpacked_variable <- (packed_variable_1 %>% unlist()) [1]
  for (packed_variable_2 in (packed_variable_1 %>% unlist()) [-1]) {
    unpacked_variable <- paste(unpacked_variable, packed_variable_2, sep = ',')}
    unpacked_variable_list <- c(unpacked_variable_list, unpacked_variable)}
  return(unpacked_variable_list)
}

#-------------------------------------------------------------------------------#
### apply function accordingly to the data

song_master_T$song_genre        <- unpack_data(song_master_T$song_genre)        #song genre
song_master_T$song_label        <- unpack_data(song_master_T$song_label)        #song label
song_master_T$song_songwriter   <- unpack_data(song_master_T$song_songwriter)   #song songwriter
song_master_T$song_producer     <- unpack_data(song_master_T$song_producer)     #song producer
album_master_T$album_genre      <- unpack_data(album_master_T$album_genre)      #album genre
album_master_T$album_label      <- unpack_data(album_master_T$album_label)      #album label
album_master_T$album_producer   <- unpack_data(album_master_T$album_producer)   #album producer
artist_master_T$artist_genre    <- unpack_data(artist_master_T$artist_genre)    #artist genre
artist_master_T$artist_label    <- unpack_data(artist_master_T$artist_label)    #artist label

#-------------------------------------------------------------------------------#
# create a temporary table to reconcile song/artists that have > 1 album
# 14,615 - 14,006 = 609 records where album will have to be consolidated

temp_song_album <- song_album
temp_song_album$album_id <- paste(temp_song_album$artist_name, temp_song_album$album_names)
temp_song_album <- left_join(temp_song_album, album_master_T[, c(2:6)], on = 'album_id')

# get rid of rows where data is missing in all four album attributes
# 1,951 - 1,933 = 18 records where album will be consolidated

temp_song_album <- temp_song_album[- which(
  is.na(temp_song_album$album_released) &
  is.na(temp_song_album$album_genre) &
  is.na(temp_song_album$album_label) &
  is.na(temp_song_album$album_producer)), ]

# identify the 18 records (really 18 x 2 = 36 total records, 18 unique)

temp_song_album_unique_test <- sqldf('
select song_id,
count from( 
  select song_name || \' \' || artist_name as song_id,
  count(song_name || \' \' || artist_name) as count
  from temp_song_album group by song_name || \' \' || artist_name) sub 
where count >= 2')

# reconcile the 18 records by sorting them and taking the second one
# due to being such a small portion should not have negative implications

temp_song_album$song_id      <- paste(temp_song_album$song_name, temp_song_album$artist_name)            # add song id for lookup
temp_song_album              <- left_join(temp_song_album, temp_song_album_unique_test, on = 'song_id')  # join in the unique test result
temp_song_album_not_unique   <- temp_song_album[which( ! is.na(temp_song_album$count)), ]                # extract the not unique records
temp_song_album_not_unique   <- sqldf('select * from temp_song_album_not_unique order by song_name')     # order by song name
temp_song_album_unique       <- temp_song_album_not_unique[which(                                        # conslidate,take even rows
  as.numeric(rownames(temp_song_album_not_unique)) %in% seq(2, 36, 2)),]                                

# replace the original records with the corrected records

temp_song_album <- temp_song_album[which(is.na(temp_song_album$count)), ]     # get rid of the not unique records
temp_song_album <- rbind(temp_song_album, temp_song_album_unique)             # re-append the unique records

#-------------------------------------------------------------------------------#
# join the results from the album data and fill in missing values for songs

song_master_T <- left_join(song_master_T, temp_song_album[, c(4:9)], on = 'song_id')

# missing values for each column before

nrow(song_master_T[which(is.na(song_master_T$song_released)),])   #6663 mising song release    (50%)
nrow(song_master_T[which(is.na(song_master_T$song_genre)),])      #7312 mising song genre      (55%)
nrow(song_master_T[which(is.na(song_master_T$song_label)),])      #7001 mising song label      (53%)
nrow(song_master_T[which(is.na(song_master_T$song_producer)),])   #7307 mising song producer   (55%)

# fill in missing values for song attributes where possible
# if song is missing, take album, otherwise take song

song_master_T$song_released   <- ifelse(is.na(song_master_T$song_released),   song_master_T$album_released,   song_master_T$song_released)
song_master_T$song_genre      <- ifelse(is.na(song_master_T$song_genre),      song_master_T$album_genre,      song_master_T$song_genre)
song_master_T$song_label      <- ifelse(is.na(song_master_T$song_label),      song_master_T$album_label,      song_master_T$song_label)
song_master_T$song_producer   <- ifelse(is.na(song_master_T$song_producer),   song_master_T$album_producer,   song_master_T$song_producer)

# missing values for each column after

nrow(song_master_T[which(is.na(song_master_T$song_released)),])   #5030 mising song release    (38%) - 12% improvement
nrow(song_master_T[which(is.na(song_master_T$song_genre)),])      #5641 mising song genre      (42%) - 13% improvement
nrow(song_master_T[which(is.na(song_master_T$song_label)),])      #5230 mising song label      (39%) - 14% improvement
nrow(song_master_T[which(is.na(song_master_T$song_producer)),])   #5713 mising song producer   (43%) - 12% improvement

# how many have no data whatsoever
# 4955 mising song producer   (37%)

nrow(song_master_T[which(
  is.na(song_master_T$song_released) &
  is.na(song_master_T$song_genre) &
  is.na(song_master_T$song_label) &
  is.na(song_master_T$song_songwriter) &
  is.na(song_master_T$song_producer)),])   

# remove the lookup columns

song_master_T <- song_master_T[, - c(11:15)]

#-------------------------------------------------------------------------------#
# join the results from the artist data and fill in missing values for songs

temp_song_artist <- data.frame(cbind('song_id' = paste(song_artist$song_name, song_artist$artist_name), 'artist_id' = song_artist$artist_name))
song_master_T <- left_join(song_master_T, temp_song_artist, on = 'song_id')
song_master_T <- left_join(song_master_T, artist_master_T[, c(2, 6, 7)], on = 'artist_id')

# missing values for each column before

nrow(song_master_T[which(is.na(song_master_T$song_genre)),])      #5641 mising song genre      (42%)
nrow(song_master_T[which(is.na(song_master_T$song_label)),])      #5230 mising song label      (39%)

# fill in missing values for song attributes where possible
# if song is missing, take artist, otherwise take song

song_master_T$song_genre      <- ifelse(is.na(song_master_T$song_genre),      song_master_T$artist_genre,      song_master_T$song_genre)
song_master_T$song_label      <- ifelse(is.na(song_master_T$song_label),      song_master_T$artist_label,      song_master_T$song_label)

# missing values for each column after

nrow(song_master_T[which(is.na(song_master_T$song_genre)),])      #1953 mising song genre      (15%) - 27% improvement
nrow(song_master_T[which(is.na(song_master_T$song_label)),])      #2283 mising song label      (17%) - 22% improvement

# remove the lookup columns

song_master_T <- song_master_T[, - c(11:13)]

#-------------------------------------------------------------------------------#
### song release column clean up ###

# eliminate anything that came out in brackets/parentheses

song_master_T$song_released <- gsub("\\(.*?)", "", song_master_T$song_released)
song_master_T$song_released <- gsub("\\[.*?]", "", song_master_T$song_released)

# extract the year and date from the song release date

dayyearnumbers <- c()
for (rownumber in seq(1, nrow(song_master_T))) {
  for (element in song_master_T[rownumber, 6]) {
    separatedtext <- as.numeric(str_split(element, "") %>% .[[1]])
    seperatedtext <- which(! is.na(separatedtext))
    newseparatedtext <- c()
      for (textelement in separatedtext) {
        newseparatedtext <- paste0(newseparatedtext, textelement)}
        newseparatedtext <- trimws(gsub('NA', '', newseparatedtext))
        dayyearnumbers <- c(dayyearnumbers, newseparatedtext)
  }
}

song_master_T$song_released <- dayyearnumbers

# take the substring of the last four characters which is the year

songyear <- c()
for (rownumber in seq(1, nrow(song_master_T))) {
  for (element in song_master_T[rownumber, 6]) {
    newelement <- substr(element, nchar(element) - 3, nchar(element))
    songyear <- c(songyear, newelement)}}

song_master_T$song_released <- as.numeric(songyear)

# missing values for each column after

nrow(song_master_T[which(is.na(song_master_T$song_released)),])   #5325 mising song release    (40%) - 2% decline, lost some

#-------------------------------------------------------------------------------#
### song genre column clean up ###

# parent genre list, any genres that contain these words will be consolidated
# hip hop is two seperate genres for the lookup but will be consolidated later

parent_genre_list <- c('alt', 'rock', 'metal', 'punk', 'pop', 'hip', 'hop', 'r&b',
                       'rap', 'jazz', 'blues', 'folk', 'country', 'elect', 'other')

new_song_genre_list <- c()
for (rownumber in seq(1, nrow(song_master_T))) {
  for (element in song_master_T[rownumber, 7]) {
    temp_song_genre_list <- c()
    for (genre in parent_genre_list) {
      if (grepl(genre, tolower(element))) {
        temp_song_genre_list <<- c(temp_song_genre_list, genre)}}
  if (is.null(temp_song_genre_list) & ! is.na(element)) {
    new_song_genre_list <- c(new_song_genre_list, 'other')} else if (
    is.null(temp_song_genre_list)) {
    new_song_genre_list <- c(new_song_genre_list, NA)} else {
    new_song_genre_list <- c(new_song_genre_list, list(temp_song_genre_list))}}
}

new_song_genre_list <- unpack_data(new_song_genre_list)
song_master_T$song_genre <- new_song_genre_list

#-------------------------------------------------------------------------------#
### finish cleaning up the song master ###

# get rid of the wiki link, isalbum, and isartist columns. Not needed for analysis.

song_master_T <- song_master_T[, -c(1, 4, 5)]

# where there is not a known song release date, the issingle column should really be NA because we don't know

song_master_T[which(is.na(song_master_T$song_released)), 2] <- NA

# clean up the labels column

song_master_T$song_label <- gsub("\\(.*?)", "", song_master_T$song_label)
song_master_T$song_label <- gsub("\\[.*?]", "", song_master_T$song_label)
song_master_T$song_label <- tolower(song_master_T$song_label)

# clean up the songwriter column

song_master_T$song_songwriter <- gsub("\\(.*?)", "", song_master_T$song_songwriter)
song_master_T$song_songwriter <- gsub("\\[.*?]", "", song_master_T$song_songwriter)
song_master_T$song_songwriter <- tolower(song_master_T$song_songwriter)

# clean up the producer column

song_master_T$song_producer <- gsub("\\(.*?)", "", song_master_T$song_producer)
song_master_T$song_producer <- gsub("\\[.*?]", "", song_master_T$song_producer)
song_master_T$song_producer <- tolower(song_master_T$song_producer)

#-------------------------------------------------------------------------------#

# extract the artist birthdates

artistbirthdates <- c()
for (messybday in artist_master_T$artist_born) {
  parenopenpos <- unique(unlist(str_locate_all(messybday, '\\('))) [1]
  parenclosepos <- unique(unlist(str_locate_all(messybday, '\\)'))) [1]
  cleanbday <- substr(messybday, parenopenpos + 1, parenclosepos - 1)
  artistbirthdates <- c(artistbirthdates, cleanbday)}
artist_master_T$birthday <- as.Date(artistbirthdates)


# extract the artist country of origin

artistunitedstates <- c()
for (artistorigin in artist_master_T$artist_origin) {
  unitedstatestest <- ifelse(
    grepl('us', tolower(artistorigin)) |
    grepl('u.s.', tolower(artistorigin)) |
    grepl('u.s', tolower(artistorigin)) |
    grepl('us.', tolower(artistorigin)) |
    grepl('united states', tolower(artistorigin)),
    'United States', NA)
  unitedstatestest <- ifelse(
    is.na(unitedstatestest) &
    ! is.na(artistorigin),
    'Foreign', unitedstatestest)
  artistunitedstates <- c(artistunitedstates, unitedstatestest)}
artist_master_T$country <- artistunitedstates

# extract the artist start year

artiststartyear <- c()
for (artistdaterange in artist_master_T$artist_yearsactive) {
  tempartiststartyear <- substr(artistdaterange, 1, 4)
  artiststartyear <- c(artiststartyear, tempartiststartyear)}
artist_master_T$startyear <- as.numeric(artiststartyear)

artist_master_T <- artist_master_T[, c(2, 8, 9, 10)]

#-------------------------------------------------------------------------------#
# a couple of last minute touch ups before putting in a database

colnames(artist_master_T) [1] <- 'artist_name'

amendsongs <- data.frame(cbind('song_id' = song_artist[which( ! song_artist$song_id %in% song_master_T$song_id),1]))
amendsongs$song_single <- NA; amendsongs$song_released <- NA; amendsongs$song_genre <- NA
amendsongs$song_label <- NA; amendsongs$song_songwriter <- NA; amendsongs$song_producer <- NA
song_master_T <- rbind(song_master_T, amendsongs)

amendartists <- unique(data.frame(cbind('artist_name' = song_artist[which( ! song_artist$artist_name %in% artist_master_T$artist_name), 3])))
amendartists$birthday <- NA; amendartists$country <- NA; amendartists$startyear <- NA
artist_master_T <- rbind(artist_master_T, amendartists)