# ### Connect to WRDS database
library(RPostgres)
wrds <- dbConnect(Postgres(),
                  host='wrds-pgdata.wharton.upenn.edu',
                  port=9737,
                  dbname='wrds',
                  sslmode='require',
                  user='tdulka')

library(dplyr)
library(stringr)

setwd("/Users/Personal/Desktop/MIT/sc-transcripts")

# read dictionary
expanded_dict = read.csv("./input/expanded_dict.csv")

# get supply chain related terms
# sc_terms = expanded_dict$supply_chain[expanded_dict$supply_chain != ""]
sc_terms = c("supply chain")

# create the conditional clause for pulling supply chain related transcripts
create_condition = function(term) {
  str_interp("LOWER(componenttext) LIKE '%${term}%'")
}
conditions = sapply(sc_terms, FUN = create_condition)
conditions_aggregated = paste(conditions, collapse = " OR ")

query = str_interp("SELECT * FROM ciq_transcripts.ciqtranscriptcomponent
                  WHERE ${conditions_aggregated};")

### pull the supply chain related transcripts from database
res = dbSendQuery(wrds, query)
sc_transcripts = dbFetch(res)
dbClearResult(res)

### get transcript detail information
res = dbSendQuery(wrds, "SELECT * FROM ciq.wrds_transcript_detail")
transcript_detail = dbFetch(res)
dbClearResult(res)

# create a regex for matching sentences with supply chain terms
sc_pattern = paste(sc_terms, collapse = "|")

# extracts part of a text where sentences match certain pattern
# plus one sentence before and one sentence after
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
vec_extract_relevant = Vectorize(extract_relevant_text, USE.NAMES = FALSE)

transcripts_shortened = sc_transcripts %>%
  mutate(componenttext = vec_extract_relevant(componenttext, "supply chain"))

transcripts_joined = transcripts_shortened %>%
  left_join(transcript_detail) 

transcripts_for_analysis = transcripts_joined %>%
  filter(keydeveventtypeid == 48 & componenttext != "") 

save(transcripts_for_analysis, file="./data/transcripts_for_analysis.RData")



