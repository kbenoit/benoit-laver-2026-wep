# In RStudio, sourcing this file in the repository starts both pilot passes.
# Use source(path, chdir = TRUE) from another working directory.
# With Rscript, --plan previews, --run scores and --compare reads saved scores.
args <- if (interactive()) "--run" else commandArgs(trailingOnly = TRUE)
if (!length(args)) args <- "--plan"
stopifnot(length(args) == 1L, args %in% c("--plan", "--run", "--compare"))

ids <- readLines("data/pilot_manifestos.txt")
corpus <- readRDS("data/corpus_manifestos.rds")
all_ids <- quanteda::docnames(corpus)
archive_dir <- file.path("data", "llm_responses")
published <- readRDS(file.path(archive_dir, "combined_published.rds"))
idx <- match(ids, all_ids)
stopifnot(identical(published$docname, all_ids), length(ids) == 6L,
          !anyNA(idx), !anyDuplicated(idx))
pilot_dir <- file.path("data", "llm_responses_rerun", "six_manifesto_pilot_02")
methods <- c("interval", "ranked", "pairwise", "budget")

if (args == "--plan") {
  print(data.frame(docname = ids, language = published$Language_LLM[idx],
                   tokens = unname(quanteda::ntoken(quanteda::tokens(corpus[idx])))), row.names = FALSE)
  cat("02_score_manifestos_gemini.R: four prompts, two passes, 48 calls before retries.\n")
} else {
  if (args == "--run") {
    message("Starting the six-manifesto Gemini pilot (48 billable calls for a fresh run, before retries).")
    for (pass in 1:2) {
      message("Running 02_score_manifestos_gemini.R, pass ", pass, " of 2")
      status <- system2(file.path(R.home("bin"), "Rscript"),
                        c("02_score_manifestos_gemini.R", paste0("--pilot-pass=", pass)))
      if (status != 0L) stop("The replication scorer stopped during pass ", pass, ".")
    }
  }

  pass_dirs <- file.path(pilot_dir, paste0("pass-", 1:2))
  protocols <- lapply(file.path(pass_dirs, "protocol.rds"), readRDS)
  for (p in protocols) stopifnot(identical(p$ids, ids), identical(p$model, "google_gemini/gemini-2.5-pro"))
  shared <- setdiff(names(protocols[[1]]), "pass")
  stopifnot(identical(protocols[[1]][shared], protocols[[2]][shared]))

  # Archived tables have corpus-order rows. New tables carry the input ID in
  # their row names. Align both dimensions of the comparison explicitly.
  compare_method <- function(method) {
    old <- readRDS(file.path(archive_dir, paste0(method, ".rds")))
    fields <- grep(if (method == "pairwise") "_winner$" else "_importance$", names(old), value = TRUE)
    stopifnot(nrow(old) == length(all_ids), length(fields) == if (method == "pairwise") 21L else 7L)
    archive <- as.matrix(old[idx, fields, drop = FALSE])
    rownames(archive) <- ids
    read_pass <- function(dir) {
      path <- file.path(dir, paste0(method, ".rds"))
      tab <- readRDS(path)
      if (anyDuplicated(rownames(tab)) || !setequal(ids, rownames(tab))) stop("Invalid IDs in ", path)
      mat <- as.matrix(tab[ids, fields, drop = FALSE])
      mat
    }
    valid_rows <- function(mat) {
      apply(mat, 1, function(x) {
        if (anyNA(x)) return(FALSE)
        switch(method, interval = all(x %in% 0:10),
               budget = all(x >= 0 & x <= 1) && abs(sum(x) - 1) < 1e-6,
               ranked = identical(sort(as.numeric(x)), as.numeric(1:7)),
               pairwise = all(vapply(seq_along(fields), function(j) {
                 x[j] %in% strsplit(sub("_winner$", "", fields[j]), "_vs_", fixed = TRUE)[[1]]
               }, logical(1))))
      })
    }
    first <- read_pass(pass_dirs[1])
    second <- read_pass(pass_dirs[2])
    first_valid <- valid_rows(first)
    second_valid <- valid_rows(second)
    stopifnot(all(valid_rows(archive)))
    agreement <- function(a, b, valid) {
      value <- rep(NA_real_, length(ids))
      if (!any(valid)) return(value)
      a <- a[valid, , drop = FALSE]
      b <- b[valid, , drop = FALSE]
      value[valid] <- switch(method, interval =, budget = rowMeans(abs(a - b)),
             ranked = vapply(seq_len(nrow(a)), function(i) cor(a[i, ], b[i, ], method = "spearman"), numeric(1)),
             pairwise = rowMeans(a == b))
      value
    }
    details <- data.frame(docname = rep(ids, each = length(fields)), method = method,
                          field = rep(fields, times = length(ids)), archive = as.vector(t(archive)),
                          pass1 = as.vector(t(first)), pass2 = as.vector(t(second)))
    metrics <- data.frame(docname = ids, method = method,
                          metric = switch(method, interval =, budget = "mean absolute difference",
                                          ranked = "Spearman rho", pairwise = "fraction of winners agreeing"),
                          pass1_archive = agreement(first, archive, first_valid),
                          pass2_archive = agreement(second, archive, second_valid),
                          pass1_pass2 = agreement(first, second, first_valid & second_valid),
                          pass1_valid = first_valid, pass2_valid = second_valid)
    list(details = details, metrics = metrics)
  }
  results <- lapply(methods, compare_method)
  details <- do.call(rbind, lapply(results, "[[", "details"))
  metrics <- do.call(rbind, lapply(results, "[[", "metrics"))
  write.csv(details, file.path(pilot_dir, "scores.csv"), row.names = FALSE)
  write.csv(metrics, file.path(pilot_dir, "agreement.csv"), row.names = FALSE)
  comparisons <- c("pass1_archive", "pass2_archive", "pass1_pass2")
  groups <- metrics[c("method", "metric")]
  summary <- aggregate(metrics[comparisons], groups, function(x) {
    if (all(is.na(x))) NA_real_ else mean(x, na.rm = TRUE)
  })
  counts <- aggregate(metrics[comparisons], groups, function(x) sum(!is.na(x)))
  summary[paste0("n_", comparisons)] <- counts[comparisons]
  write.csv(summary, file.path(pilot_dir, "summary.csv"), row.names = FALSE)
  print(summary, row.names = FALSE)
  message("Agreement summary: ", normalizePath(file.path(pilot_dir, "summary.csv")))
}
