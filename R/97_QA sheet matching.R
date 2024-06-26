gov_rds_file <- "data/gov_files/304.rds"

raw_data <- readRDS(gov_rds_file)

raw_sheet_data <- raw_data[[1]]

does_data_match_a_template <- list(match=FALSE,template=NULL)
# try({
raw_sheet_data %>%
  mutate(sheet_chr=text_sanitiser(chr)) %>%
  select(address,sheet_chr) %>%
  right_join(template_formats,by="address") %>%
  mutate(template_chr=text_sanitiser(template_chr)) %>%
  group_by(template) %>%
  summarise(match=all(!is.na(sheet_chr) & sheet_chr==template_chr),same=sum(!is.na(sheet_chr) & sheet_chr==template_chr),n=sum(!is.na(sheet_chr)))

raw_sheet_data %>%
  mutate(sheet_chr=text_sanitiser(chr)) %>%
  select(address,sheet_chr) %>%
  right_join(template_formats,by="address") %>%
  mutate(template_chr=text_sanitiser(template_chr)) %>%
  filter(template=="template 202204.csv") %>%
  filter(!is.na(sheet_chr) & sheet_chr!=template_chr)

# text_sanitiser <- function(x) {
#   x %>%
#     gsub("(\r)|(\n)|(\t)"," ",.) %>%
#     iconv(to="latin1") %>%
#     tolower() %>%
#     gsub("[^a-z]"," ",.) %>%
#     gsub(" +"," ",.) %>%
#     {.}
# }
# 
# matching_to_templates <- function(raw_sheet_data) {
#   does_data_match_a_template <- list(match=FALSE,template=NULL)
#   try({
#     template_matches <- raw_sheet_data %>%
#       mutate(sheet_chr=text_sanitiser(chr)) %>%
#       select(address,sheet_chr) %>%
#       right_join(template_formats,by="address") %>%
#       mutate(template_chr=text_sanitiser(template_chr)) %>%
#       group_by(template) %>%
#       summarise(match=all(!is.na(sheet_chr) & sheet_chr==template_chr))
#     
#     does_data_match_a_template <- list(
#       match=any(template_matches$match),
#       template=template_matches$template[template_matches$match==TRUE][1])
#   })
#   does_data_match_a_template
# }
# 
# 
# find_matching_sheets <- function(gov_rds_file) {
#   raw_data <- readRDS(gov_rds_file)
#   matching_detail <- map(raw_data,matching_to_templates)
#   matching <- map(matching_detail,~ .x$match) %>% unlist()
#   template_matched <- map(matching_detail,~ .x$template) %>% unlist()
#   
#   print(gov_rds_file)
#   list(
#     file=gov_rds_file,
#     any_sheets=any(matching),
#     which_sheets=which(matching),
#     template=template_matched[which(matching)])
# }

