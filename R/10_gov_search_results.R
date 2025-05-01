# Uses the gov.uk API to find pages that may contain workforce management information publications

# load libraries
source("pack/all_packages.R",local=TRUE)

time_stamp <- Sys.time() %>% gsub("[^0-9]","",.) %>% gsub("^20","",.)

# Function to query gov.uk search api
# https://www.gov.uk/api/search.json?q=taxes
gov_search_json_get <- function(q) {
  # Preparing the URL
  url <- modify_url("https://www.gov.uk", path = "api/search.json", query=q)
  
  # API requests
  response <- GET(url)
  
  # Tracking errors
  if ( http_error(response) ){
    print(status_code(response))
    stop("Something went wrong.", call. = FALSE)
  }
  
  if (http_type(response) != "application/json") {
    stop("API did not return json", call. = FALSE)
  }
  
  # Extracting content
  json_text <- content(response, "text")
  
  # Converting content into Dataframe
  dataframe <- jsonlite::fromJSON(json_text)
  
  dataframe
}

# print("Search for current matches using gov.uk API")

search_term='"workforce management information"'
query_list = list(q=search_term, # search term to use
                  # filter_detailed_format="transparency-data", # filters on document type
                  # filter_public_timestamp=date_range,
                  fields="updated_at", # will include 'minor' revisions, unlike 'public_timestamp'
                  fields="title", 
                  # fields="organisations", 
                  fields="link", fields="public_timestamp") # fields to return

# Count results as max return is 1000
search_n <- gov_search_json_get(q=append(query_list,list(count=0)))$total
if (search_n>=10000) {
  stop("More than 10 pages of results, refine search")
}

# Get all results and combine
gov_search_results <- ((1:(ceiling(search_n/1000))-1)*1000) %>%
  map(~ gov_search_json_get(q=append(query_list,list(start=.,count=1000)))$results) %>%
  bind_rows %>%
  mutate(public_timestamp=ymd_hms(public_timestamp),updated_at=ymd_hms(updated_at)) %>%
  select(title,link,public_timestamp,updated_at) %>%
  mutate(search_date=Sys.time()) %>%
  mutate(time_stamp=time_stamp)

saveRDS(gov_search_results,paste0("data/gov_search_results/",time_stamp,".rds"))
# gov_search_results <- readRDS("data/gov_search_results/250318151544.rds")
