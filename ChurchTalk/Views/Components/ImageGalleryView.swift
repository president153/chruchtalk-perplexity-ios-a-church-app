//
//  ImageGalleryView.swift
//  ChurchTalkAdmin
//
//  Full-screen image viewer with zoom and pan capabilities
//

import SwiftUI

struct ImageGalleryView: View {
    let imageUrl: String
    @Environment(\.dismiss) var dismiss

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            AsyncImage(url: URL(string: imageUrl)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    scale = min(max(scale * delta, 1), 4)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                    if scale < 1 {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            scale = 1
                                            offset = .zero
                                        }
                                    }
                                }
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if scale > 1 {
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if scale > 1 {
                                    scale = 1
                                    offset = .zero
                                    lastOffset = .zero
                                } else {
                                    scale = 2
                                }
                            }
                        }
                case .failure:
                    VStack(spacing: 16) {
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.5))
                        Text("Failed to load image")
                            .foregroundColor(.white.opacity(0.7))
                    }
                @unknown default:
                    EmptyView()
                }
            }

            // Close Button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.8))
                            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if scale == 1 && value.translation.height > 100 {
                        dismiss()
                    }
                }
        )
    }
}

// Preview
#if DEBUG
struct ImageGalleryView_Previews: PreviewProvider {
    static var previews: some View {
        ImageGalleryView(imageUrl: "https://via.placeholder.com/800x600")
    }
}
#endif
