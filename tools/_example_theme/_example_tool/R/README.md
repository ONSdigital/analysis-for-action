# Example tool README

This README file provides a generic template using the example tool as an example.

## Overview

The example tool is designed to provide an example of best practices for building tools within the Analysis for Action platform. In reality tools will vary in complexity and functionality, so this directory is only intended to provide an example of a simple structure as well as best practice code and documentation for tools within the platform.

## Installation

To install the [tool_name], follow these steps:

1. Clone the repository:
   ```R
   # In R console or RStudio terminal
   # Download and set working directory
   # You can also use git bash or command prompt
   git clone https://github.com/ONSdigital/analysis-for-action.git
   setwd("analysis-for-action/tools/_example_theme/_example_tool/R")
   ```

2. Install the required dependencies:
   ```R
   install.packages("devtools") # if not already installed
   devtools::install_deps(dependencies = TRUE)
   ```

> **Note:** Each tool in this repository has its own setup instructions or DESCRIPTION file to ensure dependencies are isolated and easy to manage. Only install dependencies for the tool you wish to use.

## Usage

To use the example tool, run the following command from the tool's directory:
```R
source("tool.R")
example_add_numbers(2, 3)
```

Replace `2` and `3` with your desired numbers.

## Data

[Add any information about data used by the tool here, if applicable.]

## Tests

[Add any information about how to run tests.]
