"""
Build the ChromaDB RAG knowledge base from existing MirrorBooth shaders.

Usage:
    python rag/ingest.py
    python rag/ingest.py --shaders-dir /path/to/extra/glsl/files
"""

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

import chromadb
from chromadb.utils import embedding_functions

from config import RAG_DB_DIR, SHADERS_DIR, settings
from rag.chunking import LOCAL_COLLECTION, infer_techniques, split_functions


def ingest_directory(shaders_dir: Path, collection: chromadb.Collection) -> int:
    frag_files = list(shaders_dir.glob("*.frag"))
    count = 0
    for frag_file in frag_files:
        code = frag_file.read_text(encoding="utf-8")
        techniques = infer_techniques(code, frag_file.stem)
        chunks = split_functions(code)
        for idx, chunk in enumerate(chunks):
            if len(chunk.strip()) < 20:
                continue
            doc_id = f"{frag_file.stem}_{idx}"
            collection.upsert(
                ids=[doc_id],
                documents=[chunk],
                metadatas=[
                    {
                        "source": str(frag_file),
                        "filter_name": frag_file.stem,
                        "techniques": ",".join(techniques),
                        "chunk_index": idx,
                    }
                ],
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

    ef = embedding_functions.SentenceTransformerEmbeddingFunction(model_name=settings.embedding_model)
    client = chromadb.PersistentClient(path=str(RAG_DB_DIR))
    collection = client.get_or_create_collection(name=LOCAL_COLLECTION, embedding_function=ef)

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
