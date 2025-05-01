ts <- "250428144127"

# Home office 2024 - (excl agencies) issue
t_link <- "government/publications/workforce-management-information-2024"
t_file <- "https://assets.publishing.service.gov.uk/media/6784fc6df0528401055d230f/Workforce+Management+Information+Nov+2024+_ODS_.ods"

# MOJ 2021 Feb
t_link <- "government/publications/workforce-management-information-moj"
t_file <- "https://assets.publishing.service.gov.uk/media/618a40a9e90e071979dfeea4/moj-headcount-payroll-data-february-2021.csv"


# Search results
gsr <- readRDS(paste0("data/gov_search_results/",ts,".rds"))
gsr %>%
  filter(grepl(t_link,link,fixed=TRUE))

# links results
lr <- readRDS(paste0("data/gov_data_links/",ts,".rds"))
lr %>%
  filter(grepl(t_link,link,fixed=TRUE))

# Download and format
fr <- readRDS(paste0("data/gov_data/",ts,"/form_results_",ts,".rds"))
fr %>%
  filter(grepl(t_file,data_links,fixed=TRUE))


fr %>%
  filter(grepl(t_file,data_links,fixed=TRUE)) %>%
  pull(conv_loc) %>%
  readRDS()
