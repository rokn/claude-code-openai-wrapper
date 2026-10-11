"""Tests for reasoning_effort -> Claude effort mapping."""

import pytest
from pydantic import ValidationError

from src.models import ChatCompletionRequest, Message, normalize_effort
from src.parameter_validator import ParameterValidator


def _req(**kw):
    return ChatCompletionRequest(messages=[Message(role="user", content="hi")], **kw)


@pytest.mark.parametrize(
    "given,expected",
    [
        ("none", "low"),
        ("minimal", "low"),
        ("low", "low"),
        ("MEDIUM", "medium"),
        ("high", "high"),
        ("xhigh", "xhigh"),
        ("max", "max"),
    ],
)
def test_normalize_effort(given, expected):
    assert normalize_effort(given) == expected


def test_normalize_effort_invalid():
    assert normalize_effort("bogus") is None
    assert normalize_effort(None) is None


def test_request_maps_reasoning_effort():
    assert _req(reasoning_effort="minimal").to_claude_options()["effort"] == "low"


def test_request_without_effort_has_no_option():
    assert "effort" not in _req().to_claude_options()


def test_invalid_reasoning_effort_rejected():
    with pytest.raises(ValidationError):
        _req(reasoning_effort="turbo")


def test_effort_header():
    assert ParameterValidator.extract_claude_headers({"x-claude-effort": "High"}) == {
        "effort": "high"
    }
    assert ParameterValidator.extract_claude_headers({"x-claude-effort": "nope"}) == {}
