 #Load up our packages
library(rvest)
library(tidyverse)
library(xml2)

# Enter in the website
webpage <- read_html("https://www.mbta.com/about/event-list?preview=&vid=latest&nid=5847")

# Find the list of meetings. They seem to be in the "u-linked-card" class.
meetings <- webpage |> 
  rvest::html_nodes('body') |> 
  xml2::xml_find_all("//div[contains(@class, 'u-linked-card')]") |> 
  rvest::html_text()

# separate the data into columns. 
# The "blank" fields appear to contain the new line characters
meetings_df <- meetings |>
  as_tibble() |> 
  separate(col = "value", 
           into = c("meeting_name","date_time","blank","meeting_name_dupe", "blank2", "location", "blank3"), 
           sep = "  " ) |> 
  select(-blank, -blank2, -blank3, -meeting_name_dupe) |> 
  mutate_all(trimws) # clean up /n charachters

# grab the hrefs. These didn't come with the original search, they're an attribute of the first meeting name?
# The hrefs seem to be relative to the website domain "www.mbta.com"
link <- webpage |> 
  rvest::html_nodes('body') |> 
  xml2::xml_find_all("//a[contains(@class, 'u-linked-card__primary-link')]") |> 
  rvest::html_attr('href')

# make the links into a dataframe and rebuild the links.
link_df <- link |> 
  as_tibble() |> 
  mutate(href_rel = value,
         href_full = paste0("www.mbta.com", href_rel)) |> 
  select(-value, -href_rel)

# bind the two datasets together
scraped_site <- bind_cols(meetings_df, link_df)

# export the data
write_csv(scraped_site, "./triennial-audits_MBTA-events_Jan2020-May2022.csv")
