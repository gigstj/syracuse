###############################################################
# Predict team win in the Division by pitching data in Teams table
###############################################################
library(Lahman)
View(Teams)

#yearID         Year
#G              Games played
#W              Wins
#DivWin         Division Winner (Y or N)
#ER             Earned runs allowed
#ERA            Earned run average
#SHO            Shutouts
#SV             Saves
#IPOuts         Outs Pitched (innings pitched x 3)
#HA             Hits allowed
#HRA            Homeruns allowed
#BBA            Walks allowed
#SOA            Strikeouts by pitchers

#select pitching data from  Teams table from 1901 to 2018
a <- subset(Teams, yearID > 1900 & yearID < 2019, select = c(yearID, DivWin, G, ER, ERA, SHO, SV, IPouts, HA, HRA, BBA, SOA))
colnames(a) <- c("yearID", "DivWin", "G", "ER", "ERA", "SHO", "SV", "IPouts", "HA", "HRA", "BBA", "SOA")
a <- na.omit(a)  # remove NA
rownames(a) <- NULL   # reset row names

b <- subset(a, select=c(G, ER, ERA, SHO, SV, IPouts, HA, HRA, BBA, SOA))
cor(b)  #correlation test 

train <- subset(a, !(yearID < 2019 & yearID > 1995))  #training data
test <- subset(a, yearID < 2019 & yearID > 1995)     #test data

#install.packages("nnet")
library(nnet)
train$ID_a = class.ind(train$DivWin)  # make DivWin=Y to 0 , No to 1
test$ID_b = class.ind(test$DivWin)    # make DivWin=Y to 0 , No to 1

#model1 = nnet(ID_a ~ ER+ERA+SHO+SV+IPouts+HA+HRA+BBA+SOA, train, size=3, rang=0.01, decay=5e-4, maxit=2000, softmax=T)
#model1

model2 = nnet(ID_a ~ ERA+HA+BBA+SOA, train, size=3, rang=0.01, decay=5e-4, maxit=2000, softmax=T)
summary(model2)
#rm(c)
c <- table(data.frame(predicted=predict(model2, test)[,2]>0.5, actual=test$ID_b[,2]>0.5))
c

#          actual
#predicted FALSE TRUE
#    FALSE   539  120
#    TRUE      9   18

accuracy <- (c[1,1]+c[2,2])/(c[1,1]+c[1,2]+c[2,1]+c[2,2]) # about 81% accuracy
sensitivity <- (c[1,1])/(c[1,1]+c[2,1]) # about 98% sensitivity
specificity <- (c[2,2])/(c[1,2]+c[2,2]) # about 13% specificity


install.packages("neuralnet")
library(neuralnet)
a$win=a$DivWin=="Y"            # save Division Win:Y to win 
a$not_win=a$DivWin=="N"        # save Division Win:N to not_win 
d <- neuralnet(win+not_win ~ ERA+HA+BBA+SOA, a, hidden=4, stepmax=1e6)
d$result.matrix
plot(d)



