get_gov_file <- function(file_url, file_hash, dl_stem) {
  # if (startsWith(file_url,url_stem)) { # Check that URL matches specified pattern
    
  dl_location <- paste0(dl_stem,file_hash)
  
    # # Get file location after the stem, used to ensure uniqueness
    # folder_stub <- file_url %>%
    #   gsub(paste0("^",url_stem),"",.) %>%
    #   gsub("/[^/]+$","",.)
    # # Create directory
    # dir.create(paste0(dl_stem,folder_stub),showWarnings=FALSE,recursive=TRUE)
    # 
    # # Get file name
    # file_name <- gsub(".*/([^/]+$)","\\1",file_url)
    # 
    # # Make DL location
    # dl_location <- paste0(dl_stem, folder_stub, "/", file_name)
    
    # Download
    # Check file size
    download_size <- as.numeric(httr::HEAD(file_url)$headers$`content-length`)
    if (download_size >= 25000000) {
      dl_result <- "File too large"
    } else {
      dl_result <- try(download.file(file_url, dl_location, quiet=TRUE, mode="wb"),silent=TRUE)[1] %>%
        ifelse(.==0,"Successful",.)
    }
    print(paste0(file_url," ",dl_result))
    
    # Return
    data.frame(data_link=file_url,dl_location,dl_result)
    
  # } else {
  #   # Return error if URL doesn't match specified pattern
  #   data.frame(data_link=file_url,dl_location=NA,dl_result="Malformed URL")
  # }
}

gov_downloads <- function(file_list, file_hash, ...) {
  # Map across files
  dl_tracking <- map2(file_list, file_hash, function(file_name=.x, file_hash=.y, ...) get_gov_file(file_name, file_hash, ...), ...) # note the triple ellipses to pass an argument into map
  
  # Return
  dl_tracking %>% bind_rows
}
