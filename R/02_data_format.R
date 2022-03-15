library(mwmi.govuk.scraper)
library(readxl)
# library(tidyverse)
# library(magrittr)
# library(readxl)
# library(unpivotr)
# library(tidyxl)
#

if (continue_progress) {
  ###############################################################################
  # Get list of rds files to check
  gov_rds <- list.files("data/gov_files_rds",
                        pattern=".rds$",
                        include.dirs=FALSE,
                        full.names=TRUE,
                        recursive=TRUE)
  # Add in a blank template to format for use later
  gov_rds <- c(gov_rds,"data/templates/import/blank accessible template.xlsx.rds")
  
  # TODO: filter out those which have already been checked
  
  # Read templates into a dataset to merge on
  template_format_files <- list.files("data/templates/rds",
                                      pattern="^[^~]",
                                      include.dirs=FALSE,
                                      full.names=TRUE,
                                      recursive=TRUE)
  template_formats <- map(template_format_files,~ readRDS(.x)[[1]] %>%
                            filter(!is.na(chr)) %>%
                            mutate(template_chr=text_sanitiser(chr)) %>%
                            select(address,row,col,template_chr) %>%
                            mutate(template=gsub(".*?\\/([^\\/]+)\\.rds","\\1",.x))) %>%
    bind_rows
  # TODO: currently being set and read from environment - better way?
  
  # Check all files to see if they match against the prescribed template
  match_format_results <- map(gov_rds,find_matching_sheets)
  
  which_matching <- which(map(match_format_results,~ .x$any_sheets) %>% unlist)
  
  # Output results for QA
  # write_rds(match_format_results,paste0("data/gov_meta/match_format_results.rds"))
  # write_rds(which_matching,paste0("data/gov_meta/which_matching.rds"))
  
  # Load matching datasets
  rds_data <- map(gov_rds[which_matching],readRDS)
  
  ################################################################################
  # Extract matching tabs
  matching_data <- map2(rds_data,match_format_results[which_matching], ~ if (.y$any_sheets==TRUE) .x[.y$which_sheets] else NULL) %>%
    unlist(recursive=FALSE,use.names=FALSE)
  
  # Extract list of matching formats and hence number of header rows to drop
  matching_data_format <- map(match_format_results[which_matching],~ .x$template) %>%
    unlist
  matching_data_headers <- ifelse(grepl("^accessible",matching_data_format),1,3)
  
  # Crop off header rows
  beheaded_data <- map2(matching_data,matching_data_headers,~ .x %>% filter(row>.y))
  
  ################################################################################
  # Formatting
  
  # Import labels to merge in to beheaded data
  template_labels <- read_excel("data/templates/import/template import labels.xlsx")
  # Merge in
  labelled_data <- map(beheaded_data,~ left_join(.x,template_labels))
  
  formed_data <- map(labelled_data,labelled_data_format)
  
  dat <- formed_data %>% bind_rows
  saveRDS(dat,"data/output/formed_data.RDS")
}
