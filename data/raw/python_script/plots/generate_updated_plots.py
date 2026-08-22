import os, glob, torch
import torch.nn as nn
import torch.nn.functional as F
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from torch_geometric.loader import DataLoader
from torch_geometric.nn import GATv2Conv, global_mean_pool, global_max_pool
from sklearn.metrics import confusion_matrix, roc_curve, auc

try:
    import torch_geometric.data.data
    torch.serialization.add_safe_globals([torch_geometric.data.data.DataEdgeAttr])
except Exception:
    pass

BASE_DIR = r"C:\Users\numhe\OneDrive\Desktop\research\data\labeled_dataset"
LANGUAGES = ["Solidity", "Rust", "Vyper", "Go", "C++"]
MODEL_PATH = r"C:\Users\numhe\OneDrive\Desktop\research\data\raw\python_script\PyG\robust_gat_best.pth"

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
    print("=" * 80)
    print("🎨 GENERATING UPDATED HIGH-RES EVALUATION PLOTS (9,000 DATASET)")
    print("=" * 80)

    model = RobustGAT()
    if os.path.exists(MODEL_PATH):
        model.load_state_dict(torch.load(MODEL_PATH, map_location='cpu'))
        print("✅ Loaded Model: robust_gat_best.pth")
    else:
        print("❌ Model file not found! Please check robust_gat_best.pth")
        return

    model.eval()
    all_dataset = []
    lang_accs = {}

    for lang in LANGUAGES:
        pyg_folder = os.path.join(BASE_DIR, lang, "PyG_Project_Level_Dataset")
        files = glob.glob(os.path.join(pyg_folder, "*.pt"))
        data_list = [torch.load(f, weights_only=False) for f in files]
        all_dataset.extend(data_list)
        
        # Calculate per-language accuracy
        l_loader = DataLoader(data_list, batch_size=64, shuffle=False)
        l_true, l_pred = [], []
        with torch.no_grad():
            for b in l_loader:
                out = model(b.x, b.edge_index, b.batch)
                l_pred.extend(out.argmax(dim=1).numpy())
                l_true.extend(b.y.numpy())
        lang_accs[lang] = np.mean(np.array(l_true) == np.array(l_pred)) * 100

    loader = DataLoader(all_dataset, batch_size=64, shuffle=False)
    y_true, y_pred, y_probs = [], [], []

    with torch.no_grad():
        for batch in loader:
            out = model(batch.x, batch.edge_index, batch.batch)
            probs = F.softmax(out, dim=1)[:, 1]
            preds = out.argmax(dim=1)
            y_true.extend(batch.y.numpy())
            y_pred.extend(preds.numpy())
            y_probs.extend(probs.numpy())

    y_true = np.array(y_true)
    y_pred = np.array(y_pred)
    y_probs = np.array(y_probs)

    # 1. Confusion Matrix Plot
    plt.figure(figsize=(7, 6))
    cm = confusion_matrix(y_true, y_pred)
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', xticklabels=['Safe', 'Vulnerable'], yticklabels=['Safe', 'Vulnerable'], cbar=False, annot_kws={"size": 14})
    plt.title("Updated GAT Confusion Matrix (9,000 Projects)", fontsize=13, fontweight='bold')
    plt.xlabel("Predicted Label", fontsize=11)
    plt.ylabel("True Label", fontsize=11)
    plt.tight_layout()
    plt.savefig("gat_confusion_matrix_updated.png", dpi=300)
    plt.close()
    print("  [✓] Saved: gat_confusion_matrix_updated.png")

    # 2. ROC Curve Plot
    fpr, tpr, _ = roc_curve(y_true, y_probs)
    roc_auc = auc(fpr, tpr)
    plt.figure(figsize=(7, 6))
    plt.plot(fpr, tpr, color='#2980b9', lw=2.5, label=f'Overall ROC-AUC = {roc_auc:.4f}')
    plt.plot([0, 1], [0, 1], color='gray', linestyle='--')
    plt.title("Updated ROC-AUC Curve (Multi-Language)", fontsize=13, fontweight='bold')
    plt.xlabel("False Positive Rate", fontsize=11)
    plt.ylabel("True Positive Rate", fontsize=11)
    plt.legend(loc="lower right", fontsize=11)
    plt.grid(alpha=0.3)
    plt.tight_layout()
    plt.savefig("gat_roc_curve_updated.png", dpi=300)
    plt.close()
    print("  [✓] Saved: gat_roc_curve_updated.png")

    # 3. Per-Language Accuracy Bar Chart
    plt.figure(figsize=(8, 5))
    bars = plt.bar(lang_accs.keys(), lang_accs.values(), color=['#3498db', '#e67e22', '#95a5a6', '#2ecc71', '#9b59b6'], width=0.55)
    plt.ylim(0, 105)
    plt.title("Per-Language Benchmark Accuracy Comparison", fontsize=13, fontweight='bold')
    plt.ylabel("Accuracy (%)", fontsize=11)
    for bar in bars:
        yval = bar.get_height()
        plt.text(bar.get_x() + bar.get_width()/2.0, yval + 1.5, f"{yval:.2f}%", ha='center', va='bottom', fontweight='bold')
    plt.grid(axis='y', alpha=0.3)
    plt.tight_layout()
    plt.savefig("per_language_accuracy_bar.png", dpi=300)
    plt.close()
    print("  [✓] Saved: per_language_accuracy_bar.png")

    print("\n🎉 All 3 Evaluation Plots Successfully Generated!")

if __name__ == "__main__":
    main()