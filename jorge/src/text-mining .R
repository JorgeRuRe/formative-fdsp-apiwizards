# Author: JRR
# Maintainers: JRR
# Copyright:   2021, Data Cívica GPL v2 or later
# ===========================================================


# Paquetes  ---------------------------------------------------------------
if(!require('pacman')) {install.packages('pacman')}
pacman::p_load(tidyverse, here, tidytext, scales, svglite)

devices <- c("png", "svg")
out <- here("jorge/output")

# Read  and prepare data  --------------------------------------------------------------
stack_df <- read_csv(here("jorge/output/text_data.csv"))
  

stack_tokens <- stack_df %>% 
  separate(CreationDate, c("date", "time"), sep = " ") %>% 
  filter(date < "2022-09-01") %>% 
  filter(Tags == "bread" | Tags == "baking") %>% 
  unnest_tokens(word, Title) %>% 
  anti_join(stop_words) %>% 
  filter(!str_detect(word, "[0-9]")) %>%
  ungroup()


raw_frequency <- stack_tokens %>%
  group_by(Tags) %>%
  count(word, sort = TRUE) %>%
  left_join(stack_tokens %>%  
              group_by(Tags) %>%
              summarise(total = n())) %>%
  mutate(freq = n/total) 

frequency <- raw_frequency %>%
  select(Tags, word, freq) %>%
  spread(Tags, freq) %>%
  arrange(baking, bread) %>%
  filter(!str_detect(word, "[0-9]"))

### plot 
ggplot(frequency, aes(baking, bread)) +
  geom_jitter(alpha = 0.4, size = 3.5, width = 0.25, height = 0.25,
              colour = "#558B6E") +
  geom_text(aes(label = word), check_overlap = TRUE, vjust = 1.5) +
  scale_x_log10(labels = percent_format()) + # ESCALA LOGARÍTMICA 
  scale_y_log10(labels = percent_format()) +
  geom_abline(color = "red") +
  theme_minimal() + 
  labs(title = "How similiar are the titles with \n bread and baking tags?",
       subtitle = "Recipies stackexchange") +
  theme(text = element_text(family = "Helvetica", color = "grey35"),
        plot.title = element_text(size = 15, face = "bold", color = "black", hjust = 0.5),
        plot.subtitle = element_text(size = 12, face = "bold", color = "#666666", hjust = 0.5),
        plot.caption = element_text(hjust = 0, size = 10, face = "italic"),
        panel.grid = element_line(linetype = 2), 
        legend.title = element_text(size = 14, face = "bold"),
        legend.text = element_text(size = 12),
        axis.title = element_text(size = 10, face = "bold"),
        axis.text = element_text(size = 10, face = "bold"),
        strip.background = element_blank(),
        strip.text = element_text(size = 12, face = "bold")
  )


walk(devices, ~ ggsave(filename = paste0(out, "word-comp.", .x),
                       device = .x, width = 10, height = 6))  


# TF-IDF ------------------------------------------------------------------
stack_tf <- stack_tokens %>% 
  count(word, Tags, sort = TRUE) %>%
  ungroup() %>% 
  bind_tf_idf(word, Tags, n) %>%
  arrange(-tf_idf) %>%
  ungroup() %>%
  group_by(Tags) %>%
  top_n(5)


## Plot 
stack_tf %>%
  ggplot(aes(reorder(word, tf_idf), tf_idf, fill= Tags)) +
  geom_col(fill = "#558B6E") +
  coord_flip() +
  facet_wrap(~ Tags, scales = "free", ncol = 3) +
  theme_classic(base_family = "Courier New") +
  labs(y = NULL,
       x = NULL,
       title = "TF-IDF for bread and baking",
       subtitle = "Recipies stackexchange") +
  theme(text = element_text(family = "Helvetica", color = "grey35"),
        plot.title = element_text(size = 15, face = "bold", color = "black", hjust = 0.5),
        plot.subtitle = element_text(size = 12, face = "bold", color = "#666666", hjust = 0.5),
        plot.caption = element_text(hjust = 0, size = 10, face = "italic"),
        panel.grid = element_line(linetype = 2), 
        legend.title = element_text(size = 14, face = "bold"),
        legend.text = element_text(size = 12),
        axis.title = element_text(size = 10, face = "bold"),
        axis.text = element_text(size = 10, face = "bold"),
        strip.background = element_blank(),
        strip.text = element_text(size = 12, face = "bold")
  )

walk(devices, ~ ggsave(filename = paste0(out, "tf-idf.", .x),
                       device = .x, width = 10, height = 6))  


# Done. 