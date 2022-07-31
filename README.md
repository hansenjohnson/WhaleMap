# WhaleMap
Collate and display whale survey results

[![DOI](https://joss.theoj.org/papers/10.21105/joss.03094/status.svg)](https://doi.org/10.21105/joss.03094)

## Overview

The goal of this software is to rapidly and effectively collect and share whale survey information within and between research, government, industry, and public sectors. Our hope is that it will improve survey efficiency, increase public awareness, and inform impactful, transparent management decisions. The system is live at [whalemap.org](https://whalemap.org/), and the interactive map is available [here](https://whalemap.org/WhaleMap). Check out the [WhaleMap publication in JOSS](https://doi.org/10.21105/joss.03094) for a general description of the system, or continue reading for more detailed information. Please report any problems or suggestions via this site's issue page. 

## Project structure

```
data/           All WhaleMap data (NOT tracked via git)
    raw/        Raw data cloned directly from data contributors (NEVER manually edited)
    interim/    Data from each platform coeherced to WhaleMap format
    processed/  Processed data used for display
R/              R scripts for data processing, display, and reporting
src/            Shell scripts to execute data cloning and processing
Makefile        Maps project dependency structure and facilitates efficient processing with `make`
LICENSE         License information
global.R        Shiny app - defining global variables
server.R        Shiny app - processing data for shiny app
ui.R            Shiny app - defining the user interface
```

## Data processing

### Workflow

1. Sync

The majority of the remote data are synced using the script `src/get_remote_data.sh`. This uses Rclone to sync data from remote repositories (Google Drive, Dropbox, etc.), and also calls `R/get_dcs.R` to download acoustic detection data. All the data are stored in `data/raw/`

2. Process 

Data from each contributor are processed to a common WhaleMap format (see below) using a custom R script (`R/proc_*.R`). Once formatted, observations and effort data from each platform are saved in `data/interim/`.

3. Combine 

All effort and observation data files in `data/interim/` are combined by (`R/combine.R`) and saved as `data/processed/effort.rds` and `data/processed/observations.rds`, respectively.

4. Repeat

A Makefile maps the dependency structure and orchestrates the efficient processing of the entire dataset. The `make` command is executed at the final step of `src/get_remote_data.sh` to update the dataset after synchronization. A cron job runs `src/get_remote_data.sh` every 15 minutes to keep the system up to date.

### WhaleMap data formats

#### Observations

`time` - UTC time (YYYY-MM-DD HH:MM:SS)  
`lat` - latitude in decimal degrees  
`lon` - longitude in decimal degrees  
`date` - UTC date (YYYY-MM-DD)  
`yday` - day of year  
`year` - year (YYYY)  
`platform` - type of survey platform (`vessel`, `plane`, `slocum`, `buoy`, `rpas`, `opportunistic`)  
`name` - name of platform (e.g., `noaa_twin_otter`, `dfo_coriolis`)  
`id` - unique survey identifier comprised of survey start date, platform, and name (e.g., `2020-02-21_plane_noaa_twin_otter`)  
`species` - species name (`right`, `fin`, `sei`, `humpback`, `blue`)  
`score` - detection type and score (`Definite acoustic`, `Possible acoustic`, `Definite visual`, `Possible visual`)  
`number` - number of whales (`NA` for acoustic detections)  
`calves` - number of calves (`NA` for acoustic detections)  
`source` - data source (`WhaleMap`, `RWSAS`, `WhaleInsight`, `NARWC`)  

#### Tracks

`time` - UTC time (YYYY-MM-DD HH:MM:SS)  
`lat` - latitude in decimal degrees  
`lon` - longitude in decimal degrees  
`date` - UTC date (YYYY-MM-DD)  
`yday` - day of year  
`year` - year (YYYY)  
`platform` - type of survey platform (`vessel`, `plane`, `slocum`, `buoy`, `rpas`, `opportunistic`)  
`name` - name of platform (e.g., `noaa_twin_otter`, `dfo_coriolis`)  
`id` - unique survey identifier comprised of survey start date, platform, and name (e.g., `2020-02-21_plane_noaa_twin_otter`)  
`speed` - platform speed (m/s)  
`altitude` - platform altitude (m)  
`source` - data source (`WhaleMap`, `RWSAS`, `WhaleInsight`, `NARWC`)  

#### Status table

`script` - name of the platform processing script (e.g., `proc_2021_noaa_twin_otter.R`)  
`name` - name of the platform to be displayed in the status table (e.g., `NOAA NEFSC survey sightings/tracks`)  
`url` - link url to be displayed in status table  
`email_list` - path to csv file with list of emails to be notified if there is an error processing platform data  
 
### Reporting

Error catching is performed in the `Makefile` using the scripts `src/report_error.sh` and `src/remove_error.sh`. These are run each time a platform-specific processing script is run. The results of the processing are recorded in the status table (`status.txt`). If processing is successful, a timestamp is added in the status table. If processing is unsuccessful, an error message is printed in the status table and an auto-generated email is sent to a designated email list associated with that platform (using `src/send_email_alert.sh`). The status table is displayed in the Shiny app.

### Adding a new platform

1. Update `src/get_remote_data.sh` to sync raw data  
2. Write R script to convert to WhaleMap format and save observations and tracks in `data/interim.`  
3. Update `Makefile`  
4. Update `status.txt`  
5. Test (run `make` and view results in Shiny app)  
6. Push changes to WhaleMap server via GitHub  

## Setup

### R

Here is a list of the packages that WhaleMap relies on:
- Data wrangling: `tidyverse`, `lubridate`, `tools`, `oce`   
- Mapping: `rgdal`, `maptools`, `leaflet`, `leaflet.extras`, `sf`   
- Shiny: `shiny`, `shinydashboard`, `shinybusy`   
- Misc: `htmltools`, `htmlwidgets`, `plotly`, `RColorBrewer`

Here's the output from `sessionInfo()`:
```
> sessionInfo()
R version 3.4.4 (2018-03-15)
Platform: x86_64-pc-linux-gnu (64-bit)
Running under: Ubuntu 16.04.6 LTS

Matrix products: default
BLAS: /usr/lib/libblas/libblas.so.3.6.0
LAPACK: /usr/lib/lapack/liblapack.so.3.6.0

locale:
 [1] LC_CTYPE=en_CA.UTF-8       LC_NUMERIC=C              
 [3] LC_TIME=en_CA.UTF-8        LC_COLLATE=en_CA.UTF-8    
 [5] LC_MONETARY=en_CA.UTF-8    LC_MESSAGES=en_CA.UTF-8   
 [7] LC_PAPER=en_CA.UTF-8       LC_NAME=C                 
 [9] LC_ADDRESS=C               LC_TELEPHONE=C            
[11] LC_MEASUREMENT=en_CA.UTF-8 LC_IDENTIFICATION=C       

attached base packages:
[1] tools     stats     graphics  grDevices utils     datasets  methods  
[8] base     

other attached packages:
 [1] rgeos_0.3-26         RColorBrewer_1.1-2   forcats_0.4.0       
 [4] stringr_1.3.1        dplyr_0.8.0.1        purrr_0.3.0         
 [7] readr_1.1.1          tidyr_0.8.2          tibble_2.0.1        
[10] tidyverse_1.2.1      sf_0.7-3             shinybusy_0.1.2     
[13] leaflet.extras_1.0.0 plotly_4.8.0         ggplot2_3.1.0       
[16] shinydashboard_0.7.0 oce_0.9-23           gsw_1.0-5           
[19] testthat_2.0.0       lubridate_1.7.4      maptools_0.9-2      
[22] htmlwidgets_1.3      htmltools_0.3.6      rgdal_1.2-18        
[25] sp_1.3-1             leaflet_2.0.1        shiny_1.2.0  
```

### Linux / tools

Here's a list of other tools that WhaleMap relies on and the current version:
- make (GNU Make 4.1)
- rclone (rclone v1.38)
- git (git version 2.7.4)
- pandoc (pandoc 1.16.0.2)
- shiny-verser (Shiny Server v1.5.7.907)