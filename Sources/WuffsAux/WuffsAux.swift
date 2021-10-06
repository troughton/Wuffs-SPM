import CWuffs

public enum WuffsAux {
    public typealias IOBuffer = wuffs_base__io_buffer
}

public struct WuffsError: Error, CustomStringConvertible {
    public var description: String
}

public class WuffsInput {
    func bringsItsOwnIOBuffer() -> UnsafeMutablePointer<wuffs_base__io_buffer>? { return nil }
    func copyIn(_ buffer: UnsafeMutablePointer<wuffs_base__io_buffer>?) -> String? { return nil }
}

public final class FileInput: WuffsInput {
    let file: UnsafeMutablePointer<FILE>?
    
    public init(file: UnsafeMutablePointer<FILE>?) {
        self.file = file
    }
    
    override func copyIn(_ dst: UnsafeMutablePointer<WuffsAux.IOBuffer>?) -> String? {
        if self.file == nil {
            return "wuffs_aux::sync_io::FileInput: nullptr file";
        }
        guard let dst = dst else {
            return "wuffs_aux::sync_io::FileInput: nullptr IOBuffer";
        }
        
        if dst.pointee.meta.closed {
            return "wuffs_aux::sync_io::FileInput: end of file";
        } else {
            dst.pointee.compact()
            let n = fread(dst.pointee.writerPointer, 1, dst.pointee.writerLength, self.file)
            dst.pointee.meta.wi += n;
            dst.pointee.meta.closed = feof(self.file) != 0;
            if ferror(self.file) != 0 {
                return "wuffs_aux::sync_io::FileInput: error reading file";
            }
        }
        return nil
    }
}

public final class MemoryInput: WuffsInput {
    let io: UnsafeMutablePointer<wuffs_base__io_buffer>
    
    public init(buffer: UnsafeRawBufferPointer) {
        self.io = .allocate(capacity: 1)
        self.io.initialize(to: wuffs_base__ptr_u8__reader(UnsafeMutableRawPointer(mutating: buffer.baseAddress)?.assumingMemoryBound(to: UInt8.self), buffer.count, true))
    }
    
    deinit {
        self.io.deallocate()
    }
    
    override func bringsItsOwnIOBuffer() -> UnsafeMutablePointer<wuffs_base__io_buffer>? {
        return self.io
    }
    
    override func copyIn(_ dst: UnsafeMutablePointer<WuffsAux.IOBuffer>?) -> String? {
        guard let dst = dst else {
            return "wuffs_aux::sync_io::MemoryInput: nullptr IOBuffer";
        }
        if (dst.pointee.meta.closed) {
            return "wuffs_aux::sync_io::MemoryInput: end of file";
        } else if (wuffs_base__slice_u8__overlaps(dst.pointee.data, self.io.pointee.data)) {
            // Treat m_io's data as immutable, so don't compact dst or otherwise write
            // to it.
            return "wuffs_aux::sync_io::MemoryInput: overlapping buffers";
        } else {
            dst.pointee.compact();
            let nd = dst.pointee.writerLength
            let ns = self.io.pointee.readerLength
            let n = (nd < ns) ? nd : ns;
            dst.pointee.writerPointer.copyMemory(from: self.io.pointee.readerPointer, byteCount: n)
            self.io.pointee.meta.ri += n;
            dst.pointee.meta.wi += n;
            dst.pointee.meta.closed = self.io.pointee.readerLength == 0
        }
        return nil
    }
}
