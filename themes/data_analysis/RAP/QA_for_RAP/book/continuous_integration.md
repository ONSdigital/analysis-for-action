# Automating code quality assurance

## Motivation

You can automate various tasks to increase the quality of code and make development easier and less tedious.
Automating the running of unit tests is especially important to establish trust in your pipeline or package, by ensuring that all unit tests pass before every merge.


(automate-tests)=
### Automate tests to reduce risk of errors

You should run tests whenever you make changes to your project.
This ensures that changes do not break the existing, intended functionality of your code.
However, it is easy to forget to run your tests at regular intervals.

Automatic testing, amongst other quality assurance measures, can be triggered when you make changes to your remote version control repository.
You can use these tools to ensure that all changes to a project are tested.
Additionally, it allows others, who are reviewing your code, to see the results of your tests.


(continuous-integration)=
## Commit small changes often

Committing small changes regularly is often referred to as Continuous Integration (CI).
You can achieve this easily through the use of [version control](version_control.md), such as Git.

You should commit every time you make a working change.

As a very rough guide, you should expect to commit a few times each hour and push your changes to your shared software repository at least once a day.
If the task is unfinished at the end of the day, you should consider if the task has been sufficiently broken down.

CI should be underpinned by automating routine code quality assurance tasks.
This quality assurance includes verifying that your code successfully builds or installs. It also ensures your [code tests](testing_code.md) run successfully.
You can achieve this in a number of ways such as use of Git hooks and workflows.


## Use Git hooks to encourage good practice

Git hooks are scripts that can be set to run locally at specific points in your Git workflow,
such as pre-commit, pre-push, etc.
You can use them to automate code quality assurance tasks, e.g., run tests, follow style guides, or enforce commit standards.

For example, you could set up a `pre-commit` or `pre-push` hook that runs your tests before you make each commit or push to the remote repository.
This might stop your commit/push if the tests fail, so that you won't push breaking changes to your remote repository.


(linters-formatters)=
### Linters and formatters

Style guides are important for making sure your code is clear and readable and should form part of your quality assurance process.
However, as discussed in [](automate-style-checks), the process of checking and fixing code for style and formatting is tedious.
Automation can speed up this work, either by providing suggestions as you write the code or by reformatting your code to follow your chosen style.

Two main types of tool exist for these tasks:

* Linters - these analyse your code to flag stylistic errors (and sometimes bugs or security issues too).
* Formatters - these not only detect when you have diverged from a style, but will automatically correct the formatting of your code to conform to a particular style.

```{list-table} Packages that can be used for linting or formatting in Python and R
:header-rows: 1
:name: linters

* - Language
  - Linters
  - Formatters
* - Python
  - `flake8`, `pylint`, `Bandit`
  - `Black`, `Isort`
* - R
  - `lintr`
  - `formatR`, `styler`
* - Markdown
  - `pymarkdownlnt`
  -
```

You can use these tools locally (in the command line) or as git pre-commit hooks.
As described above, using pre-commit hooks allows you to run these automatically every time there are changes;
this can reduce the burden on developers and reviewers checking that code conforms to style guides.

Make sure you read the documentation for these tools before you use them to understand what they are checking or changing in your code.
You can configure some of them to ignore or detect specific types of formatting error.
You can also run multiples of the tools to catch a broader range of stylistic or programmatic errors.

## Workflows

GitHub Actions and GitLab Pipelines are both able to define custom workflows using YAML.
Workflow refers to a defined sequence of steps and actions that you need to perform to complete a specific task or process.
Workflows are commonly used in software development to automate repetitive or complex tasks,
such as building and deploying software, testing code, and managing code reviews.
GitHub Actions and GitLab Pipelines both allow automated workflows that trigger
builds and tests whenever code changes are pushed to the repository.

### Example use cases for GitHub Actions

Here are some examples to support understanding of these ideas.

#### Configure GitHub actions to automate tests

Here is an example configuration file, for use with GitHub actions.
The `YAML` file format, used below, is common to a number of other CI tools.

```yaml
name: Test python package

on:
  push:
    branches:
      - master
  pull_request:

jobs:
  build:

    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: [3.8, 3.9, 3.10, 3.11]

    steps:
    - uses: actions/checkout@v3

    - name: Set up Python ${{ matrix.python-version }}
      uses: actions/setup-python@v4
      with:
        python-version: ${{ matrix.python-version }}

    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install pytest 
        pip install -r requirements.txt
        
    - name: Test with pytest
      run: |
        pytest
```

The first section of this example describes when you should run the workflow.
In this case, the CI workflow is run whenever code is `push`ed to the `master` branch or where any Pull Request is created.
In the case of Pull Requests, the results of the CI workflow will be report on the request's page.
If any of the workflow stages fail, this can block the merge of these changes onto a more stable branch.
Subsequent commits to the source branch will trigger the CI workflow to run again.

Below `jobs`, the tasks are defined that should run when the workflow is triggered.
Here the operating system is defined too - the Linux operating system `ubuntu`.
The `matrix` section under `strategy` defines parameters for the workflow.
The workflow will be repeated for each combination of parameters supplied here - in this case 4 recent Python versions.

The individual stages of the workflow are defined under `steps`.
`steps` typically have an informative name and run code to perform an action.
Here `uses: actions/checkout@v3` references [existing code](https://github.com/actions/checkout) that will retrieve the code from our repo.
The subsequent `steps` will use this code.
The next step provides us with a specific Python version, as specified in the `matrix`.
Then dependencies/requirements are installed for the code and the `pytest` module.
Finally, run `pytest` to check that the code is working as expected.

This workflow will report whether the test code ran successfully for each of the specified Python versions.

#### Configure GitHub actions to build and deploy documentation

It is important to maintain the documentation relating to your project to ensure contributors and users can understand, maintain, and use your product correctly.
One basic way of doing this is maintaining markdown files within a GitHub repository.
However, multiple tools exist that can transform these markdown files into HTML content.
A popular tool for building and deploying HTML documentation is Sphinx.

The UK Gov Cookie Cutter package 'govcookiecutter' is an example of a repository that uses sphinx to build its documentation. (ref)
 
### Example GitLab Pipeline

GitLab has an equivalent to GitHub Actions called GitLab Pipelines. (ref)
The use cases for these are practically the same, with a change in syntax and file structure.

### Example of automating code quality assurance

For an example of continuous intregration, please refer to the RAP in Action material (link to RAP in Action training to be added) to see how this was implemented in a COVID-19 project.

# References

govcookiecutter  (https://github.com/best-practice-and-impact/govcookiecutter/blob/main/.github/workflows/govcookiecutter-deploy-documentation.yml)

Gitlab Pipelines (https://docs.gitlab.com/ee/ci/).