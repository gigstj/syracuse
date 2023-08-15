#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#              Predicting ERA with SVM Machine Learning Algorithm              #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#


#---------------------------build the SVM base table---------------------------#


SVM_pitching <-as.data.frame(sqldf('select
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
SVM_pitching <-left_join(SVM_pitching, id_plookup, by = "playerID")

#change teamID "FLO" to "MIA"
SVM_pitching[which(SVM_pitching$teamID=="FLO"),3] <- "MIA"

#join in the team name
SVM_pitching <- left_join(SVM_pitching, id_tlookup, by = "teamID") 


#--------------------------build players by year table-------------------------#


#build new table for players by year
SVM_players_yr <- as.data.frame(sqldf('select 
SVM_pitching.playerName, SVM_pitching.yearID,
sum(SVM_pitching.BB) as "BB",
sum(SVM_pitching.HBP) as "HBP",
sum(SVM_pitching.SO) as "SO",
sum(SVM_pitching.HR) as "HR",
sum(SVM_pitching.ER) as "ER",
sum(SVM_pitching.IP) as "IP"
from SVM_pitching group by 
SVM_pitching.playerName, SVM_pitching.yearID'))


#-------------------------clean up players by year table-----------------------#


#delete records with < 100 innings pitched
SVM_players_yr <- SVM_players_yr[-which(SVM_players_yr[,8]<50),]
#create new column as the calculated ERA
SVM_players_yr$ERA <- (SVM_players_yr$ER * 9) / SVM_players_yr$IP


#new column as lookup ID for current year
SVM_players_yr$playerCurrentYear <-
  paste(SVM_players_yr$playerName, SVM_players_yr$yearID, sep = "_")
#new column as lookup ID for next year
SVM_players_yr$playerYearLookupID <-
  paste(SVM_players_yr$playerName, SVM_players_yr$yearID+1, sep = "_")


#new data frame as lookup table for next year ERA
SVM_players_look <- (SVM_players_look <- SVM_players_yr[,-1:-8])[,-3]
#rename columns in the lookup table
colnames(SVM_players_look) <- c("ERANext", "playerYearLookupID")


#join in next year ERA from lookup table
SVM_players_yr <- 
  inner_join(SVM_players_yr, SVM_players_look, by = "playerYearLookupID")
#remove some columns that are not needed
SVM_players_yr <- SVM_players_yr[,-11]


#run a binary test to see if next year exists
SVM_players_yr$test<-paste(SVM_players_yr$playerName,
  SVM_players_yr$yearID+1,sep="_")%in%SVM_players_yr[,10]
#get rid of records where prev year does not exist
SVM_players_yr <- SVM_players_yr[-which(SVM_players_yr[,12]==FALSE),]


#delete more columns that are not needed
SVM_players_yr <- SVM_players_yr[,-10]
SVM_players_yr <- SVM_players_yr[,-11]


#----------------------Build datasets for the ERA SVM model--------------------#


#establish the parameters
SVM_randIndex <- sample(1:dim(SVM_players_yr)[1])
SVM_cutPoint <- floor(2*dim(SVM_players_yr)[1]/3)

#build training dataset
SVM_pitching_train <- SVM_players_yr[era_randIndex[1:SVM_cutPoint],]
SVM_pitching_train <- SVM_pitching_train[-1:-2]

#build testing dataset
SVM_pitching_test <-
  SVM_players_yr[SVM_randIndex
  [(SVM_cutPoint+1):dim(SVM_players_yr)[1]],]
SVM_pitching_test <- SVM_pitching_test[-1:-2]


#----------------------------Exploratory Data Analysis-------------------------#


#correlation between prior year walks and following year ERA
cor(SVM_pitching_train[,1], SVM_pitching_train[,8])
#scatter plot of prior year walks (x) and following year ERA (y)
ggplot(SVM_pitching_train, aes(x=BB, y=ERANext)) + geom_point()

#correlation between prior year hit by pitch and following year ERA
cor(SVM_pitching_train[,2], SVM_pitching_train[,8])
#scatter plot of prior year HBP (x) and following year ERA (y)
ggplot(SVM_pitching_train, aes(x=HBP, y=ERANext)) + geom_point()

#correlation between prior year strike outs and following year ERA
cor(SVM_pitching_train[,3], SVM_pitching_train[,8])
#scatter plot of prior year strike outs (x) and following year ERA (y)
ggplot(SVM_pitching_train, aes(x=SO, y=ERANext)) + geom_point()

#correlation between prior year home runs given up and following year ERA
cor(SVM_pitching_train[,4], SVM_pitching_train[,8])
#scatter plot of prior year home runs given up (x) and following year ERA (y)
ggplot(SVM_pitching_train, aes(x=HR, y=ERANext)) + geom_point()

#correlation between prior year earned runs and following year ERA
cor(SVM_pitching_train[,5], SVM_pitching_train[,8])
#scatter plot of prior year earned runs (x) and following year ERA (y)
ggplot(SVM_pitching_train, aes(x=ER, y=ERANext)) + geom_point()

#correlation between prior year innings pitched and following year ERA
cor(SVM_pitching_train[,6], SVM_pitching_train[,8])
#scatter plot of prior year innings pitched (x) and following year ERA (y)
ggplot(SVM_pitching_train, aes(x=IP, y=ERANext)) + geom_point()


#------------------------Develop the model and implement it--------------------#


#generate a model based on the training dataset
SVM_pitching_mod <- svm(ERANext ~ ., data=SVM_pitching_train)
summary(SVM_pitching_mod)


#predict ERA's using the model on the testing dataset
SVM_pitching_test$ERAfcst <- predict(SVM_pitching_mod, SVM_pitching_test)


#-----------------measure the accuracy of the ERA regression model-------------#


#forecast error
SVM_pitching_test$ERAerror <- SVM_pitching_test$ERAfcst-SVM_pitching_test$ERANext

#absolute error
SVM_pitching_test$ERAabserror <- abs(SVM_pitching_test$ERAfcst-SVM_pitching_test$ERANext)

#absolute percentage error
SVM_pitching_test$ERAabspererr <- SVM_pitching_test$ERAabserror / SVM_pitching_test$ERANext

#mean absolute percentage error
mean(SVM_pitching_test$ERAabspererr)

#forecast accuracy column
SVM_pitching_test$ERAaccuracy <- ifelse(SVM_pitching_test[,12] >= 1, 0, 1-SVM_pitching_test[,12])

#mean forecast accuracy
mean(SVM_pitching_test$ERAaccuracy)

#total forecast accuracy all
1-(sum(SVM_pitching_test$ERAabserror)/sum(SVM_pitching_test$ERANext))

#Visualize the accuracy results
plot(SVM_pitching_test$ERANext, SVM_pitching_test$ERAaccuracy)
ggplot(SVM_pitching_test, aes(x=ERANext, y=ERAaccuracy)) + geom_point(aes(size=ERAabserror))
