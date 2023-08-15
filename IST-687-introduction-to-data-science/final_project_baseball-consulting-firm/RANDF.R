#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#        Predicting ERA with Random Forest Machine Learning Algorithm          #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#


#--------------------------build the RANDF base table--------------------------#


randf_pitching <-as.data.frame(sqldf('select
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
randf_pitching <-left_join(randf_pitching, id_plookup, by = "playerID")

#change teamID "FLO" to "MIA"
randf_pitching[which(randf_pitching$teamID=="FLO"),3] <- "MIA"

#join in the team name
randf_pitching <- left_join(randf_pitching, id_tlookup, by = "teamID")

#join in the salary
randf_pitching$LookupID <- paste(randf_pitching$playerID, randf_pitching$yearID, sep="_")
randf_pitching <- left_join(randf_pitching, id_sllookup, by = "LookupID")

#join in the characteristics
randf_pitching <- left_join(randf_pitching, id_charlookup, by="playerID")

#calculate the age
randf_pitching$age <- randf_pitching$yearID-randf_pitching$birthYear

#--------------------------build players by year table-------------------------#


#build new table for players by year
randf_players_yr <- as.data.frame(sqldf('select 
randf_pitching.playerName, randf_pitching.yearID,
randf_pitching.Salary, randf_pitching.age,
randf_pitching.weight, randf_pitching.height,
randf_pitching.throws,
sum(randf_pitching.BFP) as "BFP",
sum(randf_pitching.SO) as "SO",
sum(randf_pitching.ER) as "ER",
sum(randf_pitching.IP) as "IP"
from randf_pitching group by 
randf_pitching.playerName, randf_pitching.yearID'))


#-------------------------clean up players by year table-----------------------#


#pad the na's in the player salaries
randf_salary_look <- as.data.frame(sqldf('select distinct playerName, avg(Salary) as Salary2 from randf_players_yr group by playerName'))
randf_salary_look$Salary2[which(is.na(randf_salary_look$Salary2))] <- as.integer(mean(randf_salary_look$Salary2, na.rm = TRUE))


#rejoin in the padded salaries
randf_players_yr <- left_join(randf_players_yr, randf_salary_look, by="playerName")
randf_players_yr$salarypad <- ifelse(is.na(randf_players_yr$Salary), randf_players_yr$Salary2, randf_players_yr$Salary)


#delete records with < 100 innings pitched
randf_players_yr <- randf_players_yr[-which(randf_players_yr[,11]<50),]
#create new column as the calculated ERA
randf_players_yr$ERA <- (randf_players_yr$ER * 9) / randf_players_yr$IP


#new column as lookup ID for current year
randf_players_yr$playerCurrentYear <-
  paste(randf_players_yr$playerName, randf_players_yr$yearID, sep = "_")
#new column as lookup ID for next year
randf_players_yr$playerYearLookupID <-
  paste(randf_players_yr$playerName, randf_players_yr$yearID+1, sep = "_")


#new data frame as lookup table for next year ERA
randf_players_look <- (randf_players_look <- randf_players_yr[,-1:-13])[,-3]
#rename columns in the lookup table
colnames(randf_players_look) <- c("ERANext", "playerYearLookupID")


#join in next year ERA from lookup table
randf_players_yr <- 
inner_join(randf_players_yr, randf_players_look, by = "playerYearLookupID")
#remove some columns that are not needed
randf_players_yr <- randf_players_yr[,-12]


#run a binary test to see if next year exists
randf_players_yr$test<-paste(randf_players_yr$playerName,
randf_players_yr$yearID+1,sep="_")%in%randf_players_yr[,14]
#get rid of records where prev year does not exist
randf_players_yr <- randf_players_yr[-which(randf_players_yr[,17]==FALSE),]


#delete more columns that are not needed
randf_players_yr <- randf_players_yr[,-3]
randf_players_yr$salarypad <- as.integer(randf_players_yr$salarypad)
randf_players_yr <- randf_players_yr[,-13:-14]
randf_players_yr <- randf_players_yr[,-14]


#-----------------Build datasets for the ERA random forest model---------------#


#establish the parameters
randf_randIndex <- sample(1:dim(randf_players_yr)[1])
randf_cutPoint <- floor(2*dim(randf_players_yr)[1]/3)

#build training dataset
randf_pitching_train <- randf_players_yr[era_randIndex[1:randf_cutPoint],]
randf_pitching_train <- randf_pitching_train[-1:-2]


#build testing dataset
randf_pitching_test <-
randf_players_yr[randf_randIndex
[(randf_cutPoint+1):dim(randf_players_yr)[1]],]
randf_pitching_test <- randf_pitching_test[-1:-2]


#----------------------------Exploratory Data Analysis-------------------------#


#correlation between age and following year ERA
cor(randf_pitching_train[,1], randf_pitching_train[,11])
#scatter plot of prior year age (x) and following year ERA (y)
ggplot(randf_pitching_train, aes(x=age, y=ERANext)) + geom_point()

#correlation between weight and following year ERA
cor(randf_pitching_train[,2], randf_pitching_train[,11])
#scatter plot of prior year weight (x) and following year ERA (y)
ggplot(randf_pitching_train, aes(x=weight, y=ERANext)) + geom_point()

#correlation between height and following year ERA
cor(randf_pitching_train[,3], randf_pitching_train[,11])
#scatter plot of prior year height (x) and following year ERA (y)
ggplot(randf_pitching_train, aes(x=height, y=ERANext)) + geom_point()

#correlation between throws and following year ERA
mean(randf_pitching_train[which(randf_pitching_train$throws=='R'),11]) #righty ERA
mean(randf_pitching_train[which(randf_pitching_train$throws=='L'),11]) #lefty ERA

#correlation between salary and following year ERA
cor(randf_pitching_train[,9], randf_pitching_train[,11])
#scatter plot of prior year salary (x) and following year ERA (y)
ggplot(randf_pitching_train, aes(x=salarypad, y=ERANext)) + geom_point()

#correlation between batters faced by pitcher and following year ERA
cor(randf_pitching_train[,5], randf_pitching_train[,11])
#scatter plot of prior year batters faced by pitcher (x) and following year ERA (y)
ggplot(randf_pitching_train, aes(x=BFP, y=ERANext)) + geom_point()

#correlation between strikeoutsby pitcher and following year ERA
cor(randf_players_yr[,7], randf_players_yr[,13])
#scatter plot of prior year strikeouts by pitcher (x) and following year ERA (y)
ggplot(randf_players_yr, aes(x=BFP, y=ERANext)) + geom_point()


#------------------------Develop the model and implement it--------------------#


#generate a model based on the training dataset
randf_pitching_mod <- randomForest(formula=ERANext ~ ., data=randf_pitching_train)
summary(randf_pitching_mod)


#predict ERA's using the model on the testing dataset
randf_pitching_test$ERAfcst <- predict(randf_pitching_mod, randf_pitching_test)


#-----------------measure the accuracy of the random forest model--------------#


#forecast error
randf_pitching_test$ERAerror <- randf_pitching_test$ERAfcst-randf_pitching_test$ERANext

#absolute error
randf_pitching_test$ERAabserror <- abs(randf_pitching_test$ERAfcst-randf_pitching_test$ERANext)

#absolute percentage error
randf_pitching_test$ERAabspererr <- randf_pitching_test$ERAabserror / randf_pitching_test$ERANext

#mean absolute percentage error
mean(randf_pitching_test$ERAabspererr)

#forecast accuracy column
randf_pitching_test$ERAaccuracy <- ifelse(randf_pitching_test$ERAabspererr >= 1, 0, 1-randf_pitching_test$ERAabspererr)

#mean forecast accuracy
mean(randf_pitching_test$ERAaccuracy)

#total forecast accuracy all
1-(sum(randf_pitching_test$ERAabserror)/sum(randf_pitching_test$ERANext))

#Visualize the accuracy results
plot(randf_pitching_test$ERANext, randf_pitching_test$ERAaccuracy)
ggplot(randf_pitching_test, aes(x=ERANext, y=ERAaccuracy)) + geom_point(aes(size=ERAabserror))