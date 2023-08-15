#-------------------------------------------------------------------------------#
### initialization ###

require(dplyr)
require(rvest)
require(stringr)
require(sqldf)

#-------------------------------------------------------------------------------#

# clean up the environment

rm(google_search_page, song_wiki_page, google_search_result, parseresultend,
parseresultstart, skiptonext, song_artist_test, song_genre, song_google_link,
song_isalbum, song_isartist, song_label, song_producer, song_released, song_search_text,
song_single, song_songwriter, song_table_infobox, song_wiki_link, song_sample, song_artist_ID)

#-------------------------------------------------------------------------------#
# eliminate anything that came out in brackets/parentheses

song_master$song_released <- gsub("\\(.*?)", "", song_master$song_released)
song_master$song_released <- gsub("\\[.*?]", "", song_master$song_released)

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

song_master$song_release_jan <- unlist(lapply(song_master$song_released, FUN = date_parse_month, month3dig = 'Jan', month2dig = '01'))
song_master$song_release_feb <- unlist(lapply(song_master$song_released, FUN = date_parse_month, month3dig = 'Feb', month2dig = '02'))
song_master$song_release_mar <- unlist(lapply(song_master$song_released, FUN = date_parse_month, month3dig = 'Mar', month2dig = '03'))
song_master$song_release_apr <- unlist(lapply(song_master$song_released, FUN = date_parse_month, month3dig = 'Apr', month2dig = '04'))
song_master$song_release_may <- unlist(lapply(song_master$song_released, FUN = date_parse_month, month3dig = 'May', month2dig = '05'))
song_master$song_release_jun <- unlist(lapply(song_master$song_released, FUN = date_parse_month, month3dig = 'Jun', month2dig = '06'))
song_master$song_release_jul <- unlist(lapply(song_master$song_released, FUN = date_parse_month, month3dig = 'Jul', month2dig = '07'))
song_master$song_release_aug <- unlist(lapply(song_master$song_released, FUN = date_parse_month, month3dig = 'Aug', month2dig = '08'))
song_master$song_release_sep <- unlist(lapply(song_master$song_released, FUN = date_parse_month, month3dig = 'Sep', month2dig = '09'))
song_master$song_release_oct <- unlist(lapply(song_master$song_released, FUN = date_parse_month, month3dig = 'Oct', month2dig = '10'))
song_master$song_release_nov <- unlist(lapply(song_master$song_released, FUN = date_parse_month, month3dig = 'Nov', month2dig = '11'))
song_master$song_release_dec <- unlist(lapply(song_master$song_released, FUN = date_parse_month, month3dig = 'Dec', month2dig = '12'))

#-------------------------------------------------------------------------------#
# add a column for which records have multiple months and which do not
monthcount <- c()
for (rownumber in seq(1, dim(song_master) [1] )) {
  count <- 0
  for (element in song_master[rownumber, 11:(dim(song_master) [2] )]) {
    count <- count + ! is.na(element)
  }
  monthcount <- c(monthcount, count)
}
song_master$monthcount <- monthcount   

# show the count of records for each count of months
# the large majority have one. 3 and 4 were very uncommon.
table(song_master$monthcount)

#-------------------------------------------------------------------------------#
# extract the month that we want to use for the song release month
# for the ones with more than one date, take the first one
# this will be considered the 'original' song release date

monthextract <- c()
for (rownumber in seq(1, dim(song_master) [1] )) {
  targetcolumnposition <- which(! is.na(song_master[rownumber, 11:((dim(song_master) [2] ) - 1)])) [1]
  targetcolumnposition <- ifelse(is.na(targetcolumnposition), NA, targetcolumnposition)
  targetcolumnvalue <- ifelse(is.na(targetcolumnposition), NA, song_master[rownumber, targetcolumnposition+10])
  monthextract <- c(monthextract, targetcolumnvalue)}
song_master$song_release_month <- monthextract
  
# show how many songs there are for each month
table(song_master$song_release_month)

# remove all of the columns that are no longer needed
song_master <- song_master[, -c(11:23)]

#-------------------------------------------------------------------------------#
# extract the year and date from the song release date

