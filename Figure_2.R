# Figure_2.R
# Figure 2: Distributions of "budgeted" saliences -- expert, MP and LLM budget
# scores, for manifestos with expert importance scores on all six issues and a
# matching Manifesto Project record.
# Output: output/Figure_2.pdf

library("dplyr")
library("tidyr")
library("stringr")
library("ggplot2")

source("00_setup.R")   # data and shared objects

fig2_df <- expert_budget_df |>
  semi_join(mp_df, by = "manifesto")
cat("Manifestos plotted:", nrow(fig2_df), "\n")

fig2_long <- fig2_df |>
  select(manifesto,
         all_of(paste0("expert_budget_", dims6)),
         all_of(paste0("mp_", dims6, "_budget")),
         all_of(paste0(dims6, "_budget"))) |>
  pivot_longer(-manifesto, names_to = "var", values_to = "budget_value") |>
  mutate(
    measure_type = case_when(
      str_starts(var, "expert_budget_") ~ "Expert Budget",
      str_starts(var, "mp_")            ~ "MP Budget",
      TRUE                              ~ "LLM Budget"
    ),
    measure_type = factor(measure_type,
                          levels = c("Expert Budget", "MP Budget", "LLM Budget")),
    dimension = str_remove_all(var, "^expert_budget_|^mp_|_budget$")
  )

# dimensions ordered by median MP budget (lowest at the bottom of the plot)
dim_order <- fig2_long |>
  filter(measure_type == "MP Budget") |>
  group_by(dimension) |>
  summarise(med = median(budget_value, na.rm = TRUE), .groups = "drop") |>
  arrange(desc(is.na(med)), med) |>
  pull(dimension)
fig2_long <- fig2_long |>
  mutate(dimension = factor(dim_label(dimension), levels = dim_label(dim_order)))

# colours: the "jco" palette from ggsci (blue, yellow, grey), as published
fig2_colours <- c("Expert Budget" = "#0073C2",
                  "MP Budget"     = "#EFC000",
                  "LLM Budget"    = "#868686")

figure_2 <- ggplot(filter(fig2_long, !is.na(budget_value)), aes(x = dimension, y = budget_value, fill = measure_type)) +
  geom_boxplot(alpha = 0.7, outlier.alpha = 0.5, position = position_dodge(width = 0.8)) +
  scale_fill_manual(values = fig2_colours) +
  labs(x = "Policy Dimension", y = "Budget Score (0-1.0)", fill = "Measure Type",
       caption = "MP immigration scores are unavailable for all 63 matched manifestos.") +
  coord_flip() +
  theme_minimal()

ggsave(file.path(path_output, "Figure_2.pdf"), figure_2, width = 9, height = 7)
