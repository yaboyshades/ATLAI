import numpy as np
from src.core.neural_atom import NeuralAtom, NeuralStore


def test_atom_registration_and_retrieval():
    store = NeuralStore()
    atom = NeuralAtom("test", "value", vector=np.ones(1024))
    store.register(atom)
    retrieved = store.get("test")
    assert retrieved is atom


def test_lineage_links():
    parent = NeuralAtom("p", "val")
    child = NeuralAtom("c", "child", parent_keys=["p"], birth_event="test")
    store = NeuralStore()
    store.register(parent)
    store.register_with_lineage(child, [parent], "test", {})
    assert "c" in parent.children_keys
    assert store.get("c").parent_keys == ["p"]
