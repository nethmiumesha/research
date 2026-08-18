import os
import glob
import torch
import torch.nn as nn
import torch.nn.functional as F
import matplotlib.pyplot as plt
from torch_geometric.loader import DataLoader
from torch_geometric.nn import GATConv, global_mean_pool
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, roc_auc_score, confusion_matrix, ConfusionMatrixDisplay, roc_curve

# Safe unpickling for PyG data
try:
    import torch_geometric.data.data
    torch.serialization.add_safe_globals([torch_geometric.data.data.DataEdgeAttr])
except Exception:
    pass

# Updated Base Directory
BASE_DIR = r"C:\Users\numhe\OneDrive\Desktop\research\data\labeled_dataset"
LANGUAGES = ["Solidity", "Rust", "Vyper", "Go", "C++"]

# Set to "PyG_Project_Level_Dataset" (7.7k) OR "PyG_Processed_Dataset" (23.6k)
DATASET_SUBFOLDER = "PyG_Project_Level_Dataset"

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
    print("=" * 80)
    print(f"🚀 LOADING PyG GRAPHS FROM: {DATASET_SUBFOLDER}")
    print("=" * 80)

    all_files = []
    for lang in LANGUAGES:
        pyg_folder = os.path.join(BASE_DIR, lang, DATASET_SUBFOLDER)
        files = glob.glob(os.path.join(pyg_folder, "*.pt"))
        print(f"  [+] {lang:<10} : Loaded {len(files):>5} graphs")
        all_files.extend(files)

    total_graphs = len(all_files)
    print(f"\n📊 TOTAL COMBINED DATASET SIZE: {total_graphs} Graphs")

    if total_graphs == 0:
        print("❌ Error: No .pt files found. Please verify the folder path!")
        return

    print("⏳ Loading PyG objects into memory...")
    dataset = [torch.load(f, weights_only=False) for f in all_files]
    labels = [d.y.item() for d in dataset]

    # Stratified Train (80%) / Val (10%) / Test (10%) Split
    train_data, test_data = train_test_split(dataset, test_size=0.20, random_state=42, stratify=labels)
    val_data, test_data = train_test_split(test_data, test_size=0.50, random_state=42, stratify=[d.y.item() for d in test_data])

    train_loader = DataLoader(train_data, batch_size=128, shuffle=True)
    val_loader = DataLoader(val_data, batch_size=128, shuffle=False)
    test_loader = DataLoader(test_data, batch_size=128, shuffle=False)

    print(f"✅ Split Counts: Train={len(train_data)} | Val={len(val_data)} | Test={len(test_data)}")

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"💻 Training Device: {device}")

    model = SmartContractGAT(in_channels=9, hidden_channels=64, num_classes=2, heads=4).to(device)
    optimizer = torch.optim.Adam(model.parameters(), lr=0.001, weight_decay=1e-4)
    criterion = nn.CrossEntropyLoss()

    best_val_acc = 0.0
    epochs = 25

    print("\n" + "=" * 80)
    print("🔥 STARTING GAT TRAINING (25 EPOCHS)")
    print("=" * 80)

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

        train_loss = total_loss / len(train_data)

        # Validation
        model.eval()
        val_preds, val_targets = [], []
        with torch.no_grad():
            for batch in val_loader:
                batch = batch.to(device)
                out = model(batch.x, batch.edge_index, batch.batch)
                val_preds.extend(out.argmax(dim=1).cpu().numpy())
                val_targets.extend(batch.y.cpu().numpy())

        val_acc = accuracy_score(val_targets, val_preds)
        print(f"Epoch {epoch:02d}/{epochs:02d} | Train Loss: {train_loss:.4f} | Val Accuracy: {val_acc * 100:.2f}%")

        if val_acc > best_val_acc:
            best_val_acc = val_acc
            torch.save(model.state_dict(), "best_gat_multilang_model.pth")

    print("\n" + "=" * 80)
    print(f"🎯 EVALUATING ON TEST SET ({len(test_data)} UNSEEN GRAPHS)...")
    print("=" * 80)

    model.load_state_dict(torch.load("best_gat_multilang_model.pth"))
    model.eval()

    test_preds, test_targets, test_probs = [], [], []
    with torch.no_grad():
        for batch in test_loader:
            batch = batch.to(device)
            out = model(batch.x, batch.edge_index, batch.batch)
            probs = F.softmax(out, dim=1)[:, 1]
            preds = out.argmax(dim=1)
            test_preds.extend(preds.cpu().numpy())
            test_targets.extend(batch.y.cpu().numpy())
            test_probs.extend(probs.cpu().numpy())

    acc = accuracy_score(test_targets, test_preds)
    prec = precision_score(test_targets, test_preds)
    rec = recall_score(test_targets, test_preds)
    f1 = f1_score(test_targets, test_preds)
    auc_val = roc_auc_score(test_targets, test_probs)

    print(f"\n📊 FINAL BENCHMARK TEST RESULTS:")
    print(f"  • Test Accuracy  : {acc * 100:.2f}%")
    print(f"  • Precision      : {prec * 100:.2f}%")
    print(f"  • Recall         : {rec * 100:.2f}%")
    print(f"  • F1-Score       : {f1 * 100:.2f}%")
    print(f"  • ROC-AUC Score  : {auc_val:.4f}")

    # Generate Evaluation Charts
    cm = confusion_matrix(test_targets, test_preds)
    disp = ConfusionMatrixDisplay(confusion_matrix=cm, display_labels=['Safe (0)', 'Vulnerable (1)'])
    fig, ax = plt.subplots(figsize=(6, 5))
    disp.plot(cmap=plt.cm.Blues, ax=ax)
    plt.title("GAT Confusion Matrix")
    plt.tight_layout()
    plt.savefig("gat_confusion_matrix.png", dpi=300)
    plt.close()

    fpr, tpr, _ = roc_curve(test_targets, test_probs)
    plt.figure(figsize=(6, 5))
    plt.plot(fpr, tpr, color='darkorange', lw=2, label=f'GAT (AUC = {auc_val:.4f})')
    plt.plot([0, 1], [0, 1], color='navy', lw=2, linestyle='--')
    plt.xlabel('False Positive Rate')
    plt.ylabel('True Positive Rate')
    plt.title('ROC Curve (GAT)')
    plt.legend(loc="lower right")
    plt.tight_layout()
    plt.savefig("gat_roc_curve.png", dpi=300)
    plt.close()

    print("\n📁 Evaluation Plots Saved:")
    print("  ✓ gat_confusion_matrix.png")
    print("  ✓ gat_roc_curve.png")
    print("  ✓ best_gat_multilang_model.pth")
    print("=" * 80)

if __name__ == "__main__":
    main()