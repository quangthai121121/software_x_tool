# SR4Rec paper (SoftwareX Original Software Publication)

Draft of the article that describes SR4Rec v0.1.0. The article presents results; usage
instructions belong in the repository README and `docs/`.

## Files

| File | Content |
|---|---|
| `main.tex` | the article (elsarticle, SoftwareX structure); `\todo{...}` marks text still to write |
| `figures/architecture.tex` | Figure 1 (TikZ), the only drawn figure |
| `references.bib` | references; entries marked `VERIFY` must be checked before submission |
| `validation.yaml` | results of the correctness checks, turned into the validation table |
| `generated/` | every data figure, data table and number of the article, written by `scripts/make_paper_assets.py` |
| `elsarticle.cls`, `elsarticle-num.bst` | Elsevier class (v3.4c, LPPL) so that the draft compiles anywhere |

## Workflow (the same design as the EmbedKD paper)

The experiments are few and each answers one question:

| Demo | Question | Paper item |
|---|---|---|
| D1 `d1_earvn` (3 seeds) | does SR help on natively small images, and for which sizes? | main table, Figure 2, qualitative Figure 4, latency table |
| D1 `d1_earvn_fixed` | what does the evaluation protocol change? | one paragraph, summary table |
| D2 `d2_lfw` (3 seeds) | does PSNR/SSIM predict recognition? (controlled, synthetic) | D2 table, Figure 3 |
| D3 `d3_cub` (1 seed) | the workflow on another domain, no comparative claim | summary table |
| `scripts/check_sr_fidelity.py` | are SR loading and PSNR/SSIM correct? | Appendix C |

1. Run the demonstrations (README, "Reproducing the paper") and freeze them with
   `scripts/freeze_expected.py`.
2. Generate the assets from the run folders; nothing is copied by hand:
   ```bash
   python scripts/make_paper_assets.py --d1 runs/reproduce_d1_earvn \
       --d1-fixed runs/reproduce_d1_earvn_fixed --d2 runs/reproduce_d2_lfw --d3 runs/reproduce_d3_cub
   python scripts/check_sr_fidelity.py --hr-dir Set5/HR --lr-dir Set5/LR_bicubic/X4 --benchmark Set5 \
       --update paper/validation.yaml
   ```
3. Build: `cd paper && latexmk -pdf main.tex`. Missing assets appear as red "Pending" boxes.
4. Before submission: no `\todo` left (`grep -n "\\todo" main.tex`), main text at most 4,000 words
   (`texcount -inc -sum main.tex`, sections 1-5), at most 6 figures, every `VERIFY` reference
   checked, the code-metadata table matches the released tag, and the class and template are the
   ones currently distributed by the journal.

## Figures and tables

| Item | Source |
|---|---|
| Figure 1 architecture | `figures/architecture.tex` |
| Figure 2 D1 difference with bicubic by LR size | `generated/fig_d1_delta_by_size.pdf` |
| Figure 3 D2 PSNR/SSIM vs Rank-1 | `generated/fig_d2_fidelity.pdf` |
| Figure 4 D1 before/after-SR panels | `generated/fig_d1_qualitative.png` (same drawing function as `comparisons/`) |
| Tables 1-2 code metadata, related software | `main.tex` |
| D1, D2, summary, latency tables; Appendix C tables | `generated/tab_*.tex` |

No face image appears in any figure: the qualitative figure uses the ear dataset (D1).
