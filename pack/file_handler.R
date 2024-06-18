letter_seq <- function(x) {
  if (max(x) > 26*26*26) stop("Number out of range")
  d1 <- LETTERS[(x-1)%%26+1]
  d2 <- ifelse(x<=26,"",rep(LETTERS,each=26)[(x-26-1)%%(26*26)+1])
  d3 <- ifelse(x<=26*26 + 26,"",rep(rep(LETTERS,each=26),each=26)[(x-26*26-1)%%(26*26*26)+1])
  paste0(d3,d2,d1)
}

# Read a single sheet from an XLS/x file and convert to long form 'unpivotr' format
xls_sheet_cells <- function(file_name,sheet_name) {
  sheet_data <- NULL
  try({
    sheet_data <- readxl::read_excel(file_name,sheet=sheet_name,col_names=FALSE) %>%
      unpivotr::as_cells() %>%
      mutate(sheet=sheet_name,file=file_name,file_type=gsub(".*(xlsx?)$","\\1",file_name)) %>%
      mutate(address=paste0(letter_seq(col),row))
  })
  sheet_data
}

# Read all sheets in an XLS/x file, convert to cells, save as list of tables in RDS
xls_cells <- function(data_file,data_out_file) {
  print(paste0("Trying: ",data_file))
  xls_data <- NULL
  try({
    sheet_names <- readxl::excel_sheets(data_file) ;
    xls_data <- map2(data_file,sheet_names,~ xls_sheet_cells(.x,.y))
  })
  
  # create directory to save to
  # dir.create(gsub("\\/[^\\/]+$","",data_out_file),showWarnings=FALSE,recursive=TRUE)
  # save
  saveRDS(xls_data,data_out_file)
  
  return <- !is.null(xls_data)
}

ods_sheet_cells <- function(file_name,sheet_name) {
  sheet_data <- NULL
  try({
    sheet_data <- readODS::read_ods(file_name,sheet=sheet_name,col_names=FALSE) %>%
      unpivotr::as_cells() %>%
      mutate(sheet=sheet_name,file=file_name,file_type="ods") %>%
      mutate(address=paste0(letter_seq(col),row))
  })
  sheet_data
}

ods_cells <- function(data_file,data_out_file) {
  print(paste0("Trying: ",data_file))
  ods_data <- NULL
  try({
    sheet_names <- readODS::list_ods_sheets(data_file) ;
    ods_data <- map2(data_file,sheet_names,~ ods_sheet_cells(.x,.y))
  })
  
  # create directory to save to
  # dir.create(gsub("\\/[^\\/]+$","",data_out_file),showWarnings=FALSE,recursive=TRUE)
  # save
  saveRDS(ods_data,data_out_file)
  
  return <- !is.null(ods_data)
}

# Read a single sheet from a csv file and convert to long form 'unpivotr' format
csv_sheet_cells <- function(file_name,sheet_name) {
  sheet_data <- NULL
  try({
    sheet_data <- readr::read_csv(file_name,col_names=FALSE,show_col_types=FALSE) %>%
      as_cells %>%
      mutate(sheet=sheet_name,file=file_name,file_type="csv") %>%
      mutate(address=paste0(letter_seq(col),row))
  })
  sheet_data
}

# Read a csv file, convert to cells, save as table in RDS
csv_cells <- function(data_file,data_out_file) {
  print(paste0("Trying: ",data_file))
  csv_data <- NULL
  try({
    csv_data <- map2(data_file,"csv data",~ csv_sheet_cells(.x,.y))
  })
  
  # create directory to save to
  # dir.create(gsub("\\/[^\\/]+$","",data_out_file),showWarnings=FALSE,recursive=TRUE)
  # save
  saveRDS(csv_data,data_out_file)
  
  return <- !is.null(csv_data)
}


file_handler <- function(in_files,out_files) {
  # Get input file extension
  file_type <- in_files %>%
    gsub(".*?([^\\.]+)$","\\1",.) %>%
    tolower
  
  # Choose which function to use for each file
  handler_function <- case_when(
    file_type == "xls" ~ list(xls_cells),
    file_type == "xlsx" ~ list(xls_cells),
    file_type == "csv" ~ list(csv_cells),
    file_type == "ods" ~ list(ods_cells),
    TRUE ~ list(function(x,y,z) "Unhandled file type")
  )
  
  # Run the selected function on each file
  pmap(list(in_files,out_files,handler_function),map2)
}

