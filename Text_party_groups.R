# Text_party_groups.R
# Supports the in-text discussion (Results section, p. 13) of correlations
# between LLM and expert salience scores for green and far-right parties,
# compared with all other parties. Not reported as a table in the paper.
#   Part 1: budgeted expert v budgeted LLM (the n = 72 sample of Table 3)
#   Part 2: raw expert importance v unbudgeted LLM 0-10 score (manifestos with
#           expert importance scores on at least three issues)
# Output: output/Text_party_groups.csv

library("dplyr")
library("tidyr")
library("purrr")

source("00_setup.R")   # data and shared objects

green_parties <- c(
  "Die Grünen", "Grüne",                                    # Austria
  "Agalev", "Ecolo", "Groen!", "Groen",                     # Belgium
  "Strana zelených",                                        # Czech
  "Vihreän liitto", "Vihreät",                              # Finland
  "LMP - Magyarország Zöld Pártja (LMP - Politics Can Be Different)", # Hungary
  "GroenLinks",                                             # Netherlands
  "Partido Ecologista \"Os Verdes\" (PEV)", "PAN",          # Portugal
  "Stranka mladih - Zeleni Evrope",                         # Slovenia
  "Miljöpartiet de Gröna",                                  # Sweden
  "Vinstrihreyfingin grænt framboð"                         # Iceland
)

far_right_parties <- c(
  "Freiheitliche Partei Österreichs (FPÖ)",                 # Austria
  "Vlaams Blok", "Vlaams Belang",                           # Belgium
  "Атака", "Patriotic Front (PF)",                          # Bulgaria
  "Croatian Party of Rights (HSP)",                         # Croatia
  "Dansk Folkeparti", "Nye Borgerlige",                     # Denmark
  "EKRE",                                                   # Estonia
  "Perussuomalaiset (PS)",                                  # Finland
  "Χρυσή Αυγή", "Ελληνική Λύση",                            # Greece
  "Jobbik", "Fidesz",                                       # Hungary
  "Frjálslyndi flokkurinn",                                 # Iceland
  "Lijst Pim Fortuyn (LPF)", "PVV", "Partij voor de Vrijheid (PVV)", # Netherlands
  "Fremskrittspartiet",                                     # Norway
  "Konfederacja Wolność i Niepodległość",
  "Prawo i Sprawiedliwość (PiS)",                           # Poland
  "Slovenská národná strana (SNS)", "Slovak National Party (SNS)", # Slovakia
  "Slovenska demokratska stranka (SDS)",                    # Slovenia
  "Sweden Democrats",                                       # Sweden
  "British National Party", "UK Independence Party"         # UK
)

add_groups <- function(df) {
  df |> mutate(Green = party %in% green_parties,
               `Far right` = party %in% far_right_parties)
}

group_cors <- function(df, x_name, y_name, measure) {
  map_dfr(c("Green", "Far right"), \(g) {
    expand_grid(dimension = dims6, in_group = c(TRUE, FALSE)) |>
      mutate(
        party_group = ifelse(in_group, g, paste0("Non-", tolower(g))),
        stats = map2(dimension, in_group, \(d, ig) {
          x <- df[df[[g]] == ig, ]
          a <- x[[x_name(d)]]; b <- x[[y_name(d)]]
          ok <- complete.cases(a, b)
          tibble(n = sum(ok),
                 r = if (sum(ok) >= 3) suppressWarnings(cor(a[ok], b[ok])) else NA_real_)
        })
      ) |>
      unnest(stats) |>
      mutate(comparison = g, measure = measure)
  })
}

# Part 1: budgeted expert v budgeted LLM, n = 72
part1 <- group_cors(add_groups(expert_budget_df),
                    \(d) paste0("expert_budget_", d), \(d) paste0(d, "_budget"),
                    "Budgeted expert v budgeted LLM")

# Part 2: expert importance v unbudgeted LLM score, >= 3 expert scores
interv_df <- full_df |>
  filter(rowSums(!is.na(across(all_of(expert_imp_cols)))) >= 3) |>
  add_groups()
part2 <- group_cors(interv_df,
                    \(d) paste0("expert_imp_", expert_suffix[d]), \(d) paste0(d, "_interv"),
                    "Expert importance v unbudgeted LLM")

party_groups <- bind_rows(part1, part2) |>
  mutate(Dimension = dim_label(dimension), r = round(r, 3)) |>
  select(measure, comparison, Dimension, party_group, r, n)

for (m in unique(party_groups$measure)) {
  for (g in c("Green", "Far right")) {
    cat("\n==", m, "--", g, "v others ==\n")
    party_groups |>
      filter(measure == m, comparison == g) |>
      pivot_wider(id_cols = Dimension, names_from = party_group, values_from = c(r, n)) |>
      as.data.frame() |>
      print()
  }
}

write.csv(party_groups, file.path(path_output, "Text_party_groups.csv"), row.names = FALSE)
