# Errata

Benoit, Kenneth and Michael Laver (2026). "Measuring issue salience for political parties using LLMs." *West European Politics*. <https://doi.org/10.1080/01402382.2026.2637134>

While preparing these replication materials we found two errors in the published results. Both come from the code that assembled results for the tables. Neither affects the LLM scoring itself, the data, or the article's main conclusion: the budgeted LLM measure is the best of the four LLM measures, with a Fisher z-average correlation of 0.48 with the raw expert scores and 0.63 with the budgeted expert scores. The replication scripts reproduce the published values and report the corrected values alongside them.

## 1. Table 3: Plackett–Luce scores assigned to the wrong manifestos

### What went wrong

The Plackett–Luce (PL) scores are estimated separately for each manifesto from the LLM's 21 pairwise comparisons between issues. The function that estimates them returns one row per manifesto, **sorted alphabetically by manifesto name**. The analysis code then attached these rows to the other LLM scores **by position**, assuming they were in the same order as the corpus.

The corpus is not in alphabetical order. As a result, **45 of the 246 manifestos** were given another manifesto's PL scores; the other 201 happened to keep their own scores. The affected manifestos are from Belgium (10), Croatia (2), Hungary (10), Norway (8) and the United Kingdom (15).

The LLM output is correct. Only the PL column of Table 3 is affected. The unbudgeted, budgeted and rank measures were assembled correctly, and so were the PL means in Table 2, because a mean over all manifestos does not depend on which manifesto each score is attached to.

### Effect on Table 3

Correlations between the expert importance scores and the PL scores:

| Dimension | Published | Corrected |
|---|---|---|
| Economic | 0.15 | 0.28 |
| Social | 0.10 | 0.07 |
| Environment | 0.47 | 0.68 |
| Immigration | 0.55 | 0.58 |
| EU | 0.15 | 0.41 |
| Decentralisation | 0.15 | 0.38 |
| **Fisher z-average** | **0.27** | **0.42** |

### Effect on the text

The article says that the PL correlations "are clearly weaker than for the other three measures" (pp. 13–14). It also concludes that "the approach based on pairwise issue comparisons did not work particularly well" (p. 16). With the corrected scores, the pairwise approach performs about as well as the unbudgeted (Fisher z-average 0.42) and rank (0.45) measures. It still performs less well than the budgeted measure (0.48).

So the pairwise method was not an outlier. The ordering of the methods, with budgeted best, is unchanged. The discussion of why the pairwise method underperformed (pp. 13–14, 16) still applies relative to the budgeted measure, but not relative to the unbudgeted and rank measures. As in the published table, the PL correlations remain highest for environment and immigration.

## 2. Table 4: first column mislabelled

### What went wrong

The first column of Table 4 is headed "Budgeted MP-budgeted expert (n=72)". It is meant to show how closely the Manifesto Project (MP) budget measures correlate with the budgeted expert scores. The values printed there (0.68, 0.24, 0.81, 0.77, 0.50, 0.60; Fisher z-average 0.63) are in fact the correlations between the **budgeted LLM** scores and the budgeted expert scores. They are identical to the last column of Table 3. When the code assembled Table 4, it picked up the wrong set of correlations and labelled them as MP-v-expert.

The second column of Table 4 (budgeted MP v budgeted LLM, n = 63) is correct.

### Corrected values

The MP measures exist for 63 of the 72 manifestos with complete expert scores, so the corrected column has n = 63, not 72.

| Dimension | Published column (actually LLM v expert, n = 72) | Corrected: MP v expert (n = 63) |
|---|---|---|
| Economic | 0.68 | 0.46 |
| Social | 0.24 | 0.26 |
| Environment | 0.81 | 0.68 |
| Immigration | 0.77 | NA |
| EU | 0.50 | 0.39 |
| Decentralisation | 0.60 | 0.71 |
| **Fisher z-average** | **0.63** | **0.52** |

The MP immigration categories (601.2, 602.2) are zero for every manifesto in this sample, so that correlation is undefined, and the corrected Fisher z-average is over five dimensions. Over the same five dimensions, the LLM-v-expert z-average is 0.60 on the n = 72 sample and 0.56 on the n = 63 sample with MP data.

### Effect on the text

The article says that "the similar distributions of LLM and MP salience weights are also associated with similar correlations between both LLM (Table 3) and MP estimates and the expert benchmark" (p. 15). With the corrected values the MP measures correlate somewhat **less** well with the experts than the LLM does: 0.52 against 0.56 on the same 63 manifestos and five dimensions. Neither measure is uniformly better. The MP correlates more highly for decentralisation and social policy, and the LLM for economic policy, environment and the EU.

The broader argument of this section still holds. The LLM and MP estimates have similar distributions, and both differ from the expert judgements (Figure 2, which is correct). The claim that the two correlate *similarly* with the experts should be softened: the LLM correlates modestly more highly.

## Reproducing the corrections

* `Table_3.R` reports both the published and the corrected PL column.
* `Table_4.R` reports the published first column under its correct name, and the corrected MP-v-expert correlations.
* `00_setup.R` re-estimates the PL scores from the archived pairwise responses with `pl_worths()` (in `functions.R`), which keeps each manifesto's scores in its own row.
* `03_check_published_scores.R` checks that, in the published scores file, the PL scores are misassigned for exactly 45 manifestos and that every other score is identical to the raw responses.

No other table or figure is affected. Figure 2, Tables 1 and 2, and the online appendix tables and figures are all reproduced exactly.
