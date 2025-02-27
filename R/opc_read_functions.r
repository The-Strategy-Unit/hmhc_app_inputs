# README
# fns for reading OPC setting data

# read_raw_opc() ----
read_raw_opc <- function(filenm) {
  readr::read_csv(
    filenm,
    na = c("", "NA", "NULL")
  )
}

# review_raw_opc() ----
review_raw_opc <- function(df) {

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

  p1_nm <- "opc_review_mm.png"
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

  p2_nm <- "opc_review_lacd.png"
  ggplot2::ggsave(
    here::here("figures", p2_nm),
    p2
  )

  pct_first <- df |>
    dplyr::group_by(lacd, is_first) |>
    dplyr::summarise(n = sum(n)) |>
    tidyr::pivot_wider(
      names_from = "is_first", values_from = "n", names_prefix = "p"
    ) |>
    dplyr::summarise(pct_first = p1 / (p0 + p1))

  pct_tele <- df |>
    dplyr::group_by(lacd, is_tele) |>
    dplyr::summarise(n = sum(n)) |>
    tidyr::pivot_wider(
      names_from = "is_tele", values_from = "n", names_prefix = "p"
    ) |>
    dplyr::summarise(pct_tele = p1 / (p0 + p1))

  pct_surg <- df |>
    dplyr::group_by(lacd, is_surg) |>
    dplyr::summarise(n = sum(n)) |>
    tidyr::pivot_wider(
      names_from = "is_surg", values_from = "n", names_prefix = "p"
    ) |>
    dplyr::summarise(pct_surg = p1 / (p0 + p1))

  pct_proc <- df |>
    dplyr::group_by(lacd, has_proc) |>
    dplyr::summarise(n = sum(n)) |>
    tidyr::pivot_wider(
      names_from = "has_proc", values_from = "n", names_prefix = "p"
    ) |>
    dplyr::summarise(pct_proc = p1 / (p0 + p1))

  p3 <- pct_first |>
    dplyr::left_join(pct_tele, dplyr::join_by(lacd)) |>
    dplyr::left_join(pct_surg, dplyr::join_by(lacd)) |>
    dplyr::left_join(pct_proc, dplyr::join_by(lacd)) |>
    tidyr::pivot_longer(-lacd, names_to = "grp", values_to = "pct") |>
    dplyr::mutate(
      grp = factor(grp),
      lacd = tidytext::reorder_within(lacd, pct, within = grp)
    ) |>
    ggplot2::ggplot() +
    ggplot2::geom_point(ggplot2::aes(x = lacd, y = pct, color = grp)) +
    tidytext::scale_x_reordered() +
    ggplot2::facet_wrap(ggplot2::vars(grp), scales = "free_x")

  p3_nm <- "opc_review_lacdbygrp.png"
  ggplot2::ggsave(
    here::here("figures", p3_nm),
    p3
  )

  return(list(c(p1_nm, p2_nm, p3_nm)))
}

# review_clean_opc() ----
review_clean_opc <- function(df) {

  # review hsagrp by age
  p1 <- df |>
    dplyr::group_by(hsagrp, sex, age) |>
    dplyr::summarise(n = sum(n)) |>
    ggplot2::ggplot(
      ggplot2::aes(x = age, y = n, group = sex, color = sex)
    ) +
    ggplot2::geom_point() +
    ggplot2::facet_wrap(ggplot2::vars(hsagrp), scales = "free_y")

  p1_nm <- "opc_review_agebygrp.png"
  ggplot2::ggsave(
    here::here("figures", p1_nm),
    p1
  )
  
  return(list(c(p1_nm)))
}
