project = 'zpy'
author = 'Andy Kluger'
release = '0.0.4'
html_theme = 'bootstrap'

# html_sidebars = {'**': ['localtoc.html']}
html_theme_options = {
    # alabaster:
    # 'github_user': 'andydecleyre',
    # 'github_repo': 'zpy',
    # 'github_banner': True,
    # 'fixed_sidebar': True,

    # boostrap:
    'navbar_pagenav_name': "Jump to …",
    'source_link_position': 'nowhere',
    'bootswatch_theme': 'flatly',
    'navbar_links': [
        ("zpy on GitHub", 'https://github.com/andydecleyre/zpy', True),
        ("pip-tools", 'https://github.com/jazzband/pip-tools', True),
    ],

    # pydata_sphinx_theme:
    # 'github_url': 'https://github.com/andydecleyre/zpy',
    # 'search_bar_position': 'nowhere',
}
