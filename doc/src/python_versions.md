# Manage Python versions

This project doesn't maintain multiple Python installations for you;
you can use [pyenv](https://github.com/pyenv/pyenv) or [asdf](https://asdf-vm.com/) to do so.

=== "pyenv"

    ```console
    % pyenv install 3.7.9
    ```

=== "asdf"

    ```console
    % asdf install python 3.7.9
    ```

## Install a tool with a specific Python version

=== "pyenv"

    ```console
    % pyenv shell 3.7.9
    % pipz install httpie
    ```

=== "asdf"

    ```console
    % asdf shell python 3.7.9
    % pipz install httpie
    ```

## Create a venv with a specific Python version

=== "pyenv"

    ```console
    % pyenv shell 3.7.9
    % envin  # or: activate
    ```

=== "asdf"

    ```console
    % asdf shell python 3.7.9
    % envin  # or: activate
    ```

Once the venv is created this way,
`envin` and `activate` will by default use that same Python version,
regardless of the current shell's `path`.

## Keep multiple Python version venvs available for a single project

=== "pyenv"

    ```console
    % pyenv shell 3.7.9
    % envin --py current  # or: activate --py current
    ```

=== "asdf"

    ```console
    % asdf shell python 3.7.9
    % envin --py current  # or: activate --py current
    ```

Instead of the venv path being for example `~/.local/share/venvs/646…/venv`,
it will be `~/.local/share/venvs/646…/venv-python-3.7.9`.
