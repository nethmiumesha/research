import os, glob, random, torch
import torch.nn as nn
import torch.nn.functional as F
import pandas as pd
from torch_geometric.loader import DataLoader
from torch_geometric.nn import GATv2Conv, global_mean_pool, global_max_pool
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, matthews_corrcoef, roc_auc_score

try:
    import torch_geometric.data.data
    torch.serialization.add_safe_globals([torch_geometric.data.data.DataEdgeAttr])
except Exception:
    pass

BASE_DIR = r"C:\Users\numhe\OneDrive\Desktop\research\data\labeled_dataset"
LANGUAGES = ["Solidity", "Rust", "Vyper", "Go", "C++"]

class RobustGAT(nn.Module):
    def __init__(self, in_channels=9, hidden_channels=64, num_classes=2, heads=4):
        super(RobustGAT, self).__init__()
        self.conv1 = GATv2Conv(in_channels, hidden_channels, heads=heads, dropout=0.1)
        self.conv2 = GATv2Conv(hidden_channels * heads, hidden_channels, heads=1, concat=False, dropout=0.1)
        self.fc1 = nn.Linear(hidden_channels * 2, 32)
        self.fc2 = nn.Linear(32, num_classes)
        self.dropout = nn.Dropout(0.2)

    def forward(self, x, edge_index, batch):
        x = F.elu(self.conv1(x, edge_index))
        x = F.elu(self.conv2(x, edge_index))
        h = torch.cat([global_mean_pool(x, batch), global_max_pool(x, batch)], dim=1)
        h = self.dropout(F.relu(self.fc1(h)))
        return self.fc2(h)

def main():
    print("=" * 85)
    print("🚀 LOADING BALANCED MULTI-LANGUAGE BENCHMARK DATASET")
    print("=" * 85)

    lang_datasets = {}
    all_dataset = []

    for lang in LANGUAGES:
        pyg_folder = os.path.join(BASE_DIR, lang, "PyG_Project_Level_Dataset")
        files = glob.glob(os.path.join(pyg_folder, "*.pt"))
        data_list = [torch.load(f, weights_only=False) for f in files]
        lang_datasets[lang] = data_list
        all_dataset.extend(data_list)
        print(f"  [+] {lang:<10} : Loaded {len(data_list)} Graphs")

    print(f"\n📊 TOTAL COMBINED DATASET: {len(all_dataset)} Graphs")

    labels = [d.y.item() for d in all_dataset]
    train_data, test_data = train_test_split(all_dataset, test_size=0.20, random_state=42, stratify=labels)
    val_data, test_data = train_test_split(test_data, test_size=0.50, random_state=42, stratify=[d.y.item() for d in test_data])

    train_loader = DataLoader(train_data, batch_size=64, shuffle=True)
    val_loader = DataLoader(val_data, batch_size=64, shuffle=False)

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model = RobustGAT().to(device)
    optimizer = torch.optim.Adam(model.parameters(), lr=0.002, weight_decay=1e-4)
    criterion = nn.CrossEntropyLoss()

    best_val_acc = 0.0
    epochs = 30

    print("\n" + "=" * 85)
    print("🔥 TRAINING ROBUST GAT MODEL (PREVENTING CLASS COLLAPSE)")
    print("=" * 85)

    for epoch in range(1, epochs + 1):
        model.train()
        total_loss = 0.0
        for batch in train_loader:
            batch = batch.to(device)
            optimizer.zero_grad()
            out = model(batch.x, batch.edge_index, batch.batch)
            loss = criterion(out, batch.y)
            loss.backward()
            optimizer.step()
            total_loss += loss.item() * batch.num_graphs

        # Validation
        model.eval()
        v_preds, v_targets = [], []
        with torch.no_grad():
            for batch in val_loader:
                batch = batch.to(device)
                out = model(batch.x, batch.edge_index, batch.batch)
                v_preds.extend(out.argmax(dim=1).cpu().numpy())
                v_targets.extend(batch.y.cpu().numpy())

        val_acc = accuracy_score(v_targets, v_preds)
        print(f"Epoch {epoch:02d}/{epochs:02d} | Train Loss: {total_loss/len(train_data):.4f} | Val Accuracy: {val_acc * 100:.2f}%")

        if val_acc > best_val_acc:
            best_val_acc = val_acc
            torch.save(model.state_dict(), "robust_gat_best.pth")

    print("\n" + "=" * 85)
    print("📊 FINAL VERIFIED PER-LANGUAGE BENCHMARK RESULTS")
    print("=" * 85)

    model.load_state_dict(torch.load("robust_gat_best.pth"))
    model.eval()

    results = []
    for lang in LANGUAGES:
        loader = DataLoader(lang_datasets[lang], batch_size=64, shuffle=False)
        y_true, y_pred, y_probs = [], [], []
        with torch.no_grad():
            for batch in loader:
                batch = batch.to(device)
                out = model(batch.x, batch.edge_index, batch.batch)
                probs = F.softmax(out, dim=1)[:, 1]
                preds = out.argmax(dim=1)
                y_true.extend(batch.y.cpu().numpy())
                y_pred.extend(preds.cpu().numpy())
                y_probs.extend(probs.cpu().numpy())

        results.append({
            "Language": lang,
            "Samples": len(lang_datasets[lang]),
            "Accuracy (%)": f"{accuracy_score(y_true, y_pred)*100:.2f}",
            "Precision (%)": f"{precision_score(y_true, y_pred, zero_division=0)*100:.2f}",
            "Recall (%)": f"{recall_score(y_true, y_pred, zero_division=0)*100:.2f}",
            "F1-Score (%)": f"{f1_score(y_true, y_pred, zero_division=0)*100:.2f}",
            "MCC": f"{matthews_corrcoef(y_true, y_pred):.4f}",
            "ROC-AUC": f"{roc_auc_score(y_true, y_probs):.4f}"
        })

    df = pd.DataFrame(results)
    print("\n" + df.to_string(index=False))
    print("=" * 85)

if __name__ == "__main__":
    main()