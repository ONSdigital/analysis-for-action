# Testing code

Code documentation helps others to understand what you expect your code to do and how to use it. Code tests verify that your analytical code is working as expected. You cannot confirm your code works correctly if you don’t carry out tests, so you cannot be confident that your analysis is fit for purpose without them.  

Testing brings strong benefits. It helps you assure your code quality and makes developing your code more efficient.
Code that has not been tested is more likely to contain errors and need more maintenance in the future.

## What should I test?

The question you need to answer here is a simple one:    

How can I demonstrate that my code does what it is supposed to do?    

As the developer of the code, you are best placed to decide what tests you need to put in place to answer that question confidently.

Take a risk-based approach to testing. You should use tests proportionately based on your analysis.  This usually means writing more tests for parts of your code that are very new, more complex, or carry more risk.  

When you are developing your tests, here are some points to think about:    

1.  **You don't need to test everything**. It is realistic to assume that third party functions and tools (such as base R and CRAN packages) which are adequately quality assured. You may be less confident about very new functionality from third parties, or experimental tools. You may decide to test these if needed.
2. **Check tool suitability**. Think carefully about whether third party tools really do what you need for your particular context.  For example, the base R `round()` function intentionally behaves differently to the rounding function in Excel. While you can be confident that `round()` works as specified, does it produce what you need?
3. **Use tests to validate your approach**. Testing is a great way to verify that your approach is the right one. Writing tests helps challenge assumptions and uncover edge cases, making your code more robust.
4. **Test based on risk**. Be guided by the risks you need to mitigate. For example, if inputs are invalid or unusual, do you want the code to stop with an error message or do something else? Use tests to check that the code does the right thing at the right time. 

## How are tests structured?

Tests come in many shapes and sizes, but usually follow the pattern:

1. Arrange - set up any objects needed for your test, for example sample input data and expected output data.
2. Act - run the code that you are testing (one or more functions or methods).
3. Assert - verify that the code performed the expected action, for example, that the output matched the expected output.

```{admonition} Key Learning
:class: admonition-learning

Learning materials on how to write unit tests can be found in [](learning.md).
```

This section assumes that you are using a testing framework to run your tests (for example, `pytest` for Python or `testthat` for R) and have your code in a package.
It is more difficult to test code that is not in a package and therefore follow the testing good practices described here.

## Write reproducible tests

As an analyst, you routinely check that your analysis is carried out correctly.
You might do this informally by running all or part of your analysis with example data or subsets of real data.

While this builds confidence, these checks should be reproducible. As code changes, tests must be repeatable and produce consistent results, both for you and others.
To ensure this, you can represent checks as code. This lets you or another analyst carry out the same verification again to get the same results. If a test is done manually, add a coded version so it can be rerun reliably.

Code that you write for testing should also follow the good practices described earlier on in this resource, in particular [](readable_code).

## Write repeatable tests

Your tests need to be repeatable for you to be able to trust their results.

For tests to run repeatably, each test must be independent.
There should not be a shared state between tests, for example a test should not depend on another test having already run.
You could intentionally randomise the order that tests are executed to encourage this.

Where possible, tests should be deterministic.
As such, the only reason for a test to fail should be that the code being tested is incorrect.
Where your code relies on randomness tests should reuse the same random seed each time.

Where this is not possible/logical for the scenario that you are testing, you may want to run the test
case multiple times and make an assertion about the distribution of the outcomes instead.
For example, if you are testing a function that simulates a coin flip you might run it 100 times and
check the proportion of heads versus tails is close to half (within a reasonable range).

## Run all tests against each change to your code

Run **all** tests whenever you make changes to your analysis.
This ensures that changes do not break the existing, intended functionality of your code.
Running the entire collection of tests has the added benefit of detecting unexpected side-effects of your changes.
For example, you might detect an unexpected failure in part of your code that you didn't change.

If you run tests regularly, you will be more able to fix any issues before changes are added to a stable or production version of your code (e.g. the `main` Git branch).

