"""Tests that observe calls to src.add / src.clamp / src.divide."""

from src import add, clamp, divide


def test_add_positives():
    assert add(1, 2) == 3
    assert add(2, 3) == 5
    assert add(10, 20) == 30
    assert add(5, 5) == 10


def test_add_with_zero():
    assert add(0, 7) == 7
    assert add(8, 0) == 8


def test_clamp_within_range():
    assert clamp(5, 0, 10) == 5
    assert clamp(7, 0, 10) == 7
    assert clamp(3, 0, 10) == 3


def test_clamp_at_bounds():
    assert clamp(0, 0, 10) == 0
    assert clamp(10, 0, 10) == 10


def test_clamp_outside_range():
    assert clamp(15, 0, 10) == 10
    assert clamp(-5, 0, 10) == 0


def test_divide_positives():
    assert divide(10, 2) == 5
    assert divide(20, 4) == 5
    assert divide(100, 5) == 20
