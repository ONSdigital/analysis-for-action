# Contributing

## Contents
- [What to Contribute](#what-to-contribute)
- [Contribution Process](#contribution-process)
  - [1. Cloning the Repository](#1-cloning-the-repository)
  - [2. Set-up](#2-set-up)
  - [3. Adding your code and data](#3-adding-your-code-and-data)
  - [4. Pull Requests](#4-pull-requests)
- [Coding standards](#coding-standards)
- [Raising Issues](#raising-issues)
- [Questions](#questions)

## What to Contribute
This repository should include code and data that directly relates to written content or tools on the Analysis for Action platform, including:
- runnable code snippets in Python and R,
- example datasets,
- small tools that are included within a unit,
- documentation to support understanding and use of the code snippets and tools.

This repository should **not** include:
- sensitive data,
- large tools or applications (these should be in their own repositories),
- written unit content that is or will be hosted on the Analysis for Action platform,
- code from written unit content that is not runnable i.e. only used as an example.

## Contribution Process

### 1. **Cloning the Repository**
To begin contributing, clone the repository directly:

```cmd
git clone https://github.com/ONSdigital/analysis-for-action.git
cd analysis-for-action
```

### 2. **Set-up**
Follow the setup instructions in the [README.md](README.md) to configure your development environment.

This repository also uses `pre-commit` to manage git hooks. This ensures our code is consistent and secure. To set it up:
1. install python dependencies following instructions in the [README.md](README.md)
2. run the below in your terminal:
   ```sh
   pre-commit install
   ```

### 3. **Adding your code and data**

#### Branching
Create a new branch for your changes, include the unit name and description of the code where possible e.g. `intro_to_rap_code_snippets`, `outputs_and_reporting_contrast_checker`.

#### Where to add your code

##### Learning resources
- Add code and documentation to the correct folder, following the [repository structure](README.md#repository-structure).
- Python code should be added to the `python/` folder as an `.ipynb` notebook file.
- R code should be to the `r/` folder as an `.Rmd` R markdown file.
- Documentation should be added to the `docs/` folder as a `.md` markdown file.
- You may need to create the folders yourself if they do not already exist.

Templates for each can be found the below:
 - Python notebook template - [learning_resources\\_example_theme\\_example_module\\_example_unit\\python\\example.ipynb](learning_resources\\_example_theme\\_example_module\\_example_unit\\python\\example.ipynb)
 - R markdown template - [learning_resources\\_example_theme\\_example_module\\_example_unit\\r\\example.Rmd](learning_resources\\_example_theme\\_example_module\\_example_unit\\r\\example.Rmd)
 - Instructions template - [learning_resources\\_example_theme\\_example_module\\_example_unit\\docs\\example.md](learning_resources\\_example_theme\\_example_module\\_example_unit\\docs\\example.md)

##### Tools
Code files and structure will vary for each tool. As a minimum ensure code follows the [coding standards](#coding-standards) and contains a README file explaining its purpose and how it can be used or adapted by the user.

#### Where to add data
Add data for learning resource code to the `learning_resources/data/` folder.

> **Ensure no sensitive code or data is included before committing and pushing changes.**

#### Where to add dependencies
Add any dependencies to the relevant files:
- For Python, update `requirements.txt`.
- For R, add the package names to the `setup.R` script if new packages are required.

Ensure your code has been peer reviewed and meets the project's [coding standards](#coding-standards).

### 4. **Pull Requests**

- **Do not select `main` as the target branch.**
- When you create a Pull Request (PR), always select the `dev` branch as the target for merging your changes.
- Fill in details and submit the pull request.
- Use clear, consistent Pull Request (PR) names to make collaboration easier. Follow this format:

```
<theme>.<module>.<unit>. <unit_name> <short_description_or_product_name>
```
Example - `2.2.1. Intro to RAP Code snippets`
- Clearly describe your changes and reference any relevant issues.
- The code must be reviewed by at least one tester and a member of the UK analysis for action team before it is merged.

## Coding standards
All contributions should adhere to the following standards:

### Coding practice
- Code follows the tidyverse style (for R) or the PEP8 style (for Python).
- Function, variable, and dataframe names are clear and logical.
- Code logic is clear and avoids unnecessary complexity.
- Hardcoded values (like file paths or constants) have been removed so that the user can easily customise these themselves.
- Repetition in the code is minimalised. For example, by moving reusable code into functions or classes.

### Code documentation

- A README file is submitted alongside your code explaining its purpose and how it can be used by the user. This may not be appropriate for all scripts, but it should be included for code designed to be adapted and used by the user for their own purposes.
- Comments are used to describe what the code is doing.
- Comments are up to date, so they do not confuse the user.
- Code is not commented out to adjust which lines of code run.
- All functions and classes are documented to describe what they do, what inputs they take and what they return.
- R functions are documented using roxygen2 comments. Python functions are documented using docstrings.

### Data management

- Any sensitive input data are omitted or replaced with fictional (i.e. ‘dummy’) data. There is no way to identify individuals from the data.
- All input data referred to in the code are submitted alongside the Unit content, so that the Tester can access and download the files.
- All input data referred to in the code is documented in your copy of the PPT Data Register, including where they come from, whether they are real or fictional data, assurance of their quality, and their importance to the Unit.

### Testing

- The programmer has tested the code from start to finish using one or more realistic end-to-end tests. In other words, the code does what it is supposed to.
- A peer reviewer (i.e. not the original programmer) has tested the code from start to finish using one or more realistic end-to-end tests. In other words, they have verified that the code does what it is supposed to.
- Core functionality has been unit tested, where appropriate (this may not be necessary for shorter code). See testthat for R and pytest for Python.
- Where appropriate, the code has been designed so that users can adapt it for their own purposes, including using their own input data instead of the example data provided. This may not be appropriate for all scripts, for example, source code for a tool. However, it is important to consider for code intended for users to make use of in their own work.

### Dependency management

- Required libraries and packages are documented, including their versions.
- Where appropriate, configuration files are included.
- Where appropriate, code runs independently of the operating system (for example there is suitable management of file paths for different operating systems).
- The code handles memory and processing efficiently, avoiding unnecessary data duplication and excessive memory usage.

## Raising Issues
If you encounter any problems or have suggestions for improvements, raise an issue in the repository. Provide as much detail as possible to help us understand and address the issue effectively.

You are also welcome to google message or email.

## Questions
If you have questions, please contact the project maintainers directly at [analysisforaction@ons.gov.uk](analysisforaction@ons.gov.uk) or in the google workspace.
