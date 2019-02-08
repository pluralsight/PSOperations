import Foundation

extension DispatchQueue {
    class func global(qos: QualityOfService) -> DispatchQueue {
        return global(qos: .init(qos: qos))
    }
}
