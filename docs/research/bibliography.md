# Bibliography

**Project:** Brainwaves — open-source functional audio
**Last verified:** 2026-10-30
**Verification method:** each DOI was looked up in the Crossref REST API (`api.crossref.org/works/<doi>`). The returned first author, year and title were checked against the entry. `scripts/qa_gate.py --check-dois` repeats this check on demand.

> [!NOTE]
> In the project's documents, citations take the form `[@woods2024]` (several keys separated by semicolons). The release gate (`scripts/qa_gate.py`) fails if a document cites a key that is not defined here, or if an entry has no DOI or URL.

## Legend

| Column | Meaning |
|---|---|
| **Type** | MA = meta-analysis · SR = systematic review · RCT = randomised controlled trial · EXP = laboratory experiment · ANI = animal study · STD = standard or guideline · PAT = patent · COM = commercial source · REV = narrative review · CRIT = critique or commentary |
| **Independence** | **Ind** = no declared commercial interest in the tested product · **COI** = authors have a financial interest in the tested product or method |

## A. Brain.fm and company-linked sources

| Key | Reference | DOI / URL | Type | Independence |
|---|---|---|---|---|
| `woods2024` | Woods KJP, Sampaio G, James T, Przysinda E, Hewett A, Spencer AE, Morillon B, Loui P. Rapid modulation in music supports attention in listeners with attentional difficulties. *Communications Biology* 7, 1376 (2024). Author correction to the competing-interests statement published later (PMC record dated 2025). | https://doi.org/10.1038/s42003-024-07026-3 | EXP | **COI**. Woods is a Brain.fm employee with equity options, and Hewett was an employee with equity. Brain.fm produced the test music. Funded by NSF STTR award 1720698. |
| `woods2019` | Woods KJP, Hewett A, Spencer A, Morillon B, Loui P. Modulation in background music influences sustained attention. arXiv:1907.06909 (2019 preprint; not peer reviewed). | https://arxiv.org/abs/1907.06909 | EXP (preprint) | **COI** (as above) |
| `brainfm-science` | Brain.fm. "The Science" web page (accessed 2026-10-30). | https://www.brain.fm/science | COM | Company |
| `brainfm-blog-works` | Brain.fm. "Does Brain.fm actually work?" blog post (accessed 2026-10-30). | https://www.brain.fm/blog/does-brain-fm-actually-work | COM | Company |
| `pat-us11205414` | Hewett A (inventor); BrainFM Inc (assignee). *Noninvasive neural stimulation through audio.* US 11,205,414 B2, granted 2021-12-21; priority 2019-02-15. | https://patents.google.com/patent/US11205414B2/en | PAT | Company |
| `pat-us7674224` | Hewett A. *Method for incorporating brain wave entrainment into sound production.* US 7,674,224 B2 (2010). | https://patents.google.com/patent/US7674224B2/en | PAT | Inventor |

## B. Attention, background music and noise

