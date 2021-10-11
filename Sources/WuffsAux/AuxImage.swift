
// Copyright 2021 The Wuffs Authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// ---------------- Auxiliary - Image

import CWuffs

public final class ImageDecoder {
    let decoder: OpaquePointer?
    
    init(decoder: OpaquePointer?) {
        self.decoder = decoder
    }
    
    deinit {
        if let decoder = self.decoder {
            UnsafeMutableRawPointer(decoder).deallocate()
        }
    }
    
    public func decodeFrame(_ a_dst: UnsafeMutablePointer<wuffs_base__pixel_buffer>!, _ a_src: UnsafeMutablePointer<wuffs_base__io_buffer>!, _ a_blend: wuffs_base__pixel_blend, _ a_workbuf: wuffs_base__slice_u8, _ a_opts: UnsafeMutablePointer<wuffs_base__decode_frame_options>!) -> wuffs_base__status {
        return wuffs_base__image_decoder__decode_frame(self.decoder, a_dst, a_src, a_blend, a_workbuf, a_opts)
    }
    
    public func decodeFrameConfig(_ a_dst: UnsafeMutablePointer<wuffs_base__frame_config>!, _ a_src: UnsafeMutablePointer<wuffs_base__io_buffer>!) -> wuffs_base__status {
        return wuffs_base__image_decoder__decode_frame_config(self.decoder, a_dst, a_src)
    }
    
    public func decodeImageConfig(_ a_dst: UnsafeMutablePointer<wuffs_base__image_config>!, _ a_src: UnsafeMutablePointer<wuffs_base__io_buffer>!) -> wuffs_base__status {
        return wuffs_base__image_decoder__decode_image_config(self.decoder, a_dst, a_src)
    }
    
    public var frameDirtyRect: wuffs_base__rect_ie_u32 {
        return wuffs_base__image_decoder__frame_dirty_rect(self.decoder)
    }
    
    public var animationLoopCount: Int {
        return Int(wuffs_base__image_decoder__num_animation_loops(self.decoder))
    }

    public var decodedFrameConfigCount: UInt64 {
        return wuffs_base__image_decoder__num_decoded_frame_configs(self.decoder)
    }

    public var decodedFrameCount: UInt64 {
        return wuffs_base__image_decoder__num_decoded_frames(self.decoder)
    }
    
    public func restartFrame(index: UInt64, position: UInt64) -> wuffs_base__status {
        
      return wuffs_base__image_decoder__restart_frame(
        self.decoder, index, position);
    }

    public func setQuirkEnabled(
        quirk: UInt32,
        enabled: Bool) -> wuffs_base__empty_struct {
      return wuffs_base__image_decoder__set_quirk_enabled(
        self.decoder, quirk, enabled);
    }

    public func setReportMetadata(fourCC: UInt32, report: Bool) -> wuffs_base__empty_struct {
      return wuffs_base__image_decoder__set_report_metadata(
        self.decoder, fourCC, report);
    }

    public func tellMeMore(
    _ a_dst: UnsafeMutablePointer<wuffs_base__io_buffer>,
    _ a_minfo: UnsafeMutablePointer<wuffs_base__more_information>,
    _ a_src: UnsafeMutablePointer<wuffs_base__io_buffer>) -> wuffs_base__status {
      return wuffs_base__image_decoder__tell_me_more(
        self.decoder, a_dst, a_minfo, a_src);
    }

    public var workBufferLength: wuffs_base__range_ii_u64 {
        return wuffs_base__image_decoder__workbuf_len(self.decoder)
    }
}

public final class PixelBuffer {
    public let buffer: wuffs_base__pixel_buffer
    public private(set) var allocation: UnsafeMutableRawPointer?
    public let deallocateFunc: @convention(thin) (_ memory: UnsafeMutableRawPointer, _ userContext: AnyObject?) -> Void
    public var userContext: AnyObject? = nil
    