If you have altered the functionality of your code, this will likely break existing tests.
Failing tests here act as a good reminder that you should update your tests and documentation to reflect the new functionality.
Many testing frameworks support writing tests as examples in the function documentation.

It's not easy to remember to run your tests manually at regular intervals.
Use [continuous integration](continuous-integration) to automate
the running of tests. This way, you can trigger tests to run when any changes are made to your
remote version control repository.

## Record the outcomes of your tests

For auditability, it is important you record the outcome from running tests.
Record the test outcomes with the code, so that
it is clear which tests have been run successfully for a given version of the code.

As mentioned above, automating the running of tests on a version control platform is the simplest and
most effective way to achieve this association between the code version and test outcomes.
See [](continuous_integration) for further guidance on using these tools.

## Minimise your test data
Tests for analytical code will usually require data. To ensure that tests are clear in their meaning, you should use the smallest possible dataset for a test.

Good test data are:
* only just detailed enough data to carry out the test
* fake, static (hardcoded), and readable
* stored closely to the test

```{warning}
You must not copy the output from running your code to create your expected test outcomes.
If you do this the test will check that the function is running in the same way that it ran when you generated the data.
This assumes that your function is working correctly.

You must create your test data independently, ensuring that it reflects how you want your code to work, rather than how it currently works.
```

It's tempting to create a test dataset that closely mimics your real data. 

However, using minimal and general data in tests make it clearer on what is being tested, and also avoids any unnecessary disclosure.

Note that the way you write your test affects how the function is implemented.
Using minimal, generalised data encourages you to follow good practices when designing your function.

## Structure test files to match code structure

The chapter [](modular_code) describes how complexity can be managed by separating code into related groups.
Modular, well-structured code is easier to write tests for.
But you also want to make it easy to identify which tests relate to which parts of your code.

You should mirror the structure of your code in the structure of your test files.
You might use one test file per function/class or one test file per module.
Overall, the aim is to make it easy to find the tests for a given function or class and vice versa.

`````{tabs}
````{tab} Python
```
project/
│
├── src/
│   ├── __init__.py
│   ├── math.py
│   ├── strings.py
│   └── api.py
│
└── tests/
    ├── unit/
    │   ├── test_math.py
    │   └── test_strings.py
    │
    ├── integration/
    │   └── test_api.py
    │
    └── end_to_end/
        └── test_end_to_end_pipeline.py
```
````

````{tab} R
```
project/  
│  
├── .Rproj  
│  
├── R/  
│   ├── math.R  
│   ├── strings.R  
│   └── api.R  
│  
└── tests/  
    │  
    ├── testthat/  
    │   ├── test-maths_abs.R  
    │   ├── test-maths_sum.R  
    │   └── test-strings_option.R  
    │  
    └── testthat.R  
```
````

`````

The Python example above has one file containing unit tests for each module (group of related functions and classes).
When using this structure, you may want to also group multiple test functions into test classes.
Having one test class per function/class that you are testing will make it clear that the group of tests relates to that function or class in your source code.

```{code-block} python
# An example for tests/unit/test_math.py

class TestAbs:
    def test_abs_all_positive_values(self):
        ...

    def test_abs_all_negative_values(self):
        ...
    
    ...


class TestSum:
    def test_sum_all_positive_values(self):
        ...

    def test_sum_all_negative_values(self):
        ...
    
    ...
```

Using classes for unit tests has many additional benefits, allowing reuse of the same logic either by class inheritance, or through fixtures.
Similar to fixtures,
you can use the same pieces of logic through class inheritance in Python.
Note that it is easier to mix up and link unit tests when using class inheritance.
The following code block demonstrates an example of class inheritance which will inherit both the
variable and the `test_var_positive` unit test, meaning three unit tests are run.
You can overwrite the variable within the subclass at any time, but will still inherit defined functions/tests from the parent class.

```{code-block} python
class TestBase:
    var = 3

    def test_var_positive(self):
        assert self.var >= 0

class TestSub(TestBase):
    var = 8
    def test_var_even(self):
        assert self.var % 2 == 0
```


