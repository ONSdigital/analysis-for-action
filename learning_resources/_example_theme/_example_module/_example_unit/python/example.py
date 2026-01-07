"""
[unit name], [chapter name] example code
"""


def example_function(x: int, y: int) -> int:
    """
    Adds two integers together.

    Args:
        x (int): The first integer.
        y (int): The second integer.

    Returns:
        int: The sum of x and y.

    Example:
        >>> example_function(2, 3)
        5
    """
    return x + y


if __name__ == "__main__":
    # Example usage of the function
    a = 2
    b = 3
    result = example_function(a, b)
    print(f"The sum of {a} and {b} is {result}.")
