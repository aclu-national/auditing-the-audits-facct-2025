# Replication Resources and Materials for *Auditing the Audits,* published at FAccT 2025

This repository includes replication materials and other resources from [Auditing the Audits: Lessons for Algorithmic Accountability from Local Law 144’s Bias Audits](https://doi.org/10.1145/3715275.3732004), published at FAccT 2025. The repository includes a dataset with the results of all the bias audits in our study's sample and code for extracting and combining bias audit results to support future auditing efforts. See [here](https://github.com/aclu-national/tracking-ll144-bias-audits/blob/main/README.md) for a crowd-sourced tracker of Local Law 144 Bias Audits. 

## Bias Audits Dataset 

[`audits_full.csv`](audits/audits_full.csv) is the dataset we use in our analyses, which includes joined, cleaned, and standardized data we extracted from 116 bias audits conducted in connection with New York City's [Local Law 144](https://www.nyc.gov/site/dca/about/automated-employment-decision-tools.page) (all those made publicly available to our knowledge as of November 2024). Each row represents a result reported in a LL144 bias audit for a particular group or intersection of groups, and also includes columns noting the deploying entity, auditor, year, and other metadata. 

Some of the information included in our schema—such as the race, sex, or intersectional group for each result, as well as the number of applications, number of applicants selected or above the median score, selection rate, and impact ratio for that group—were often reported in tables in the underlying bias audits. Other information, such as the type of data used for the audit or the time frame in which the audit’s data was collected, was usually noted in audits’ text, footnotes, or missing altogether. As a result, our data extraction required automatic tabular data extraction (from generally non-machine-readable formats) as well as manual data entry of information that was typically included in the text of the audits (see below for more detail and resources for extracting data from new audits in a similar manner). See our [data schema](data_schema.md) for more details. 

## Paper Results

Materials to replicate the analyses from our FAccT 2025 paper are in [`paper_results.Rmd`](code/paper_results.Rmd), which saves resulting plots to the `figures` folder. 

## Resources for Extracting Audits

For researchers interested in extracting tables and other information from LL144 bias audits (or similar algorithm audits), we include [starter code](code/extraction_template.Rmd) and [helper functions](code/helpers.R) for extracting information from tables and transforming audit contents to fit a common data schema. This code should work with either [`tabulapdf`](https://cran.r-project.org/web/packages/tabulapdf/tabulapdf.pdf) or `tabulizer`. Some users may have issues with `tabulizer`, so `tabulapdf` works as an alternative. The [helper functions](code/helpers.R) file includes various convenience functions, functions used in our analyses (in [`paper_results.Rmd`](code/paper_results.Rmd)) and helper script for extracting tables from LL144 audits.

### Audit Extraction Tips and Tricks

A suggested workflow for extracting information from multiple audits:

- Save audits as pdfs (e.g., within a subfolder titled `pdf` in the `audits` folder for instance)
- Create a copy of the [`extraction_template.Rmd`](code/extraction_template.Rmd) file for each audit, and modify as needed for each audit, saving extracted outputs to another subfolder (e.g., `extracted_tables` within the audits folder). The extraction template is an RMarkdown to allow for periodic inspection of outputs and to easily capture notes about the nuances of each audit and choices made in the data extraction process. 
- Create a parent RMarkdown (e.g., `ll144_table_extraction.Rmd`) and, for each audit, add a chunk to the file to knit the associated extraction Rmd. 

#### Tricky tables

Even standard-looking tables can sometimes throw off the extraction because of multi-line headers, multi-line cells, or other formatting issues. If the extraction is correctly reading cell values, but messing up the column or row format, it's worth trying these steps:

1) Use the `locate_areas()` function to find the area of the table you want to extract. Store the output as a separate object.
2) Look up the x-coordinate for the beginning of each column. If the columns are not spaced the same in every table, you'll need to adjust the coordinates for each one.
3) Use the `extract_tables()` function directly with `method = "stream"`, passing the results of step (1) to the `area` parameter and the results of step (2) to the `columns` parameter.

#### Manual Extraction

Some tables might be easier and more efficient to extract manually (e.g., copying and pasting). A suggested flow for copying and pasting and storing outputs that aligns with the suggested OCR extraction flow would be to: 

- Create a copy of the [`extraction_template.Rmd`](code/extraction_template.Rmd) file, name it based on the audit, and modify as needed. Even though you're going to copy and paste the data, the markdown can contain code you use to clean the data after copying and pasting, notes about data cleaning choices you made, or serve as a record for future use that the extraction method was copying and pasting. 
- For the audit in question, create a subfolder with the name of the audit in the `extracted_tables` subfolder of the `audits` folder (if one doesn't already exist).
- Save the outputs as CSV files with appropriate names within that audit-specific folder in `extracted_tables`, or in `interim_data` for copy-pasted data that needs some cleaning to get it into the right format, and in the corresponding RMD, clean and save the data as a CSV in `extracted_tables`. 
- Update the parent markdown doc by adding a chunk to the file to knit the associated extraction Rmd. 

## Additional Resources and Questions

For additional resources, data extraction troubleshooting, or questions about the repository, you can [email us](mailto:analytics_inquiry@aclu.org). 

## License

The tracker in this repository is licensed under [CC BY-NC 4.0](http://creativecommons.org/licenses/by-nc/4.0/).
