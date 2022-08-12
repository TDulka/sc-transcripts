# ### Connect to WRDS database
library(RPostgres)
# Needs updating for current user 
wrds <- dbConnect(Postgres(),
                  host='wrds-pgdata.wharton.upenn.edu',
                  port=9737,
                  dbname='wrds',
                  sslmode='require',
                  user='tdulka')

library(dplyr)
library(stringr)

# Set working directory, update for current user
setwd("/Users/Personal/Desktop/MIT/sc-transcripts")

# read dictionary, can be used for supply chain related words
expanded_dict = read.csv("./input/expanded_dict.csv")

# get supply chain related terms, can specify terms from directory or manually
# simple version just uses "suuply chain" since it runs faster
# sc_terms = expanded_dict$supply_chain[expanded_dict$supply_chain != ""]
sc_terms = c("supply chain")

# create the conditional clause for pulling supply chain related transcripts
create_condition = function(term) {
  str_interp("LOWER(componenttext) LIKE '%${term}%'")
}
conditions = sapply(sc_terms, FUN = create_condition)
conditions_aggregated = paste(conditions, collapse = " OR ")

# the SQL query that will be run to pull supply chain related transcripts
query = str_interp("SELECT * FROM ciq_transcripts.ciqtranscriptcomponent
                  WHERE ${conditions_aggregated};")

### pull the supply chain related transcripts from database
res = dbSendQuery(wrds, query)
sc_transcripts = dbFetch(res)
dbClearResult(res)

### get transcript detail information, includes important things like company names
res = dbSendQuery(wrds, "SELECT * FROM ciq.wrds_transcript_detail")
transcript_detail = dbFetch(res)
dbClearResult(res)

# create a regex for matching sentences with supply chain terms
sc_pattern = paste(sc_terms, collapse = "|")

# extracts part of a text where sentences match certain pattern
# plus one sentence before and one sentence after
# if they mention the pattern multiple times the chunk of the text
# can be relatively long, maybe could use a different approach
extract_relevant_text = function(text, pattern) {
  parts = str_split(text, '\\.')[[1]]
  matching_indeces = which(grepl(pattern, parts))
  if (length(matching_indeces) == 0) {
    return("")
  }
  
  first_occ = min(matching_indeces)
  last_occ = max(matching_indeces)
  start_index = max(first_occ - 1, 1)
  end_index = min(last_occ + 1, length(parts))
  
  relevant_portion = parts[start_index:end_index]
  
  return(paste(relevant_portion, collapse = "."))
}
# Vectorize the function so it can be run on a vector of componenttext-s
vec_extract_relevant = Vectorize(extract_relevant_text, USE.NAMES = FALSE)

# subset the set only to the converstation more closely surrounding supply chains
transcripts_shortened = sc_transcripts %>%
  mutate(componenttext = vec_extract_relevant(componenttext, sc_pattern))

# connect transcript texts with details about the transcripts
transcripts_joined = transcripts_shortened %>%
  left_join(transcript_detail) 

# keydeveventtypeid == 48 should subset to Earnings calls, 
# keydeveventtypename variable could be used maybe too
transcripts_for_analysis = transcripts_joined %>%
  filter(keydeveventtypeid == 48 & componenttext != "") 

save(transcripts_for_analysis, file="./data/transcripts_for_analysis.RData")



