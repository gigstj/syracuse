#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#                      Predicting ERA with the DICE Method                     #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#


#---------------------------build the DICE base table--------------------------#


dice_pitching <-as.data.frame(sqldf('select
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


#-------------------------Join in player and team names------------------------#


#join in the player name
dice_pitching <-left_join(dice_pitching, id_plookup, by = "playerID")

#change teamID "FLO" to "MIA"
dice_pitching[which(dice_pitching$teamID=="FLO"),3] <- "MIA"

#join in the team name
dice_pitching <- left_join(dice_pitching, id_tlookup, by = "teamID") 


#--------------------------build players by year table-------------------------#


#build new table for players by year
dice_players_yr <- as.data.frame(sqldf('select 
dice_pitching.playerName, dice_pitching.yearID,
sum(dice_pitching.BB) as "BB",
sum(dice_pitching.HBP) as "HBP",
sum(dice_pitching.SO) as "SO",
sum(dice_pitching.HR) as "HR",
sum(dice_pitching.ER) as "ER",
sum(dice_pitching.IP) as "IP"
from dice_pitching group by 
dice_pitching.playerName, dice_pitching.yearID'))


#-------------------------clean up players by year table-----------------------#


#delete records with < 100 innings pitched
dice_players_yr <- dice_players_yr[-which(dice_players_yr[,8]<50),]
#create new column as the calculated ERA
dice_players_yr$ERA <- (dice_players_yr$ER * 9) / dice_players_yr$IP
#create new column as the calculated DICE
dice_players_yr$DICE <- 3+(((13*dice_players_yr$HR)+(3*(dice_players_yr$BB
+dice_players_yr$HBP)) -(2*dice_players_yr$SO))/dice_players_yr$IP) 


#new column as lookup ID for current year
dice_players_yr$playerCurrentYear <-
  paste(dice_players_yr$playerName, dice_players_yr$yearID, sep = "_")
#new column as lookup ID for previous year
dice_players_yr$playerYearLookupID <-
  paste(dice_players_yr$playerName, dice_players_yr$yearID-1, sep = "_")


#new data frame as lookup table for prev year DICE
dice_players_look <- (dice_players_look <- dice_players_yr[,-1:-9])[,-3]
#rename columns in the lookup table
colnames(dice_players_look) <- c("DICEPrev", "playerYearLookupID")


#join in previous year DICE from lookup table
dice_players_yr <- 
  inner_join(dice_players_yr, dice_players_look, by = "playerYearLookupID")
#remove some columns that are not needed
dice_players_yr <- dice_players_yr[,-3:-8]


#run a binary test to see if prev year exists
dice_players_yr$test<-paste(dice_players_yr$playerName,
  dice_players_yr$yearID-1,sep="_")%in%dice_players_yr[,5]
#get rid of records where prev year does not exist
dice_players_yr <- dice_players_yr[-which(dice_players_yr[,8]==FALSE),]


#delete more columns that are not needed
dice_players_yr <- dice_players_yr[,-4:-6]
dice_players_yr <- dice_players_yr[,-5]
#rename columns in the players by year table
colnames(dice_players_yr) <- c("playerName", "yearID", "ERACurr", "DICEPrev")


#create a new lookup column
dice_players_yr$playerYear <- 
  paste(dice_players_yr$playerName, dice_players_yr$yearID, sep = "_") 


#----------------------------Exploratory Data Analysis-------------------------#


#generate a model based on the training dataset
dice_regression_mod <- lm(formula=ERACurr ~ DICEPrev, data=dice_players_yr)
summary(dice_regression_mod)

#plot the linear regression line on the scatter plot
plot(dice_players_yr$DICEPrev, dice_players_yr$ERACurr, main = "DICE scatterplot",
xlab="DICE Prior Year", ylab="ERA Following Year")
abline(dice_regression_mod)


#---------------------measure the accuracy of the DICE forecast----------------#


#create new table
dice_model_tbl <- dice_players_yr[,-5]                  

#forecast error
dice_model_tbl$DICEerror <- dice_model_tbl$DICEPrev - dice_model_tbl$ERACurr

#absolute error
dice_model_tbl$DICEabserror <- abs(dice_model_tbl$DICEPrev - dice_model_tbl$ERACurr)

#absolute percent error
dice_model_tbl$DICEabspererr <- dice_model_tbl$DICEabserror / dice_model_tbl$ERACurr

#mean absolute percent error
mean(dice_model_tbl$DICEabspererr)

#forecast accuracy column
dice_model_tbl$DICEaccuracy <- ifelse(dice_model_tbl[,7] >= 1, 0, 1-dice_model_tbl[,7])

#mean forecast accuracy
mean(dice_model_tbl$DICEaccuracy) 

#total forecast accuracy all
1-(sum(dice_model_tbl$DICEabserror)/sum(dice_model_tbl$ERACurr))