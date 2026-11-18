# Table_1.R
# Table 1: Description of manifesto corpus for LLM analysis.
# Output: output/Table_1.csv

library("dplyr")

source("00_setup.R")   # data and shared objects

# manifesto language as identified by the LLM
tab1_df <- full_df |>
  mutate(Language = llm_scores$Language_LLM)

table_1 <- tab1_df |>
  group_by(Country = country) |>
  summarise(
    `Number of manifestos` = n(),
    `Main languages` = paste(na.omit(names(sort(table(Language), decreasing = TRUE))[1:2]),
                             collapse = ", "),
    `Total tokens` = sum(ntoken),
    .groups = "drop"
  ) |>
  # label tidying as in the published table
  mutate(`Main languages` = gsub(", Luxembourgish", "", `Main languages`, fixed = TRUE),
         `Main languages` = gsub("Norwegian (Nynorsk)", "Nynorsk", `Main languages`, fixed = TRUE))

table_1 <- bind_rows(
  table_1,
  tibble(Country = "Total",
         `Number of manifestos` = nrow(tab1_df),
         `Main languages` = paste(length(unique(tab1_df$Language)), "Languages"),
         `Total tokens` = sum(tab1_df$ntoken))
) |>
  mutate(`Total tokens` = format(`Total tokens`, big.mark = ","))

print(as.data.frame(table_1), right = FALSE)

# statistics quoted in the text
cat("\nCountries:", length(unique(tab1_df$country)),
    "\nLanguages:", length(unique(tab1_df$Language)),
    "\nTokens per manifesto: min", min(tab1_df$ntoken),
    "max", max(tab1_df$ntoken),
    "mean", round(mean(tab1_df$ntoken)), "\n")

write.csv(table_1, file.path(path_output, "Table_1.csv"), row.names = FALSE)
