# Uses the gov.uk API to find pages that may contain workforce management information publications

# load libraries
source("pack/all_packages.R",local=TRUE)

####################################################################################################
# latest set of data links
list.files("data/gov_data_links",".rds$",full.names=TRUE) %>%
  sort() %>%
  {.[1]}

















