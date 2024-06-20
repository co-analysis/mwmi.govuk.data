# Source functions from eventual package
source("pack/all_packages.R",local=TRUE)
list.files("pack",pattern="\\.[rR]$",full.names=TRUE) %>%
  map(~source(.x))

################################################################################
start_time <- gsub("[^0-9]"," ",Sys.time())

# Toggle to interrupt run when no further work is required
continue_progress <- TRUE

# toggle for doing a complete new scrape - set to TRUE in github action for refresh
# if (!exists('refresh_mwmi')) refresh_mwmi = FALSE 
if (!exists('refresh_mwmi')) refresh_mwmi = TRUE
################################################################################


print("Search for current matches, by default filters for updates in last year")
gov_results <- gov_search()

# Temporary limit on number of results to save time
# gov_results <- gov_results[sample(1:nrow(gov_results),10),]
# gov_results <- gov_results[c(8, 15, 53, 76, 93, 113, 125, 153, 205, 207),]

gov_to_update <- gov_results
# # Results to check
# if (refresh_mwmi) {
#   # Update everything
#   gov_to_update <- gov_results
# 
# } else {
#   # Calc updated files
#   
#   # Get previous match results
#   # TODO: check that this is meaningfully earlier than current date
#   last_results_file <- list.files("data/gov_meta","^gov_results") %>%
#     sort(decreasing=TRUE) %>%
#     {.[1]}
#   gov_last_results <- readRDS(paste0("data/gov_meta/",last_results_file))
# 
#   # Work out which files have been created or updated
#   gov_to_update <- gov_last_results %>%
#     mutate(old_time=public_timestamp) %>%
#     select(link,old_time) %>%
#     right_join(gov_results)%>%
#     filter(is.na(old_time) | public_timestamp>old_time)
# }

# Save current results
# saveRDS(gov_results,paste0("data/gov_meta/gov_results ",start_time,".rds"),compress=FALSE)

# Save results to update
# saveRDS(gov_to_update,paste0("./data/gov_meta/gov_to_update ",start_time,".rds"))

if (nrow(gov_to_update)==0) { continue_progress <- FALSE; print("No new results") }

################################################################################
# gov_contents(links) function
# Takes a vector of results for pages and scrapes links to embedded data
# returns a list as long as the input with:
# url: original url requested
# meta_data: data.table of meta data including org and date
# data_titles: a vector of text titles for data files
# data_links: a vector of links to data files

if (continue_progress) {
  print("Take vector of results for pages and scrape links to embedded data")
  gov_datalinks <- gov_contents(gov_to_update$link)
  # saveRDS(gov_datalinks,paste0("data/gov_meta/gov_datalinks ",start_time,".rds"))
}

# # Check which urls have no results
# # gov_to_update$link[which((map(gov_datalinks, ~ .$data_links %>% length) %>% unlist)==0)]
# # defra linking to data.gov in older files
# # dclg publishing with pdf in older files
#
################################################################################
# source("./R/scraper functions/gov_downloads.R")

if (continue_progress) {
  print("Get data_links as vector")
  
  file_list <- gov_datalinks %>%
    map(~ data.frame(urls=rep(.$url_scraped,length(.$data_link)),data_link=.$data_links)) %>%
    bind_rows
  
  if (nrow(file_list)==0) {continue_progress <- FALSE ; print("no new links") }
}
# TODO: Filter out whatever is already downloaded

if (continue_progress) {
  
  file_links <- unique(file_list$data_link)
  
  file_hash <- paste0(1:length(file_links),".",gsub(".*((ods)|(csv)|(xls)|(xlsx))$","\\1",file_links,ignore.case=TRUE))
  
  # gov_dl_results <- gov_downloads(file_list$data_link,
  #                                 dl_stem="data/gov_files/",
  #                                 url_stem="https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/")
  
  
  # delete old files
  file.remove(list.files("data/gov_files",full.names=TRUE))
  
  gov_dl_results <- gov_downloads(file_list=file_links, file_hash=file_hash, dl_stem="data/gov_files/")
  
  # saveRDS(gov_dl_results,paste0("data/gov_meta/gov_dl_results ",start_time,".rds"))
  
  if (!any(gov_dl_results$dl_result=="Successful")) {continue_progress <- FALSE ; print("No new files downloaded")}
}
################################################################################
if (continue_progress) {
  print("Download files")
  
  # List of recently downloaded files
  gov_files <- gov_dl_results %>% filter(dl_result=="Successful") %>% pull(dl_location)
  
  # Create output file names, run conversion code
  # rds_stem = "data/gov_files_rds"
  # rds_files <- gov_files %>%
  #   paste0(.,".rds") %>%
  #   gsub("gov_files","gov_files_rds",.)
  rds_files <- paste0("data/gov_files/",1:length(gov_files),".rds")
  
  # Convert files from downloaded format to rds
  file_conversion_results <- file_handler(gov_files,rds_files)
}
