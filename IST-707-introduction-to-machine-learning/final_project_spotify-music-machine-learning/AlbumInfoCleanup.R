#-------------------------------------------------------------------------------#
### initialization ###

require(dplyr)
require(rvest)
require(stringr)
require(sqldf)

#-------------------------------------------------------------------------------#

# create a temporary data frame to figure out the date cleaning

# date_cleaning <- data.frame(cbind('song_released' = unique(song_master$song_released)))

#-------------------------------------------------------------------------------#
# get rid of any text that is in parentheses and brackets

# date_cleaning$song_released <- gsub("\\(.*?)", "", date_cleaning$song_released)
# date_cleaning$song_released <- gsub("\\[.*?]", "", date_cleaning$song_released)

album_master$album_released <- gsub("\\(.*?)", "", album_master$album_released)
album_master$album_released <- gsub("\\[.*?]", "", album_master$album_released)

#-------------------------------------------------------------------------------#
# create a function to extract the month from the date

date_parse_month <- function(x, month3dig, month2dig) {
  
  tryCatch({
    month <- if (grepl(month3dig, x)) {month2dig} else {NA}},
  error = function(e) {month <<- NA})
  
return(month)
}

#-------------------------------------------------------------------------------#
# create a seperate column for whether the month is recognized
# this is because some songs had a second or third release

album_master$album_release_jan <- unlist(lapply(album_master$album_released, FUN = date_parse_month, month3dig = 'Jan', month2dig = '01'))
album_master$album_release_feb <- unlist(lapply(album_master$album_released, FUN = date_parse_month, month3dig = 'Feb', month2dig = '02'))
album_master$album_release_mar <- unlist(lapply(album_master$album_released, FUN = date_parse_month, month3dig = 'Mar', month2dig = '03'))
album_master$album_release_apr <- unlist(lapply(album_master$album_released, FUN = date_parse_month, month3dig = 'Apr', month2dig = '04'))
album_master$album_release_may <- unlist(lapply(album_master$album_released, FUN = date_parse_month, month3dig = 'May', month2dig = '05'))
album_master$album_release_jun <- unlist(lapply(album_master$album_released, FUN = date_parse_month, month3dig = 'Jun', month2dig = '06'))
album_master$album_release_jul <- unlist(lapply(album_master$album_released, FUN = date_parse_month, month3dig = 'Jul', month2dig = '07'))
album_master$album_release_aug <- unlist(lapply(album_master$album_released, FUN = date_parse_month, month3dig = 'Aug', month2dig = '08'))
album_master$album_release_sep <- unlist(lapply(album_master$album_released, FUN = date_parse_month, month3dig = 'Sep', month2dig = '09'))
album_master$album_release_oct <- unlist(lapply(album_master$album_released, FUN = date_parse_month, month3dig = 'Oct', month2dig = '10'))
album_master$album_release_nov <- unlist(lapply(album_master$album_released, FUN = date_parse_month, month3dig = 'Nov', month2dig = '11'))
album_master$album_release_dec <- unlist(lapply(album_master$album_released, FUN = date_parse_month, month3dig = 'Dec', month2dig = '12'))

#-------------------------------------------------------------------------------#
# add a column for which records have multiple months and which do not
monthcount <- c()
for (rownumber in seq(1, dim(album_master) [1] )) {
  count <- 0
  for (element in album_master[rownumber, 7:(dim(album_master) [2] )]) {
    count <- count + ! is.na(element)
  }
  monthcount <- c(monthcount, count)
}
album_master$monthcount <- monthcount   

# show the count of records for each count of months
# the large majority have one. 3 and 4 were very uncommon.
table(album_master$monthcount)

#-------------------------------------------------------------------------------#
# extract the month that we want to use for the song release month
# for the ones with more than one date, take the first one
# this will be considered the 'original' song release date

