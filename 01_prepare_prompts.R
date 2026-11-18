# 01_prepare_prompts.R
# -----------------------------------------------------------------------------
# Builds the system prompts (Online Appendix C) and the ellmer structured-output
# type objects used to score the manifestos with Gemini 2.5 Pro.
#
# These are the seven-dimension prompts used for the published results: the
# six substantive issues plus the "planetary defence" control dimension.
#
# Sourced by 02_score_manifestos_gemini.R and Appendix_C_prompts.R; can also be
# run on its own to print the prompts:
#   source("01_prepare_prompts.R"); cat(prompt_budget)
# -----------------------------------------------------------------------------

dimensions <- readRDS("data/dimensions.rds")
dimensions_core <- dimensions$core
dimensions_control <- dimensions$control

library(glue)
library(purrr)

# Issue dimensions ----

# Choose only the core six dimensions plus planetary defence as a control
dimensions_study <- c(dimensions_core, dimensions_control[2])

# Helper to inject the definition block
defs_block <- paste0(
  paste0(
    sprintf("- %s: %s", toupper(names(dimensions_study)), dimensions_study),
    collapse = "\n"
  )
)

# Common preface for system prompts ----

prompt_preface <- glue(
  "You are a political scientist trained in manifesto analysis.",
  "Judge relative importance strictly from the provided manifesto text.",
  "Do NOT use outside knowledge.",
  "Use the full scale where justified.",
  "The policy issues are defined as:
{defs_block}\n
",
  .sep = " "
)

# System prompts ----

## interval scale ----

prompt_interval <- glue(
  prompt_preface, " ",
  "Rate the importance of each issue on a 0-10 scale.
	0 = completely absent or irrelevant;
	2-3 = mentioned only briefly or tangentially;
	5 = moderate importance, discussed but not central;
	7-8 = substantial importance, given sustained attention;
	10 = top priority, central theme of the manifesto.

Also provide a brief justification, citing phrases or themes from the text."
)

## ranked scale ----

N <- length(dimensions_study)

prompt_ranked <- glue(
  prompt_preface, " ",
  "First, assign a complete ranking of all {N} issues, from 1 (most important) to {N} (least important). Each issue must have a unique rank.
Then, provide a 1–2 sentence justification per issue, citing evidence from the text.
Weak or absent evidence should result in a lower rank, with the justification noting the lack of discussion."
)

## pairwise comparisons ----

prompt_pairwise <- glue(
  prompt_preface, " ",
  "When presented with pairs of the policy issues, select which is more important in the manifesto. No ties are allowed.

Evidence each decision with a brief justification, with reference to the text.
If evidence is weak, choose the best-supported option and explain the uncertainty."
)

## budgeted importance ----

prompt_budget <- glue(
  prompt_preface, " ",
  "Distribute importance across the issues as a set of weights between 0.0 and 1.0.

  Rules:
  - Each issue must receive a numeric score in the range [0.0, 1.0].
  - A score of 0.0 means the issue is completely absent or irrelevant in the manifesto.
  - Higher scores mean more relative importance; the more central an issue is to the manifesto, the larger its weight.
  - All issue weights must sum to exactly 1.0 across the six issues.

Also provide a brief justification for each issue’s score."
)


# Type objects using augmented dimensions ----------------------------

# Code to recreate the importance_*_type objects
# This script can be run to regenerate the ellmer type objects if needed

library(ellmer)
library(purrr)
library(glue)


dims <- names(dimensions_study)
N <- length(dimensions_study)


meta_fields <- list(
  Party_LLM    = type_string("Party name extracted from the document", required = FALSE),
  Country_LLM  = type_string("Country of the manifesto", required = FALSE),
  Language_LLM = type_string("Language of the document", required = FALSE)
)


# Interval scaling type object (new) ----

