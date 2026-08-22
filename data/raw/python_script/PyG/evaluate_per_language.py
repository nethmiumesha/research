import os, glob, torch
import torch.nn as nn
import torch.nn.functional as F
import pandas as pd
from torch_geometric.loader import DataLoader
from torch_geometric.nn import GATConv, global_mean_pool
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, matthews_corrcoef, roc_auc_score

# Safe unpickling for PyG data
try:
    import torch_geometric.data.data
    torch.serialization.add_safe_globals([torch_geometric.data.data.DataEdgeAttr])
except Exception:
    pass

BASE_DIR = r"C:\Users\numhe\OneDrive\Desktop\research\data\labeled_dataset"
LANGUAGES = ["Solidity", "Rust", "Vyper", "Go", "C++"]

class SmartContractGAT(nn.Module):
    def __init__(self, in_channels=9, hidden_channels=64, num_classes=2, heads=4):
        super(SmartContractGAT, self).__init__()
        self.conv1 = GATConv(in_channels, hidden_channels, heads=heads, dropout=0.2)
        self.conv2 = GATConv(hidden_channels * heads, hidden_channels, heads=1, concat=False, dropout=0.2)
        self.fc1 = nn.Linear(hidden_channels, 32)
        self.fc2 = nn.Linear(32, num_classes)
        self.dropout = nn.Dropout(0.3)

    def forward(self, x, edge_index, batch):
        x = F.elu(self.conv1(x, edge_index))
        x = F.elu(self.conv2(x, edge_index))
        x = global_mean_pool(x, batch)
        x = F.relu(self.fc1(x))
        x = self.dropout(x)
        return self.fc2(x)

def main():
    print("=" * 85)
    print("📊 EVALUATING PER-LANGUAGE PERFORMANCE (ACADEMIC BENCHMARK TABLE)")
    print("=" * 85)

    model = SmartContractGAT()
    model_path = "best_gat_multilang_model.pth"
    if os.path.exists(model_path):
        model.load_state_dict(torch.load(model_path, map_location='cpu'))
    model.eval()

    results = []

    for lang in LANGUAGES:
        pyg_folder = os.path.join(BASE_DIR, lang, "PyG_Project_Level_Dataset")
        files = glob.glob(os.path.join(pyg_folder, "*.pt"))
        if not files:
            continue

        dataset = [torch.load(f, weights_only=False) for f in files]
        loader = DataLoader(dataset, batch_size=64, shuffle=False)

        y_true, y_pred, y_probs = [], [], []
        with torch.no_grad():
            for batch in loader:
                out = model(batch.x, batch.edge_index, batch.batch)
                probs = F.softmax(out, dim=1)[:, 1]
                preds = out.argmax(dim=1)
                y_true.extend(batch.y.cpu().numpy())
                y_pred.extend(preds.cpu().numpy())
                y_probs.extend(probs.cpu().numpy())

        acc = accuracy_score(y_true, y_pred) * 100
        prec = precision_score(y_true, y_pred, zero_division=0) * 100
        rec = recall_score(y_true, y_pred, zero_division=0) * 100
        f1 = f1_score(y_true, y_pred, zero_division=0) * 100
        mcc = matthews_corrcoef(y_true, y_pred)
        try:
            auc = roc_auc_score(y_true, y_probs)
        except Exception:
            auc = 0.5

        results.append({
            "Language": lang,
            "Samples": len(dataset),
            "Accuracy (%)": f"{acc:.2f}",
            "Precision (%)": f"{prec:.2f}",
            "Recall (%)": f"{rec:.2f}",
            "F1-Score (%)": f"{f1:.2f}",
            "MCC": f"{mcc:.4f}",
            "ROC-AUC": f"{auc:.4f}"
        })

    df = pd.DataFrame(results)
    print("\n" + df.to_string(index=False))
    print("=" * 85)

if __name__ == "__main__":
    main()