    init(buffer: wuffs_base__pixel_buffer, allocation: UnsafeMutableRawPointer?, userContext: AnyObject? = nil, deallocateFunc: @escaping @convention(thin) (_ memory: UnsafeMutableRawPointer, _ userContext: AnyObject?) -> Void) {
        self.buffer = buffer
        self.allocation = allocation
        self.userContext = userContext
        self.deallocateFunc = deallocateFunc
    }
    
    public convenience init(imageConfig image_config: wuffs_base__image_config,
    allocatingWith allocateFunc: (_ byteCount: Int) throws -> (memory: UnsafeMutableRawPointer, userContext: AnyObject?)?, deallocatingWith deallocateFunc: @escaping @convention(thin) (_ memory: UnsafeMutableRawPointer, _ userContext: AnyObject?) -> Void) throws {
        let w = image_config.pixcfg.width
        let h = image_config.pixcfg.height
        if ((w == 0) || (h == 0)) {
            throw WuffsError.zeroSizedImage
        }
        let len = image_config.pixcfg.pixelBufferLength
        if ((len == 0) || (SIZE_MAX < len)) {
            throw WuffsError.unsupportedPixelConfiguration
        }
        guard let (ptr, userContext) = try allocateFunc(Int(len)) else {
            throw WuffsError.outOfMemory
        }
        var pixbuf = wuffs_base__pixel_buffer()
        var status = withUnsafePointer(to: image_config.pixcfg) { pixConfig in
            return wuffs_base__pixel_buffer__set_from_slice(&pixbuf,
                                                     pixConfig,
                                                     wuffs_base__make_slice_u8(ptr.assumingMemoryBound(to: UInt8.self), Int(len)))
        }
        if (!wuffs_base__status__is_ok(&status)) {
            deallocateFunc(ptr, userContext)
            throw WuffsError(description: String(cString: wuffs_base__status__message(&status)))
        }
        self.init(buffer: pixbuf, allocation: ptr, userContext: userContext, deallocateFunc: deallocateFunc)
    }

    public func moveAllocation() -> (allocation: UnsafeMutableRawPointer?, userContext: AnyObject?) {
        let result = (self.allocation, self.userContext)
        self.allocation = nil
        self.userContext = nil
        return result
    }
    
    deinit {
        if let allocation = self.allocation {
            self.deallocateFunc(allocation, self.userContext)
        }
    }
}

public final class WorkBuffer {
    let buffer: wuffs_base__slice_u8
    let allocation: UnsafeMutableRawPointer?
    let deallocateFunc: @convention(thin) (UnsafeMutableRawPointer) -> Void
    
    init(buffer: wuffs_base__slice_u8, allocation: UnsafeMutableRawPointer?, deallocateFunc: @escaping @convention(thin) (UnsafeMutableRawPointer) -> Void) {
        self.buffer = buffer
        self.allocation = allocation
        self.deallocateFunc = deallocateFunc
    }
    
    deinit {
        if let allocation = self.allocation {
            self.deallocateFunc(allocation)
        }
    }
}

// DecodeImageCallbacks are the callbacks given to DecodeImage. They are always
// called in this order:
//  1. SelectDecoder
//  2. SelectPixfmt
//  3. AllocPixbuf
//  4. AllocWorkbuf
//  5. Done
//
// It may return early - the third callback might not be invoked if the second
// one fails - but the final callback (Done) is always invoked.
public protocol DecodeImageCallbacks {
    //    public typealias AllocatePixelBufferResult = Result<PixelBuffer, WuffsError>
    //    public typealias AllocateWorkBufferResult = Result<WorkBuffer, WuffsError>
    
