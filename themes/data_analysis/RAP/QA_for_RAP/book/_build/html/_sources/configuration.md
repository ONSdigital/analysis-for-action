# Configuration

Configuration describes how your code runs when you execute it.

In analysis, it it common to want to run the analysis code using different inputs or parameters, and also for other analysts to be able to run the code on different machines to reproduce the results.
This section describes how to define analysis configuration that is easy to update and can remain separate from the logic in your analysis.


## Basic configuration

Configuration for your analysis code should include high level parameters (settings) that can be used to easily adjust how your analysis runs.
This might include paths to input and output files, database connection settings, and model parameters that are likely to be adjusted between runs.

In early development of your analysis, lets imagine a script that looks something like this:

````{tabs}

```{code-tab} python
# Note: this is not an example of good practice
# This is intended as example of what early pipeline code might look like
data = read_csv("C:/a/very/specific/path/to/input_data.csv") 

variables_test, variables_train, outcome_test, outcome_train = train_test_split(data["a", "b", "c"], data["outcome"], test_size=0.3, random_seed=42)

model = Model()
model.fit(variables_train, outcome_train)

# prediction = model.predict(variables_test, constant_a=4.5, max_v=100)
prediction = model.predict(variables_test, constant_a=7, max_v=1000)

prediction.to_csv("outputs/predictions.csv")

```

```{code-tab} r R
# Note: this is not an example of good practice
# This is intended as example of what early pipeline code might look like
data <- utils::read.csv("C:/a/very/specific/path/to/input_data.csv") 

set.seed(42)
split <- caTools::sample.split(data, SplitRatio = .3)

train_data <- data[split, ]
test_data <- data[!split, ]

model <- glm(formula = outcome ~ a + b + c, family = binomial(link = "logit"), data = train_data, method = "model.frame")
# model <- glm(formula = outcome ~ a + b + c, family = binomial(link = "logit"), data = train_data, method = "glm.fit")

prediction <- predict(model, test_data, type = "response")

utils::write.csv(prediction, "outputs/predictions.csv")

```

````

Here the code reads in some data and splits it into subsets for training and testing a model.
The model's predictions are exported to a `.csv` file.

The file paths used to read and write data in the script are particular to the working environment.
This makes the code harder to reuse or share, especially if paths or parameters differ across machines. Other analysts would need to find these in the code and replace them.

Instead, a better approach would be to clearly outline your configurations. These should be stored in variables to make it easier to adjust them consistently throughout the script.

````{tabs}

```{code-tab} python
# Note: this is not an example of good practice
# This is intended as an example of basic in-code configuration. 

# Configuration
input_path = "C:/a/very/specific/path/to/input_data.csv"
output_path = "outputs/predictions.csv"

test_split_proportion = 0.3
random_seed = 42

prediction_parameters = {
    "constant_a": 7,
    "max_v": 1000
}

# Analysis
data = read_csv(input_path)

variables_test, variables_train, outcome_test, outcome_train = train_test_split(data["a", "b", "c"], data["outcome"], test_size=test_split_proportion, random_seed=random_seed)

model = Model()
model.fit(variables_train, outcome_train)

prediction = model.predict(variables_test, constant_a=prediction_parameters["constant_a"], max_v=prediction_parameters["max_v"])

prediction.to_csv(output_path)
```

```{code-tab} r R
# Note: this is not an example of good practice
# This is intended as an example of basic in-code configuration. 

# Configuration
input_path <- "C:/a/very/specific/path/to/input_data.csv"
output_path <- "outputs/predictions.csv"

random_seed = 42
test_split_proportion = .3
model_method = "glm.fit"

#analysis
data <- utils::read.csv(input_path) 

set.seed(random_seed)
split <- caTools::sample.split(data, SplitRatio = test_split_proportion)

train_data <- data[split, ]
test_data <- data[!split, ]

model <- glm(formula = outcome ~ a + b + c, family = binomial(link = "logit"), data = train_data, method = model_method)

prediction <- predict(model, test_data, type = "response")

utils::write.csv(prediction, output_path)
```

````

Separating configuration from the rest of your code makes it easy to adjust parameters and apply them consistently throughout the analysis script.
Basic objects (like lists and dictionaries) can be used to group related parameters.
These objects can then be referenced in the analysis section of the script.

The configuration could be extended to include other parameters, such as which variables are being selecting to train the model.
However, the configuration must be kept simple and easy to maintain.
Before moving aspects of code to the configuration, consider whether it improves your workflow.
You should include things that are dependent on the computer that you are using (e.g., file paths) or are likely to change between runs of your analysis, in your configuration.


## Use separate configuration files

The previous example can be taken one step further using independent configuration files.
For this, the collection of variables, containing parameters and options for the analysis are moved to a separate file.
These files can be written in the same language as your code or other simple languages, as described in the following subsections.

