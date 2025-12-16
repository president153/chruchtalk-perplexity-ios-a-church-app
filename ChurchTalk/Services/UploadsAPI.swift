//
//  UploadsAPI.swift
//  ChurchTalk
//
//  API service for file uploads using S3 presigned URLs.
//

import Foundation
import UIKit

// MARK: - Request/Response Types

enum UploadType: String, Codable {
    case profilePhoto = "profile-photos"
    case churchImage = "church-images"
    case bulletinMedia = "bulletin-media"
    case eventImage = "event-images"
    case storyMedia = "stories"
    case outreachImage = "outreach-images"
}

struct PresignedUrlRequest: Codable {
    let uploadType: String
    let fileName: String
    let contentType: String
}

struct PresignedUrlResponse: Codable {
    let uploadUrl: String
    let fileUrl: String
    let expiresIn: Int
}

// MARK: - UploadsAPI

/// API service for file uploads
class UploadsAPI {

    // MARK: - Singleton

    static let shared = UploadsAPI()

    // MARK: - Dependencies

    private let client = APIClient.shared

    // MARK: - Init

    private init() {}

    // MARK: - Get Presigned URL

    /// Get a presigned URL for uploading a file
    func getPresignedUrl(
        uploadType: UploadType,
        fileName: String,
        contentType: String
    ) async throws -> PresignedUrlResponse {
        let request = PresignedUrlRequest(
            uploadType: uploadType.rawValue,
            fileName: fileName,
            contentType: contentType
        )
        return try await client.post("/uploads/presigned-url", body: request)
    }

    // MARK: - Upload Image

    /// Upload an image and return the final URL
    /// - Parameters:
    ///   - image: The UIImage to upload
    ///   - uploadType: The type of upload (determines S3 folder)
    ///   - quality: JPEG compression quality (0.0 to 1.0)
    /// - Returns: The permanent URL of the uploaded image
    func uploadImage(
        _ image: UIImage,
        uploadType: UploadType,
        quality: CGFloat = 0.8
    ) async throws -> String {
        // Compress image to JPEG
        guard let imageData = image.jpegData(compressionQuality: quality) else {
            throw UploadError.compressionFailed
        }

        // Generate a unique filename
        let fileName = "\(UUID().uuidString).jpg"
        let contentType = "image/jpeg"

        // Get presigned URL
        let presignedResponse = try await getPresignedUrl(
            uploadType: uploadType,
            fileName: fileName,
            contentType: contentType
        )

        // Upload to S3
        guard let uploadUrl = URL(string: presignedResponse.uploadUrl) else {
            throw UploadError.invalidUrl
        }

        var request = URLRequest(url: uploadUrl)
        request.httpMethod = "PUT"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("public-read", forHTTPHeaderField: "x-amz-acl")
        request.httpBody = imageData

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Upload failed: No HTTP response")
            throw UploadError.uploadFailed
        }

        if !(200...299).contains(httpResponse.statusCode) {
            let responseBody = String(data: data, encoding: .utf8) ?? "No body"
            print("❌ S3 Upload failed with status \(httpResponse.statusCode): \(responseBody)")
            throw UploadError.uploadFailed
        }

        return presignedResponse.fileUrl
    }
}

// MARK: - Upload Errors

enum UploadError: LocalizedError {
    case compressionFailed
    case invalidUrl
    case uploadFailed

    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress image"
        case .invalidUrl:
            return "Invalid upload URL"
        case .uploadFailed:
            return "Failed to upload file"
        }
    }
}
