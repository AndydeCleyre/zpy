project = 'zpy'
author = 'Andy Kluger'
release = '0.0.5'
html_favicon = '../favicon-32x32.png'
html_theme = 'bootstrap'
html_theme_options = {
    'navbar_pagenav_name': "Jump to …",
    'source_link_position': 'nowhere',
    'bootswatch_theme': 'flatly',
    'navbar_links': [
        ("Source", 'https://github.com/andydecleyre/zpy', True),
        ("Issues", 'https://github.com/andydecleyre/zpy/issues', True),
        ("pip-tools", 'https://github.com/jazzband/pip-tools', True),
    ],
}
html_static_path = ['DarkReader-zpy-readthedocs-io.css']
def setup(app):
    app.add_css_file('DarkReader-zpy-readthedocs-io.css')
