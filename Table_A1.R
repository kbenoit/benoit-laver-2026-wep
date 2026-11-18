# Table_A1.R
# Online Appendix Table A.1: Manifestos included in the sample, and their
# associated expert survey source.
# Output: output/Table_A1.csv

library("dplyr")

source("00_setup.R")   # data and shared objects

table_a1 <- full_df |>
  transmute(
    Country = country,
    Party = party,
    Language = llm_scores$Language_LLM,
    `Expert Survey` = expert_survey,
    `Expert Survey Year` = expert_survey_year,
    Tokens = format(ntoken, big.mark = ",")
  )

print(as.data.frame(table_a1), right = FALSE)

write.csv(table_a1, file.path(path_output, "Table_A1.csv"), row.names = FALSE)
