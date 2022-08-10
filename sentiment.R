install.packages("vader", repos = "http://cran.us.r-project.org")
library(vader)
library(dplyr)
library(lubridate)
library(ggplot2)


setwd("/Users/Personal/Desktop/MIT/sc-transcripts")

# import transcript data
# load(file="./data/transcripts_for_analysis.RData")

transcripts_cleaned = transcripts_for_analysis %>%
  filter(transcriptpresentationtypeid == 5, transcriptcollectiontypename == "Proofed Copy")

company_ids = sample(unique(transcripts_cleaned$companyid), 500)

transcripts_sample = transcripts_cleaned %>%
  filter(companyid %in% company_ids) %>%
  mutate(
    date = floor_date(mostimportantdateutc, unit = "quarter")
  )

transcripts_sample_without_redundant = transcripts_sample %>%
  distinct(componenttext, .keep_all = TRUE) %>%
  filter(date > "2010-07-01")

scores = vader_df(transcripts_sample_without_redundant$componenttext) 

one_number_scores = scores %>%
  mutate(componenttext = text) %>%
  select(componenttext, compound)

scored_transcripts =  transcripts_sample_without_redundant %>% left_join(one_number_scores)

# average_quarter_sentiment = scored_transcripts %>%
#   select(companyname, date, compound) %>%
#   group_by(companyname, date) %>%
#   summarize(sentiment = mean(compound))
# 
# planes = average_quarter_sentiment %>%
#   filter(companyname %in% c("Airbus SE", "The Boeing Company"))
# 
# beer = average_quarter_sentiment %>%
#   filter(companyname %in% c("Molson Coors Beverage Company", "Heineken N.V."))
# 
# plotplanes = ggplot(data = planes, aes(x=date, y=sentiment, group = companyname)) +
#   aes(color=companyname) + 
#   geom_line() +
#   geom_point(size=1) +
#   xlab('Dates') +
#   ylab('Sentiment scores')
# 
# ggsave(filename="sentiment_planes.png", path="output/plots")
# 
# plotbeer = ggplot(data = beer, aes(x=date, y=sentiment, group = companyname)) +
#   aes(color=companyname) + 
#   geom_line() +
#   geom_point(size=1) +
#   xlab('Dates') +
#   ylab('Sentiment scores') 
# 
# ggsave(filename="sentiment_beer.png", path="output/plots")


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
