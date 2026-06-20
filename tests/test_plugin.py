# from tests import PLUGIN_QML_PATH


def test_qfield_bot_is_there(qfield_bot):
    assert qfield_bot is not None

def test_qfield_iface_is_there(qfield_iface):
    assert qfield_iface is not None

# def test_plugin_loads_with_errours(qfield_bot):
#     qfield_bot.load_plugin(PLUGIN_QML_PATH)
