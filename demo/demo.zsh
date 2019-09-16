#!/bin/zsh
mkdir myproject
cd myproject
envin
ls -l `venvs_path`
pipacs structlog 'plumbum==1.6.0'
sed -i -E 's/(plumbum)==.+/\1/' requirements.in
pipu plumbum
pipapublish flit pygments
pipatest pytest
pipadev ipython
pipcs
pips {test,publish}-requirements.txt
pips
flit init
bat pyproject.toml
pypc
bat pyproject.toml
tail -vn +1 *req* | hpype | less
ls
envout
envin
envout
envin publish-requirements.txt
envout
activate
envout
envin requirements.txt
envout
echo "import structlog" > app.py
python app.py
vpy app.py
vpyshebang app.py
bat app.py
pipch
