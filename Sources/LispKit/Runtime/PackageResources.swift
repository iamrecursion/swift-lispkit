// DIALECT: added — finds the Scheme libraries and prelude that SwiftPM bundles with LispKit.

import Foundation

#if SWIFT_PACKAGE
    extension LispKitContext {
        /// The directory holding the `Libraries/` and `Prelude.scm` that
        /// SwiftPM bundles with this module, or `nil` if the bundle has no
        /// resource directory. If the bundle itself is missing, the first
        /// access traps, as `Bundle.module` calls `fatalError`.
        ///
        /// Upstream finds its resources in the framework its Xcode project
        /// builds, which a SwiftPM build does not have: there,
        /// `LispKitContext.bundle` is `nil`, so `includeInternalResources`
        /// finds nothing and `defaultPreludePath` falls back to the Documents
        /// folder.
        public static let packageResourceURL: URL? = Bundle.module.resourceURL

        /// The prelude in `packageResourceURL`, or `nil` if it is missing.
        public static let packagePreludePath: String? = {
            guard let root = packageResourceURL else {
                return nil
            }
            let path = root.appendingPathComponent("Prelude.scm", isDirectory: false).path
            return FileManager.default.fileExists(atPath: path) ? path : nil
        }()

        /// Puts the bundled libraries ahead of this context's search paths, as
        /// the REPL's `setupBinaryBundle(root:)` does for a directory on disk.
        /// Returns `false`, changing nothing, if they are missing. Calling it
        /// again adds nothing.
        ///
        /// It does not load the prelude: evaluate the file at
        /// `packagePreludePath` for that.
        public func usePackageResources() -> Bool {
            guard let root = Self.packageResourceURL else {
                return false
            }
            let libraries = root.appendingPathComponent("Libraries", isDirectory: true)
            let fileHandler = self.fileHandler
            guard fileHandler.isDirectory(atPath: root.path),
                fileHandler.isDirectory(atPath: libraries.path)
            else {
                return false
            }
            if !fileHandler.searchUrls.contains(where: { $0.path == root.path }) {
                _ = fileHandler.prependSearchPath(root.path)
            }
            if !fileHandler.librarySearchUrls.contains(where: { $0.path == libraries.path }) {
                _ = fileHandler.prependLibrarySearchPath(libraries.path)
            }
            return true
        }
    }
#endif
