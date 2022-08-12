Repository for doing textual analysis on earnings transcripts related to supply chains

1. Run `get_sc_transcripts.R` to pull data on transcripts from the WRDS Postgres database. Requires account that can access the WRDS database. Link to the source website: [WRDS Capital IQ Transcripts](https://wrds-www.wharton.upenn.edu/pages/grid-items/capital-iq-transcripts/). Will store data in `data/transcripts_for_analysis.RData`.

2. a) After pulling the data run `robustness_efficiency_trends.R` to get trends in supply chain related discussions mentioning robustness or efficiency. The dictionary of related words is taken from `input/expanded_dict.csv`. Plots are output to `ouput/plots`.

2. b) Run `sentiment.R` to do a simple time trend of sentiment surrounding supply chain discussions over time. 

Very interesting repository is this one: [Measuring Corporate Culture Using Machine Learning](https://github.com/MS20190155/Measuring-Corporate-Culture-Using-Machine-Learning). It is relatively easy to run their code and there is some possibility to use it to generate dictionaries of words that are related to a certain concept like supply chains / robustness / efficiency, I recommend checking it out.

Other interesting papers are [Ersahin, Giannetti, & Huang (2022)](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4036798) and [Hassan, Hollander, Van Lent, and Tahoun (2020)](https://www.nber.org/system/files/working_papers/w26971/w26971.pdf).