dayyearnumbers <- c()
for (rownumber in seq(1, dim(song_master) [1] )) {
  for (element in song_master[rownumber, 6]) {
    separatedtext <- as.numeric(str_split(element, "") %>% .[[1]])
    seperatedtext <- which(! is.na(separatedtext))
    newseparatedtext <- c()
      for (textelement in separatedtext) {
        newseparatedtext <- paste0(newseparatedtext, textelement)}
        newseparatedtext <- trimws(gsub('NA', '', newseparatedtext))
        dayyearnumbers <- c(dayyearnumbers, newseparatedtext)
  }
}

song_master$song_release_year <- dayyearnumbers

song_master$song_release_year <- substr(
  song_master$song_release_year,
  nchar(song_master$song_release_year) - 3,
  nchar(song_master$song_release_year))

song_master[which(song_master$song_release_year == ''),
            which(colnames(song_master) == 'song_release_year')] <- NA

song_master$song_release_month <- as.numeric(song_master$song_release_month)
song_master$song_release_year <- as.numeric(song_master$song_release_year)

#-------------------------------------------------------------------------------#
# explore the song genres

# create a seperate table where the work will be completed
song_genre_extract <- song_master[, which(colnames(song_master) %in% c('song_id', 'song_genre'))]

# create a unique list of all of the genres
unique_genre_list <- c()

  for (rownumber in seq(1, dim(song_genre_extract) [1] )) {
    for (element in song_genre_extract[rownumber, 2]) {
      unique_genre_list <- c(unique_genre_list, element)}}

#get rid of brackets and make it unique
unique_genre_list <- gsub("\\[.*?]", "", unique_genre_list)
unique_genre_list <- tolower(unique_genre_list)
unique_genre_list <- unique(unique_genre_list)

# further extract each individual genre
# each genre should be a single word
new_unique_genre_list <- c()

  for (rownumber in seq(1, length(unique_genre_list))) {
    for (element in unique_genre_list[rownumber]) {
      atomicelement <- str_split(element, ' ') %>% .[[1]]
      new_unique_genre_list <- c(new_unique_genre_list, atomicelement)}}

new_unique_genre_list <- unique(new_unique_genre_list)

#-------------------------------------------------------------------------------#
# extract the song genres
# the parent genre will be selected out of the following
# alternative, rock, metal, punk, pop, r&b, rap, jazz, blues, folk, country, electronic, other

parent_genre_list <- c('alt', 'rock', 'metal', 'punk', 'pop', 'r&b',
                       'rap', 'jazz', 'blues', 'folk', 'country', 'elect', 'other')

# create a data frame for the parent genres
genre_dataframe <- data.frame()

  for (rownumber in seq(1, dim(song_genre_extract) [1] )) {
    for (element in song_genre_extract[rownumber, 2]) {
      newelement <- gsub("\\[.*?]", "", element)
      newelement <- tolower(newelement)
      genre_list <- c()
      for (genre in parent_genre_list) {
        check_genre <- tryCatch({ifelse(max(grepl(genre, newelement)), 1, 0)},
                       warning = function(e) {check_genre <<- 0})
        genre_list <- c(genre_list, check_genre)}
      genre_dataframe <- rbind(genre_dataframe, genre_list)}}
        
song_genre_extract <- cbind(song_genre_extract, genre_dataframe)
colnames(song_genre_extract) [3:15] <- parent_genre_list

# fill in the values for the other column
# if none of the parent genres were found, then it is considered to be other

song_genre_extract$song_genre <- ifelse(song_genre_extract$song_genre == 'character(0)', NA, song_genre_extract$song_genre)
song_genre_extract$other <- ifelse(rowSums(song_genre_extract[,3:14]) == 0, 1, 0)
song_genre_extract$other <- ifelse(is.na(song_genre_extract$song_genre), 0, song_genre_extract$other)

song_genre <- song_genre_extract
rm(song_genre_extract)

#-------------------------------------------------------------------------------#
# create the song label dataframe
# some songs have multiple labels, take only the top 3 labels

song_label              <- song_master[, which(colnames(song_master) %in% c('song_id', 'song_label'))]
song_label$song_label   <- ifelse(song_label$song_label == 'character(0)', NA, song_label$song_label)

