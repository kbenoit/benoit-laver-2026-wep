# 00_setup.R
# -----------------------------------------------------------------------------
# Shared setup for the replication of:
#   Benoit, Kenneth and Michael Laver (2026). "Measuring issue salience for
#   political parties using LLMs." West European Politics.
#   https://doi.org/10.1080/01402382.2026.2637134
#
# Sourced by every Table_*.R and Figure_*.R script, each of which also loads
# the packages it uses itself. It:
#   1. loads the manifesto corpus (with the expert survey scores)
#   2. builds the LLM salience scores from the archived Gemini responses
#   3. computes the Manifesto Project (MP) "budget" salience measures
#   4. builds the analysis data frames used across tables and figures
#
# Run with replication/ as the working directory.
# -----------------------------------------------------------------------------

library("quanteda")   # corpus object and token counts
library("dplyr")
source("functions.R")   # pl_worths()

path_output <- "output"
dir.create(path_output, showWarnings = FALSE)

# 1. Manifesto corpus and issue dimensions -------------------------------------
# 246 manifestos (full texts), with document variables for country, party,
# expert survey source and year, and expert position (expert_pos_*) and
# importance (expert_imp_*) scores.
data_corpus_manifs <- readRDS("data/corpus_manifestos.rds")
docs <- docnames(data_corpus_manifs)

# Issue definitions used in the prompts: six substantive issues plus the
# "planetary defence" control
dimensions <- readRDS("data/dimensions.rds")
dimensions_study <- c(dimensions$core, dimensions$control["planetarydefence"])
dims7 <- names(dimensions_study)

# the six substantive dimensions, in the order used in the tables
dims6 <- c("economic", "social", "environment", "immigration", "eu",
           "decentralization")

# mapping from LLM dimension names to expert survey variable suffixes
expert_suffix <- c(economic = "economic", social = "social",
                   environment = "envir", immigration = "immig",
                   eu = "eu", decentralization = "decent")

# display labels
dim_label <- function(x) {
  dplyr::case_when(
    x == "economic"         ~ "Economic",
    x == "social"           ~ "Social",
    x == "environment"      ~ "Environment",
    x == "immigration"      ~ "Immigration",
    x == "eu"               ~ "EU",
    x == "decentralization" ~ "Decentralization",
    x == "planetarydefence" ~ "Planetary defence",
    TRUE ~ x
  )
}

# 2. LLM (Gemini 2.5 Pro) salience scores -------------------------------------
# The raw LLM responses in data/llm_responses/ are GIVEN DATA: produced once,
# in August 2025, by 02_score_manifestos_gemini.R, and not exactly repeatable.
# To analyse a new run of 02_ instead, change llm_dir to
# "data/llm_responses_rerun". (The published Plackett-Luce column, *_pl, always
# comes from the archived run.)
# Each file has one row per manifesto (in corpus order), with the LLM's score
# and justification for each of the seven dimensions:
#   interval.rds  unbudgeted cardinal score, 0-10
#   ranked.rds    rank, 1 (most important) to 7
#   pairwise.rds  winner and justification for each of the 21 pairs
#   budget.rds    budgeted score, 0-1, summing to 1
llm_dir <- file.path("data", "llm_responses")
raw <- lapply(c(interval = "interval", ranked = "ranked",
                pairwise = "pairwise", budget = "budget"),
              \(f) readRDS(file.path(llm_dir, paste0(f, ".rds"))))
stopifnot(all(sapply(raw, nrow) == length(docs)))

scores_from <- function(df, suffix) {
  df |>
    select(all_of(paste0(dims7, "_importance"))) |>
    rename_with(~ paste0(sub("_importance$", "", .x), "_", suffix))
}

# Plackett-Luce worths from the pairwise comparisons (*_pl_corrected)
pl_corrected <- pl_worths(raw$pairwise, docs, dims7) |>
  select(-docname) |>
  rename_with(~ paste0(.x, "_pl_corrected"))