The R  project structure above has one test file per function in the modules.
There are multiple test files for the `math.R` module because it contains more than one function.
Tests in these test files do not need grouping into classes, as the file name is used to indicate exactly which function or class is being tested.
Tests in R are now linked together based on the file, previously named contexts.
Context is now tied to test file name to ensure they are always synced.
The `context()` function is now depreciated and should be removed from your R script.

These are the common conventions for each of Python and R, but are interchangeable.
Use the approach that makes it easiest for developers to identify the relationship between tests and the code they are testing.

Note that some test frameworks allow you to keep the tests in the same file as the code that is being tested.
This is a good way of keeping tests and code associated,
but you should follow good modular code practices to separate unrelated code into different files.
Additional arguments are made to separate tests and functions when you are packaging your code.
If you store unit tests and code in the same file,
the unit tests would also be packaged and installed by additional users.
Therefore when packaging code,
you should move the unit tests to an adjacent test folder as users will not need to have unit tests installed when installing the package.

When separating unit tests into main package and testing scripts, it is important to import your package to ensure the correct functions are being unit tested.
For the module structure outlined previously, use `from src.math import my_math_function`.
For R, you need to specify the name of your package within the `testthat.R` file within your tests folder.

## Structuring tests

To maintain a consistency across modules you develop, you should follow PEP8 (Python) [1]
or Google / tidyverse (R) [2, 3] standards when structuring unit tests.

For python this involves importing all needed functions at the beginning of the test file.
To ensure you import the correct functions from your module,
it is recommended to install a local editable version into your virtual environment.
Run `pip install -e .` and any changes made to your
module functions will also be updated in your python environment.
Following this it is recommended to define fixtures, classes and then test functions.

You should follow a similar structure in R, with all modules loaded in the beginning of a test script.
Test contexts and then functions should be defined in turn.

Generally, tests within the same file should follow some structure or order.
It is recommended that the order that functions are defined in the main script is also mirrored
within the test scripts.
This will make it easier for future developers to debug and follow and
ensures that no functions have been missed and do not have unit tests written.


## Test that new logic is correct using unit tests

When you implement new logic in code, tests are required to assure that the code works as expected.

To make sure that your code works as expected, you should write tests for each individual unit in your code.
A unit is the smallest modular piece of logic in the code - a function or method.

Unit tests should cover realistic use cases for your function, such as:
* boundary cases, like the highest and lowest expected input values
* positive, negative, zero, and missing value inputs
* examples that trigger errors that have been defined in your code

When your function documentation describes the expected inputs to your function, there is less need to test unexpected cases.
If misuse is still likely or risky, then providing the user with an error is the best approach to mitigate this risk.

Reusing logic from an existing package that is already tested does not require tests when you use that logic alone.
You should be aware of whether your dependencies are sufficiently tested.
Newly developed packages or those with very few users are more likely to not be thoroughly tested.

## Test that different parts of the code interact correctly using integration tests

Integration tests are those that test on a higher level than a unit. This includes testing that:
* multiple units work together correctly
* multiple high level functions work together (e.g., many units grouped into stages of a pipeline)
* the analysis works with typical inputs from other systems

Integration tests give you assurance that your analysis is fit for purpose.
Additionally, they give you safety when refactoring or rearranging large parts of code.
Refactoring is an important part of managing the complexity of your analysis as it grows.

You can similarly consider a high level stage of an analysis pipeline.
If you have a stage responsible for imputing missing values, you can create integration tests to check that all values are
imputed and that you used particular imputation methods for specific cases in your test data.
When changes are made to individual imputation methods you might not expect these general characteristics to change.
This test helps to identify cases where this inadvertently has changed.

```{note}
Integration tests are more robust when they focus on general high level outcomes that you don't expect to change often.
Integration tests that check very specific outcomes will need to be updated with any small change to the logic within the part that is being tested.
```

## Test that the analysis runs as expected using end-to-end tests

