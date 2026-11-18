# Errata

Benoit, Kenneth and Michael Laver (2026). "Measuring issue salience for political parties using LLMs." *West European Politics*. <https://doi.org/10.1080/01402382.2026.2637134>

While preparing these replication materials we found errors in the assembly of Tables 3 and 4 and in the construction of the Manifesto Project (MP) salience budgets used in Table 4 and Figure 2. The corrections use the archived LLM responses. The budgeted LLM measure has the highest Fisher z-average correlation of the four LLM measures with the raw expert scores (0.48), rising to 0.63 when we also budget the expert scores.

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

## 2. Table 4 and Figure 2

### The first column of Table 4

The heading of the first column of Table 4 identifies the comparison as ‘Budgeted MP-budgeted expert (n = 72)’. In assembling the table we copied the last column of Table 3, which gives the correlations between budgeted LLM and expert scores for the 72 manifestos with complete expert scores. The values are valid for that comparison. The revised table retains the column under its correct heading, retains the MP–LLM comparison in the second column, and adds the intended MP–expert comparison in the third.

### The MP salience budget

Two decisions in the original code affected the MP weights. First, both MP immigration categories (601.2 and 602.2) are missing for every one of the 63 manifestos that we could match to the 72 with complete expert scores. Summing the two missing values with `na.rm = TRUE` assigned each manifesto an immigration score of zero. The two correlations involving MP immigration in Table 4 are therefore unavailable. The published Figure 2 plotted these zeros as if we had observed them. The corrected figure shows the expert and LLM distributions for immigration and marks the MP series as unavailable.

Second, we included category 604 in the numerator for social policy but omitted it from the denominator of the MP budget. As a result, the six MP weights summed to more than one for 32 of the 63 manifestos, reaching 1.068. We now sum the observed issue totals to form the denominator, counting category 604 wherever it contributes to the social-policy total. For these 63 manifestos the MP weights sum to one over five observed issues. The expert and LLM weights retain their original budgets.

### Corrected Table 4

| Dimension | Budgeted LLM v expert (n = 72) | Budgeted MP v LLM (n = 63) | Budgeted MP v expert (n = 63) |
|---|---:|---:|---:|
| Economic | 0.681 | 0.488 | 0.444 |
| Social | 0.238 | −0.060 | 0.263 |
| Environment | 0.809 | 0.873 | 0.683 |
| Immigration | 0.770 | NA | NA |
| EU | 0.495 | 0.627 | 0.383 |
| Decentralisation | 0.602 | 0.545 | 0.712 |
| **Fisher z-average** | **0.631** | **0.561** | **0.519** |

The first column averages correlations over six issues. Each MP column averages correlations over the five issues observed for all 63 matched manifestos. For immigration there are zero observed MP pairs.

### Effect on the text

On p. 15 we describe LLM and MP salience estimates as having similar correlations with the expert benchmark. Comparing the same 63 manifestos and the same five issues, the Fisher z-average is 0.563 for LLM–expert and 0.519 for MP–expert. The MP estimates correlate more highly with expert judgements on social policy and decentralisation, the LLM estimates on economic policy, the environment and the EU. As a further check, we rescaled all three sets of weights to sum to one over the same five issues. The corresponding LLM–expert and MP–expert averages are 0.573 and 0.533. The LLM estimates thus correlate modestly more highly with the experts on average under either budget definition.

Figure 2 still shows that both manifesto-based measures assign greater salience to economic and social policy than the experts do. The published figure provides no evidence about the distribution of MP immigration salience in this sample.

## Reproducing the corrections

* `Table_3.R` reports both the published and the corrected PL column.
* `00_setup.R` re-estimates PL worths from the archived comparisons and constructs the MP budgets from the categories listed in Table B.1.
* `Table_4.R` writes the three comparisons above and prints the matched LLM–expert average and the five-issue sensitivity check.
* `Figure_2.R` plots the observed distributions for the same 63 manifestos.
* The [earlier replication snapshot](https://github.com/kbenoit/benoit-laver-2026-wep/tree/c07d227) retains the original MP calculation, Figure 2, and the earlier Table 4 output.
