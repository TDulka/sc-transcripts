library(lubridate)
library(ggplot2)
library(dplyr)
library(tidyr)

setwd("/Users/Personal/Desktop/MIT/sc-transcripts")

# import transcript data
load(file="./data/transcripts_for_analysis.RData")

# read dictionary
expanded_dict = read.csv("./input/expanded_dict.csv")

robustness_terms = expanded_dict$robustness
efficiency_terms = expanded_dict$efficiency[expanded_dict$efficiency != ""]

# create patterns for matching robustness and efficiency mentioning text
robustness_pattern = paste(robustness_terms, collapse = "|")
efficiency_pattern = paste(efficiency_terms, collapse = "|")

transcripts = transcripts_for_analysis %>%
  mutate(
    mentions_robustness = grepl(robustness_pattern, componenttext),
    mentions_efficiency = grepl(efficiency_pattern, componenttext)
  ) 

counts_by_date = transcripts %>%
  mutate(
    date = floor_date(mostimportantdateutc, unit = "quarter")
  ) %>%
  filter(date >= "2006-01-01") %>% # very few observations before this date
  group_by(date) %>%
  summarize(
    n_total = n(),
    n_robust = sum(mentions_robustness),
    n_efficient = sum(mentions_efficiency)
  )

statistics = counts_by_date %>%
  mutate(
  # calculate shares of supply chain related discussions mentioning robustness / efficiency
    share_robust = n_robust / n_total,
    share_efficient = n_efficient / n_total
  ) %>%
  # put the scores into one column for easier plotting
  pivot_longer(cols = c(share_robust, share_efficient), names_to="share")

plot <- ggplot(data = statistics, aes(x=date, y=value, group = share)) +
  aes(color=share) + 
  geom_line() +
  geom_point(size=1) +
  expand_limits(y = 0) +
  xlab('Dates') +
  ylab('Share of transcripts')

ggsave(filename="ratios.png", path="output/plots")   
