import os

from setuptools import setup

#from halo.settings import DEBUG, VERSION

if DEBUG:
    print("You cannot build or install in debug mode.")
    exit(1)


def get_long_description():
    description = []
    with open('README.md') as f:
        description.append(f.read())


setup(name='tunic',
      version=VERSION,
      description='Install Linux from Windows',
      long_description=get_long_description(),
      author='Mike Slattery',
      license='GNU GPL v3',
      packages=[],
      url='https://github.com/mikeslattery/tunic',
      entry_points={
          "gui_scripts": [
              "halo-weather = halo.__main__:main",
          ]
      },
      install_requires=[
          "requests",
      ],
      data_files=[
#          (os.getenv('HOME') + '/.local/share/applications', ['halo.desktop']),
#          (os.getenv('HOME') + '/.local/share/icons', ['halo/assets/halo.svg']),
      ],
      package_data={
#          '': ['*.css', 'assets/*.*', 'assets/icon/*']
      },
      zip_safe=False)

