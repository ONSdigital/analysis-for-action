## Pull request naming convention
   Use clear, consistent Pull Request (PR) names to make collaboration easier. Follow this format:

   ```
   <theme>.<module>.<unit>. <unit_name> <short_description_or_product_name>
   ```

   **Example:**
   - `2.2.1. Intro to RAP Code snippets`

## Description
Please include a summary of the changes.

  - What is this change?

## Type of change

*You can delete options that are not relevant.*

- [ ] New feature - *non-breaking change*
- [ ] Bug fix - *non-breaking change*
- [ ] Breaking change - *backwards incompatible change, changes expected behaviour*
- [ ] Non-user facing change, structural change, dev functionality, docs ...

## Checklist:

- [ ] **Test run**: Have you run the code to ensure it works as expected?
- [ ] **Dependencies**: Have you added any new dependencies to `requirements.txt`
- [ ] **Confidentiality**: Has any sensitive data been removed from code, properly protected, anonymised, or encrypted where necessary?
- [ ] **Clear naming conventions**: Are variables, functions, and classes named descriptively and consistently?
- [ ] **Modularity**: Is the code divided into clear, reusable functions or modules?
- [ ] **Code comments**: Are there sufficient comments explaining key parts of the logic, especially complex ones?
- [ ] **Code formatting**: Is the code written in both R/Python language?
- [ ] **Avoid hardcoding**: Have any hardcoded values (like file paths or constants) been removed?
- [ ] **Resource management**: Does the code handle memory and processing efficiently, avoiding unnecessary data duplication or excessive memory usage?
- [ ] **Usage instructions**: Is there documentation explaining how to set up and run the code, such as README files?

<br>

#  Peer review
Any new code includes all the following:

- **Documentation**: docstrings, comments have been added/ updated.
- **Style guidelines**: New code conforms to the project's contribution guidelines.
- **Functionality**: The code works as expected.
- **Complexity**: The code is not overly complex, logic has been split into appropriately sized functions, etc..

### Review comments
Suggestions should be tailored to the code that you are reviewing. Provide context.
Be critical and clear, but not mean. Ask questions and set actions.
<details><summary>These might include:</summary>

- bugs that need fixing (does it work as expected?)
- alternative methods (could it be written more efficiently or with more clarity?)
- documentation improvements (does the documentation reflect how the code actually works?)
- code style improvements (could the code be written more clearly?)
</details>
<br>

*Further reading: [code review best practices](https://best-practice-and-impact.github.io/qa-of-code-guidance/peer_review.html)*
