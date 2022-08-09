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
  first_occ = min(which(grepl(pattern, parts)))
  last_occ = max(which(grepl(pattern, parts)))
  start_index = max(first_occ - 1, 1)
  end_index = min(last_occ + 1, length(parts))
  
  relevant_portion = parts[start_index:end_index]
  
  return(paste(relevant_portion, collapse = "."))
}
vec_extract_relevant = Vectorize(extract_relevant_text)

transcripts_for_analysis = sc_transcripts %>%
  left_join(transcript_detail) %>%
  filter(keydeveventtypeid == 48) %>%
  select(headline, mostimportantdateutc, componenttext)

save(transcripts_for_analysis, file="./data/transcripts_for_analysis.RData")



