# Automatic Activation

If you'd like your shell to automatically activate and deactivate venvs
when you switch directories, there are a few tools to make that happen.

Here's how to configure them to do so in a zpy-friendly way.
If you notice room for improvement, or your favorite tool is missing,
please open an issue or discussion on GitHub.

=== "zsh-autoenv"

    [zsh-autoenv](https://github.com/Tarrasch/zsh-autoenv)
    runs any Zsh code you want in your current shell,
    making it the simplest tool to configure for this job.

    In any project folder, create the following two files:

    `.autoenv.zsh`:

    ```zsh
    a8 ${0:h}
    ```

    `.autoenv_leave.zsh`:

    ```zsh
    if [[ $VIRTUAL_ENV ]]  envout
    ```

    The zero in `${0:h}` is the path of the `.autoenv.zsh` file,
    and the `:h` expansion gets that path's parent.
    This ensures the proper project folder is used,
    even if you're activating the script by entering a deeper subdirectory.

=== "direnv"

    [direnv](https://github.com/direnv/direnv/)
    runs Bash (not Zsh) and exports variables.
    We'll create a self-contained script for each of `a8` and `venvs_path`,
    so that we can easily call them from Bash.

    Assuming `~/.local/bin` is in your `PATH`, run

    ```console
    $ zpy mkbin a8 ~/.local/bin/
    $ zpy mkbin venvs_path ~/.local/bin/
    ```

    Now define a Bash function within the file `~/.config/direnv/direnvrc`:

    ```bash
    layout_zpy () {
      a8
      export VIRTUAL_ENV="$(venvs_path)/venv"
      PATH_add "$VIRTUAL_ENV/bin"
      export VENV_ACTIVE=1
    }
    ```

    In any project folder, create `.envrc`:

    ```bash
    layout zpy
    ```
