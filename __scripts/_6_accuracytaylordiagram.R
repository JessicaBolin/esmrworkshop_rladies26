# Step 6: Taylor diagram
# Calculate the accuracy/skill of tos ESMS - average hist 1994-2014
# Author/s: Jessica Bolin
# Created: December 2024
# Updated: Feb 2026
# macOS: OK
# Windows: TBD

# Dependencies ------------------------------------------------------------
source(paste0(getwd(), "/__scripts/helpers.R"))

library(terra)
library(plotrix) #taylor.diagram()
library(tidyverse)

# Rasters of OISST climatology, and the historical means for both ESMs
oisst <- rast(paste0(pth, bc_pth, "/_2_OISST_climatology.nc"))
access_bc <- rast(paste0(pth, bc_pth, bc_pth_bc, "/tos_mo_ACCESS-CM2_1995-2014_bc_historical_remapped.nc"))
ipsl_bc <- rast(paste0(pth, bc_pth, bc_pth_bc, "/tos_mo_IPSL-CM6A-LR_1995-2014_bc_historical_remapped.nc"))
access_raw <- rast(paste0(pth, cmip_pth_proc, "/tos_Omon_ACCESS-CM2_historical_r1i1p1f1_gn_185001-201412.nc"))
access_raw <- access_raw[[time(access_raw) > "1995-01-01"]]
ipsl_raw <- rast(paste0(pth, cmip_pth_proc, "/tos_Omon_IPSL-CM6A-LR_historical_r1i1p1f1_gn_185001-201412.nc"))
ipsl_raw <- ipsl_raw[[time(ipsl_raw) > "1995-01-01"]]


# 6.2 Convert rasters to dataframes -------------------------------------------

# Calculate mean of each field (i.e., baseline/climatology)
oisst_df <- oisst %>% mean %>% as.data.frame(xy = T)
access_df <- access_raw %>% mean %>% as.data.frame(xy = T)
access_bc_df <- access_bc %>% mean %>% as.data.frame(xy = T)
ipsl_df <- ipsl_raw %>% mean %>% as.data.frame(xy = T)
ipsl_bc_df <- ipsl_bc %>% mean %>% as.data.frame(xy = T)


# Merge and fix names -----------------------------------------------------

alldata <- inner_join(oisst_df, access_df, by = c("x","y")) 
names(alldata) <- c("x", "y", "oisst_mean", "access_mean")
alldata <- inner_join(alldata, access_bc_df, by = c("x","y"))
names(alldata) <- c("x", "y", "oisst_mean", "access_mean", "access_bc_mean")

alldata2 <- inner_join(oisst_df, ipsl_df, by = c("x","y")) 
names(alldata2) <- c("x", "y", "oisst_mean", "ipsl_mean")
alldata2 <- inner_join(alldata2, ipsl_bc_df, by = c("x","y"))
names(alldata2) <- c("x", "y", "oisst_mean", "ipsl_mean", "ipsl_bc_mean")

alldata <- inner_join(alldata, alldata2)

alldata <- alldata %>% #ensemble mean
  mutate(ens_bc_mean = (access_bc_mean + ipsl_bc_mean) / 2)

head(alldata)

# 6.3 Taylor Diagram ----------------------------------------------------------

# Base diagram
taylor.diagram(alldata$oisst_mean, 
               alldata$oisst_mean, 
               ref.sd = T, #display arc of ref. std. dev. (i.e., 1)
               normalize=TRUE, #normalize models so ref has SD of 1
               sd.arcs=TRUE,  #display arcs along SD axes
               pcex = 4,
               pch = 19,
               col = "red",
               xlab = "Standard deviation (normalised)",
               pos.cor = T, #show correlation (y-axis) from 0-1 
               gamma.col = "blue", #RMSE arcs
               main="OISST vs. CMIP6 ESM tos (SST) 1995-2014")

taylor.diagram(alldata$oisst_mean,
               alldata$access_mean,
               add=TRUE, normalize=TRUE,  
               pcex=3, pch=17, col= "purple")

taylor.diagram(alldata$oisst_mean,
               alldata$ipsl_mean,
               add=TRUE, normalize=TRUE,  
               pcex=3, pch=17, col= "forestgreen")

taylor.diagram(alldata$oisst_mean,
               alldata$access_bc_mean,
               add=TRUE, normalize=TRUE,  
               pcex=2, pch=17, col= "black")

taylor.diagram(alldata$oisst_mean,
               alldata$ipsl_bc_mean,
               add=TRUE, normalize=TRUE,  
               pcex=2, pch=17, col= "black")


# Legend ------------------------------------------------------------------

legend(1.2, 1.7, cex=1, pt.cex=2, pch=17,
       legend=c("ACCESS-CM2", "IPSL-CM6A-LR"),
       col=c("purple", "forestgreen"), 
       bty = "n")

legend(1.2, 1.54, cex=1, pt.cex=2, pch=19,
       legend=c("OISST"),
       col= 'red', 
       bty = "n")

legend(1.2, 1.45, cex=1, pt.cex=2, pch=17,
       legend=c("Bias-corrected ESMs"),
       col= 'black', 
       bty = "n")

