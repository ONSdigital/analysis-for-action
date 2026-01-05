# Analysis for Action code snippets repository

This repository contains tools and example code snippets in **Python** and **R** to support materials and case studies for the Analysis for Action platform. The content is organised by **themes**, **modules** and **units** to align with the structure of the website.

---

## Repository Structure

```
analysis-for-action/
├── learning_resources/             # Top-level folder containing all learning resource code examples.
│   ├── data/                       # Example datasets used for learning resource examples.
│   ├── theme1/                     # A specific theme (e.g., data_analysis, outputs_and_reporting).
│   │   ├── module1/                # A module within a theme.
│   │   │   ├── unit1/              # A unit within a module.
│   │   │   │   ├── docs/           # Documentation for the specific unit code examples.
│   │   │   │   ├── python/         # Python code examples for the specific unit.
│   │   │   │   │   └── example1.py
│   │   │   │   └── r/              # R code examples for the specific unit.
│   │   │   │       └── example1.R
│   │   │   └── unit2/
│   │   │       ├── docs/
│   │   │       ├── python/
│   │   │       └── r/
│   │   └── module2/
│   │       └── unit1/
│   │           ├── docs/
│   │           ├── python/
│   │           └── r/
├── tools/                    # Top-level folder containing all tools.
│   ├── theme1/               # A specific theme (e.g., data_analysis, outputs_and_reporting).
│   │   └── tool1/            # A specific tool.
│   │       ├── docs/         # Documentation for the specific tool.
│   │       ├── python/       # Python code for the specific tool.
│   │       │   └── tool.py
│   │       └── r/            # R code for the specific tool.
│   │           └── tool.R
├── requirements.txt      # Python dependencies
├── setup.R               # R dependencies setup script
├── .pre-commit-config.yaml
├── .gitignore
├── README.md
└── CHANGELOG
```

---

## Getting Started

### Python Setup

1. Ensure you have Python 3.12+ installed
2. (Recommended) Create a virtual environment:
   ```sh
   python -m venv .venv
   ```
3. Activate the virtual environment:
   - Windows (cmd):
     ```sh
     .venv\Scripts\activate
     ```
   - macOS/Linux:
     ```sh
     source .venv/bin/activate
     ```
4. Install dependencies:
   ```sh
   pip install -r requirements.txt
   ```

### R Setup

1. Ensure you have R installed.
2. Run the provided `setup.R` script to install required packages:
   ```R
   source("setup.R")
   ```
   This will install all necessary R packages for the project.

---

## How to Use

Learning resources and tools are structured in the same way as the platform content.

`learning_resources/` contains code snippets and examples relating to written content.
`tools/` contains more comprehensive scripts and functions that can be used as standalone tools that can be adapted for your own use.

> Note: Some tools on the platform are located in standalone repositories. Please refer to the platform for the full range of tools.

To use this repository:
- Navigate to the relevant learning resource code or tool of interest.
- Choose the `python/` or `r/` folder depending on your language of interest.
- Run the code snippets as needed for your learning or case study
or
- Use or adapt the tools provided in the `tools/` directory.
