# 7: Making Projections: Time series for each SSP 
# UC Davis/BML ESM R workshop 2025 
# Author/s: Jessica Bolin
# Created: December 2024
# Updated: March 2025
# macOS: OK
# Windows: TBD

# 7.1.1 Dependencies ------------------------------------------------------------

source(paste0(getwd(), "/__scripts/helpers.R"))
models = c("ACCESS-CM2|IPSL-CM6A-LR")
models2 = c("ACCESS-CM2", "IPSL-CM6A-LR")
indir_proj <- paste0(pth, bc_pth, bc_pth_bc)
outdir <- ts_pth


# 7.1.1 Projections -------------------------------------------------------------

timeseries_ssp <- function(ssp) {
  
  allfiles_proj <- list.files(indir_proj, pattern = models, full.names = T)
  allfiles_proj2 <- allfiles_proj[grep(ssp, allfiles_proj)]
  rr <- rast(allfiles_proj2)
  rr <- rr[[time(rr) < "2100-12-31"]]
  dateys <- time(rr) %>% unique
  years <- lubridate::year(dateys) %>% unique
  
  emplist <- list()
  emplist_allmodels <- list()
  
  # ensemble mean 
  for (i in 1:length(years)) {
    
    alldates <- dateys[grep(years[i], dateys)]
    rasty <- rr[[time(rr) == alldates]]
    meanrast <- mean(rasty) 
    meanval <- values(meanrast) %>% mean(na.rm=T)
    forlist <- data.frame(date = years[i], value = meanval)
    emplist[[i]] <- forlist
    print(paste0("ens_", years[i]))
  }
  
  
  # individual models
  for (j in 1:length(models2)) {
    emplist_indmodel <- list()
    
    
    for (h in 1:(length(years)-1)) {
      modelrast <- rast(allfiles_proj2[grep(models2[j], allfiles_proj2)])
      
      dateys <- time(modelrast) %>% unique
      alldates <- dateys[grep(years[h], dateys)]
      modelrast <- modelrast[[time(modelrast) == alldates]]
      meanrast <- mean(modelrast) 
      meanval <- values(meanrast) %>% mean(na.rm=T)
      forlist <- data.frame(model = models2[j], date = years[h], value = meanval)
      emplist_indmodel[[h]] <- forlist
    }
    
    toadd <- do.call(rbind, emplist_indmodel)
    emplist_allmodels[[j]] <- toadd
    print(models2[j])
  }
  
  saveRDS(emplist, 
          paste0(ts_pth, "/sst_year_proj_ens_",
                 ssp, ".RDS"))
  saveRDS(emplist_allmodels,
          paste0(ts_pth, "/sst_year_proj_ind_",
                 ssp, ".RDS"))
}

ssps <- c("ssp245", "ssp585")
tic(); future_walk(ssps, timeseries_ssp); toc() #26 seconds for both

# For loop version
#tic(); timeseries_ssp("ssp245"); toc() #Jessie: 16.32 seconds
#timeseries_ssp("ssp585")


# 7.1.2 Bind everything and 11 yr mean and plot -----------------------------------------

smooth_esms <- function(ssp, window_size) {
  
  #ensembled 
  timeseries_proj_ens <- readRDS(paste0(ts_pth, "/sst_year_proj_ens_", ssp, ".RDS"))
  
  timeseries_proj_ens <- do.call(rbind, timeseries_proj_ens)
  alltimeseries_ensm <- timeseries_proj_ens
  
  ens <- alltimeseries_ensm
  zoo_data <- zoo(ens$value, order.by = ens$date)
  smoothed_esm <- rollapply(zoo_data, width = window_size, 
                            FUN = mean, align = "center", fill = "extend")
  smooth_11_esm <- data.frame(date = time(smoothed_esm), 
                              values = coredata(smoothed_esm))
  smooth_esm <- smooth_11_esm
  assign(paste0("smooth_esm_", ssp), 
         smooth_esm, 
         envir = globalenv())
  
  # Individual 
  
  timeseries_proj <- readRDS(paste0(ts_pth, "/sst_year_proj_ind_", ssp, ".RDS"))
  timeseries_allmodels <- do.call(rbind, timeseries_proj)
  allmodels <- timeseries_allmodels
  emplist <- list()
  ens2 <- allmodels
  
  for (i in 1:length(unique(allmodels$model))) {
    ens <- subset(ens2, model == unique(ens2$model)[i])
    zoo_data <- zoo(ens$value, order.by = ens$date)
    smoothed_esm <- rollapply(zoo_data, width = window_size, 
                              FUN = mean, align = "center", fill = "extend")
    smooth_11_esm <- data.frame(date = time(smoothed_esm), 
                                values = coredata(smoothed_esm))
    smooth_11_esm$model <- unique(ens$model)
    emplist[[i]] <- smooth_11_esm
  }
  
  ssp_smoothed_ind <- do.call(rbind, emplist)
  assign(paste0("ssp_smoothed_ind_", ssp), 
         ssp_smoothed_ind, 
         envir = globalenv())
  
}

