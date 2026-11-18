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
# Output is written to data/llm_responses_rerun/ (NOT to data/llm_responses/)
# so that the archived responses are never overwritten:
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
# Run this script with --pilot-pass=1 or --pilot-pass=2 to score the six named
# documents in data/pilot_manifestos.txt using the study model. A pilot pass
# writes under data/llm_responses_rerun/six_manifesto_pilot_02/pass-{1,2}/.
# For ordinary runs, two environment variables override the defaults:
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

study_model <- "google_gemini/gemini-2.5-pro"
args <- commandArgs(trailingOnly = TRUE)
pilot <- length(args) == 1L && args %in% paste0("--pilot-pass=", 1:2)
if (length(args) && !pilot) stop("Use no arguments, --pilot-pass=1 or --pilot-pass=2.")
out_dir <- file.path("data", "llm_responses_rerun")
texts <- setNames(as.character(data_corpus_manifs), docnames(data_corpus_manifs))

if (pilot) {
  pass <- sub("--pilot-pass=", "", args, fixed = TRUE)
  model <- study_model
  ids <- readLines("data/pilot_manifestos.txt")
  stopifnot(length(ids) == 6L, !anyDuplicated(ids), all(ids %in% names(texts)))
  texts <- texts[ids]
  out_dir <- file.path(out_dir, "six_manifesto_pilot_02", paste0("pass-", pass))
} else {
  model <- Sys.getenv("SALIENCE_MODEL", study_model)
  n_docs <- as.integer(Sys.getenv("SALIENCE_N_DOCS", length(texts)))
  stopifnot(!is.na(n_docs), n_docs >= 1L, n_docs <= length(texts))
  texts <- texts[seq_len(n_docs)]
}
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# Save each completed pilot coding batch before starting the next prompt.
# A file rename avoids treating an interrupted write as a completed checkpoint.
save_pilot_rds <- function(value, path) {
  tmp <- tempfile(tmpdir = dirname(path))
  on.exit(unlink(tmp))
  saveRDS(value, tmp)
  stopifnot(file.rename(tmp, path))
}
if (pilot) {
  pilot_lock <- filelock::lock(file.path(out_dir, "pass.lock"), timeout = 0)
  if (is.null(pilot_lock)) stop("This pilot pass is already running.")
  inputs <- c("02_score_manifestos_gemini.R", "01_prepare_prompts.R",
              "data/corpus_manifestos.rds", "data/dimensions.rds")
  protocol <- list(ids = ids, model = model, pass = pass, inputs = tools::md5sum(inputs),
                   quallmer = as.character(packageVersion("quallmer")),
                   ellmer = as.character(packageVersion("ellmer")))
  protocol_file <- file.path(out_dir, "protocol.rds")
  if (file.exists(protocol_file)) {
    if (!identical(protocol, readRDS(protocol_file))) {
      stop("Pilot inputs changed. Move the earlier pilot directory before starting a new run.")
    }
  } else {
    save_pilot_rds(protocol, protocol_file)
  }
}

# Score every manifesto with one prompt
code_manifestos <- function(name, system_prompt, type, seed, max_active = 20) {
  checkpoint <- file.path(out_dir, paste0(name, "_coded.rds"))
  if (pilot && file.exists(checkpoint)) {
    message("Reading completed ", name, " batch from ", checkpoint)
    return(readRDS(checkpoint))
  }
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
  if (pilot) save_pilot_rds(coded, checkpoint)
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
  stopifnot(!anyDuplicated(df$.id), setequal(df$.id, names(texts)))
  df <- df[match(names(texts), df$.id), , drop = FALSE]
  rownames(df) <- df$.id
  df |>
    mutate(across(where(is.factor), as.character)) |>
    select(-any_of(c(".id", ".error")))
}

runs <- list()

# Unbudgeted cardinal scale, 0-10 ---------------------------------------------
cat(prompt_interval)
runs$interval <- code_manifestos("interval", prompt_interval,
                                 importance_interval_type, seed = score_seeds[["interval"]])
result_interval_df <- as_result_df(runs$interval)
saveRDS(result_interval_df, file.path(out_dir, "interval.rds"))

# Ranking, 1 (most important) to 7 --------------------------------------------
cat(prompt_ranked)
runs$ranked <- code_manifestos("ranked", prompt_ranked,
                               importance_ranked_type, seed = score_seeds[["ranked"]],
                               max_active = 12)
result_ranked_df <- as_result_df(runs$ranked) |>
  mutate(across(ends_with("_importance"), as.integer))
saveRDS(result_ranked_df, file.path(out_dir, "ranked.rds"))

# Pairwise comparisons (21 pairs) ----------------------------------------------
cat(prompt_pairwise)
runs$pairwise <- code_manifestos("pairwise", prompt_pairwise,
                                 importance_pairwise_type, seed = score_seeds[["pairwise"]])
result_pairwise_df <- as_result_df(runs$pairwise)
saveRDS(result_pairwise_df, file.path(out_dir, "pairwise.rds"))

# Budgeted cardinal scale, 0-1 summing to 1 -----------------------------------
cat(prompt_budget)
runs$budget <- code_manifestos("budget", prompt_budget,
                               importance_budget_type, seed = score_seeds[["budget"]])
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

if (pilot) filelock::unlock(pilot_lock)
