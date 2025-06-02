# load libraries
source("pack/all_packages.R",local=TRUE)

####################################################################################################
# Load latest results for data links

links_file <- sort(list.files("data/gov_data_links",".rds",full.names=TRUE),decreasing=TRUE)[1]

data_links_results <- readRDS(links_file) %>%
  mutate(file_types=gsub(".*\\.([odsxlcv]{3,4})$","\\1",tolower(data_links)))

# time stamp based on latest search result
time_stamp <- max(data_links_results$time_stamp)

dl_stem <- paste0("data/gov_data/",time_stamp)

dir.create(dl_stem)

####################################################################################################
# TODO: rewrite now that dl_results is only partial...


# previous dl results
# filter to latest?
all_dl_results <- list.files("data/gov_data/","^dl_results",recursive=TRUE,full.names=TRUE) %>%
  map(readRDS) %>%
  bind_rows()
# previous search details (time updated etc) for dls
search_details <- unique(all_dl_results$time_stamp) %>%
  paste0("data/gov_data_links/",.,".rds") %>%
  map(readRDS) %>%
  bind_rows()
# merged info
all_dl_results_details <- all_dl_results %>%
  select(data_links,dl_result,time_stamp) %>%
  left_join(select(search_details,data_links,prev_public_timestamp=public_timestamp,prev_updated_at=updated_at,time_stamp)) %>%
  group_by(data_links) %>%
  filter(time_stamp==max(time_stamp)) %>%
  ungroup() %>%
  select(-time_stamp)

data_links_results_type <- data_links_results %>%
  left_join(all_dl_results_details) %>%
  mutate(type="") %>%
  mutate(type=ifelse(is.na(dl_result),"new",type)) %>%
  mutate(type=ifelse(type=="" & dl_result!="Successful","failed",type)) %>%
  # mutate(type=ifelse(type=="" & dl_result=="Successful" & (public_timestamp>prev_public_timestamp | updated_at>prev_updated_at),"updated",type)) %>%
  mutate(type=ifelse(type=="" & dl_result=="Successful" & (public_timestamp>prev_public_timestamp),"updated_public",type)) %>%
  mutate(type=ifelse(type=="" & dl_result=="Successful" & (updated_at>prev_updated_at),"updated",type)) %>%
  mutate(type=ifelse(type=="" & dl_result=="Successful","existing",type))

# NOTE: 'updated_at' appears to be returning invalid results, but will need to be monitored in case removing this drops actual changes
data_links_toproc <- data_links_results_type %>%
  filter(!type%in%c("existing","updated")) %>% 
  mutate(dl_index=1:n())

####################################################################################################
# Loop through and download files 

dl_results <- NULL
N <- nrow(data_links_toproc)

for (i in 1:N) {
  # i = 1702, 3178
  k = which(data_links_toproc$dl_index==i)
  data_link <- data_links_toproc$data_links[k]
  data_index <- data_links_toproc$dl_index[k]
  file_type <- data_links_toproc$file_types[k]
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