| Key | Reference | DOI / URL | Type | Independence |
|---|---|---|---|---|
| `kampfe2011` | Kämpfe J, Sedlmeier P, Renkewitz F. The impact of background music on adult listeners: a meta-analysis. *Psychology of Music* 39(4):424–448 (2011). | https://doi.org/10.1177/0305735610376261 | MA | Ind |
| `vasilev2018` | Vasilev MR, Kirkby JA, Angele B. Auditory distraction during reading: a Bayesian meta-analysis of a continuing controversy. *Perspectives on Psychological Science* 13(5):567–597 (2018). | https://doi.org/10.1177/1745691617747398 | MA | Ind |
| `souza2023` | Souza AS, Leal Barbosa LC. Should we turn off the music? Music with lyrics interferes with cognitive tasks. *Journal of Cognition* 6(1):24 (2023). | https://doi.org/10.5334/joc.273 | EXP | Ind |
| `salame1989` | Salamé P, Baddeley A. Effects of background music on phonological short-term memory. *Quarterly Journal of Experimental Psychology A* 41(1):107–122 (1989). | https://doi.org/10.1080/14640748908402355 | EXP | Ind |
| `perham2014` | Perham N, Currie H. Does listening to preferred music improve reading comprehension performance? *Applied Cognitive Psychology* 28(2):279–284 (2014). | https://doi.org/10.1002/acp.2994 | EXP | Ind |
| `thompson2001` | Thompson WF, Schellenberg EG, Husain G. Arousal, mood, and the Mozart effect. *Psychological Science* 12(3):248–251 (2001). | https://doi.org/10.1111/1467-9280.00345 | EXP | Ind |
| `pietschnig2010` | Pietschnig J, Voracek M, Formann AK. Mozart effect–Shmozart effect: a meta-analysis. *Intelligence* 38(3):314–323 (2010). | https://doi.org/10.1016/j.intell.2010.03.001 | MA | Ind |
| `lesiuk2005` | Lesiuk T. The effect of music listening on work performance. *Psychology of Music* 33(2):173–191 (2005). | https://doi.org/10.1177/0305735605050650 | EXP (field) | Ind |
| `soderlund2007` | Söderlund G, Sikström S, Smart A. Listen to the noise: noise is beneficial for cognitive performance in ADHD. *Journal of Child Psychology and Psychiatry* 48(8):840–847 (2007). | https://doi.org/10.1111/j.1469-7610.2007.01749.x | EXP | Ind |
| `nigg2024` | Nigg JT, Bruton A, Kozlowski MB, Johnstone JM, Karalunas SL. Systematic review and meta-analysis: do white noise or pink noise help with task performance in youth with ADHD or with elevated attention problems? *J Am Acad Child Adolesc Psychiatry* 63(8):778–788 (2024). PROSPERO CRD42023393992. | https://doi.org/10.1016/j.jaac.2023.12.014 | SR + MA (preregistered) | Ind |

## C. Auditory beats, entrainment and steady-state responses

| Key | Reference | DOI / URL | Type | Independence |
|---|---|---|---|---|
| `garciaargibay2019` | Garcia-Argibay M, Santed MA, Reales JM. Efficacy of binaural auditory beats in cognition, anxiety, and pain perception: a meta-analysis. *Psychological Research* 83(2):357–372 (2019; online 2018). | https://doi.org/10.1007/s00426-018-1066-8 | MA | Ind |
| `ingendoh2023` | Ingendoh RM, Posny ES, Heine A. Binaural beats to entrain the brain? A systematic review of the effects of binaural beat stimulation on brain oscillatory activity, and the implications for psychological research and intervention. *PLOS ONE* 18(5):e0286023 (2023). | https://doi.org/10.1371/journal.pone.0286023 | SR | Ind |
| `chaieb2015` | Chaieb L, Wilpert EC, Reber TP, Fell J. Auditory beat stimulation and its effects on cognition and mood states. *Frontiers in Psychiatry* 6:70 (2015). | https://doi.org/10.3389/fpsyt.2015.00070 | SR | Ind |
| `nozaradan2011` | Nozaradan S, Peretz I, Missal M, Mouraux A. Tagging the neuronal entrainment to beat and meter. *Journal of Neuroscience* 31(28):10234–10240 (2011). | https://doi.org/10.1523/JNEUROSCI.0411-11.2011 | EXP | Ind |
| `novembre2018` | Novembre G, Iannetti GD. Tagging the musical beat: neural entrainment or event-related potentials? *PNAS* 115(47) (2018), letter. | https://doi.org/10.1073/pnas.1815311115 | CRIT | Ind |
| `picton2003` | Picton TW, John MS, Dimitrijevic A, Purcell D. Human auditory steady-state responses. *International Journal of Audiology* 42(4):177–219 (2003). | https://doi.org/10.3109/14992020309101316 | REV | Ind |

## D. 40 Hz ("gamma") sensory stimulation

| Key | Reference | DOI / URL | Type | Independence |
|---|---|---|---|---|
| `iaccarino2016` | Iaccarino HF, Singer AC, Martorell AJ, et al. Gamma frequency entrainment attenuates amyloid load and modifies microglia. *Nature* 540:230–235 (2016). | https://doi.org/10.1038/nature20587 | ANI | COI (senior author L-H Tsai is a co-founder of Cognito Therapeutics, which develops 40 Hz devices; disclosed in `chan2022`) |
| `martorell2019` | Martorell AJ, Paulson AL, Suk HJ, et al. Multi-sensory gamma stimulation ameliorates Alzheimer's-associated pathology and improves cognition. *Cell* 177(2):256–271 (2019). | https://doi.org/10.1016/j.cell.2019.02.014 | ANI | COI (as for `iaccarino2016`) |
| `chan2022` | Chan D, Suk HJ, Jackson BL, et al. Gamma frequency sensory stimulation in mild probable Alzheimer's dementia patients: results of feasibility and pilot studies. *PLOS ONE* 17(12):e0278412 (2022). | https://doi.org/10.1371/journal.pone.0278412 | RCT (pilot, n = 15) | **COI**. Tsai and Brown co-founded Cognito Therapeutics. |
| `soula2023` | Soula M, Martín-Ávila A, Zhang Y, et al. Forty-hertz light stimulation does not entrain native gamma oscillations in Alzheimer's disease model mice. *Nature Neuroscience* 26:570–578 (2023). | https://doi.org/10.1038/s41593-023-01270-2 | ANI (replication) | Ind |