Instead of defining parameters in your script, you can store them in a separate configuration file. This keeps your code focused on logic and makes it easier to switch between setups.

The benefits of this are that you can:

* version control code and config files separately.
* easily switch between multiple configurations by providing the analysis code with different configuration files.
* track which configuration file was used to generate specific results.

You may not want to version control your configuration file if it includes file paths that are specific to your machine or references to sensitive data.
Instead, include a sample or example configuration file, so others can use this as a template to configure the analysis for their own environment. Ensure to keep this template up to date, so that it is compatible with your code.


### Use code files for configuration

Parameter variables from a script can be copied directly into a separate script to serve as a configuration file.

In Python, variables from the config files can be imported into your analysis script.
In R, your script might `source()` the config file to read the variables into the R environment.


### Use dedicated configuration files

Many other file formats can be used to store configuration parameters.
You may have come across data-serialisation languages (including YAML, TOML, JSON and XML), which can be used independently of your programming language.

The above example configuration is presented below in YAML:

```yaml
input_path: "C:/a/very/specific/path/to/input_data.csv"
output_path: "outputs/predictions.csv"

test_split_proportion: 0.3
random_seed: 42

prediction_parameters:
    constant_a: 7
    max_v: 1000
```

You can use relevant libraries to read configuration files that are written in other languages.
For example, the YAML example can be read into the analysis like this:

````{tabs}

```{code-tab} python
import yaml

with open("./my_config.yaml") as file:
    config = yaml.safe_load(file)

data = read_csv(config["input_path"])
...
```

```{code-tab} r R
config <- yaml::yaml.load_file(config_path)

data <- read.csv(config$input_path)
...
```

````

Configuration file formats like YAML and TOML are compact and human-readable.
This makes them easy to interpret and update, even without knowledge of the underlying code used in the analysis.
Reading these files in produces a single object containing all of the `key:value` pairs defined in the configuration file.
The configuration parameters can then be selected using their keys in the analysis.


## Use configuration files as arguments

In the previous example, configuration options were stored in a separate file and referenced in the analysis script. However, the file path was hard-coded, which can cause issues if the script is run on a different machine or if a different configuration file needs to be used.

To make this more flexible, the analysis script can be set up to accept the configuration file path as an input argument. This allows the script to run with different configurations without modifying the code. A simple example of this approach is shown below.

````{tabs}

```{code-tab} python
import sys
import yaml

if len(sys.argv) < 2:
    # The Python script name is counted as the first argument
    raise ValueError("Configuration file must be passed as an argument.")

config_path = sys.argv[1]
with open(config_path) as file:
    config = yaml.safe_load(file)
...
```

```{code-tab} r R
args <- commandArgs()
if (length(args) < 1) {
  stop("Configuration file must be passed as an argument.")
}

config_path <- args[1]
config <- yaml::yaml.load_file(config_path)
...
```

````

When executing the analysis file above, you pass the path to the configuration file after calling the script.
If the script was named 'analysis_script', it would be called from the command line as:

````{tabs}

```{code-tab} sh Python
python analysis_script.py /path/to/my_configuration.yaml
```

```{code-tab} sh R
Rscript analysis_script.R /path/to/my_configuration.yaml
```

````

To run the analysis with a different configuration, simply pass a new configuration file to the script. This avoids the need to modify the code when change to the configuration are made.

```{note}
It is possible to pass configuration options directly as arguments in this way, instead of referencing a configuration file.
However, you should use configuration files as they allow you to document which configuration has been used to produce your analysis outputs, for reproducibility.
```


(environment-variables)=
## Configure secrets as environment variables

Environment variables are variables that are available in a particular environment.
In most analysis contexts, the environment is the user environment that the code is running from. This might be your local machine or an analysis platform.

If your code depends on credentials of some kind, do not write these in your code. You can store passwords and keys in configuration files, but there is a risk that these files may be included in [version control](version_control.md).
To avoid this risk, store this information in local environment variables.

Environment variables can also be useful for storing other environment-dependent variables.
For example, the location of a database or a software dependency.

In Unix systems (e.g., Linux and Mac), you can set environment variables in the terminal using `export` and delete them using `unset`:

```none
export SECRET_KEY="mysupersecretpassword"
unset SECRET_KEY
```

In Windows, the equivalent commands to these are:

```none
setx SECRET_KEY "mysupersecretpassword"
reg delete HKCU\Environment /F /V SECRET_KEY
```

You can alternatively define them using a graphical interface under `Edit environment variables for your account` in your Windows settings.

Once stored in environment variables, these variables will remain available in your environment until you delete them.

You can access this variable in your code like so:

````{tabs}

```{code-tab} python
import os

my_key = os.environ.get("SECRET_KEY")
```

```{code-tab} r R
my_key <- Sys.getenv("SECRET_KEY")
```

````

It is then safer for this code to be shared with others, as they can't acquire your credentials without access to your environment.
