//
//  NSObject+ScopeFunction.swift
//  I340_IPTV
//
//  Created by HaoLK on 03/12/2020.
//

import Foundation

/// Scope functions
protocol ScopeFunc { }

extension ScopeFunc {
  /// Calls the specified function block with self value as its argument and returns self value.
  @inline(__always) func apply(block: (Self) -> ()) -> Self {
    block(self)
    return self
  }

  /// Calls the specified function block with self value as its argument and returns its result.
  @discardableResult
  @inline(__always) func letIt<R>(block: (Self) -> R) -> R {
    return block(self)
  }
}

extension NSObject: ScopeFunc { }
