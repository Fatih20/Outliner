project('com.github.phase1geo.outliner', ['vala', 'c'],
    version : '1.0.0',
    license: 'GPL-3.0'
)

add_project_arguments([
        '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name())
    ],
    language: 'c',
)

gnome = import('gnome')
i18n = import('i18n')

gresource = gnome.compile_resources(
    'as-resources', 'data/com.github.phase1geo.outliner.gresource.xml',
    source_dir: 'data',
    c_name: 'as'
)

conf = configuration_data()
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
configure_file(output: 'config.h', configuration: conf)
config_h_dir = include_directories('.')

c_args = [
  '-include', 'config.h'
]

sources = files()

subdir('data')
subdir('po')
subdir('src')
subdir('tests')

dependencies = [
  dependency('gobject-2.0'),
  dependency('glib-2.0'),
  dependency('granite'),
  dependency('gtk+-3.0'),
  dependency('libxml-2.0')
]

e = executable('com.github.phase1geo.outliner',
    sources,
    gresource,
    c_args: c_args,
    dependencies: dependencies,
    install : true
)

#test('tests', e, args : ['--run-tests'])

meson.add_install_script('meson/post_install.py')
