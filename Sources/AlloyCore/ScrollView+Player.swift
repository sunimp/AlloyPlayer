//
//  ScrollView+Player.swift
//  AlloyCore
//
//  Created by Sun on 2026/4/14.
//

#if canImport(UIKit)
    import ObjectiveC
    import UIKit

    // MARK: - UIScrollView 播放器扩展

    public extension UIScrollView {
        // MARK: - Associated Keys

        private enum AssociatedKeys {
            static var scrollViewDirection = "alloy_scrollViewDirection"
            static var lastOffsetY = "alloy_lastOffsetY"
            static var lastOffsetX = "alloy_lastOffsetX"
            static var scrollDirection = "alloy_scrollDirection"
        }

        // MARK: - 公开属性

        /// 滚动视图方向（纵向/横向）
        var scrollViewDirection: ScrollViewDirection {
            get {
                (objc_getAssociatedObject(self, &AssociatedKeys.scrollViewDirection) as? Int)
                    .flatMap(ScrollViewDirection.init(rawValue:)) ?? .vertical
            }
            set {
                objc_setAssociatedObject(self, &AssociatedKeys.scrollViewDirection, newValue.rawValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }

        /// 当前滚动方向
        internal(set) var scrollDirection: ScrollDirection {
            get {
                (objc_getAssociatedObject(self, &AssociatedKeys.scrollDirection) as? Int)
                    .flatMap(ScrollDirection.init(rawValue:)) ?? .none
            }
            set {
                objc_setAssociatedObject(self, &AssociatedKeys.scrollDirection, newValue.rawValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }

        // MARK: - 内部属性

        internal var lastOffsetY: CGFloat {
            get { objc_getAssociatedObject(self, &AssociatedKeys.lastOffsetY) as? CGFloat ?? 0 }
            set { objc_setAssociatedObject(self, &AssociatedKeys.lastOffsetY, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        }

        internal var lastOffsetX: CGFloat {
            get { objc_getAssociatedObject(self, &AssociatedKeys.lastOffsetX) as? CGFloat ?? 0 }
            set { objc_setAssociatedObject(self, &AssociatedKeys.lastOffsetX, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
        }

        // MARK: - Cell 查找

        /// 获取指定 IndexPath 对应的 Cell
        func cell(at indexPath: IndexPath) -> UIView? {
            if let tableView = self as? UITableView {
                return tableView.cellForRow(at: indexPath)
            } else if let collectionView = self as? UICollectionView {
                return collectionView.cellForItem(at: indexPath)
            }
            return nil
        }

        /// 获取 Cell 对应的 IndexPath
        func indexPath(for cell: UIView) -> IndexPath? {
            if let tableView = self as? UITableView, let tableCell = cell as? UITableViewCell {
                return tableView.indexPath(for: tableCell)
            } else if let collectionView = self as? UICollectionView, let collectionCell = cell as? UICollectionViewCell {
                return collectionView.indexPath(for: collectionCell)
            }
            return nil
        }

        // MARK: - 滚动

        /// 滚动到指定 IndexPath
        func scroll(
            to indexPath: IndexPath,
            at anchor: ScrollAnchor,
            animated: Bool
        ) async {
            await withCheckedContinuation { continuation in
                scroll(to: indexPath, at: anchor, animated: animated) {
                    continuation.resume()
                }
            }
        }

        internal func scroll(
            to indexPath: IndexPath,
            at anchor: ScrollAnchor,
            animated: Bool,
            completion: (() -> Void)?
        ) {
            if let tableView = self as? UITableView {
                let position: UITableView.ScrollPosition = switch anchor {
                case .top: .top
                case .centeredVertically: .middle
                case .bottom: .bottom
                default: .none
                }
                tableView.scrollToRow(at: indexPath, at: position, animated: animated)
            } else if let collectionView = self as? UICollectionView {
                let position: UICollectionView.ScrollPosition = switch anchor {
                case .top: .top
                case .centeredVertically: .centeredVertically
                case .bottom: .bottom
                case .left: .left
                case .centeredHorizontally: .centeredHorizontally
                case .right: .right
                default: []
                }
                collectionView.scrollToItem(at: indexPath, at: position, animated: animated)
            }

            if animated {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    completion?()
                }
            } else {
                completion?()
            }
        }
    }
#endif
