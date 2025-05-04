source("pack/all_packages.R",local=TRUE)
clip_tab <- workforcedata::clip_tab

# timestamps
ts <- list.files("data/gov_search_results") %>% gsub(".rds","",.)

# Search results
search_results <- paste0("data/gov_search_results/",ts,".rds") %>%
  map(readRDS) %>%
  bind_rows()
head(search_results,2)


# data links
data_links <- map(ts,~readRDS(paste0("data/gov_data_links/",.x,".rds"))) %>%
  bind_rows()
head(data_links,2)

# dl_results
# # conversion results
# conv_results <- paste0("data/gov_data/",ts,"/conversion_results_",ts,".rds") %>%
#   map(readRDS) %>%
#   bind_rows()

# Formatting results
form_results <- paste0("data/gov_data/",ts,"/form_results_",ts,".rds") %>%
  map(readRDS) %>%
  bind_rows()
head(form_results,2)

# Has everything been found?
file_targets <- data.frame(targ=c('https://assets.publishing.service.gov.uk/media/680b7cdc5072e9b7db83cc93/Workforce_Management_Information_2024-25_-_AGO__GLD__HMCPSI.ods', 'https://assets.publishing.service.gov.uk/media/680badcd5072e9b7db83ccc0/_March_2025_MWMI_template.csv', 'https://assets.publishing.service.gov.uk/media/680b608afaff81833fcae8b2/Charity_Commission_monthly_workforce_management_information_March_2025.csv', 'https://assets.publishing.service.gov.uk/media/680b45b7532adcaaab3a2790/MWMI_March.csv', '-', 'https://assets.publishing.service.gov.uk/media/67ebbbc2632d0f88e8248aec/dbt-headcount-and-payroll-data-for-february-2025.csv', 'https://assets.publishing.service.gov.uk/media/67ebcd25632d0f88e8248b0c/_February_2025_MWMI.csv', 'https://assets.publishing.service.gov.uk/media/67ebe89598b3bac1ec299aec/February_2025_DfE_Family_Monthly_Workforce_Management_Information__MI_.csv', 'https://assets.publishing.service.gov.uk/media/67e17644d8e313b503358ce7/DESNZ_February_2025_MWMI_Template.csv', 'https://assets.publishing.service.gov.uk/media/6800d0bf0b24153af1e7c6eb/Defra_MWMI_March_2025.csv', 'https://assets.publishing.service.gov.uk/media/67e1893664220b68ed6a704f/dsit-workforce-management-information-february-2025.csv', 'https://assets.publishing.service.gov.uk/media/67f5420732b0da5c2a09e197/dft-mwmi-feb-2025.csv', 'https://assets.publishing.service.gov.uk/media/6808d85a4dd7e0f8897a622d/dwp-workforce-management-march-2025.csv', 'https://assets.publishing.service.gov.uk/media/67f672a7b7e44efc70acc409/dhsc-workforce-management-information-february-2025.csv', 'https://assets.publishing.service.gov.uk/media/67ffb404393a986ec5cf8e34/FSA_March_2025_MWMI_template.csv', 'https://assets.publishing.service.gov.uk/media/6809f59e8c1316be7978e7d1/FCDO_workforce_management_information_March_2025.csv', '-', 'https://assets.publishing.service.gov.uk/media/67e1be4c0114b0b86e59f524/HMRC_headcount_and_payroll_data_for_February_2025.csv', 'https://assets.publishing.service.gov.uk/media/6808c73a4dd7e0f8897a6217/March_2025_MWMI_template.xlsx', 'https://assets.publishing.service.gov.uk/media/680f5182b0d43971b07f5be1/Workforce+Management+Information+March+2025+_ODS_.ods', 'https://assets.publishing.service.gov.uk/media/67e6b18496745eff958ca01a/MHCLG_workforce_management_information__February_2025.csv', 'https://assets.publishing.service.gov.uk/media/67ebbfb653fa8521c3248af1/MOD_workforce_management_information_February_2025.csv', 'https://assets.publishing.service.gov.uk/media/67d0099b74b001c38a02879b/MoJ_headcount_and_payroll_data_for_December_2024.ods', '-', '-', 'https://assets.publishing.service.gov.uk/media/66e83992f8082e9740881b7a/NIO_s_Headcount_and_Payroll_Data__March_2024.csv', 'https://assets.publishing.service.gov.uk/media/680b5581521c5b6f2883cc50/MWMI_March_2025_Workforce_Management_Information.csv', '-', 'https://assets.publishing.service.gov.uk/media/67fd1d85694d57c6b1cf8cf4/2024_to_2025_MWMI_Ofqual-2.csv', '-', 'https://www.orr.gov.uk/sites/default/files/2025-04/workforce-data-march-2025.csv', '-', 'https://assets.publishing.service.gov.uk/media/67cb2187ade26736dbfa007e/UK_Export_Finance_headcount_data_February_2025.xlsx', 'https://assets.publishing.service.gov.uk/media/680a432bbc942a09683a276a/MAR_25_MWMI_updated_template.xlsx', '-', '-', 'https://assets.publishing.service.gov.uk/media/680b6968b0d43971b07f5b80/Wales_Office_WMI_-_March_2025.csv')) %>%
  mutate(i=1:n()) %>%
  mutate(data_links=targ) %>%
  left_join(form_results)

file_targets %>%
  group_by(i,targ) %>%
  summarise(found=any(!is.na(time_stamp)),dl=any(dl_result=="Successful"),formed=paste0(form_result,collapse=", ")) %>%
  clip_tab()

file_targets %>%
  filter(!is.na(time_stamp),dl_result!="Successful")



