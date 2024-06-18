# library(mwmi.govuk.scraper)

# ################################################################################
# Converts clean versions of the data templates into .rds
# to be used when checking if downloaded files match the expected format

# Input files
template_files <- list.files("data/templates/original",
                             pattern="^[^~]",
                             include.dirs=FALSE,
                             full.names=TRUE,
                             recursive=TRUE)

# Create output file names, run conversion code
template_rds_files <- template_files %>%
  paste0(.,".rds") %>%
  gsub("templates/original","templates/rds",.)
template_conversion_results <- file_handler(template_files,template_rds_files)

# Convert a blank copy to use when filling in missing returns
blanks <- list.files("data/templates/blank",full.names=TRUE,pattern="(xlsx?$)|(csv$)")
file_handler(blanks,paste0(blanks,".rds"))