End-to-end testing (sometimes called system testing) checks the entire workflow from start to finish, ensuring all components work correctly in real-world scenarios. While integration testing focuses on the interaction of specific modules, end-to-end testing involves all elements of a pipeline. This is useful when refactoring code for example, by providing assurance that overall functionality remains unchanged. 

For example, a piece of analysis has an end-to-end test to check that outputs are generated and the data are the right shape or format. There might also be a "regression" test that checks that the exact values in the output remain the same. After you make any changes to tidy up or refactor the code, these end-to-end tests can be run to assure no functionality has accidentally changed.

Use end-to-end tests to also quality assure a project from an end user's perspective; these should be run in an environment that replicates the production environment as closely as possible. This type of testing can catch errors that individual unit tests might miss and confirms that the output is fit for purpose and the user requirements are met. End-to-end testing is a form of 'black box' testing, meaning the tester verifies functionality without focusing on the underlying code. It is therefore important to use end to end testing alongside other forms of testing such as unit tests.


## Good practices for integration and end-to-end testing

When devising an integration or end-to-end testing it’s important to follow these good practices:

- Planning ahead: Have a clear plan of what you want to test and how before you start.
- Testing Early:  Start testing integration as soon as parts are combined rather than waiting until everything is finished. This helps catch issues sooner.
- Use Real Data: Whenever possible, use real data in your tests to make sure everything behaves like it would in the real world. When not possible, make sure the test data reflect the complexities of real data.
- Automate tests: Automate your integration tests. This makes it easier to run them frequently and catch problems quickly.
- Checking dependencies: Make sure to test how different components rely on each other, as issues can arise there.
- Test for failures: don’t just test for success; also check how the system behaves when things go wrong. This helps ensure it handles errors gracefully.
- Keep tests isolated: Try to isolate tests so that one failure doesn’t affect another, making it easier to pinpoint issues.
- Document: Keep a record of tests, results, and issues found. This helps with future testing and understanding what changes might affect integration.


## Write tests to assure that bugs are fixed

Each time you find a bug in your code, you should write a new test to assert that the code works correctly.
Once you resolve the issue, this new test should pass and give you confidence that the bug has been fixed.

When you change or refactor your code in future, the new tests
will continue to assure that bugs you have already fixed will not reappear.
Doing this increases the coverage of your tests in a proportionate way.

## Write tests before writing logic

The best practice for testing code is to use test-driven development (TDD).
This is an iterative approach that involves writing tests before writing the logic to meet the tests.

If you know the expected outcome—based on user needs or internal requirements—you can define the test first, before you think about how you are going to write the solution.

TDD typically repeats three steps:
1. Red - Write a test that you expect to fail.
2. Green - Write or update our code to pass the new test.
3. Refactor - Make improvements to the quality of the code without changing the functionality.

As with any code that is adequately covered by tests, code written using TDD can be safely refactored. You can be more confident that your tests will capture any changes that would unintentionally alter the way your code works.

This iterative approach also helps manage complexity. You should start by writing tests with minimal functionality and gradually expanding both tests and logic.

Beyond test coverage, TDD encourages best practices, including keeping test data minimal, writing simple functions and classes and developing focused code. Though it takes practice, it leads to clean, robust and adaptable code.



## Acceptance and Stress Testing in Reproducible Analytical Pipelines

In the development of reproducible analytical pipelines, acceptance testing and stress testing can be useful to consider, to ensure reliability, usability, and robustness of pipelines.

### Acceptance testing
Acceptance testing verifies that the pipeline meets user, business, and operational requirements. It ensures that analytical outputs are accurate, relevant, and aligned with stakeholder expectations. There are three types of acceptance testing:
* User Acceptance Testing (UAT) enables end-users to test the pipeline to ensure it meets their needs and provides accurate outputs.
* Business Acceptance Testing (BAT) ensures the pipeline supports business processes and integrates smoothly with existing workflows.
* Operational Acceptance Testing (OAT) checks that the pipeline is ready for deployment, including aspects like error handling, maintenance, and recovery.

These tests help validate that the pipeline is not only technically sound but also fit for purpose in real-world settings.

### Stress Testing

