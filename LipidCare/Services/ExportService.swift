import Foundation
import SwiftUI

/// Builds CSV files and PDF reports for sharing with a doctor.
enum ExportService {

    private static var exportDirectory: URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("exports", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func csvFile(readings: [LipidReading]) -> URL? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"

        var csv = "date,total_mgdl,ldl_mgdl,hdl_mgdl,triglycerides_mgdl,non_hdl_mgdl,fasting,ldl_calculated,note\n"
        for r in readings.sorted(by: { $0.date < $1.date }) {
            let nonHdl: String
            if let total = r.totalMgdl, let hdl = r.hdlMgdl {
                nonHdl = String(Int(LipidMath.nonHdl(total: total, hdl: hdl)))
            } else {
                nonHdl = ""
            }
            let note = (r.note ?? "").replacingOccurrences(of: "\"", with: "\"\"")
            csv += [
                formatter.string(from: r.date),
                r.totalMgdl.map { String(Int($0)) } ?? "",
                r.ldlMgdl.map { String(Int($0)) } ?? "",
                r.hdlMgdl.map { String(Int($0)) } ?? "",
                r.trigMgdl.map { String(Int($0)) } ?? "",
                nonHdl,
                String(r.fasting),
                String(r.ldlCalculated),
                "\"\(note)\""
            ].joined(separator: ",") + "\n"
        }
        let url = exportDirectory.appendingPathComponent("lipidcare-readings.csv")
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    /// Renders a formatted PDF report from a SwiftUI view.
    @MainActor
    static func pdfReport(readings: [LipidReading], settings: UserSettings) -> URL? {
        let report = ReportView(readings: readings.sorted(by: { $0.date > $1.date }), settings: settings)
        let renderer = ImageRenderer(content: report.frame(width: 560))
        let url = exportDirectory.appendingPathComponent("lipidcare-report.pdf")

        var success = false
        renderer.render { size, renderInContext in
            var mediaBox = CGRect(origin: .zero, size: CGSize(width: size.width + 40, height: size.height + 40))
            guard let context = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else { return }
            context.beginPDFPage(nil)
            context.translateBy(x: 20, y: 20)
            renderInContext(context)
            context.endPDFPage()
            context.closePDF()
            success = true
        }
        return success ? url : nil
    }
}

/// Doctor-ready report layout, rendered to PDF.
private struct ReportView: View {
    let readings: [LipidReading]
    let settings: UserSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LipidCare — Cholesterol Report")
                .font(.title.bold())
            HStack(spacing: 8) {
                if !settings.name.isEmpty { Text(settings.name) }
                if let age = settings.age { Text("Age \(age)") }
                Text("Units: \(settings.unit.label)")
            }
            .font(.footnote)
            Text("Generated \(Date.now.formatted(date: .abbreviated, time: .shortened)) — for discussion with your healthcare provider.")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 6) {
                GridRow {
                    Text("Date").bold()
                    Text("Total").bold()
                    Text("LDL").bold()
                    Text("HDL").bold()
                    Text("TG").bold()
                    Text("Non-HDL").bold()
                    Text("TC/HDL").bold()
                    Text("Fasting").bold()
                }
                .font(.caption)
                Divider()
                ForEach(readings, id: \.persistentModelID) { r in
                    GridRow {
                        Text(r.date.formatted(date: .abbreviated, time: .omitted))
                        cell(r.totalMgdl, .total)
                        cell(r.ldlMgdl, .ldl, suffix: r.ldlCalculated ? "*" : "")
                        cell(r.hdlMgdl, .hdl)
                        cell(r.trigMgdl, .triglycerides)
                        nonHdlCell(r)
                        ratioCell(r)
                        Text(r.fasting ? "Yes" : "No")
                    }
                    .font(.caption)
                }
            }
            Text("* LDL calculated with the Friedewald equation. This report is not a medical document.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(Color.white)
        .foregroundStyle(Color.black)
    }

    private func cell(_ value: Double?, _ metric: MetricType, suffix: String = "") -> some View {
        Text(value.map { LipidMath.format($0, metric: metric, unit: settings.unit) + suffix } ?? "—")
    }
    private func nonHdlCell(_ r: LipidReading) -> some View {
        let value: String
        if let total = r.totalMgdl, let hdl = r.hdlMgdl {
            value = LipidMath.format(LipidMath.nonHdl(total: total, hdl: hdl), metric: .nonHdl, unit: settings.unit)
        } else {
            value = "—"
        }
        return Text(value)
    }
    private func ratioCell(_ r: LipidReading) -> some View {
        let value: String
        if let total = r.totalMgdl, let hdl = r.hdlMgdl, let ratio = LipidMath.tcHdlRatio(total: total, hdl: hdl) {
            value = String(format: "%.1f", ratio)
        } else {
            value = "—"
        }
        return Text(value)
    }
}
