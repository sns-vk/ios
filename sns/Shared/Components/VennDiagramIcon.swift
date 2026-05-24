import SwiftUI

struct VennDiagramIcon: View {
    var size: CGFloat = 22
    var color: Color = .secondary

    var body: some View {
        let scale = size / 22

        ZStack {
            Circle()
                .stroke(lineWidth: 2 * scale)
                .frame(width: 14 * scale, height: 14 * scale)
                .offset(x: -4 * scale)

            Circle()
                .stroke(lineWidth: 2 * scale)
                .frame(width: 14 * scale, height: 14 * scale)
                .offset(x: 4 * scale)
        }
        .foregroundStyle(color)
        .frame(width: size, height: size)
    }
}
