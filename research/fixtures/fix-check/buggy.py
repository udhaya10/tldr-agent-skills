"""Source with a deliberate NameError to test fix-check loop."""


def compute(x):
    # `valeu` is a typo — will trigger NameError at test time.
    return valeu * 2


def test_compute():
    assert compute(5) == 10
