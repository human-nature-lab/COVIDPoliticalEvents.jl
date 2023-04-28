# map plot for treatment plot
# example treatment in 9009 (New Haven) and control as 25009 (Essex)

library("ggplot2")
library("ggmap")

usa <- map_data("usa")
states <- map_data("state")

ggplot(data = states) +
  geom_polygon(aes(x = long, y = lat), fill = "#fffdef", color = "black") +
  coord_fixed(1.3)

sne <- subset(
    states, region %in% c("massachusetts", "connecticut", "rhode island")
)

ggplot(data = sne) +
  geom_polygon(aes(x = long, y = lat), fill = "#fffdef", color = "black") +
  coord_fixed(1.3)

###


devtools::install_github("UrbanInstitute/urbnmapr")

library("tidyverse")
library("urbnmapr")

states_sf <- get_urbn_map("states", sf = TRUE)
counties_sf <- get_urbn_map("counties", sf = TRUE)

counties_sf$treatment <- "not used"
counties_sf$treatment[counties_sf$county_fips == "09009"] <- "treated"
counties_sf$treatment[counties_sf$county_fips == "25009"] <- "control"

plt <- counties_sf %>%
  filter(state_name %in% c("Massachusetts", "Connecticut", "Rhode Island")) %>%
  ggplot(aes()) +
  geom_sf(color = "#ffffff", mapping = aes(fill = treatment)) +
  scale_fill_manual(values = c("paleturquoise", "grey", "orangered3")) +
  coord_sf(datum = NA) + theme(legend.position="none")

ggsave(
    "covid-political-events-paper (working)/treatment_plot.png",
    plt,
    dpi = "retina"
)