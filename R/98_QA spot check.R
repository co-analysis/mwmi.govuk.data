# Publications not showing up
# pubs <- c("/government/publications/dluhc-workforce-management-information-april-2024","/government/publications/mod-workforce-management-information-january-to-december-2024")
# fils <- c("https://assets.publishing.service.gov.uk/media/6641f1524f29e1d07fadc5e6/DLUHC_Group_Workforce_Management___March_2024.csv","https://assets.publishing.service.gov.uk/media/6661c6a17322adea1a895d35/DLUHC_Group_Workforce_Management_April.csv","https://assets.publishing.service.gov.uk/media/66168cdb56df202ca4ac05aa/MOD_Workforce_Management_Information_January_2024.csv")

pubs <- c("/government/publications/charity-commission-monthly-workforce-management-information-2024-to-2025",
          "/government/publications/dft-workforce-management-information-october-2024",
          "/government/publications/dft-workforce-management-information-september-2024")
fils <- c("https://assets.publishing.service.gov.uk/media/677fb68ed721a08c006655ee/Charity_Commission_monthly_workforce_management_information_November_2024.csv",
          "https://assets.publishing.service.gov.uk/media/6746cabcb58081a2d9be9785/dft-workforce-management-information-october-2024.csv",
          "https://assets.publishing.service.gov.uk/media/672105283ce5634f5f6ef42f/dft-workforce-management-information-september-2024.csv")

# Did the search find them?
which(gov_results$link%in%pubs)

# Did the search find the files?
which(file_links%in%fils)

# Did the files download?
gov_dl_results[which(file_links%in%fils),]

# Did they match to a template?
rnom <- rds_files[which(gov_files%in%(gov_dl_results[which(file_links%in%fils),]$dl_location))]
match_format_results[which(gov_rds%in%rnom)] %>%
  bind_rows()

# formatted data?
file_i <- gsub("data/gov_files/([0-9]+)\\.rds","\\1",rnom)
d_d <- dat %>% 
  mutate(i=gsub("data/gov_files/([0-9]+)\\..*","\\1",file)) %>%
  filter(i%in%file_i) %>%
  group_by(file,org_main,date_year,date_month,org_body) %>%
  summarise(n=n())
d_d %>%
  print(n=50)

# Cleaned data
d_filt <- d_d %>%
  ungroup() %>%
  mutate(Department=org_main,Year=as.integer(date_year),Month=factor(date_month,levels=month.name)) %>%
  select(Department,Year,Month) %>%
  unique()

dat4 %>%
  right_join(d_filt) %>%
  group_by(Department,Month,Year,file) %>%
  summarise(n=n())

dat7 %>%
  right_join(d_filt) %>%
  group_by(Department,Month,Year,file) %>%
  summarise(n=n())

ddd <- readRDS("data/output/cleaned_data.RDS")

ddd %>%
  right_join(d_filt) %>%
  group_by(Department,Month,Year,file) %>%
  summarise(n=n())


ddd %>%
  filter(Department=="Charity Commission",Month=="November",Year==2024) %>%
  print(n=50)


# a = dat7