Stress testing evaluates the pipeline’s resilience under extreme or unexpected conditions—such as large datasets or noisy data.

By simulating challenging scenarios, stress testing helps identify performance issues and ensures the pipeline can maintain integrity and produce reliable outputs even under pressure. Stress testing involves introducing variations or noise into the input data and observing how this affects the pipeline’s outputs, to ensure it can handle real-world challenges.

## Reduce repetition in test code (fixtures and parameterised tests)
Where possible, you should reduce repetition in your tests. As with functional code, test code is much easier to maintain when it is [modular and reusable. 

### Use fixtures to reduce repetition in test set up

As your test suite grows, many of your tests may use similar code to prepare your tests or to clean up after each test has run. You can be more tolerant of repetition in test code. However, copying code snippets for each test is laborious and increases the risk of applying those steps inconsistently. You can use fixtures to help avoid this form of repetition in tests. 

A fixture allows you to define your test preparation and clean up as functions. You then use the fixture to carry out these steps consistently for each test that they are required for.

In Class-based testing frameworks, these functions tend to be separated into `SetUp` and `TearDown` functions. These are set to run before and after each test, respectively.

Fixtures can be scoped to run:
* Per test (function)
* Per group of tests
* Once per session (session), useful for expensive setup like starting a Spark session.

Fixtures also help reset environments, such as cleaning up test databases or temporary files.

For usage details see the documentation for packages that offer fixtures:
* [Python `pytest` Fixture](https://docs.pytest.org/en/stable/fixture.html) documentation [4]
* [R `testthat` Fixture](https://testthat.r-lib.org/articles/test-fixtures.html) documentation [5]

### Use parameterisation to reduce repetition in test logic

Similar steps are often repeated when testing multiple combinations of inputs and outputs.
Parameterisation allows reduction of repetition in test code, in a similar way to writing your logic in functions.
Specify pairs of inputs and expected outputs, so your testing tool can repeat the same test for each scenario.

Using parameterisation in a test framework is equivalent to using a for-loop to apply a test function over multiple inputs and expected outputs.

In `pytest`, this can be achieved using the [Parametrize mark](https://docs.pytest.org/en/stable/parametrize.html) [6].

In R, the `patrick` package extends `testthat` to provide a
[`with_parameters_test_that`](https://rdrr.io/cran/patrick/man/with_parameters_test_that.html) function to achieve this [7].


## Lacking time? The risks to skipping tests
In an ideal world, you would never skip testing code, ensuring the software is reliable
and easily reproducible. However, in practice there are times when skipping tests may be necessary, such as due to tight deadlines, limited resources, or the need to quickly get a feature up
and running. While this can save time in the moment, it’s important to be cautious, as
skipping tests can lead to hidden problems that may become harder to fix later, particularly
as the project grows. Whenever tests are set aside, it’s best to have a plan for going back to add
them, to avoid risks to the stability and quality of the software.

<details> 
<summary><h2 style="display:inline-block">References </h2></summary>

1) Van Rossum G, Warsaw B, Coghlan N. PEP 8 – Style Guide for Python Code [Online]. Python Software Foundation; 2001 [Accessed September 24 2025]. Available from: https://www.python.org/dev/peps/pep-0008/

2) Google. Google R Style Guide [Online]. Google. [Accessed September 24 2025]. Available from: https://google.github.io/styleguide/Rguide.html

3) Wickham H. The Tidyverse Style Guide [Online]. Tidyverse. [Accessed September 24 2025]. Available from: https://style.tidyverse.org/

4) pytest. Fixtures: explicit, modular, scalable [Online]. [Accessed September 24 2025]. Available from: https://docs.pytest.org/en/stable/explanation/fixtures.html

5) testthat. Test fixtures [Online]. testthat.r-lib.org. [Accessed September 25 2025]. Available from: https://testthat.r-lib.org/articles/test-fixtures.html

6) pytest. How to parametrize fixtures and test functions [Online]. pytest.org. [Accessed September 25 2025]. Available from: https://docs.pytest.org/en/stable/how-to/parametrize.html

</details>