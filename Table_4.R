# Table_4.R
# Table 4: Correlations between "budgeted" LLM, MP and expert salience scores,
# restricted to the n = 72 manifestos with expert importance scores on all six
# issues. MP budget measures are computed from the MP categories in
# Appendix Table B.1 (see 00_setup.R).
# Output: output/Table_4.csv

library("dplyr")
library("purrr")

source("00_setup.R")   # data and shared objects

matched <- semi_join(expert_budget_df, mp_df, by = "manifesto")
stopifnot(nrow(matched) == 63L, nrow(expert_budget_df) == 72L)

cor_table4 <- function(d) {
  expert_col <- paste0("expert_budget_", d)
  llm_col <- paste0(d, "_budget")
  mp <- matched[[paste0("mp_", d, "_budget")]]
  keep <- complete.cases(mp, matched[[expert_col]], matched[[llm_col]])
  n <- sum(keep)
  tibble(
    dimension = d,
    `Budgeted LLM v budgeted expert (n=72)` =
      cor(expert_budget_df[[llm_col]], expert_budget_df[[expert_col]]),
    `Budgeted MP v budgeted LLM` =
      if (n >= 2L) cor(mp[keep], matched[[llm_col]][keep]) else NA_real_,
    `Budgeted MP v budgeted expert` =
      if (n >= 2L) cor(mp[keep], matched[[expert_col]][keep]) else NA_real_,
    `n (MP comparisons)` = n
  )
}

table_4 <- map_dfr(dims6, cor_table4)
fisher_row <- table_4 |>
  summarise(across(-c(dimension, `n (MP comparisons)`), fisher_mean_r)) |>
  mutate(dimension = "Fisher z-average", `n (MP comparisons)` = NA)

table_4 <- bind_rows(table_4, fisher_row) |>
  mutate(Dimension = dim_label(dimension), .before = 1) |>
  select(-dimension) |>
  mutate(across(where(is.double), ~ round(.x, 3)))

# Matched LLM–expert comparison quoted in ERRATA.md. The corrected table
# retains the n = 72 column under the label for the comparison it measures.
observed_dims <- dims6[vapply(dims6, function(d) {
  any(!is.na(matched[[paste0("mp_", d, "_budget")]]))
}, logical(1))]
get_weights <- function(columns) {
  weights <- as.matrix(matched[columns])
  colnames(weights) <- observed_dims
  weights
}
llm_weights <- get_weights(paste0(observed_dims, "_budget"))
expert_weights <- get_weights(paste0("expert_budget_", observed_dims))
mp_weights_matched <- get_weights(paste0("mp_", observed_dims, "_budget"))
average_correlation <- function(x, y) {
  fisher_mean_r(vapply(observed_dims, function(d) cor(x[, d], y[, d]), numeric(1)))
}
cat("Matched LLM v expert Fisher z-average:",
    round(average_correlation(llm_weights, expert_weights), 3), "\n")

# Sensitivity analysis: give all three methods the same five-issue budget.
rescale_observed <- function(x) x / rowSums(x)
expert_five <- rescale_observed(expert_weights)
cat("Common five-issue budgets, MP v expert and LLM v expert:",
    round(average_correlation(rescale_observed(mp_weights_matched), expert_five), 3),
    round(average_correlation(rescale_observed(llm_weights), expert_five), 3), "\n")
print(as.data.frame(table_4))

write.csv(table_4, file.path(path_output, "Table_4.csv"), row.names = FALSE)
