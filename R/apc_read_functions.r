# README
# fns for reading APC setting data

# read_raw_apc() ----
read_raw_apc <- function(filenm) {
  readr::read_csv(
    filenm,
    na = c("", "NA", "NULL")
  )
}

# review_raw_apc() ----
review_raw_apc <- function(df) {

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
    here::here("figures", "apc_review_yyyymm.png"),
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
    here::here("figures", "apc_review_lacd.png"),
    p2
  )

  # hsagrp by LAD
  p3 <- df |>
    dplyr::group_by(lacd, admigrp) |>
    dplyr::summarise(n = sum(n)) |>
    dplyr::ungroup() |>
    dplyr::mutate(pct_admigrp = n / sum(n)) |>
    dplyr::select(-n) |>
    dplyr::mutate(
      admigrp = factor(admigrp),
      lacd = tidytext::reorder_within(
        lacd, pct_admigrp,
        within = admigrp
      )
    ) |>
    ggplot2::ggplot() +
    ggplot2::geom_point(
      ggplot2::aes(x = lacd, y = pct_admigrp, color = admigrp)
    ) +
    tidytext::scale_x_reordered() +
    ggplot2::facet_wrap(
      ggplot2::vars(admigrp),
      scales = "free_x"
    )

  ggplot2::ggsave(
    here::here("figures", "apc_review_hsagrp_bylacd.png"),
    p3
  )

  # hsagrp by age
  p4 <- df |>
    dplyr::group_by(admigrp, sex, age) |>
    dplyr::summarise(n = sum(n)) |>
    ggplot2::ggplot(
      ggplot2::aes(x = age, y = n, group = sex, color = sex)
    ) +
    ggplot2::geom_point() +
    ggplot2::facet_wrap(
      ggplot2::vars(admigrp),
      scales = "free_y"
    )

  ggplot2::ggsave(
    here::here("figures", "apc_review_hsagrp_byage.png"),
    p4
  )
}
