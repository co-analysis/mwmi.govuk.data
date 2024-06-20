# Publications not showing up
pubs <- c("/government/publications/dluhc-workforce-management-information-april-2024","/government/publications/mod-workforce-management-information-january-to-december-2024")
fils <- c("https://assets.publishing.service.gov.uk/media/6641f1524f29e1d07fadc5e6/DLUHC_Group_Workforce_Management___March_2024.csv","https://assets.publishing.service.gov.uk/media/6661c6a17322adea1a895d35/DLUHC_Group_Workforce_Management_April.csv","https://assets.publishing.service.gov.uk/media/66168cdb56df202ca4ac05aa/MOD_Workforce_Management_Information_January_2024.csv")

# Did the search find them?
which(gov_results$link%in%pubs)

# Did the search find the files?
which(file_links%in%fils)

# Did the files download?
gov_dl_results[which(file_links%in%fils),]

# Did they match to a template?
rnom <- rds_files[which(gov_files%in%(gov_dl_results[which(file_links%in%fils),]$dl_location))]
match_format_results[which(gov_rds%in%rnom)]
