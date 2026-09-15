// Cup Season — one way to sign a round photograph for a screen (D361).
//
// Home, the board and the receipt all put a golfer's photograph on a screen,
// and each used to sign it its own way: a fresh batch every load, no cache,
// the original bytes. This is the one way. A path is signed once an hour,
// SIZED FOR A SCREEN (1200 wide, quality 75 — 35–50% of the original bytes,
// measured 2026-09-14), and the answer says which paths the storage refused
// and which simply could not be reached this time, so a surface can keep a
// picture it already has through a bad moment on the network.

import Foundation
import Supabase

public enum StoragePhotos {
  public static let width = 1200
  public static let quality = 75

  /// Signed, sized URLs for `paths`, through `SignedURLCache.shared`.
  public static func sized(_ paths: [String], storage: SupabaseStorageClient,
                           expiresIn: Int = 3600) async -> SignedURLCache.Resolution {
    await SignedURLCache.shared.resolve(paths, expiresIn: expiresIn) { missing in
      await withTaskGroup(of: (String, SignedURLCache.Outcome).self,
                          returning: [String: SignedURLCache.Outcome].self) { group in
        for path in missing {
          group.addTask {
            do {
              let u = try await storage.from("media").createSignedURL(
                path: path, expiresIn: expiresIn,
                transform: TransformOptions(width: width, quality: quality))
              return (path, .url(u))
            } catch let e as StorageError {
              // the storage's own refusal is about the object; anything else is
              // about the connection and says nothing about the picture
              let code = Int(e.statusCode ?? "") ?? 0
              return (path, (400...499).contains(code) ? .denied : .unavailable)
            } catch {
              return (path, .unavailable)
            }
          }
        }
        var fresh: [String: SignedURLCache.Outcome] = [:]
        for await (path, o) in group { fresh[path] = o }
        return fresh
      }
    }
  }
}
