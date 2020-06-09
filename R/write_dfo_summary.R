## write_summary_reports ##

# user input --------------------------------------------------------------

## report directory
report_dir = 'shared/dfo/summary_reports/'

## day to write weekly report
weekly_report_day = 'Friday'

## rewrite all reports (will take a long time, maybe an hour or so)
rewrite_reports = FALSE
rewrite_from = as.Date('2019-01-01')

## remove .tex files
remove_tex = TRUE

# setup -------------------------------------------------------------------

# define dates in various formats
today = Sys.Date()
today_name = format(today, '%A')
yesterday = today-1

# define report function --------------------------------------------------

render_report = function(template = "R/write_dfo_summary-template.Rmd", 
                         outdir = report_dir, 
                         report_date = yesterday, 
                         type = 'daily'){
  
  # libraries
  library(knitr)
  library(rmarkdown)

  # define file names and paths
  if(type == 'daily'){
    
    ## daily report ##
    
    # set time interval for daily report
    t0 = report_date
    t1 = report_date
    
    # define output directory
    daily_dir = paste0(outdir, 'daily/')
    if(!dir.exists(daily_dir)){dir.create(daily_dir, recursive = TRUE)}
    
    # define output file - must be relative to location of template
    output_file = paste0('../', daily_dir, t1, '_WhaleMap_daily_summary.pdf')
    
  } else if(type == 'daily-extended'){
    
    ## daily-extend report ##
    
    # set time interval for daily report
    t0 = report_date-2
    t1 = report_date
    
    # define output directory
    extended_dir = paste0(outdir, 'daily-extended/')
    if(!dir.exists(extended_dir)){dir.create(extended_dir, recursive = TRUE)}
    
    # define output file - must be relative to location of template
    output_file = paste0('../', extended_dir, t1, '_WhaleMap_daily-extended_summary.pdf')
    
  } else if(type == 'weekly'){
    
    ## weekly report ##
    
    # set time interval for daily report
    t0 = report_date-6
    t1 = report_date
    
    # define output directory
    weekly_dir = paste0(outdir, 'weekly/')
    if(!dir.exists(weekly_dir)){dir.create(weekly_dir, recursive = TRUE)}
    
    # define output file - must be relative to location of template
    output_file = paste0('../', weekly_dir, t0, '_WhaleMap_weekly_summary.pdf')
  }
  
  # render report
  rmarkdown::render(input = template, 
                    output_file = output_file, 
                    quiet = TRUE,
                    clean = TRUE,
                    params = list(
                      start = t0,
                      stop = t1
                    )
  )
}

# make reports ------------------------------------------------------------

## render daily report ##
render_report(report_date=yesterday, type = 'daily')

## render extendeddaily report ##
render_report(report_date=yesterday, type = 'daily-extended')

## render weekly report ##
if(today_name == weekly_report_day){
  render_report(report_date=yesterday, type = 'weekly')
}

## rewrite all reports for given period ##
if(rewrite_reports){
  
  # define date sequence
  date_seq = seq.Date(from = rewrite_from, to = Sys.Date(), by = 1)
  
  # build reports
  for(i in seq_along(date_seq)){
    
    # render daily report
    render_report(report_date=date_seq[i], type = 'daily')
    
    # render weekly report
    if(format(date_seq[i], '%A') == weekly_report_day){
      render_report(report_date=date_seq[i]-1, type = 'weekly')
    }
    
  }
}

# clean report directory --------------------------------------------------

if(remove_tex){
  # list temporary tex files created during pdf rendering
  rm_files = list.files(path = report_dir, pattern = '*.tex$', recursive = TRUE, full.names = TRUE)
  
  # delete temporary files
  file.remove(rm_files)
}

