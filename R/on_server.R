on_server = function(){
  # simple test to determine if app is running from server
  Sys.info()[['sysname']] == "Linux"
}