## E. Sleep

| Key | Reference | DOI / URL | Type | Independence |
|---|---|---|---|---|
| `jespersen2022` | Jespersen KV, Pando-Naude V, Koenig J, Jennum P, Vuust P. Listening to music for insomnia in adults. *Cochrane Database of Systematic Reviews* 2022, Issue 8, CD010459. | https://doi.org/10.1002/14651858.CD010459.pub3 | SR + MA | Ind |
| `ngo2013` | Ngo HVV, Martinetz T, Born J, Mölle M. Auditory closed-loop stimulation of the sleep slow oscillation enhances memory. *Neuron* 78(3):545–553 (2013). | https://doi.org/10.1016/j.neuron.2013.03.006 | EXP | Ind |
| `wunderlin2021` | Wunderlin M, Züst MA, Hertenstein E, et al. Modulating overnight memory consolidation by acoustic stimulation during slow-wave sleep: a systematic review and meta-analysis. *Sleep* 44(7):zsaa296 (2021). | https://doi.org/10.1093/sleep/zsaa296 | SR + MA | Ind |
| `harlow2023` | Harlow TJ, Jané MB, Read HL, Chrobak JJ. Memory retention following acoustic stimulation in slow-wave sleep: a meta-analytic review of replicability and measurement quality. *Frontiers in Sleep* 2:1082253 (2023). | https://doi.org/10.3389/frsle.2023.1082253 | MA | Ind |

## F. Stress, relaxation and breathing

| Key | Reference | DOI / URL | Type | Independence |
|---|---|---|---|---|
| `dewitte2020` | de Witte M, Spruit A, van Hooren S, Moonen X, Stams GJ. Effects of music interventions on stress-related outcomes: a systematic review and two meta-analyses. *Health Psychology Review* 14(2):294–324 (2020; online 2019). | https://doi.org/10.1080/17437199.2019.1627897 | SR + MA | Ind |
| `zaccaro2018` | Zaccaro A, Piarulli A, Laurino M, et al. How breath-control can change your life: a systematic review on psycho-physiological correlates of slow breathing. *Frontiers in Human Neuroscience* 12:353 (2018). | https://doi.org/10.3389/fnhum.2018.00353 | SR | Ind |
| `lehrer2014` | Lehrer PM, Gevirtz R. Heart rate variability biofeedback: how and why does it work? *Frontiers in Psychology* 5:756 (2014). | https://doi.org/10.3389/fpsyg.2014.00756 | REV | Ind |

## G. Safety and standards

| Key | Reference | DOI / URL | Type | Independence |
|---|---|---|---|---|
| `who-h870` | World Health Organization & International Telecommunication Union. *Safe listening devices and systems: a WHO-ITU standard* (H.870) (2019). | https://www.who.int/publications/i/item/9789241515276 | STD | Ind |
| `hugh2014` | Hugh SC, Wolter NE, Propst EJ, Gordon KA, Cushing SL, Papsin BC. Infant sleep machines and hazardous sound pressure levels. *Pediatrics* 133(4):677–681 (2014). | https://doi.org/10.1542/peds.2013-3617 | EXP (device measurement) | Ind |
| `wcag22` | W3C. *Web Content Accessibility Guidelines (WCAG) 2.2*, W3C Recommendation (2023). Used here as the reference for flashing limits and contrast. | https://www.w3.org/TR/WCAG22/ | STD | Ind |
| `apple-hig-a11y` | Apple. *Human Interface Guidelines: Accessibility* (accessed 2026-10-30). | https://developer.apple.com/design/human-interface-guidelines/accessibility | STD | Platform vendor |
