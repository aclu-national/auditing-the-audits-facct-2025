# Helper functions 
# load required packages

library(docstring)
library(tidyverse)
library(readr)
library(stringr)
library(here)
if(!require(tabulizer, quietly = TRUE)) library(tabulapdf)
library(janitor)
library(docstring)

extract_tables_from_audit <- function(audit_filename, 
                                      table_pg_numbers, audit_path = NULL) {
  #' Extract Tables from Audits
  #'
  #' @param audit_filename: filename (including filetype) of audit inside audits folder. Ignored if `audit_path` is provided.
  #' @param table_pg_numbers:  list of page numbers within the audit where the tables
  #' you want to extract are. if there are multiple tables on the same page, repeat
  #' the given page number as many times as there are tables on that page. 
  #' @param audit_path: optional filepath, to be used instead of `audit_filename`.
  #'
  #' @return set of dataframes, one per table extracted. tables will still likely need some 
  #' amount of customized cleaning/refining once extracted.
  
  if( is.null(audit_path) ) audit_path <- paste0("audits/pdfs/", audit_filename)
  
  audit_tbls <- extract_areas(
    file = here::here(audit_path), 
    pages = table_pg_numbers
  ) %>%
    map(as.data.frame) %>%
    map(row_to_names, row_number = 1)
}


calc_audit_bounds <- 
  function(audit_df, group_cols = c("sex", "race_ethnicity"), .comparator_group = NULL) {
    #' Use missingness counts to calculate bounds on selection rates and impact ratios based
    #' 
    #' Not all audit reports include information on missing data on protected characteristics.
    #' Some audits use algorithms like NameSor to guess demographic applicants' information, and thus report no missing data.
    #' When audits report the amount of missing data, we can calculate bounds on selection rates and impact ratios.
    #' This is impossible when audits do not report missing data or when the missing data is not reported by group.
    #' The bounds for these audits are `NA`.
    #' 
    #' @param audit_df A data frame with audit results. If it contains results from multiple audits, you must group by audit ID or a set of unique identifiers.
    #' @param group_cols A character vector of column names that define the protected characteristic groups.
    #' @param comparator_group Name of the column that flags all rows of comparator groups, marking the denominator for impact ratio calculations.
    #' The default value of `NULL` uses the most selected group as the comparator group.
    #' 
    #' @return A data frame with the same number of rows as the input, but with additional columns for the calculated bounds.
    #' 
    #' @examples
    #' library(dplyr)
    #' readr::read_csv("audits/audits_full.csv") %>% 
    #'   group_by(audit_id) %>% 
    #'   calc_audit_bounds()
    #'   
    #' readr::read_csv("audits/audits_full.csv") %>%
    #'   group_by(audit_id) %>%
    #'   mutate(
    #'      compgroup = result == max(result, na.rm = TRUE)
    #'   ) %>% 
    #'   group_by(audit_id) %>%
    #'   calc_audit_bounds(comparator_group = "compgroup")
    #'
    
    require(dplyr)
    
    groups_in <- group_vars(audit_df)
    
    # Calculate baseline demographics in observed data for alternative bounds calculation
    demo_df <- 
      audit_df %>%
      filter(across(all_of(group_cols), ~ . != "Missing/Unknown")) %>%
      group_by(pick(all_of(c(groups_in, "protected_char_group", group_cols)))) %>% 
      summarize(n = sum(number_of_applications)) %>% 
      group_by(pick(all_of(c(groups_in, "protected_char_group")))) %>% 
      mutate(
        prop = n / sum(n),
        n = NULL
      )
    
    audit_demo_df <- 
      left_join(
        audit_df, demo_df,
        by = unique(c(groups_in, "protected_char_group", group_cols)), 
        relationship = "one-to-many", unmatched = "error"
      )
    
    
    out <- 
      audit_demo_df %>% 
      rowwise() %>% 
      mutate(
        flag_miss = any(across(all_of(group_cols), ~ . == "Missing/Unknown"))
      ) %>%
      group_by(pick(all_of(c(groups_in, "protected_char_group")))) %>% 
      mutate(
        comparator_result = 
          ifelse(
            is.null(.comparator_group) | sum(which(.data[[.comparator_group]])) == 0 , 
            max(result, na.rm = TRUE), 
            result[which( .data[[.comparator_group]] )]
          ),
        
        n_miss = ifelse(!any(flag_miss), NA, number_of_applications[flag_miss]),
        
        # calculate selection rate if all missing were in the row's group...
        # ...and were selected:
        result_upper_bound = (n_selected_or_n_above_median + n_miss) / (number_of_applications + n_miss),
        # ...and were not selected:
        result_lower_bound = n_selected_or_n_above_median / (number_of_applications + n_miss),
        
        # calculate bounds for impact ratios
        impact_ratio_upper_bound = result_upper_bound / comparator_result,
        impact_ratio_lower_bound = result_lower_bound / comparator_result,
        
        result_upper_bound2 = (n_selected_or_n_above_median + n_miss * prop) / (number_of_applications + n_miss * prop),
        result_lower_bound2 = n_selected_or_n_above_median / (number_of_applications + n_miss*prop),
        impact_ratio_upper_bound2 = result_upper_bound2 / comparator_result,
        impact_ratio_lower_bound2 = result_lower_bound2 / comparator_result,
        
        prop = NULL
      )
    
    return(out)
  }

case_regex <- 
  function(.x, ..., .default = NULL, .ptype = NULL, .size = NULL) {
    #' Like case_match, but with regular expressions
    #' 
    #' This function combines [dplyr::case_when()] and [stringr::str_detect()] into a function that works like [dplyr::case_match()], 
    #' but searching for regex matches in `.x`, instead of full string matches.
    #' The LHS of the formula is a regular expression, and the RHS is the value to map to.
    #' Order the formula statements carefully according to the rules in [dplyr::case_when()].
    #' 
    #' @param .x A character vector to search for regex matches.
    #' @param ... A set of formulas, each with a regular expression on the LHS and its output value on the RHS.
    #' @inheritParams dplyr::case_when
    #' 
    #' @return A vector of the same length as `.x`, with the values mapped according to the regular expressions.
    
    
    args <- rlang::list2(...)
    args <- dplyr:::case_formula_evaluate(args = args, default_env = rlang::caller_env(), 
                                          dots_env = rlang::current_env(), error_call = rlang::current_env())
    
    # change regex in LHS of formula to str_detect() condition
    conditions <- 
      lapply(
        args$lhs, 
        function(regex) stringr::str_detect(.x, regex)
      )
    values <- args$rhs
    
    .size <- vctrs::vec_size_common(!!!conditions, !!!values, .size = .size)
    conditions <- vctrs::vec_recycle_common(!!!conditions, .size = .size)
    
    values <- vctrs::vec_recycle_common(!!!values, .size = .size)
    dplyr:::vec_case_when(conditions = conditions, values = values, conditions_arg = "", 
                          values_arg = "", default = .default, default_arg = ".default", 
                          ptype = .ptype, size = .size, call = rlang::current_env())
  }


# Mostly for interactive use / code development

glue_here <- function(...) glue::glue(here::here(...))

source_rmd <- function(file){
  
  #' Source Rmd files
  #' Use [knitr::purl()] to extract code to a temporary file, then source it.
  #'
  #' @param file string, path to Rmd file
  #' @export
  
  tf <- tempfile(fileext = ".Rmd")
  knitr::purl(input = file, output = tf)
  
  source(tf, echo = TRUE, local = knitr::knit_global())
}