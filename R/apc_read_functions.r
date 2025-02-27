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

  # by hsa group and month
  p1 <- df |>
    dplyr::group_by(admigrp, yyyymm) |>
    dplyr::summarise(n = sum(n)) |>
    dplyr::mutate(yyyymm = factor(yyyymm)) |>
    ggplot2::ggplot() +
    ggplot2::geom_bar(
      ggplot2::aes(x = yyyymm, y = n),
      stat = "identity"
    ) +
    ggplot2::facet_wrap(
      ggplot2::vars(admigrp),
      scales = "free_y"
    )

  p1_nm <- "apc_review_mmbygrp.png"
  ggplot2::ggsave(
    here::here("figures", p1_nm),
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

  p2_nm <- "apc_review_lacd.png"
  ggplot2::ggsave(
    here::here("figures", p2_nm),
    p2
  )

  # hsagrp by LAD
  p3 <- df |>
    dplyr::group_by(lacd, admigrp) |>
    dplyr::summarise(n = sum(n)) |>
    dplyr::mutate(pct_admigrp = n / sum(n) * 100) |>
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

  p3_nm <- "apc_review_lacdbygrp.png"
  ggplot2::ggsave(
    here::here("figures", p3_nm),
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

  p4_nm <- "apc_review_agebygrp.png"
  ggplot2::ggsave(
    here::here("figures", p4_nm),
    p4
  )

  return(list(c(p1_nm, p2_nm, p3_nm, p4_nm)))
}
