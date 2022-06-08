# Populate `pyproject.toml`

Let's take our project to the next level,
and prepare it for distribution via PyPI.
Never mind that it doesn't have any actual code.

We'll use
[flit](https://github.com/takluyver/flit)
to generate a `pyproject.toml`:

```console
[venv] % pipacs -c dev flit
[venv] % flit init
```

Our basic generated `pyproject.toml`, courtesy of `flit`:

```toml
[build-system]
requires = ["flit_core >=3.2,<4"]
build-backend = "flit_core.buildapi"

[project]
name = "goodmod"
authors = [{name = "andy", email = "andy@example.com"}]
classifiers = ["License :: OSI Approved :: MIT License"]
dynamic = ["version", "description"]
```

Now that we have one,
we can populate it with entries from our `requirements.in` files:

```console
[venv] % pypc
```

![Animated demo: pypc](https://gist.github.com/AndydeCleyre/c8cad3380bd475706815969b07733a55/raw/5a4b327bf699819c96c8126de4ef60546c5cccea/pypc_demo.svg?sanitize=true)

The dependencies have been injected according to
[PEP 621](https://www.python.org/dev/peps/pep-0621/),
and categorized according to their `<category>-requirements.in` filenames.

---

```console
% pypc --help
```
```shell
# Inject loose requirements.in dependencies into a PEP 621 pyproject.toml.
# Run either from the folder housing pyproject.toml, or one below.
# To categorize, name files <category>-requirements.in.
pypc [-y]
```

---
