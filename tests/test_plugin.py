from pytest_qfield.qfieldbot import QFieldBot

def test_qfield_bot_is_there(qfield_bot: QFieldBot):
    """Test that the QField bot is available."""
    assert qfield_bot is not None

def test_qfield_new_project_is_there(qfield_new_project: "QFieldProject"):
    """Test that the new QField project is available."""
    assert qfield_new_project is not None
