import DashKit
import RxSwift
import HsToolKit

class DashAdapter: BitcoinBaseAdapter {
    private let feeRate = 1

    private let dashKit: Kit

    init(wallet: Wallet, syncMode: SyncMode?, testMode: Bool) throws {
        guard case let .mnemonic(words, _) = wallet.account.type, words.count == 12 else {
            throw AdapterError.unsupportedAccount
        }

        guard let walletSyncMode = syncMode else {
            throw AdapterError.wrongParameters
        }

        let networkType: Kit.NetworkType = testMode ? .testNet : .mainNet
        let logger = App.shared.logger.scoped(with: "DashKit")

        dashKit = try Kit(withWords: words, walletId: wallet.account.id, syncMode: BitcoinBaseAdapter.kitMode(from: walletSyncMode), networkType: networkType, confirmationsThreshold: BitcoinBaseAdapter.confirmationsThreshold, logger: logger)

        super.init(abstractKit: dashKit)

        dashKit.delegate = self
    }

}

extension DashAdapter: DashKitDelegate {

    public func transactionsUpdated(inserted: [DashTransactionInfo], updated: [DashTransactionInfo]) {
        var records = [TransactionRecord]()

        for info in inserted {
            records.append(transactionRecord(fromTransaction: info))
        }
        for info in updated {
            records.append(transactionRecord(fromTransaction: info))
        }

        transactionRecordsSubject.onNext(records)
    }

}

extension DashAdapter: ISendDashAdapter {

    func availableBalance(address: String?) -> Decimal {
        availableBalance(feeRate: feeRate, address: address)
    }

    func validate(address: String) throws {
        try validate(address: address, pluginData: [:])
    }

    func fee(amount: Decimal, address: String?) -> Decimal {
        fee(amount: amount, feeRate: feeRate, address: address)
    }

    func sendSingle(amount: Decimal, address: String, sortMode: TransactionDataSortMode, logger: Logger) -> Single<Void> {
        sendSingle(amount: amount, address: address, feeRate: feeRate, sortMode: sortMode, logger: logger)
    }

}

extension DashAdapter {

    static func clear(except excludedWalletIds: [String]) throws {
        try Kit.clear(exceptFor: excludedWalletIds)
    }

}
