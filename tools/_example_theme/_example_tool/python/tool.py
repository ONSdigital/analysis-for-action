"""
Tool Name: Example Adder Tool
Description: Adds two numbers together and prints the result.
"""

import argparse


def add_numbers(x: float, y: float) -> float:
    """
    Adds two numbers together.

    Args:
        x (float): First number.
        y (float): Second number.

    Returns:
        float: The sum of x and y.
    """
    return x + y


def main():
    parser = argparse.ArgumentParser(description="Add two numbers together.")
    parser.add_argument("--x", type=float, required=True, help="First number")
    parser.add_argument("--y", type=float, required=True, help="Second number")
    args = parser.parse_args()
    result = add_numbers(args.x, args.y)
    print(f"The sum of {args.x} and {args.y} is {result}.")


if __name__ == "__main__":
    main()
