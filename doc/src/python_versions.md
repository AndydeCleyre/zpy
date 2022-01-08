# Manage Python versions

This project doesn't maintain multiple Python installations for you; you can use [pyenv](https://github.com/pyenv/pyenv) or [asdf](https://asdf-vm.com/) to do so.

Let's say you use pyenv and wish to use `pipz` to install a tool with a specific Python version:

```console
$ pyenv install 3.7.9
$ pyenv shell 3.7.9
$ pipz install httpie
$ pyenv shell --unset
```

You can do the same thing if you want to create a venv
with `activate` or `envin` and you always want it to use a specific Python.

If you want to have multiple venvs available for a single project, each with their own Python interpreter:

```console
$ pyenv shell 3.7.9
$ envin --py current  # or: activate --py current
```

Instead of the venv path being for example `~/.local/share/venvs/646…/venv`, it will be `~/.local/share/venvs/646…/venv-python-3.7.9`.
