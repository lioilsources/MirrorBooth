import pytest

import integrator
from integrator import IntegrationError, install


def _frag(tmp_path, body="// gen\nvoid main(){ fragColor = vec4(1.0); }\n"):
    p = tmp_path / "filter_neon_swirl.frag"
    p.write_text(body)
    return p


def _install(tree, frag, name="neon_swirl", tech_spec=None):
    return install(
        frag, name, tech_spec or {"effect_name": "Neon Swirl", "needs_time": True},
        shaders_dir=tree.shaders_dir,
        pubspec_path=tree.pubspec,
        dart_path=tree.dart,
    )


def test_fresh_install_touches_all_sites(fake_flutter_tree, tmp_path):
    frag = _frag(tmp_path)
    rep = _install(fake_flutter_tree, frag)

    assert rep["enum_name"] == "neonSwirl"
    assert rep["frag_filename"] == "filter_neon_swirl.frag"

    dart = fake_flutter_tree.dart.read_text()
    assert "\n  neonSwirl,\n" in dart
    assert "MirrorFilter.neonSwirl => 'Neon S'," in dart
    assert "MirrorFilter.neonSwirl => 'N'," in dart
    assert "MirrorFilter.neonSwirl => true," in dart
    assert "MirrorFilter.neonSwirl => 'shaders/filter_neon_swirl.frag'," in dart

    pubspec = fake_flutter_tree.pubspec.read_text()
    assert pubspec.count("- shaders/filter_neon_swirl.frag") == 1

    dest = fake_flutter_tree.shaders_dir / "filter_neon_swirl.frag"
    assert dest.read_text() == frag.read_text()


def test_install_is_idempotent(fake_flutter_tree, tmp_path):
    frag = _frag(tmp_path)
    _install(fake_flutter_tree, frag)
    dart1 = fake_flutter_tree.dart.read_text()
    pub1 = fake_flutter_tree.pubspec.read_text()

    rep2 = _install(fake_flutter_tree, frag)

    assert rep2["already_installed"] is True
    assert rep2["files_changed"] == []
    assert fake_flutter_tree.dart.read_text() == dart1
    assert fake_flutter_tree.pubspec.read_text() == pub1


def test_collision_gets_numeric_suffix_everywhere(fake_flutter_tree, tmp_path):
    # pre-seed an unrelated enum identifier that collides with camelCase
    d = fake_flutter_tree.dart.read_text().replace(
        "  // >>> generated-filters-enum <<<",
        "  oilWarm,\n  // >>> generated-filters-enum <<<",
    )
    fake_flutter_tree.dart.write_text(d)

    f = tmp_path / "filter_oil_warm.frag"
    f.write_text("// oil\nvoid main(){ fragColor = vec4(0.5); }\n")
    rep = install(
        f, "oil_warm", {"effect_name": "Oil Warm", "needs_time": False},
        shaders_dir=fake_flutter_tree.shaders_dir,
        pubspec_path=fake_flutter_tree.pubspec,
        dart_path=fake_flutter_tree.dart,
    )

    assert rep["enum_name"] == "oilWarm2"
    assert rep["frag_filename"] == "filter_oil_warm2.frag"
    dart = fake_flutter_tree.dart.read_text()
    assert "\n  oilWarm2,\n" in dart
    assert "MirrorFilter.oilWarm2 => 'shaders/filter_oil_warm2.frag'," in dart
    assert "MirrorFilter.oilWarm2 => true," not in dart  # needs_time False
    assert (fake_flutter_tree.shaders_dir / "filter_oil_warm2.frag").is_file()


def test_missing_sentinel_aborts_without_writing(fake_flutter_tree, tmp_path):
    d = fake_flutter_tree.dart.read_text().replace(
        "        // >>> generated-filters-icon <<<\n", ""
    )
    fake_flutter_tree.dart.write_text(d)
    before_dart = fake_flutter_tree.dart.read_text()
    before_pub = fake_flutter_tree.pubspec.read_text()

    with pytest.raises(IntegrationError):
        _install(fake_flutter_tree, _frag(tmp_path))

    assert fake_flutter_tree.dart.read_text() == before_dart
    assert fake_flutter_tree.pubspec.read_text() == before_pub
    assert not (fake_flutter_tree.shaders_dir / "filter_neon_swirl.frag").exists()


def test_needs_time_false_skips_needstime_site(fake_flutter_tree, tmp_path):
    rep = _install(
        fake_flutter_tree, _frag(tmp_path), name="calm_fade",
        tech_spec={"effect_name": "Calm Fade", "needs_time": False},
    )
    dart = fake_flutter_tree.dart.read_text()
    assert "MirrorFilter.calmFade => 'shaders/filter_calm_fade.frag'," in dart
    assert "MirrorFilter.calmFade => true," not in dart
    assert rep["needs_time"] is False
