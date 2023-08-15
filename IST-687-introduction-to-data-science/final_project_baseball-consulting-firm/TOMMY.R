#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#                             The Tommy Johns Effect                           #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#


#------------------------build the Tommy Johns base table----------------------#


tommy_pitching <-as.data.frame(sqldf('select
raw_pitching.playerID, raw_pitching.yearID, raw_pitching.teamID,
sum(raw_pitching.IPOuts / 3) as "IP",
sum(raw_pitching.ER) as "ER",
sum(raw_pitching.BFP) as "BFP",
sum(raw_pitching.SO) as "SO",
sum(raw_pitching.BB) as "BB",
sum(raw_pitching.HBP) as "HBP", 
sum(raw_pitching.HR) as "HR",
sum(raw_pitching.H) as "H",
sum(raw_pitching.R) as "R"
from raw_pitching where raw_pitching.yearID > 2004 group by
raw_pitching.playerID, raw_pitching.yearID, raw_pitching.teamID'))


#-----------------------------Join in new variables----------------------------#


#join in the player name
tommy_pitching <-left_join(tommy_pitching, id_plookup, by = "playerID")

#change teamID "FLO" to "MIA"
tommy_pitching[which(tommy_pitching$teamID=="FLO"),3] <- "MIA"

#join in the team name
tommy_pitching <- left_join(tommy_pitching, id_tlookup, by = "teamID")

#join in tommy johns players
tommy_pitching_lookup <- raw_tommyjohns[1:2]
colnames(tommy_pitching_lookup) <- c('playerName', 'surgeryDate')
tommy_pitching_lookup <- as.data.frame(sqldf('select playerName, min(surgeryDate)
as surgeryDate from tommy_pitching_lookup group by playerName'))
tommy_pitching_lookup$surgeryDate <- as.numeric(RIGHT(tommy_pitching_lookup$surgeryDate, 4))
colnames(tommy_pitching_lookup) <- c('playerName', 'surgeryYear')
tommy_pitching[which(tommy_pitching$playerName == 'A. J. Griffin'),13] <- 'AJ. Griffin'
tommy_pitching[which(tommy_pitching$playerName == 'AJ Ramos'),13] <- 'AJ. Ramos'
tommy_pitching <- left_join(tommy_pitching, tommy_pitching_lookup, on="playerName")

#join in the characteristics
tommy_pitching <- left_join(tommy_pitching, id_charlookup, by="playerID")

#calculate the age
tommy_pitching$age <- tommy_pitching$yearID-tommy_pitching$birthYear


#--------------------------build players by year table-------------------------#


tommy_players_yr <- as.data.frame(sqldf('select
tommy_pitching.playerName, tommy_pitching.yearID,
tommy_pitching.surgeryYear, tommy_pitching.age,
sum(tommy_pitching.ER) as "ER",
sum(tommy_pitching.IP) as "IP"
from tommy_pitching group by
tommy_pitching.playerName, tommy_pitching.yearID'))


#-------------------------clean up players by year table-----------------------#


#delete records with < 25 innings pitched
tommy_players_yr <- tommy_players_yr[-which(tommy_players_yr[,6]<25),]
#create new column as the calculated ERA
tommy_players_yr$ERA <- (tommy_players_yr$ER * 9) / tommy_players_yr$IP
#remove the records that have no surgeries
tommy_players_yr <- tommy_players_yr[which(is.na(tommy_players_yr$surgeryYear)==FALSE),]


#perform a test to check if surgery date is within the players range of data
tommy_surgery_lookup <- as.data.frame(sqldf('select playerName, max(yearID) as EndYear, 
min(yearID) as StartYear from tommy_players_yr group by playerName'))
tommy_players_yr <- left_join(tommy_players_yr, tommy_surgery_lookup, on = "playerName")
tommy_players_yr$test <- 
tommy_players_yr$surgeryYear <= tommy_players_yr$EndYear &
tommy_players_yr$surgeryYear > tommy_players_yr$StartYear


#remove records where the surgery was not within the players range of data
tommy_players_yr <- tommy_players_yr[which(tommy_players_yr$test==TRUE),]


#remove columns that are no longer needed
tommy_players_yr <- tommy_players_yr[,-8:-10]


#calculate column for the age at which the player had the surgery
tommy_players_yr$surgeryAge <- (tommy_players_yr$surgeryYear - tommy_players_yr$yearID) + tommy_players_yr$age


#------------------------------ERA Tommy johns Surgery-------------------------#


#build the surgery table for ERA
tommy_surgery_lookup2 <- as.data.frame(sqldf('
select playerName,
avg(surgeryYear) as surgeryYear,
avg(surgeryAge) as surgeryAge
from tommy_players_yr
group by playerName'))
tommy_era_analysis <- tommy_players_yr[,-4:-6]
tommy_era_analysis$Before <- tommy_era_analysis$yearID < tommy_era_analysis$surgeryYear
tommy_era_analysis <- tommy_era_analysis[,-2:-3]
tommy_era_analysis <- tommy_era_analysis[,-3]
tommy_era_analysis$Before <- as.character(tommy_era_analysis$Before)
tommy_era_analysis <- cast(tommy_era_analysis, playerName ~ Before, value="ERA",mean)
tommy_era_analysis <- left_join(tommy_era_analysis, tommy_surgery_lookup2, on="playerName")


#calculate average ERA total per row
tommy_era_analysis$ERAavgTotal <- rowMeans(tommy_era_analysis[2:3], na.rm=TRUE)


#adjust column names accordingly
colnames(tommy_era_analysis) <- c("playerName", "ERAafter", "ERAbefore", "surgeryYear", "surgeryAge", "ERAavgTotal")


#average age of the surgeries and distribution
mean(tommy_era_analysis$surgeryAge)
hist(tommy_era_analysis$surgeryAge, xlab="surgeryAge", main="Player Age of Tommy Johns", breaks=20)


#average ERA's before surgery
mean(tommy_era_analysis$ERAbefore)


#average ERA's after surgery
mean(tommy_era_analysis$ERAafter)


#------------------------------IP Tommy johns Surgery--------------------------#


#build the surgery table for ERA
tommy_ip_analysis <- tommy_players_yr[,-4:-5]
tommy_ip_analysis <- tommy_players_yr[,-5]
tommy_ip_analysis$Before <- tommy_ip_analysis$yearID < tommy_ip_analysis$surgeryYear
tommy_ip_analysis <- tommy_ip_analysis[,-2:-4]
tommy_ip_analysis <- tommy_ip_analysis[,-3:-4]
tommy_ip_analysis$Before <- as.character(tommy_ip_analysis$Before)
tommy_ip_analysis <- cast(tommy_ip_analysis, playerName ~ Before, value="IP",mean)
tommy_ip_analysis <- left_join(tommy_ip_analysis, tommy_surgery_lookup2, on="playerName")


#calculate avipge ip total per row
tommy_ip_analysis$ipavgTotal <- rowMeans(tommy_ip_analysis[2:3], na.rm=TRUE)


#adjust column names accordingly
colnames(tommy_ip_analysis) <- c("playerName", "IPafter", "IPbefore", "surgeryYear", "surgeryAge", "IPavgTotal")


#avipge age of the surgeries and distribution
mean(tommy_ip_analysis$surgeryAge)
hist(tommy_ip_analysis$surgeryAge, xlab="surgeryAge", main="Player Age of Tommy Johns", breaks=20)


#avipge ip's before surgery
mean(tommy_ip_analysis$IPbefore)


#average ip's after surgery
mean(tommy_ip_analysis$IPafter)