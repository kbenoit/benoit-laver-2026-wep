# Figure_D1.R
# Online Appendix Figure D.1: Overall correlations by quartile of manifesto
# length -- distribution across the six dimensions of the budgeted expert v
# budgeted LLM correlations reported in Table D.1.
# Output: output/Figure_D1.pdf

library("dplyr")
library("tidyr")
library("purrr")
library("ggplot2")

source("00_setup.R")   # data and shared objects

length_df <- expert_budget_df |>
  mutate(quartile = cut(ntoken,
                        breaks = quantile(ntoken, probs = seq(0, 1, by = 0.25)),
                        labels = paste0("Q", 1:4), include.lowest = TRUE))

cors_by_quartile <- expand_grid(dimension = dims6, quartile = paste0("Q", 1:4)) |>
  mutate(r = map2_dbl(dimension, quartile, \(d, q) {
    x <- filter(length_df, quartile == q)
    cor(x[[paste0("expert_budget_", d)]], x[[paste0(d, "_budget")]])
  }))

figure_d1 <- ggplot(cors_by_quartile,
                    aes(y = factor(quartile, levels = paste0("Q", 4:1)), x = r)) +
  geom_boxplot(fill = "lightblue", alpha = 0.7) +
  labs(y = "Quartile", x = "Pearson Correlation") +
  theme_minimal() +
  theme(axis.text = element_text(size = 10), axis.title = element_text(size = 11))

ggsave(file.path(path_output, "Figure_D1.pdf"), figure_d1, width = 8, height = 3.5)
