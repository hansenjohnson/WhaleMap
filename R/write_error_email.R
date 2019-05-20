## write_error_email ##
# write an email to report an error

# input -------------------------------------------------------------------

# data paths
index_file = 'status_index.csv'
status_file = 'data/processed/status.txt'
default_email_list = 'data/email/default.csv'

# path to sendmail executable
sendmail = '/usr/sbin/sendmail'

# email details
email_file = 'error_email.txt'

# process -----------------------------------------------------------------

# read in status file
st = read.csv(status_file, header = FALSE,
              col.names = c('script', 'status'),
              stringsAsFactors = FALSE)

# find error(s)
er = grep(pattern = 'ERROR', x = st$status)

# create and send email if error exists
if(length(er)!=0){

  # only create and send email if it has not been sent already
  if(!file.exists(email_file)){

    # read in lookup table
    id = read.csv(index_file, header = TRUE, stringsAsFactors = FALSE)

    # find bad script(s) in lookup table
    bad = match(st$script[er], id$script)

    # remove those missing from looking table
    bad = bad[!is.na(bad)]

    # only report one error at a time
    bad = bad[1]

    # report error
    message('Error found in: ', id$script[bad])

    # define email list file
    efile = id$email_list[bad]

    # read email list for bad script
    if(file.exists(efile)){
      message('Sending to recipients listed in: ', efile)
      emails = read.csv(efile, header = TRUE, stringsAsFactors = FALSE)$email
    } else {
      message('Could not find ', efile, ', so deferring to the default email list here: ', default_email_list)
      emails = read.csv(default_email_list, header = TRUE, stringsAsFactors = FALSE)$email
    }

    # email pieces
    subject = paste0("Subject: WhaleMap Error (", format(Sys.time(), '%b-%d %H:%M %Z'),"): Cannot process data from ", id$name[bad])
    from = "From: hansen.johnson@dal.ca"
    to = paste0("To: ", paste(emails, collapse = ','))
    txt = paste0(
"
WhaleMap could not process ", id$name[bad], " correctly!

Please check your data for errors. Common issues include typos in the file name, mixing time or lat/lon conventions, or using unknown species codes. It can be very helpful to check the formatting of a previous record.

If you have tried to make a correction, head to https://whalemap.ocean.dal.ca/WhaleMap to see if it was successful. WhaleMap updates every 15 minutes, so it should not take long to see your changes. You can also scroll down on WhaleMap to check the status table. If you see an error message next to your platform name, there is still a problem.

If you cannot find an error and/or suspect the problem is related to WhaleMap, please reply to this email for more help.

[Auto-generated email from WhaleMap]
")
    
    # write email file
    fileConn<-file(email_file)
    writeLines(c(to, subject, from, txt), fileConn)
    close(fileConn)

    # send email
    system(paste0(sendmail, ' -vt < ', email_file))

    message('Error message sent on: ', Sys.time())

  } else {
    message('Error message already sent')
  }

} else {
  # no error found

  # remove email file if it exists
  if(file.exists(email_file)){
    file.remove(email_file)
    message('Error no longer exists - removing email file')
  } else {
    message('No errors to report')
  }
}
