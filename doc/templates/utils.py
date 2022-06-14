from shlex import quote
from textwrap import indent

from plumbum import local
from plumbum.cmd import zsh


def zpy_help(*funcs, indentation=0, indent_first_line=False):
    plugin = local.path(__file__).up(3) / "zpy.plugin.zsh"
    content = zsh(
        "-c", f". {plugin} && NO_COLOR=1 .zpy_ui_help {' '.join(map(quote, funcs))}"
    ).rstrip()
    try:
        first, rest = content.split("\n", 1)
    except ValueError:
        return content
    return f"{first}\n{indent(rest, ' ' * indentation)}"