song_label_dataframe <- data.frame()
  for (rownumber in seq(1, dim(song_label) [1] )) {
    song_label_row <- c()
    for (element in song_label[rownumber, 2]) {
      song_label_row <- c(song_label_row, element)
      song_label1 <- song_label_row[1]
      song_label2 <- song_label_row[2]
      song_label3 <- song_label_row[3]
      song_label_matrix <- data.frame(cbind(
        'label1' = song_label1,
        'label2' = song_label2,
        'label3' = song_label3))
      song_label_dataframe <- rbind(song_label_dataframe, song_label_matrix)}}

# standardize the text. get rid of anything in (), [], and change to lower case
song_label_dataframe$label1 <- tolower(gsub("\\[.*?]", "", gsub("\\(.*?)", "", song_label_dataframe$label1)))
song_label_dataframe$label2 <- tolower(gsub("\\[.*?]", "", gsub("\\(.*?)", "", song_label_dataframe$label2)))
song_label_dataframe$label3 <- tolower(gsub("\\[.*?]", "", gsub("\\(.*?)", "", song_label_dataframe$label3)))

# append to main
song_label <- cbind(song_label, song_label_dataframe)

# create a temporary dataframe to correct the records still separated by comma
temp_label_dataframe <- song_label[which(grepl(',', song_label$label1)),]  # these are the records seperated by comma
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
song_label <- left_join(song_label, temp_label_dataframe, on = 'song_id')
song_label$label1 <- ifelse(is.na(song_label$temp_label1), song_label$label1, song_label$temp_label1)
song_label$label2 <- ifelse(is.na(song_label$temp_label2), song_label$label2, song_label$temp_label2)
song_label$label3 <- ifelse(is.na(song_label$temp_label3), song_label$label3, song_label$temp_label3)
song_label <- song_label[, - which(colnames(song_label) %in% c('temp_label1', 'temp_label2', 'temp_label3'))]

# clean up the environment
rm(temp_label_dataframe, comma_pos1, comma_pos2, num_commas, split1, split2, split3,
temp_label1, temp_label2, temp_label3, temp_label)

#-------------------------------------------------------------------------------#
# create the song songwriter dataframe
# some songs have multiple songwriters, take only the top 3 songwriters

song_songwriter                   <- song_master[, which(colnames(song_master) %in% c('song_id', 'song_songwriter'))]
song_songwriter$song_songwriter   <- ifelse(song_songwriter$song_songwriter == 'character(0)', NA, song_songwriter$song_songwriter)

song_songwriter_dataframe <- data.frame()
  for (rownumber in seq(1, dim(song_songwriter) [1] )) {
    song_songwriter_row <- c()
    for (element in song_songwriter[rownumber, 2]) {
      song_songwriter_row <- c(song_songwriter_row, element)
      song_songwriter1 <- song_songwriter_row[1]
      song_songwriter2 <- song_songwriter_row[2]
      song_songwriter3 <- song_songwriter_row[3]
      song_songwriter_matrix <- data.frame(cbind(
        'songwriter1' = song_songwriter1,
        'songwriter2' = song_songwriter2,
        'songwriter3' = song_songwriter3))
      song_songwriter_dataframe <- rbind(song_songwriter_dataframe, song_songwriter_matrix)}}

# standardize the text. get rid of anything in (), [], and change to lower case
song_songwriter_dataframe$songwriter1 <- tolower(gsub("\\[.*?]", "", gsub("\\(.*?)", "", song_songwriter_dataframe$songwriter1)))
song_songwriter_dataframe$songwriter2 <- tolower(gsub("\\[.*?]", "", gsub("\\(.*?)", "", song_songwriter_dataframe$songwriter2)))
song_songwriter_dataframe$songwriter3 <- tolower(gsub("\\[.*?]", "", gsub("\\(.*?)", "", song_songwriter_dataframe$songwriter3)))

# append to main
song_songwriter <- cbind(song_songwriter, song_songwriter_dataframe)

# create a temporary dataframe to correct the records still separated by comma
temp_songwriter_dataframe <- song_songwriter[which(grepl(',', song_songwriter$songwriter1)),]  # these are the records seperated by comma
temp_songwriter_dataframe$songwriter1 <- gsub(' ', '', temp_songwriter_dataframe$songwriter1)  # remove spaces this will help with the next step

