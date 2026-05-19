"""
Build the ChromaDB RAG knowledge base from MirrorBooth shaders and the
Shadertoy-convention ToyShaders seed corpus.

Usage:
    python rag/ingest.py
    python rag/ingest.py --reset
    python rag/ingest.py --shaders-dir /path/to/extra/frag
    python rag/ingest.py --seed-dir /path/to/extra/shadertoy/glsl
"""

import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

import chromadb
from chromadb.utils import embedding_functions
from config import settings, SHADERS_DIR, SEED_SHADERS_DIR, RAG_DB_DIR
from agents.shadertoy_adapter import port_shadertoy

TECHNIQUE_TAGS = {
    "sobel": "sobel_edge_detection",
    "edge": "edge_detection",
    "blur": "gaussian_blur",
    "gaussian": "gaussian_blur",
    "cel": "cel_shading",
    "toon": "cel_shading",
    "noise": "noise",
    "random": "noise",
    "hue": "hue_rotation",
    "hsv": "hue_rotation",
    "posteriz": "posterization",
    "quantiz": "color_quantization",
    "floor": "color_quantization",
    "chromat": "chromatic_aberration",
    "offset": "chromatic_aberration",
    "halftone": "halftone",
    "pixel": "pixelation",
    "glitch": "glitch",
    "watercolor": "watercolor",
    "oil": "oil_painting",
    "sketch": "sketch",
    "pencil": "sketch",
    "thermal": "thermal",
    "neon": "neon",
    "crt": "crt",
    "plasma": "plasma",
    "voronoi": "voronoi",
    "fbm": "fbm",
    "kaleido": "kaleidoscope",
    "tunnel": "tunnel",
    "march": "raymarch",
    "raymarch": "raymarch",
    "sdf": "raymarch",
    "sdsphere": "raymarch",
    "domain": "domain_warp",
    "warp": "domain_warp",
    "palette": "palette_cycle",
    "scanline": "crt",
    "truchet": "truchet",
    "metaball": "metaballs",
    "curl": "flow_field",
    "hex": "hex_grid",
    "mainimage": "shadertoy_port",
    "sin(": "animation",
    "cos(": "animation",
    "itime": "animation",
    "utime": "animation",
}


def _infer_techniques(code: str, filename: str) -> list[str]:
    combined = (code + " " + filename).lower()
    found = set()
    for keyword, tag in TECHNIQUE_TAGS.items():
        if keyword in combined:
            found.add(tag)
    return sorted(found)


def _split_functions(code: str) -> list[str]:
    """Split GLSL code into top-level function blocks."""
    # match: returnType funcName(...) { ... } allowing nested braces
    pattern = re.compile(
        r'(?:^|\n)(?:[\w]+\s+)+\w+\s*\([^)]*\)\s*\{',
        re.MULTILINE,
    )
    starts = [m.start() for m in pattern.finditer(code)]
    if not starts:
        return [code]

    chunks = []
    for i, start in enumerate(starts):
        end = starts[i + 1] if i + 1 < len(starts) else len(code)
        chunks.append(code[start:end].strip())
    return [c for c in chunks if c]


def _upsert_code(collection, source: Path, stem: str, code: str,
                 *, convention: str, origin: str, id_suffix: str) -> int:
    techniques = _infer_techniques(code, stem)
    chunks = _split_functions(code)
    count = 0
    for idx, chunk in enumerate(chunks):
        if len(chunk.strip()) < 20:
            continue
        collection.upsert(
            ids=[f"{stem}_{id_suffix}{idx}"],
            documents=[chunk],
            metadatas=[{
                "source": str(source),
                "filter_name": stem,
                "techniques": ",".join(techniques),
                "chunk_index": idx,
                "convention": convention,
                "origin": origin,
            }],
        )
        count += 1
    return count


def ingest_directory(shaders_dir: Path, collection: chromadb.Collection,
                     *, glob: str = "*.frag", convention: str = "flutter",
                     origin: str = "app") -> int:
    count = 0
    for f in sorted(shaders_dir.glob(glob)):
        code = f.read_text(encoding="utf-8")
        count += _upsert_code(
            collection, f, f.stem, code,
            convention=convention, origin=origin, id_suffix="",
        )
    return count


def ingest_seed_directory(seed_dir: Path, collection: chromadb.Collection) -> int:
    """Ingest Shadertoy-convention *.glsl seeds: original chunks AND ported."""
    count = 0
    for f in sorted(seed_dir.glob("*.glsl")):
        code = f.read_text(encoding="utf-8")
        count += _upsert_code(
            collection, f, f.stem, code,
            convention="shadertoy", origin="seed", id_suffix="st",
        )
        ported = port_shadertoy(code).code
        count += _upsert_code(
            collection, f, f.stem, ported,
            convention="flutter", origin="seed", id_suffix="fl",
        )
    return count


def main():
    parser = argparse.ArgumentParser(description="Ingest GLSL shaders into ChromaDB")
    parser.add_argument(
        "--shaders-dir",
        type=Path,
        default=None,
        help="Additional directory of .frag files to ingest",
    )
    parser.add_argument(
        "--seed-dir",
        type=Path,
        default=None,
        help="Additional directory of Shadertoy-convention .glsl seeds",
    )
    parser.add_argument(
        "--reset",
        action="store_true",
        help="Delete and recreate the collection for a clean re-ingest",
    )
    args = parser.parse_args()

    RAG_DB_DIR.mkdir(parents=True, exist_ok=True)

    ef = embedding_functions.SentenceTransformerEmbeddingFunction(
        model_name=settings.embedding_model
    )
    client = chromadb.PersistentClient(path=str(RAG_DB_DIR))
    if args.reset:
        try:
            client.delete_collection(name="glsl_shaders")
            print("  reset: dropped existing 'glsl_shaders' collection")
        except Exception:
            pass
    collection = client.get_or_create_collection(name="glsl_shaders", embedding_function=ef)

    total = 0

    if SHADERS_DIR.exists():
        n = ingest_directory(SHADERS_DIR, collection)
        print(f"  MirrorBooth shaders: {n} chunks from {SHADERS_DIR}")
        total += n

    if SEED_SHADERS_DIR.exists():
        n = ingest_seed_directory(SEED_SHADERS_DIR, collection)
        print(f"  ToyShaders seed corpus: {n} chunks from {SEED_SHADERS_DIR}")
        total += n

    if args.shaders_dir and args.shaders_dir.exists():
        n = ingest_directory(args.shaders_dir, collection)
        print(f"  Extra shaders: {n} chunks from {args.shaders_dir}")
        total += n

    if args.seed_dir and args.seed_dir.exists():
        n = ingest_seed_directory(args.seed_dir, collection)
        print(f"  Extra seeds: {n} chunks from {args.seed_dir}")
        total += n

    print(f"\nRAG database ready: {total} chunks stored in {RAG_DB_DIR}")


if __name__ == "__main__":
    main()
