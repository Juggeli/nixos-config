from setuptools import setup

setup(
    name='qbit-manager setup',
    version='0.1',
    scripts=['main.py'],
    entry_points={
        "console_scripts": [
        "qbit-manager = main:main"
    ]
    }
)
