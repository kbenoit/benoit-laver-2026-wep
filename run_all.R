# run_all.R
# Runs every replication script in turn (each in a fresh environment) and
# records the R session information. Run from the replication/ directory:
#   Rscript run_all.R
# 02_score_manifestos_gemini.R (LLM API calls) is deliberately NOT run.

scripts <- c(
  "03_check_published_scores.R",
  "Figure_1.R",
  "Table_1.R",
  "Table_2.R",
  "Table_3.R",
  "Figure_2.R",
  "Table_4.R",
  "Text_party_groups.R",
  "Table_A1.R",
  "Table_B1.R",
  "Appendix_C_prompts.R",
  "Table_D1.R",
  "Figure_D1.R"
)

for (s in scripts) {
  cat("\n\n########", s, "########\n")
  sys.source(s, envir = new.env(parent = globalenv()), chdir = FALSE)
}

writeLines(capture.output(sessionInfo()), file.path("output", "sessionInfo.txt"))
