//
//  Inspector.swift
//  KinescopeSDK
//
//  Created by Никита Коробейников on 23.03.2021.
//

// MARK: - KinescopeInspectable

class Inspector: KinescopeInspectable {

    // MARK: - Properties

    private let videosService: VideosService

    // MARK: - Initialisation

    init(videosService: VideosService) {
        self.videosService = videosService
    }

    // MARK: - Methods

    func video(id: String,
               referer: String?,
               onSuccess: @escaping (KinescopeVideo) -> Void,
               onError: @escaping (KinescopeInspectError) -> Void) {
        videosService.getVideo(by: id, referer: referer) { result in
            switch result {
            case .success(let response):
                onSuccess(response)
            case .failure(let error):
                onError(Inspector.parse(error: error))
            }
        }
    }
}

// MARK: - Private

private extension Inspector {

    static func parse(error: Error) -> KinescopeInspectError {
        guard let httpError = error as? KinescopeHTTPError else {
            return .unknown(error)
        }

        switch httpError.statusCode {
        case 404:
            return .notFound
        case 403:
            return .denied
        default:
            return .unknown(httpError)
        }
    }

}
