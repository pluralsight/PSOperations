import Foundation

extension DispatchQoS.QoSClass {
    init(qos: QualityOfService) {
        switch qos {
        case .userInteractive:
            self = .userInteractive
        case .userInitiated:
            self = .userInitiated
        case .utility:
            self = .utility
        case .background:
            self = .background
        case .default:
            self = .default
        @unknown default:
            self = .default
        }
    }
}
