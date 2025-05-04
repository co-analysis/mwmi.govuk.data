# Uses the gov.uk API to find pages that may contain workforce management information publications

# load libraries
source("pack/all_packages.R",local=TRUE)

####################################################################################################
# Compile search results
# Get unprocessed search results
# search_result_ts <- list.files("data/gov_search_results",".rds$") %>% gsub(".rds","",.)
# form_ts <- list.files("data/output","formed_data_[0-9]{12}.rds") %>%
#   gsub("formed_data_([0-9]{12}).rds","\\1",.)
# toproc_ts <- setdiff(search_result_ts,form_ts)
# 
# all_results <- list.files("data/gov_search_results",".rds$",full.names=TRUE) %>%
#   map(~readRDS(.x) %>% mutate(search_file=.x)) %>%
#   bind_rows()
# latest_results <- all_results %>%
#   unique() %>%
#   group_by(link) %>%
#   filter(updated_at==max(updated_at)) %>%
#   filter(search_date==max(search_date)) %>%
#   ungroup()

# load latest search results
latest_results <- list.files("data/gov_search_results",".rds$",full.names=TRUE) %>%
  sort(decreasing=TRUE) %>%
  head(1) %>%
  readRDS()

####################################################################################################
# Get links to possible files
# Scraping function
get_data_links <- function(link) {
  # add prefix
  url_to_scrape <- modify_url("https://www.gov.uk/api/content", path = link)
  
  # Extracting content
  html_text <- rvest::read_html(url_to_scrape) # no error catching...
  
  # Meta data
  # Todo: parse 'from' by using the hyperlinks (i.e. each dept is within a link)
  meta_data_raw <- html_text %>%
    rvest::html_nodes(".gem-c-metadata")
  meta_terms <- meta_data_raw %>%
    rvest::html_nodes(".gem-c-metadata__term") %>%
    rvest::html_text(trim=TRUE)
  meta_definitions <- meta_data_raw %>%
    rvest::html_nodes(".gem-c-metadata__definition") %>%
    rvest::html_text(trim=TRUE)
  meta_data <- data.frame(terms=meta_terms,definitions=meta_definitions)
  
  # Find links to attached data in the html
  data_links <- html_text %>%
    # rvest::html_nodes(".attachment .attachment-details a") %>%
    rvest::html_nodes("a") %>%
    rvest::html_attr("href") %>%
    grep("((ods)|(csv)|(xls)|(xlsx))$",.,value=TRUE,ignore.case=TRUE)
  
  
  # # Find text titles for files
  # data_titles <- html_text %>%
  #   rvest::html_nodes(".attachment .attachment-details h3") %>%
  #   rvest::html_text()
  
  print(paste0(length(data_links)," results from ",url_to_scrape))
  if (length(data_links)==0) data_links <- "none"
  
  list(link=link,meta_data=meta_data,data_links=data_links,data_titles="Not currently implemented")
}
# function wrapper to limit rate of connections to 10 per second
get_data_links_limited <- ratelimitr::limit_rate(get_data_links, ratelimitr::rate(n=10,period=1))

data_links_results_raw <- latest_results$link %>%
  map(get_data_links_limited) %>%
  map(~data.frame(link=.x$link,data_links=.x$data_links)) %>%
  bind_rows() %>%
  left_join(latest_results)

dupes <- function(x) duplicated(x) | duplicated(x,fromLast=TRUE)

data_links_results <- data_links_results_raw %>%
  unique() %>%
  filter(data_links!="none")

# time stamp based on latest search result
time_stamp <- max(data_links_results$time_stamp)

saveRDS(data_links_results,paste0("data/gov_data_links/",time_stamp,".rds"))
# head(data_links_results,2) %>% clip_tab()
# data_links_results <- readRDS("data/gov_data_links/250318151544.rds")

# # defra linking to data.gov in older files
# # dclg publishing with pdf in older files
  
  
  
  
  
  



















