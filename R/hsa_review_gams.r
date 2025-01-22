# README
# review GAMs by plotting modeled values against observed values

# review_area_gams() ----
# produce a small multiple plot to check gams fit
# param: area_code, type: string, ONS geography code
# param: base_year, type: int, base year for gams
# returns: the filepath for a saved plot, rtype: string
review_area_gams <- function(area_code, base_year) {

  path_self <- path_closure(area_code, base_year)

  obs  <- readr::read_csv(path_self("obs_rt_tbl.csv"))
  gams <- readr::read_csv(path_self("model_rt_tbl.csv"))

  dat <- obs |>
    dplyr::left_join(
      gams,
      dplyr::join_by(area_code, setting, hsagrp, sex, age)
    )

  # split by sex
  dat_f <- dat |>
    dplyr::filter(sex == "f")
  dat_m <- dat |>
    dplyr::filter(sex == "m")

  plot_f <- ggplot2::ggplot(dat_f) +
    ggplot2::geom_point(
      ggplot2::aes(x = age, y = rt),
      color = "#fd484e"
    ) +
    ggplot2::geom_line(
      ggplot2::aes(x = age, y = gam_rt),
      color = "#fd484e"
    ) +
    ggplot2::geom_vline(
      ggplot2::aes(xintercept = 55),
      linetype = "22",
      color = "#686f73"
    ) +
    ggplot2::scale_y_continuous(name = NULL) +
    ggplot2::facet_wrap(ggplot2::vars(hsagrp), scales = "free_y") +
    ggplot2::labs(subtitle = "Females")

  plot_m <- ggplot2::ggplot(dat_m) +
    ggplot2::geom_point(
      ggplot2::aes(x = age, y = rt),
      color = "#2c74b5"
    ) +
    ggplot2::geom_line(
      ggplot2::aes(x = age, y = gam_rt),
      color = "#2c74b5"
    ) +
    ggplot2::geom_vline(
      ggplot2::aes(xintercept = 55),
      linetype = "22",
      color = "#686f73"
    ) +
    ggplot2::scale_y_continuous(name = NULL) +
    ggplot2::facet_wrap(ggplot2::vars(hsagrp), scales = "free_y") +
    ggplot2::labs(subtitle = "Males")

  p1 <- patchwork::wrap_plots(plot_f, plot_m)

  # save plot
  filenm <- path_self("review_gams.png")
  ggplot2::ggsave(
    filenm, p1, width = 400, height = 300, units = "mm"
  )

  return(filenm)
}
