# Source functions from eventual package
source("pack/all_packages.R",local=TRUE)
list.files("pack",pattern="\\.[rR]$",full.names=TRUE) %>%
  map(~source(.x))

if (continue_progress) {
  ###############################################################################
  # Get list of rds files to check
  gov_rds <- list.files("data/gov_files",
                        pattern=".rds$",
                        include.dirs=FALSE,
                        full.names=TRUE,
                        recursive=TRUE)
  # Add in a blank templates to format for use later
  gov_rds <- c(gov_rds,list.files("data/templates/blank",
                                  pattern=".rds$",
                                  include.dirs=FALSE,
                                  full.names=TRUE,
                                  recursive=TRUE))
  
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
  # TODO: currently template_formats is being set and read from environment rather than passed as an argument
  
  # Check all files to see if they match against the prescribed template
  match_format_results <- map(gov_rds,find_matching_sheets)
  
  which_matching <- which(map(match_format_results,~ .x$any_sheets) %>% unlist)
  
  # Output results for QA
  # write_rds(match_format_results,paste0("data/gov_meta/match_format_results.rds"))
  # write_rds(which_matching,paste0("data/gov_meta/which_matching.rds"))
  
  # Load matching datasets
  rds_data <- map(gov_rds[which_matching],readRDS)
  
  ################################################################################
  # Load meta data on template formats
  template_meta <- read_excel("data/metadata/template metadata.xlsx","meta")

  # Extract list of matching formats and merge in meta data
  matching_data_format <- map(match_format_results[which_matching],~ .x$template) %>%
    unlist %>%
    gsub("\\.[xlscvod]{3,4}$","",.) %>%
    data.frame(template=.) %>%
    left_join(template_meta)

  # Extract matching tabs
  matching_data <- map2(rds_data,match_format_results[which_matching], ~ if (.y$any_sheets==TRUE) {.x[.y$which_sheets]} else {NULL}) %>%
    unlist(recursive=FALSE,use.names=FALSE)
  
  # Crop off header rows
  beheaded_data <- map2(matching_data,matching_data_format$header_rows,~ .x %>% filter(row>.y))
  
  ################################################################################
  # Formatting
  
  # Set up labels to merge in to beheaded data
  # Sheet names designating different label sets
  template_label_sheets <- excel_sheets("data/metadata/template import labels.xlsx")
  # Import label data
  template_labels_data <- map(template_label_sheets,~read_excel("data/metadata/template import labels.xlsx",.x))
  names(template_labels_data) <- template_label_sheets
  # Match labels to format of data
  # template_labels <- template_labels_data[matching_data_format$labels]
  
  # Merge in
  labelled_data <- map2(beheaded_data,matching_data_format$labels,~ left_join(.x,template_labels_data[[.y]]))
  
  formed_data <- map(labelled_data,labelled_data_format)
  
  dat <- formed_data %>% bind_rows
  
  dat_name <- paste0("data/output/formed_data_",format(Sys.time(),"%Y_%m_%d_%H_%M_%S"),".RDS")
  
  saveRDS(dat,dat_name)
}
