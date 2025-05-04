# load libraries
source("pack/all_packages.R",local=TRUE)

# Standardise characters
text_sanitiser <- function(x) {
  x %>%
    gsub("(\r)|(\n)|(\t)"," ",.) %>%
    iconv(to="latin1") %>%
    tolower() %>%
    gsub("[^a-z0-9]+"," ",.) %>%
    gsub(" $","",.) %>%
    {.}
}

####################################################################################################
# Convert templates to standardised format for matching
# Note, this only needs to be run when the templates are updated

# source("pack/file_handler.R") # conversion functions
# 
# temp_files <- list.files("data/templates/original")
# temp_conv <- paste0("data/templates/rds/",temp_files,".rds")
# 
# file_handler(paste0("data/templates/original/",temp_files),temp_conv)
# 
# temp_to_match <- temp_conv %>%
#   map(readRDS) %>%
#   map2(temp_files,~mutate(.x[[1]],template=.y)) %>%
#   bind_rows() %>%
#   filter(!is.na(chr)) %>%
#   mutate(lab=text_sanitiser(chr)) %>%
#   mutate(template=gsub(".*(template [0-9]{6}).*","\\1",template)) %>%
#   select(address,col,row,template,lab) %>%
#   unique() %>%
#   arrange(template,col,row)
# 
# # Output the template data structure so group labels etc can be merged onto it
# write.csv(temp_to_match,"data/templates/temp.csv",row.names=FALSE)

####################################################################################################
# Load template labelling meta data (can also use for matching?)
temp_labels <- read.csv("data/templates/temp_labels.csv")
temp_header_rows <- temp_labels %>%
  group_by(template) %>%
  summarise(header_rows=max(row))

####################################################################################################

# Get list of files that still need to be formatted 
conv_list <- list.files("data/gov_data","conversion_results",recursive=TRUE,full.names=TRUE)

to_conv <- readRDS(rev(sort(conv_list))[1])
# TODO filter out what has already been converted

# 
time_stamp <- max(to_conv$time_stamp)
dir.create(paste0("data/gov_data_form/",time_stamp),recursive=TRUE)

# to_conv <- readRDS(conv_list)
# list.files(paste0("data/gov_data_form/",time_stamp),full.names=TRUE) %>% file.remove()

conv_files <- to_conv %>%
  filter(conv_result==TRUE)
nq <- nrow(conv_files)
# nq <- 10

temp_names <- unique(temp_labels$template)

form_results <- NULL

# which(conv_files$conv_loc=="data/gov_data/250428144127/956.csv.rds")

