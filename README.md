# WhaleMap
Collate and display whale survey results

## Overview
The goal of this software is to rapidly and effectively collect and share whale survey information within and between research, government, industry, and public sectors. Our hope is that it will improve survey efficiency, increase public awareness, and inform impactful, transparent management decisions. It is in active development, so please report any problems or suggestions via this site's issue page. Follow the links below for more information and a live demonstration.

## Demonstration

See the homepage with summary map here:
https://whalemap.ocean.dal.ca/  

And see the Shiny App interactive map page here:
https://whalemap.ocean.dal.ca/WhaleMap/

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
global.R        Shiny app
server.R        Shiny app
ui.R            Shiny app
```

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