    // SelectDecoder returns the image decoder for the input data's file format.
    // Returning a nullptr means failure (DecodeImage_UnsupportedImageFormat).
    //
    // Common formats will have a FourCC value in the range [1 ..= 0x7FFF_FFFF],
    // such as WUFFS_BASE__FOURCC__JPEG. A zero FourCC value means that the
    // caller is responsible for examining the opening bytes (a prefix) of the
    // input data. SelectDecoder implementations should not modify those bytes.
    //
    // SelectDecoder might be called more than once, since some image file
    // formats can wrap others. For example, a nominal BMP file can actually
    // contain a JPEG or a PNG.
    //
    // The default SelectDecoder accepts the FOURCC codes listed below. For
    // modular builds (i.e. when #define'ing WUFFS_CONFIG__MODULES), acceptance
    // of the ETC file format is optional (for each value of ETC) and depends on
    // the corresponding module to be enabled at compile time (i.e. #define'ing
    // WUFFS_CONFIG__MODULE__ETC).
    //  - WUFFS_BASE__FOURCC__BMP
    //  - WUFFS_BASE__FOURCC__GIF
    //  - WUFFS_BASE__FOURCC__NIE
    //  - WUFFS_BASE__FOURCC__PNG
    //  - WUFFS_BASE__FOURCC__WBMP
    func selectDecoder(fourCC: UInt32, prefix: wuffs_base__slice_u8) -> ImageDecoder?
    
    // SelectPixfmt returns the destination pixel format for AllocPixbuf. It
    // should return wuffs_base__make_pixel_format(etc) called with one of:
    //  - WUFFS_BASE__PIXEL_FORMAT__BGR_565
    //  - WUFFS_BASE__PIXEL_FORMAT__BGR
    //  - WUFFS_BASE__PIXEL_FORMAT__BGRA_NONPREMUL
    //  - WUFFS_BASE__PIXEL_FORMAT__BGRA_NONPREMUL_4X16LE
    //  - WUFFS_BASE__PIXEL_FORMAT__BGRA_PREMUL
    //  - WUFFS_BASE__PIXEL_FORMAT__RGBA_NONPREMUL
    //  - WUFFS_BASE__PIXEL_FORMAT__RGBA_PREMUL
    // or return image_config.pixcfg.pixel_format(). The latter means to use the
    // image file's natural pixel format. For example, GIF images' natural pixel
    // format is an indexed one.
    //
    // Returning otherwise means failure (DecodeImage_UnsupportedPixelFormat).
    //
    // The default SelectPixfmt implementation returns
    // wuffs_base__make_pixel_format(WUFFS_BASE__PIXEL_FORMAT__BGRA_PREMUL) which
    // is 4 bytes per pixel (8 bits per channel × 4 channels).
    func selectPixelFormat(imageConfig: wuffs_base__image_config) -> wuffs_base__pixel_format
    
    // AllocPixbuf allocates the pixel buffer.
    //
    // allow_uninitialized_memory will be true if a valid background_color was
    // passed to DecodeImage, since the pixel buffer's contents will be
    // overwritten with that color after AllocPixbuf returns.
    //
    // The default AllocPixbuf implementation allocates either uninitialized or
    // zeroed memory. Zeroed memory typically corresponds to filling with opaque
    // black or transparent black, depending on the pixel format.
    func allocatePixelBuffer(imageConfig: wuffs_base__image_config, allowUninitializedMemory: Bool) throws -> PixelBuffer
    
    // AllocWorkbuf allocates the work buffer. The allocated buffer's length
    // should be at least len_range.min_incl, but larger allocations (up to
    // len_range.max_incl) may have better performance (by using more memory).
    //
    // The default AllocWorkbuf implementation allocates len_range.max_incl bytes
    // of either uninitialized or zeroed memory.
    func allocateWorkBuffer(lengthRange: wuffs_base__range_ii_u64, allowUninitializedMemory: Bool) throws -> WorkBuffer
    