monthextract <- c()
for (rownumber in seq(1, dim(album_master) [1] )) {
  targetcolumnposition <- which(! is.na(album_master[rownumber, 7:((dim(album_master) [2] ) - 1)])) [1]
  targetcolumnposition <- ifelse(is.na(targetcolumnposition), NA, targetcolumnposition)
  targetcolumnvalue <- ifelse(is.na(targetcolumnposition), NA, album_master[rownumber, targetcolumnposition+6])
  monthextract <- c(monthextract, targetcolumnvalue)}
album_master$album_release_month <- monthextract
  
# show how many songs there are for each month
table(album_master$album_release_month)

# remove all of the columns that are no longer needed
album_master <- album_master[, -c(7:19)]

#-------------------------------------------------------------------------------#
# extract the year and date from the song release date

dayyearnumbers <- c()
for (rownumber in seq(1, dim(album_master) [1] )) {
  for (element in album_master[rownumber, 3]) {
    separatedtext <- as.numeric(str_split(element, "") %>% .[[1]])
    seperatedtext <- which(! is.na(separatedtext))
    newseparatedtext <- c()
      for (textelement in separatedtext) {
        newseparatedtext <- paste0(newseparatedtext, textelement)}
        newseparatedtext <- trimws(gsub('NA', '', newseparatedtext))
        dayyearnumbers <- c(dayyearnumbers, newseparatedtext)
  }
}

album_master$album_release_year <- dayyearnumbers

album_master$album_release_year <- substr(
  album_master$album_release_year,
  nchar(album_master$album_release_year) - 3,
  nchar(album_master$album_release_year))

album_master[which(album_master$album_release_year == ''),
            which(colnames(album_master) == 'album_release_year')] <- NA

album_master$song_release_month <- as.numeric(album_master$album_release_month)
album_master$album_release_year <- as.numeric(album_master$album_release_year)

#-------------------------------------------------------------------------------#
# extract the album genres
# the parent genre will be selected out of the following
# alternative, rock, metal, punk, pop, r&b, rap, jazz, blues, folk, country, electronic, other

album_genre_extract <- album_master[, which(colnames(album_master) %in% c('album_id', 'album_genre'))]

parent_genre_list <- c('alt', 'rock', 'metal', 'punk', 'pop', 'r&b',
                       'rap', 'jazz', 'blues', 'folk', 'country', 'elect', 'other')

# create a data frame for the parent genres
genre_dataframe <- data.frame()

  for (rownumber in seq(1, dim(album_genre_extract) [1] )) {
    for (element in album_genre_extract[rownumber, 2]) {
      newelement <- gsub("\\[.*?]", "", element)
      newelement <- tolower(newelement)
      genre_list <- c()
      for (genre in parent_genre_list) {
        check_genre <- tryCatch({ifelse(max(grepl(genre, newelement)), 1, 0)},
                       warning = function(e) {check_genre <<- 0})
        genre_list <- c(genre_list, check_genre)}
      genre_dataframe <- rbind(genre_dataframe, genre_list)}}
        
album_genre_extract <- cbind(album_genre_extract, genre_dataframe)
colnames(album_genre_extract) [3:15] <- parent_genre_list

# fill in the values for the other column
# if none of the parent genres were found, then it is considered to be other

album_genre_extract$album_genre <- ifelse(album_genre_extract$album_genre == 'character(0)', NA, album_genre_extract$album_genre)
album_genre_extract$other <- ifelse(rowSums(album_genre_extract[,3:14]) == 0, 1, 0)
album_genre_extract$other <- ifelse(is.na(album_genre_extract$album_genre), 0, album_genre_extract$other)

album_genre <- album_genre_extract

colnames(album_genre_extract) <- paste(colnames(album_genre_extract, 1))

#-------------------------------------------------------------------------------#
# create the album label dataframe
# some songs have multiple labels, take only the top 3 labels

