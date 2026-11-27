test_that("Add unreliability columns function adds extra cols", {

  dummy_data <- data.frame(
    a = rep("a", 5),
    col_1 = 17:21,
    col_2 = 1:5
  )

  expected_output <- data.frame(
    a = rep("a", 5),
    col_1 = 17:21,
    `Unreliable indicator col_1` = c(rep("[u]", 3), "", ""),
    col_2 = 1:5,
    `Unreliable indicator col_2` = c("", "", rep("[u]", 3)),
    check.names = FALSE
  )
  output <- create_unreliability_columns(dummy_data, c("col_1", "col_2"))

  expect_equal(output, expected_output)
})


test_that("Add unreliability columns function doesn't add extra cols", {

  dummy_data <- data.frame(
    a = rep("a", 5),
    col_1 = 20:24,
    col_2 = 100:104
  )

  output <- create_unreliability_columns(dummy_data, c("col_1", "col_2"))

  expect_equal(output, dummy_data)
})

test_that("Add unreliability cols function adds extra cols, custom threshold", {

  dummy_data <- data.frame(
    a = rep("a", 5),
    col_1 = 17:21,
    col_2 = 1:5
  )

  expected_output <- data.frame(
    a = rep("a", 5),
    col_1 = 17:21,
    `Unreliable indicator col_1` = rep("[u]", 5),
    col_2 = 1:5,
    `Unreliable indicator col_2` = c(rep("", 4), "[u]"),
    check.names = FALSE
  )
  output <- create_unreliability_columns(dummy_data, c("col_1", "col_2"), 5, 50)

  expect_equal(output, expected_output)
})
