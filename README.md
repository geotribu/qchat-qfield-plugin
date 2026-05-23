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

----

Shout out to @nirvn, the initiator of this QField plugin. Thanks for the amazing work !