# create a for loop to extract the comma separated songwriters
temp_songwriter1 <- c()
temp_songwriter2 <- c()
temp_songwriter3 <- c()
for (temp_songwriter in temp_songwriter_dataframe$songwriter1) {
num_commas <- length(unique(unlist(str_locate_all(temp_songwriter, ','))))
comma_pos1 <- unique(unlist(str_locate_all(temp_songwriter, ','))) [1]
comma_pos2 <- unique(unlist(str_locate_all(temp_songwriter, ','))) [2]
comma_pos3 <- unique(unlist(str_locate_all(temp_songwriter, ','))) [3]
split1 <- substr(temp_songwriter, 1, comma_pos1 - 1)
split2 <- ifelse(num_commas > 1, 
                 substr(temp_songwriter, comma_pos1 + 1, comma_pos2 - 1),
                 substr(temp_songwriter, comma_pos1 + 1, nchar(temp_songwriter)))
split3 <- ifelse(num_commas > 2,
                 substr(temp_songwriter, comma_pos2 + 1, comma_pos3 - 1),
                 substr(temp_songwriter, comma_pos2 + 1, nchar(temp_songwriter)))
temp_songwriter1 <- c(temp_songwriter1, split1)
temp_songwriter2 <- c(temp_songwriter2, split2)
temp_songwriter3 <- c(temp_songwriter3, split3)
}

# join the songwriters into the temporary dataframe
temp_songwriter_dataframe <- data.frame(cbind(temp_songwriter_dataframe, temp_songwriter1, temp_songwriter2, temp_songwriter3))
temp_songwriter_dataframe <- temp_songwriter_dataframe[, c(1, 6, 7, 8)]

# join the new songwriters into the main dataframe
song_songwriter <- left_join(song_songwriter, temp_songwriter_dataframe, on = 'song_id')
song_songwriter$songwriter1 <- ifelse(is.na(song_songwriter$temp_songwriter1), song_songwriter$songwriter1, song_songwriter$temp_songwriter1)
song_songwriter$songwriter2 <- ifelse(is.na(song_songwriter$temp_songwriter2), song_songwriter$songwriter2, song_songwriter$temp_songwriter2)
song_songwriter$songwriter3 <- ifelse(is.na(song_songwriter$temp_songwriter3), song_songwriter$songwriter3, song_songwriter$temp_songwriter3)
song_songwriter <- song_songwriter[, - which(colnames(song_songwriter) %in% c('temp_songwriter1', 'temp_songwriter2', 'temp_songwriter3'))]

# clean up the environment
rm(temp_songwriter_dataframe, comma_pos1, comma_pos2, num_commas, split1, split2, split3,
temp_songwriter1, temp_songwriter2, temp_songwriter3, temp_songwriter, comma_pos3)

#-------------------------------------------------------------------------------#
# create the song producer dataframe
# some songs have multiple producers, take only the top 3 producers

song_producer                 <- song_master[, which(colnames(song_master) %in% c('song_id', 'song_producer'))]
song_producer$song_producer   <- ifelse(song_producer$song_producer == 'character(0)', NA, song_producer$song_producer)

song_producer_dataframe <- data.frame()
  for (rownumber in seq(1, dim(song_producer) [1] )) {
    song_producer_row <- c()
    for (element in song_producer[rownumber, 2]) {
      song_producer_row <- c(song_producer_row, element)
      song_producer1 <- song_producer_row[1]
      song_producer2 <- song_producer_row[2]
      song_producer3 <- song_producer_row[3]
      song_producer_matrix <- data.frame(cbind(
        'producer1' = song_producer1,
        'producer2' = song_producer2,
        'producer3' = song_producer3))
      song_producer_dataframe <- rbind(song_producer_dataframe, song_producer_matrix)}}

# standardize the text. get rid of anything in (), [], and change to lower case
song_producer_dataframe$producer1 <- tolower(gsub("\\[.*?]", "", gsub("\\(.*?)", "", song_producer_dataframe$producer1)))
song_producer_dataframe$producer2 <- tolower(gsub("\\[.*?]", "", gsub("\\(.*?)", "", song_producer_dataframe$producer2)))
song_producer_dataframe$producer3 <- tolower(gsub("\\[.*?]", "", gsub("\\(.*?)", "", song_producer_dataframe$producer3)))

