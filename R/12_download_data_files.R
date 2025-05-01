# load libraries
source("pack/all_packages.R",local=TRUE)

####################################################################################################
# Load latest results for data links

links_file <- sort(list.files("data/gov_data_links",".rds",full.names=TRUE),decreasing=TRUE)[1]

latest_links <- readRDS(links_file) %>%
  mutate(dl_index=1:n()) %>%
  mutate(file_types=gsub(".*\\.([odsxlcv]{3,4})$","\\1",tolower(data_links)))

# time stamp based on latest search result
time_stamp <- max(latest_links$time_stamp)

dl_stem <- paste0("data/gov_data/",time_stamp)

dir.create(dl_stem)

####################################################################################################
# TODO: remove files that have already been downloaded



####################################################################################################
# Loop through and download files 

dl_results <- NULL
N <- nrow(latest_links)

for (i in 1:N) {
  # i = 1702, 3178
  k = which(latest_links$dl_index==i)
  data_link <- latest_links$data_links[k]
  data_index <- latest_links$dl_index[k]
  file_type <- latest_links$file_types[k]
  dl_loc <- paste0(dl_stem,"/",data_index,".",file_type)
  
  file_check <- try(httr::HEAD(data_link),silent=TRUE)
  
  if (class(file_check)=="response") {
    if (file_check$status_code=="200") {
      download_size <- as.numeric(file_check$headers$`content-length`)
      if (download_size >= 25000000) {
        dl_result <- "File too large" # error if over 25MB
      } else {
        dl_result <- try(download.file(data_link, dl_loc, quiet=TRUE, mode="wb"),silent=TRUE)[1] %>% # return error message if it fails
          ifelse(.==0,"Successful",.) # if no message, successful
      }
    } else {
      dl_result <- file_check$status_code # return status error if not successful
    }
  } else {
    dl_result <- file_check[1] # if response not received, return error message
  }
  print(paste0(data_index,"/",N," : ",dl_result," : ",data_link))
  
  dl_results <- bind_rows(dl_results,data.frame(data_links=data_link,dl_loc,dl_result=as.character(dl_result),dl_index=data_index))
}
dl_results <- mutate(dl_results,time_stamp=time_stamp)
saveRDS(dl_results,paste0(dl_stem,"/dl_results_",time_stamp,".rds"))
# dl_results <- readRDS(paste0(dl_stem,"/dl_results_",time_stamp,".rds"))

# dl_results <- dl_results %>%
#   # head() %>%
#   select(-time_stamp) %>%
#   mutate(dl_loc=gsub("250407171606",time_stamp,dl_loc)) %>%
#   mutate(time_stamp=time_stamp)

####################################################################################################
# Convert files to standardised data.frames set up for unpivotr
source("pack/file_handler.R") # conversion functions

conversion_list <- dl_results %>%
  mutate(conv_loc=ifelse(dl_result=="Successful",paste0(dl_loc,".rds"),""))

conversion_results <- conversion_list %>%
  filter(dl_result=="Successful") %$%
  file_handler(dl_loc,conv_loc) %>%
  right_join(conversion_list)

saveRDS(conversion_results,paste0(dl_stem,"/conversion_results_",time_stamp,".rds"))
# conversion_results <- readRDS(paste0(dl_stem,"/conversion_results_",time_stamp,".rds"))

# conversion_results <- conversion_results %>%
#   # tail() %>%
#   select(-time_stamp) %>%
#   mutate(dl_loc=gsub("250407123554",time_stamp,dl_loc)) %>%
#   mutate(conv_loc=gsub("250407123554",time_stamp,conv_loc)) %>%
#   mutate(time_stamp=time_stamp)