tic(); smooth_esms("ssp245", window_size = 5); toc() #Jessie: 0.003 seconds
smooth_esms("ssp585", window_size = 5)

ssp_smoothed_ind_ssp245
ssp_smoothed_ind_ssp585
smooth_esm_ssp245
smooth_esm_ssp585


# 7.1.3 Plot --------------------------------------------------------------

plot_ts <- function(ssp, sspletter) {
  
  smooth_esm <- get(paste0("smooth_esm_", ssp)) #relies on this already being in your env
  ssp_smoothed_ind <- get(paste0("ssp_smoothed_ind_", ssp))
  
  # Make a kick-ass plot
  p1 <- ggplot() +
    geom_line(smooth_esm, 
              mapping = aes(x = date, y = values), 
              lwd = 1.5) +
    geom_rect(data = data.frame(), 
              mapping = aes(xmin = 2020, xmax = 2040, ymin = -Inf, ymax = Inf),
              fill = "grey",
              alpha = 0.4) +
    geom_rect(data = data.frame(), 
              mapping = aes(xmin = 2080, xmax = 2100, ymin = -Inf, ymax = Inf),
              fill = "grey", 
              alpha = 0.4) + 
    geom_line(smooth_esm, 
              mapping = aes(x = date, y = values), 
              lwd = 1.5) +
    geom_line(subset(ssp_smoothed_ind, model == "ACCESS-CM2"), 
              mapping = aes(x = date, y = values), 
              col = "black", 
              alpha = 0.3) +
    geom_line(subset(ssp_smoothed_ind, model == "IPSL-CM6A-LR"), 
              mapping = aes(x = date, y = values), 
              col = "black", 
              alpha = 0.3) +
    theme_bw() + 
    scale_x_continuous(name = "Year", 
                       n.breaks = 6) +
    scale_y_continuous(name = "SST (˚C)", 
                       limits = c(13.5, 20.5)) +
    theme(panel.grid.minor = element_blank(),
          plot.margin=unit(c(1,0.1,.1,0.1),"cm"),
          axis.title = element_text(size = 20, 
                                    family = "Arial Narrow",
                                    face = "bold"),
          axis.text = element_text(size = 20, 
                                   family = "Arial Narrow"),
          axis.title.x = element_text(margin = margin(t = 10, r = -20))) +
    annotate("text", x = 2019, y = 20.1,
             label = sspletter, 
             size = 9, 
             fontface = "bold", 
             family = "Arial Narrow", 
             hjust = 0, 
             vjust = 1) +
    annotate("text", x = 2083, y = 13.7,
             label = "Long-term", size = 5, 
             family = "Arial Narrow", 
             hjust = 0, 
             vjust = 1) + 
    annotate("text", x = 2043, y = 13.7,
             label = "Mid-term", size = 5, 
             family = "Arial Narrow", 
             hjust = 0, 
             vjust = 1) +
    annotate("text", x = 2023, y = 13.7,
             label = "Short-term", size = 5, 
             family = "Arial Narrow", 
             hjust = 0, 
             vjust = 1)
  
  ggsave(p1,
         filename = paste0(outdir, "/",
                           ssp, "_SST_timeseries_1995-2100_11yrsmooth.png"),
         width = 8, height = 5)
  
}

tic(); plot_ts("ssp245", sspletter = "SSP2-4.5"); toc() #Jessie: 0.197 seconds

plot_ts("ssp585", sspletter = "SSP5-8.5")



