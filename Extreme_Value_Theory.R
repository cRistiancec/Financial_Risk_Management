# Applying Extreme Value Theory to Amazon.com Inc. Stock Data
library(evd)
library(evir)
library(fExtremes)

# Adjusted Close values for the period of 01/05/2009 �C 10/05/2018 were downloaded from Yahoo Finance, denoted Si
# Negative log returns were calculated as: ��Xi = ln (Si/Si+1)

stock = read.csv("AMZN.csv", header = TRUE)
ac = stock$Adj.Close
X = log(((ac[1:(length(ac)-1)]))/(ac[2:length(ac)]))
size = length(X)

# Block maximum based method
# With n = 22, we obtain the following n-block sequence histogram for {Mn,1, Mn,2, �� }
n = 22
start.ind = 1+size-n*floor(size/n)
X.trim = X[start.ind:size] #truncate list so that is integer multiple of n
m = (length(X.trim))/n #get number of full blocks

block.max = rep(0,m) #vector of block maxima
for(i in 0:(m-1)){
  block.max[i + 1] = X.trim[n*i + 1]
  for(j in 1:(n-1)){
    if(X.trim[n*i + j + 1] > block.max[i + 1]){
      block.max[i + 1] = X.trim[n*i + j + 1]
    }
  }
}

hist(block.max,
     main = paste("Maximum across ", n, "-block sequences", sep = ""),
     xlab = "Maximum NL-return in block",
     col = "gold")

# Fitting to GED
# Fitting the block maxima to the Generalized Extreme Distribution
fit.ged = fgev(block.max)
ged.mu = fit.ged$estimate[[1]]
ged.theta = fit.ged$estimate[[2]]
ged.xi = fit.ged$estimate[[3]]

# Goodness of Fit Analysis - GED
pts = ppoints(length(block.max))
plot(qgev(pts, ged.xi, ged.mu, ged.theta),
     quantile(block.max, p = pts),
     main = paste("GED QQ Plot, n=", n, sep = ""),
     xlab = "Theoretical Quantiles",
     ylab = "Data Quantiles")
abline(0,1, col = "red")

# We conclude that the GED goodness of fit is quite strong for n = 22


# Threshold exceedance based method

# Fitting the GPD
# Fitting the Generalized Pareto Distribution with u = 0.01
meplot(X, main = "Sample Mean Excess Plot")
abline(v = 0.01, col = "red")
#Choose u = 0.01
u = 0.01

fit.gpd = gpdFit(X, u = 0.01, type = "mle")
gpd.xi = 0.10578144 #from fit.gpd
gpd.theta = 0.01161951 #from fit.gpd

# GPD VaR0.99(X) and CVaR0.99(X)
survU = length(X[X >= u])/size #estimate of S(u)
VaR99.gpd = u + (gpd.theta/gpd.xi)*(((1-0.99)/survU) ^ (-gpd.xi)-1)
CVaR99.gpd = (VaR99.gpd+gpd.theta-u*gpd.xi) / (1-gpd.xi)

# We estimate F(u) as:(#observations >= 0.01) / total observations= 0.2151899
# We then use the formulas to obtain estimates for VaR and CVaR under GPD: 
# VaR0.99(X) to be 0.05212839
# We estimate CVaR0.99(X) to be 0.070106


# Hill's Method 
# Hill Plot for X:
hillPlot(X)

# Based on the Hill Plot, we choose k = 190
# Using the formula from the slides, we obtain a Hill Estimator of 2.826003
k = 100
abline(v = k, col = "gold")

# Choose k = 190
X = sort(X)
hill.low = size - k + 1
hill.vals = X[hill.low:size]
hill.est = ((sum(log(hill.vals)))/k - log(X[hill.low]))^(-1)
abline(h = hill.est, col = "gold")

# VaR0.99(X) and CVaR0.99(X) Under Hill
VaR99.hill = (size*0.01/k)^(-1/hill.est)*X[hill.low]
CVaR99.hill = mean(X[X >= VaR99.hill])

# Again, using the formula from the slides, VaR0.99(X) can be estimated to be 0.05012537
# Using CVaR = E(X|X >= VaR), CVaR0.99(X) can be estimated to be 0.07380687

# ****************************************************************************

# summary
tail = X[X > X[floor(0.97*size)]]
plot(tail,
     xaxt = 'n',
     xlab = "Largest 3% of Negative Log Returns",
     ylab = "Negative Log Return")
title(expression("VaR and CVaR under " * phantom("GPD") * " and " * phantom("Hill")), col.main = "black")
title(expression(phantom("VaR and CVaR under ") * "GPD" * phantom(" and Hill")), col.main = "red")
title(expression(phantom("VaR and CVaR under GPD and ") * "Hill"), col.main = "blue")
abline(h = VaR99.gpd, col = "red", lwd = 3)
abline(h = VaR99.hill, col = "blue", lwd = 3)
abline(h = CVaR99.gpd, col = "red", lwd = 3)
abline(h = CVaR99.hill, col = "blue", lwd = 3)