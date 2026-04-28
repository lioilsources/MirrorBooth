"""
Build the ChromaDB RAG knowledge base from existing MirrorBooth shaders.

Usage:
    python rag/ingest.py
    python rag/ingest.py --shaders-dir /path/to/extra/glsl/files
"""

import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

import chromadb
from chromadb.utils import embedding_functions
from config import settings, SHADERS_DIR, RAG_DB_DIR

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


def ingest_directory(shaders_dir: Path, collection: chromadb.Collection) -> int:
    frag_files = list(shaders_dir.glob("*.frag"))
    count = 0
    for frag_file in frag_files:
        code = frag_file.read_text(encoding="utf-8")
        techniques = _infer_techniques(code, frag_file.stem)
        chunks = _split_functions(code)
        for idx, chunk in enumerate(chunks):
            if len(chunk.strip()) < 20:
                continue
            doc_id = f"{frag_file.stem}_{idx}"
            collection.upsert(
                ids=[doc_id],
                documents=[chunk],
                metadatas=[{
                    "source": str(frag_file),
                    "filter_name": frag_file.stem,
                    "techniques": ",".join(techniques),
                    "chunk_index": idx,
                }],
            )
            count += 1
    return count


def main():
    parser = argparse.ArgumentParser(description="Ingest GLSL shaders into ChromaDB")
    parser.add_argument(
        "--shaders-dir",
        type=Path,
        default=None,
        help="Additional directory of .frag files to ingest",
    )
    args = parser.parse_args()

    RAG_DB_DIR.mkdir(parents=True, exist_ok=True)

    ef = embedding_functions.SentenceTransformerEmbeddingFunction(
        model_name=settings.embedding_model
    )
    client = chromadb.PersistentClient(path=str(RAG_DB_DIR))
    collection = client.get_or_create_collection(name="glsl_shaders", embedding_function=ef)

    total = 0

    if SHADERS_DIR.exists():
        n = ingest_directory(SHADERS_DIR, collection)
        print(f"  MirrorBooth shaders: {n} chunks from {SHADERS_DIR}")
        total += n

    if args.shaders_dir and args.shaders_dir.exists():
        n = ingest_directory(args.shaders_dir, collection)
        print(f"  Extra shaders: {n} chunks from {args.shaders_dir}")
        total += n

    print(f"\nRAG database ready: {total} chunks stored in {RAG_DB_DIR}")


if __name__ == "__main__":
    main()
