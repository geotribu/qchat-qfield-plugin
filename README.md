# QChat - QField plugin

[![🧹 Lint](https://github.com/geotribu/qchat-qfield-plugin/actions/workflows/lint.yml/badge.svg?branch=main)](https://github.com/geotribu/qchat-qfield-plugin/actions/workflows/lint.yml)
[![🚀 Release](https://github.com/geotribu/qchat-qfield-plugin/actions/workflows/release.yml/badge.svg)](https://github.com/geotribu/qchat-qfield-plugin/actions/workflows/release.yml)
[![Latest release](https://img.shields.io/github/v/release/geotribu/qchat-qfield-plugin?label=latest%20release&logo=github)](https://github.com/geotribu/qchat-qfield-plugin/releases/latest)
[![License: GPL v2](https://img.shields.io/badge/License-GPLv2-blue.svg)](LICENSE)
[![QField](https://img.shields.io/badge/QField-plugin-green?logo=qgis)](https://docs.qfield.org/how-to/plugins/)

**QChat client in QField, let's chat with your GIS fellows on the field !**

- See [`QChat`](https://github.com/geotribu/qchat): the QGIS plugin and QChat client in QGIS.
- QChat client compatible with [the `gischat` backend](https://github.com/geotribu/gischat).
- QField users can target the `qchat.geotribu.net` instance, the one configured by default.

----

## Installation

You can follow [the QField documentation](https://docs.qfield.org/how-to/plugins/#application-plugins) regarding plugin installation.

The URL to install the `QChat` plugin is:

```
https://github.com/geotribu/qchat-qfield-plugin/releases/latest/download/qfchat-latest.zip
```

Or flash this QR code directly within QField :

![QR code to download latest QfChat plugin version](./qrcode_download_latest.png)

----

## Development

- Install precommit tools with:

```sh
pre-commit install
```

- Create a symlink from the `qfield-plugin-qchat` repository into your QField documents / plugins local repository.

- Install [the `QField Plugin Reloader` plugin](https://github.com/gacarrillor/qfield-plugin-reloader) for an easier reloading workflow.

## Tests locally

> [!NOTE]
> QGIS4 must be installed on the test machine!

- Install `uv` locally:

```sh
python3 -m pip install uv --break-system-packages
```

- Create local virtualenv with system packages and sync:

```sh
uv venv --system-site-packages
uv sync
```

- Add system packages to local virtual env (hacky):

```sh
SITE_PACKAGES=$(uv run python -c "import site; print(site.getsitepackages()[0])")
echo "/usr/share/qgis/python" > "$SITE_PACKAGES/qgis.pth"
```

- Test that imports are fine:

```sh
uv run python -c "import qgis; print(qgis.__file__)"
uv run python -c "import PyQt6; print(PyQt6.__file__)"
uv run python -c "from PyQt6.QtCore import QT_VERSION_STR; print(QT_VERSION_STR)"
```

> [!NOTE]
> Tested on Ubuntu 26.04, only...

- Run tests:

```sh
uv run pytest tests -v
```

----

Shout out to @nirvn, the initiator of this QField plugin. Thanks for the amazing work !
