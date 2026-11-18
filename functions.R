# functions.R
# -----------------------------------------------------------------------------
# Plackett-Luce worths from the LLM's pairwise issue comparisons.
#
# For each manifesto, the LLM chose the more important issue in each of the 21
# pairs of the seven dimensions. A Plackett-Luce model (Turner et al. 2020) is
# fitted to each manifesto's 21 comparisons, and the estimated worths (which
# sum to one across the seven dimensions) are its relative issue saliences.
#
# This is equivalent to salienceTools::pl_worth_from_pairwise(transform =
# "worth", format = "wide"), used for the paper, except that it returns the
# rows in the same order as the input. (The salienceTools function returns
# them sorted by manifesto name -- the source of the error in ERRATA.md.)
#
# Arguments:
#   pairwise_df  one row per manifesto, with columns "<dim1>_vs_<dim2>_winner"
#                holding the name of the winning dimension
#   docnames     manifesto identifiers, in the same order as the rows
#   dimensions   names of the dimensions compared
#   npseudo      pseudo-comparisons with a hypothetical item, which keep the
#                estimates finite when an issue wins or loses every comparison
# Returns: a data frame with `docname` and one worth column per dimension.
# -----------------------------------------------------------------------------

pl_worths <- function(pairwise_df, docnames, dimensions, npseudo = 0.55) {
  winner_cols <- grep("_winner$", names(pairwise_df), value = TRUE)
  pairs <- sub("_winner$", "", winner_cols)
  dim1 <- sub("_vs_.*", "", pairs)
  dim2 <- sub(".*_vs_", "", pairs)

  worths <- t(vapply(seq_len(nrow(pairwise_df)), function(i) {
    winner <- as.character(unlist(pairwise_df[i, winner_cols]))
    loser <- ifelse(winner == dim1, dim2, dim1)
    ok <- !is.na(winner)
    winner <- winner[ok]
    loser <- loser[ok]
    stopifnot(all(c(winner, loser) %in% dimensions))
    if (length(unique(c(winner, loser))) < 2) {
      return(setNames(rep(NA_real_, length(dimensions)), dimensions))
    }
    # one row per comparison: winner ranked 1, loser ranked 2
    m <- matrix(NA_integer_, nrow = length(winner), ncol = length(dimensions),
                dimnames = list(NULL, dimensions))
    m[cbind(seq_along(winner), match(winner, dimensions))] <- 1L
    m[cbind(seq_along(loser), match(loser, dimensions))] <- 2L
    fit <- PlackettLuce::PlackettLuce(PlackettLuce::as.rankings(m), npseudo = npseudo)
    stats::coef(fit, log = FALSE)[dimensions]
  }, numeric(length(dimensions))))

  data.frame(docname = docnames, worths, row.names = NULL)
}
