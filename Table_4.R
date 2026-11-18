# Table_4.R
# Table 4: Correlations between "budgeted" LLM, MP and expert salience scores,
# restricted to the n = 72 manifestos with expert importance scores on all six
# issues. MP budget measures are computed from the MP categories in
# Appendix Table B.1 (see 00_setup.R).
# Output: output/Table_4.csv

library("dplyr")
library("purrr")

source("00_setup.R")   # data and shared objects

cor_table4 <- function(d) {
  expert <- expert_budget_df[[paste0("expert_budget_", d)]]
  llm    <- expert_budget_df[[paste0(d, "_budget")]]
  mp     <- expert_budget_df[[paste0("mp_", d, "_budget")]]
  tibble(
    dimension = d,
    # NOTE: this column reproduces the first column of the published Table 4,
    # which is the budgeted expert v budgeted LLM correlation (identical to the
    # last column of Table 3), although the published header labels it as
    # "Budgeted MP-budgeted expert".
    `Budgeted expert v budgeted LLM (n=72)` = cor(expert, llm, use = "complete.obs"),
    `Budgeted MP v budgeted LLM` = suppressWarnings(cor(mp, llm, use = "complete.obs")),
    `n (MP v LLM)` = sum(complete.cases(mp, llm)),
    # Not reported in the published table: budgeted MP v budgeted expert
    `Budgeted MP v budgeted expert` = suppressWarnings(cor(mp, expert, use = "complete.obs"))
  )
}

table_4 <- map_dfr(dims6, cor_table4)
fisher_row <- table_4 |>
  summarise(across(-c(dimension, `n (MP v LLM)`), fisher_mean_r)) |>
  mutate(dimension = "Fisher z-average", `n (MP v LLM)` = NA)

table_4 <- bind_rows(table_4, fisher_row) |>
  mutate(Dimension = dim_label(dimension), .before = 1) |>
  select(-dimension) |>
  mutate(across(where(is.double), ~ round(.x, 3)))

# The MP immigration categories (601.2, 602.2) are zero for all manifestos
# in this sample, so the immigration correlation is undefined (NA).
print(as.data.frame(table_4))

write.csv(table_4, file.path(path_output, "Table_4.csv"), row.names = FALSE)
