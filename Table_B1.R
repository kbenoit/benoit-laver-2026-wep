# Table_B1.R
# Online Appendix Table B.1: Dimension scales from the MP dataset, following
# Lowe et al. (2011). These category sets are used to compute the MP "budget"
# salience measures in 00_setup.R (Figure 2, Table 4).
# Output: output/Table_B1.csv

library("dplyr")

source("00_setup.R")   # data and shared objects

lowe_label <- c(economic = "Planned v. Market Economy",
                social = "Social Liberal-Conservative",
                environment = "Environmental Protection",
                immigration = "(not defined)",
                eu = "EU",
                decentralization = "Decentralisation")

table_b1 <- tibble(
  Dimension = dim_label(dims6),
  `Lowe et al. (2011) Label` = lowe_label[dims6],
  `Manifesto Categories` = sapply(mp_cats[dims6], \(x) paste(sub("_", ".", x), collapse = ", "))
)

print(as.data.frame(table_b1), right = FALSE)

write.csv(table_b1, file.path(path_output, "Table_B1.csv"), row.names = FALSE)
