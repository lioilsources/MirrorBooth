import chromadb
from chromadb.utils import embedding_functions
from config import settings, RAG_DB_DIR
from state import ShaderGenState


def rag_retriever_node(state: ShaderGenState) -> ShaderGenState:
    tech_spec = state["tech_spec"]
    query = " ".join(tech_spec.get("techniques", [])) + " " + tech_spec.get("description", "")

    ef = embedding_functions.SentenceTransformerEmbeddingFunction(
        model_name=settings.embedding_model
    )
    client = chromadb.PersistentClient(path=str(RAG_DB_DIR))

    try:
        collection = client.get_collection(name="glsl_shaders", embedding_function=ef)
        results = collection.query(query_texts=[query], n_results=settings.rag_top_k)
        snippets = results["documents"][0] if results["documents"] else []
    except Exception:
        # RAG DB not built yet — proceed without context
        snippets = []

    return {**state, "rag_context": snippets}
