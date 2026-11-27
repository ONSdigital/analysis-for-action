test_that("Mcounty renamed, postcodes recoded, Cornwall and Scilly combined", {
  df <- data.frame(
    mcd21 = c("a", "b", "c"),
    pcd = c("a11 1aa", "b11 1bb", "c11 1cc"),
    laua = c("E06000052", "E06000053", "A"),
    other = 1:3
  )

  expected_output <- data.frame(
    mcounty = c("a", "b", "c"),
    pcd = c("a111aa", "b111bb", "c111cc"),
    laua = c("E06000052, E06000053", "E06000052, E06000053", "A"),
    other = 1:3
  )

  expect_equal(process_nspl(df, "mcd21"), expected_output)
})

test_that("Births and nspl are joined correctly", {
  births_df <- data.frame(
    pcdrm = c("LE3 6HT", "TR112QT", "CF 24 2NF"),
    other = c(1:3))

  nspl <- data.frame(
    pcd = c("LE36HT", "CF242NF", "TR11NAS", "TR112QT"),
    county = c("Leicestershire", "Cardiff", "Cornwall", "Cornwall"))

  expected_output <- data.frame(
    pcdrm = c("LE36HT", "TR112QT", "CF242NF"),
    other = c(1:3),
    county = c("Leicestershire", "Cornwall", "Cardiff"))

  expect_equal(join_births_nspl(births_df, nspl), expected_output)
})
