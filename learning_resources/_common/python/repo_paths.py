from __future__ import annotations

from pathlib import Path


def learning_resources_dir(start: Path | None = None) -> Path:
    current = (start or Path.cwd()).resolve()

    for candidate in (current, *current.parents):
        if candidate.name == "learning_resources":
            return candidate

        learning_resources = candidate / "learning_resources"
        if learning_resources.is_dir():
            return learning_resources

    raise FileNotFoundError(
        "Could not find the learning_resources folder from the current working directory."
    )


def data_path(*parts: str, start: Path | None = None) -> Path:
    return learning_resources_dir(start) / "data" / Path(*parts)


def local_resource_path(*parts: str, start: Path | None = None) -> Path:
    base_dir = learning_resources_dir(start)
    current = (start or Path.cwd()).resolve()

    try:
        relative_current = current.relative_to(base_dir)
    except ValueError as exc:
        raise FileNotFoundError(
            "Could not resolve a path inside learning_resources from the current working directory."
        ) from exc

    local_dir = base_dir / relative_current.parent
    return local_dir / Path(*parts)