album_label              <- album_master[, which(colnames(album_master) %in% c('album_id', 'album_label'))]
album_label$album_label   <- ifelse(album_label$album_label == 'character(0)', NA, album_label$album_label)

album_label_dataframe <- data.frame()
  for (rownumber in seq(1, dim(album_label) [1] )) {
    album_label_row <- c()
    for (element in album_label[rownumber, 2]) {
      album_label_row <- c(album_label_row, element)
      album_label1 <- album_label_row[1]
      album_label2 <- album_label_row[2]
      album_label3 <- album_label_row[3]
      album_label_matrix <- data.frame(cbind(
        'label1' = album_label1,
        'label2' = album_label2,
        'label3' = album_label3))
      album_label_dataframe <- rbind(album_label_dataframe, album_label_matrix)}}

# standardize the text. get rid of anything in (), [], and change to lower case
album_label_dataframe$label1 <- tolower(gsub("\\[.*?]", "", gsub("\\(.*?)", "", album_label_dataframe$label1)))
album_label_dataframe$label2 <- tolower(gsub("\\[.*?]", "", gsub("\\(.*?)", "", album_label_dataframe$label2)))
album_label_dataframe$label3 <- tolower(gsub("\\[.*?]", "", gsub("\\(.*?)", "", album_label_dataframe$label3)))

# append to main
album_label <- cbind(album_label, album_label_dataframe)

# create a temporary dataframe to correct the records still separated by comma
temp_label_dataframe <- album_label[which(grepl(',', album_label$label1)),]  # these are the records seperated by comma
temp_label_dataframe$label1 <- gsub(' ', '', temp_label_dataframe$label1)  # remove spaces this will help with the next step

# create a for loop to extract the comma separated labels
temp_label1 <- c()
temp_label2 <- c()
temp_label3 <- c()
for (temp_label in temp_label_dataframe$label1) {
num_commas <- length(unique(unlist(str_locate_all(temp_label, ','))))
comma_pos1 <- unique(unlist(str_locate_all(temp_label, ','))) [1]
comma_pos2 <- unique(unlist(str_locate_all(temp_label, ','))) [2]
split1 <- substr(temp_label, 1, comma_pos1 - 1)
split2 <- ifelse(num_commas > 1, 
                 substr(temp_label, comma_pos1 + 1, comma_pos2 - 1),
                 substr(temp_label, comma_pos1 + 1, nchar(temp_label)))
split3 <- substr(temp_label, comma_pos2 + 1, nchar(temp_label))
temp_label1 <- c(temp_label1, split1)
temp_label2 <- c(temp_label2, split2)
temp_label3 <- c(temp_label3, split3)
}

# join the labels into the temporary dataframe
temp_label_dataframe <- data.frame(cbind(temp_label_dataframe, temp_label1, temp_label2, temp_label3))
temp_label_dataframe <- temp_label_dataframe[, c(1, 6, 7, 8)]

# join the new labels into the main dataframe
album_label <- left_join(album_label, temp_label_dataframe, on = 'album_id')
album_label$label1 <- ifelse(is.na(album_label$temp_label1), album_label$label1, album_label$temp_label1)
album_label$label2 <- ifelse(is.na(album_label$temp_label2), album_label$label2, album_label$temp_label2)
album_label$label3 <- ifelse(is.na(album_label$temp_label3), album_label$label3, album_label$temp_label3)
album_label <- album_label[, - which(colnames(album_label) %in% c('temp_label1', 'temp_label2', 'temp_label3'))]

# clean up the environment
rm(temp_label_dataframe, comma_pos1, comma_pos2, num_commas, split1, split2, split3,
temp_label1, temp_label2, temp_label3, temp_label)

#-------------------------------------------------------------------------------#
# create the album producer dataframe
# some albums have multiple producers, take only the top 3 producers

album_producer                 <- album_master[, which(colnames(album_master) %in% c('album_id', 'album_producer'))]
album_producer$album_producer   <- ifelse(album_producer$album_producer == 'character(0)', NA, album_producer$album_producer)

