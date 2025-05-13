# Aggregation of monthly workforce management information

This repository holds an automatic aggregation of monthly workforce management information (MWMI), scraped from publicly available information on gov.uk.

Figures are provided 'as is' - they have not been quality assured, are not official statistics, and cannot be guaranteed to be accurate. For further information, contact the publishing department.

Aggregate data files are available in two formats as long form data (one value per row with meta data specifying its meaning):

data/output/cleaned_data_trial.RDS - compressed R data.frame

data/output/cleaned_data_trial.csv - csv formatted

| Field      | Definition                                                                                                                                        |
|----------------|--------------------------------------------------------|
| group      | Broad category of data, corresponding to the first segment of the column headings in MWMI publications                                            |
| sub_group  | Sub category of data, corresponding to the second segment of the column heading in MWMI publications                                              |
| measure    | Type of data encoded (i.e. FTE, Headcount, Costs, \# of contracts), corresponding to the third segment of the column heading in MWMI publications |
| value      | The data value                                                                                                                                    |
| org_type   | Organisation type                                                                                                                                 |
| Month      | Reference month for the data                                                                                                                      |
| Year       | Reference year for the data                                                                                                                       |
| Body       | The body / organisation covered by the data                                                                                                       |
| Department | The responsible department for the body / organisation covered by the data                                                                        |
