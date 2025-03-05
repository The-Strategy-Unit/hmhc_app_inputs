# README
# review observed rates by plotting local area rates against England rates

# functions ----
# plot_rates
# review_area_obs_rates

# plot_rates() ----
# helper fn to create a small multiple plot to compare local activity rates
# against England rates
# param: obs_eng, type: df, activity rates for England
# param: obs_area, type: df, activity rates in a local area
# returns: a small multiple plot, rtype: ggplot2 plot
plot_rates <- function(obs_eng, obs_area) {
  ggplot2::ggplot() +
    ggplot2::geom_line(
      ggplot2::aes(x = age, y = rt, group = sex),
      color = "#a9adb0",
      data = obs_area
    ) +
    ggplot2::geom_line(
      ggplot2::aes(x = age, y = rt, group = sex, color = sex),
      show.legend = FALSE,
      data = obs_eng
    ) +
    ggplot2::facet_wrap(ggplot2::vars(hsagrp), scales = "free_y") +
    ggplot2::scale_color_manual(values = c("#fd484e", "#2c74b5"))
}

# review_area_obs_rates() ----
# create and save a small multiple plot to compare local activity rates against
# England rates
# param: area_code, type: string, ONS geography code
# param: base_year, type: int, base year for observed rates
# returns: the filepath for a saved ggplot2 plot, rtype: string
review_area_obs_rates <- function(area_code, base_year) {

  path_self <- path_closure(area_code, base_year)

  obs_eng <- readr::read_csv(
    here::here("data", base_year, "E92000001", "obs_rt_df.csv")
  )
  obs  <- readr::read_csv(path_self("obs_rt_df.csv"))

  p1 <- plot_rates(obs_eng, obs)

  # save plot
  filenm <- path_self("review_obs_rates.png")
  ggplot2::ggsave(
    filenm, p1, width = 400, height = 300, units = "mm"
  )

  return(filenm)
}