# Plackett-Luce worths AS PUBLISHED (*_pl). The original analysis attached
# them to the wrong manifestos in 45 cases (see ERRATA.md). The exact
# misassignment depended on the computer's sort order, so the published values
# are read from the archived scores file rather than recomputed.
# 03_check_published_scores.R verifies that file against the raw responses.
pl_published <- readRDS("data/llm_responses/combined_published.rds")
stopifnot(identical(pl_published$docname, docs))

# One row per manifesto, in corpus order:
#   *_interv, *_ranked, *_budget, *_pl (published), *_pl_corrected
llm_scores <- bind_cols(
  docname = docs,
  select(raw$interval, Country_LLM, Language_LLM, Party_LLM),
  scores_from(raw$interval, "interv"),
  scores_from(raw$ranked, "ranked"),
  select(pl_published, all_of(paste0(dims7, "_pl"))),
  scores_from(raw$budget, "budget"),
  pl_corrected
)
rm(raw, pl_corrected, pl_published)

# 3. Manifesto Project data and MP budget measures ----------------------------
# MP dataset (2024 release) rows for the manifestos in the corpus, linked by
# `manifesto`.
data_mp <- readRDS("data/manifesto_project.rds")

# MP category definitions, following Lowe et al. (2011); see Table B.1
mp_cats <- list(
  economic = c(403, 404, 406, 412, 413, 504, 506, 701,     # planned economy
               401, 402, 407, 414, 505),                   # market economy
  social   = c(103, 105, 106, 107, 202, 604,               # liberal
               104, 201, 203, 305, 601, 603, 605, 606),    # conservative
  environment      = c(501, 416, 410),
  immigration      = c("602_2", "601_2"),
  eu               = c(108, 110),
  decentralization = c(301, 302)
)
# Each issue requires its component categories to have been recorded. A recorded
# zero remains a zero. For each manifesto the denominator is the sum of the
# observed issue totals, including category 604 in the social total.
mp_totals <- vapply(mp_cats, function(categories) {
  rowSums(data_mp[paste0("per", categories)], na.rm = FALSE)
}, numeric(nrow(data_mp)))
mp_total <- rowSums(mp_totals, na.rm = TRUE)
mp_total[mp_total == 0] <- NA_real_
mp_weights <- mp_totals / mp_total
colnames(mp_weights) <- paste0("mp_", colnames(mp_weights), "_budget")
mp_df <- bind_cols(select(data_mp, manifesto), as_tibble(mp_weights))
stopifnot(!anyDuplicated(mp_df$manifesto),
          all(abs(rowSums(mp_weights, na.rm = TRUE)[!is.na(mp_total)] - 1) < 1e-10))

# 4. Combined analysis data ----------------------------------------------------

full_df <- docvars(data_corpus_manifs) |>
  mutate(ntoken = unname(ntoken(tokens(data_corpus_manifs)))) |>
  bind_cols(select(llm_scores, -docname)) |>
  left_join(mp_df, by = "manifesto")

# Expert "budget": raw expert importance scores rescaled to sum to one across
# the six issues, for the manifestos where experts rated all six (n = 72)
expert_imp_cols <- paste0("expert_imp_", expert_suffix[dims6])
expert_budget_df <- full_df |>
  filter(if_all(all_of(expert_imp_cols), ~ !is.na(.x))) |>
  mutate(expert_total = rowSums(across(all_of(expert_imp_cols)))) |>
  filter(expert_total > 0)
for (d in dims6) {
  expert_budget_df[[paste0("expert_budget_", d)]] <-
    expert_budget_df[[paste0("expert_imp_", expert_suffix[d])]] /
    expert_budget_df$expert_total
}

# Helpers ----------------------------------------------------------------------

# Fisher z-average of a vector of correlations
fisher_mean_r <- function(r) tanh(mean(atanh(r), na.rm = TRUE))
