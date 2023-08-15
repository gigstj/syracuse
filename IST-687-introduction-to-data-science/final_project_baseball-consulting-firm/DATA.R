#packages needed
require(RSQLite) #install.packages('RSQLite')
require(sqldf) #install.packages('sqldf')
require(dplyr) #install.packages('dplyr')
require(ggplot2) #install.packages('ggplot2')
require(moments) #install.packages('moments')
require(scales) #install.packages('scales')
require(arules) #install.packages('arules')
require(arulesViz) #install.packages('arulesViz')
require(kernlab) #install.packages('kernlab')
require(e1071) #install.packages('e1071')
require(gridExtra) #install.packages('gridExtra')
require(caret) #install.packages('caret')
require(googlesheets) #install.packages('googlesheets')
require(gsheet) #install.packages('gsheet')
require(randomforest) #install.packages('randomforest')
require(reshape2) #install.packages('reshape2')
require(reshape) #install.packages('reshape')


#load raw data
raw_pitching <- read.csv(url("http://github.com/chadwickbureau/baseballdatabank/raw/master/core/Pitching.csv"))
raw_teams <- read.csv(url("https://github.com/chadwickbureau/baseballdatabank/raw/master/core/Teams.csv"))
raw_players <- read.csv(url("https://github.com/chadwickbureau/baseballdatabank/blob/master/core/People.csv?raw=true"))
raw_salary <- read.csv(url("https://raw.githubusercontent.com/chadwickbureau/baseballdatabank/master/core/Salaries.csv"))
raw_tommyjohns <- gsheet2tbl('https://docs.google.com/spreadsheets/d/1gQujXQQGOVNaiuwSN680Hq-FDVsCwvN-3AazykOBON0/edit#gid=0')


#lookup tables
id_plookup  <-   as.data.frame(sqldf('select raw_players.playerID, raw_players.nameFirst,
                 raw_players.nameLast from raw_players group by raw_players.playerID'))
                 id_plookup$playerName <- paste(id_plookup$nameFirst, id_plookup$nameLast, sep = " ")
                 id_plookup <- id_plookup[,-2:-3]
id_tlookup  <-   as.data.frame(sqldf('select raw_teams.teamID, raw_teams.name as "teamName" 
                 from raw_teams where raw_teams.yearID > 2004 group by raw_teams.teamID'))
                 id_tlookup <- id_tlookup[-which(id_tlookup$teamID=="FLO"),]
                 id_tlookup[which(id_tlookup$teamID=="TBA"),2] <- "Tampa Bay Rays"
                 row.names(id_tlookup) <- NULL
id_sllookup  <-  data.frame(LookupID=paste(raw_salary$playerID, raw_salary$yearID, sep = "_"), Salary=raw_salary$salary)
id_charlookup <- as.data.frame(sqldf('select raw_players.playerID, raw_players.birthYear,
                 raw_players.weight, raw_players.height, raw_players.throws from raw_players'))
id_charlookup$weight[which(is.na(id_charlookup$weight))] <- as.integer(mean(id_charlookup$weight, na.rm = TRUE))
id_charlookup$height[which(is.na(id_charlookup$height))] <- as.integer(mean(id_charlookup$height, na.rm = TRUE))
id_charlookup$birthYear[which(is.na(id_charlookup$birthYear))] <- sample(id_charlookup$birthYear,1)
id_charlookup$throws[which(id_charlookup$throws=='')] <- sample(id_charlookup$throws,1)


#functions
RIGHT = function(x,n){
substring(x,nchar(x)-n+1)}

Surgery <- function(year1, year2){
if(year1==year2)
return(TRUE)
return(FALSE)}