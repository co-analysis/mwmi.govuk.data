# library(tidyverse)
# library(magrittr)
# library(readxl)
# library(tidyr)

if (continue_progress) {
  ################################################################################
  # Load formatted but unclean data
  # rawdat <- readRDS("data/output/formed_data.RDS")
  rawdat <- dat # still in memory from previous script
  
  # Extract blank data set that will be used as a placeholder where there is no return
  blankdat <- rawdat %>% filter(org_main=="blank")
  
  dat1 <- rawdat %>%
    filter(org_main!="blank") %>% # filter out the blank template placeholder
    mutate(Month=factor(date_month,levels=month.name)) %>%
    mutate(Year=as.integer(date_year)) %>%
    select(-date_year,-date_month) %>%
    filter(!is.na(Month),!is.na(Year))
  
  ################################################################################
  # Drop empty returns
  todrop <- dat1 %>%
    group_by(file,Year,Month) %>%
    summarise(v=sum(value,na.rm=T)) %>%
    filter(v==0)
  
  dat2 <- dat1 %>%
    left_join(todrop) %>%
    filter(is.na(v)) %>%
    select(-v)
  
  ################################################################################
  # Clean up and standardise dept coding
  
  # list.files("data/metadata","^dep_orgs")
  # todo: list all files and select most recent
  # Import standard names and meta data
  main_deps <- read_xlsx("data/metadata/main_deps 2021 09 01.xlsx")
  
  # Clean up dept/body names
  body_cleaner <- function(x) {
    x %>%
      gsub(" \\(.*\\)$","",.) %>%
      gsub(" and "," & ",.)
  }
  # Strip down extras to help with matching
  body_stripper <- function(x) {
    x %>%
      body_cleaner %>%
      tolower %>%
      gsub("[^a-z &]","",.)
  }
  
  # Set up data for matching into dataset
  main_match <- main_deps %>%
    mutate(depmatch=body_stripper(alternatives)) %>%
    select(Department=dept,depmatch)
  
  # Merge in, matching on simplified name & alternatives
  dat2 <- dat2 %>%
    mutate(depmatch=body_stripper(org_main),Body=body_cleaner(org_body)) %>%
    left_join(main_match) %>%
    select(-depmatch,-org_main,-org_body)
  
  # Error reporting and filtering out
  dat2 %>%
    filter(is.na(Department)) %>%
    write.csv("data/gov_errors/maindept_matching_errors.csv")
  dat3 <- filter(dat2,!is.na(Department))
  
  ################################################################################
  # Drop duplicate returns
  
  # Check for and remove duplication by filetype
  dat4 <- dat3 %>%
    mutate(filetype=gsub(".*\\.([a-z]{3,4})$","\\1",tolower(file))) %>%
    group_by(Department,Year,Month) %>%
    mutate(filetype_to_use=unique(filetype)[1]) %>% # if multiple filetypes are published, select only one
    filter(filetype==filetype_to_use) %>%
    select(-filetype,-filetype_to_use) %>%
    ungroup()
  
  # Check for duplication by file
  dat4 <- dat4 %>%
    group_by(Department,Year,Month) %>%
    mutate(duples=length(unique(file))) %>%
    ungroup()
  # Save errors
  dat4 %>%
    filter(duples>1) %>%
    write.csv("data/gov_errors/file_duplication.csv")
  # Drop extra files
  dat5 <- dat4 %>%
    mutate(filecode=gsub(".*gov_files/([0-9]+)/.*","\\1",file) %>% as.integer) %>%
    arrange(-filecode) %>% # extract and reverse sort by file code to bring most recent upload to the top
    group_by(Department,Year,Month) %>%
    mutate(file_to_use=unique(file)[1]) %>%
    filter(file==file_to_use) %>%
    select(-file_to_use,-duples,-filecode) %>%
    ungroup()
  
  ################################################################################
  # Fill in NA values for key departments that haven't published
  # Dates that need placeholders
  dates_to_fill <- dat5 %>%
    select(Month,Year) %>%
    unique()
  
  # Blank copy of the template
  blank_template <- blankdat %>%
    mutate(value=0*NA) %>%
    select(group,sub_group,measure,value,date_year,date_month) %>%
    mutate(match_num=as.numeric(date_year)*100+match(date_month,month.name))
  # Set of dates that the blank data applies from
  blank_data_dates <- blank_template$match_num %>%
    unique %>%
    sort
  
  # Departments to make placeholders for
  # Todo: search for most recent file definition
  showmissing <- main_deps %>%
    filter(showmissing=="yes") %>%
    select(dept,org_body,org_type) %>%
    rename(Department=dept) %>%
    unique
  
  # Dept returns that already exist
  deptdates_not_to_fill <- dat5 %>%
    select(Month,Year,Department) %>%
    unique %>%
    filter(Department %in% showmissing$Department)
  
  # Set up blanks to add in
  deptdates <- merge(dates_to_fill,showmissing %>% select(Department)) # all date * dept combos
  deptdates_to_fill <- setdiff(deptdates,deptdates_not_to_fill) %>% # filter out data that already exists
    mutate(date_num=Year*100+match(Month,month.name)) %>%
    filter(date_num>=min(blank_data_dates))
  for (d in blank_data_dates) deptdates_to_fill <- mutate(deptdates_to_fill,match_num=ifelse(date_num>=d,d,match_num))
  
  blank_dates <- merge(deptdates_to_fill,select(blank_template,-date_year,-date_month)) %>% # merge in all the NA data rows for each dept * date
    select(-match_num)
  
  # Add in Body and org_type from metadata
  blank_placeholders <- showmissing %>%
    mutate(depmatch=body_stripper(Department),Body=body_cleaner(org_body)) %>%
    select(depmatch,org_type,Body) %>%
    right_join(blank_dates %>% mutate(depmatch=body_stripper(Department))) %>%
    select(-depmatch)
  
  # Add in to data set
  dat6 <- bind_rows(dat5,blank_placeholders)
  
  ################################################################################
  # Cost per FTE
  # Payroll
  payrollftetotal <- dat6 %>%
    filter(group=="payroll",sub_group!="total",measure=="fte") %>%
    group_by(Department,Body,org_type,Year,Month) %>%
    summarise(fte_total=ifelse(any(!is.na(value)),sum(value,na.rm=T),NA))
  payrollcosts <- dat6 %>%
    filter(group=="payroll costs",sub_group!="total") %>%
    select(Department,Body,Year,Month,org_type,sub_group,costs=value)
  payrollcostperfte <- full_join(payrollftetotal,payrollcosts) %>%
    # mutate(value=costs/fte_total,group="payroll costs",measure="costperfte") %>%
    mutate(group="payroll costs",measure="costperfte") %>%
    select(group,sub_group,measure,costs,fte_total,org_type,Month,Year,Body,Department)
  
  # Non payroll
  nonpayrollcosts <- dat6 %>%
    filter(group=="non payroll costs",sub_group!="total") %>%
    select(Department,Body,Year,Month,org_type,sub_group,costs=value)
  nonpayrollftetotal <- dat6 %>%
    filter(group=="non payroll",sub_group!="total",measure=="fte") %>%
    mutate(sub_group=ifelse(sub_group=="consultants","consultants","contingent")) %>%
    group_by(Department,Body,org_type,Year,Month) %>%
    summarise(fte_total=ifelse(any(!is.na(value)),sum(value,na.rm=T),NA))
  nonpayrollcostperfte <-full_join(nonpayrollftetotal,nonpayrollcosts) %>%
    # mutate(value=costs/fte_total,group="non payroll costs",measure="costperfte") %>%
    mutate(group="non payroll costs",measure="costperfte") %>%
    select(group,sub_group,measure,costs,fte_total,org_type,Month,Year,Body,Department)
  
  dat7 <- bind_rows(dat6,payrollcostperfte,nonpayrollcostperfte)
  
  ################################################################################
  
  saveRDS(dat7,"data/output/cleaned_data.RDS")
}