    // Done is always the last Callback method called by DecodeImage, whether or
    // not parsing the input encountered an error. Even when successful, trailing
    // data may remain in input and buffer.
    //
    // The image_decoder is the one returned by SelectDecoder (if SelectDecoder
    // was successful), or a no-op unique_ptr otherwise. Like any unique_ptr,
    // ownership moves to the Done implementation.
    //
    // Do not keep a reference to buffer or buffer.data.ptr after Done returns,
    // as DecodeImage may then de-allocate the backing array.
    //
    // The default Done implementation is a no-op, other than running the
    // image_decoder unique_ptr destructor.
    func done(pixelBuffer: PixelBuffer, input: WuffsInput, buffer: WuffsAux.IOBuffer, imageDecoder: ImageDecoder)
}

extension DecodeImageCallbacks {
    public func selectDecoder(fourCC: UInt32, prefix: wuffs_base__slice_u8) -> ImageDecoder? {
        switch Int32(fourCC) {
        case WUFFS_BASE__FOURCC__BMP:
            return ImageDecoder(decoder: wuffs_bmp__decoder__alloc_as__wuffs_base__image_decoder())
            
        case WUFFS_BASE__FOURCC__GIF:
            return ImageDecoder(decoder: wuffs_gif__decoder__alloc_as__wuffs_base__image_decoder())
            
        case WUFFS_BASE__FOURCC__NIE:
            return ImageDecoder(decoder: wuffs_nie__decoder__alloc_as__wuffs_base__image_decoder())
            
        case WUFFS_BASE__FOURCC__PNG:
            let dec = ImageDecoder(decoder: wuffs_png__decoder__alloc_as__wuffs_base__image_decoder())
            // Favor faster decodes over rejecting invalid checksums.
            _ = dec.setQuirkEnabled(quirk: UInt32(WUFFS_BASE__QUIRK_IGNORE_CHECKSUM), enabled: true)
            return dec
            
        case WUFFS_BASE__FOURCC__WBMP:
            return ImageDecoder(decoder: wuffs_wbmp__decoder__alloc_as__wuffs_base__image_decoder())
            
        default:
            return nil
        }
    }
    
    public func selectPixelFormat(imageConfig: wuffs_base__image_config) -> wuffs_base__pixel_format {
        return wuffs_base__make_pixel_format(WUFFS_BASE__PIXEL_FORMAT__BGRA_PREMUL)
    }
    
    public func allocatePixelBuffer(imageConfig image_config: wuffs_base__image_config, allowUninitializedMemory: Bool) throws -> PixelBuffer {
        let w = image_config.pixcfg.width
        let h = image_config.pixcfg.height
        if ((w == 0) || (h == 0)) {
            throw WuffsError.zeroSizedImage
        }
        let len = image_config.pixcfg.pixelBufferLength
        if ((len == 0) || (SIZE_MAX < len)) {
            throw WuffsError.unsupportedPixelConfiguration
        }
        guard let ptr = (allowUninitializedMemory ? malloc(Int(len)) : calloc(Int(len), 1)) else {
            throw WuffsError.outOfMemory
        }
        var pixbuf = wuffs_base__pixel_buffer()
        var status = withUnsafePointer(to: image_config.pixcfg) { pixConfig in
            return wuffs_base__pixel_buffer__set_from_slice(&pixbuf,
                                                     pixConfig,
                                                     wuffs_base__make_slice_u8(ptr.assumingMemoryBound(to: UInt8.self), Int(len)))
        }
        if (!wuffs_base__status__is_ok(&status)) {
            free(ptr)
            throw WuffsError(description: String(cString: wuffs_base__status__message(&status)))
        }
        return PixelBuffer(buffer: pixbuf, allocation: ptr, deallocateFunc: { mem, _ in free(mem) })
       
    }
    
    public func allocateWorkBuffer(lengthRange: wuffs_base__range_ii_u64, allowUninitializedMemory: Bool) throws -> WorkBuffer {
        let len = lengthRange.max_incl
        if len == 0 {
            throw WuffsError.zeroSizedAllocation
        }
        if SIZE_MAX < len {
            throw WuffsError.outOfMemory
        }
        guard let ptr = (allowUninitializedMemory ? malloc(Int(len)) : calloc(Int(len), 1)) else {
            throw WuffsError.outOfMemory
        }
        return WorkBuffer(buffer: wuffs_base__make_slice_u8(ptr.assumingMemoryBound(to: UInt8.self), Int(len)), allocation: ptr, deallocateFunc: { free($0) })
    }
    
