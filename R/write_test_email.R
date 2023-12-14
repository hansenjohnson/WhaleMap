## write_test_email ##
# write an email to test an error report

# input -------------------------------------------------------------------

# data paths
email_list = 'data/email/default.csv'

# path to sendmail executable
sendmail = '/usr/sbin/sendmail'

# email details
email_file = 'test_email.txt'

# user email
myemail = 'whalemap.tech@gmail.com'

# process -----------------------------------------------------------------

# read in default emails
emails = read.csv(email_list, header = TRUE, stringsAsFactors = FALSE)$email

# email pieces
subject = paste0("Subject: WhaleMap Email Test (", format(Sys.time(), '%b-%d %H:%M %Z'),")")
from = paste0("From: ", myemail)
to = paste0("To: ", paste(emails, collapse = ','))
txt = paste0(
  "
This is a test of the WhaleMap email system.

[Auto-generated email from WhaleMap]
")

# write email file
fileConn<-file(email_file)
writeLines(c(to, subject, from, txt), fileConn)
close(fileConn)

# send email
system(paste0(sendmail, ' -vt < ', email_file))

message('Test message sent on: ', Sys.time())

