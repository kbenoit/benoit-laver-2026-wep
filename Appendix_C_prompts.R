# Appendix_C_prompts.R
# Online Appendix C: System prompts. Prints the four system prompts used to
# score the manifestos and writes them to output/Appendix_C_prompts.txt.

source("01_prepare_prompts.R")
dir.create("output", showWarnings = FALSE)

prompts <- c(
  "Unbudgeted cardinal (0-10)" = prompt_interval,
  "Ranked"                     = prompt_ranked,
  "Pairwise"                   = prompt_pairwise,
  "Budgeted cardinal (0-1)"    = prompt_budget
)
out <- unlist(lapply(names(prompts), \(n) c(paste("=====", n, "====="), prompts[[n]], "")))
writeLines(out)
writeLines(out, file.path("output", "Appendix_C_prompts.txt"))
