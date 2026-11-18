# Table_D1.R
# Online Appendix Table D.1: Correlations by length quartile, between the
# budgeted expert scores and the budgeted LLM scores, for the 72 manifestos
# with expert importance scores on all six issues (18 per quartile).
# Output: output/Table_D1.csv

library("dplyr")
library("tidyr")
library("purrr")

source("00_setup.R")   # data and shared objects

length_df <- expert_budget_df |>
  mutate(quartile = cut(ntoken,
                        breaks = quantile(ntoken, probs = seq(0, 1, by = 0.25)),
                        labels = paste0("Q", 1:4), include.lowest = TRUE))
print(table(length_df$quartile))

cors_by_quartile <- expand_grid(dimension = dims6, quartile = paste0("Q", 1:4)) |>
  mutate(r = map2_dbl(dimension, quartile, \(d, q) {
    x <- filter(length_df, quartile == q)
    cor(x[[paste0("expert_budget_", d)]], x[[paste0(d, "_budget")]])
  }))

# dimension order as in the published table
d1_order <- c("economic", "social", "immigration", "eu", "environment", "decentralization")

table_d1 <- cors_by_quartile |>
  pivot_wider(names_from = quartile, values_from = r) |>
  arrange(match(dimension, d1_order)) |>
  mutate(Dimension = dim_label(dimension), .before = 1) |>
  select(-dimension)

summary_rows <- map_dfr(
  list(Mean = mean, Median = median, Minimum = min, Maximum = max),
  \(f) summarise(table_d1, across(Q1:Q4, f)),
  .id = "Dimension"
)

table_d1 <- bind_rows(table_d1, summary_rows) |>
  mutate(across(Q1:Q4, ~ round(.x, 2)))

print(as.data.frame(table_d1))

write.csv(table_d1, file.path(path_output, "Table_D1.csv"), row.names = FALSE)
