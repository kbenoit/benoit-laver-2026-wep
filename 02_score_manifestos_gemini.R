# 02_score_manifestos_gemini.R
# -----------------------------------------------------------------------------
# Scores the 246 manifestos with Gemini 2.5 Pro using each of the four prompts
# (unbudgeted 0-10, ranked, pairwise, budgeted 0-1), using the quallmer package.
#
# *** NOT NEEDED TO REPRODUCE THE TABLES AND FIGURES. ***
# The LLM responses from the run used in the paper are archived in
# data/llm_responses/ and are treated as given data. Re-running this script
# requires a Google Gemini API key (env var GEMINI_API_KEY or GOOGLE_API_KEY),
# incurs API charges, and -- because LLM output is not fully deterministic even
# at temperature 0 -- will produce results that differ slightly from the
# archived run.
#
# Output is written to llm_output/ (NOT to data/llm_responses/) so that the
# archived responses are never overwritten:
#   interval.rds, ranked.rds, pairwise.rds, budget.rds
#                      new responses, in the same format as data/llm_responses/
#   qlm_coded_runs.rds the four quallmer `qlm_coded` objects, which record the
#                      codebook, model, settings and metadata of each run
#
# The original run (August 2025) called ellmer directly through an
# experimental function. quallmer (>= 0.6.0) now provides the same behaviour:
# a failed request does not stop the batch (on_error = "continue"), and failed
# manifestos are re-coded automatically (backfill). The system prompts are
# sent exactly as written in 01_prepare_prompts.R (structured = "structured"
# prevents quallmer's JSON fallback from appending schema instructions).
#
# For testing, two environment variables override the defaults:
#   SALIENCE_MODEL   provider/model, e.g. "ollama/llama3.2"
#                    (default "google_gemini/gemini-2.5-pro")
#   SALIENCE_N_DOCS  number of manifestos to score (default: all 246)
# -----------------------------------------------------------------------------

library("quallmer")       # qlm_codebook(), qlm_code(), qlm_failures()
library("ellmer")         # params()
library("quanteda")
library("dplyr")

source("01_prepare_prompts.R")   # prompt_* and importance_*_type objects

data_corpus_manifs <- readRDS("data/corpus_manifestos.rds")

model <- Sys.getenv("SALIENCE_MODEL", "google_gemini/gemini-2.5-pro")
n_docs <- as.integer(Sys.getenv("SALIENCE_N_DOCS", ndoc(data_corpus_manifs)))

out_dir <- "llm_output"
dir.create(out_dir, showWarnings = FALSE)

texts <- setNames(as.character(data_corpus_manifs), docnames(data_corpus_manifs))
texts <- texts[seq_len(n_docs)]

# Score every manifesto with one prompt
code_manifestos <- function(name, system_prompt, type, seed, max_active = 20) {
  codebook <- qlm_codebook(name = name, instructions = system_prompt, schema = type)
  coded <- qlm_code(
    texts,
    codebook,
    model = model,
    params = params(seed = seed, temperature = 0),
    structured = "structured",
    backfill = TRUE,          # re-code failed manifestos (up to two passes)
    max_active = max_active,
    name = name
  )
  failed <- qlm_failures(coded)
  if (nrow(failed)) {
    warning(nrow(failed), " manifesto(s) not coded for '", name, "': ",
            paste(failed$.id, collapse = ", "))
  }
  coded
}

# Convert a qlm_coded object to the plain data frame format of the archived
# results: one row per manifesto, in corpus order, enum fields as character
as_result_df <- function(coded) {
  df <- as.data.frame(coded)
  df <- df[match(names(texts), df$.id), , drop = FALSE]
  df |>
    mutate(across(where(is.factor), as.character)) |>
    select(-any_of(c(".id", ".error")))
}

runs <- list()

# Unbudgeted cardinal scale, 0-10 ---------------------------------------------
cat(prompt_interval)
runs$interval <- code_manifestos("interval", prompt_interval,
                                 importance_interval_type, seed = 20250816)
result_interval_df <- as_result_df(runs$interval)
saveRDS(result_interval_df, file.path(out_dir, "interval.rds"))

# Ranking, 1 (most important) to 7 --------------------------------------------
cat(prompt_ranked)
runs$ranked <- code_manifestos("ranked", prompt_ranked,
                               importance_ranked_type, seed = 20250813,
                               max_active = 12)
result_ranked_df <- as_result_df(runs$ranked) |>
  mutate(across(ends_with("_importance"), as.integer))
saveRDS(result_ranked_df, file.path(out_dir, "ranked.rds"))

# Pairwise comparisons (21 pairs) ----------------------------------------------
cat(prompt_pairwise)
runs$pairwise <- code_manifestos("pairwise", prompt_pairwise,
                                 importance_pairwise_type, seed = 20250813)
result_pairwise_df <- as_result_df(runs$pairwise)
saveRDS(result_pairwise_df, file.path(out_dir, "pairwise.rds"))

# Budgeted cardinal scale, 0-1 summing to 1 -----------------------------------
cat(prompt_budget)
runs$budget <- code_manifestos("budget", prompt_budget,
                               importance_budget_type, seed = 20250813)
result_budget_df <- as_result_df(runs$budget)
# check that the budget weights sum to one for every manifesto coded
budget_sums <- rowSums(select(result_budget_df, ends_with("_importance")))
if (any(abs(budget_sums - 1) > 1e-6, na.rm = TRUE)) {
  warning("budget weights do not sum to 1 for: ",
          paste(names(texts)[which(abs(budget_sums - 1) > 1e-6)], collapse = ", "))
}
saveRDS(result_budget_df, file.path(out_dir, "budget.rds"))

# Keep the full quallmer run objects (codebooks, settings, metadata)
saveRDS(runs, file.path(out_dir, "qlm_coded_runs.rds"))
