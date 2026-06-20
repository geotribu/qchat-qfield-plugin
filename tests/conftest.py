from collections.abc import Generator
from pytest_qfield.qfieldbot import QFieldBot

import pytest

from tests import PLUGIN_QML_PATH


@pytest.fixture
def qfield_bot_loaded(qfield_bot: QFieldBot) -> Generator[QFieldBot, None, None]:
    # TODO: investigate and remove `raise_if_warnings=False`
    qfield_bot.load_plugin(PLUGIN_QML_PATH, raise_if_warnings=False)
    yield qfield_bot
