# EMF FUTURES ##################################################################

## Installing and loading packages =============================================
# install.packages("urca")
# install.packages("egcm")
# install.packages("EnvStats")
# install.packages("tidyverse")

# install.packages("pacman")
pacman::p_load(pacman,
               dplyr,
               tidyr,
               stringr,
               lubridate,
               httr,
               ggvis,
               ggplot2,
               shiny,
               rio,
               rmarkdown,
               tibble
               )

## Setting working directory ===================================================
getwd()
setwd("C:/Users/juanf/OneDrive/GitRepos/emf_futures/data")

## Importing data ==============================================================
# rm(list = ls())
dat <- as_tibble(read.csv("MainData01_CSV.csv"))
# dat <- read.csv("MainData01_CSV.csv")
# names(dat)
# head(dat, n = 5)
# attach(dat)

## Data cleaning and sorting ===================================================
dat$Dates <- as.Date(dat$Dates, "%m/%d/%Y")           # Convert char into dates
dat <- dat[order(dat$Dates, decreasing = FALSE),]     # Sort by column(s)

## Creating key variables ======================================================

# Calculating lagged values
dat$FMEMAdjPriceLag1 <- lag(dat$FMEMAdjPrice)
dat$EMFAdjPriceLag1 <- lag(dat$EMFAdjPrice)
dat$VWOAdjPriceLag1 <- lag(dat$VWOAdjPrice)
dat$FTSEPriceLag1 <- lag(dat$FTSEPrice)

# Calculating returns - daily
dat$emf_dret <- (dat$EMFAdjPrice / dat$EMFAdjPriceLag1) - 1
dat$fmem_dret <- (dat$FMEMAdjPrice / dat$FMEMAdjPriceLag1) - 1
dat$vwo_dret <- (dat$VWOAdjPrice / dat$VWOAdjPriceLag1) - 1
dat$ftse_dret <- (dat$FTSEPrice / dat$FTSEPriceLag1) - 1

# Subsetting data to keep relevant variables
keepvars <- c("emf_dret",
              "fmem_dret",
              "vwo_dret",
              "ftse_dret"
              )
dat2 <- dat[keepvars]

# Summary statistics of key variables ==========================================
head(dat2)
summary(dat2)
plot(dat2)

## Calculating the Hedge Ratio =================================================
hedge.ratio <- function(xvar, yvar) {
  cov(xvar,
      yvar,
      use="pairwise.complete.obs"
      ) / var(xvar, na.rm=TRUE)
}

hr_emf_vwo <- hedge.ratio(dat2$emf_dret, dat2$vwo_dret)
hr_emf_ftse <- hedge.ratio(dat2$emf_dret, dat2$ftse_dret)
hr_fmem_vwo <- hedge.ratio(dat2$fmem_dret, dat2$vwo_dret)
hr_fmem_ftse <- hedge.ratio(dat2$fmem_dret, dat2$ftse_dret)
hr_vwo_ftse <- hedge.ratio(dat2$vwo_dret, dat2$ftse_dret)

# Calculating the hedging effectiveness ========================================
he_emf_vwo <- 1 - ((var(dat2$vwo_dret, na.rm=TRUE) +
                    hr_emf_vwo ^ 2 *
                    var(dat2$emf_dret, na.rm=TRUE) - 
                    2 * hr_emf_vwo * 
                    cov(dat2$emf_dret,
                        dat2$vwo_dret,
                        use="pairwise.complete.obs")) 
                   / var(dat2$vwo_dret, na.rm=TRUE))
