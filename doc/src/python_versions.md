# Manage Python versions

This project doesn't maintain multiple Python installations for you;
you can use [mise](https://github.com/jdx/mise), [pyenv](https://github.com/pyenv/pyenv), or [asdf](https://asdf-vm.com/) to do so.

/// tab | mise

```console
% mise install python@3.13.1
```

///

/// tab | pyenv

```console
% pyenv install 3.13.1
```

///

/// tab | asdf

```console
% asdf install python 3.13.1
```

///

## Install a tool with a specific Python version

/// tab | mise

```console
% mise shell python@3.13.1
% pipz install httpie
```

///

/// tab | pyenv

```console
% pyenv shell 3.13.1
% pipz install httpie
```

///

/// tab | asdf

```console
% asdf shell python 3.13.1
% pipz install httpie
```

///

## Create a venv with a specific Python version

/// tab | mise

```console
% mise shell python@3.13.1
% envin  # or: activate
```

///

/// tab | pyenv

```console
% pyenv shell 3.13.1
% envin  # or: activate
```

///

/// tab | asdf

```console
% asdf shell python 3.13.1
% envin  # or: activate
```

///

Once the venv is created this way,
`envin` and `activate` will by default use that same Python version,
regardless of the current shell's `path`.

## Keep multiple Python version venvs available for a single project

/// tab | mise

```console
% mise shell python@3.13.1
% envin --py current  # or: activate --py current
```

///

/// tab | pyenv

```console
% pyenv shell 3.13.1
% envin --py current  # or: activate --py current
```

///

/// tab | asdf

```console
% asdf shell python 3.13.1
% envin --py current  # or: activate --py current
```

///

Instead of the venv path being for example `~/.local/share/venvs/646…/venv`,
it will be `~/.local/share/venvs/646…/venv-python-3.13.1`.
