import os, glob, torch
import torch.nn as nn
import torch.nn.functional as F
from torch_geometric.loader import DataLoader
from torch_geometric.nn import GATv2Conv, global_mean_pool, global_max_pool
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, roc_auc_score

# Safe unpickling for PyG data
try:
    import torch_geometric.data.data
    torch.serialization.add_safe_globals([torch_geometric.data.data.DataEdgeAttr])
except Exception:
    pass

BASE_DIR = r"C:\Users\numhe\OneDrive\Desktop\research\data\labeled_dataset"
LANGUAGES = ["Solidity", "Rust", "Vyper", "Go", "C++"]

class AdvancedGATv2(nn.Module):
    def __init__(self, in_channels=9, hidden_channels=128, num_classes=2, heads=8):
        super(AdvancedGATv2, self).__init__()
        self.conv1 = GATv2Conv(in_channels, hidden_channels, heads=heads, dropout=0.1)
        self.conv2 = GATv2Conv(hidden_channels * heads, hidden_channels, heads=4, dropout=0.1)
        self.conv3 = GATv2Conv(hidden_channels * 4, hidden_channels, heads=1, concat=False, dropout=0.1)
        
        self.fc1 = nn.Linear(hidden_channels * 2, 64)
        self.bn1 = nn.BatchNorm1d(64)
        self.fc2 = nn.Linear(64, num_classes)
        self.dropout = nn.Dropout(0.2)

    def forward(self, x, edge_index, batch):
        x = F.elu(self.conv1(x, edge_index))
        x = F.elu(self.conv2(x, edge_index))
        x = F.elu(self.conv3(x, edge_index))
        
        # Dual Pooling (Mean + Max) for complete subgraph context
        pool_mean = global_mean_pool(x, batch)
        pool_max = global_max_pool(x, batch)
        h = torch.cat([pool_mean, pool_max], dim=1)
        
        h = self.dropout(F.relu(self.bn1(self.fc1(h))))
        return self.fc2(h)

def main():
    print("=" * 80)
    print("🚀 LOADING PROJECT-LEVEL PyG DATASET FOR ADVANCED GATv2 TRAINING...")
    print("=" * 80)

    all_files = []
    for lang in LANGUAGES:
        pyg_folder = os.path.join(BASE_DIR, lang, "PyG_Project_Level_Dataset")
        files = glob.glob(os.path.join(pyg_folder, "*.pt"))
        print(f"  [+] {lang:<10} : Loaded {len(files):>5} graphs")
        all_files.extend(files)

    dataset = [torch.load(f, weights_only=False) for f in all_files]
    labels = [d.y.item() for d in dataset]

    train_data, test_data = train_test_split(dataset, test_size=0.20, random_state=42, stratify=labels)
    val_data, test_data = train_test_split(test_data, test_size=0.50, random_state=42, stratify=[d.y.item() for d in test_data])

    train_loader = DataLoader(train_data, batch_size=64, shuffle=True)
    val_loader = DataLoader(val_data, batch_size=64, shuffle=False)
    test_loader = DataLoader(test_data, batch_size=64, shuffle=False)

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"💻 Training Device: {device}")

    model = AdvancedGATv2(in_channels=9, hidden_channels=128, num_classes=2, heads=8).to(device)
    optimizer = torch.optim.AdamW(model.parameters(), lr=0.001, weight_decay=1e-4)
    scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=40)
    criterion = nn.CrossEntropyLoss()

    best_val_acc = 0.0
    epochs = 40

    print("\n" + "=" * 80)
    print("🔥 TRAINING ADVANCED GATv2 (40 EPOCHS WITH DUAL POOLING)")
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

        scheduler.step()
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
    print(f"🎯 TEST EVALUATION ({len(test_data)} UNSEEN GRAPHS)...")
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

    print(f"\n📊 HIGH-ACCURACY GATv2 RESULTS:")
    print(f"  • Test Accuracy  : {acc * 100:.2f}%")
    print(f"  • Precision      : {prec * 100:.2f}%")
    print(f"  • Recall         : {rec * 100:.2f}%")
    print(f"  • F1-Score       : {f1 * 100:.2f}%")
    print(f"  • ROC-AUC Score  : {auc_val:.4f}")

if __name__ == "__main__":
    main()