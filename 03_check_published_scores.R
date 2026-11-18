# 03_check_published_scores.R
# -----------------------------------------------------------------------------
# Checks the archived scores file used for the published results
# (data/llm_responses/combined_published.rds) against the raw LLM responses.
#
# The published scores file combined the four raw response files into one
# row per manifesto, adding Plackett-Luce worths estimated from the pairwise
# comparisons. This script confirms that:
#   - the unbudgeted, ranked and budgeted scores in it are exactly the raw
#     responses;
#   - its Plackett-Luce worths are the correct worths of the 246 manifestos,
#     but attached to the wrong manifesto in 45 cases (see ERRATA.md).
#
# To check a new LLM run instead, set raw_dir to "data/llm_responses_rerun".
# -----------------------------------------------------------------------------

library("quanteda")
source("functions.R")   # pl_worths()

raw_dir <- file.path("data", "llm_responses")

docs <- docnames(readRDS("data/corpus_manifestos.rds"))
dimensions <- readRDS("data/dimensions.rds")
dims7 <- c(names(dimensions$core), "planetarydefence")

raw <- lapply(c(interval = "interval", ranked = "ranked",
                pairwise = "pairwise", budget = "budget"),
              \(f) readRDS(file.path(raw_dir, paste0(f, ".rds"))))
published <- readRDS(file.path("data", "llm_responses", "combined_published.rds"))

same <- function(a, b) isTRUE(all.equal(a, b, tolerance = 1e-6, check.attributes = FALSE))
scores <- function(df) as.matrix(df[paste0(dims7, "_importance")])

cat("Unbudgeted scores identical to raw responses:",
    same(as.matrix(published[paste0(dims7, "_interv")]), scores(raw$interval)), "\n")
cat("Ranks identical to raw responses:",
    same(as.matrix(published[paste0(dims7, "_ranked")]), scores(raw$ranked)), "\n")
cat("Budgeted scores identical to raw responses:",
    same(as.matrix(published[paste0(dims7, "_budget")]), scores(raw$budget)), "\n")

# Plackett-Luce worths: correct values, compared with the published ones
pl_correct  <- round(as.matrix(pl_worths(raw$pairwise, docs, dims7)[dims7]), 10)
pl_archived <- round(as.matrix(published[paste0(dims7, "_pl")]), 10)
key <- function(m) apply(m, 1, paste, collapse = "|")
cat("Every published PL row is the correct PL row of some manifesto:",
    all(key(pl_archived) %in% key(pl_correct)), "\n")
cat("Manifestos whose published PL scores differ from their correct scores:",
    sum(key(pl_archived) != key(pl_correct)), "of", length(docs), "\n")
