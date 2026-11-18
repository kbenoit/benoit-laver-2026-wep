# Replication materials

Benoit, Kenneth and Michael Laver (2026). "Measuring issue salience for political parties using LLMs." *West European Politics*. <https://doi.org/10.1080/01402382.2026.2637134>

This folder reproduces every table and figure in the article and its online appendix. It is self-contained: it needs R and a few CRAN packages, and nothing else.

## LLM output as data

The work has two stages:

1. **Generating the LLM responses.** Each of the 246 manifestos was sent to Gemini 2.5 Pro in August 2025 with four prompts, and the responses were saved. The code is included (`01_` and `02_`) so that the procedure is fully documented. The responses cannot be regenerated exactly: hosted models are updated and retired, and their output is partly stochastic even at temperature 0 with a fixed seed.
2. **Analysing the responses.** Everything else starts from the saved responses, which are included in full in `data/llm_responses/`, with every score and the LLM's written justification for it. This stage is deterministic and fully re-runnable.

The saved LLM responses should therefore be treated as **given data**, in the same way as the expert surveys and the Manifesto Project codings. Re-running stage 1 would produce a new, slightly different dataset, not a replication of this one.

## How to replicate

1. Install R (≥ 4.1) and these CRAN packages:

   ```r
   install.packages(c("quanteda", "dplyr", "tidyr", "stringr", "purrr",
                      "ggplot2", "PlackettLuce", "glue", "ellmer"))
   ```

2. **Set the working directory to this folder** before running any script. The scripts find `00_setup.R` and `data/` relative to it. In RStudio, open any script here and use *Session › Set Working Directory › To Source File Location*, or run `setwd("path/to/replication")`. If you see an error such as `cannot open file '00_setup.R'`, the working directory is not set to this folder.
3. Either run everything at once:

   ```r
   source("run_all.R")
   ```

   or step through the scripts in the order of the table below. Each table or figure script runs on its own; it sources `00_setup.R` itself. Results are written to `output/`. A full run takes about a minute.

## Folder structure

```
├── README.md                     this file
├── LICENSE                       CC BY 4.0
├── ERRATA.md                     two errors in the published results, and their corrections
├── run_all.R                     runs every analysis script in order
│
├── 00_setup.R                    shared setup, sourced by every table and figure script
├── functions.R                   pl_worths(): Plackett–Luce worths from pairwise comparisons
│
├── 01_prepare_prompts.R          stage 1: the system prompts and output formats
├── 02_score_manifestos_gemini.R  stage 1: LLM scoring (not run by run_all.R)
├── 03_check_published_scores.R   checks the published scores file against the raw responses
│
├── Figure_1.R  Table_1.R  Table_2.R  Table_3.R  Figure_2.R  Table_4.R
├── Text_party_groups.R
├── Table_A1.R  Table_B1.R  Appendix_C_prompts.R  Table_D1.R  Figure_D1.R
│
├── data/
│   ├── corpus_manifestos.rds     the 246 manifestos, with expert survey scores
│   ├── dimensions.rds            issue definitions used in the prompts
│   ├── manifesto_project.rds     Manifesto Project codings of the same manifestos
│   └── llm_responses/            the Gemini 2.5 Pro responses (given data)
│       ├── interval.rds
│       ├── ranked.rds
│       ├── pairwise.rds
│       ├── budget.rds
│       └── combined_published.rds
│
└── output/                       created by the scripts
```

## Scripts

| Script | Reproduces | Output in `output/` |
|---|---|---|
| `00_setup.R` | Shared setup: loads the data, builds the LLM scores from the raw responses, and computes the MP and expert "budget" measures | — |
| `functions.R` | Defines `pl_worths()`, used by `00_setup.R` and `03_` | — |
| `01_prepare_prompts.R` | Builds the four system prompts and the structured output formats | — |
| `02_score_manifestos_gemini.R` | Sends the manifestos to Gemini 2.5 Pro. **Not run by `run_all.R`**; see below | (`llm_output/`) |
| `03_check_published_scores.R` | Confirms that the published scores file matches the raw responses, and identifies the 45 misassigned Plackett–Luce scores (ERRATA.md) | printed |
| `Figure_1.R` | Figure 1 (conceptual illustration, no data) | `Figure_1.pdf` |
| `Table_1.R` | Table 1, plus corpus statistics quoted in the text | `Table_1.csv` |
| `Table_2.R` | Table 2 | `Table_2.csv` |
| `Table_3.R` | Table 3, plus a corrected Plackett–Luce column | `Table_3.csv` |
| `Figure_2.R` | Figure 2 | `Figure_2.pdf` |
| `Table_4.R` | Table 4, with the first column correctly labelled and the corrected MP v expert column added | `Table_4.csv` |
| `Text_party_groups.R` | Green and far-right party comparisons discussed in the text (p. 13) | `Text_party_groups.csv` |
| `Table_A1.R` | Online Appendix Table A.1 | `Table_A1.csv` |
| `Table_B1.R` | Online Appendix Table B.1 | `Table_B1.csv` |
| `Appendix_C_prompts.R` | Online Appendix C (system prompts) | `Appendix_C_prompts.txt` |
| `Table_D1.R` | Online Appendix Table D.1 | `Table_D1.csv` |
| `Figure_D1.R` | Online Appendix Figure D.1 | `Figure_D1.pdf` |
| `run_all.R` | Runs `03_` and all table and figure scripts, and records the R session | `sessionInfo.txt` |

## Data

All files are R data files; read them with `readRDS()`.

