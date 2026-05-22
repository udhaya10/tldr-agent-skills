"""Source with a typo that triggers a NameError at runtime."""


def compute(x):
    # `valeu` is a typo for `value`; will raise NameError when called.
    return valeu * 2


def safe_compute(x):
    return x * 2
