get_data_links <- function(url_to_scrape) {
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
  
  list(url_scraped=url_to_scrape,meta_data=meta_data,data_links=data_links,data_titles="Not currently implemented")
}

get_data_links_limited <- ratelimitr::limit_rate(get_data_links, ratelimitr::rate(n=10,period=1))

gov_contents <- function(links) {
  # url format
  urls <- map(links, ~ modify_url("https://www.gov.uk/api/content", path = .))
  
  # Get the data links
  map(urls,get_data_links_limited)
}


