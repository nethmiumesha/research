import os
import glob
import torch
import torch.nn as nn
import torch.nn.functional as F
from torch_geometric.loader import DataLoader
from torch_geometric.nn import GATConv, global_mean_pool
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, roc_auc_score

# PyTorch 2.6+ unpickling support for PyG data objects
import torch_geometric.data.data
try:
    torch.serialization.add_safe_globals([torch_geometric.data.data.DataEdgeAttr])
except Exception:
    pass

# ==========================================
# 1. BASE DATASET PATH (Language Directories)
# ==========================================
BASE_DIR = r"C:\Users\numhe\OneDrive\Desktop\my_research (2)\data\labeled_dataset"
LANGUAGES = ["Solidity", "Rust", "Vyper", "Go", "C++"]

# ==========================================
# 2. GAT MODEL ARCHITECTURE
# ==========================================
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

# ==========================================
# 3. FULL DATASET TRAINING PIPELINE
# ==========================================
def main():
    print("=" * 75)
    print("🚀 LOADING ALL MULTI-LANGUAGE PyG GRAPH DATASETS (FULL RECURSIVE SCAN)...")
    print("=" * 75)
    
    all_files = []
    
    for lang in LANGUAGES:
        lang_path = os.path.join(BASE_DIR, lang)
        # Recursive glob search for all .pt files inside any subfolder
        files = glob.glob(os.path.join(lang_path, "**", "*.pt"), recursive=True)
        print(f"  [+] {lang:<10} : Found {len(files)} graphs (.pt)")
        all_files.extend(files)

    total_graphs = len(all_files)
    print("=" * 75)
    print(f"📊 TOTAL COMBINED DATASET SIZE: {total_graphs} Graphs")
    print("=" * 75)

    if total_graphs == 0:
        print("❌ Error: No .pt graph files found! Check BASE_DIR path.")
        return

    # Load PyG data objects into memory safely
    print("⏳ Processing all PyG objects into memory...")
    dataset = [torch.load(f, weights_only=False) for f in all_files]
    labels = [data.y.item() for data in dataset]

    # Stratified Train (80%), Val (10%), Test (10%) Split
    train_files, test_files = train_test_split(dataset, test_size=0.20, random_state=42, stratify=labels)
    val_files, test_files = train_test_split(test_files, test_size=0.50, random_state=42, stratify=[d.y.item() for d in test_files])

    # PyG DataLoaders
    train_loader = DataLoader(train_files, batch_size=64, shuffle=True)
    val_loader = DataLoader(val_files, batch_size=64, shuffle=False)
    test_loader = DataLoader(test_files, batch_size=64, shuffle=False)

    print(f"✅ Data Split Complete: Train={len(train_files)} | Val={len(val_files)} | Test={len(test_files)}")

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"💻 Training Device: {device}")

    model = SmartContractGAT(in_channels=9, hidden_channels=64, num_classes=2, heads=4).to(device)
    optimizer = torch.optim.Adam(model.parameters(), lr=0.001, weight_decay=1e-4)
    criterion = nn.CrossEntropyLoss()

    best_val_acc = 0.0
    epochs = 30

    print("\n" + "=" * 75)
    print("🔥 STARTING FULL DATASET GAT TRAINING (30 EPOCHS)")
    print("=" * 75)

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

        train_loss = total_loss / len(train_files)

        model.eval()
        val_preds, val_targets = [], []
        with torch.no_grad():
            for batch in val_loader:
                batch = batch.to(device)
                out = model(batch.x, batch.edge_index, batch.batch)
                preds = out.argmax(dim=1)
                val_preds.extend(preds.cpu().numpy())
                val_targets.extend(batch.y.cpu().numpy())

        val_acc = accuracy_score(val_targets, val_preds)
        print(f"Epoch {epoch:02d}/{epochs:02d} | Train Loss: {train_loss:.4f} | Val Accuracy: {val_acc * 100:.2f}%")

        if val_acc > best_val_acc:
            best_val_acc = val_acc
            torch.save(model.state_dict(), "best_gat_full_22k_model.pth")

    print("\n" + "=" * 75)
    print("🎯 EVALUATING FULL DATASET MODEL ON TEST SET...")
    print("=" * 75)

    model.load_state_dict(torch.load("best_gat_full_22k_model.pth"))
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
    auc = roc_auc_score(test_targets, test_probs)

    print(f"\n📊 FINAL FULL DATASET EVALUATION RESULTS:")
    print(f"  - Total Test Samples: {len(test_files)}")
    print(f"  - Test Accuracy     : {acc * 100:.2f}%")
    print(f"  - Precision         : {prec * 100:.2f}%")
    print(f"  - Recall            : {rec * 100:.2f}%")
    print(f"  - F1-Score          : {f1 * 100:.2f}%")
    print(f"  - ROC-AUC Score     : {auc:.4f}")
    print("\n✅ Best Full Model saved as: 'best_gat_full_22k_model.pth'")
    print("=" * 75)

if __name__ == "__main__":
    main()