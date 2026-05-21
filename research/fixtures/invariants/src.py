"""Source file for invariants inference."""


def add(a, b):
    return a + b


def clamp(value, lo, hi):
    if value < lo:
        return lo
    if value > hi:
        return hi
    return value


def divide(num, denom):
    return num / denom
