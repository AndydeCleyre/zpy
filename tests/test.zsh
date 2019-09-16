#!/usr/bin/env zsh

local zpy_home=$0:P:h:h
. $zpy_home/python.zshrc
mkdir -p "$zpy_home/awful spaces project"
cd "$zpy_home/awful spaces project"
# echo $(venvs_path)
[[ $(venvs_path) = '/home/zpyuser/.local/share/venvs/e3c52587276d97814f5cbe87ea10bb06' ]] && echo "SUCCESS venvs_path" || echo "FAILED venvs_path"
envin
_pipa "awful spaces category" pyratemp
echo "import pyratemp; print('SUCCESS vpy')" > script.py
chmod +x script.py
# echo $(_whichpy venv script.py)
[[ $(_whichpy venv script.py) = '/home/zpyuser/.local/share/venvs/e3c52587276d97814f5cbe87ea10bb06/venv/bin/python' ]] && echo "SUCCESS _whichpy" || echo "FAILED _whichpy"
pipcs
python script.py
envout
vpy script.py
vpyfrom . pyratemp_tool.py -s script.py
