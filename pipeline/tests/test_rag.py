"""Shadertoy RAG ingest + retriever attribution, with in-memory fake collections."""

import shutil

import agents.glsl_coder as glsl_coder
import agents.rag_retriever as rr
from rag.chunking import infer_techniques, split_functions
from rag.ingest_shadertoy import build_records, ingest_shaders
from shadertoy.client import iter_cached
from shadertoy.model import parse_shader
from state import initial_state
from tests.shadertoy_factory import FIXTURES, load_fixture


class FakeCollection:
    def __init__(self, hits=None):
        self.store: dict[str, tuple[str, dict]] = {}
        self.hits = hits or []  # (distance, doc, meta)
        self.queries: list[dict] = []

    def upsert(self, ids, documents, metadatas):
        for i, d, m in zip(ids, documents, metadatas, strict=True):
            self.store[i] = (d, m)

    def query(self, query_texts, n_results, where=None):
        self.queries.append({"n": n_results, "where": where})
        hits = self.hits[:n_results]
        return {
            "documents": [[h[1] for h in hits]],
            "metadatas": [[h[2] for h in hits]],
            "distances": [[h[0] for h in hits]],
        }


def test_split_functions_and_techniques():
    code = "float a(){return 1.;}\nvec3 kaleido(vec2 p){return vec3(p,0.);}\nvoid mainImage(out vec4 c,in vec2 f){c=vec4(1);}"
    assert len(split_functions(code)) == 3
    assert "kaleidoscope" in infer_techniques(code)
    assert {"raymarching", "sdf"} <= set(infer_techniques("float sdSphere(vec3 p); // raymarch"))


def test_build_records_metadata():
    shader = parse_shader(load_fixture("noise_texture"))
    records = build_records(shader)
    assert len(records) == 2  # noise() + mainImage()
    rid, doc, meta = records[0]
    assert rid == "st_stNoiseTx_0_0"
    assert "float noise" in doc
    assert meta["source"] == "shadertoy" and meta["shader_id"] == "stNoiseTx"
    assert meta["permissive"] is True and meta["license"] == "Public Domain"
    assert meta["category"] == "data_texture"
    assert "noise" in meta["techniques"].split(",")
    assert all(isinstance(v, (str, int, float, bool)) for v in meta.values())  # Chroma-compatible


def test_ingest_is_idempotent(tmp_path):
    cache = tmp_path / "cache"
    shutil.copytree(FIXTURES, cache)
    col = FakeCollection()
    n1 = ingest_shaders(iter_cached(cache), col)
    size = len(col.store)
    n2 = ingest_shaders(iter_cached(cache), col)
    assert n1 == n2 == size > 0
    assert len(col.store) == size


def test_shadertoy_where():
    assert rr.shadertoy_where({}) is None
    assert rr.shadertoy_where({"category": "image_filter"}) == {"category": "image_filter"}
    assert rr.shadertoy_where({"category": "procedural", "permissive_only": True}) == {
        "$and": [{"category": "procedural"}, {"permissive": True}]
    }


def test_retrieve_mixes_and_attributes():
    local = FakeCollection([(0.1, "float luma(vec3 c){...}", {"filter_name": "filter_neon"})] * 5)
    st = FakeCollection(
        [
            (
                0.3,
                "vec2 kal(vec2 p){...}",
                {"source": "shadertoy", "shader_id": "abc", "author": "al", "license": "MIT", "permissive": True},
            ),
            (
                0.4,
                "float fbm(vec2 p){...}",
                {
                    "source": "shadertoy",
                    "shader_id": "nc1",
                    "author": "bo",
                    "license": "CC BY-NC-SA 3.0 (default)",
                    "permissive": False,
                },
            ),
        ]
    )
    out = rr.retrieve("kaleido", {"category": "image_filter"}, local, st, k=5)
    assert len(out) == 5
    assert sum("source: shadertoy/" in s for s in out) == 2
    assert "// source: shadertoy/abc by al (MIT)\nvec2 kal(vec2 p){...}" in out
    nc = next(s for s in out if "nc1" in s)
    assert rr.REFERENCE_ONLY in nc.splitlines()[0]
    assert "// source: mirrorbooth/filter_neon" in out[0]
    assert st.queries[0]["where"] == {"category": "image_filter"}


def test_retrieve_backfills_when_one_side_empty():
    local = FakeCollection([(0.1 * i, f"doc{i}", {"filter_name": f"f{i}"}) for i in range(6)])
    out = rr.retrieve("x", {}, local, None, k=5)
    assert len(out) == 5


def test_node_uses_open_collections(monkeypatch):
    st = FakeCollection(
        [
            (
                0.2,
                "vec3 pal(float t){...}",
                {"source": "shadertoy", "shader_id": "p1", "author": "c", "license": "CC0 1.0", "permissive": True},
            )
        ]
    )
    monkeypatch.setattr(rr, "open_collections", lambda: (FakeCollection(), st))
    s = initial_state("kaleidoscope mirror")
    s["tech_spec"] = {"techniques": ["kaleidoscope"], "description": "mirror"}
    out = rr.rag_retriever_node(s)
    assert out["rag_context"] == ["// source: shadertoy/p1 by c (CC0 1.0)\nvec3 pal(float t){...}"]


def test_coder_prompt_has_licensing_rule(fake_llm):
    s = initial_state("x")
    s["tech_spec"] = {"effect_name": "X"}
    s["rag_context"] = [
        "// source: shadertoy/nc1 by bo (CC BY-NC-SA 3.0 (default)) — reference only, do not copy\nfloat f();"
    ]
    glsl_coder.glsl_coder_node(s)
    system, human = fake_llm.calls[-1][1]
    assert "never copy" in system.content.lower()
    assert "reference only, do not copy" in human.content
