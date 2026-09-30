import SwiftUI

struct ContentView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Page Capture").font(.headline)
                Spacer()
                Button { NSApp.terminate(nil) } label: {
                    Image(systemName: "xmark.circle.fill").font(.title3)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Quit Page Capture")
            }
            HStack {
                Button("Select Region") { model.selectRegion() }
                Button("Clear") { model.clearRegion() }
                    .disabled(model.region == nil)
            }
            Text(model.region?.summary ?? "No region")
                .foregroundStyle(.secondary)
            Button("Choose Folder") { model.chooseFolder() }
            Text(model.folder?.lastPathComponent ?? "No folder")
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .help(model.folder?.path ?? "")
            Divider()
            Button("Capture One Page") { Task { await model.captureOne() } }
                .disabled(model.region == nil || model.folder == nil || model.busy)
            Text(model.status)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
        .padding(14)
        .frame(width: 240, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.white, lineWidth: 2)
        )
    }
}