    public func done(pixelBuffer: PixelBuffer, input: WuffsInput, buffer: WuffsAux.IOBuffer, imageDecoder: ImageDecoder) {
        
    }
}

public struct DefaultDecodeImageCallbacks: DecodeImageCallbacks {
    public init() {
        
    }
}

extension WuffsError {
    public static var bufferIsTooShort: WuffsError {
        return WuffsError(description: "wuffs_aux::DecodeImage: buffer is too short")
    }
    
    static var zeroSizedImage: WuffsError {
        return WuffsError(description: "wuffs_aux::DecodeImage: zero-sized image")
    }
    
    static var zeroSizedAllocation: WuffsError {
        return WuffsError(description: "wuffs_aux::DecodeImage: zero-sized work buffer allocation")
    }
    
    static var maxInclDimensionExceeded: WuffsError {
        return WuffsError(description: "wuffs_aux::DecodeImage: max_incl_dimension exceeded")
    }
    
    static var outOfMemory: WuffsError {
        return WuffsError(description: "wuffs_aux::DecodeImage: out of memory")
    }
    
    static var unexpectedEndOfFile: WuffsError {
        return WuffsError(description: "wuffs_aux::DecodeImage: unexpected end of file")
    }
    
    static var unsupportedImageFormat: WuffsError {
        return WuffsError(description: "wuffs_aux::DecodeImage: unsupported image format")
    }
    
    static var unsupportedPixelBlend: WuffsError {
        return WuffsError(description: "wuffs_aux::DecodeImage: unsupported pixel blend")
    }
    
    static var unsupportedPixelConfiguration: WuffsError {
        return WuffsError(description: "wuffs_aux::DecodeImage: unsupported pixel configuration")
    }
    
    static var unsupportedPixelFormat: WuffsError {
        return WuffsError(description: "wuffs_aux::DecodeImage: unsupported pixel format")
    }
}


func decodeImageAdvanceIOBuf(input: WuffsInput,
                             io_buf: inout wuffs_base__io_buffer,
                             compactable: Bool,
                             min_excl_pos: UInt64,
                             pos: UInt64) throws {
    if ((pos <= min_excl_pos) || (pos < io_buf.readerPosition)) {
        // Redirects must go forward.
        throw WuffsError.unsupportedImageFormat
    }
    while (true) {
        let relative_pos = pos - io_buf.readerPosition
        if (relative_pos <= io_buf.readerLength) {
            io_buf.meta.ri += Int(relative_pos)
            break;
        } else if (io_buf.meta.closed) {
            throw WuffsError.unexpectedEndOfFile;
        }
        io_buf.meta.ri = io_buf.meta.wi;
        if (compactable) {
            io_buf.compact()
        }
        if let error_message = input.copyIn(&io_buf) {
            throw WuffsError(description: error_message);
        }
    }
}

