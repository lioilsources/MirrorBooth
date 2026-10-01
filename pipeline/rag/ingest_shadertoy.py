"""
Ingest cached Shadertoy shaders (from shadertoy/harvest.py) into ChromaDB.

Every shader goes in — including non-permissive and unsupported ones — because
the RAG is technique reference only. The license travels in the metadata and
the retriever/coder enforce "permissive=false -> do not copy".

Usage:
    python rag/ingest_shadertoy.py                 # whole cache
    python rag/ingest_shadertoy.py --ids XsX3zB 4dXGR4
Re-running is safe: chunks are upserted under stable ids.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from config import RAG_DB_DIR, SHADERTOY_CACHE_DIR, settings
from rag.chunking import SHADERTOY_COLLECTION, infer_techniques, split_functions
from shadertoy.client import iter_cached, load_cached
from shadertoy.license import classify_shader
from shadertoy.model import Shader
from shadertoy.portability import classify

MIN_CHUNK_CHARS = 20
INGESTED_PASSES = ("common", "image", "buffer")


def build_records(shader: Shader) -> list[tuple[str, str, dict]]:
    """(id, document, metadata) for every function chunk of the shader."""
    lic = classify_shader(shader)
    port = classify(shader)
    info = shader.info
    techniques = infer_techniques(shader.all_code, info.name, " ".join(info.tags))
    base_meta = {
        "source": "shadertoy",
        "shader_id": info.id,
        "name": info.name,
        "author": info.username,
        "license": lic.license,
        "permissive": lic.permissive,
        "tags": ",".join(info.tags),
        "likes": info.likes,
        "category": port.category,
        "techniques": ",".join(techniques),
        "url": shader.url,
    }
    records = []
    for pass_idx, rp in enumerate(shader.renderpass):
        if rp.type not in INGESTED_PASSES or not rp.code.strip():
            continue
        for idx, chunk in enumerate(split_functions(rp.code)):
            if len(chunk.strip()) < MIN_CHUNK_CHARS:
                continue
            meta = {**base_meta, "pass": rp.type, "chunk_index": idx}
            records.append((f"st_{info.id}_{pass_idx}_{idx}", chunk, meta))
    return records


def ingest_shaders(shaders, collection) -> int:
    count = 0
    for shader in shaders:
        records = build_records(shader)
        if not records:
            continue
        ids, docs, metas = zip(*records, strict=True)
        collection.upsert(ids=list(ids), documents=list(docs), metadatas=list(metas))
        count += len(records)
    return count


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Ingest cached Shadertoy shaders into ChromaDB")
    parser.add_argument("--ids", nargs="*", help="only these shader ids (default: whole cache)")
    parser.add_argument("--cache-dir", type=Path, default=SHADERTOY_CACHE_DIR)
    args = parser.parse_args(argv)

    if not args.cache_dir.exists():
        print(f"No Shadertoy cache at {args.cache_dir} — run shadertoy/harvest.py first.")
        return 1

    import chromadb
    from chromadb.utils import embedding_functions

    RAG_DB_DIR.mkdir(parents=True, exist_ok=True)
    ef = embedding_functions.SentenceTransformerEmbeddingFunction(model_name=settings.embedding_model)
    client = chromadb.PersistentClient(path=str(RAG_DB_DIR))
    collection = client.get_or_create_collection(name=SHADERTOY_COLLECTION, embedding_function=ef)

    shaders = [load_cached(i, args.cache_dir) for i in args.ids] if args.ids else iter_cached(args.cache_dir)
    total = ingest_shaders(shaders, collection)
    print(f"Shadertoy RAG ready: {total} chunks upserted into '{SHADERTOY_COLLECTION}' ({RAG_DB_DIR})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
