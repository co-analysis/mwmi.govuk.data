# library(tidyverse)
# library(magrittr)
# library(workforcedata)
#
# source("R/qa functions/load_qa_data.R")
# qad <- load_qa_data()
#
# file_search_string <- "MOD_MWMI_June_21"
#
# # Matches in gov_datalinks
# match_datalinks_index <- map(qad$gov_datalinks,~any(grep(file_search_string,.x$data_links))) %>%
#   unlist %>%
#   which
# match_datalinks <- map(qad$gov_datalinks,~grep(file_search_string,.x$data_links,value=TRUE)) %>%
#   {.[map(.,length)>0]}
#
# # Matches in gov_files
# match_govfiles_index <- grep(file_search_string,qad$gov_files)
# match_govfiles <- grep(file_search_string,qad$gov_files,value=T)
#
# # Matches in gov_rds
# match_govrds_index <- grep(file_search_string,qad$gov_rds)
# match_govrds <- grep(file_search_string,qad$gov_rds,value=T)
#
# # match_format_results
# match_format <- qad$match_format_results[match_govrds_index]
#
# # which rds files match
# whichmatching_rds <- qad$gov_rds[intersect(qad$which_matching,match_govrds_index)]
#
# # Matches in formed_data
# match_formeddata <- qad$formed_data %>%
#   filter(grepl(file_search_string,file))
#
# # Matches in cleaned_data
# match_cleaneddata <- qad$cleaned_data %>%
#   filter(grepl(file_search_string,file))
#
