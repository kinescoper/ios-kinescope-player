//
//  KinescopeInspectableMock.swift
//  KinescopeSDKTests
//
//  Created by Никита Коробейников on 29.03.2021.
//

@testable import KinescopeSDK

final class KinescopeInspectableMock: KinescopeInspectable {

    // MARK: - Spy Properties

    private(set) var listRequests = [KinescopeVideosRequest]()
    private(set) var videoRequests = [String]()
    private(set) var videoReferers = [String?]()

    // MARK: - Mock Properties

    var listSuccessMock: [Int: ([KinescopeVideo], KinescopeMetaData)] = [:]
    var videoSuccessMock: [String: KinescopeVideo] = [:]

    // MARK: - Methods

    func list(request: KinescopeVideosRequest,
              onSuccess: @escaping (([KinescopeVideo], KinescopeMetaData)) -> Void,
              onError: @escaping (KinescopeInspectError) -> Void) {
        listRequests.append(request)

        if let result = listSuccessMock[request.page] {
            onSuccess(result)
        } else {
            onSuccess(([], .init(pagination: .init(page: request.page,
                                                   perPage: request.perPage,
                                                   total: 0))))
        }
    }

    var videoErrorMock: [String: KinescopeInspectError] = [:]
    /// Keeps completions instead of calling them, to test calls made while loading.
    var defersCompletion = false
    private(set) var pendingCompletions = [() -> Void]()

    func video(id: String,
               referer: String?,
               onSuccess: @escaping (KinescopeVideo) -> Void,
               onError: @escaping (KinescopeInspectError) -> Void) {
        videoRequests.append(id)
        videoReferers.append(referer)

        let completion: () -> Void
        if let error = videoErrorMock[id] {
            completion = { onError(error) }
        } else if let result = videoSuccessMock[id] {
            completion = { onSuccess(result) }
        } else {
            completion = { onSuccess(.stub()) }
        }

        if defersCompletion {
            pendingCompletions.append(completion)
        } else {
            completion()
        }
    }

    func completePending() {
        let completions = pendingCompletions
        pendingCompletions.removeAll()
        completions.forEach { $0() }
    }

}
