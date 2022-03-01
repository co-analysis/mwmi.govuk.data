# library(httr)
# library(jsonlite)
# library(tidyverse)
# library(rvest)
# library(ratelimitr)
# library(lubridate)
# library(magrittr)
# library(readxl)
# library(unpivotr)
# library(tidyxl)
#
# ################################################################################
# start_time <- gsub("[^0-9]"," ",Sys.time())
# refresh = FALSE # toggle for doing a complete new scrape
#
# ################################################################################
# source("./R/scraper functions/gov_search.R")
# # gov_search() function
# # returns data frame of results for 'workforce management information' from gov.uk search API with:
# # title:
# # organisations:
# # link:
# # public_timestamp:
# # Other columns relate to the search engine
#
# # Get previous match results
# # TODO: check that this is meaningfully earlier than current date
# last_results_file <- list.files("./data/gov_meta","^gov_results") %>%
#   sort(decreasing=TRUE) %>%
#   {.[1]}
# gov_last_results <- read_rds(paste0("./data/gov_meta/",last_results_file))
#
# # Search for current matches
# gov_results <- gov_search()
# # Save current results
# write_rds(gov_results,paste0("./data/gov_meta/gov_results ",start_time,".rds"))
#
# # Work out which files have been created or updated
# gov_updated_results <- gov_last_results %>%
#   mutate(old_time=ymd_hms(public_timestamp)) %>%
#   select(link,old_time) %>%
#   right_join(gov_results) %>%
#   mutate(new_time=ymd_hms(public_timestamp))
# if (refresh==FALSE) {
#   gov_updated_results <- gov_updated_results %>%
#     filter(is.na(old_time) | new_time>old_time)
# }
# write_rds(gov_updated_results,paste0("./data/gov_meta/gov_updated_results ",start_time,".rds"))
#
# ################################################################################
# source("./R/scraper functions/gov_contents.R")
# # gov_contents(links) function
# # Takes a vector of results for pages and scrapes links to embedded data
# # returns a list as long as the input with:
# # url: original url requested
# # meta_data: data.table of meta data including org and date
# # data_titles: a vector of text titles for data files
# # data_links: a vector of links to data files
#
# gov_datalinks <- gov_contents(gov_updated_results$link)
# write_rds(gov_datalinks,paste0("./data/gov_meta/gov_datalinks ",start_time,".rds"))
#
# # Check which urls have no results
# # gov_updated_results$link[which((map(gov_datalinks, ~ .$data_links %>% length) %>% unlist)==0)]
# # defra linking to data.gov in older files
# # dclg publishing with pdf in older files
#
# ################################################################################
# source("./R/scraper functions/gov_downloads.R")
#
# # Get data_links as vector
# file_list <- gov_datalinks %>%
#   map(~ data.frame(urls=rep(.$url_scraped,length(.$data_link)),data_link=.$data_links)) %>%
#   bind_rows
#
# # TODO: Filter out whatever is already downloaded
#
# gov_dl_results <- gov_downloads(file_list$data_link,
#               dl_stem="./data/gov_files/",
#               url_stem="https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/")
# write_rds(gov_dl_results,paste0("./data/gov_meta/gov_dl_results ",start_time,".rds"))
#
# ################################################################################
# source("./R/scraper functions/file_handler.R")
# # Inconsistency with prev argument, no / at end
# # dl_stem = "./data/gov_files"
# # gov_files <- list.files(dl_stem,pattern="^[^~]",include.dirs=FALSE,full.names=TRUE,recursive=TRUE)
#
# # List of recently downloaded files
# gov_files <- gov_dl_results %>% filter(dl_result=="Successful") %>% pull(dl_location)
#
# # Create output file names, run conversion code
# rds_stem = "./data/gov_files_rds"
# rds_files <- gov_files %>%
#   paste0(.,".rds") %>%
#   gsub("gov_files","gov_files_rds",.)
#
# # Convert files from downloaded format to rds
# file_conversion_results <- file_handler(gov_files,rds_files)
#
