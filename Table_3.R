# Table_3.R
# Table 3: Correlations of LLM estimates with expert benchmark.
#   Columns 1-4: Pearson correlation between the raw expert importance score
#     and each LLM measure, using all manifestos with an expert score for that
#     dimension (n varies by dimension).
#   Last column: correlation between the "budgeted" expert score (expert
#     importance rescaled to sum to one over the six issues) and the budgeted
#     LLM score, for the n = 72 manifestos with expert scores on all six.
#   Extra column, not in the published table: "Plackett-Luce (corrected)" uses
#     the correctly aligned PL scores. The published PL column used PL scores
#     that were misassigned for 45 of the 246 manifestos (see 00_setup.R and
#     the README), and understates the correlations.
# Output: output/Table_3.csv

library("dplyr")
library("purrr")

source("00_setup.R")   # data and shared objects

cor_expert <- function(d) {
  expert <- full_df[[paste0("expert_imp_", expert_suffix[d])]]
  # reverse ranks so that higher = more important
  ranked <- (max(full_df[[paste0(d, "_ranked")]], na.rm = TRUE) + 1) -
    full_df[[paste0(d, "_ranked")]]
  tibble(
    dimension = d,
    `Unbudgeted cardinal 1-10` = cor(expert, full_df[[paste0(d, "_interv")]], use = "complete.obs"),
    `Budgeted cardinal 0-1`    = cor(expert, full_df[[paste0(d, "_budget")]], use = "complete.obs"),
    Rank                       = cor(expert, ranked, use = "complete.obs"),
    `Plackett-Luce`            = cor(expert, full_df[[paste0(d, "_pl")]], use = "complete.obs"),
    `Plackett-Luce (corrected)` = cor(expert, full_df[[paste0(d, "_pl_corrected")]], use = "complete.obs"),
    n                          = sum(complete.cases(expert, full_df[[paste0(d, "_budget")]])),
    `Budgeted expert-budgeted LLM (n=72)` =
      cor(expert_budget_df[[paste0("expert_budget_", d)]],
          expert_budget_df[[paste0(d, "_budget")]])
  )
}

table_3 <- map_dfr(dims6, cor_expert)
fisher_row <- table_3 |>
  summarise(across(-c(dimension, n), fisher_mean_r)) |>
  mutate(dimension = "Fisher z-average", n = NA)

table_3 <- bind_rows(table_3, fisher_row) |>
  mutate(Dimension = dim_label(dimension), .before = 1) |>
  select(-dimension) |>
  mutate(across(where(is.double), ~ round(.x, 3)))

cat("Manifestos with expert scores on all six issues:", nrow(expert_budget_df), "\n\n")
print(as.data.frame(table_3))

write.csv(table_3, file.path(path_output, "Table_3.csv"), row.names = FALSE)