for (q in 1:nq) {
  # file name
  fl <- conv_files$conv_loc[q]
  # load data
  rawdat <- readRDS(fl)
  # filter out empty sheets
  rawdat <- rawdat[map(rawdat,~!is.null(.x)) %>% unlist(F,F)]
  
  # Which template does each sheet best match?
  mres <- NULL
  for (tt in temp_names) {
    tt_m <- map(rawdat,~filter(.x,!is.na(chr)) %>% mutate(lab=text_sanitiser(chr))) %>%
      map(~right_join(.x,filter(temp_labels,template==tt))) %>%
      # map2(1:length(.),~summarise(.x,template=tt,i=.y,n=n(),m=sum(!is.na(file)))) %>%
      map2(1:length(.),~group_by(.x,col) %>% summarise(m=all(!is.na(file))) %>% ungroup() %>% summarise(template=tt,i=.y,n=n(),head=sum(col%in%1:3 & m),m=sum(m))) %>%
      bind_rows()
    mres <- bind_rows(mres,tt_m)
  }
  # get the best match
  m_proc <- mres %>%
    filter(m>9,head==3) %>% # match first 3 headers, and at least 10 headers in total
    group_by(i) %>%
    filter(m/n==max(m/n)) # best match
  nk <- nrow(m_proc)
  
  # handle no matching
  if (nk==0) {
    form_results <- bind_rows(form_results,data.frame(conv_loc=fl,form_result="No matches"))
    
  } else {
    
    # If there are matching sheets
    for (k in 1:nk) {
      # k = 1
      t_match = m_proc[k,]
      t_heads <- temp_header_rows %>%
        filter(template==t_match$template) %>%
        pull(header_rows)
      # which columns match?
      col_match <- rawdat[[t_match$i]] %>%
        mutate(lab=text_sanitiser(chr)) %>%
        right_join(filter(temp_labels,template==t_match$template)) %>%
        group_by(col) %>%
        filter(all(!is.na(file))) %>%
        ungroup() %>%
        pull(col)
      # do labelling
      # Note - step below should be refactored to run only once to speed things up slightly
      lab_dat <- filter(temp_labels,template==t_match$template) %>%
        select(col,template,group,sub_group,measure) %>%
        unique()
      formdat <- rawdat[[t_match$i]] %>%
        filter(col%in%col_match) %>%
        left_join(lab_dat) %>%
        # filter(!is.na(chr)) %>%
        filter(row>t_heads) %>%
        mutate(value=chr) %>%
        mutate(across(any_of(c("lgl","dbl")),~ifelse(is.na(value),as.character(as.numeric(.x)),value),.names="value")) %>%
        select(-any_of(c("chr","lgl","dbl"))) %>%
        select(-address,-col,-data_type) %>%
        filter(!is.na(value))
      
      file_nom <- conv_files$dl_loc[q]
      form_loc <- paste0(gsub("gov_data","gov_data_form",file_nom),"_",t_match$i,".rds")
      saveRDS(formdat,form_loc)
      tfr <- data.frame(conv_loc=fl,form_result=t_match$template,form_loc)
      print(paste0("q ",q," k ",k))
      print(tfr)
      form_results <- bind_rows(form_results,tfr)
    } # k
  }
  print(q/nq)
  
} # q

form_results_track <- full_join(to_conv,form_results) %>%
  mutate(form_result=ifelse(is.na(form_result),"Not attempted",form_result))

saveRDS(form_results_track,paste0("data/gov_data/",time_stamp,"/form_results_",time_stamp,".rds"))
# form_results_track <- readRDS(paste0("data/gov_data/",time_stamp,"/form_results_",time_stamp,".rds"))


###################################################################################################
# Tidy up and reformat data
ff <- form_results_track %>%
  filter(!is.na(form_loc))

allraw <- map2(ff$form_loc,ff$time_stamp,~readRDS(.x) %>% mutate(time_stamp=.y)) %>%
  bind_rows()

# Pull metadata
# Date
year_month <- allraw %>%
  filter(group%in%c("date")) %>%
  select(-measure) %>%
  pivot_wider(names_from=c("group","sub_group"),values_from=value) %>%
  mutate(Year=as.integer(date_year)) %>%
  mutate(Month=tolower(date_month) %>% str_trunc(3,ellipsis="") %>% factor(levels=tolower(month.abb),labels=month.name)) %>%
  select(-date_year,-date_month)

# Org stuff
dept_body <- allraw %>%
  filter(group%in%c("org")) %>%
  select(-measure) %>%
  pivot_wider(names_from=c("group","sub_group"),values_from=value) %>%
  rename(Body=org_body,Department=org_main)

formed_data <- allraw %>%
  filter(!group%in%c("date","org")) %>%
  left_join(year_month) %>%
  left_join(dept_body) %>%
  mutate(value=stri_trans_general(value,"latin-ascii") %>% iconv(to="latin1",sub="") %>% gsub("[^0-9\\.]","",.) %>% as.numeric(value))
  # mutate(value=value %>% gsub("[^0-9\\.]","",.) %>% as.numeric(value))

saveRDS(formed_data,paste0("data/output/formed_data_",time_stamp,".rds"))



