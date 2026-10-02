"""License classifier on realistic Shadertoy header styles (decision B)."""

import pytest

from shadertoy.license import DEFAULT_LICENSE, classify_shader, classify_text
from shadertoy.model import parse_shader
from tests.shadertoy_factory import shader_payload

PERMISSIVE_HEADERS = [
    (
        "// The MIT License\n// Copyright © 2013 Some Author\n// Permission is hereby granted, free of charge, "
        'to any person obtaining a copy of this software and associated documentation files (the "Software"), '
        "to deal in the Software without restriction",
        "MIT",
    ),
    ("// SPDX-License-Identifier: MIT\n// Copyright 2023 someone", "MIT"),
    ("/* Licensed under the MIT license. See LICENSE for details. */", "MIT"),
    ("// CC0 1.0 Universal - https://creativecommons.org/publicdomain/zero/1.0/", "CC0 1.0"),
    ("// This shader is released into the public domain. Do whatever you want.", "Public Domain"),
    ("// This is free and unencumbered software released into the public domain (Unlicense).", "Unlicense"),
    ("// Unlicense: https://unlicense.org", "Unlicense"),
    (
        "// BSD 3-Clause License\n// Redistribution and use in source and binary forms, with or without modification, "
        "are permitted ... Neither the name of the copyright holder may be used to endorse or promote products "
        "derived from this software without specific prior written permission.",
        "BSD",
    ),
    (
        "// This work is licensed under a Creative Commons Attribution 4.0 International License.\n"
        "// http://creativecommons.org/licenses/by/4.0/",
        "CC BY",
    ),
    ("// License: CC BY 3.0 — credit me", "CC BY"),
]

RESTRICTIVE_HEADERS = [
    (
        "// Created by inigo quilez - iq/2013\n// License Creative Commons Attribution-NonCommercial-ShareAlike "
        "3.0 Unported License.",
        "NonCommercial",
    ),
    ("// CC BY-NC-SA 4.0", "CC BY-NC-SA"),
    ("// license: https://creativecommons.org/licenses/by-nc/4.0/", "CC BY-NC"),
    ("// CC BY-SA 4.0 (share your changes)", "CC BY-SA"),
    (
        "// Copyright Some Author, 2019\n// I am the sole copyright owner of this Work.\n// You cannot host, display, "
        "distribute or share this Work neither as it is or altered.",
        "All rights reserved",
    ),
    ("// Copyright (c) 2020. All rights reserved.", "All rights reserved"),
    ("// GPLv3 - see gnu.org", "GPL"),
    ("// Free for personal use, no commercial use without permission.", "NonCommercial"),
]


@pytest.mark.parametrize(("header", "expected"), PERMISSIVE_HEADERS)
def test_permissive_headers(header, expected):
    info = classify_text(header)
    assert info.permissive is True, info
    assert info.license == expected


@pytest.mark.parametrize(("header", "expected"), RESTRICTIVE_HEADERS)
def test_restrictive_headers(header, expected):
    info = classify_text(header)
    assert info.permissive is False, info
    assert info.license == expected


def test_no_header_falls_back_to_shadertoy_default():
    info = classify_text("// fun waves\n")
    assert info.permissive is False
    assert info.license == DEFAULT_LICENSE


def test_restrictive_wins_over_permissive():
    info = classify_text("// MIT License for the noise function\n// rest: CC BY-NC-SA 3.0")
    assert info.permissive is False


def test_derived_work_is_not_permissive():
    info = classify_text("// MIT License\n// based on https://www.shadertoy.com/view/XsX3zB")
    assert info.permissive is False
    assert "derived" in info.license


def test_fork_name_is_not_permissive():
    info = classify_text("// MIT License", name="Fork Webcam Fun 123")
    assert info.permissive is False


def test_identifiers_in_code_do_not_count():
    # "mit" / "public domain" appear in code but not in comments
    shader = parse_shader(
        shader_payload(code="float mit = 1.0; // waves\nvoid mainImage(out vec4 c, in vec2 f){ c = vec4(mit); }")
    )
    assert classify_shader(shader).permissive is False


def test_description_is_considered():
    shader = parse_shader(shader_payload(description="Released under the MIT License."))
    assert classify_shader(shader).license == "MIT"
