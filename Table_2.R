# Table_2.R
# Table 2: Mean importance scores, by issue dimension (all 246 manifestos).
# Output: output/Table_2.csv

library("dplyr")

source("00_setup.R")   # data and shared objects

dims7 <- names(dimensions_study)   # six issues + planetary defence control

col_mean <- function(suffix, f = mean) {
  sapply(dims7, \(d) f(llm_scores[[paste0(d, "_", suffix)]], na.rm = TRUE))
}

table_2 <- tibble(
  dimension                      = dims7,
  `Unbudgeted cardinal 1-10`     = col_mean("interv"),
  `Budgeted cardinal 0-1`        = col_mean("budget"),
  Rank                           = col_mean("ranked"),
  `Proportion ranking first`     = sapply(dims7, \(d) mean(llm_scores[[paste0(d, "_ranked")]] == 1, na.rm = TRUE)),
  `Plackett-Luce 0-1`            = col_mean("pl")
) |>
  arrange(desc(`Plackett-Luce 0-1`)) |>
  mutate(Dimension = dim_label(dimension), .before = 1) |>
  select(-dimension) |>
  mutate(across(where(is.numeric), ~ round(.x, 3)))

print(as.data.frame(table_2))

write.csv(table_2, file.path(path_output, "Table_2.csv"), row.names = FALSE)
