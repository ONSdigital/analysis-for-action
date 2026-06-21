# Set up

install.packages(c(

  readr, # for read_csv()

  dplyr, # for data manipulation

  janitor, # for clean_names()

  ggplot2, # for visualising data

  tidyr, # for tidying data

  scales, # for automatically determining labels for axes and legends

  patchwork, # for combining plots

  ))





library(readr)

library(dplyr)

library(janitor)

library(ggplot2)

library(tidyr)

library(scales)

library(patchwork)




create_bar_chart <- function(){
  ## Importing data using the readr package and read_csv function



  vulnerable <- read_csv("D:/repos/analysis-for-action/data/vulnerable.csv")



  ## Make the base chart

  # Make a simple bar chart with one variable, looking at count of countries by continent

  # The data is filtered to 1997 first

  #Rank categories in descending order (highest first)

  # For a frequency chart, this needs to be done manually



  # Prepare the data



  ranked_categories <- vulnerable %>%

    filter(year == 1997) %>%

    group_by(continent) %>%

    mutate(level_continent = factor(continent,

                                    levels = c("Oceania", "Americas", "Europe", "Asia", "Africa")))





  bar_chart <- ggplot(ranked_categories) +

  geom_bar(mapping = aes(x = level_continent), fill = "#003d59", width = 0.6) +

  scale_y_continuous(

    breaks = pretty(c(0, 60), n = 10),

    expand = expansion(mult = c(0, 0.05))) +

  geom_text(stat = "count", aes(x = continent, y = ..count.., label = ..count..),

            hjust = -0.4, color = "black", size = 3) +

  coord_flip() +

  labs(

    title = "Figure 1: Africa has the most countries by continent",

    subtitle = "Number of countries by continent",

    x = "",

    y = "Number of countries"

  ) +

  theme(

    panel.background = element_rect(fill = "white"),

    plot.background = element_rect(fill = "white"),

    panel.grid.major.x = element_line(color = "grey85", size = 0.5),

    panel.grid.major.y = element_blank()

  )

  # Export chart as .svg file



  ggsave(

    filename = "R_barchart.svg",

    plot = bar_chart,

    path = "D:/repos/analysis-for-action/output",

    width = 7,

    height = 5,

    dpi = 300

  )
}

create_bar_chart()