//
func decodeImage0(callbacks: DecodeImageCallbacks,
                  input: WuffsInput,
                  io_buf: inout wuffs_base__io_buffer,
                  pixel_blend: wuffs_base__pixel_blend,
                  background_color: wuffs_base__color_u32_argb_premul,
                  max_incl_dimension: UInt32) throws -> (ImageDecoder, PixelBuffer) {
    // Check args.
    switch (pixel_blend) {
    case WUFFS_BASE__PIXEL_BLEND__SRC, WUFFS_BASE__PIXEL_BLEND__SRC_OVER:
        break;
    default:
        throw WuffsError.unsupportedPixelBlend
    }
    
    var image_decoder: ImageDecoder = .init(decoder: nil)
    var image_config = wuffs_base__null_image_config();
    let start_pos = io_buf.readerPosition;
    var redirected = false;
    var fourcc = 0 as Int32;
    redirect: repeat {
        // Determine the image format.
        if (!redirected) {
            while (true) {
                fourcc = wuffs_base__magic_number_guess_fourcc(io_buf.readerSlice);
                if (fourcc > 0) {
                    break;
                } else if ((fourcc == 0) && (io_buf.readerLength >= 64)) {
                    break;
                } else if (io_buf.meta.closed || (io_buf.writerLength == 0)) {
                    fourcc = 0;
                    break;
                }
                if let error_message = input.copyIn(&io_buf) {
                    throw WuffsError(description: error_message);
                }
            }
        } else {
            var empty = wuffs_base__empty_io_buffer();
            var minfo = wuffs_base__empty_more_information();
            var tmm_status = image_decoder.tellMeMore(&empty, &minfo, &io_buf)
            if (tmm_status.repr != nil) {
                throw WuffsError(description: String(cString: wuffs_base__status__message(&tmm_status)))
            }
            if (minfo.flavor != WUFFS_BASE__MORE_INFORMATION__FLAVOR__IO_REDIRECT) {
                throw WuffsError.unsupportedImageFormat
            }
            let pos = wuffs_base__more_information__io_redirect__range(&minfo).min_incl;
            try decodeImageAdvanceIOBuf(
                input: input, io_buf: &io_buf, compactable: input.bringsItsOwnIOBuffer() == nil, min_excl_pos: start_pos, pos: pos)
            fourcc = Int32(wuffs_base__more_information__io_redirect__fourcc(&minfo))
            if (fourcc == 0) {
                throw WuffsError.unsupportedImageFormat
            }
        }
        
        // Select the image decoder.
        guard let decoder = callbacks.selectDecoder(fourCC:
                                                            UInt32(fourcc),
                                                          prefix: fourcc != 0 ? wuffs_base__empty_slice_u8() : io_buf.readerSlice) else {
            throw WuffsError.unsupportedImageFormat
        }
        image_decoder = decoder
        
        // Decode the image config.
        while (true) {
            var id_dic_status = image_decoder.decodeImageConfig(&image_config, &io_buf)
            if (id_dic_status.repr == nil) {
                break;
            } else if (id_dic_status.repr == wuffs_base__note__i_o_redirect) {
                if (redirected) {
                    throw WuffsError.unsupportedImageFormat
                }
                redirected = true;
                continue redirect
            } else if ( id_dic_status.repr != wuffs_base__suspension__short_read) {
                throw WuffsError(description: String(cString:  wuffs_base__status__message(&id_dic_status)))
            } else if (io_buf.meta.closed) {
                throw WuffsError.unexpectedEndOfFile
            } else {
                if let error_message = input.copyIn(&io_buf) {
                    throw WuffsError(description: error_message)
                }
            }
        }
    } while false
    
    // Select the pixel format.
    let w = wuffs_base__pixel_config__width(&image_config.pixcfg)
    let h = wuffs_base__pixel_config__height(&image_config.pixcfg)
    if ((w > max_incl_dimension) || (h > max_incl_dimension)) {
        throw WuffsError.maxInclDimensionExceeded
    }
    let pixel_format = callbacks.selectPixelFormat(imageConfig: image_config);
    if (pixel_format.repr != wuffs_base__pixel_config__pixel_format(&image_config.pixcfg).repr) {
//        switch (pixel_format.repr) {
//        case WUFFS_BASE__PIXEL_FORMAT__BGR_565,
//            WUFFS_BASE__PIXEL_FORMAT__BGR,
//            WUFFS_BASE__PIXEL_FORMAT__BGRA_NONPREMUL,
//            WUFFS_BASE__PIXEL_FORMAT__BGRA_NONPREMUL_4X16LE,
//            WUFFS_BASE__PIXEL_FORMAT__BGRA_PREMUL,
//            WUFFS_BASE__PIXEL_FORMAT__RGBA_NONPREMUL,
//        WUFFS_BASE__PIXEL_FORMAT__RGBA_PREMUL:
//            break;
//        default:
//            throw WuffsError.unsupportedPixelFormat
//        }
        wuffs_base__pixel_config__set(&image_config.pixcfg, pixel_format.repr, UInt32(WUFFS_BASE__PIXEL_SUBSAMPLING__NONE), w, h)
    }
    
    // Allocate the pixel buffer.
    let valid_background_color =
    wuffs_base__color_u32_argb_premul__is_valid(background_color);
    
    let alloc_pixbuf_result = try callbacks.allocatePixelBuffer(imageConfig: image_config, allowUninitializedMemory: valid_background_color)
    var pixel_buffer = alloc_pixbuf_result.buffer;
    if (valid_background_color) {
        var pb_scufr_status = wuffs_base__pixel_buffer__set_color_u32_fill_rect(&pixel_buffer, wuffs_base__pixel_config__bounds(&pixel_buffer.pixcfg), background_color)
        if (pb_scufr_status.repr != nil) {
            throw WuffsError(description: String(cString: wuffs_base__status__message(&pb_scufr_status)))
        }
    }
    
    // Allocate the work buffer. Wuffs' decoders conventionally assume that this
    // can be uninitialized memory.
    let workbuf_len = image_decoder.workBufferLength
    let alloc_workbuf_result = try
    callbacks.allocateWorkBuffer(lengthRange: workbuf_len, allowUninitializedMemory: true)
    if (alloc_workbuf_result.buffer.len < workbuf_len.min_incl) {
        throw WuffsError.bufferIsTooShort
    }
    
    // Decode the frame config.
    var frame_config = wuffs_base__null_frame_config();
    while (true) {
        var id_dfc_status = image_decoder.decodeFrameConfig(&frame_config, &io_buf)
        if (id_dfc_status.repr == nil) {
            break;
        } else if (id_dfc_status.repr != wuffs_base__suspension__short_read) {
            throw WuffsError(description: String(cString:  wuffs_base__status__message(&id_dfc_status)))
        } else if (io_buf.meta.closed) {
            throw WuffsError.unexpectedEndOfFile
        } else {
            if let error_message = input.copyIn(&io_buf) {
                throw WuffsError(description: error_message)
            }
        }
    }
    
    // Decode the frame (the pixels).
    //
    // TODO:
    // From here on, always returns the pixel_buffer. If we get this far, we can
    // still display a partial image, even if we encounter an error.
    var pixel_blend = pixel_blend
    if ((pixel_blend == WUFFS_BASE__PIXEL_BLEND__SRC_OVER) &&
        wuffs_base__frame_config__overwrite_instead_of_blend(&frame_config)) {
        pixel_blend = WUFFS_BASE__PIXEL_BLEND__SRC;
    }
    while (true) {
        var id_df_status = image_decoder.decodeFrame(&pixel_buffer, &io_buf, pixel_blend, alloc_workbuf_result.buffer, nil)
        if (id_df_status.repr == nil) {
            break;
        } else if (id_df_status.repr != wuffs_base__suspension__short_read) {
            throw WuffsError(description: String(cString:  wuffs_base__status__message(&id_df_status)))
        } else if (io_buf.meta.closed) {
            throw WuffsError.unexpectedEndOfFile
        } else {
            if let error_message = input.copyIn(&io_buf) {
                throw WuffsError(description: error_message)
            }
        }
    }
    return (image_decoder, alloc_pixbuf_result)
}

