#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#
#                          More analysis for the project                       #
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~#


#build new table
moredata_age <- as.data.frame(sqldf('select 
randf_pitching.playerName, randf_pitching.yearID,
randf_pitching.age,
sum(randf_pitching.SO) as "SO",
sum(randf_pitching.ER) as "ER",
sum(randf_pitching.IP) as "IP"
from randf_pitching group by 
randf_pitching.playerName, randf_pitching.yearID'))


#delete records with < 50 innings pitched
moredata_age <- moredata_age[-which(moredata_age[,6]<50),]
#create new column as the calculated ERA
moredata_age$ERA <- (moredata_age$ER * 9) / moredata_age$IP


#correlation between age and ERA
cor(moredata_age$age, moredata_age$ERA)
plot(moredata_age$age, moredata_age$ERA)


#correlation between age and IP
cor(moredata_age$age, moredata_age$IP)
plot(moredata_age$age, moredata_age$IP)


#correlation between age and SO
cor(moredata_age$age, moredata_age$SO)
plot(moredata_age$age, moredata_age$SO)


#correlation between age and ER
cor(moredata_age$age, moredata_age$ER)
plot(moredata_age$age, moredata_age$ER)


#build new table bucket by age
moredata_age2 <- as.data.frame(tapply(moredata_age$ERA, moredata_age$age, mean))
moredata_age2$age <- rownames(moredata_age2)
rownames(moredata_age2) <- NULL
colnames(moredata_age2) <- c("AvgERA", "Age")


#plot avg era and age
ggplot(moredata_age2, aes(x=Age, y=AvgERA)) + geom_col()


#how many teams were there in each year
countofTeams <- as.data.frame(sqldf('select count(distinct teamID) as teamCount, yearID from raw_pitching group by yearID'))
ggplot(countofTeams, aes(x=yearID, y=teamCount)) + geom_col()