# append to main
song_producer <- cbind(song_producer, song_producer_dataframe)

# create a temporary dataframe to correct the records still separated by comma
temp_producer_dataframe <- song_producer[which(grepl(',', song_producer$producer1)),]  # these are the records seperated by comma
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
song_producer <- left_join(song_producer, temp_producer_dataframe, on = 'song_id')
song_producer$producer1 <- ifelse(is.na(song_producer$temp_producer1), song_producer$producer1, song_producer$temp_producer1)
song_producer$producer2 <- ifelse(is.na(song_producer$temp_producer2), song_producer$producer2, song_producer$temp_producer2)
song_producer$producer3 <- ifelse(is.na(song_producer$temp_producer3), song_producer$producer3, song_producer$temp_producer3)
song_producer <- song_producer[, - which(colnames(song_producer) %in% c('temp_producer1', 'temp_producer2', 'temp_producer3'))]

# clean up the environment
rm(temp_producer_dataframe, comma_pos1, comma_pos2, num_commas, split1, split2, split3,
temp_producer1, temp_producer2, temp_producer3, temp_producer, comma_pos3)

#-------------------------------------------------------------------------------#
# put all the pieces back together in a new song master

song_master2 <- song_master[, c(2, 1, 3, 11, 12)]

# clean up the environment
rm(date_cleaning, genre_dataframe, song_label_dataframe, song_label_matrix, song_producer_dataframe,
song_producer_matrix, song_songwriter_dataframe, song_songwriter_matrix, addelement, atomicelement,
check_genre, checkelement, count, dayyearnumbers, element, genre, genre_list, getelement, month,
monthcount, monthcounter, monthextract, new_unique_genre_list, newelement, newseparatedtext,
nextelement, parent_genre_list, rownumber, seperatedtext, seperatedtext, song_label_row, song_label1,
song_label2, song_label3, song_label4, song_label5, song_producer_row, song_producer1, song_producer2,
song_producer3, song_songwriter_row, song_songwriter1, song_songwriter2, song_songwriter3, song_songwriter_row,
song_targetcolumnposition, targetcolumnvalue, test, testing, textelement, unique_genre_list)

#-------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------#
#-------------------------------------------------------------------------------#
### T_song_genre ###

# change the album genre column names so that when it is joined
# there is not ambiguity with the song genre column names
colnames(album_genre) [3:15] <- paste0(colnames(album_genre) [3:15], '1')

# join the album names to to the song genre
song_genre <- unique(left_join(song_genre, data.frame(cbind('song_id' = paste(song_album[,1], song_album[,2]), 'album_id' =  paste(song_album[,2], song_album[,3]))), on = 'song_id'))

# join the album genre to the song genre
song_genre <- unique(left_join(song_genre, album_genre[, c(1, 3:15)], on = 'album_id'))

# converge the values from the album genre where needed
song_genre$alt <- ifelse( ! is.na(song_genre$alt1), song_genre$alt1, song_genre$alt)
song_genre$rock <- ifelse( ! is.na(song_genre$rock1), song_genre$rock1, song_genre$rock)
song_genre$metal <- ifelse( ! is.na(song_genre$metal1), song_genre$metal1, song_genre$metal)
song_genre$punk <- ifelse( ! is.na(song_genre$punk1), song_genre$punk1, song_genre$punk)
song_genre$pop <- ifelse( ! is.na(song_genre$pop1), song_genre$pop1, song_genre$pop)
song_genre$`r&b` <- ifelse( ! is.na(song_genre$`r&b1`), song_genre$`r&b1`, song_genre$`r&b`)
song_genre$rap <- ifelse( ! is.na(song_genre$rap1), song_genre$rap1, song_genre$rap)
song_genre$jazz <- ifelse( ! is.na(song_genre$jazz1), song_genre$jazz1, song_genre$jazz)
song_genre$blues <- ifelse( ! is.na(song_genre$blues1), song_genre$blues1, song_genre$blues)
song_genre$folk <- ifelse( ! is.na(song_genre$folk1), song_genre$folk1, song_genre$folk)
song_genre$country <- ifelse( ! is.na(song_genre$country1), song_genre$country1, song_genre$country)
song_genre$elect <- ifelse( ! is.na(song_genre$elect1), song_genre$elect1, song_genre$elect)
song_genre$other <- ifelse( ! is.na(song_genre$other1), song_genre$other1, song_genre$other)

