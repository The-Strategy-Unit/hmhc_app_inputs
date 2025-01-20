# README
# fns for reading ED setting data

# read_raw_edc() ----
read_raw_edc <- function(filenm) {
  readr::read_csv(
    filenm,
    na = c("", "NA", "NULL")
  )
}

# review_raw_edc() ----
review_raw_edc <- function(df) {

  # by month
  p1 <- df |>
    dplyr::group_by(yyyymm) |>
    dplyr::summarise(n = sum(n)) |>
    dplyr::mutate(yyyymm = factor(yyyymm)) |>
    ggplot2::ggplot() +
    ggplot2::geom_bar(
      ggplot2::aes(x = yyyymm, y = n),
      stat = "identity"
    )

  ggplot2::ggsave(
    here::here("figures", "edc_review_yyyymm.png"),
    p1
  )

  # by LAD
  p2 <- df |>
    dplyr::group_by(lacd) |>
    dplyr::summarise(n = sum(n)) |>
    ggplot2::ggplot() +
    ggplot2::geom_point(
      ggplot2::aes(x = reorder(lacd, n), y = n)
    )

  ggplot2::ggsave(
    here::here("figures", "edc_review_lacd.png"),
    p2
  )

  # hsagrp by LAD
  p3 <- df |>
    dplyr::group_by(lacd, arrmode) |>
    dplyr::summarise(n = sum(n)) |>
    dplyr::ungroup() |>
    dplyr::mutate(pct_arrmode = n / sum(n)) |>
    dplyr::select(-n) |>
    dplyr::mutate(
      arrmode = factor(arrmode),
      lacd = tidytext::reorder_within(
        lacd, pct_arrmode,
        within = arrmode
      )
    ) |>
    ggplot2::ggplot() +
    ggplot2::geom_point(
      ggplot2::aes(x = lacd, y = pct_arrmode, color = arrmode)
    ) +
    tidytext::scale_x_reordered() +
    ggplot2::facet_wrap(
      ggplot2::vars(arrmode),
      scales = "free_x"
    )

  ggplot2::ggsave(
    here::here("figures", "edc_review_hsagrp_bylacd.png"),
    p3
  )

  # hsagrp by age
  p4 <- df |>
    dplyr::group_by(arrmode, sex, age) |>
    dplyr::summarise(n = sum(n)) |>
    ggplot2::ggplot(
      ggplot2::aes(x = age, y = n, group = sex, color = sex)
    ) +
    ggplot2::geom_point() +
    ggplot2::facet_wrap(
      ggplot2::vars(arrmode),
      scales = "free_y"
    )

  ggplot2::ggsave(
    here::here("figures", "edc_review_hsagrp_byage.png"),
    p4
  )
}
