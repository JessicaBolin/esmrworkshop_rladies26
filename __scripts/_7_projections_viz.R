# Step 7: Projections for two time periods
# 2020-2040; 2080-2100
# UC Davis/BML ESM R workshop 2025 
# Author/s: Jessica Bolin
# Created: December 2024
# Updated: March 2025
# macOS: OK
# Windows: TBD


# Dependencies ------------------------------------------------------------

source(paste0(getwd(), "/__scripts/helpers.R"))

# 7.2.1 Ensemble for each model -------------------------------------------------

models = c("ACCESS-CM2", "IPSL-CM6A-LR")
ssps = c("ssp245", "ssp585")
term = c("near", "long")
outdir = paste0(pth, proj_pth)
indir_proj <- paste0(pth, bc_pth, bc_pth_bc)

termdf <- data.frame(timeperiod = c("near", "long"),
                     st = c("2020-01-01", "2080-01-01"),
                     fin = c("2040-01-01", "2100-01-01"))

tic(); for (k in term) {
  for (i in ssps) {
    for (j in models) {
      
      allfiles_proj <- list.files(indir_proj, pattern = j, full.names = T)
      allfiles_proj <- allfiles_proj[grep(i, allfiles_proj)]
      allfiles_proj <- allfiles_proj[grep("2100", allfiles_proj)]
      rr <- rast(allfiles_proj)
      
      # subset to time period
      tp <- subset(termdf, timeperiod == k)
      rr <- rr[[time(rr) > tp[,"st"] & time(rr) < tp[,"fin"] ]]
      
      # Mean and SD
      proj_u <- mean(rr)
      proj_sd <- stdev(rr)
      # write to outdir
      filename_u <- paste0(outdir, "/ind/mean_", j, "_", i, "_", k, "_", "proj.nc" )
      filename_sd <- paste0(outdir, "/ind/sd_", j, "_", i, "_", k, "_", "proj.nc" )
      terra::writeCDF(proj_u, filename_u, overwrite = T)
      terra::writeCDF(proj_sd, filename_sd, overwrite = T)
    }
  }
}; toc() #Jessie: 1.8 seconds

list.files(paste0(pth, "/__data/projections/ind"))


# 7.2.2 Actual ensemble ---------------------------------------------------------

tic(); for (k in term) {
  for (i in ssps) {
    
      
      allfiles_proj <- list.files(paste0(pth, "/__data/projections/ind"), 
                                  pattern = i, full.names = T)
      allfiles_proj <- allfiles_proj[grep(k, allfiles_proj)]
      allfiles_proj <- allfiles_proj[grep("mean", allfiles_proj)]
      rr <- rast(allfiles_proj)
      
      # Mean and SD
      proj_u <- mean(rr)
      proj_sd <- stdev(rr)
    
      # write to outdir
      filename_u <- paste0(outdir, "/ens/mean_ens_", i, "_", k, "_", "proj.nc" )
      filename_sd <- paste0(outdir, "/ens/sd_ens_", i, "_", k, "_", "proj.nc" )
      terra::writeCDF(proj_u, filename_u, overwrite = T)
      terra::writeCDF(proj_sd, filename_sd, overwrite = T)
      
  }
}; toc() #Jessie: 0.3 seconds

list.files(paste0(pth, "/__data/projections/ens"))


# 7.2.3 Delta difference --------------------------------------------------------

# Delta difference
outdir = paste0(pth, proj_pth, "/delta") 

# Historical --------------------------------------------------------------

#Ensemble average of 1995-2014 for both models
full_pth <- paste0(pth, bc_pth, bc_pth_bc, "/")
r1 <- rast(paste0(full_pth, "tos_mo_ACCESS-CM2_1995-2014_bc_historical_remapped.nc"))
r2 <- rast(paste0(full_pth, "tos_mo_IPSL-CM6A-LR_1995-2014_bc_historical_remapped.nc"))
rr <- c(r1, r2)
mean_hist <- mean(rr)
plot(mean_hist, main = "Ensembled SST 1995-2014"); maps::map("world", add = T)


# Delta projections -------------------------------------------------------

# Read in ensemble for all three terms SSP245