album_producer_dataframe <- data.frame()
  for (rownumber in seq(1, dim(album_producer) [1] )) {
    album_producer_row <- c()
    for (element in album_producer[rownumber, 2]) {
      album_producer_row <- c(album_producer_row, element)
      album_producer1 <- album_producer_row[1]
      album_producer2 <- album_producer_row[2]
      album_producer3 <- album_producer_row[3]
      album_producer_matrix <- data.frame(cbind(
        'producer1' = album_producer1,
        'producer2' = album_producer2,
        'producer3' = album_producer3))
      album_producer_dataframe <- rbind(album_producer_dataframe, album_producer_matrix)}}

# standardize the text. get rid of anything in (), [], and change to lower case
album_producer_dataframe$producer1 <- tolower(gsub("\\[.*?]", "", gsub("\\(.*?)", "", album_producer_dataframe$producer1)))
album_producer_dataframe$producer2 <- tolower(gsub("\\[.*?]", "", gsub("\\(.*?)", "", album_producer_dataframe$producer2)))
album_producer_dataframe$producer3 <- tolower(gsub("\\[.*?]", "", gsub("\\(.*?)", "", album_producer_dataframe$producer3)))

# append to main
album_producer <- cbind(album_producer, album_producer_dataframe)

# create a temporary dataframe to correct the records still separated by comma
temp_producer_dataframe <- album_producer[which(grepl(',', album_producer$producer1)),]  # these are the records seperated by comma
temp_producer_dataframe$producer1 <- gsub(' ', '', temp_producer_dataframe$producer1)  # remove spaces this will help with the next step

# create a for loop to extract the comma separated producers
temp_producer1 <- c()
temp_producer2 <- c()
temp_producer3 <- c()
for (temp_producer in temp_producer_dataframe$producer1) {
num_commas <- length(unique(unlist(str_locate_all(temp_producer, ','))))
comma_pos1 <- unique(unlist(str_locate_all(temp_producer, ','))) [1]
comma_pos2 <- unique(unlist(str_locate_all(temp_producer, ','))) [2]
comma_pos3 <- unique(unlist(str_locate_all(temp_producer, ','))) [3]
split1 <- substr(temp_producer, 1, comma_pos1 - 1)
split2 <- ifelse(num_commas > 1, 
                 substr(temp_producer, comma_pos1 + 1, comma_pos2 - 1),
                 substr(temp_producer, comma_pos1 + 1, nchar(temp_producer)))
split3 <- ifelse(num_commas > 2,
                 substr(temp_producer, comma_pos2 + 1, comma_pos3 - 1),
                 substr(temp_producer, comma_pos2 + 1, nchar(temp_producer)))
temp_producer1 <- c(temp_producer1, split1)
temp_producer2 <- c(temp_producer2, split2)
temp_producer3 <- c(temp_producer3, split3)
}

# join the producers into the temporary dataframe
temp_producer_dataframe <- data.frame(cbind(temp_producer_dataframe, temp_producer1, temp_producer2, temp_producer3))
temp_producer_dataframe <- temp_producer_dataframe[, c(1, 6, 7, 8)]

# join the new producers into the main dataframe
album_producer <- left_join(album_producer, temp_producer_dataframe, on = 'album_id')
album_producer$producer1 <- ifelse(is.na(album_producer$temp_producer1), album_producer$producer1, album_producer$temp_producer1)
album_producer$producer2 <- ifelse(is.na(album_producer$temp_producer2), album_producer$producer2, album_producer$temp_producer2)
album_producer$producer3 <- ifelse(is.na(album_producer$temp_producer3), album_producer$producer3, album_producer$temp_producer3)
album_producer <- album_producer[, - which(colnames(album_producer) %in% c('temp_producer1', 'temp_producer2', 'temp_producer3'))]