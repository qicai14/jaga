import logging

import jaga.main  # noqa: F401


def test_jaga_info_logs_are_enabled():
    assert logging.getLogger("jaga.telephony").getEffectiveLevel() <= logging.INFO
