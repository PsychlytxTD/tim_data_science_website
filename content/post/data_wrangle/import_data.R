import_data<- function() {

  csv_files<- fs::dir_ls(here(), regexp = "\\.csv$")

  pain_data_raw<- csv_files %>% purrr::map( ~readr::read_csv(.x, col_types = cols(.default = "c"))) %>%
    purrr::set_names("early_19", "mid_17", "mid_18")

  data_comparison<- janitor::compare_df_cols(pain_data_raw)

  matching_vars<- data_comparison %>% dplyr::filter_at(vars(-column_name), all_vars(!is.na(.))) %>%
    dplyr::select(column_name) %>% dplyr::pull(1)

  pain_data_complete<- pain_data_raw %>% purrr::map(~dplyr::select(.x, matching_vars))

  joined_data<- dplyr::bind_rows(pain_data_complete)

}
