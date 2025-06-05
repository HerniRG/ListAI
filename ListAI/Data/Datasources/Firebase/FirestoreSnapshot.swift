import Combine
import FirebaseFirestore

extension Publishers {
    struct FirestoreSnapshot: Publisher {
        typealias Output = QuerySnapshot
        typealias Failure = Error

        private let query: Query

        init(_ query: Query) { self.query = query }

        func receive<S: Subscriber>(subscriber: S)
        where S.Input == Output, S.Failure == Failure {

            let subscription = SnapshotSubscription(subscriber: subscriber, query: query)
            subscriber.receive(subscription: subscription)
        }

        private final class SnapshotSubscription<S: Subscriber>: Subscription
        where S.Input == QuerySnapshot, S.Failure == Error {

            private var listener: ListenerRegistration?
            private var subscriber: S?

            init(subscriber: S, query: Query) {
                self.subscriber = subscriber
                listener = query.addSnapshotListener(includeMetadataChanges: true) { snap, error in
                    if let error {
                        subscriber.receive(completion: .failure(error))
                    } else if let snap {
                        _ = subscriber.receive(snap)
                    }
                }
            }

            func request(_ demand: Subscribers.Demand) { /* no-op */ }

            func cancel() {
                listener?.remove()
                listener = nil
                subscriber = nil
            }
        }
    }
}
