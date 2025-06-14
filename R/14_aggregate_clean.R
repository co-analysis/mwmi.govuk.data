# load libraries
source("pack/all_packages.R",local=TRUE)

df <- list.files("data/output","^formed_data_[0-9]{12}.rds",full.names=T)

# Clean up org names
org_clean <- function(x) {
  x %>%
    gsub(",","",.) %>%
    gsub(" \\([A-Z]+\\)$","",.) %>%
    gsub("Inovation","Innovation",.) %>%
    gsub(" For "," for ",.) %>%
    gsub("&"," and ",.) %>%
    gsub(" +"," ",.)
  }

# Load all formatted data
alldata <- map(df,readRDS) %>%
  bind_rows() %>%
  mutate(Department=org_clean(Department)) %>%
  mutate(Body=org_clean(Body))
ts <- unique(alldata$time_stamp)

# Timestamps of publication
# data_links, updated_at, time_stamp
m0 <- map(ts,~readRDS(paste0("data/gov_data_links/",.x,".rds"))) %>%
  bind_rows()
  
# Index file
# data_links,time_stamp, dl_loc
m1 <- map(ts,~readRDS(paste0("data/gov_data/",.x,"/dl_results_",.x,".rds"))) %>%
  bind_rows()
  
mm <- select(m0,data_links,updated_at,public_timestamp,time_stamp) %>%
  full_join(select(m1,data_links,time_stamp,dl_loc,data_links)) %>%
  select(file=dl_loc,time_stamp,updated_at,public_timestamp,data_links)

dupes0 <- alldata %>%
  left_join(mm) %>%
  select(Year,Month,Department,Body,file,file_type,sheet,time_stamp,updated_at,public_timestamp,data_links) %>%
  unique()

dd <- dupes0 %>%
  group_by(Year,Month,Department,Body) %>%
  filter(updated_at==max(updated_at)) %>%
  filter(public_timestamp==max(public_timestamp)) %>%
  mutate(n=n()) %>%
  filter(n==1 | (n>1 & !any(file_type=="csv")) | (n>1 & file_type=="csv")) %>%
  mutate(n=n()) %>%
  filter(n==1 | (n>1 & !any(file_type=="xlsx")) | (n>1 & file_type=="xlsx")) %>%
  mutate(n=n()) %>%
  filter(n==1 | (n>1 & !any(file_type=="xls")) | (n>1 & file_type=="xls")) %>%
  mutate(n=n()) %>% # note, remaining duplication appears to be from data errors from depts
  # {.} %$% table(n)
  mutate(dups=duplicated(data.frame(Year,Month,Department,Body))) %>%
  filter(!dups)

# dd %>% select(file) %>% left_join(rename(m1,file=dl_loc)) %>% left_join(m0) %>% View()

a1 <- alldata %>%
  filter(if_all(all_of(c("value","Year","Month","Body","Department","org_type")),~!is.na(.x)))

# Drop duplication
a2 <- inner_join(a1,dd)

a2 %>%
  # filter(if_all(all_of(c("value","Year","Month","Body","Department")),~!is.na(.x))) %>%
  select(Year,Month,Body,Department,group,sub_group,measure,file,time_stamp) %>%
  unique() %>%
  group_by(Year,Month,Body,Department,group,sub_group,measure) %>%
  # arrange(Year,Month,Body,Department,group,sub_group,measure) %>%
  mutate(n=n()) %$% table(n)


# head(a2)


# a3 <- a2 %>%
#   select(group,sub_group,measure,value,file,org_type,Month,Year,Body,Department) %>%
#   mutate(costs=NA,fte_total=NA)

a3 <- a2 %>%
  select(group,sub_group,measure,value,org_type,Month,Year,Body,Department)


ad10 <- a3
# output as per previous
ad10 %>%
  # select(group,sub_group,measure,value,file,org_type,Month,Year,Body,Department) %>%
  # mutate(costs=NA,fte_total=NA) %>%
  saveRDS("data/output/cleaned_data_trial.RDS")
ad10 %>%
  write.csv("data/output/cleaned_data_trial.csv",row.names=FALSE)
