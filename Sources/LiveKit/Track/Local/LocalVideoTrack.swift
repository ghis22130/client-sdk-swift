/*
 * Copyright 2023 LiveKit
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation
import Promises
import WebRTC

@objc
public class LocalVideoTrack: Track, LocalTrack, VideoTrack {
    @objc
    public internal(set) var capturer: VideoCapturer

    @objc
    public internal(set) var videoSource: RTCVideoSource

    init(name: String,
         source: Track.Source,
         capturer: VideoCapturer,
         videoSource: RTCVideoSource)
    {
        let rtcTrack = Engine.createVideoTrack(source: videoSource)
        rtcTrack.isEnabled = true

        self.capturer = capturer
        self.videoSource = videoSource

        super.init(name: name,
                   kind: .video,
                   source: source,
                   track: rtcTrack)
    }

    override public func start() -> Promise<Bool> {
        super.start().then(on: queue) { didStart in
            self.capturer.startCapture().then(on: self.queue) { _ in didStart }
        }
    }

    override public func stop() -> Promise<Bool> {
        super.stop().then(on: queue) { didStop in
            self.capturer.stopCapture().then(on: self.queue) { _ in didStop }
        }
    }
}

public extension LocalVideoTrack {
    func add(videoRenderer: VideoRenderer) {
        super._add(videoRenderer: videoRenderer)
    }

    func remove(videoRenderer: VideoRenderer) {
        super._remove(videoRenderer: videoRenderer)
    }
}

// MARK: - Deprecated methods

public extension LocalVideoTrack {
    @available(*, deprecated, message: "Use CameraCapturer's methods instead to switch cameras")
    func restartTrack(options: CameraCaptureOptions = CameraCaptureOptions()) -> Promise<Bool> {
        guard let capturer = capturer as? CameraCapturer else {
            return Promise(TrackError.state(message: "Must be an CameraCapturer"))
        }
        capturer.options = options
        return capturer.restartCapture()
    }
}

public extension LocalVideoTrack {
    var publishOptions: PublishOptions? { super._publishOptions }

    var publishState: Track.PublishState { super._publishState }
}

public extension LocalVideoTrack {
    /// Clone with same ``VideoCapturer``.
    func clone() -> LocalVideoTrack {
        LocalVideoTrack(name: name,
                        source: source,
                        capturer: capturer,
                        videoSource: videoSource)
    }
}
