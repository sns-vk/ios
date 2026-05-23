import SwiftUI

struct VennDiagramIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 2)
                .frame(width: 14, height: 14)
                .offset(x: -4)

            Circle()
                .stroke(lineWidth: 2)
                .frame(width: 14, height: 14)
                .offset(x: 4)
        }
        .foregroundStyle(.secondary)
        .frame(width: 22, height: 22)
    }
}
