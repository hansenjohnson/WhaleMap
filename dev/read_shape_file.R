library(rgdal)

ifile = 'data/raw/to_add/NARW sightings 2017 Exp GoSL/Shapefiles ODY vessel track/ODY_vessel_track_clean_line.shp'

ifile = 'data/raw/to_add/NARW sightings 2017 Exp GoSL/Shapefiles ODY vessel track/Survey tracks/ODY_Oceana_pelagic_survey_2017AUG27_1.shp'

shape <- readOGR(dsn = ifile)

summary(shape)

