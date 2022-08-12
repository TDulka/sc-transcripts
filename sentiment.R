install.packages("vader", repos = "http://cran.us.r-project.org")
library(vader)
library(dplyr)
library(lubridate)
library(ggplot2)


setwd("/Users/Personal/Desktop/MIT/sc-transcripts")

# import transcript data
# load(file="./data/transcripts_for_analysis.RData")

# Point of this filtering is to remove duplicates, sometimes there are multiple versions
# of the same text like Preliminary / Final and Proofed / Spellchecked / Audited copies
# Could maybe be run better
transcripts_cleaned = transcripts_for_analysis %>%
  filter(transcriptpresentationtypeid == 5, transcriptcollectiontypename == "Proofed Copy")

# Running text analysis on a sample of companies (just for hardware performance constrains)
company_ids = sample(unique(transcripts_cleaned$companyid), 500)

# Subset transcripts and collect them by quarter
transcripts_sample = transcripts_cleaned %>%
  filter(companyid %in% company_ids) %>%
  mutate(
    date = floor_date(mostimportantdateutc, unit = "quarter")
  )

# Trying to be even more sure there are no duplicate texts
transcripts_sample_without_redundant = transcripts_sample %>%
  distinct(componenttext, .keep_all = TRUE) %>%
  filter(date > "2010-07-01")

# Score using the vader library
scores = vader_df(transcripts_sample_without_redundant$componenttext) 

# The library returns multiple scores, take just the compound overall score
one_number_scores = scores %>%
  mutate(componenttext = text) %>%
  select(componenttext, compound)

scored_transcripts =  transcripts_sample_without_redundant %>% left_join(one_number_scores)

# Aggregate the total sentiment in each quarter
average_aggregate_sentiment_over_time = scored_transcripts %>%
  select(date, compound) %>%
  group_by(date) %>%
  summarize(sentiment = mean(compound, na.rm = TRUE))

plot = ggplot(data = average_aggregate_sentiment_over_time, aes(x=date, y=sentiment)) +
  geom_line() +
  geom_point(size=1) +
  xlab('Dates') +
  ylab('Sentiment scores') 

plot
ggsave(filename="largersample_sentiment.png", path="output/plots")

