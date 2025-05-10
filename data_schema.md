## Data Schema

Our dataset, [`audits_full.csv`](audits/audits_full.csv) includes the following columns, most of which are created in our data extraction code (see below for examples), and some of which were produced with subsequent data cleaning we conducted. Many columns represent information required to be reported in bias audit summaries under LL144 and other columns we created based on patterns we noticed as we reviewed the audits: 

- **audit_id:** Identifier for bias audit results for a particular tool and position. Each audit is a unique combination of deploying entity, vendor, year, auditor, tool ID, and employment position.
- **audit_report_id:** Identifier for document(s) posted on an employer’s, employment agency’s, or vendor’s website and characterized as a bias audit with a reference to LL144. Each audit report may contain multiple audits and is a unique
combination of deploying entity, tool vendor, year, and auditor.
- **number_of_applications:** The number of applicants or candidates in a particular group assessed by the tool, as reported in the audit. When the underlying audit doesn't say how many applications assessed by the tool were missing demographic data, use value of 0 to signify there were no applications with missing demographic data (either because the audit says that explicitly or because the audit used simulated data) and use a value of NA to mean it's not clear/not specified how many applications had missing demographic data. 
- **n_selected_or_n_above_median:** The number of applicants or candidates in a particular group assessed by the tool who are selected to move forward or assigned a score above the median score, as reported in the audit. See [LL144](https://rules.cityofnewyork.us/wp-content/uploads/2023/04/DCWP-NOA-for-Use-of-Automated-Employment-Decisionmaking-Tools-2.pdf) for definitions and our paper for more context. 
- **result:** The selection rate[^1] or scoring rate[^2] for a given group, as reported in the audit, which generally should be equal to `n_selected_or_n_above_median` / `number_of_applications` (though this is not always the case -- see paper for more detail).
- **impact_ratio:** The impact ratio for a given group, as reported in the audit, which generally should be equal to `result` for this group divided by the highest `result` of any group in the analysis of the tool in question (though this is not always the case -- see paper for more detail).
- **protected_char_group:** Type of protected characteristic, either "race", "sex", or "intersectional." 
- **race_ethnicity:** Specific race/ethnicity value, standardized to align with the 2023 EEO-1 categories,[^3] or "Total" (for analyses that are not broken down by race/ethnicity) or "Missing/Unknown" (for applicants whose race/ethnicity is  unknown).
- **sex:** Specific sex, standardized to align with the 2023 EEO-1 categories,[^3] or "Total" (for analyses that are not broken down by sex or "Missing/Unknown" (for applicants whose sex is  unknown).
- **auditor:** Organization conducting the bias audit of the automated tool(s) (independent from the deployer/vendor of the tool under audit). 
- **deploying_entity:** Organization posting the bias audit on their website.
- **tool_id:** Name or identifier for the tool being audited, if provided. `tool_id` may be the same as `tool_vendor` in some instances where a more descriptive tool name is not provided in the audit. 
- **tool_vendor:** Organization selling or licensing the automated tool being audited. Some vendors post audits directly, so some tool vendors are also deploying entities in our dataset. 
- **position:** Specific roles or types of job positions that the tool is used for, including for the data used in the audit. May be quite general/not descriptive (e.g., "multiple jobs" or "Unknown") or specific. 
- **type_of_tool:** Either "selection" or "scoring."
- **selection_or_scoring_rate:** One of "Scoring", "Selection", "Selection, top" or "Selection, top and middle." Several audits include results for tools that categorize applicants into one of three tiers (e.g., "top," "middle" and "bottom") and present results for the same tool, data, and groups with two different definitions of "selection," specifically one definition where applicants in the "top" tier are considered as having been selected (and those in the "middle" and "bottom" tiers are not), and one where applicants in either the "top" or "middle" tiers are considered as having been selected. In these occurrences, we include one row for each threshold definition, and this variable is used to identify/distinguish between these instances. 
- **audit_data_start_date:** Start date of data used for audit; may be "Unknown."
- **audit_data_end_date:** End date of data used for audit; may be "Unknown." 
- **date_of_first_use:** The rules of Local Law 144 require that employers and employment agencies include in the bias audit the "distribution date" of the AEDT, which is defined as "the date the employer or employment agency began using a specific AEDT." This date is referred to in some audits as the "date of first use." Often times, this date does not appear to be included in published audits, and in those instances, we record the date of first use as "Unknown." In general, for dates that include a month and year but no day, we record the day as the first of the month. 
- **year_of_audit_result:** Year of audit result. 
- **link_to_result:** Link to audit result. 
- **data_type:** Type of data used for the audit, either "historical", "test", or "unknown". 

The dataset also includes various other columns we created in the data cleaning and analysis process; for more context on these variables, feel free to reach out to us. 

[^1]: The Local Law 144 Rules state that "'Selection rate' means the rate at which individuals in a category are either selected to move forward in the hiring process or assigned a classification by an AEDT." See [LL144 Rules](https://rules.cityofnewyork.us/wp-content/uploads/2023/04/DCWP-NOA-for-Use-of-Automated-Employment-Decisionmaking-Tools-2.pdf) for more detail.
[^2]: The Local Law 144 Rules state that "Scoring Rate' means the rate at which individuals in a category receive a score above the sample’s median score, where the score has been calculated by an AEDT." See [LL144 Rules](https://rules.cityofnewyork.us/wp-content/uploads/2023/04/DCWP-NOA-for-Use-of-Automated-Employment-Decisionmaking-Tools-2.pdf) for more detail.
[^3]: LL144 requires that "a bias audit of an AEDT must calculate the selection rate for each race/ethnicity and
sex category that is required to be reported on to the U.S. Equal Employment Opportunity Commission ("EEOC")
pursuant to the EEO Component 1 report." See [LL144 Rules](https://rules.cityofnewyork.us/wp-content/uploads/2023/04/DCWP-NOA-for-Use-of-Automated-Employment-Decisionmaking-Tools-2.pdf) for more detail.
