# WhaleMap
Interactive map of all whale detections detections and sightings data (from 2014 through 2017) that the WHaLE project has access to.

## Overview
This app us intented to be used as a visual tool for exploring and gaining intuition about the data we have already collected on baleen whales in the Northwest Atlantic. It is particularly geared towards visualizing seasonal shifts over single and multiple years in an attempt to understand seasonal whale distribution and gaps in our knowledge. This app is for demonstration purposes only; it includes sensitive and raw data, and as such should not be distributed widely.

## Caveats
These data come from a variety of different sources, each with their own caveats. Here are some of the caveats and details regarding each dataset:

### DCS

* All near real-time detections from platforms (slocum and wave gliders and moored buoys) equipped with Mark Baumgartner's low frequency classification and detection system (LFDCS). This includes something like 21 deployments in the NW Atlantic since 2014, mostly of Slocum gliders.  
* These monitor for right, fin, sei, and humpback whales ONLY  
* The wave glider detections should be treated cautiously, as the probability of detection is lower due to platform noise  
* These include detections with a score of 'detected' and 'possibly detected'. The map allows you to choose which to display. Typically we expect that %50 of all 'possibly detected' scores are correct.  

### Plane

* This dataset include NOAA flights from 2015 and 2017. The 2015 data are 'complete' in that they have gone through some level of quality control and include multiple species (i.e. not just right whales). The 2017 data are much more raw and *only include right whales*.  
* I recommend turning the tracks off when viewing these data to improve map performance  

### Vessel

* The vessel data come from surveys on the Shelagh in the GSL in 2016 and 2017. Similar to the NOAA flight data, the 2016 data has gone through more QC and includes multiple species, whereas the 2017 data is raw and *only includes right whales*  
* Tracklines only reflect times when the vessel was 'on effort'. There may be cases where they logged a sighting while 'off effort. These *should* still display on the map but will not have an associated trackline.  

## To Do
* Roseway basin ATBA, and closure area in the GSL  
* Sonobuoys on map  
* NOAA effort from GOM  
* Fundy effort and tracklines from Kim  
* Identify days with effort on barplot  
* For each day of each deployment, calculate kilometers and time of survey effort  
* set up glider database to update automatically  


