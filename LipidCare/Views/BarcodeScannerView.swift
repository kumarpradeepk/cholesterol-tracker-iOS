import SwiftUI
import VisionKit

/// Full-screen barcode scanner using VisionKit's DataScanner.
/// When a product barcode resolves via FatSecret, the food is handed back to the caller.
struct BarcodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    var onFound: (FoodItem) -> Void

    @State private var status = "Point the camera at a product barcode"
    @State private var resolving = false
    @State private var handledCode: String?

    var body: some View {
        NavigationStack {
            ZStack {
                if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                    DataScannerRepresentable { code in
                        handleBarcode(code)
                    }
                    .ignoresSafeArea()

                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.85), lineWidth: 2)
                        .frame(width: 260, height: 160)
                } else {
                    VStack(spacing: 10) {
                        Text("📷").font(.system(size: 44))
                        Text("Camera scanning isn't available on this device, or camera permission was denied.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 32)
                    }
                }

                VStack {
                    Spacer()
                    VStack(spacing: 8) {
                        if resolving { ProgressView().tint(.white) }
                        Text(status)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 16))
                    .padding(24)
                }
            }
            .navigationTitle("Scan barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func handleBarcode(_ code: String) {
        guard !resolving, handledCode != code else { return }
        handledCode = code
        resolving = true
        status = "Looking up product…"
        Task {
            do {
                if let food = try await FoodRepository.findByBarcode(code) {
                    onFound(food)
                } else {
                    status = "Product not found — try searching by name"
                    resolving = false
                    handledCode = nil
                }
            } catch {
                status = error.localizedDescription
                resolving = false
                handledCode = nil
            }
        }
    }
}

private struct DataScannerRepresentable: UIViewControllerRepresentable {
    var onScan: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.ean13, .ean8, .upce])],
            qualityLevel: .balanced,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onScan: onScan) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onScan: (String) -> Void
        init(onScan: @escaping (String) -> Void) { self.onScan = onScan }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            for item in addedItems {
                if case .barcode(let barcode) = item, let payload = barcode.payloadStringValue {
                    onScan(payload)
                    return
                }
            }
        }
    }
}
