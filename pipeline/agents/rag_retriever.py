"""Retrieve reference GLSL snippets from both RAG collections.

* ``glsl_shaders``      — MirrorBooth's own shaders (rag/ingest.py)
* ``shadertoy_shaders`` — harvested Shadertoy shaders (rag/ingest_shadertoy.py)

Each snippet gets a ``// source: ...`` attribution line. Shadertoy snippets
without a permissive license are marked reference-only; the coder's system
prompt forbids copying them verbatim (decision B of the ShaderGen v2 plan).

Optional ``tech_spec`` keys narrowing the Shadertoy query:
  ``category``         — only chunks of that portability category
  ``permissive_only``  — only permissively licensed chunks
"""

from __future__ import annotations

from config import RAG_DB_DIR, settings
from rag.chunking import LOCAL_COLLECTION, SHADERTOY_COLLECTION
from state import ShaderGenState

REFERENCE_ONLY = "reference only, do not copy"


def shadertoy_where(tech_spec: dict) -> dict | None:
    clauses = []
    if tech_spec.get("category"):
        clauses.append({"category": tech_spec["category"]})
    if tech_spec.get("permissive_only"):
        clauses.append({"permissive": True})
    if not clauses:
        return None
    return clauses[0] if len(clauses) == 1 else {"$and": clauses}


def attribution(meta: dict) -> str:
    if meta.get("source") == "shadertoy":
        line = f"// source: shadertoy/{meta.get('shader_id', '?')} by {meta.get('author', '?')} ({meta.get('license', '?')})"
        if not meta.get("permissive"):
            line += f" — {REFERENCE_ONLY}"
        return line
    return f"// source: mirrorbooth/{meta.get('filter_name', '?')}"


def _query(collection, query: str, n: int, where: dict | None) -> list[tuple[float, str, dict]]:
    if collection is None or n <= 0:
        return []
    kwargs = {"query_texts": [query], "n_results": n}
    if where:
        kwargs["where"] = where
    try:
        res = collection.query(**kwargs)
    except Exception as exc:  # empty collection, bad filter, embedder failure...
        print(f"[rag_retriever] WARNING: query failed ({exc})")
        return []
    docs = (res.get("documents") or [[]])[0]
    metas = (res.get("metadatas") or [[]])[0] or [{}] * len(docs)
    dists = (res.get("distances") or [[]])[0] or [0.0] * len(docs)
    return list(zip(dists, docs, metas, strict=False))


def retrieve(query: str, tech_spec: dict, local, shadertoy, k: int) -> list[str]:
    """Mix both collections: ~half the slots each, backfilled when one side is short."""
    n_local, n_st = k - k // 2, k // 2
    local_hits = _query(local, query, k, None)
    st_hits = _query(shadertoy, query, k, shadertoy_where(tech_spec))
    picked = local_hits[:n_local] + st_hits[:n_st]
    rest = sorted(local_hits[n_local:] + st_hits[n_st:], key=lambda h: h[0])
    picked += rest[: max(0, k - len(picked))]
    picked.sort(key=lambda h: h[0])
    return [f"{attribution(meta or {})}\n{doc}" for _, doc, meta in picked]


def open_collections():
    """(local, shadertoy) Chroma collections; either may be None. Raises ImportError without chromadb."""
    import chromadb
    from chromadb.utils import embedding_functions

    ef = embedding_functions.SentenceTransformerEmbeddingFunction(model_name=settings.embedding_model)
    client = chromadb.PersistentClient(path=str(RAG_DB_DIR))
    out = []
    for name in (LOCAL_COLLECTION, SHADERTOY_COLLECTION):
        try:
            out.append(client.get_collection(name=name, embedding_function=ef))
        except Exception:
            out.append(None)  # not ingested yet
    return tuple(out)


def rag_retriever_node(state: ShaderGenState) -> ShaderGenState:
    tech_spec = state["tech_spec"]
    query = " ".join(tech_spec.get("techniques", [])) + " " + tech_spec.get("description", "")

    try:
        # Imported lazily: chromadb + sentence-transformers are heavy optional deps
        # (not needed for the offline test suite).
        local, shadertoy = open_collections()
    except ImportError:
        print("[rag_retriever] WARNING: chromadb not installed — proceeding without RAG context")
        return {**state, "rag_context": []}
    except Exception as exc:
        # RAG DB not built yet (or embedder unavailable) — proceed without context
        print(f"[rag_retriever] WARNING: RAG unavailable ({exc}) — proceeding without context")
        return {**state, "rag_context": []}

    snippets = retrieve(query, tech_spec, local, shadertoy, settings.rag_top_k)
    return {**state, "rag_context": snippets}