extension WuffsAux {
    /// DecodeImage decodes the image data in input. A variety of image file formats
    /// can be decoded, depending on what callbacks.SelectDecoder returns.
    ///
    /// For animated formats, only the first frame is returned, since the API is
    /// simpler for synchronous I/O and having DecodeImage only return when
    /// completely done, but rendering animation often involves handling other
    /// events in between animation frames. To decode multiple frames of animated
    /// images, or for asynchronous I/O (e.g. when decoding an image streamed over
    /// the network), use Wuffs' lower level C API instead of its higher level,
    /// simplified C++ API (the wuffs_aux API).
    ///
    /// The DecodeImageResult's fields depend on whether decoding succeeded:
    ///  - On total success, the error_message is empty and pixbuf.pixcfg.is_valid()
    ///    is true.
    ///  - On partial success (e.g. the input file was truncated but we are still
    ///    able to decode some of the pixels), error_message is non-empty but
    ///    pixbuf.pixcfg.is_valid() is still true. It is up to the caller whether to
    ///    accept or reject partial success.
    ///  - On failure, the error_message is non_empty and pixbuf.pixcfg.is_valid()
    ///    is false.
    ///
    /// The callbacks allocate the pixel buffer memory and work buffer memory. On
    /// success, pixel buffer memory ownership is passed to the DecodeImage caller
    /// as the returned pixbuf_mem_owner. Regardless of success or failure, the work
    /// buffer memory is deleted.
    ///
    /// The pixel_blend (one of the constants listed below) determines how to
    /// composite the decoded image over the pixel buffer's original pixels (as
    /// returned by callbacks.AllocPixbuf):
    ///  - WUFFS_BASE__PIXEL_BLEND__SRC
    ///  - WUFFS_BASE__PIXEL_BLEND__SRC_OVER
    ///
    /// The background_color is used to fill the pixel buffer after
    /// callbacks.AllocPixbuf returns, if it is valid in the
    /// wuffs_base__color_u32_argb_premul__is_valid sense. The default value,
    /// 0x0000_0001, is not valid since its Blue channel value (0x01) is greater
    /// than its Alpha channel value (0x00). A valid background_color will typically
    /// be overwritten when pixel_blend is WUFFS_BASE__PIXEL_BLEND__SRC, but might
    /// still be visible on partial (not total) success or when pixel_blend is
    /// WUFFS_BASE__PIXEL_BLEND__SRC_OVER and the decoded image is not fully opaque.
    ///
    /// Decoding fails (with DecodeImage_MaxInclDimensionExceeded) if the image's
    /// width or height is greater than max_incl_dimension.
    public static func decodeImage(callbacks: DecodeImageCallbacks = DefaultDecodeImageCallbacks(),
                                   input: WuffsInput,
                                   pixelBlend pixel_blend: wuffs_base__pixel_blend = WUFFS_BASE__PIXEL_BLEND__SRC,
                                   backgroundColor background_color: wuffs_base__color_u32_argb_premul = 0x0000_0001, // Invalid
                                   maxInclDimension max_incl_dimension: Int = 1048575) throws -> PixelBuffer {
        if let ioBuf = input.bringsItsOwnIOBuffer() {
            let (decoder, result) =
            try decodeImage0(callbacks: callbacks, input: input, io_buf: &ioBuf.pointee, pixel_blend: pixel_blend,
                             background_color: background_color, max_incl_dimension: UInt32(max_incl_dimension))
            callbacks.done(pixelBuffer: result, input: input, buffer: ioBuf.pointee, imageDecoder: decoder)
            return result
        } else {
            let fallbackIOArray = UnsafeMutableRawPointer.allocate(byteCount: 32768, alignment: 16)
            var ioBuf = wuffs_base__ptr_u8__writer(fallbackIOArray.assumingMemoryBound(to: UInt8.self), 32768)
            
            let (decoder, result) =
            try decodeImage0(callbacks: callbacks, input: input, io_buf: &ioBuf, pixel_blend: pixel_blend,
                             background_color: background_color, max_incl_dimension: UInt32(max_incl_dimension))
            callbacks.done(pixelBuffer: result, input: input, buffer: ioBuf, imageDecoder: decoder)
            fallbackIOArray.deallocate()
            
            return result
        }
    }
}
