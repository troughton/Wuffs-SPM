import CWuffs

extension wuffs_base__io_buffer {
    @inlinable
    public var isValid: Bool {
        return withUnsafePointer(to: self) { wuffs_base__io_buffer__is_valid($0) }
    }
    
    @inlinable
    public mutating func compact() {
        withUnsafeMutablePointer(to: &self) { wuffs_base__io_buffer__compact($0) }
    }
    
    @inlinable
    public var readerIOPosition: UInt64 {
        return withUnsafePointer(to: self) { wuffs_base__io_buffer__reader_io_position($0) }
    }
    
    @inlinable
    public var readerLength: Int {
        return withUnsafePointer(to: self) { wuffs_base__io_buffer__reader_length($0) }
    }
    
    @inlinable
    public var readerPointer: UnsafeMutableRawPointer {
        return withUnsafePointer(to: self) { UnsafeMutableRawPointer(wuffs_base__io_buffer__reader_pointer($0)) }
    }
    
    @inlinable
    public var readerPosition: UInt64 {
        return withUnsafePointer(to: self) { wuffs_base__io_buffer__reader_position($0) }
    }
    
    @inlinable
    public var readerSlice: wuffs_base__slice_u8 {
        return withUnsafePointer(to: self) { wuffs_base__io_buffer__reader_slice($0) }
    }
    
    @inlinable
    public var writerIOPosition: UInt64 {
        return withUnsafePointer(to: self) { wuffs_base__io_buffer__writer_io_position($0) }
    }
    
    @inlinable
    public var writerLength: Int {
        return withUnsafePointer(to: self) { wuffs_base__io_buffer__writer_length($0) }
    }
    
    @inlinable
    public var writerPointer: UnsafeMutableRawPointer {
        return withUnsafePointer(to: self) { UnsafeMutableRawPointer(wuffs_base__io_buffer__writer_pointer($0)) }
    }
    
    @inlinable
    public var writerPosition: UInt64 {
        return withUnsafePointer(to: self) { wuffs_base__io_buffer__writer_position($0) }
    }
    
    @inlinable
    public var writerSlice: wuffs_base__slice_u8 {
        return withUnsafePointer(to: self) { wuffs_base__io_buffer__writer_slice($0) }
    }
}

extension wuffs_base__pixel_config {
    public mutating func set(pixfmt_repr: UInt32,
                             pixsub_repr: UInt32,
                             width: UInt32,
                             height: UInt32) {
      wuffs_base__pixel_config__set(&self, pixfmt_repr, pixsub_repr, width, height);
    }

    public mutating func invalidate() {
        wuffs_base__pixel_config__invalidate(&self)
    }
    
    public var isValid: Bool {
        return withUnsafePointer(to: self) { wuffs_base__pixel_config__is_valid($0) }
    }
    
    public var pixelFormat: wuffs_base__pixel_format {
        return withUnsafePointer(to: self) { wuffs_base__pixel_config__pixel_format($0) }
    }
    
    public var pixelSubsampling: wuffs_base__pixel_subsampling {
        return withUnsafePointer(to: self) { wuffs_base__pixel_config__pixel_subsampling($0) }
    }

    public var bounds: wuffs_base__rect_ie_u32 {
        return withUnsafePointer(to: self) { wuffs_base__pixel_config__bounds($0) }
    }
    
    public var width: UInt32 {
        return withUnsafePointer(to: self) { wuffs_base__pixel_config__width($0) }
    }
    
    public var height: UInt32 {
        return withUnsafePointer(to: self) { wuffs_base__pixel_config__height($0) }
    }
    
    public var pixelBufferLength: UInt64 {
        return withUnsafePointer(to: self) { wuffs_base__pixel_config__pixbuf_len($0) }
    }
}
