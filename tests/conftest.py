import pytest

from tests import PLUGIN_QML_PATH


@pytest.fixture
def loaded_plugin(qfield_bot):
    qfield_bot.load_plugin(PLUGIN_QML_PATH)
    yield qfield_bot
