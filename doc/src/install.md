# Installation

After checking out the [dependencies](deps.md),
download `zpy.plugin.zsh` and source it in your `.zshrc`.

You might use `git`, `wget`, or `curl`:

=== "`git`"

    ```console
    % git clone https://github.com/andydecleyre/zpy ~/.zpy
    % print ". ~/.zpy/zpy.plugin.zsh" >>~/.zshrc
    ```

=== "`wget`"

    ```console
    % wget -O ~/.zpy.plugin.zsh https://github.com/AndydeCleyre/zpy/raw/master/zpy.plugin.zsh
    % print ". ~/.zpy.plugin.zsh" >>~/.zshrc
    ```

=== "`curl`"

    ```console
    % curl -Lo ~/.zpy.plugin.zsh https://github.com/AndydeCleyre/zpy/raw/master/zpy.plugin.zsh
    % print ". ~/.zpy.plugin.zsh" >>~/.zshrc
    ```

or install it with a plugin manager:

=== "Oh My Zsh"

    ```console
    % git clone https://github.com/andydecleyre/zpy $ZSH_CUSTOM/plugins/zpy
    ```

    Then add `zpy` to your `plugins` array in `~/.zshrc`.

=== "zcomet"

    Put `zcomet load andydecleyre/zpy` in `~/.zshrc` (between `. /path/to/zcomet.zsh` and `zcomet compinit`)

=== "Zim"

    ```console
    % print zmodule andydecleyre/zpy >>~/.zimrc
    % zimfw install
    ```

=== "yadm"

    ```console
    % yadm submodule add git@github.com:andydecleyre/zpy ~/.zpy
    % print ". ~/.zpy/zpy.plugin.zsh" >>~/.zshrc
    ```

=== "Zinit"

    ```console
    % print zinit light andydecleyre/zpy >>~/.zshrc
    ```

=== "antibody"

    ```console
    % print antibody bundle andydecleyre/zpy >>~/.zshrc
    ```

=== "Antigen"

    Put `antigen bundle andydecleyre/zpy` in your ``~/.zshrc``, before `antigen apply`.

=== "antidote"

    ```console
    % print antidote bundle andydecleyre/zpy >>~/.zshrc
    ```

=== "Prezto"

    ```console
    % git clone https://github.com/andydecleyre/zpy $ZPREZTODIR/modules/zpy
    ```

    Then add `zpy` to your pmodule list in `~/.zpreztorc`.

=== "zgen"

    Put `zgen load andydecleyre/zpy` in the plugin section of your `~/.zshrc`, then

    ```console
    % zgen reset
    ```

=== "zgenom"

    Put `zgenom load andydecleyre/zpy` in the plugin section of your `~/.zshrc`, then

    ```console
    % zgenom reset
    ```

=== "znap"

    ```console
    % print znap source andydecleyre/zpy >>~/.zshrc
    ```

=== "zplug"

    Put `zplug "andydecleyre/zpy"` in `~/.zshrc` (between `. ~/.zplug/init.zsh` and `zplug load`), then

    ```console
    % zplug install; zplug load
    ```

=== "zpm"

    ```console
    % print zpm load andydecleyre/zpy >>~/.zshrc
    % zpm clean
    ```
