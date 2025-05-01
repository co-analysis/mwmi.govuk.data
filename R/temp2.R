to_conv <- readRDS(conv_list)


conv_files <- to_conv %>%
  filter(conv_result==TRUE)
nq <- nrow(conv_files)
# nq <- 10

temp_names <- unique(temp_labels$template)

form_results <- NULL

for (q in 1919:nq) {
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
      map2(1:length(.),~summarise(.x,template=tt,i=.y,n=n(),m=sum(!is.na(file)))) %>%
      bind_rows()
    mres <- bind_rows(mres,tt_m)
  }
  # get the best match
  m_proc <- mres %>%
    filter(m>0,m/n>.5) %>% # match at least half of headers
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
      # which columns match?
      col_match <- rawdat[[t_match$i]] %>%
        right_join(filter(temp_labels,template==t_match$template)) %>%
        group_by(col) %>%
        filter(all(!is.na(file))) %>%
        ungroup() %>%
        pull(col)
      # do labelling
      formdat <- rawdat[[t_match$i]] %>%
        filter(col%in%col_match) %>%
        left_join(filter(temp_labels,template==t_match$template) %>% select(-row,-address)) %>%
        # filter(!is.na(chr)) %>%
        select(-row,-col,-data_type)
      
      file_nom <- conv_files$dl_loc[q]
      form_loc <- paste0(gsub("gov_data","gov_data_form",file_nom),"_",t_match$i,".rds")
      saveRDS(formdat,form_loc)
      form_results <- bind_rows(form_results,data.frame(conv_loc=fl,form_results=t_match$template,form_loc))
    } # k
  }
  print(q/nq)
  
} # q