ssps = c("ssp245", "ssp585")
#i = "ssp585"
tic(); for (i in ssps) {
  
  near_mean <- rast(paste0(pth, "/__data/projections/ens/mean_ens_", i, "_near_proj.nc"))
  rr <- near_mean - mean_hist
  writeCDF(rr, paste0(outdir, "/delta_mean_ens_near_", i, ".nc"),
           overwrite = T)
  
  long_mean <- rast(paste0(pth, "/__data/projections/ens/mean_ens_", i, "_long_proj.nc"))
  rr <- long_mean - mean_hist
  writeCDF(rr, paste0(outdir, "/delta_mean_ens_long_", i, ".nc"),
           overwrite = T)
  
}; toc() #Jessie: 0.226 seconds

list.files(paste0(pth, "/__data/projections/delta"))


# 7.2.4 Plot ---------------------------------------------------------------------

# Visualise projections

# 3 columns
# Near, mid, long 

# 2 rows
# Projections
# Delta

# Repeat for each SSP
deltapth = paste0(pth, "/__data/projections/delta/")


# Long --------------------------------------------------------------------

par(mfrow=c(2,3))

r2 <- rast(paste0(pth, "/__data/projections/ens/mean_ens_ssp585_long_proj.nc"))
plot(r2, 
     main = "Mean - Long term SSP585",
     range = c(11,22)); maps::map("world", add = T, fill = T, col = "grey")
r3 <-  rast(paste0(pth, "/__data/projections/ens/sd_ens_ssp585_long_proj.nc"))
plot(r3, main = "Std Dev - Long term SSP585",
     col = viridis::magma(255),
     range = c(0,2)); maps::map("world", add = T, fill = T, col = "grey")
r1 <- rast(paste0(deltapth, "delta_mean_ens_long_ssp585.nc"))
plot(r1, main = "Delta SST - Long term SSP585",
     col = viridis::mako(255),
     range = c(0.5,4.5)); maps::map("world", add = T, fill = T, col = "grey")


# Near --------------------------------------------------------------------

r2 <- rast(paste0(pth, "/__data/projections/ens/mean_ens_ssp585_near_proj.nc"))
plot(r2, main = "Mean - Near term SSP585",
     col = viridis::viridis(255),
     range = c(11,22)); maps::map("world", add = T, fill = T, col = "grey")
r3 <-  rast(paste0(pth, "/__data/projections/ens/sd_ens_ssp585_near_proj.nc"))
plot(r3, main = "Std Dev Near term SSP585",
     col = viridis::magma(255),
     range = c(0,2)); maps::map("world", add = T, fill = T, col = "grey")
r1 <- rast(paste0(deltapth, "delta_mean_ens_near_ssp585.nc"))
plot(r1, main = "Delta SST - Near term SSP585",
     col = viridis::mako(255),
     range = c(0.5,4.5)); maps::map("world", add = T, fill = T, col = "grey")



# SSP245 ------------------------------------------------------------------


# Long --------------------------------------------------------------------

r2 <- rast(paste0(pth, "/__data/projections/ens/mean_ens_ssp245_long_proj.nc"))
plot(r2, main = "Mean - Long term SSP245",
     range = c(11,22)); maps::map("world", add = T, fill = T, col = "grey")
r3 <-  rast(paste0(pth, "/__data/projections/ens/sd_ens_ssp245_long_proj.nc"))
plot(r3, main = "Std Dev - Long term SSP245",
     col = viridis::magma(255),
     range = c(0,2)); maps::map("world", add = T, fill = T, col = "grey")
r1 <- rast(paste0(deltapth, "delta_mean_ens_long_ssp245.nc"))
plot(r1, main = "Delta SST - Long term SSP245",
     col = viridis::mako(255),
     range = c(0.5,4.5)); maps::map("world", add = T, fill = T, col = "grey")



# Near --------------------------------------------------------------------

r2 <- rast(paste0(pth, "/__data/projections/ens/mean_ens_ssp245_near_proj.nc"))
plot(r2, main = "Mean - Near term SSP245",
     col = viridis::viridis(255),
     range = c(11,22)); maps::map("world", add = T, fill = T, col = "grey")
r3 <-  rast(paste0(pth, "/__data/projections/ens/sd_ens_ssp245_near_proj.nc"))
plot(r3, main = "Std Dev- Near term SSP245",
     col = viridis::magma(255),
     range = c(0,2)); maps::map("world", add = T, fill = T, col = "grey")
r1 <- rast(paste0(deltapth, "delta_mean_ens_near_ssp245.nc"))
plot(r1, main = "Delta SST - Near term SSP245",
     col = viridis::mako(255),
     range = c(0.5,4.5)); maps::map("world", add = T, fill = T, col = "grey")