| File | Contents |
|---|---|
| `data/corpus_manifestos.rds` | A quanteda corpus of the 246 manifestos (21 countries, 22 languages), with the full texts. Document variables give the country, party, manifesto identifier, expert survey source (Laver & Hunt; Benoit & Laver; CHES) and year, and the expert position (`expert_pos_*`) and importance (`expert_imp_*`) scores for each issue. The texts come from the Manifesto Project corpus (<https://manifesto-project.wzb.eu>) |
| `data/dimensions.rds` | The issue definitions inserted into the prompts: `core` (the six issues) and `control` (the control issues; the paper uses planetary defence) |
| `data/manifesto_project.rds` | Manifesto Project dataset (2024 release) rows for the corpus manifestos, linked by `manifesto`. Used for the MP salience measures (Appendix B) |
| `data/llm_responses/interval.rds` | Unbudgeted importance, 0–10, for each of the seven issues, with the LLM's justification for each |
| `data/llm_responses/ranked.rds` | Rank of the seven issues, 1 (most important) to 7, with justifications |
| `data/llm_responses/pairwise.rds` | For each of the 21 pairs of issues, the more important one (`<a>_vs_<b>_winner`) and the LLM's justification (`<a>_vs_<b>_evidence`) |
| `data/llm_responses/budget.rds` | Budgeted importance: weights from 0 to 1, summing to 1 across the seven issues, with justifications |
| `data/llm_responses/combined_published.rds` | The manifesto-level scores file used for the published results, derived from the four files above. The analysis uses only its Plackett–Luce scores (`*_pl`), to reproduce the published values (see ERRATA.md) |

Each `llm_responses` file has one row per manifesto, in the same order as the corpus, plus the party, country and language the LLM identified.

## Re-running the LLM scoring (optional)

`02_score_manifestos_gemini.R` sends all 246 manifestos to Gemini 2.5 Pro again. As explained above, this produces a new set of LLM responses rather than reproducing the archived ones. It needs:

* the **quallmer** package (≥ 0.6.0) from CRAN
* a Google Gemini API key, in the environment variable `GEMINI_API_KEY` or `GOOGLE_API_KEY`. The run incurs API charges.

The script uses quallmer with the same model, seeds and temperature (0) as the original run. A failed request does not stop the batch, and quallmer re-codes failed manifestos automatically. The prompts are sent exactly as written in `01_prepare_prompts.R`. (The original run called ellmer directly through an experimental function; quallmer now provides the same behaviour.)

The new responses are written to `llm_output/`, in the same format as `data/llm_responses/`, so the archived data are never overwritten. To try the pipeline cheaply first, two environment variables override the defaults: `SALIENCE_MODEL` (for example `"ollama/llama3.2"` for a local model) and `SALIENCE_N_DOCS` (the number of manifestos to score).

## Notes on correspondence with the published article

**Two errors in the published results are documented in [ERRATA.md](ERRATA.md):** misassigned Plackett–Luce scores in Table 3, and a mislabelled column in Table 4. The scripts reproduce the published values and report the corrected values alongside them.

1. **Rounding (Tables 3 and 4).** The scripts report three decimals. The published tables were rounded by hand to two decimals from these three-decimal values. In three cells this double rounding differs by 0.01 from rounding the exact value directly:
   * Table 3 Fisher z-average, unbudgeted: 0.424 → published 0.43
   * Table 3 Social, Plackett–Luce: 0.095 (exactly 0.0948) → published 0.10
   * Table 3/Table 4 EU, budgeted expert v LLM: 0.495 (exactly 0.4947) → published 0.50

   The 0.43 also reflects the original code, which computed the Fisher average from correlations already rounded to three decimals (0.425 rather than 0.424). Every other value matches exactly.
2. **Immigration in Table 4.** The MP immigration categories (601.2, 602.2) are zero for every manifesto in the n = 63 overlap sample, so the correlation is undefined (NA), as published.
3. **Figure 2** uses the 63 manifestos that have expert importance scores on all six issues and a Manifesto Project record.
4. **Appendix D.** The appendix text describes the sample as manifestos "for which at least three dimensions were scored by the experts". In practice the computation requires expert scores on all six dimensions, giving 72 manifestos, or 18 per quartile, as stated in the Table D.1 caption.
5. **Figure 1** is a conceptual diagram. The published version was drawn by hand; `Figure_1.R` recreates it.

## Software

Results were verified with R 4.6.2, quanteda 4.5.1, dplyr 1.2.1, tidyr 1.3.2, ggplot2 4.0.3 and PlackettLuce 0.4.5. `run_all.R` writes the full session details to `output/sessionInfo.txt`.

## Licence and third-party data

The scripts, the LLM responses in `data/llm_responses/`, and the other material written for this replication are licensed under the [Creative Commons Attribution 4.0 International licence](LICENSE) (CC BY 4.0). Please cite the article when you use them.

Some of the data come from other sources and remain subject to their own terms:

* **Manifesto texts and Manifesto Project codings.** The manifesto texts in `data/corpus_manifestos.rds` and the codings in `data/manifesto_project.rds` are processed versions of material from the Manifesto Project (<https://manifesto-project.wzb.eu>). Their use is subject to the [Manifesto Project's Terms of Use](https://manifesto-project.wzb.eu/information/documents/terms_of_use). Please cite the Manifesto Project Dataset and the Manifesto Corpus as the project recommends.
* **Expert surveys.** The expert position and importance scores come from Laver and Hunt (1992), Benoit and Laver (2006) and the Chapel Hill Expert Survey (Jolly et al. 2022). Please cite these sources when using the scores.

## Depositing

This folder is the complete deposit. Leave out `output/` and `llm_output/`, which the scripts create. Harvard Dataverse keeps the folder structure when the folder is uploaded as a single `.zip` file, so the scripts work unchanged after download.