# importance_interval_type <- type_object(
#   description = "Policy importance scoring on a 0-10 scale for a single manifesto",
#   Party_LLM    = type_string("Party name extracted from the document", required = FALSE),
#   Country_LLM  = type_string("Country of the manifesto", required = FALSE),
#   Language_LLM = type_string("Language of the document", required = FALSE),
#   economic_importance     = type_integer("Importance (0–10)", required = TRUE),
#   econoimic_justification = type_string(required = TRUE),
#   social_importance       = type_integer("Importance (0–10)", required = TRUE),
#   social_justification    = type_string(required = TRUE),
#   immigration_importance  = type_integer("Importance (0–10)", required = TRUE),
#   immigration_justification = type_string(required = TRUE),
#   eu_importance           = type_integer("Importance (0–10)", required = TRUE),
#   eu_justification        = type_string(required = TRUE),
#   environment_importance  = type_integer("Importance (0–10)", required = TRUE),
#   environment_justification = type_string(required = TRUE),
#   decentralization_importance = type_integer("Importance (0–10)", required = TRUE),
#   decentralization_justification = type_string(required = TRUE)
# )

dimension_fields_list <- lapply(dims, function(nm) {
  imp <- setNames(list(type_integer(required = TRUE)),
                  paste0(nm, "_importance"))
  jus <- setNames(list(type_string(required = TRUE)),
                  paste0(nm, "_justification"))
  c(imp, jus)
})

# Flatten to a single named list of Type objects
dimension_fields <- do.call(c, dimension_fields_list)

# Compose the type_object: description must be the first, unnamed arg
importance_interval_type <- do.call(
  type_object,
  c(list("Policy importance scoring on a 0–10 scale for a single manifesto"),
    meta_fields,
    dimension_fields
  )
)

# Ranked importance type definitions ----

dimension_fields_list <- lapply(dims, function(nm) {
  imp <- setNames(list(type_enum(as.character(1:N), required = TRUE)),
                  paste0(nm, "_importance"))
  jus <- setNames(list(type_string(required = TRUE)),
                  paste0(nm, "_justification"))
  c(imp, jus)
})

dimension_fields <- do.call(c, dimension_fields_list)

importance_ranked_type <- do.call(
  type_object,
  c(list("Policy importance ranking for a single manifesto"),
    meta_fields,
    dimension_fields
  )
)


# Pairwise scaling type definitions ----

# helper to build one pair's two fields using the shared definitions
pair_fields <- function(dim1, dim2) {
  pair_name <- paste0(dim1, "_vs_", dim2)

  out <- list(
    # note: choices passed POSITIONALLY, not as `choices =`
    type_enum(
      c(dim1, dim2),
      glue("Which is more important for the party: {dim1} or {dim2}? Answer with just the dimension name."),
      required = TRUE
    ),
    type_string(
      glue("Brief justification why {dim1} vs {dim2} was decided this way."),
      required = TRUE
    )
  )
  names(out) <- c(paste0(pair_name, "_winner"), paste0(pair_name, "_evidence"))
  out
}

pairs <- combn(dims, 2, simplify = FALSE)

comparison_list <- pairs |>
  map(~ pair_fields(.x[1], .x[2])) |>
  flatten()

importance_pairwise_type <- do.call(
  type_object,
  c(list("Pairwise importance comparisons for a single manifesto"),
    meta_fields,
    comparison_list
  )
)


# Budget importance scaling definitions ----

# Build "<dim>_weight" (number in [0,1]) and "<dim>_justification" (string) for each dimension
dimension_fields_list <- lapply(dims, function(nm) {
  wt  <- setNames(list(type_number("Weight (0.0–1.0)", required = TRUE)),
                  paste0(nm, "_importance"))
  jus <- setNames(list(type_string(required = TRUE)),
                  paste0(nm, "_justification"))
  c(wt, jus)
})

dimension_fields <- do.call(c, dimension_fields_list)

importance_budget_type <- do.call(
  type_object,
  c(list("Budgeted importance weights (sum to 1.0) for a single manifesto"),
    meta_fields,
    dimension_fields)
)


# Save the type objects ----

# library(usethis)
# use_data(importance_interval_type, overwrite = TRUE)
# use_data(importance_ranked_type, overwrite = TRUE)
# use_data(importance_pairwise_type, overwrite = TRUE)
# use_data(importance_budget_type, overwrite = TRUE)