# drop the columns that were used for lookup
T_song_genre <- unique(song_genre[, c(1, 3:15)])

#-------------------------------------------------------------------------------#
### T_song_label ###

# change the album genre column names so that when it is joined
# there is not ambiguity with the song genre column names
colnames(album_label) [3:5] <- paste0(colnames(album_label) [3:5], '1')

# join the album names to to the song genre
song_label <- unique(left_join(song_label, data.frame(cbind('song_id' = paste(song_album[,1], song_album[,2]), 'album_id' =  paste(song_album[,2], song_album[,3]))), on = 'song_id'))

# join the album genre to the song genre
song_label <- unique(left_join(song_label, album_label[, c(1, 3:5)], on = 'album_id'))

# converge the values from the album genre where needed
song_label$label1 <- ifelse( ! is.na(song_label$label11), song_label$label11, song_label$label1)
song_label$label2 <- ifelse( ! is.na(song_label$label21), song_label$label21, song_label$label2)
song_label$label3 <- ifelse( ! is.na(song_label$label31), song_label$label31, song_label$label3)

# drop the columns that were used for lookup
T_song_label <- unique(song_label[, c(1, 3:5)])

#-------------------------------------------------------------------------------#
### T_song_producer ###

# change the album genre column names so that when it is joined
# there is not ambiguity with the song genre column names
colnames(album_producer) [3:5] <- paste0(colnames(album_producer) [3:5], '1')

# join the album names to to the song genre
song_producer <- unique(left_join(song_producer, data.frame(cbind('song_id' = paste(song_album[,1], song_album[,2]), 'album_id' =  paste(song_album[,2], song_album[,3]))), on = 'song_id'))

# join the album genre to the song genre
song_producer <- unique(left_join(song_producer, album_producer[, c(1, 3:5)], on = 'album_id'))

# converge the values from the album genre where needed
song_producer$producer1 <- ifelse( ! is.na(song_producer$producer11), song_producer$producer11, song_producer$producer1)
song_producer$producer2 <- ifelse( ! is.na(song_producer$producer21), song_producer$producer21, song_producer$producer2)
song_producer$producer3 <- ifelse( ! is.na(song_producer$producer31), song_producer$producer31, song_producer$producer3)

# drop the columns that were used for lookup
T_song_producer <- unique(song_producer[, c(1, 3:5)])

#-------------------------------------------------------------------------------#
### T_song_master ###

# create the data frame from the song master
T_song_master <- song_master2

# join the album names to to the song genre
T_song_master <- unique(left_join(T_song_master, data.frame(cbind('song_id' = paste(song_album[,1], song_album[,2]), 'album_id' =  paste(song_album[,2], song_album[,3]))), on = 'song_id'))

# join the album genre to the song genre
T_song_master <- unique(left_join(T_song_master, album_master[, c(2, 7:8)], on = 'album_id'))

# change album release dates to numberic to align with song release dates
T_song_master$album_release_month <- as.numeric(T_song_master$album_release_month)
T_song_master$album_release_year <- as.numeric(T_song_master$album_release_year)

# converge the values from the album genre where needed
T_song_master$song_release_month <- ifelse( ! is.na(T_song_master$album_release_month), T_song_master$album_release_month, T_song_master$song_release_month)
T_song_master$song_release_year <- ifelse( ! is.na(T_song_master$album_release_year), T_song_master$album_release_year, T_song_master$song_release_year)

# drop the columns that were used for lookup
T_song_master <- unique(T_song_master[, c(1:2, 3:5)])

#-------------------------------------------------------------------------------#
### T_song_songwriter ###

# create the data frame from the song master
T_song_songwriter <- song_songwriter[, c(1, 3:5)]

#-------------------------------------------------------------------------------#
### filter down the results to minimize the number of nulls ###

# remove NA's
T_song_master <- T_song_master[which( ! is.na(T_song_master$song_release_year)),] 


