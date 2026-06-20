from pytest_qfield.qfieldbot import QFieldBot
from pytest_qfield.stub_interface.qfield_stubs import QFieldAppInterfaceStub

from tests import PLUGIN_QML_PATH


def test_qfield_bot_is_there(qfield_bot: QFieldBot):
    assert qfield_bot is not None

def test_qfield_iface_is_there(qfield_iface: QFieldAppInterfaceStub):
    assert qfield_iface is not None

def test_plugin_loads_without_errors(qfield_bot: QFieldBot):
    # TODO: investigate and remove `raise_if_warnings=False`
    qfield_bot.load_plugin(PLUGIN_QML_PATH, raise_if_warnings=False)

def test_buttons_available(qfield_bot_loaded: QFieldBot):
    assert qfield_bot_loaded.get_item("pluginButton") is not None
    assert qfield_bot_loaded.get_item("pluginQChatButton") is not None
    assert qfield_bot_loaded.get_item("pluginNewsButton") is not None
