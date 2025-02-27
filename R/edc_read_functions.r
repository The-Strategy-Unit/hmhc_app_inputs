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

  p1_nm <- "edc_review_mmbygrp.png"
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

  p2_nm <- "edc_review_lacd.png"
  ggplot2::ggsave(
    here::here("figures", p2_nm),
    p2
  )

  # hsagrp by LAD
  p3 <- df |>
    dplyr::group_by(lacd, arrmode) |>
    dplyr::summarise(n = sum(n)) |>
    dplyr::mutate(pct_arrmode = n / sum(n) * 100) |>
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

  p3_nm <- "edc_review_lacdbygrp.png"
  ggplot2::ggsave(
    here::here("figures", p3_nm),
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

  p4_nm <- "edc_review_agebygrp.png"
  ggplot2::ggsave(
    here::here("figures", p4_nm),
    p4
  )

  return(list(c(p1_nm, p2_nm, p3_nm, p4_nm)))
}
