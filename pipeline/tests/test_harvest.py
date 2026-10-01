import json
import shutil

from shadertoy import harvest as harvest_mod
from tests.shadertoy_factory import FIXTURES


class FakeClient:
    def __init__(self, fixtures):
        self.fixtures = fixtures
        self.gets = []

    def search(self, query, sort="popular", filter=None, num=25, from_=0):  # noqa: A002
        return list(self.fixtures)[:num]

    def get(self, shader_id):
        from shadertoy.model import parse_shader

        self.gets.append(shader_id)
        return parse_shader(json.loads((FIXTURES / f"{self.fixtures[shader_id]}.json").read_text()))


def _fixture_ids():
    out = {}
    for path in sorted(FIXTURES.glob("*.json")):
        out[json.loads(path.read_text())["Shader"]["info"]["id"]] = path.stem
    return out


def test_harvest_writes_report_and_candidates(tmp_path):
    client = FakeClient(_fixture_ids())
    run_dir = harvest_mod.harvest(client, ["webcam", "filter"], num=50, out_root=tmp_path)
    data = json.loads((run_dir / "candidates.json").read_text())
    cands = data["candidates"]
    assert len(cands) == len(_fixture_ids())
    # dedup across queries: every id fetched once
    assert len(client.gets) == len(set(client.gets))
    # portable image filters come first
    assert cands[0]["permissive"] and cands[0]["category"] == "image_filter"
    report = (run_dir / "harvest_report.md").read_text()
    assert "## Licenses" in report and "## Categories" in report
    assert "CC BY-NC-SA 3.0 (default)" in report
    assert "https://www.shadertoy.com/view/stWebInv" in report


def test_harvest_tag_filter(tmp_path):
    run_dir = harvest_mod.harvest(FakeClient(_fixture_ids()), ["x"], tags=["webcam"], out_root=tmp_path)
    cands = json.loads((run_dir / "candidates.json").read_text())["candidates"]
    assert [c["id"] for c in cands] == ["stWebInv"]


def test_harvest_from_cache(tmp_path):
    cache = tmp_path / "cache"
    shutil.copytree(FIXTURES, cache)
    run_dir = harvest_mod.harvest(None, [], from_cache=True, out_root=tmp_path, cache_dir=cache)
    cands = json.loads((run_dir / "candidates.json").read_text())["candidates"]
    assert len(cands) == len(_fixture_ids())


def test_cli_requires_query(capsys):
    import pytest

    with pytest.raises(SystemExit):
        harvest_mod.main([])


def test_missing_key_aborts_with_message(tmp_path, monkeypatch, capsys):
    from config import settings

    monkeypatch.setattr(settings, "shadertoy_api_key", "")
    assert harvest_mod.main(["--query", "webcam"]) == 2
    assert "shadertoy.com/myapps" in capsys.readouterr().out
