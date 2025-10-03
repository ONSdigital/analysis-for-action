# Contributing
Thank you for your interest in contributing to this project.

**Please note:** We are not accepting public contributions at this stage. This guidance is intended only for delivery partners and approved collaborators.

## Contribution Process

### 1. **Cloning the Repository**
To begin contributing, clone the repository directly:

```cmd
git clone https://github.com/ONSdigital/analysis-for-action.git
cd analysis-for-action
```

### 2. **Making Changes**

- Create a new branch for your changes.
- Commit and push your code to your branch.
- Add any dependencies to the relevant files:
  - For Python, update `requirements.txt`.
  - For R, use `renv::snapshot()` to update `renv.lock`.
- Ensure your code has been peer reviewed and meets the project's coding standards.

### 3. **Pull Requests**

- When you create a Pull Request (PR), always select the `dev` branch as the target for merging your changes.
  **Do not select `main` as the target branch.**
- Fill in details and submit the pull request.
- Clearly describe your changes and reference any relevant issues.
- The code must be reviewed by at least one tester and a member of the UK analysis for action team before it is merged.

## **Pull Request Naming Convention**
Use clear, consistent Pull Request (PR) names to make collaboration easier. Follow this format:

```
<theme>.<module>.<unit>.<unit_name>_<short_description_or_product_name>
```

**Example:**
- `2.2.1.intro_to_rap_code_snippets`

## Questions
If you have questions, please contact the project maintainers directly at [analysisforaction@ons.gov.uk](analysisforaction@ons.gov.uk).
