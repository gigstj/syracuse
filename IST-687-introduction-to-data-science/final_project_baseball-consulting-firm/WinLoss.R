#winloss
wl_pitching <- as.data.frame(sqldf('select raw_pitching.playerID, raw_pitching.yearID, 
               raw_pitching.teamID, sum(raw_pitching.W) as "W", sum(raw_pitching.L) as "L" 
               from raw_pitching where raw_pitching.yearID > 2004
               group by raw_pitching.playerID, raw_pitching.yearID, raw_pitching.teamID'))
wl_pitching <- left_join(wl_pitching, id_plookup, by = "playerID")             #join in the player name
wl_pitching[which(wl_pitching$teamID=="FLO"),3] <- "MIA"                       #change teamID "FLO" to "MIA"
wl_pitching <- left_join(wl_pitching, id_tlookup, by = "teamID")               #join in the team name


#build new table for players
wl_players <- as.data.frame(sqldf('select wl_pitching.playerName, sum(wl_pitching.W) as "W", 
sum(wl_pitching.L) as "L" from wl_pitching group by wl_pitching.playerName'))
#wl_players <- wl_players[-which(wl_players[,2]==0 & wl_players[,3]==0),]                         #optional scrub W=0 & L=0
wl_players <- (wl_players <- wl_players[-which(wl_players[,2]==0),])[-which(wl_players[,3]==0),]  #optional scrub W=0 or L=0


#calculate new columns
wl_players$total_win_loss <- wl_players$W + wl_players$L          #total win + loss
wl_players$total_rel_avg <- wl_players[,4] / mean(wl_players[,4]) #total relative to avg.
wl_players$wlratio <- wl_players$W / wl_players$L                 #raw win loss ratio
wl_players$adj_wlratio <- log10(wl_players[,5]*wl_players[,6])    #normalized win loss ratio


#scrub out errors
wl_players[which(wl_players[,2]==0),6] <- 0 #where wins = 0 make win loss ratio = 0
wl_players[which(wl_players[,3]==0),6] <- 0 #where losses = 0 make win loss ratio = 0
wl_players[which(wl_players[,5]==0),7] <- 0 #where wins = 0 make adj. win loss ratio = 0
wl_players[which(wl_players[,6]==0),7] <- 0 #where losses = 0 make adj. win loss ratio = 0


#analysis
wl_players[which.max(wl_players[,2]),c(1,2)] #player with the most wins
wl_players[which.max(wl_players[,3]),c(1,3)] #player with the most losses
wl_players[which.max(wl_players[,7]),c(1,6)] #player with the best w/l ratio
wl_players[which.min(wl_players[,7]),c(1,6)] #player with the worst w/l ratio
printStats(wl_players$wlratio)               #descriptive stats of w/lratio
printStats(wl_players$adj_wlratio)           #descriptive stats of adj. w/l ratio


#visualizations
ggplot(wl_players, aes(x=wlratio)) + geom_histogram(bins=50, color="black", fill="white")   #histogram of win loss ratio
ggplot(wl_players, aes(x=adj_wlratio)) + geom_histogram(color="black", fill ="white")       #histogram of adj. win loss ratio
ggplot(wl_players, aes(W,L)) + geom_point()                                                 #scatterplot of wins/losses


#build new table for teams
wl_teams <- as.data.frame(sqldf('select wl_pitching.teamName, sum(wl_pitching.W) as "W", 
sum(wl_pitching.L) as "L" from wl_pitching group by wl_pitching.teamName'))


#calculate new columns
wl_teams$total_win_loss <- wl_teams$W + wl_teams$L              #total win + loss
wl_teams$total_rel_avg <- wl_teams[,4] / mean(wl_teams[,4])     #total relative to avg.
wl_teams$wlratio <- wl_teams$W / wl_teams$L                     #raw win loss ratio
wl_teams$adj_wlratio <- log10(wl_teams[,5]*wl_teams[,6])        #normalized win loss ratio


#analysis
wl_teams[which.max(wl_teams[,2]),c(1,2)] #team with the most wins
wl_teams[which.max(wl_teams[,3]),c(1,3)] #team with the most losses
wl_teams[which.max(wl_teams[,7]),c(1,6)] #team with the best w/l ratio
wl_teams[which.min(wl_teams[,7]),c(1,6)] #team with the worst w/l ratio
printStats(wl_teams$wlratio)             #descriptive stats of w/lratio
printStats(wl_pl$adj_wlratio)            #descriptive stats of adj. w/l ratio


#visualizations
ggplot(wl_teams, aes(x=wlratio)) + geom_histogram(bins=50, color="black", fill="white")   #histogram of win loss ratio
ggplot(wl_teams, aes(x=adj_wlratio)) + geom_histogram(color="black", fill ="white")       #histogram of adj. win loss ratio
ggplot(wl_teams, aes(W,L)) + geom_point()                                                 #scatterplot of wins/losses


#justin verlander wins by year
ggplot(sqldf('select wl_pitching.yearID, sum(wl_pitching.W) as "W" from wl_pitching where
wl_pitching.playerName = "Justin Verlander" group by wl_pitching.yearID'), aes(yearID, W)) + geom_col()


#new york yankees wins by year
ggplot(sqldf('select wl_pitching.yearID, sum(wl_pitching.W) as "W" from wl_pitching where
wl_pitching.teamName = "New York Yankees" group by wl_pitching.yearID'), aes(yearID, W)) + geom_col()