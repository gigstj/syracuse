#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#               Predicting ERA with Linear Regression of Past ERA              #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#


#---------------------------build the ERA base table---------------------------#


era_pitching <- as.data.frame(sqldf('select
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
era_pitching <- left_join(era_pitching, id_plookup, by = "playerID")
#change teamID "FLO" to "MIA"
era_pitching[which(era_pitching$teamID=="FLO"),3] <- "MIA"
#join in the team name 
era_pitching <- left_join(era_pitching, id_tlookup, by = "teamID")     


#--------------------------build players by year table-------------------------#


era_players_yr <- as.data.frame(sqldf('select
era_pitching.playerName, era_pitching.yearID,
sum(era_pitching.ER) as "ER",
sum(era_pitching.IP) as "IP"
from era_pitching group by
era_pitching.playerName, era_pitching.yearID'))


#-------------------------clean up players by year table-----------------------#


#delete records with < 100 innings pitched
era_players_yr <- era_players_yr[-which(era_players_yr[,4]<50),]
#create new column as the calculated ERA
era_players_yr$ERA <- (era_players_yr$ER * 9) / era_players_yr$IP


#new column as lookup ID for current year
era_players_yr$playerCurrentYear <-                                                                 
  paste(era_players_yr$playerName, era_players_yr$yearID, sep = "_")
#new column as lookup ID for previous year
era_players_yr$playerYearLookupID <-                                                               
  paste(era_players_yr$playerName, era_players_yr$yearID-1, sep = "_")
#new data frame as lookup table for prev year ERA
era_players_look <- (era_players_look <- era_players_yr[,-1:-4])[,-3]
#rename columns in the lookup table
colnames(era_players_look) <- c("ERAPrev", "playerYearLookupID")


#join in previous year ERA from the lookup table
era_players_yr <-
  inner_join(era_players_yr, era_players_look, by = "playerYearLookupID")
#remove some columns that are not needed                 
era_players_yr <- era_players_yr[,-3:-4]


#run a binary test to see if prev year exists
era_players_yr$test <- paste(era_players_yr$playerName,
  era_players_yr$yearID-1,sep="_")%in%era_players_yr[,4]
#get rid of records where prev year does not exist
era_players_yr <- era_players_yr[-which(era_players_yr[,7]==FALSE),]


#delete more columns that are not needed
era_players_yr <- era_players_yr[,-4:-5]                                                                            
era_players_yr <- era_players_yr[,-5]
#rename columns in the players by year table
colnames(era_players_yr) <- c("playerName", "yearID", "ERACurr", "ERAPrev")


#create a new lookup column
era_players_yr$playerYear <-
  paste(era_players_yr$playerName, era_players_yr$yearID, sep = "_")                     


#------------------Build datasets for the ERA regression model-----------------#


#establish the parameters
era_randIndex <- sample(1:dim(era_players_yr)[1])
era_cutPoint <- floor(2*dim(era_players_yr)[1]/3)

#build training dataset
era_regression_train <- era_players_yr[era_randIndex[1:era_cutPoint],]
era_regression_train <- era_regression_train[-1:-2]
era_regression_train <- era_regression_train[-3]

#build testing dataset
era_regression_test <-
era_players_yr[era_randIndex
[(era_cutPoint+1):dim(era_players_yr)[1]],]
era_regression_test <- era_regression_test[-1:-2]
era_regression_test <- era_regression_test[-3]


#----------------------------Exploratory Data Analysis-------------------------#


#correlation between prior year ERA and following year ERA
cor(era_regression_train[,2], era_regression_train[,1])

#scatter plot of prior year ERA (x) and following year ERA (y)
ggplot(era_regression_train, aes(x=ERAPrev, y=ERACurr)) + geom_point()


#------------------------Develop the model and implement it--------------------#


#generate a model based on the training dataset
era_regression_mod <- lm(formula=ERACurr ~ ERAPrev, data=era_regression_train)
summary(era_regression_mod)

#plot the linear regression line on the scatter plot
plot(era_regression_train$ERAPrev, era_regression_train$ERACurr, 
     main = "Predicting ERA with Linear Regression", 
     xlab='Last Year ERA', 
     ylab='Next Year ERA')
abline(era_regression_mod)

#predict ERA's using the model on the testing dataset
era_regression_test$ERAfcst <- predict(era_regression_mod, era_regression_test)


#-----------------measure the accuracy of the ERA regression model-------------#


#forecast error
era_regression_test$ERAerror <- era_regression_test$ERAfcst-era_regression_test$ERACurr

#absolute error
era_regression_test$ERAabserror <- abs(era_regression_test$ERAfcst-era_regression_test$ERACurr)

#absolute percentage error
era_regression_test$ERAabspererr <- era_regression_test$ERAabserror / era_regression_test$ERACurr

#mean absolute percentage error
mean(era_regression_test$ERAabspererr)

#forecast accuracy column
era_regression_test$ERAaccuracy <- ifelse(era_regression_test[,6] >= 1, 0, 1-era_regression_test[,6])

#mean forecast accuracy
mean(era_regression_test$ERAaccuracy)

#total forecast accuracy all
1-(sum(era_regression_test$ERAabserror)/sum(era_regression_test$ERACurr))